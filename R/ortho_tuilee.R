# L'ortho de la tournee des travaux : un seul fichier tuile, en Web Mercator
# (EPSG:3857), que QField et Surculus lisent sans reseau (briefs
# `2026-10-27-ortho-tuilee-3857` et `2026-10-29-ortho-metadonnees`). C'est un
# MBTiles, donc en TMS (lignes comptees depuis le sud) : le GDAL de `sf` l'ecrit
# ainsi. Zooms 12 a 18, ceux que Groma precharge.
SOMMIER_ZOOMS_ORTHO <- c(12L, 18L)

# u00a9 et u00ae : le code reste en ASCII.
SOMMIER_ATTRIBUTION_ORTHO <- paste0(
  "\u00a9 IGN, BD ORTHO\u00ae, G\u00e9oplateforme, Licence Ouverte 2.0")

# Convertit une ortho (GeoTIFF, Lambert-93 ou autre) en `ortho.mbtiles`. La
# table `metadata` recoit `attribution` (cle de la specification MBTiles 1.3)
# et `date_mise_a_jour`, AAAA-MM-JJ (convention sommieR/Surculus, hors norme).
# La date est celle du GeoTIFF - le jour ou l'ortho a ete telechargee - sauf si
# l'appelant la donne : le service ne dit pas la date de prise de vue. (La date
# de modification est celle du telechargement tant que le GeoTIFF n'est ni
# copie ni retouche ; `sommier_ortho_ign()` n'a pas de canal pour la
# transmettre autrement.)
ecrire_ortho_tuilee <- function(ortho, chemin,
                                zooms = SOMMIER_ZOOMS_ORTHO,
                                attribution = SOMMIER_ATTRIBUTION_ORTHO,
                                date_mise_a_jour = NULL) {
  if (!requireNamespace("sf", quietly = TRUE) ||
      !requireNamespace("RSQLite", quietly = TRUE)) {
    stop("Les paquets `sf` et `RSQLite` sont requis pour tuiler l'ortho.",
         call. = FALSE)
  }
  if (is.null(date_mise_a_jour)) {
    date_mise_a_jour <- format(as.Date(file.mtime(ortho)), "%Y-%m-%d")
  }
  if (!grepl("^[0-9]{4}-[0-9]{2}-[0-9]{2}$", date_mise_a_jour) ||
      is.na(as.Date(date_mise_a_jour, optional = TRUE))) {
    stop("`date_mise_a_jour` doit etre une date AAAA-MM-JJ.", call. = FALSE)
  }
  # Le pilote MBTiles de GDAL ignore MINZOOM/MAXZOOM a la copie : il prend le
  # zoom le plus proche de la resolution de la source, et gdaladdo s'arrete
  # quand l'image tient dans une tuile. On cale donc la source sur la grille
  # du zoom le plus fin (resolution de la carte du monde en 3857 divisee par
  # 2^zoom) ET son emprise sur les tuiles du zoom le plus grossier qui la
  # couvrent (fond transparent) : les pyramides descendent alors jusqu'a ce
  # zoom. Les tuiles entierement vides ne sont pas ecrites. Tuiles en PNG :
  # MBTiles n'a pas de mode JPEG/PNG automatique, et en JPEG le fond hors
  # emprise serait noir et opaque.
  monde <- 2 * 20037508.342789244
  pas <- monde / 256 / 2^zooms[[2L]]
  cote <- monde / 2^zooms[[1L]]
  fin <- tempfile(fileext = ".tif")
  on.exit(unlink(fin), add = TRUE)
  niveaux <- 2L^seq_len(zooms[[2L]] - zooms[[1L]])
  fait <- try({
    boite <- emprise_3857(ortho)
    te <- c(floor((boite[[1L]] + monde / 2) / cote),
            floor((boite[[2L]] + monde / 2) / cote),
            ceiling((boite[[3L]] + monde / 2) / cote),
            ceiling((boite[[4L]] + monde / 2) / cote)) * cote - monde / 2
    sf::gdal_utils("warp", ortho, fin, quiet = TRUE,
                   options = c("-t_srs", "EPSG:3857", "-tr", pas, pas,
                               "-te", trimws(format(te, nsmall = 3L, scientific = FALSE)),
                               "-r", "bilinear", "-of", "GTiff",
                               "-dstalpha", "-co", "TILED=YES",
                               "-co", "COMPRESS=DEFLATE",
                               "-co", "SPARSE_OK=TRUE", "-co", "BIGTIFF=YES"))
    sf::gdal_utils("translate", fin, chemin, quiet = TRUE,
                   options = c("-of", "MBTILES", "-co", "TILE_FORMAT=PNG",
                               "-co", "NAME=ortho", "-co", "TYPE=baselayer"))
    sf::gdal_addo(chemin, method = "average", overviews = niveaux)
  }, silent = TRUE)
  if (inherits(fait, "try-error") || !file.exists(chemin)) {
    unlink(chemin)
    stop("Impossible de tuiler l'ortho : ",
         if (inherits(fait, "try-error")) {
           conditionMessage(attr(fait, "condition"))
         }, call. = FALSE)
  }
  unlink(paste0(chemin, ".aux.xml"))
  base <- DBI::dbConnect(RSQLite::SQLite(), chemin)
  on.exit(DBI::dbDisconnect(base), add = TRUE)
  for (cle in c("attribution", "date_mise_a_jour")) {
    DBI::dbExecute(base, "DELETE FROM metadata WHERE name = ?", list(cle))
  }
  DBI::dbExecute(base, "INSERT INTO metadata (name, value) VALUES (?, ?)",
                 list(c("attribution", "date_mise_a_jour"),
                      c(attribution, date_mise_a_jour)))
  invisible(chemin)
}

# Emprise d'une image en EPSG:3857 (xmin, ymin, xmax, ymax), par un warp vers
# un VRT : GDAL fait la reprojection de l'emprise, quel que soit le SCR.
emprise_3857 <- function(ortho) {
  vrt <- tempfile(fileext = ".vrt")
  on.exit(unlink(vrt))
  sf::gdal_utils("warp", ortho, vrt, quiet = TRUE,
                 options = c("-t_srs", "EPSG:3857", "-of", "VRT"))
  info <- jsonlite::fromJSON(sf::gdal_utils("info", vrt, quiet = TRUE,
                                            options = "-json"))
  c(info$cornerCoordinates$lowerLeft, info$cornerCoordinates$upperRight)
}
