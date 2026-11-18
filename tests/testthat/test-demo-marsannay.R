# Le jeu de demonstration de Marsannay-la-Cote (brief demo-marsannay).

test_that("les parcelles de Marsannay sont reelles dans leur forme", {
  p <- SOMMIER_PARCELLES_MARSANNAY
  expect_equal(nrow(p), 3L)
  # Reference cadastrale sur quatorze caracteres : INSEE 21390 + 0 + section
  # + numero sur quatre chiffres.
  expect_match(p$geo_parcelle, "^21390[0-9]{4}A[0-9]{4}$")
  expect_equal(p$surface_ha, p$contenance_m2 / 1e4)
  expect_true(all(grepl("^POLYGON\\(\\(", p$wkt_4326)))
  expect_match(NOM_FORET_DEMO_MARSANNAY, "(jeu de demonstration)",
               fixed = TRUE)
  skip_if_not_installed("sf")
  g <- sf::st_as_sfc(p$wkt_4326, crs = 4326)
  expect_true(all(sf::st_is_valid(g)))
  # A Marsannay, pas ailleurs.
  bb <- sf::st_bbox(g)
  expect_true(bb[["xmin"]] > 4.9 && bb[["xmax"]] < 5.1)
  expect_true(bb[["ymin"]] > 47.2 && bb[["ymax"]] < 47.4)
})

test_that("le jeu s'ecrit, porte la mention, et n'emploie que des codes connus", {
  con <- sauter_sans_base()
  withr::defer(DBI::dbDisconnect(con))
  sommier_init_schema(con)
  suffixe <- substr(uuid_v4(), 1L, 8L)
  demo <- sommier_demo_marsannay(con, suffixe = suffixe)
  expect_equal(names(demo$ug), SOMMIER_PARCELLES_MARSANNAY$numero)
  nom <- DBI::dbGetQuery(con, "SELECT nom FROM foret WHERE id = $1",
                         params = parametres(list(demo$foret_id)))$nom
  expect_match(nom, "(jeu de demonstration)", fixed = TRUE)
  expect_match(nom, "Marsannay", fixed = TRUE)
  expect_error(sommier_demo_marsannay(con, suffixe = suffixe), "existe deja")
  expect_true(sommier_verifier(con, demo$foret_id)$valide)

  codes <- DBI::dbGetQuery(
    con, "SELECT DISTINCT payload->>'code_travaux' AS c FROM entree_sommier
          WHERE foret_id = $1 AND registre = 6",
    params = parametres(list(demo$foret_id)))$c
  codes <- codes[!is.na(codes)]
  expect_true(length(codes) > 0L)
  expect_true(all(codes %in% SOMMIER_CODES_TRAVAUX$code))
  n_geom <- DBI::dbGetQuery(
    con, "SELECT count(*) AS n FROM ug_geometrie WHERE ug_uuid IN ($1, $2, $3)",
    params = parametres(as.list(unname(demo$ug))))$n
  expect_equal(as.integer(n_geom), 3L)
})

test_that("la tournee de Marsannay a le schema de celle de Couchey", {
  skip_if_not_installed("sf")
  skip_if_not_installed("xml2")
  con <- sauter_sans_base()
  withr::defer(DBI::dbDisconnect(con))
  sommier_init_schema(con)
  m <- sommier_demo_marsannay(con, suffixe = substr(uuid_v4(), 1L, 8L))
  cou <- sommier_demo_couchey(con, suffixe = substr(uuid_v4(), 1L, 8L))
  dm <- file.path(withr::local_tempdir(), "tournee")
  dc <- file.path(withr::local_tempdir(), "tournee")
  sommier_projet_qfield_travaux(con, m$foret_id, dm, "P. O.")
  sommier_projet_qfield_travaux(con, cou$foret_id, dc, "P. O.")
  gm <- file.path(dm, "travaux.gpkg")
  gc <- file.path(dc, "travaux.gpkg")
  couches <- sf::st_layers(gm)$name
  expect_equal(sort(couches), sort(sf::st_layers(gc)$name))
  for (couche in couches) {
    expect_equal(names(sf::read_sf(gm, couche)),
                 names(sf::read_sf(gc, couche)), info = couche)
  }
  # Comme Couchey : trois placettes, trois UG, deux campagnes de controle.
  expect_equal(nrow(sf::read_sf(gm, "placettes")),
               nrow(sf::read_sf(gc, "placettes")))
  expect_equal(nrow(sf::read_sf(gm, "placettes")), 3L)
  expect_equal(nrow(sf::read_sf(gm, "suivis")),
               nrow(sf::read_sf(gc, "suivis")))
  # La couche parcelles vient du fond cadastral (absent ici), comme a Couchey.
  expect_equal(nrow(sf::read_sf(gm, "parcelles")),
               nrow(sf::read_sf(gc, "parcelles")))
})
