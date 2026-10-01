# Extracted from test-detections-db.R:166

# prequel ----------------------------------------------------------------------
base_detections <- function(env = parent.frame()) {
  con <- sauter_sans_base()
  withr::defer(DBI::dbDisconnect(con), envir = env)
  sommier_init_schema(con)
  con
}
foret_detections <- function(con) {
  foret <- foret_creer(con, paste0("Foret detections-", substr(uuid_v4(), 1L, 8L)),
                       "domanial")
  ug <- ug_creer(con, foret, "12", "2010-01-01")
  DBI::dbExecute(
    con,
    "INSERT INTO ug_geometrie (ug_uuid, version, geom, source, date_debut)
     VALUES ($1, 1, ST_Multi(ST_GeomFromText('POLYGON((600000 6700000,
       600300 6700000, 600300 6700200, 600000 6700200, 600000 6700000))',
       2154)), 'test', '2010-01-01')",
    params = list(ug)
  )
  reconfort <- sommier_importer_detections(
    con, foret, list(list(nature = "crise_sanitaire", ug_uuid = ug,
                          description = "Deperissement du chene",
                          date_evenement = "2026-07-14", surface_ha = 1)),
    source = "reconfort", ndp = 1L, auteur = "chaine-reconfort"
  )
  sufosat <- sommier_importer_detections(
    con, foret, list(list(nature = "autre", ug_uuid = ug,
                          description = "Coupe rase",
                          date_evenement = "2019-08-28", surface_ha = 0.5)),
    source = "sufosat", ndp = 1L, auteur = "chaine-sufosat"
  )
  list(foret = foret, ug = ug, reconfort = reconfort[[1L]]$id,
       sufosat = sufosat[[1L]]$id)
}
raster_carre <- function(xmin, ymin, xmax, ymax, valeur, fond = 0,
                         env = parent.frame()) {
  skip_if_not_installed("sf")
  gpkg <- withr::local_tempfile(fileext = ".gpkg", .local_envir = env)
  carre <- sf::st_polygon(list(rbind(c(xmin, ymin), c(xmax, ymin),
                                     c(xmax, ymax), c(xmin, ymax),
                                     c(xmin, ymin))))
  sf::st_write(sf::st_sf(v = 1, geometry = sf::st_sfc(carre, crs = 2154)),
               gpkg, quiet = TRUE)
  tif <- withr::local_tempfile(fileext = ".tif", .local_envir = env)
  sf::gdal_utils("rasterize", gpkg, tif, options = c(
    "-burn", valeur, "-init", fond, "-a_nodata", "0", "-tr", "10", "10",
    "-te", "599900", "6699900", "600400", "6700300", "-ot", "Int32"))
  tif
}
constat_detection <- function(uuid, detection_id, etat, nature, x, y,
                              visite = "2026-10-14 10:00:00") {
  sf::st_sf(uuid = uuid, detection_id = detection_id, etat = etat,
            nature = nature, surface_ha = NA_real_, volume_m3 = NA_real_,
            visite_le = as.POSIXct(visite, tz = "UTC"), operateur = "P. O.",
            precision_m = 3, source_gnss = "interne",
            observations = NA_character_,
            geometry = sf::st_sfc(sf::st_point(c(x, y)), crs = 2154))
}
saisir_constats <- function(dossier, constats) {
  sf::st_write(constats, file.path(dossier, "detections.gpkg"),
               layer = "constats", append = TRUE, quiet = TRUE)
}

# test -------------------------------------------------------------------------
con <- base_detections()
f <- foret_detections(con)
reconfort <- raster_carre(600050, 6700050, 600150, 6700150, 3, fond = 1)
dossier <- file.path(withr::local_tempdir(), "detections")
qgs <- sommier_projet_qfield_detections(con, f$foret, dossier, "P. & O.",
                                          reconfort = reconfort)
expect_true(file.exists(qgs))
expect_true(dir.exists(file.path(dossier, "DCIM")))
expect_error(sommier_projet_qfield_detections(con, f$foret, dossier, "P. O."),
               "existe deja")
xml <- paste(readLines(qgs, encoding = "UTF-8"), collapse = "\n")
expect_no_match(xml, "@@|111111")
d <- sf::read_sf(file.path(dossier, "detections.gpkg"), "detections")
expect_equal(nrow(d), 2L)
expect_equal(d$numero, c("D01", "D02"))
expect_equal(d$id, c(f$sufosat, f$reconfort))
