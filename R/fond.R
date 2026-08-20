#' Couches du fond cadastral
#'
#' @description
#' Ce que les livraisons publiques du cadastre exposent reellement, verifie le
#' 20 aout 2026 sur `cadastre.data.gouv.fr` : parcelles, sections, batiments,
#' lieux-dits, feuilles, prefixes de section et subdivisions fiscales.
#'
#' @details
#' **Ce que ces livraisons ne portent pas.** Ni bornes, ni fosses, ni aucun
#' objet topographique ponctuel ou lineaire. Ceux-la figurent dans la forme
#' EDIGEO du Plan Cadastral Informatise, publiee sur le meme site mais dans un
#' autre jeu de donnees (`dgfip-pci-vecteur`), par feuille cadastrale et dans
#' un format qui demande le pilote EDIGEO de GDAL. Elle n'est donc pas hors
#' d'atteinte : elle est hors de ce que ce paquet va chercher aujourd'hui.
#'
#' Et quand bien meme on l'irait chercher, une borne relevee par la DGFiP reste
#' la donnee d'un tiers. Ce qui fait foi dans un sommier, c'est le **constat du
#' gestionnaire** - registre 2 pour le foncier, registre 4 pour les
#' infrastructures - saisi avec sa geometrie (voir [geometries]) et chaine avec
#' le reste.
#'
#' @export
SOMMIER_COUCHES_CADASTRE <- c("parcelles", "sections", "batiments",
                              "lieux_dits", "feuilles")

SOMMIER_SOURCE_CADASTRE <- "https://cadastre.data.gouv.fr/data/etalab-cadastre"

#' Fond cadastral d'une commune
#'
#' @description
#' Telecharge et met en cache une couche du cadastre pour une commune. Le
#' fichier obtenu sert de fond de plan aux cartes du sommier.
#'
#' @details
#' **Le cadastre n'est pas une ecriture du sommier.** Rien de ce qui est
#' telecharge ici n'entre dans un registre, dans une empreinte ou dans un
#' manifeste : ce serait faire passer la donnee d'un tiers pour un constat du
#' gestionnaire, exactement ce que le registre existe pour empecher. Le fond
#' est un decor, date et source ; sa perte n'affecte rien.
#'
#' **Le telechargement est explicite.** Ni le rapport ni un export ne
#' declenchent d'appel reseau : un document de gestion doit pouvoir s'engendrer
#' sur un poste hors ligne. C'est l'appelant qui va chercher le fond, une fois,
#' et le passe ensuite a [sommier_rapport_quarto()].
#'
#' Le millesime est lu sur le serveur et conserve avec le fichier. Un fond sans
#' millesime induit en erreur des l'annee suivante - le parcellaire bouge.
#'
#' @param code_insee Code INSEE de la commune, sur cinq caracteres.
#' @param couche L'une de [SOMMIER_COUCHES_CADASTRE].
#' @param cache Repertoire de cache (defaut : le repertoire de cache de
#'   l'utilisateur pour ce paquet).
#' @param force Retelecharger meme si le fichier est deja en cache.
#'
#' @return Invisiblement, un objet `sommier_fond` : `chemin`, `code_insee`,
#'   `couche`, `millesime`, `source`, `telecharge_le`.
#'
#' @seealso [sommier_fond_lire()]
#'
#' @examples
#' # Necessite un acces reseau :
#' # fond <- sommier_fond_cadastral("21200")
#'
#' @export
sommier_fond_cadastral <- function(code_insee, couche = "parcelles",
                                   cache = NULL, force = FALSE) {
  code_insee <- valider_code_insee(code_insee)
  couche <- valider_choix(couche, "couche", SOMMIER_COUCHES_CADASTRE)
  cache <- repertoire_cache(cache)

  departement <- substr(code_insee, 1L, 2L)
  fichier <- sprintf("cadastre-%s-%s.json.gz", code_insee, couche)
  chemin <- file.path(cache, fichier)

  millesime <- NA_character_
  if (isTRUE(force) || !file.exists(chemin)) {
    dossier <- sprintf("%s/latest/geojson/communes/%s/%s/",
                       SOMMIER_SOURCE_CADASTRE, departement, code_insee)
    millesime <- millesime_publie(dossier)
    telecharger(paste0(dossier, fichier), chemin)
    writeLines(millesime, paste0(chemin, ".millesime"))
  } else if (file.exists(paste0(chemin, ".millesime"))) {
    millesime <- readLines(paste0(chemin, ".millesime"), warn = FALSE)[[1L]]
  }

  structure(
    list(chemin = chemin, code_insee = code_insee, couche = couche,
         millesime = millesime, source = SOMMIER_SOURCE_CADASTRE,
         telecharge_le = format(file.info(chemin)$mtime, "%d/%m/%Y")),
    class = "sommier_fond"
  )
}

#' @export
print.sommier_fond <- function(x, ...) {
  cat("<fond cadastral>\n")
  cat("  commune   : ", x$code_insee, "\n", sep = "")
  cat("  couche    : ", x$couche, "\n", sep = "")
  cat("  millesime : ", if (is.na(x$millesime)) "inconnu" else x$millesime,
      "\n", sep = "")
  cat("  cache     : ", x$chemin, "\n", sep = "")
  invisible(x)
}

#' Lecture d'un fond cadastral
#'
#' @description
#' Lit un fond telecharge par [sommier_fond_cadastral()] et le restreint a
#' l'emprise de la foret.
#'
#' @details
#' On ne retient que ce qui intersecte l'emprise tamponnee, et non tout le
#' territoire communal : Couchey compte pres de trois mille parcelles, une
#' foret n'en couvre qu'une poignee, et un fond illisible ne renseigne
#' personne.
#'
#' La sortie est en Lambert-93, comme les couches du sommier : une carte se
#' mesure en metres, et melanger deux systemes sur le meme dessin les
#' decalerait.
#'
#' @param fond Objet `sommier_fond`.
#' @param emprise Couche des unites de gestion ([sommier_couche_ug()]), ou tout
#'   `data.frame` portant une colonne `wkt` en Lambert-93. `NULL` : toute la
#'   commune.
#' @param marge_m Marge autour de l'emprise, en metres. Une foret collee au
#'   bord de sa carte se lit mal.
#'
#' @return Un `data.frame` : `reference`, `section`, `numero`, `contenance_m2`,
#'   `wkt` (Lambert-93), portant les attributs `source` et `millesime`.
#'
#' @examples
#' # Necessite `sf` et un fond telecharge :
#' # sommier_fond_lire(fond, emprise = couche)
#'
#' @export
sommier_fond_lire <- function(fond, emprise = NULL, marge_m = 100) {
  if (!inherits(fond, "sommier_fond")) {
    stop("`fond` doit venir de sommier_fond_cadastral().", call. = FALSE)
  }
  if (!requireNamespace("sf", quietly = TRUE)) {
    stop("Le paquet `sf` est requis pour lire un fond cadastral.",
         call. = FALSE)
  }
  if (!file.exists(fond$chemin)) {
    stop("Fond absent du cache : ", fond$chemin, ". Le retelecharger avec ",
         "sommier_fond_cadastral().", call. = FALSE)
  }
  marge_m <- valider_nombre(marge_m, "marge_m", min = 0)

  # `/vsigzip/` : GDAL lit l'archive sans qu'on la decompresse sur disque,
  # ce qui evite de doubler le cache et de laisser trainer un temporaire.
  couche <- sf::read_sf(paste0("/vsigzip/", normalizePath(fond$chemin)))
  couche <- sf::st_transform(couche, 2154)

  if (!is.null(emprise) && nrow(emprise) > 0L && !is.null(emprise$wkt)) {
    boite <- sf::st_bbox(sf::st_as_sfc(emprise$wkt, crs = 2154))
    boite <- sf::st_as_sfc(boite)
    couche <- couche[sf::st_intersects(couche, sf::st_buffer(boite, marge_m),
                                       sparse = FALSE)[, 1L], , drop = FALSE]
  }

  resultat <- data.frame(
    reference     = couche$id %||% NA_character_,
    section       = couche$section %||% NA_character_,
    numero        = couche$numero %||% NA_character_,
    contenance_m2 = suppressWarnings(as.numeric(couche$contenance %||% NA)),
    wkt           = sf::st_as_text(sf::st_geometry(couche)),
    stringsAsFactors = FALSE
  )
  attr(resultat, "source") <- fond$source
  attr(resultat, "millesime") <- fond$millesime
  resultat
}

# ---------------------------------------------------------------------------

valider_code_insee <- function(x) {
  x <- trimws(as.character(x))
  # Les communes de Corse portent 2A ou 2B en tete : un motif purement
  # numerique les exclurait, et l'erreur ne se verrait qu'a l'usage.
  if (length(x) != 1L || !grepl("^([0-9]{2}|2[AB])[0-9]{3}$", x)) {
    stop("`code_insee` doit etre un code communal sur cinq caracteres, ",
         "recu : ", paste(x, collapse = ", "), ".", call. = FALSE)
  }
  x
}

repertoire_cache <- function(cache) {
  if (est_vide(cache)) {
    cache <- tools::R_user_dir("sommieR", "cache")
  }
  if (!dir.exists(cache)) {
    dir.create(cache, recursive = TRUE)
  }
  cache
}

# Le millesime n'est pas dans le fichier : il est dans le chemin vers lequel
# `latest` redirige. On le lit sur l'index du dossier, et son absence se dit
# plutot que de se deviner - un fond date a tort vaut moins qu'un fond non
# date.
millesime_publie <- function(dossier) {
  index <- try(
    suppressWarnings(readLines(dossier, warn = FALSE, n = 40L)),
    silent = TRUE
  )
  if (inherits(index, "try-error")) {
    return(NA_character_)
  }
  trouve <- regmatches(
    paste(index, collapse = " "),
    regexpr("etalab-cadastre/[0-9]{4}-[0-9]{2}-[0-9]{2}/",
            paste(index, collapse = " "))
  )
  if (length(trouve) == 0L) {
    return(NA_character_)
  }
  substr(trouve, 17L, 26L)
}

telecharger <- function(url, destination) {
  resultat <- try(
    utils::download.file(url, destination, mode = "wb", quiet = TRUE),
    silent = TRUE
  )
  if (inherits(resultat, "try-error") || !file.exists(destination) ||
      file.info(destination)$size == 0L) {
    unlink(destination)
    stop("Telechargement du fond cadastral impossible : ", url,
         "\nVerifier l'acces reseau, ou fournir le fichier au cache a la main.",
         call. = FALSE)
  }
  invisible(destination)
}
