#' Construction d'une entree de sommier
#'
#' @description
#' Prepare une entree valide mais **non encore chainee** : `seq`, `hash_prev`
#' et `hash` sont affectes au moment de l'insertion, par [sommier_chainer()]
#' hors base ou par [sommier_ajouter()] en base. Cette separation est
#' volontaire - la position dans la chaine n'est pas une propriete de
#' l'entree, c'est une propriete du registre au moment ou on l'y ecrit.
#'
#' @details
#' Le champ `ndp` raccorde le sommier au systeme nemeton (brief, section 4) :
#' une entree saisie sur le terrain est NDP 0 par definition, une entree
#' deduite de teledetection porte le NDP de sa source. La valeur par defaut
#' est donc 0, le sommier etant le receptacle NDP 0 de la plateforme.
#'
#' Une correction ne modifie jamais l'entree fautive : elle prend la forme
#' d'une nouvelle entree portant `corrige_id`. C'est le comportement du
#' classeur papier, ou la rature est interdite et la rectification se fait par
#' mention nouvelle.
#'
#' @param foret_id UUID de la foret.
#' @param registre Numero de registre, parmi [SOMMIER_REGISTRES_OUVERTS].
#' @param date_evenement Date de l'evenement enregistre (`Date` ou
#'   `"AAAA-MM-JJ"`) - celle du fait, pas celle de la saisie.
#' @param auteur Identifiant de l'auteur (`sub` OIDC Keycloak).
#' @param payload Liste nommee produite par [registre5_coupe()] ou
#'   [registre6_travaux()].
#' @param ug_uuid UUID de l'unite de gestion, ou `NULL` pour une entree a
#'   l'echelle de la foret.
#' @param ndp Niveau de precision nemeton (entier >= 0, defaut 0).
#' @param corrige_id UUID de l'entree que celle-ci rectifie, le cas echeant.
#' @param date_saisie Instant de saisie (`POSIXct` ou `"AAAA-MM-JJTHH:MM:SSZ"`).
#'   Par defaut l'instant courant en UTC. Il est couvert par l'empreinte, il
#'   doit donc etre fixe par l'ecrivain, pas par l'horloge du serveur.
#' @param id UUID de l'entree ; genere si absent.
#'
#' @return Un objet de classe `sommier_entree`.
#'
#' @examples
#' sommier_entree(
#'   foret_id = "3f2b1c4d-5e6f-4a7b-8c9d-0e1f2a3b4c5d",
#'   registre = 6L,
#'   date_evenement = "2026-04-15",
#'   auteur = "agent-01",
#'   payload = registre6_travaux(annee = 2026, nature_travaux = "degagement")
#' )
#'
#' @export
sommier_entree <- function(foret_id,
                           registre,
                           date_evenement,
                           auteur,
                           payload,
                           ug_uuid = NULL,
                           ndp = 0L,
                           corrige_id = NULL,
                           date_saisie = Sys.time(),
                           id = uuid_v4()) {
  registre <- valider_entier(registre, "registre", min = 1, max = 9)
  payload <- valider_payload(registre, payload)

  echelle <- echelle_registre(registre)
  if (echelle == "ug" && est_vide(ug_uuid)) {
    stop("Le registre ", registre, " (", SOMMIER_REGISTRES$nom[[registre]],
         ") s'ancre sur une unite de gestion : `ug_uuid` est obligatoire.",
         call. = FALSE)
  }
  if (echelle == "foret" && !est_vide(ug_uuid)) {
    stop("Le registre ", registre, " (", SOMMIER_REGISTRES$nom[[registre]],
         ") s'ancre a l'echelle de la foret : `ug_uuid` doit rester NULL.",
         call. = FALSE)
  }

  structure(
    list(
      id             = valider_uuid(id, "id"),
      foret_id       = valider_uuid(foret_id, "foret_id"),
      ug_uuid        = if (est_vide(ug_uuid)) NULL else valider_uuid(ug_uuid, "ug_uuid"),
      registre       = registre,
      seq            = NA_real_,
      date_evenement = format_date(date_evenement, "date_evenement"),
      date_saisie    = format_instant(date_saisie, "date_saisie"),
      auteur         = valider_texte(auteur, "auteur"),
      ndp            = valider_entier(ndp, "ndp", min = 0),
      corrige_id     = if (est_vide(corrige_id)) NULL else valider_uuid(corrige_id, "corrige_id"),
      schema_version = unname(SOMMIER_SCHEMA_VERSIONS[[as.character(registre)]]),
      payload        = payload,
      hash_prev      = NULL,
      hash           = NULL
    ),
    class = "sommier_entree"
  )
}

#' @export
print.sommier_entree <- function(x, ...) {
  cat("<entree de sommier>\n")
  cat("  registre  : ", x$registre, " - ",
      SOMMIER_REGISTRES$nom[[x$registre]], "\n", sep = "")
  cat("  foret     : ", x$foret_id, "\n", sep = "")
  cat("  ug        : ", x$ug_uuid %||% "(echelle foret)", "\n", sep = "")
  cat("  evenement : ", x$date_evenement, "\n", sep = "")
  cat("  auteur    : ", x$auteur, " (NDP ", x$ndp, ")\n", sep = "")
  if (!is.null(x$corrige_id)) {
    cat("  corrige   : ", x$corrige_id, "\n", sep = "")
  }
  if (is.null(x$hash)) {
    cat("  chainage  : non chainee\n")
  } else {
    cat("  seq       : ", format(x$seq, scientific = FALSE), "\n", sep = "")
    cat("  hash      : ", empreinte_hex(x$hash), "\n", sep = "")
  }
  cat("  payload   : ", jcs(x$payload), "\n", sep = "")
  invisible(x)
}

#' Chainage d'une suite d'entrees hors base
#'
#' @description
#' Affecte `seq`, `hash_prev` et `hash` a une suite d'entrees, dans l'ordre
#' fourni. C'est la meme arithmetique que celle appliquee par
#' [sommier_ajouter()] cote base, isolee ici pour pouvoir etre testee,
#' rejouee et verifiee sans serveur.
#'
#' @param entrees Liste d'objets `sommier_entree`, ou un objet seul.
#' @param seq_depart Sequence de la premiere entree (defaut 1).
#' @param hash_prev Empreinte precedant la premiere entree. Par defaut la
#'   genese de la foret ; a renseigner pour prolonger une chaine existante.
#'
#' @return Une liste d'objets `sommier_entree` chainees.
#'
#' @examples
#' foret <- "3f2b1c4d-5e6f-4a7b-8c9d-0e1f2a3b4c5d"
#' e <- sommier_entree(
#'   foret_id = foret, registre = 6L, date_evenement = "2026-04-15",
#'   auteur = "agent-01",
#'   payload = registre6_travaux(annee = 2026, nature_travaux = "degagement")
#' )
#' chainees <- sommier_chainer(list(e))
#' sommier_verifier_chaine(chainees)$valide
#'
#' @export
sommier_chainer <- function(entrees, seq_depart = 1, hash_prev = NULL) {
  if (inherits(entrees, "sommier_entree")) {
    entrees <- list(entrees)
  }
  if (length(entrees) == 0L) {
    return(list())
  }

  forets <- unique(vapply(entrees, function(e) e$foret_id, character(1)))
  if (length(forets) > 1L) {
    stop("sommier_chainer(): la sequence est monotone par foret ; entrees de ",
         length(forets), " forets differentes recues.", call. = FALSE)
  }

  courant <- if (is.null(hash_prev)) {
    sommier_empreinte_genese(forets[[1L]])
  } else {
    valider_empreinte(hash_prev, "hash_prev")
  }
  seq_courant <- valider_entier(seq_depart, "seq_depart", min = 1)

  for (i in seq_along(entrees)) {
    entrees[[i]]$seq <- seq_courant
    entrees[[i]]$hash_prev <- courant
    entrees[[i]]$hash <- sommier_empreinte(entrees[[i]], courant)
    courant <- entrees[[i]]$hash
    seq_courant <- seq_courant + 1
  }
  entrees
}

#' Conversion d'entrees en data.frame
#'
#' Met les entrees a plat pour l'insertion en base ou l'export : le payload
#' est rendu en JSON canonique, les empreintes en hexadecimal.
#'
#' @param entrees Liste d'objets `sommier_entree`.
#' @return Un `data.frame`.
#' @export
entrees_en_data_frame <- function(entrees) {
  if (inherits(entrees, "sommier_entree")) {
    entrees <- list(entrees)
  }
  champ <- function(nom, type) {
    vapply(entrees, function(e) {
      v <- e[[nom]]
      if (est_vide(v)) as(NA, type) else as(v, type)
    }, vector(type, 1L))
  }
  data.frame(
    id             = champ("id", "character"),
    foret_id       = champ("foret_id", "character"),
    ug_uuid        = champ("ug_uuid", "character"),
    registre       = champ("registre", "numeric"),
    seq            = champ("seq", "numeric"),
    date_evenement = champ("date_evenement", "character"),
    date_saisie    = champ("date_saisie", "character"),
    auteur         = champ("auteur", "character"),
    ndp            = champ("ndp", "numeric"),
    corrige_id     = champ("corrige_id", "character"),
    schema_version = champ("schema_version", "character"),
    payload        = vapply(entrees, function(e) jcs(e$payload), character(1)),
    hash_prev      = vapply(entrees, function(e) empreinte_hex(e$hash_prev), character(1)),
    hash           = vapply(entrees, function(e) empreinte_hex(e$hash), character(1)),
    stringsAsFactors = FALSE
  )
}
