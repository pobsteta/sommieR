# La tournee des travaux : le projet QField, le retour du terrain, le rejeu.

base_travaux_qfield <- function(env = parent.frame()) {
  con <- sauter_sans_base()
  withr::defer(DBI::dbDisconnect(con), envir = env)
  sommier_init_schema(con)
  con
}

# Deux unites de 300 x 200 m cote a cote ; une plantation 2024 dans la
# premiere, suivie par une placette deja controlee.
foret_tournee <- function(con) {
  foret <- foret_creer(con, paste0("Foret tournee-", substr(uuid_v4(), 1L, 8L)),
                       "communal")
  ug <- c(a = ug_creer(con, foret, "12", "2010-01-01"),
          b = ug_creer(con, foret, "13", "2010-01-01"))
  for (k in seq_along(ug)) {
    x0 <- 600000 + 300 * (k - 1L)
    DBI::dbExecute(con, sprintf(
      "INSERT INTO ug_geometrie (ug_uuid, version, geom, source, date_debut)
       VALUES ($1, 1, ST_Multi(ST_GeomFromText('POLYGON((%1$d 6700000,
         %2$d 6700000, %2$d 6700200, %1$d 6700200, %1$d 6700000))', 2154)),
         'test', '2010-01-01')", x0, x0 + 300L), params = list(ug[[k]]))
  }
  plantation <- sommier_ajouter(con, sommier_entree(
    foret_id = foret, registre = 6L, date_evenement = "2024-11-20",
    auteur = "agent-01", ug_uuid = ug[["a"]],
    payload = registre6_travaux(2024, "plantation", code_travaux = "PL",
                                quantite = 2, unite = "ha", prevu = "prevu")
  ))[[1L]]$id
  centre <- sf::st_coordinates(sf::st_transform(
    sf::st_sfc(sf::st_point(c(600150, 6700100)), crs = 2154), 4326))
  placette <- sommier_installer_placette(
    con, plantation, "P12-01", geom_point(centre[1L, 1L], centre[1L, 2L]),
    "agent-01", date_evenement = "2024-12-01")[[1L]]$id
  sommier_controler_placette(con, placette, 20, 17, "agent-01",
                             visite_le = "2025-06-10T09:00:00Z", besoin = "DG")
  list(foret = foret, ug = ug, plantation = plantation, placette = placette)
}

# Une saisie de terrain dans une couche du projet.
saisir <- function(dossier, couche, x) {
  sf::st_write(x, file.path(dossier, "travaux.gpkg"), layer = couche,
               append = TRUE, quiet = TRUE)
}

intervention <- function(uuid, code, geometrie, quantite, unite, prevu,
                         motif = NA_character_) {
  sf::st_sf(
    uuid = uuid, code_travaux = code, nature_travaux = NA_character_,
    annee = 2026L, quantite = quantite, unite = unite,
    nb_plants = NA_integer_, montant_eur = 1500, modalite = NA_character_,
    essence_objectif = NA_character_, execution = "entreprise",
    intervenant = "ETF Martin", prevu = prevu, motif_ecart = motif,
    date_reception = as.Date("2026-03-02"),
    visite_le = as.POSIXct("2026-03-02 10:00:00", tz = "UTC"),
    operateur = "P. O.", precision_m = 2, source_gnss = "interne",
    observations = NA_character_,
    geometry = sf::st_sfc(geometrie, crs = 2154)
  )
}

controle <- function(uuid, placette, vivants, jour, besoin = "aucun",
                     x = 600150, y = 6700100) {
  sf::st_sf(uuid = uuid, placette_uuid = placette, nb_total = 20L,
            nb_vivants = vivants, h_moy_cm = 40L, nb_abroutis = 1L,
            concurrence = "moyenne", besoin = besoin,
            visite_le = as.POSIXct(paste(jour, "09:00:00"), tz = "UTC"),
            operateur = "P. O.", observations = NA_character_,
            geometry = sf::st_sfc(sf::st_point(c(x, y)), crs = 2154))
}

carre <- function(x0, y0, cote) {
  sf::st_polygon(list(rbind(c(x0, y0), c(x0 + cote, y0),
                            c(x0 + cote, y0 + cote), c(x0, y0 + cote),
                            c(x0, y0))))
}

test_that("le projet des travaux s'engendre et s'ouvre dans QGIS", {
  skip_if_not_installed("sf")
  skip_if_not_installed("xml2")
  con <- base_travaux_qfield()
  f <- foret_tournee(con)
  dossier <- file.path(withr::local_tempdir(), "travaux")
  qgs <- sommier_projet_qfield_travaux(con, f$foret, dossier, "P. & O.")
  expect_true(file.exists(qgs))
  expect_true(dir.exists(file.path(dossier, "DCIM")))
  expect_error(sommier_projet_qfield_travaux(con, f$foret, dossier, "P. O."),
               "existe deja")
  xml <- paste(readLines(qgs, encoding = "UTF-8"), collapse = "\n")
  expect_no_match(xml, "@@|111111")
  # La couche des surfaces ne propose que les codes qui admettent une surface.
  expect_match(xml, "&quot;formes&quot; LIKE '%surface%'", fixed = TRUE)

  gpkg <- file.path(dossier, "travaux.gpkg")
  codes <- sf::read_sf(gpkg, "codes")
  expect_equal(codes$code, c(SOMMIER_CODES_TRAVAUX$code, "aucun"))
  suivis <- sf::read_sf(gpkg, "suivis")
  expect_equal(suivis$id, f$plantation)
  expect_match(suivis$libelle, "^UG 12 - 2024 - PL plantation")
  p <- sf::read_sf(gpkg, "placettes")
  expect_equal(p$uuid, f$placette)
  expect_equal(p$etat_suivi, "a_programmer")
  expect_equal(p$dernier_besoin, "DG")

  ouvert <- ouvrir_dans_qgis(qgs)
  expect_true(ouvert$lu)
  expect_true(all(vapply(ouvert$couches, function(c) isTRUE(c$valide),
                         logical(1))))
  expect_true(all(c("travaux_travaux_surf", "travaux_travaux_lin",
                    "travaux_travaux_pt", "travaux_placettes",
                    "travaux_controles", "travaux_photos", "travaux_codes",
                    "travaux_suivis") %in% names(ouvert$couches)))
  expect_true(ouvert$couches$travaux_codes$lecture_seule)
  expect_false(ouvert$couches$travaux_placettes$lecture_seule)
  # Trois relations de photos aux travaux, une au controle, une des
  # controles a la placette.
  expect_length(ouvert$relations, 5L)
  expect_true(all(vapply(ouvert$relations, function(r) isTRUE(r$valide),
                         logical(1))))
  expect_equal(ouvert$variables$operateur, "P. & O.")
})

test_that("la tournee s'importe dans l'ordre, une seule fois", {
  skip_if_not_installed("sf")
  skip_if_not_installed("xml2")
  con <- base_travaux_qfield()
  f <- foret_tournee(con)
  dossier <- file.path(withr::local_tempdir(), "travaux")
  depot <- file.path(withr::local_tempdir(), "photos")
  sommier_projet_qfield_travaux(con, f$foret, dossier, "P. O.")

  u <- list(pl = uuid_v4(), pg = uuid_v4(), placette = uuid_v4(),
            k1 = uuid_v4(), k2 = uuid_v4())
  # Une plantation dans l'unite 13, non prevue ; une cloture a cheval.
  saisir(dossier, "travaux_surf", intervention(
    u$pl, "PL", carre(600350, 6700050, 100), 1, "ha", "non_prevu",
    "Trouee de chablis"))
  saisir(dossier, "travaux_lin", intervention(
    u$pg, "PG", sf::st_linestring(rbind(c(600250, 6700020),
                                        c(600450, 6700020))),
    200, "m", "prevu"))
  # Une placette dans la plantation du jour, controlee le jour meme ; un
  # controle de la placette deja installee.
  saisir(dossier, "placettes", sf::st_sf(
    uuid = u$placette, code_placette = "P13-01", travaux_id = u$pl,
    rayon_m = 3.99, materialisation = "piquet", ug = NA_character_,
    etat_suivi = "nouvelle", dernier_controle = as.Date(NA),
    dernier_besoin = NA_character_,
    geometry = sf::st_sfc(sf::st_point(c(600400, 6700100)), crs = 2154)))
  saisir(dossier, "controles", rbind(
    controle(u$k1, u$placette, 20, "2026-03-02", x = 600400, y = 6700100),
    controle(u$k2, f$placette, 18, "2026-06-12", besoin = "aucun")
  ))
  file.copy(testthat::test_path("fixtures", "photo-exif-ii.jpg"),
            file.path(dossier, "DCIM", "travaux_1.jpg"))
  saisir(dossier, "photos", data.frame(
    uuid = uuid_v4(), constat_uuid = u$k2, fichier = "DCIM/travaux_1.jpg",
    prise_le = as.POSIXct("2026-06-12 09:05:00", tz = "UTC")))

  bilan <- sommier_importer_qfield_travaux(con, f$foret, dossier, depot,
                                           auteur = "test")
  expect_equal(c(bilan$travaux, bilan$placettes, bilan$controles),
               c(2L, 1L, 2L))
  expect_equal(bilan$photos, 1L)
  # La plantation tombe dans l'unite 13, avec son contour.
  pl <- Filter(function(e) e$id == u$pl, bilan$entrees)[[1L]]
  expect_equal(pl$ug_uuid, f$ug[["b"]])
  expect_equal(pl$ndp, 0L)
  expect_equal(pl$payload$geometrie$type, "Polygon")
  expect_equal(pl$payload$prevu, "non_prevu")
  expect_equal(pl$payload$nature_travaux, "PL")
  # La placette suit la plantation inscrite dans la meme tournee.
  pla <- DBI::dbGetQuery(con, "SELECT travaux_id::text AS t, ug_uuid::text AS u
                                 FROM v_placette WHERE id = $1",
                         params = list(u$placette))
  expect_equal(pla$t, u$pl)
  expect_equal(pla$u, f$ug[["b"]])
  k <- DBI::dbGetQuery(con, "SELECT placette_id::text AS p, age_ans
                               FROM v_controle_plantation WHERE id = $1",
                       params = list(u$k2))
  expect_equal(k$p, f$placette)
  expect_equal(k$age_ans, 2L)
  expect_true(all(sommier_verifier_photos(con, f$foret, depot)$statut ==
                    "intacte"))

  encore <- sommier_importer_qfield_travaux(con, f$foret, dossier, depot,
                                            auteur = "test")
  expect_equal(c(encore$travaux, encore$placettes, encore$controles),
               c(0L, 0L, 0L))
  # Les cinq saisies, et la placette deja inscrite versee dans le projet.
  expect_equal(encore$deja_presents, 6L)
  expect_true(sommier_verifier(con, f$foret)$valide)
})

test_that("une tournee fautive n'ecrit rien et dit tout", {
  skip_if_not_installed("sf")
  skip_if_not_installed("xml2")
  con <- base_travaux_qfield()
  f <- foret_tournee(con)
  dossier <- file.path(withr::local_tempdir(), "travaux")
  sommier_projet_qfield_travaux(con, f$foret, dossier, "P. O.")
  avant <- sommier_verifier(con, f$foret)$hash_tete

  # Une cloture saisie en surface ; une plantation non prevue sans motif ; une
  # placette rattachee a rien de connu ; plus de vivants que de plants.
  saisir(dossier, "travaux_surf", rbind(
    intervention(uuid_v4(), "PG", carre(600050, 6700050, 50), 200, "m",
                 "prevu"),
    intervention(uuid_v4(), "PL", carre(600350, 6700050, 50), 1, "ha",
                 "non_prevu")
  ))
  saisir(dossier, "placettes", sf::st_sf(
    uuid = uuid_v4(), code_placette = "P13-09", travaux_id = uuid_v4(),
    rayon_m = 3.99, materialisation = NA_character_, ug = NA_character_,
    etat_suivi = "nouvelle", dernier_controle = as.Date(NA),
    dernier_besoin = NA_character_,
    geometry = sf::st_sfc(sf::st_point(c(600400, 6700100)), crs = 2154)))
  saisir(dossier, "controles", controle(uuid_v4(), f$placette, 25,
                                        "2026-06-12"))

  erreur <- tryCatch(
    sommier_importer_qfield_travaux(con, f$foret, dossier,
                                    withr::local_tempdir(), auteur = "test"),
    error = conditionMessage)
  expect_match(erreur, "rien n'est ecrit")
  expect_match(erreur, "un PG ne se trace pas en surface")
  expect_match(erreur, "motif_ecart")
  expect_match(erreur, "travaux suivis inconnus")
  expect_match(erreur, "Plus de plants vivants")
  expect_equal(sommier_verifier(con, f$foret)$hash_tete, avant)
})

test_that("un controle saisi depuis sa couche se rattache a la placette proche", {
  skip_if_not_installed("sf")
  skip_if_not_installed("xml2")
  con <- base_travaux_qfield()
  f <- foret_tournee(con)
  dossier <- file.path(withr::local_tempdir(), "travaux")
  sommier_projet_qfield_travaux(con, f$foret, dossier, "P. O.")
  # Sans placette choisie : a 5 m de P12-01, il s'y rattache.
  k <- uuid_v4()
  saisir(dossier, "controles", controle(k, NA_character_, 18, "2026-06-12",
                                        x = 600153, y = 6700104))
  bilan <- sommier_importer_qfield_travaux(con, f$foret, dossier,
                                           withr::local_tempdir(),
                                           auteur = "test")
  expect_equal(bilan$controles, 1L)
  p <- DBI::dbGetQuery(con, "SELECT placette_id::text AS p
                               FROM v_controle_plantation WHERE id = $1",
                       params = list(k))$p
  expect_equal(p, f$placette)

  # A 40 m de toute placette : refuse, et rien n'est ecrit.
  autre <- file.path(withr::local_tempdir(), "travaux")
  sommier_projet_qfield_travaux(con, f$foret, autre, "P. O.")
  saisir(autre, "controles", controle(uuid_v4(), NA_character_, 18,
                                      "2026-06-13", x = 600150, y = 6700140))
  expect_error(sommier_importer_qfield_travaux(con, f$foret, autre,
                                               withr::local_tempdir(),
                                               auteur = "test"),
               "aucune placette choisie, ni a moins de 15 m")
})
