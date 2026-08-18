base_export <- function() {
  con <- sauter_sans_base()
  withr::defer(DBI::dbDisconnect(con), envir = parent.frame())
  sommier_init_schema(con)
  con
}

foret_garnie <- function(con) {
  foret <- foret_creer(con, "Foret de Chaux", "communal", surface_ha = 500)
  exercice_definir(con, foret, 2024, 100)
  exercice_definir(con, foret, 2025, 100)
  ecrire <- function(registre, payload, date) {
    sommier_ajouter(con, sommier_entree(
      foret_id = foret, registre = registre, date_evenement = date,
      auteur = "agent-01", payload = payload
    ))
  }
  ecrire(5L, registre5_coupe("martelage", 2024, "amelioration", 120), "2024-03-01")
  ecrire(5L, registre5_coupe("martelage", 2025, "reguliere", 80), "2025-03-01")
  ecrire(6L, registre6_travaux(2024, "plantation", quantite = 3, unite = "ha",
                               montant_eur = 4800, taux_reprise_pct = 88),
         "2024-04-01")
  ecrire(7L, registre7_ecriture("bois_sur_pied", 2024, 18400), "2024-06-30")
  ecrire(7L, registre7_ecriture("reboisement", 2024, 4800), "2024-06-30")
  ecrire(8L, registre8_phenomene("tempete", "Coup de vent", surface_ha = 8),
         "2024-12-15")
  ecrire(8L, registre8_equilibre_gibier("2024-2025", 42,
                                        taux_abroutissement_pct = 23), "2025-02-01")
  ecrire(9L, registre9_arbre("Chene des Trois Bornes", "CHS", "Age"), "2024-05-01")
  # Hors periode : ne doit pas remonter dans un export borne a 2024-2025.
  ecrire(5L, registre5_coupe("martelage", 2030, "sanitaire", 500), "2030-03-01")
  foret
}

test_that("la gestion anterieure rassemble les sections attendues", {
  con <- base_export()
  foret <- foret_garnie(con)
  ga <- sommier_gestion_anterieure(con, foret, "2024-01-01", "2025-12-31")

  expect_s3_class(ga, "sommier_gestion_anterieure")
  expect_equal(ga$referentiel, "psg")
  expect_equal(sum(ga$sections$coupes$volume_m3), 200)   # 2030 exclu
  expect_equal(nrow(ga$sections$travaux), 1L)
  expect_equal(nrow(ga$sections$evenements), 1L)
  expect_equal(nrow(ga$sections$equilibre_gibier), 1L)
})

test_that("chaque referentiel retient les sections qui le concernent", {
  con <- base_export()
  foret <- foret_garnie(con)

  psg <- sommier_gestion_anterieure(con, foret, referentiel = "psg")
  amenagement <- sommier_gestion_anterieure(con, foret, referentiel = "amenagement")
  ct88 <- sommier_gestion_anterieure(con, foret, referentiel = "ct88")

  # Le PSG ne reclame pas le detail financier au proprietaire.
  expect_false("finances" %in% names(psg$sections))
  expect_true("finances" %in% names(amenagement$sections))
  expect_true("finances" %in% names(ct88$sections))

  # Le CT88 evalue un contrat : le patrimoine remarquable n'y figure pas.
  expect_true("patrimoine" %in% names(psg$sections))
  expect_false("patrimoine" %in% names(ct88$sections))

  # Le socle commun est present partout.
  for (r in list(psg, amenagement, ct88)) {
    expect_true(all(c("coupes", "balance", "travaux", "evenements") %in%
                      names(r$sections)))
  }
})

test_that("le bilan financier de l'export concorde avec la vue", {
  con <- base_export()
  foret <- foret_garnie(con)
  ga <- sommier_gestion_anterieure(con, foret, "2024-01-01", "2025-12-31",
                                   referentiel = "amenagement")
  finances <- ga$sections$finances
  expect_equal(finances$recettes_eur[finances$exercice == 2024], 18400)
  expect_equal(finances$depenses_eur[finances$exercice == 2024], 4800)
  expect_equal(finances$solde_eur[finances$exercice == 2024], 13600)
})

test_that("une periode inversee est refusee", {
  con <- base_export()
  foret <- foret_garnie(con)
  expect_error(
    sommier_gestion_anterieure(con, foret, "2025-01-01", "2024-01-01"),
    "precede"
  )
  expect_error(sommier_gestion_anterieure(con, uuid_v4()), "Foret inconnue")
})

test_that("le rendu Markdown porte les sections et dit les vides", {
  con <- base_export()
  foret <- foret_garnie(con)
  ga <- sommier_gestion_anterieure(con, foret, "2024-01-01", "2025-12-31",
                                   referentiel = "amenagement")
  md <- sommier_rapport_markdown(ga)

  expect_match(md, "# Gestion anterieure - Foret de Chaux")
  expect_match(md, "## Coupes realisees")
  expect_match(md, "## Bilan financier")
  expect_match(md, "\\| exercice \\|")

  # Une section vide se dit plutot que de rendre un tableau sans ligne.
  vide <- sommier_gestion_anterieure(con, foret, "2040-01-01", "2041-01-01")
  expect_match(sommier_rapport_markdown(vide), "Aucun enregistrement")

  chemin <- withr::local_tempfile(fileext = ".md")
  sommier_rapport_markdown(ga, chemin)
  expect_true(file.exists(chemin))
  expect_match(paste(readLines(chemin, warn = FALSE), collapse = "\n"),
               "Gestion anterieure")
})

test_that("l'export GeoJSON rend une FeatureCollection valide", {
  con <- base_export()
  foret <- foret_creer(con, "Foret test", "domanial", surface_ha = 100)
  ug <- ug_creer(con, foret, "1", "2010-01-01")
  DBI::dbExecute(
    con,
    "INSERT INTO ug_geometrie (ug_uuid, version, geom, date_debut)
     VALUES ($1, 1, ST_Multi(ST_GeomFromText($2, 2154)), $3::date)",
    params = list(ug, "POLYGON((0 0, 100 0, 100 100, 0 100, 0 0))", "2010-01-01")
  )
  sommier_ajouter(con, sommier_entree(
    foret_id = foret, registre = 6L, ug_uuid = ug,
    date_evenement = "2026-04-01", auteur = "a1",
    payload = registre6_travaux(2026, "degagement")
  ))

  chemin <- withr::local_tempfile(fileext = ".geojson")
  resultat <- sommier_exporter_sig(con, foret, chemin, format = "geojson")
  expect_equal(resultat$n_unites, 1L)
  expect_length(resultat$unites_sans_geometrie, 0L)

  lu <- jsonlite::fromJSON(chemin, simplifyVector = FALSE)
  expect_equal(lu$type, "FeatureCollection")
  expect_length(lu$features, 1L)
  entite <- lu$features[[1]]
  expect_equal(entite$geometry$type, "MultiPolygon")
  expect_equal(entite$properties$numero_affichage, "1")
  expect_equal(entite$properties$n_entrees, 1L)
})

test_that("une unite sans geometrie est signalee plutot qu'inventee", {
  # L'omettre en silence laisserait croire la foret entierement cartographiee.
  con <- base_export()
  foret <- foret_creer(con, "Foret test", "domanial")
  ug_creer(con, foret, "12", "2010-01-01")

  chemin <- withr::local_tempfile(fileext = ".geojson")
  resultat <- sommier_exporter_sig(con, foret, chemin)
  expect_equal(resultat$n_unites, 0L)
  expect_equal(resultat$unites_sans_geometrie, "12")

  lu <- jsonlite::fromJSON(chemin, simplifyVector = FALSE)
  expect_length(lu$features, 0L)
})

# Fabrique une foret d'une unite de gestion carree de 1 ha, geometrie posee.
foret_cartographiee <- function(con, cote_m = 100) {
  foret <- foret_creer(con, "Foret cartographiee", "domanial", surface_ha = 100)
  ug <- ug_creer(con, foret, "1", "2010-01-01")
  DBI::dbExecute(
    con,
    "INSERT INTO ug_geometrie (ug_uuid, version, geom, date_debut)
     VALUES ($1, 1, ST_Multi(ST_GeomFromText($2, 2154)), $3::date)",
    params = list(
      ug,
      sprintf("POLYGON((0 0, %1$d 0, %1$d %1$d, 0 %1$d, 0 0))", cote_m),
      "2010-01-01"
    )
  )
  list(foret = foret, ug = ug)
}

test_that("l'export GeoPackage ecrit une couche relisible", {
  # `sf` est installe sur le runner de CI (il est en Suggests) : ce chemin y
  # est donc reellement exerce, et pas seulement redige.
  skip_if_not_installed("sf")
  con <- base_export()
  perimetre <- foret_cartographiee(con)

  chemin <- withr::local_tempfile(fileext = ".gpkg")
  resultat <- sommier_exporter_sig(con, perimetre$foret, chemin, format = "gpkg")
  expect_equal(resultat$n_unites, 1L)
  expect_true(file.exists(chemin))

  couche <- sf::read_sf(chemin)
  expect_equal(nrow(couche), 1L)
  expect_equal(couche$numero_affichage, "1")
  expect_equal(couche$uuid, perimetre$ug)
  # Le systeme de coordonnees doit survivre a l'ecriture : une couche en
  # Lambert-93 relue sans projection serait inexploitable.
  expect_equal(sf::st_crs(couche)$epsg, 2154L)
  expect_equal(as.numeric(sf::st_area(couche)), 10000)   # 100 m de cote
})

test_that("un GeoPackage sans unite cartographiee est refuse plutot que vide", {
  # Un fichier SIG sans couche est plus difficile a diagnostiquer qu'une
  # erreur : le destinataire croit avoir recu la cartographie.
  skip_if_not_installed("sf")
  con <- base_export()
  foret <- foret_creer(con, "Foret sans geometrie", "domanial")
  ug_creer(con, foret, "12", "2010-01-01")
  chemin <- withr::local_tempfile(fileext = ".gpkg")
  expect_error(sommier_exporter_sig(con, foret, chemin, format = "gpkg"),
               "Aucune unite de gestion avec geometrie")
})

test_that("l'export GeoPackage exige sf et le dit", {
  skip_if(requireNamespace("sf", quietly = TRUE),
          "sf est installe : le chemin d'erreur ne s'exerce pas.")
  con <- base_export()
  foret <- foret_creer(con, "Foret test", "domanial")
  chemin <- withr::local_tempfile(fileext = ".gpkg")
  expect_error(sommier_exporter_sig(con, foret, chemin, format = "gpkg"),
               "sf")
})

test_that("un format inconnu est refuse", {
  con <- base_export()
  foret <- foret_creer(con, "Foret test", "domanial")
  expect_error(
    sommier_exporter_sig(con, foret, tempfile(), format = "shapefile"),
    "format"
  )
})
