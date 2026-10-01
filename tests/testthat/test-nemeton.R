# Ce que nemeton, l'IFN et SUFOSAT apportent a la balance - sans rien
# ecrire dans la chaine.

# Un raster d'essai en Lambert-93, 10 m, ecrit par GDAL depuis une grille
# XYZ : `valeur(x, y)` rend la valeur de chaque pixel.
raster_essai <- function(valeur, x0 = 600000, y0 = 6700000, n = 20L,
                         env = parent.frame()) {
  xyz <- withr::local_tempfile(fileext = ".xyz", .local_envir = env)
  tif <- withr::local_tempfile(fileext = ".tif", .local_envir = env)
  centres <- expand.grid(x = x0 + 5 + 10 * (seq_len(n) - 1L),
                         y = rev(y0 + 5 + 10 * (seq_len(n) - 1L)))
  centres <- centres[order(-centres$y, centres$x), ]
  centres$v <- mapply(valeur, centres$x, centres$y)
  utils::write.table(centres, xyz, row.names = FALSE, col.names = FALSE)
  sf::gdal_utils("translate", xyz, tif, quiet = TRUE,
                 options = c("-a_srs", "EPSG:2154", "-ot", "UInt32"))
  tif
}

test_that("le numero de parcelle se lit a la fin du libelle, ou pas du tout", {
  expect_equal(numero_du_libelle(c(
    "Forêt domaniale d'Orléans — parcelle 1039",
    "Parcelle 12a", "Unite sans numero", NA
  )), c("1039", "12a", NA, NA))
})

test_that("la reference IFN se valide", {
  ref <- valider_reference_ifn(list(taux_m3_ha_an = 2.28, ser = "B70",
                                    nom = "Sologne-Orleanais"))
  expect_equal(ref$taux_m3_ha_an, 2.28)
  expect_null(valider_reference_ifn(NULL))
  expect_error(valider_reference_ifn(list(ser = "B70")), "taux_m3_ha_an")
  expect_error(valider_reference_ifn(list(taux_m3_ha_an = -1)), "taux")
})

test_that("les indices d'un projet nemeton se lisent par unite", {
  skip_if_not_installed("arrow")
  projet <- withr::local_tempdir()
  dir.create(file.path(projet, "data"))
  arrow::write_parquet(data.frame(
    ug_id = c("ug_1", "ug_2"),
    label = c("Foret d'essai — parcelle 1039", "Foret d'essai — parcelle 1040"),
    surface_m2 = c(31400, 76700),
    indicateur_p1_volume = c(0, 424.25),
    indicateur_t3_coupes_rases = c(0, 0),
    cadastral_refs = c("451880000B0007", "451880000B0006"),
    autre = 1
  ), file.path(projet, "data", "indicators.parquet"))

  ind <- sommier_lire_indices_nemeton(projet)
  expect_equal(ind$numero, c("1039", "1040"))
  expect_equal(ind$surface_ha, c(3.14, 7.67))
  expect_equal(ind$volume_m3_ha, c(0, 424.25))
  expect_s3_class(attr(ind, "date_calcul"), "Date")
  expect_match(attr(ind, "source"), "nemeton")
  expect_error(sommier_lire_indices_nemeton(withr::local_tempdir()),
               "indicators.parquet")
})

test_that("SUFOSAT s'agrege par unite et par annee, les miettes ecartees", {
  skip_if_not_installed("sf")
  # Un bloc de 8 x 8 pixels coupe en 2018 (jour 200), a 95 % ; une miette de
  # 2 pixels en 2019 ; un pixel a 60 %, sous le seuil.
  dates <- raster_essai(function(x, y) {
    if (x < 600080 && y > 6700120) 18200
    else if (x > 600180 && y < 6700020) 19100
    else if (x > 600100 && x < 600110 && y > 6700100 && y < 6700110) 20050
    else 0
  })
  proba <- raster_essai(function(x, y) {
    if (x > 600100 && x < 600110 && y > 6700100 && y < 6700110) 60 else 95
  })
  unite <- data.frame(
    numero_affichage = "A",
    wkt = paste0("POLYGON((600000 6700000, 600200 6700000, 600200 6700200, ",
                 "600000 6700200, 600000 6700000))"),
    stringsAsFactors = FALSE
  )
  coupes <- sommier_coupes_sufosat(dates, proba, unite, surface_min_ha = 0.05)
  expect_equal(coupes$ug, "A")
  expect_equal(coupes$annee, 2018L)
  expect_equal(coupes$surface_ha, 0.64)
  expect_equal(coupes$date_mediane, as.Date("2018-07-19"))
  expect_equal(attr(coupes, "seuil_proba"), 90)
  # Sans seuil de surface, la miette de 2019 apparait ; le pixel a 60 %,
  # jamais.
  toutes <- sommier_coupes_sufosat(dates, proba, unite, surface_min_ha = 0)
  expect_setequal(toutes$annee, c(2018L, 2019L))
  expect_false(2020L %in% toutes$annee)
})

test_that("la sylvoecoregion se lit dans la couche de l'IGN mise en cache", {
  skip_if_not_installed("sf")
  cache <- withr::local_tempdir()
  dir.create(file.path(cache, "ser"))
  carre <- function(x0) {
    sf::st_polygon(list(rbind(c(x0, 6700000), c(x0 + 1000, 6700000),
                              c(x0 + 1000, 6701000), c(x0, 6701000),
                              c(x0, 6700000))))
  }
  sf::st_write(sf::st_sf(codeser = c("B70", "B61"),
                         NomSER = c("Sologne-Orleanais", "Voisine"),
                         geometry = sf::st_sfc(carre(600000), carre(601000),
                                               crs = 2154)),
               file.path(cache, "ser", "ser_l93.shp"), quiet = TRUE)
  foret <- data.frame(wkt = paste0(
    "POLYGON((600100 6700100, 600500 6700100, 600500 6700500, ",
    "600100 6700500, 600100 6700100))"), stringsAsFactors = FALSE)
  ser <- sommier_ser(foret, cache = cache)
  expect_equal(ser$code, "B70")
  expect_false(ser$plusieurs)
  # Une foret a cheval le dit.
  a_cheval <- data.frame(wkt = paste0(
    "POLYGON((600800 6700100, 601200 6700100, 601200 6700500, ",
    "600800 6700500, 600800 6700100))"), stringsAsFactors = FALSE)
  expect_true(sommier_ser(a_cheval, cache = cache)$plusieurs)
})

test_that("le rapport situe la possibilite et signale la coupe sans martelage", {
  skip_if(!nzchar(Sys.which("quarto")), "Quarto n'est pas installe.")
  skip_if_not_installed("sf")
  con <- sauter_sans_base()
  withr::defer(DBI::dbDisconnect(con))
  sommier_init_schema(con)
  foret <- foret_creer(con, paste0("Foret nemeton-", substr(uuid_v4(), 1, 8)),
                       "domanial")
  unites <- c(A = ug_creer(con, foret, "A", "2010-01-01"),
              B = ug_creer(con, foret, "B", "2010-01-01"))
  for (i in seq_along(unites)) {
    x0 <- 600000 + (i - 1L) * 300
    DBI::dbExecute(con, sprintf(paste0(
      "INSERT INTO ug_geometrie (ug_uuid, version, geom, source, date_debut) ",
      "VALUES ($1, 1, ST_Multi(ST_GeomFromText('POLYGON((%1$d 6700000, ",
      "%2$d 6700000, %2$d 6700200, %1$d 6700200, %1$d 6700000))', 2154)), ",
      "'test', '2010-01-01')"), x0, x0 + 200), params = list(unites[[i]]))
  }
  amenager(con, foret, 2017, 2019, 300)
  sommier_ajouter(con, sommier_entree(
    foret_id = foret, registre = 5L, date_evenement = "2017-10-15",
    auteur = "agent-01", ug_uuid = unites[["A"]],
    payload = registre5_coupe("martelage", 2017, "regeneration", 400)
  ))
  coupes <- data.frame(ug = c("A", "B"), annee = 2018L, surface_ha = c(1.2, 0.8),
                       date_mediane = as.Date("2018-08-01"),
                       debut = as.Date("2018-07-01"), fin = as.Date("2018-09-01"),
                       proba_moyenne = 97, stringsAsFactors = FALSE)
  attr(coupes, "seuil_proba") <- 90
  attr(coupes, "surface_min_ha") <- 0.5
  indices <- data.frame(ug_id = c("u1", "u2"), libelle = c("p A", "p B"),
                        numero = c("A", "B"), surface_ha = c(4, 4),
                        volume_m3_ha = c(300, 0), coupe_rase_5ans_pct = 0,
                        cadastral_refs = NA_character_,
                        stringsAsFactors = FALSE)
  attr(indices, "date_calcul") <- as.Date("2026-09-23")
  attr(indices, "source") <- "nemeton, projet d'essai"

  chemin <- withr::local_tempfile(fileext = ".html")
  sommier_rapport_quarto(
    con, foret, chemin, format = "html", indices = indices,
    reference_ifn = list(taux_m3_ha_an = 2.28, ser = "B70",
                         nom = "Sologne-Orleanais", millesime = "2005-2024"),
    coupes_detectees = coupes
  )
  html <- paste(readLines(chemin, warn = FALSE, encoding = "UTF-8"),
                collapse = "\n")
  expect_match(html, "Repères, à l", fixed = TRUE)
  expect_match(html, "SER B70 Sologne-Orleanais (2005-2024)", fixed = TRUE)
  expect_match(html, "2,28", fixed = TRUE)
  expect_match(html, "Ce que la forêt porte", fixed = TRUE)
  expect_match(html, "1 200 m³", fixed = TRUE)
  expect_match(html, "Coupes détectées sans martelage inscrit", fixed = TRUE)
  # A est expliquee par le martelage de 2017 ; B ne l'est pas.
  expect_match(html, "B en 2018 (0,80 ha)", fixed = TRUE)
  expect_no_match(html, "A en 2018", fixed = TRUE)
})
