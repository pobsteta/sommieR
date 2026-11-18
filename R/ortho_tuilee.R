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
# l'appelant la donne : le service ne dit pas la date de prise de vue.
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
  # zoom le plus proche de la resolution de la source. On cale donc la source
  # sur la grille du zoom le plus fin (resolution de la carte du monde en
  # 3857 divisee par 2^zoom), puis les pyramides descendent les zooms
  # inferieurs - jusqu'a ce que l'emprise ne tienne plus qu'en une tuile,
  # d'ou un zoom minimal parfois superieur a 12 pour une petite emprise.
  pas <- 156543.03392804097 / 2^zooms[[2L]]
  fin <- tempfile(fileext = ".tif")
  on.exit(unlink(fin), add = TRUE)
  niveaux <- 2L^seq_len(zooms[[2L]] - zooms[[1L]])
  fait <- try({
    sf::gdal_utils("warp", ortho, fin, quiet = TRUE,
                   options = c("-t_srs", "EPSG:3857", "-tr", pas, pas,
                               "-r", "bilinear", "-of", "GTiff",
                               "-dstalpha"))
    sf::gdal_utils("translate", fin, chemin, quiet = TRUE,
                   options = c("-of", "MBTILES", "-co", "TILE_FORMAT=JPEG",
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
