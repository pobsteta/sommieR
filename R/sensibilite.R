#' Referentiel de sensibilite des especes (SINP)
#'
#' @description
#' Lit le referentiel national de sensibilite de l'INPN - le fichier
#' `RefSensibilite_<version>.csv` de l'archive `SENSIBILITE.zip` - pour
#' flouter, dans un sommier a transmettre, la localisation des especes
#' sensibles (voir [sommier_registre_quarto()]).
#'
#' @details
#' **Le fichier n'est pas dans le paquet.** Sa licence n'est pas connue : on
#' le telecharge soi-meme depuis l'INPN
#' (`https://assets.patrinat.fr/files/referentiel/SENSIBILITE.zip`) et on
#' passe ici le CSV, ou l'archive entiere. Ce qui en est lu est date et
#' empreint : la version (tiree du nom du fichier) et le SHA-256 du CSV sont
#' portes en attributs, et le document qui en use les cite.
#'
#' Chaque ligne donne, pour un taxon (`cd_nom`, `cd_ref`) et un departement
#' (`cd_dept`), un code de sensibilite de 1 a 3, sa duree en annees depuis
#' l'observation (`duree`), les conditions qui la restreignent
#' (`statut_biologique`, `comportement`, `autre`) et la liste regionale dont
#' elle vient (`cd_sens_mtd`).
#'
#' @param chemin Le fichier `RefSensibilite_<version>.csv`, ou l'archive
#'   `SENSIBILITE.zip` qui le contient.
#'
#' @return Un `data.frame` aux colonnes en minuscules, portant les attributs
#'   `version`, `empreinte` (SHA-256 du CSV) et `fichier`.
#'
#' @seealso [sommier_registre_quarto()]
#'
#' @examples
#' # Le fichier se telecharge depuis l'INPN :
#' # ref <- sommier_sensibilite("SENSIBILITE.zip")
#' # attr(ref, "version")
#'
#' @export
sommier_sensibilite <- function(chemin) {
  chemin <- valider_texte(chemin, "chemin")
  if (!file.exists(chemin)) {
    stop("Fichier introuvable : ", chemin, ".", call. = FALSE)
  }
  if (identical(tolower(tools::file_ext(chemin)), "zip")) {
    noms <- utils::unzip(chemin, list = TRUE)$Name
    csv <- grep("RefSensibilite_[0-9]+\\.csv$", noms, value = TRUE)
    if (length(csv) != 1L) {
      stop("L'archive ne contient pas un et un seul fichier ",
           "RefSensibilite_<version>.csv.", call. = FALSE)
    }
    dossier <- tempfile("sensibilite-")
    dir.create(dossier)
    on.exit(unlink(dossier, recursive = TRUE), add = TRUE)
    utils::unzip(chemin, files = csv, exdir = dossier, junkpaths = TRUE)
    chemin <- file.path(dossier, basename(csv))
  }
  ref <- utils::read.csv(chemin, colClasses = "character",
                         encoding = "UTF-8", na.strings = "")
  names(ref) <- tolower(names(ref))
  attendues <- c("nom_cite", "cd_nom", "cd_ref", "cd_sensibilite", "duree",
                 "cd_dept")
  manquantes <- setdiff(attendues, names(ref))
  if (length(manquantes) > 0L) {
    stop("Ce n'est pas le referentiel de sensibilite de l'INPN : colonnes ",
         "absentes (", paste(manquantes, collapse = ", "), ").", call. = FALSE)
  }
  for (n in c("cd_nom", "cd_ref", "cd_sensibilite", "duree")) {
    ref[[n]] <- suppressWarnings(as.integer(ref[[n]]))
  }
  version <- sub("^RefSensibilite_([0-9]+)\\.csv$", "\\1", basename(chemin))
  attr(ref, "version") <- if (identical(version, basename(chemin)))
    NA_character_ else version
  attr(ref, "empreinte") <- empreinte_hex(as.raw(openssl::sha256(file(chemin))))
  attr(ref, "fichier") <- basename(chemin)
  ref
}

# Codes de sensibilite du SINP et diffusion de la localisation : 1 commune,
# 2 maille 10 x 10 km, 3 departement (referentiel de Bretagne v1.1, 2019,
# p. 7 ; guide SINP des donnees sensibles v2.0, 2022, p. 8). Le niveau 4,
# aucune diffusion, n'est dans aucune liste : il sert ici a l'espece qu'on
# ne peut juger faute de referentiel.
SOMMIER_FLOUTAGE_SINP <- c(
  `1` = "commune", `2` = "maille 10 km", `3` = "departement",
  `4` = "aucune diffusion"
)

# Le niveau de sensibilite de chaque fiche espece localisee. Une espece se
# reconnait a son cd_nom (contre CD_NOM ou CD_REF) ou, sans cd_nom, a son
# binome latin (contre NOM_CITE). Une sensibilite dont la duree est echue a
# la date d'edition tombe. Les conditions (statut biologique, comportement)
# ne sont pas lues : le payload ne les porte pas, et dans le doute on floute.
# Sans departement, la plus forte sensibilite, tous departements confondus.
sensibilite_des_ecritures <- function(ecritures, sensibilite, departement,
                                      date_edition) {
  vide <- data.frame(seq = numeric(0), niveau = integer(0))
  if (nrow(ecritures) == 0L) {
    return(vide)
  }
  candidates <- which(ecritures$registre == 9L)
  payloads <- lapply(ecritures$payload[candidates], jsonlite::fromJSON,
                     simplifyVector = FALSE)
  especes <- vapply(payloads, function(p) identical(p$type_fiche, "espece"),
                    logical(1))
  candidates <- candidates[especes]
  payloads <- payloads[especes]
  if (length(candidates) == 0L) {
    return(vide)
  }
  if (is.null(sensibilite)) {
    return(data.frame(seq = ecritures$seq[candidates], niveau = 4L))
  }
  binome <- function(x) tolower(sub("^(\\S+\\s+\\S+).*$", "\\1", trimws(x)))
  ref <- sensibilite
  if (!est_vide(departement)) {
    ref <- ref[!is.na(ref$cd_dept) & ref$cd_dept == departement, ,
               drop = FALSE]
  }
  cites <- binome(ref$nom_cite)
  niveaux <- vapply(seq_along(candidates), function(k) {
    p <- payloads[[k]]
    cd <- suppressWarnings(as.integer(p$cd_nom %||% NA))
    lignes <- if (!is.na(cd)) {
      (!is.na(ref$cd_nom) & ref$cd_nom == cd) |
        (!is.na(ref$cd_ref) & ref$cd_ref == cd)
    } else {
      cites == binome(p$nom_latin %||% "")
    }
    age <- as.numeric(as.Date(date_edition) -
                        as.Date(ecritures$date_evenement[[candidates[[k]]]])) /
      365.25
    lignes <- lignes & (is.na(ref$duree) | age < ref$duree)
    codes <- ref$cd_sensibilite[lignes]
    codes <- codes[!is.na(codes)]
    if (length(codes) == 0L) 0L else as.integer(max(codes))
  }, integer(1))
  data.frame(seq = ecritures$seq[candidates], niveau = niveaux)
}

# Le floutage, a public = TRUE : une localisation sensible quitte le croquis
# et sa fiche dit seulement a quelle echelle elle est diffusee. L'unite de
# gestion et le libelle de localisation disent plus que la commune : ils
# sont tus aussi.
flouter_sensibles <- function(sommier, sensibilite, departement,
                              date_edition) {
  niveaux <- sensibilite_des_ecritures(sommier$ecritures, sensibilite,
                                       departement, date_edition)
  niveaux <- niveaux[niveaux$niveau > 0L, , drop = FALSE]
  if (nrow(niveaux) == 0L) {
    return(sommier)
  }
  masque <- "(flout\u00e9e)"
  e <- sommier$ecritures
  for (i in which(e$seq %in% niveaux$seq)) {
    p <- jsonlite::fromJSON(e$payload[[i]], simplifyVector = FALSE)
    if (!is.null(p$localisation)) {
      p$localisation <- masque
    }
    e$payload[[i]] <- as.character(jsonlite::toJSON(
      p, auto_unbox = TRUE, null = "null", digits = NA
    ))
    e$contenu[[i]] <- contenu_generique(p)
    e$ug[[i]] <- NA_character_
  }
  sommier$ecritures <- e

  o <- sommier$croquis$objets
  if (!is.null(o) && nrow(o) > 0L) {
    for (i in which(o$seq %in% niveaux$seq)) {
      niveau <- niveaux$niveau[niveaux$seq == o$seq[[i]]][[1L]]
      o$floutage[[i]] <- switch(
        as.character(niveau),
        `1` = "\u00e0 la commune",
        `2` = sprintf("\u00e0 la maille 10kmL93E%03dN%03d",
                      as.integer(floor(o$x_l93[[i]] / 10000)),
                      as.integer(floor(o$y_l93[[i]] / 10000))),
        `3` = paste0("au d\u00e9partement",
                     if (!est_vide(departement)) paste0(" (", departement, ")")),
        "non diffus\u00e9e"
      )
      o$floutage[[i]] <- paste0(o$floutage[[i]], " (", if (niveau == 4L)
        "aucun r\u00e9f\u00e9rentiel de sensibilit\u00e9 fourni" else
          paste0("sensibilit\u00e9 SINP ", niveau), ")")
      o$localisation[[i]] <- "floutee"
      o$wkt[[i]] <- NA_character_
      o$ug[[i]] <- NA_character_
      o$ug_uuid[[i]] <- NA_character_
      o$contour_version[[i]] <- NA_integer_
      o$contour_en_vigueur[[i]] <- NA
      o$precision_m[[i]] <- NA_real_
      o$x_l93[[i]] <- NA_real_
      o$y_l93[[i]] <- NA_real_
    }
    sommier$croquis$objets <- o
  }
  sommier
}
