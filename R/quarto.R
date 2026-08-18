#' Formats de rendu Quarto
#' @export
SOMMIER_FORMATS_QUARTO <- c("html", "pdf")

#' Rapport de gestion anterieure en Quarto
#'
#' @description
#' Rend la gestion anterieure sous forme de document Quarto — HTML autoportant
#' ou PDF — en y joignant l'etat de la chaine, la balance de possibilite, les
#' elements d'IBP et la desserte.
#'
#' @details
#' Les donnees sont extraites de la base **avant** le rendu et deposees dans un
#' fichier RDS que le document lit. Deux consequences voulues : aucun
#' identifiant de connexion ne circule dans le document ou ses parametres, et
#' le rendu est reproductible a l'identique sans acces a la base — on peut
#' rejouer un rapport des mois plus tard sur le meme instantane.
#'
#' Le document porte l'empreinte de tete et l'etat de la chaine au moment de
#' l'edition. C'est une mise en forme, pas la preuve : la valeur probante reste
#' dans le registre, et [sommier_exporter_manifeste()] est ce qui la transporte.
#' Le rapport le dit explicitement a son lecteur plutot que de laisser croire
#' qu'un PDF vaut attestation.
#'
#' Quarto doit etre installe et joignable dans le `PATH` ; le rendu PDF exige
#' en outre une distribution LaTeX (`quarto install tinytex` suffit).
#'
#' @param con Connexion DBI.
#' @param foret_id UUID de la foret.
#' @param chemin Fichier de destination. Son extension doit s'accorder avec
#'   `format`.
#' @param format `"html"` ou `"pdf"`.
#' @param debut,fin Bornes de la periode (voir [sommier_gestion_anterieure()]).
#' @param referentiel L'un de [SOMMIER_REFERENTIELS].
#' @param quarto Chemin de l'executable Quarto.
#'
#' @return Invisiblement, le chemin du document produit.
#'
#' @seealso [sommier_gestion_anterieure()], [sommier_rapport_markdown()]
#'
#' @examples
#' # Necessite une connexion et Quarto :
#' # sommier_rapport_quarto(con, foret, "gestion-anterieure.html")
#'
#' @export
sommier_rapport_quarto <- function(con, foret_id, chemin, format = "html",
                                   debut = NULL, fin = NULL,
                                   referentiel = "psg",
                                   quarto = Sys.which("quarto")) {
  format <- valider_choix(format, "format", SOMMIER_FORMATS_QUARTO)
  chemin <- valider_texte(chemin, "chemin")
  if (!nzchar(quarto)) {
    stop("Quarto est introuvable dans le PATH. L'installer depuis ",
         "https://quarto.org, ou passer son chemin par `quarto`.",
         call. = FALSE)
  }
  extension <- tolower(tools::file_ext(chemin))
  if (!identical(extension, format)) {
    stop("L'extension de `chemin` (", extension, ") ne correspond pas au ",
         "format demande (", format, ").", call. = FALSE)
  }

  rapport <- list(
    gestion_anterieure = sommier_gestion_anterieure(
      con, foret_id, debut = debut, fin = fin, referentiel = referentiel
    ),
    verification    = sommier_verifier(con, foret_id),
    ibp             = essayer_section(sommier_elements_ibp(con, foret_id)),
    densite_voirie  = essayer_section(sommier_densite_voirie(con, foret_id)),
    version_sommier = as.character(utils::packageVersion("sommieR")),
    edite_le        = format(Sys.Date(), "%d/%m/%Y")
  )

  modele <- system.file("quarto", "gestion-anterieure.qmd", package = "sommieR")
  if (modele == "") {
    stop("Modele Quarto introuvable dans le paquet.", call. = FALSE)
  }

  # Rendu dans un repertoire de travail dedie : Quarto y depose ses fichiers
  # intermediaires, qu'on ne veut pas melanger a ceux de l'appelant.
  atelier <- tempfile("sommier-quarto-")
  dir.create(atelier)
  on.exit(unlink(atelier, recursive = TRUE), add = TRUE)

  source_qmd <- file.path(atelier, "rapport.qmd")
  file.copy(modele, source_qmd)
  saveRDS(rapport, file.path(atelier, "donnees.rds"))

  # Chemin absolu, et non un nom relatif : `system2()` n'offre pas de
  # repertoire de travail, la commande s'executerait donc dans celui de
  # l'appelant et Quarto ne trouverait pas le source.
  resultat <- system2(
    quarto,
    c("render", shQuote(normalizePath(source_qmd)), "--to", format),
    stdout = TRUE, stderr = TRUE, env = environnement_utf8()
  )
  statut <- attr(resultat, "status")
  produit <- file.path(atelier, paste0("rapport.", format))
  if ((!is.null(statut) && statut != 0L) || !file.exists(produit)) {
    stop("Le rendu Quarto a echoue :\n",
         paste(utils::tail(resultat, 25L), collapse = "\n"), call. = FALSE)
  }

  dossier <- dirname(chemin)
  if (!dir.exists(dossier)) {
    dir.create(dossier, recursive = TRUE)
  }
  file.copy(produit, chemin, overwrite = TRUE)
  invisible(chemin)
}

# Une section facultative absente ne doit pas faire echouer tout le rapport :
# un sommier sans patrimoine remarquable ou sans desserte reste editable.
essayer_section <- function(expr) {
  resultat <- try(expr, silent = TRUE)
  if (inherits(resultat, "try-error") || is.null(resultat) ||
      (is.data.frame(resultat) && nrow(resultat) == 0L)) {
    return(NULL)
  }
  resultat
}

#' Locale UTF-8 pour le rendu
#'
#' @description
#' Rend les variables d'environnement a passer au processus Quarto pour que le
#' R qu'il lance ecrive en UTF-8.
#'
#' @details
#' Sans locale UTF-8, R echappe tout caractere non ASCII qu'il emet : un
#' rapport francais sort crible de `<U+00E9>` a la place des `e` accentues, et
#' le defaut passe d'autant plus facilement inapercu qu'il n'echoue pas. Le cas
#' n'a rien d'exotique - une tache cron, un conteneur ou un runner de CI
#' tournent couramment sous `LANG=C`.
#'
#' Si la session est deja en UTF-8, rien n'est impose : la locale de
#' l'utilisateur, souvent `fr_FR.UTF-8`, vaut mieux qu'un choix arbitraire.
#' Sinon, la premiere locale UTF-8 disponible est retenue. Si le systeme n'en
#' propose aucune, un avertissement le dit plutot que de laisser decouvrir le
#' probleme dans le document.
#'
#' @return Un vecteur de caracteres `VAR=valeur`, eventuellement vide.
#' @noRd
environnement_utf8 <- function() {
  if (isTRUE(l10n_info()[["UTF-8"]])) {
    return(character(0))
  }
  disponibles <- try(
    system2("locale", "-a", stdout = TRUE, stderr = FALSE),
    silent = TRUE
  )
  if (inherits(disponibles, "try-error")) {
    disponibles <- character(0)
  }
  candidates <- c("C.UTF-8", "C.utf8", "fr_FR.UTF-8", "fr_FR.utf8",
                  "en_US.UTF-8", "en_US.utf8")
  retenue <- candidates[candidates %in% disponibles]

  if (length(retenue) == 0L) {
    warning("Aucune locale UTF-8 disponible sur ce systeme : les caracteres ",
            "accentues seront echappes en <U+00E9> dans le document. ",
            "Installer une locale UTF-8 (par exemple C.UTF-8) pour y remedier.",
            call. = FALSE)
    return(character(0))
  }
  c(paste0("LC_ALL=", retenue[[1L]]), paste0("LANG=", retenue[[1L]]))
}
