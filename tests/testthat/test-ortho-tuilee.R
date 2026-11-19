# L'ortho de la tournee des travaux : un MBTiles en EPSG:3857, zooms 12 a 18,
# avec attribution et date_mise_a_jour (briefs 2026-10-27 et 2026-10-29).

faire_ortho_test <- function(dossier) {
  skip_if_not_installed("sf")
  skip_if_not_installed("RSQLite")
  skip_if(!"MBTiles" %in% sf::st_drivers("raster")$name,
          "Le GDAL local n'ecrit pas de MBTiles.")
  # Une image PPM 300 x 300 (octets au hasard), calee en Lambert-93 a 1 m.
  ppm <- file.path(dossier, "source.ppm")
  con <- file(ppm, "wb")
  writeBin(charToRaw("P6\n300 300\n255\n"), con)
  writeBin(as.raw(sample(0:255, 300L * 300L * 3L, replace = TRUE)), con)
  close(con)
  chemin <- file.path(dossier, "source.tif")
  sf::gdal_utils("translate", ppm, chemin, quiet = TRUE,
                 options = c("-a_srs", "EPSG:2154", "-a_ullr", "600000",
                             "6700300", "600300", "6700000"))
  Sys.setFileTime(chemin, as.POSIXct("2026-10-27 12:00:00", tz = "UTC"))
  chemin
}

lire_meta <- function(mbtiles) {
  base <- DBI::dbConnect(RSQLite::SQLite(), mbtiles)
  on.exit(DBI::dbDisconnect(base))
  m <- DBI::dbGetQuery(base, "SELECT name, value FROM metadata")
  stats::setNames(m$value, m$name)
}

test_that("l'ortho est tuilee en 3857, zooms 12 a 18, avec ses metadonnees", {
  d <- withr::local_tempdir()
  src <- faire_ortho_test(d)
  sortie <- file.path(d, "ortho.mbtiles")
  ecrire_ortho_tuilee(src, sortie)
  expect_true(file.exists(sortie))
  meta <- lire_meta(sortie)
  expect_equal(meta[["attribution"]], SOMMIER_ATTRIBUTION_ORTHO)
  expect_match(meta[["attribution"]], "IGN")
  expect_match(meta[["attribution"]], "Licence Ouverte")
  expect_equal(meta[["date_mise_a_jour"]], "2026-10-27")
  # Zooms 12 a 18, meme pour une emprise de 300 m.
  expect_equal(meta[["maxzoom"]], "18")
  expect_equal(meta[["minzoom"]], "12")
  base <- DBI::dbConnect(RSQLite::SQLite(), sortie)
  on.exit(DBI::dbDisconnect(base))
  z <- DBI::dbGetQuery(base,
    "SELECT MIN(zoom_level) AS a, MAX(zoom_level) AS b FROM tiles")
  expect_equal(z$b, 18)
  expect_equal(z$a, 12)
  # Les tuiles couvrent la zone de la source (vers 1,67 E 47,39 N) :
  # la colonne du zoom 18 est celle de la longitude, la ligne est TMS (comptee
  # depuis le sud : 2^18 - 1 - y_xyz).
  t18 <- DBI::dbGetQuery(base,
    "SELECT tile_column AS x, tile_row AS y FROM tiles WHERE zoom_level = 18")
  lon <- 1.6760; lat <- 47.3940
  x <- floor((lon + 180) / 360 * 2^18)
  y_xyz <- floor((1 - log(tan(lat * pi / 180) + 1 / cos(lat * pi / 180)) / pi)
                 / 2 * 2^18)
  expect_true(any(abs(t18$x - x) <= 3 & abs(t18$y - (2^18 - 1 - y_xyz)) <= 3))
  info <- sf::gdal_utils("info", sortie, quiet = TRUE)
  expect_match(info, "3857")
  # Hors emprise, une tuile du zoom 12 est transparente (alpha 0), pas noire
  # et opaque : la tuile en PNG a un canal alpha dont le minimum est 0.
  blob <- DBI::dbGetQuery(base,
    "SELECT tile_data FROM tiles WHERE zoom_level = 12 LIMIT 1")$tile_data[[1L]]
  png <- file.path(d, "z12.png")
  writeBin(blob, png)
  stat <- jsonlite::fromJSON(sf::gdal_utils("info", png, quiet = TRUE,
                                            options = c("-json", "-stats")))
  expect_equal(nrow(stat$bands), 4L)
  expect_equal(stat$bands$minimum[[4L]], 0)
  expect_equal(stat$bands$maximum[[4L]], 255)
})

test_that("la date de mise a jour se donne, et se controle", {
  d <- withr::local_tempdir()
  src <- faire_ortho_test(d)
  sortie <- file.path(d, "o.mbtiles")
  ecrire_ortho_tuilee(src, sortie, date_mise_a_jour = "2026-11-01",
                      attribution = "Source X", zooms = c(16L, 18L))
  meta <- lire_meta(sortie)
  expect_equal(meta[["date_mise_a_jour"]], "2026-11-01")
  expect_equal(meta[["attribution"]], "Source X")
  expect_error(ecrire_ortho_tuilee(src, file.path(d, "p.mbtiles"),
                                   date_mise_a_jour = "1er novembre"),
               "AAAA-MM-JJ")
  expect_false(file.exists(file.path(d, "p.mbtiles")))
})

test_that("une source illisible n'ecrit rien", {
  d <- withr::local_tempdir()
  skip_if_not_installed("RSQLite")
  skip_if_not_installed("sf")
  bidon <- file.path(d, "bidon.tif")
  writeLines("pas une image", bidon)
  expect_error(ecrire_ortho_tuilee(bidon, file.path(d, "o.mbtiles")),
               "tuiler")
  expect_false(file.exists(file.path(d, "o.mbtiles")))
})

test_that("le projet des travaux lit ortho.mbtiles, pas ortho.tif", {
  qgs <- readLines(system.file("qgis", "travaux.qgs", package = "sommieR"),
                   encoding = "UTF-8")
  expect_true(any(grepl("./ortho.mbtiles", qgs, fixed = TRUE)))
  expect_false(any(grepl("ortho.tif", qgs, fixed = TRUE)))
  i <- grep("<id>travaux_ortho</id>", qgs, fixed = TRUE)
  expect_true(any(grepl("EPSG:3857", qgs[i:(i + 12L)], fixed = TRUE)))
})

test_that("joindre_ortho tuile pour les travaux et copie pour les autres", {
  d <- withr::local_tempdir()
  src <- faire_ortho_test(d)
  dest <- file.path(d, "t")
  dir.create(dest)
  joindre_ortho("inutile.qgs", dest, src, "travaux_ortho", tuilee = TRUE)
  expect_true(file.exists(file.path(dest, "ortho.mbtiles")))
  expect_false(file.exists(file.path(dest, "ortho.tif")))
  dest2 <- file.path(d, "l")
  dir.create(dest2)
  joindre_ortho("inutile.qgs", dest2, src, "limites_ortho")
  expect_true(file.exists(file.path(dest2, "ortho.tif")))
})
