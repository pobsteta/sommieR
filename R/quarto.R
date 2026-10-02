#' Formats de rendu Quarto
#' @export
SOMMIER_FORMATS_QUARTO <- c("html", "pdf")

#' Bilan de gestion en Quarto
#'
#' @description
#' Rend la gestion anterieure sous forme de document Quarto — HTML autoportant
#' ou PDF — en y joignant l'etat de la chaine, la balance de possibilite, les
#' elements d'IBP et la desserte.
#'
#' @details
#' Les cartes sont portees par la meme extraction : les contours des unites de
#' gestion et leurs indicateurs voyagent en WKT dans le RDS, et le document les
#' convertit en `sf` au rendu. Le RDS n'exige donc pas `sf` pour etre relu.
#'
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
#' @param fond Fond cadastral a poser sous les cartes, tel que le rend
#'   [sommier_fond_lire()] ; `NULL` pour s'en passer. Il se fournit et ne se
#'   telecharge pas : le rendu ne doit declencher aucun appel reseau, sans
#'   quoi un rapport cesserait d'etre editable hors ligne - et le meme rapport
#'   rejoue plus tard changerait de fond sans le dire. C'est aussi lui qui
#'   donne les tenements du recapitulatif du parcellaire - la part de chaque
#'   parcelle cadastrale comprise dans une unite : sans fond, le recapitulatif
#'   ne liste que les unites.
#' @param fond_pci Le PCI vecteur, sous l'une de deux formes. Les elements
#'   du plan que rend [sommier_elements_pci()] - bornes, details, cours d'eau,
#'   voies, dans la foret et a ses abords - recoivent leur propre section,
#'   avec une carte et un tableau par categorie. Les bornes seules, telles que
#'   les rend [sommier_fond_pci_lire()], se posent en croix sur la carte de la
#'   desserte. `NULL` pour s'en passer. Meme regle que `fond` : fourni, jamais
#'   telecharge au rendu.
#' @param photos Depot des photos des constats de terrain - reconnaissances
#'   de limite et suites des detections (voir [sommier_deposer_photo()]) ;
#'   `NULL` pour s'en passer. Fourni, jamais
#'   telecharge. Les vignettes de la planche photographique sont reduites au
#'   rendu ; une photo dont l'empreinte ne tient plus n'est pas montree.
#' @param public `TRUE` pour un document a diffuser : la planche
#'   photographique est retiree, le tableau garde le nombre de photos, et le
#'   document dit qu'elles existent. Une photo peut montrer un riverain ou une
#'   plaque d'immatriculation.
#' @param indices Indices de nemeton par unite, tels que les rend
#'   [sommier_lire_indices_nemeton()] (facultatif) : un encadre « Ce que la
#'   foret porte » donne le volume sur pied et la possibilite rapportee au
#'   capital. Des estimations, hors chaine, presentees comme telles.
#' @param reference_ifn Prelevement de reference de l'IFN, pour situer la
#'   possibilite et le preleve (facultatif) : liste nommee portant
#'   `taux_m3_ha_an`, et facultativement `ser`, `nom`, `millesime`, `source`.
#'   [sommier_reference_ifn()] la rend toute faite, depuis la
#'   sylvoecoregion de la foret et les tables IFN de nemeton.
#' @param coupes_detectees Coupes rases detectees, telles que les rend
#'   [sommier_coupes_sufosat()] (facultatif) : celles qu'aucun martelage de la
#'   meme unite n'explique, l'exercice de la detection ou le precedent, sont
#'   signalees sous la balance.
#' @param especes_observees Especes observees dans la foret et a ses abords,
#'   telles que les rend [sommier_especes_observees()] (facultatif) : une
#'   sous-section du patrimoine les liste, nommees dans TAXREF, comme un
#'   contexte hors registre. Un document public ne les rattache a aucune
#'   unite de gestion.
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
                                   referentiel = "psg", fond = NULL,
                                   fond_pci = NULL, photos = NULL,
                                   public = FALSE, indices = NULL,
                                   reference_ifn = NULL,
                                   coupes_detectees = NULL,
                                   especes_observees = NULL,
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

  # La sequence arrive en `integer64` (bigint) : relue par un R qui n'a pas
  # charge `bit64`, elle s'imprime comme le double dont elle partage les
  # octets - 16 devient 8e-323. Le RDS la porte donc en texte, et reste
  # lisible sans `bit64`.
  verification <- sommier_verifier(con, foret_id)
  if (!is.null(verification$seq_tete)) {
    verification$seq_tete <- format(verification$seq_tete, scientific = FALSE)
  }

  # Meme piege pour les tableaux : un `count(*)` arrive en bigint, et une
  # entree comptee sortait « 4.940656e-324 ». Les colonnes `integer64` des
  # sections passent en numerique avant d'entrer dans le RDS.
  gestion <- sommier_gestion_anterieure(
    con, foret_id, debut = debut, fin = fin, referentiel = referentiel
  )
  gestion$sections <- lapply(gestion$sections, sans_integer64)

  rapport <- list(
    gestion_anterieure = gestion,
    verification    = verification,
    carte           = essayer_section(sommier_couche_ug(
      con, foret_id, debut = debut, fin = fin
    )),
    # Sans bornes : le patrimoine remarquable et la desserte sont des etats
    # courants, et un phenomene anterieur a la periode explique souvent ce
    # qu'on y lit.
    objets          = essayer_section(sommier_objets_localises(con, foret_id)),
    fond            = fond,
    fond_pci        = fond_pci,
    ibp             = essayer_section(sommier_elements_ibp(con, foret_id)),
    densite_voirie  = essayer_section(sommier_densite_voirie(con, foret_id)),
    # Sans bornes, comme le patrimoine : la derniere visite d'une borne est un
    # etat courant, quelle que soit la periode du rapport.
    limites         = essayer_section(lire_reconnaissances(
      con, foret_id, elements = if (!is.null(fond_pci$categorie)) fond_pci
    )),
    public          = isTRUE(public),
    indices         = indices,
    balance_surface = essayer_section(sommier_balance_surface(con, foret_id)),
    reference_ifn   = valider_reference_ifn(reference_ifn),
    # Sans bornes, comme les limites : le sort d'une detection est un etat
    # courant.
    suites_detection = essayer_section(lire_suites_detection(con, foret_id)),
    coupes_sans_martelage = essayer_section(suite_des_coupes(
      con, foret_id, coupes_sans_martelage(con, foret_id, coupes_detectees)
    )),
    coupes_detectees_parametres = if (!is.null(coupes_detectees)) list(
      seuil_proba = attr(coupes_detectees, "seuil_proba"),
      surface_min_ha = attr(coupes_detectees, "surface_min_ha"),
      n = nrow(coupes_detectees)
    ),
    especes_observees = valider_especes_observees(especes_observees, public),
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
  # Le titre est fixe ; le sous-titre dit la foret, la periode et l'objet du
  # bilan, que l'en-tete YAML ne sait pas calculer : il se pose dans la copie.
  poser_sous_titre(source_qmd, sous_titre_bilan(gestion))
  # Les vignettes se deposent dans l'atelier, a cote du document : un rendu
  # public n'en fabrique aucune.
  if (!isTRUE(public) && !est_vide(photos)) {
    depot <- valider_texte(photos, "photos")
    for (section in c("limites", "suites_detection")) {
      if (!is.null(rapport[[section]])) {
        rapport[[section]]$photos <- preparer_vignettes(
          rapport[[section]]$photos, depot, atelier
        )
      }
    }
  }
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
  # `file.copy()` ne signale un echec que par un avertissement : sans ce
  # controle, la fonction rendrait le chemin d'un document qui n'existe pas.
  if (!isTRUE(file.copy(produit, chemin, overwrite = TRUE))) {
    stop("Impossible d'ecrire le document dans ", chemin, ".", call. = FALSE)
  }
  invisible(chemin)
}

# Les compteurs sont petits : les passer en double ne perd rien, et le RDS
# se relit alors sans `bit64`.
sans_integer64 <- function(df) {
  if (!is.data.frame(df)) return(df)
  for (colonne in names(df)) {
    if (inherits(df[[colonne]], "integer64")) {
      df[[colonne]] <- as.numeric(df[[colonne]])
    }
  }
  df
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

# Un document public ne place aucune observation dans une unite : sans les
# statuts, on ne sait pas quelle espece est sensible.
valider_especes_observees <- function(especes, public) {
  if (is.null(especes)) {
    return(NULL)
  }
  if (!is.data.frame(especes) || is.null(attr(especes, "taxref")) ||
      !all(c("cd_ref", "nom_valide", "groupe", "n_observations") %in%
             names(especes))) {
    stop("`especes_observees` doit venir de sommier_especes_observees().",
         call. = FALSE)
  }
  if (isTRUE(public)) {
    especes$ug <- NULL
  }
  especes
}

# Ce que le bilan sert a reviser, dans les termes de chaque referentiel.
SOMMIER_OBJETS_BILAN <- c(
  psg = "Gestion ant\u00e9rieure du plan simple de gestion",
  amenagement = "Bilan de l'am\u00e9nagement pr\u00e9c\u00e9dent",
  ct88 = "\u00c9valuation de fin de plan (CT88)"
)

sous_titre_bilan <- function(gestion) {
  debut <- if (identical(gestion$debut, "0001-01-01")) {
    "depuis l'ouverture du sommier"
  } else {
    paste("du", format(as.Date(gestion$debut), "%d/%m/%Y"))
  }
  fin <- if (identical(gestion$fin, "9999-12-31")) "\u00e0 ce jour" else
    paste("au", format(as.Date(gestion$fin), "%d/%m/%Y"))
  paste0(gestion$foret, " \u2014 ", debut, " ", fin, " \u2014 ",
         SOMMIER_OBJETS_BILAN[[gestion$referentiel]])
}

# Une chaine YAML entre apostrophes double ses apostrophes : "Foret
# domaniale d'Orleans" ne doit pas fermer la chaine.
poser_sous_titre <- function(qmd, sous_titre) {
  lignes <- readLines(qmd, encoding = "UTF-8", warn = FALSE)
  yaml <- paste0("'", gsub("'", "''", sous_titre, fixed = TRUE), "'")
  lignes <- sub("@@SOUS_TITRE@@", yaml, lignes, fixed = TRUE)
  writeLines(enc2utf8(lignes), qmd, useBytes = TRUE)
}

valider_reference_ifn <- function(reference) {
  if (is.null(reference)) {
    return(NULL)
  }
  if (!is.list(reference) || is.null(reference$taux_m3_ha_an)) {
    stop("`reference_ifn` doit etre une liste portant `taux_m3_ha_an`.",
         call. = FALSE)
  }
  compacter(list(
    taux_m3_ha_an = valider_nombre(reference$taux_m3_ha_an,
                                   "reference_ifn$taux_m3_ha_an", min = 0),
    ser = si_present(reference$ser, valider_texte, "reference_ifn$ser"),
    nom = si_present(reference$nom, valider_texte, "reference_ifn$nom"),
    millesime = si_present(reference$millesime, valider_texte,
                           "reference_ifn$millesime"),
    source = si_present(reference$source, valider_texte,
                        "reference_ifn$source")
  ))
}

# Une coupe detectee est expliquee par un martelage de la meme unite,
# l'exercice de la detection ou le precedent : on martele avant d'abattre.
coupes_sans_martelage <- function(con, foret_id, coupes) {
  if (is.null(coupes) || nrow(coupes) == 0L) {
    return(NULL)
  }
  martelages <- DBI::dbGetQuery(
    con,
    "SELECT u.numero_affichage AS ug, c.exercice
       FROM v_coupe c JOIN ug u ON u.uuid = c.ug_uuid
      WHERE c.foret_id = $1
        AND c.type_entree IN ('martelage', 'produit_accidentel')",
    params = list(foret_id)
  )
  explique <- vapply(seq_len(nrow(coupes)), function(i) {
    any(martelages$ug == coupes$ug[[i]] &
          martelages$exercice %in% (coupes$annee[[i]] - c(1L, 0L)))
  }, logical(1))
  coupes[!explique, , drop = FALSE]
}
