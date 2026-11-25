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

test_that("une tournee de l'ancien format, sans position aux controles, s'importe", {
  skip_if_not_installed("sf")
  skip_if_not_installed("xml2")
  con <- base_travaux_qfield()
  f <- foret_tournee(con)
  dossier <- file.path(withr::local_tempdir(), "travaux")
  sommier_projet_qfield_travaux(con, f$foret, dossier, "P. O.")
  # Les controles d'avant la v0.31.0 : une table, sans geometrie.
  k <- uuid_v4()
  sf::st_write(sf::st_drop_geometry(controle(k, f$placette, 18, "2026-06-12")),
               file.path(dossier, "travaux.gpkg"), layer = "controles",
               delete_layer = TRUE, quiet = TRUE)
  bilan <- sommier_importer_qfield_travaux(con, f$foret, dossier,
                                           withr::local_tempdir(),
                                           auteur = "test")
  expect_equal(bilan$controles, 1L)
  # Sans placette ni position, il est refuse.
  autre <- file.path(withr::local_tempdir(), "travaux")
  sommier_projet_qfield_travaux(con, f$foret, autre, "P. O.")
  sf::st_write(sf::st_drop_geometry(controle(uuid_v4(), NA_character_, 18,
                                             "2026-06-13")),
               file.path(autre, "travaux.gpkg"), layer = "controles",
               delete_layer = TRUE, quiet = TRUE)
  expect_error(sommier_importer_qfield_travaux(con, f$foret, autre,
                                               withr::local_tempdir(),
                                               auteur = "test"),
               "aucune placette choisie")
})

test_that("le projet des travaux porte la symbologie de Marculus", {
  skip_if_not_installed("sf")
  skip_if_not_installed("xml2")
  con <- base_travaux_qfield()
  f <- foret_tournee(con)
  dossier <- file.path(withr::local_tempdir(), "travaux")
  carre_wkt <- function(x0) {
    sprintf("POLYGON((%1$d 6700000, %2$d 6700000, %2$d 6700100, %1$d 6700100, %1$d 6700000))",
            x0, x0 + 100L)
  }
  fond <- data.frame(reference = c("A", "B", "C"),
                     section = c("000AB", "000AB", "000AB"),
                     numero = c("0012", "0013", "0014"),
                     wkt = vapply(c(600000L, 600150L, 600300L), carre_wkt, ""),
                     proprietaire = c("Commune", NA, "Commune"),
                     stringsAsFactors = FALSE)
  qgs <- sommier_projet_qfield_travaux(con, f$foret, dossier, "P. O.",
                                       fond = fond)
  parcelles <- sf::read_sf(file.path(dossier, "travaux.gpkg"), "parcelles")
  expect_equal(parcelles$numero, c("12", "13", "14"))
  expect_equal(parcelles$proprietaire, c("Commune", NA, "Commune"))
  xml <- xml2::read_xml(qgs)
  rend <- xml2::xml_find_first(
    xml, "//maplayer[id='travaux_parcelles']/renderer-v2")
  expect_equal(xml2::xml_attr(rend, "type"), "categorizedSymbol")
  expect_equal(xml2::xml_attr(xml2::xml_find_all(rend, ".//category"), "value"),
               c("Commune", ""))
  # Le projet reste lisible par QGIS.
  ouvert <- ouvrir_dans_qgis(qgs)
  expect_true(ouvert$lu)
  expect_true(ouvert$couches$travaux_parcelles$valide)
})

test_that("l'action_id du programme passe de la tournee au registre 6", {
  skip_if_not_installed("sf")
  skip_if_not_installed("xml2")
  con <- base_travaux_qfield()
  f <- foret_tournee(con)
  programme <- testthat::test_path("fixtures", "programme-travaux-exemple.gpkg")
  dossier <- file.path(withr::local_tempdir(), "travaux")
  sommier_projet_qfield_travaux(con, f$foret, dossier, "P. O.",
                                programme = programme)
  gpkg <- file.path(dossier, "travaux.gpkg")
  p <- sf::read_sf(gpkg, "programme")
  expect_equal(p$action_id, c("act_20261105093012_k3x9a1", "act_20261105093044_p7q2zd", "act_20261106101502_m4w8tb"))
  expect_match(p$libelle[[1L]], "^act_20261105093012_k3x9a1 - UG 12 plantation 2026")
  # Le champ est dans les trois couches de travaux du modele.
  for (couche in c("travaux_surf", "travaux_lin", "travaux_pt")) {
    expect_true("action_id" %in% names(sf::read_sf(gpkg, couche)))
  }
  xml <- paste(readLines(file.path(dossier, "travaux.qgs"),
                         encoding = "UTF-8"), collapse = "\n")
  expect_equal(lengths(regmatches(xml, gregexpr('name="action_id"', xml))), 6L)
  # La liste des actions : un ValueMap, identifiant stocke, libelle affiche.
  doc <- xml2::read_xml(file.path(dossier, "travaux.qgs"))
  expect_length(xml2::xml_find_all(
    doc, "//field[@name='action_id']/editWidget[@type='ValueMap']"), 3L)
  expect_length(xml2::xml_find_all(
    doc, "//field[@name='action_id']/editWidget[@type='ValueMap']//Option[@value='act_20261105093012_k3x9a1']"), 3L)

  # Une seule couche porte l'action (l'autre la laisse vide) : l'import
  # tient, l'action arrive au registre 6, et le realise la rend au plan.
  u <- uuid_v4()
  x <- intervention(u, "PL", carre(600050, 6700050, 100), 1.75, "ha", "prevu")
  x$action_id <- "act_20261105093012_k3x9a1"
  saisir(dossier, "travaux_surf", x)
  saisir(dossier, "travaux_lin", intervention(
    uuid_v4(), "PG", sf::st_linestring(rbind(c(600020, 6700020),
                                             c(600120, 6700020))),
    100, "m", "prevu"))
  bilan <- sommier_importer_qfield_travaux(con, f$foret, dossier,
                                           withr::local_tempdir(),
                                           auteur = "test")
  expect_equal(bilan$travaux, 2L)
  pl <- Filter(function(e) e$id == u, bilan$entrees)[[1L]]
  expect_equal(pl$payload$action_id, "act_20261105093012_k3x9a1")
  r <- sommier_actions_realisees(con, f$foret)
  expect_equal(r$travaux_id, u)
  expect_equal(r$action_id, "act_20261105093012_k3x9a1")
})

test_that("un action_id hors du programme du projet fait refuser la tournee", {
  skip_if_not_installed("sf")
  skip_if_not_installed("xml2")
  con <- base_travaux_qfield()
  f <- foret_tournee(con)
  dossier <- file.path(withr::local_tempdir(), "travaux")
  sommier_projet_qfield_travaux(
    con, f$foret, dossier, "P. O.",
    programme = testthat::test_path("fixtures", "programme-travaux-exemple.gpkg"))
  x <- intervention(uuid_v4(), "PL", carre(600050, 6700050, 100), 1, "ha",
                    "prevu")
  x$action_id <- "act_20261231000000_zzzzzz"
  saisir(dossier, "travaux_surf", x)
  expect_error(sommier_importer_qfield_travaux(con, f$foret, dossier,
                                               withr::local_tempdir(),
                                               auteur = "test"),
               "act_20261231000000_zzzzzz absent du programme")
  expect_error(sommier_projet_qfield_travaux(
    con, f$foret, file.path(withr::local_tempdir(), "autre"), "P. O.",
    programme = "absent.gpkg"), "introuvable")
})

test_that("une couche sans action_id et une qui en porte : seule l'action sort", {
  skip_if_not_installed("sf")
  skip_if_not_installed("xml2")
  con <- base_travaux_qfield()
  f <- foret_tournee(con)
  dossier <- file.path(withr::local_tempdir(), "travaux")
  sommier_projet_qfield_travaux(con, f$foret, dossier, "P. O.")
  gpkg <- file.path(dossier, "travaux.gpkg")
  # Une tournee d'avant 0.41.0 : la couche des lignes est recreee sans la
  # colonne action_id, comme le faisait l'ancien modele.
  u_lin <- uuid_v4()
  ligne <- intervention(u_lin, "PG", sf::st_linestring(rbind(
    c(600020, 6700020), c(600120, 6700020))), 100, "m", "prevu")
  sf::st_write(ligne, gpkg, layer = "travaux_lin", delete_layer = TRUE,
               quiet = TRUE)
  expect_false("action_id" %in% names(sf::read_sf(gpkg, "travaux_lin")))
  # La couche des surfaces, elle, porte une action.
  u_surf <- uuid_v4()
  surf <- intervention(u_surf, "PL", carre(600050, 6700050, 100), 1.75, "ha",
                       "prevu")
  surf$action_id <- "act_20261105093012_k3x9a1"
  saisir(dossier, "travaux_surf", surf)
  bilan <- sommier_importer_qfield_travaux(con, f$foret, dossier,
                                           withr::local_tempdir(),
                                           auteur = "test")
  expect_equal(bilan$travaux, 2L)
  pg <- Filter(function(e) e$id == u_lin, bilan$entrees)[[1L]]
  expect_null(pg$payload$action_id)
  r <- sommier_actions_realisees(con, f$foret)
  expect_equal(r$travaux_id, u_surf)
  expect_equal(r$action_id, "act_20261105093012_k3x9a1")
})
# Brief surculus du 2026-10-28 : photos de placette et de plant.

# La couche `photos_terrain` telle que Surculus l'ecrit (docs/spec.md § 5) :
# POINT dans le repere de la tournee, types du GeoPackage de Surculus.
photos_terrain_surculus <- function(photo_uuid, sujet, placette_uuid,
                                    plant_uuid, sha256) {
  n <- length(photo_uuid)
  sf::st_sf(
    photo_uuid = photo_uuid, sujet = sujet, placette_uuid = placette_uuid,
    plant_uuid = plant_uuid, azimut_visee_mag_deg = seq(180, by = 10,
                                                       length.out = n),
    declinaison_deg = 1.4, modele_geomagnetique = "WMM2025",
    precision_m = c(0.03, 2)[seq_len(n)], source_gnss = c("rtk", "interne")[seq_len(n)],
    referentiel_source = c("RGF93", "WGS84")[seq_len(n)],
    age_fix_ms = c(800L, 1200L)[seq_len(n)], simulee = FALSE, sha256 = sha256,
    geometry = sf::st_sfc(rep(list(sf::st_point(c(600150, 6700100))), n),
                          crs = 2154))
}

# Une tournee avec un controle portant deux photos (placette, plant).
tournee_photos <- function(con, f, dossier) {
  sommier_projet_qfield_travaux(con, f$foret, dossier, "P. O.")
  k <- uuid_v4()
  saisir(dossier, "controles", controle(k, f$placette, 18, "2026-11-18"))
  ph <- c(placette = uuid_v4(), plant = uuid_v4())
  photo_exif(file.path(dossier, "DCIM", paste0(ph[["placette"]], ".jpg")),
             decalage = "+01:00",
             gps = list(lat = 47.977, lon = 2.030667, datum = "ETRS89",
                        erreur_m = 0.03))
  photo_exif(file.path(dossier, "DCIM", paste0(ph[["plant"]], ".jpg")),
             decalage = "+01:00",
             gps = list(lat = 47.977, lon = 2.030667, datum = "WGS-84",
                        erreur_m = 2))
  saisir(dossier, "photos", data.frame(
    uuid = unname(ph), constat_uuid = k,
    fichier = paste0("DCIM/", ph, ".jpg"),
    prise_le = as.POSIXct("2026-11-18 09:31:05", tz = "UTC")))
  list(k = k, ph = ph)
}

test_that("une tournee avec une photo de placette et une de plant s'importe, puis revient a l'aller", {
  skip_if_not_installed("sf")
  skip_if_not_installed("xml2")
  con <- base_travaux_qfield()
  f <- foret_tournee(con)
  dossier <- file.path(withr::local_tempdir(), "travaux")
  depot <- file.path(withr::local_tempdir(), "photos")
  t <- tournee_photos(con, f, dossier)
  gpkg <- file.path(dossier, "travaux.gpkg")
  # sommieR n'ecrit pas la couche a l'aller : Surculus la cree.
  expect_false("photos_terrain" %in% sf::st_layers(gpkg)$name)

  plant <- uuid_v4()
  empreintes <- vapply(t$ph, function(u) {
    empreinte_fichier(file.path(dossier, "DCIM", paste0(u, ".jpg")))
  }, "")
  sf::st_write(photos_terrain_surculus(
    unname(t$ph), c("placette", "plant"), f$placette, c(NA, plant),
    unname(empreintes)), gpkg, layer = "photos_terrain", quiet = TRUE)

  bilan <- sommier_importer_qfield_travaux(con, f$foret, dossier, depot,
                                           auteur = "test")
  expect_equal(bilan$controles, 1L)
  expect_equal(bilan$photos, 2L)
  payload <- bilan$entrees[[1L]]$payload
  expect_length(payload$photos, 2L)
  expect_equal(vapply(payload$photos, function(p) p$exif_datum, ""),
               c("ETRS89", "WGS-84"))
  expect_equal(payload$photos[[1L]]$uuid, t$ph[["placette"]])
  # Placette, plant, unites et empreinte arrivent au registre, par leurs noms.
  pla <- payload$photos[[1L]]$terrain
  pln <- payload$photos[[2L]]$terrain
  expect_equal(pla$sujet, "placette")
  expect_equal(pla$placette_uuid, f$placette)
  expect_null(pla$plant_uuid)
  expect_equal(pln$sujet, "plant")
  expect_equal(pln$placette_uuid, f$placette)
  expect_equal(pln$plant_uuid, plant)
  expect_equal(pln$age_fix_ms, 1200L)
  # La position du fix : la geometrie de la couche, avec son SCR, sans conversion.
  expect_equal(c(pln$fix_x, pln$fix_y), c(600150, 6700100))
  expect_equal(pln$fix_scr, "EPSG:2154")
  expect_equal(pla$fix_scr, "EPSG:2154")
  expect_length(bilan$avertissements, 0L)
  expect_equal(pln$referentiel_source, "WGS84")
  expect_false(pln$simulee)
  expect_equal(pln$sha256, unname(empreintes[["plant"]]))
  expect_true(all(sommier_verifier_photos(con, f$foret, depot)$statut ==
                    "conforme"))
  expect_true(sommier_verifier(con, f$foret)$valide)

  # A l'aller suivant, les deux photos du dernier controle reviennent par la
  # couche `photos` seule.
  suivant <- file.path(withr::local_tempdir(), "travaux")
  sommier_projet_qfield_travaux(con, f$foret, suivant, "P. O.", depot = depot)
  retour <- sf::read_sf(file.path(suivant, "travaux.gpkg"), "photos")
  expect_equal(nrow(retour), 2L)
  expect_equal(retour$constat_uuid, rep(t$k, 2L))
  expect_true(all(file.exists(file.path(suivant, retour$fichier))))
  expect_false("photos_terrain" %in%
                 sf::st_layers(file.path(suivant, "travaux.gpkg"))$name)
  # Rapportee telle quelle, cette tournee n'ecrit rien de plus.
  encore <- sommier_importer_qfield_travaux(con, f$foret, suivant, depot,
                                            auteur = "test")
  expect_equal(c(encore$controles, encore$photos), c(0L, 0L))
})

test_that("une description de photo qui ne colle pas refuse la tournee, en clair", {
  skip_if_not_installed("sf")
  skip_if_not_installed("xml2")
  con <- base_travaux_qfield()
  f <- foret_tournee(con)
  dossier <- file.path(withr::local_tempdir(), "travaux")
  depot <- file.path(withr::local_tempdir(), "photos")
  t <- tournee_photos(con, f, dossier)
  gpkg <- file.path(dossier, "travaux.gpkg")
  pt <- photos_terrain_surculus(
    c(t$ph[["placette"]], uuid_v4()), c("arbre", "plant"), f$placette,
    NA_character_, c(strrep("0", 64), NA))
  sf::st_write(pt, gpkg, layer = "photos_terrain", quiet = TRUE)
  err <- tryCatch(
    sommier_importer_qfield_travaux(con, f$foret, dossier, depot,
                                    auteur = "test"),
    error = function(e) conditionMessage(e))
  expect_match(err, "rien n'est ecrit")
  expect_match(err, "sujet inconnu")
  expect_match(err, "sha256 declare")
  expect_match(err, "aucune photo")
  expect_equal(DBI::dbGetQuery(
    con, "SELECT count(*)::int AS n FROM entree_sommier WHERE id = $1",
    params = list(t$k))$n, 0L)
})

test_that("une colonne en trop, une empreinte vide, une photo en double : l'import passe et le dit", {
  skip_if_not_installed("sf")
  skip_if_not_installed("xml2")
  con <- base_travaux_qfield()
  f <- foret_tournee(con)
  dossier <- file.path(withr::local_tempdir(), "travaux")
  depot <- file.path(withr::local_tempdir(), "photos")
  t <- tournee_photos(con, f, dossier)
  gpkg <- file.path(dossier, "travaux.gpkg")
  emp <- empreinte_fichier(file.path(dossier, "DCIM",
                                     paste0(t$ph[["placette"]], ".jpg")))
  # Deux lignes pour la photo de placette (la seconde a une empreinte vide) ;
  # plus une colonne que Surculus n'ecrit pas encore.
  pt <- photos_terrain_surculus(
    c(t$ph[["placette"]], t$ph[["placette"]]),
    c("placette", "placette"), f$placette, NA_character_, c(emp, ""))
  pt$colonne_future <- c("a", "b")
  sf::st_write(pt, gpkg, layer = "photos_terrain", quiet = TRUE)
  avertis <- character(0)
  bilan <- withCallingHandlers(
    sommier_importer_qfield_travaux(con, f$foret, dossier, depot,
                                    auteur = "test"),
    warning = function(w) {
      avertis <<- c(avertis, conditionMessage(w))
      invokeRestart("muffleWarning")
    })
  expect_equal(bilan$controles, 1L)
  expect_equal(bilan$photos, 2L)
  expect_length(bilan$avertissements, 3L)
  expect_match(bilan$avertissements[[1L]], "colonne_future")
  expect_match(bilan$avertissements[[2L]], "sha256 vide")
  expect_match(bilan$avertissements[[3L]], "la premiere est gardee")
  expect_equal(avertis, bilan$avertissements)
  # La premiere ligne fait foi ; la colonne en trop n'arrive pas au registre.
  pla <- bilan$entrees[[1L]]$payload$photos[[1L]]$terrain
  expect_equal(pla$sha256, emp)
  expect_null(pla$colonne_future)
  expect_true(sommier_verifier(con, f$foret)$valide)
})

test_that("une empreinte vide sur une ligne unique : gardee, avertissement, absente du payload", {
  skip_if_not_installed("sf")
  skip_if_not_installed("xml2")
  con <- base_travaux_qfield()
  f <- foret_tournee(con)
  dossier <- file.path(withr::local_tempdir(), "travaux")
  depot <- file.path(withr::local_tempdir(), "photos")
  t <- tournee_photos(con, f, dossier)
  gpkg <- file.path(dossier, "travaux.gpkg")
  pt <- photos_terrain_surculus(t$ph[["placette"]], "placette", f$placette,
                                NA_character_, "")
  sf::st_write(pt, gpkg, layer = "photos_terrain", quiet = TRUE)
  bilan <- suppressWarnings(
    sommier_importer_qfield_travaux(con, f$foret, dossier, depot,
                                    auteur = "test"))
  expect_equal(bilan$photos, 2L)
  expect_length(bilan$avertissements, 1L)
  expect_match(bilan$avertissements, "sha256 vide")
  pla <- bilan$entrees[[1L]]$payload$photos[[1L]]$terrain
  expect_equal(pla$sujet, "placette")
  expect_null(pla$sha256)
  expect_equal(pla$fix_scr, "EPSG:2154")
})

test_that("une couche photos_terrain aux colonnes manquantes est une faute lisible, les colonnes en trop non", {
  skip_if_not_installed("sf")
  skip_if_not_installed("xml2")
  con <- base_travaux_qfield()
  f <- foret_tournee(con)
  dossier <- file.path(withr::local_tempdir(), "travaux")
  depot <- file.path(withr::local_tempdir(), "photos")
  t <- tournee_photos(con, f, dossier)
  gpkg <- file.path(dossier, "travaux.gpkg")
  pt <- photos_terrain_surculus(
    unname(t$ph), c("placette", "plant"), f$placette, NA_character_,
    NA_character_)
  # Sans sha256, avec une colonne que Surculus n'ecrit pas.
  pt$sha256 <- NULL
  pt$colonne_inventee <- 1
  sf::st_write(pt, gpkg, layer = "photos_terrain", quiet = TRUE)
  err <- tryCatch(
    sommier_importer_qfield_travaux(con, f$foret, dossier, depot,
                                    auteur = "test"),
    error = function(e) e)
  expect_match(conditionMessage(err), "colonne\\(s\\) manquante\\(s\\) : sha256")
  # La colonne en trop n'est pas une faute (elle est ignoree, avertissement).
  expect_false(grepl("colonne_inventee", conditionMessage(err)))
  expect_false(grepl("missing value", conditionMessage(err)))
})

# Mission 028 : les deux comptages de plants d'un controle (nb_plants_vivants,
# nb_plants_concurrences) sont lus a l'import et passes a registre6_controle().
# Un jour different a chaque appel : une placette ne se controle qu'une fois
# par jour.
jours_comptages <- new.env()
jours_comptages$n <- 0L
importer_comptages <- function(con, f, ...) {
  jours_comptages$n <- jours_comptages$n + 1L
  jour <- sprintf("2026-07-%02d", jours_comptages$n)
  dossier <- file.path(withr::local_tempdir(), "travaux")
  sommier_projet_qfield_travaux(con, f$foret, dossier, "P. O.")
  k <- uuid_v4()
  tab <- sf::st_drop_geometry(controle(k, f$placette, 18, jour))
  extra <- list(...)
  for (n in names(extra)) tab[[n]] <- extra[[n]]
  sf::st_write(tab, file.path(dossier, "travaux.gpkg"), layer = "controles",
               delete_layer = TRUE, quiet = TRUE)
  av <- character(0)
  bilan <- withCallingHandlers(
    sommier_importer_qfield_travaux(con, f$foret, dossier,
                                    withr::local_tempdir(), auteur = "test"),
    warning = function(w) {
      av <<- c(av, conditionMessage(w))
      invokeRestart("muffleWarning")
    })
  list(bilan = bilan, payload = bilan$entrees[[1L]]$payload, warnings = av)
}

test_that("l'import deduit la concurrence des deux comptages", {
  skip_if_not_installed("sf")
  skip_if_not_installed("xml2")
  con <- base_travaux_qfield()
  f <- foret_tournee(con)
  # 6 sur 10 = 60 % : forte ; le niveau saisi est vide.
  r <- importer_comptages(con, f, nb_plants_vivants = 10L,
                          nb_plants_concurrences = 6L,
                          concurrence = NA_character_)
  expect_equal(r$payload$concurrence, "forte")
  expect_equal(r$payload$nb_plants_vivants, 10L)
  expect_equal(r$payload$nb_plants_concurrences, 6L)
  expect_null(r$payload$concurrence_calculee)
  expect_length(r$bilan$avertissements, 0L)
})

test_that("un niveau saisi qui contredit les comptages est garde et signale", {
  skip_if_not_installed("sf")
  skip_if_not_installed("xml2")
  con <- base_travaux_qfield()
  f <- foret_tournee(con)
  # Saisi : moyenne ; comptages : 6 sur 10 = forte.
  r <- importer_comptages(con, f, nb_plants_vivants = 10L,
                          nb_plants_concurrences = 6L)
  expect_equal(r$payload$concurrence, "moyenne")
  expect_equal(r$payload$concurrence_calculee, "forte")
  expect_length(r$bilan$avertissements, 1L)
  expect_match(r$bilan$avertissements, "^controle 1 : concurrence saisie")
  # Le warning() final reprend le bilan, une seule fois.
  expect_length(r$warnings, 1L)
})

test_that("0 sur 0 : aucun niveau, saisi conserve, aucun signalement", {
  skip_if_not_installed("sf")
  skip_if_not_installed("xml2")
  con <- base_travaux_qfield()
  f <- foret_tournee(con)
  r <- importer_comptages(con, f, nb_plants_vivants = 0L,
                          nb_plants_concurrences = 0L)
  expect_equal(r$payload$concurrence, "moyenne")
  expect_null(r$payload$concurrence_calculee)
  expect_length(r$bilan$avertissements, 0L)
  r <- importer_comptages(con, f, nb_plants_vivants = 0L,
                          nb_plants_concurrences = 0L,
                          concurrence = NA_character_)
  expect_null(r$payload$concurrence)
})

test_that("colonnes absentes, NA ou isolees : rien ne bloque", {
  skip_if_not_installed("sf")
  skip_if_not_installed("xml2")
  con <- base_travaux_qfield()
  f <- foret_tournee(con)
  # Absentes : comme avant.
  r <- importer_comptages(con, f)
  expect_null(r$payload$nb_plants_vivants)
  expect_equal(r$payload$concurrence, "moyenne")
  expect_length(r$bilan$avertissements, 0L)
  # Presentes mais NA.
  r <- importer_comptages(con, f, nb_plants_vivants = NA_integer_,
                          nb_plants_concurrences = NA_integer_)
  expect_null(r$payload$nb_plants_vivants)
  expect_length(r$bilan$avertissements, 0L)
  # Seule la colonne des vivants : inscrite, rien a deduire.
  r <- importer_comptages(con, f, nb_plants_vivants = 12L)
  expect_equal(r$payload$nb_plants_vivants, 12L)
  expect_null(r$payload$nb_plants_concurrences)
  expect_equal(r$payload$concurrence, "moyenne")
  # Seule la colonne des concurrences (colonne des vivants absente) : le
  # nombre est garde brut, aucun niveau deduit, signale.
  r <- importer_comptages(con, f, nb_plants_concurrences = 3L)
  expect_equal(r$payload$nb_plants_concurrences, 3L)
  expect_null(r$payload$nb_plants_vivants)
  expect_equal(r$payload$concurrence, "moyenne")
  expect_null(r$payload$concurrence_calculee)
  expect_length(r$bilan$avertissements, 1L)
  expect_match(r$bilan$avertissements, "sans plants vivants notes")
  # Un seul message, relaye une fois par le warning() final.
  expect_length(r$warnings, 1L)
  # Vivants presents mais NA, concurrences renseignees : meme sort.
  r <- importer_comptages(con, f, nb_plants_vivants = NA_integer_,
                          nb_plants_concurrences = 3L,
                          concurrence = NA_character_)
  expect_equal(r$payload$nb_plants_concurrences, 3L)
  expect_null(r$payload$nb_plants_vivants)
  expect_null(r$payload$concurrence)
  expect_length(r$bilan$avertissements, 1L)
  expect_match(r$bilan$avertissements, "sans plants vivants notes")
  expect_length(r$warnings, 1L)
})

test_that("plus de plants notes que de vivants : la tournee est refusee", {
  skip_if_not_installed("sf")
  skip_if_not_installed("xml2")
  con <- base_travaux_qfield()
  f <- foret_tournee(con)
  # Le controle compte 18 vivants ; 25 plants notes.
  erreur <- tryCatch(
    importer_comptages(con, f, nb_plants_vivants = 25L,
                       nb_plants_concurrences = 2L),
    error = conditionMessage)
  expect_match(erreur, "rien n'est ecrit")
  expect_match(erreur, "Plus de plants notes")
})

test_that("concurrences > vivants : la regle de registre6_controle() refuse", {
  skip_if_not_installed("sf")
  skip_if_not_installed("xml2")
  con <- base_travaux_qfield()
  f <- foret_tournee(con)
  erreur <- tryCatch(
    importer_comptages(con, f, nb_plants_vivants = 4L,
                       nb_plants_concurrences = 9L),
    error = conditionMessage)
  expect_match(erreur, "rien n'est ecrit")
  expect_match(erreur, "Plus de plants au contact")
})

# Mission 052 : la position mesuree du controle, du terrain au registre.
# Un jour different a chaque appel (une placette ne se controle qu'une fois
# par jour).
jours_position <- new.env()
jours_position$n <- 0L
jour_position <- function() {
  jours_position$n <- jours_position$n + 1L
  sprintf("2026-08-%02d", jours_position$n)
}

lambert_vers_wgs84 <- function(x, y) {
  m <- sf::st_coordinates(sf::st_transform(
    sf::st_sfc(sf::st_point(c(x, y)), crs = 2154), 4326))
  geom_point(m[1L, 1L], m[1L, 2L])
}

ligne_controle <- function(con, id) {
  DBI::dbGetQuery(
    con,
    "SELECT a_position_mesuree, precision_position_m, rattache_par_identite,
            sans_position_mesuree, position_mesuree IS NULL AS sans_point,
            ST_X(ST_Transform(position_mesuree, 4326)) AS lon,
            ST_Y(ST_Transform(position_mesuree, 4326)) AS lat,
            ST_X(position_mesuree) AS x, ST_Y(position_mesuree) AS y,
            ST_SRID(position_mesuree) AS srid
       FROM v_controle_plantation WHERE id = $1", params = list(id))
}

test_that("un controle avec position mesuree : payload, geom et vue la rendent", {
  skip_if_not_installed("sf")
  con <- base_travaux_qfield()
  f <- foret_tournee(con)
  k <- uuid_v4()
  e <- sommier_controler_placette(
    con, f$placette, 20, 15, "agent-01", visite_le = "2026-08-20T09:00:00Z",
    id = k, geometrie = lambert_vers_wgs84(600151.2, 6700099.6),
    precision_m = 0.4, rattache_par_identite = FALSE)[[1L]]
  expect_equal(e$payload$precision_m, 0.4)
  expect_equal(e$payload$geometrie$type, "Point")
  # entree_sommier.geom : la projection Lambert-93 du point du payload.
  g <- DBI::dbGetQuery(con, "SELECT ST_X(geom) AS x, ST_Y(geom) AS y,
                                    ST_SRID(geom) AS srid
                               FROM entree_sommier WHERE id = $1",
                       params = list(k))
  expect_equal(g$srid, 2154L)
  expect_lt(sqrt((g$x - 600151.2)^2 + (g$y - 6700099.6)^2), 0.05)
  v <- ligne_controle(con, k)
  expect_true(v$a_position_mesuree)
  expect_equal(v$precision_position_m, 0.4)
  expect_false(v$rattache_par_identite)
  expect_true(is.na(v$sans_position_mesuree))
  expect_equal(v$srid, 2154L)
  expect_lt(sqrt((v$x - 600151.2)^2 + (v$y - 6700099.6)^2), 0.05)
  # Un controle francais tombe en France.
  expect_true(v$lon > -5.5 && v$lon < 10 && v$lat > 41 && v$lat < 51.5)
  # La position mesuree n'est pas le centre de la placette.
  expect_gt(DBI::dbGetQuery(
    con, "SELECT ST_Distance(c.position_mesuree, p.geom) AS d
            FROM v_controle_plantation c JOIN v_placette p ON p.id = c.placette_id
           WHERE c.id = $1", params = list(k))$d, 1)
  expect_true(sommier_verifier(con, f$foret)$valide)
})

test_that("un controle sans position mesuree : pas de geom, drapeau vrai, jamais (0, 0)", {
  skip_if_not_installed("sf")
  con <- base_travaux_qfield()
  f <- foret_tournee(con)
  k <- uuid_v4()
  e <- sommier_controler_placette(
    con, f$placette, 20, 15, "agent-01", visite_le = "2026-08-21T09:00:00Z",
    id = k, sans_position_mesuree = TRUE, rattache_par_identite = TRUE)[[1L]]
  expect_false("geometrie" %in% names(e$payload))
  expect_true(DBI::dbGetQuery(
    con, "SELECT geom IS NULL AS n FROM entree_sommier WHERE id = $1",
    params = list(k))$n)
  v <- ligne_controle(con, k)
  expect_false(v$a_position_mesuree)
  expect_true(v$sans_point)
  expect_true(v$sans_position_mesuree)
  expect_true(v$rattache_par_identite)
  expect_true(is.na(v$precision_position_m))
  # Aucun point a l'origine nulle part dans le registre.
  expect_equal(DBI::dbGetQuery(
    con, "SELECT count(*)::int AS n FROM v_controle_plantation
           WHERE position_mesuree IS NOT NULL
             AND ST_X(position_mesuree) = 0 AND ST_Y(position_mesuree) = 0")$n, 0L)
  expect_true(sommier_verifier(con, f$foret)$valide)
})

test_that("un controle a l'ancienne : memes champs qu'avant, chaine verifiee", {
  skip_if_not_installed("sf")
  con <- base_travaux_qfield()
  f <- foret_tournee(con)
  k <- uuid_v4()
  e <- sommier_controler_placette(
    con, f$placette, 20, 15, "agent-01", visite_le = "2026-08-22T09:00:00Z",
    id = k, besoin = "aucun")[[1L]]
  expect_false(any(c("geometrie", "precision_m", "rattache_par_identite",
                     "sans_position_mesuree") %in% names(e$payload)))
  v <- ligne_controle(con, k)
  expect_false(v$a_position_mesuree)
  expect_true(is.na(v$sans_position_mesuree))
  expect_true(is.na(v$rattache_par_identite))
  # Les colonnes d'avant n'ont ni change de nom ni de place.
  anciennes <- c("id", "foret_id", "ug_uuid", "seq", "visite_le", "auteur",
                 "placette_id", "code_placette", "travaux_id", "annee_travaux",
                 "code_travaux", "age_ans", "nb_total", "nb_vivants",
                 "h_moy_cm", "nb_abroutis", "concurrence", "besoin",
                 "operateur", "taux_reprise_pct", "densite_ha", "abroutis_pct")
  colonnes <- names(DBI::dbGetQuery(
    con, "SELECT * FROM v_controle_plantation LIMIT 0"))
  expect_equal(colonnes[seq_along(anciennes)], anciennes)
  expect_equal(colonnes[-seq_along(anciennes)],
               c("position_mesuree", "a_position_mesuree",
                 "precision_position_m", "rattache_par_identite",
                 "sans_position_mesuree"))
  expect_true(sommier_verifier(con, f$foret)$valide)
})

ecrire_positions <- function(dossier, uuids, x, y, precision, rattache, sans,
                             crs = 2154) {
  if (is.na(crs)) crs <- sf::NA_crs_
  geometries <- Map(function(a, b) {
    if (is.na(a)) sf::st_point() else sf::st_point(c(a, b))
  }, x, y)
  couche <- sf::st_sf(
    controle_uuid = uuids, precision_m = precision,
    rattache_par_identite = rattache, sans_position_mesuree = sans,
    geometry = sf::st_sfc(geometries, crs = crs))
  sf::st_write(couche, file.path(dossier, "travaux.gpkg"),
               layer = "positions_controles", delete_layer = TRUE, quiet = TRUE)
}

test_that("l'import lit positions_controles : un point, une geometrie NULL", {
  skip_if_not_installed("sf")
  skip_if_not_installed("xml2")
  skip_if_not_installed("RSQLite")
  con <- base_travaux_qfield()
  f <- foret_tournee(con)
  dossier <- file.path(withr::local_tempdir(), "travaux")
  sommier_projet_qfield_travaux(con, f$foret, dossier, "P. O.")
  k1 <- uuid_v4()
  k2 <- uuid_v4()
  saisir(dossier, "controles", rbind(
    controle(k1, f$placette, 18, "2026-09-01"),
    controle(k2, f$placette, 17, "2026-09-02")))
  ecrire_positions(dossier, c(k1, k2), c(600151.2, 600150), c(6700099.6, 6700100),
                   c(0.4, NA), c(FALSE, TRUE), c(FALSE, TRUE))
  # Surculus ecrit une vraie geometrie NULL (pas un POINT EMPTY) : on la pose.
  db <- DBI::dbConnect(RSQLite::SQLite(), file.path(dossier, "travaux.gpkg"))
  # Les declencheurs du GeoPackage appellent ST_IsEmpty, que SQLite seul n'a pas.
  for (t in DBI::dbGetQuery(db, "SELECT name FROM sqlite_master
                                  WHERE type = 'trigger'
                                    AND tbl_name = 'positions_controles'")$name) {
    DBI::dbExecute(db, paste0("DROP TRIGGER \"", t, "\""))
  }
  DBI::dbExecute(db, "UPDATE positions_controles SET geom = NULL
                       WHERE controle_uuid = ?", params = list(k2))
  DBI::dbDisconnect(db)
  bilan <- sommier_importer_qfield_travaux(con, f$foret, dossier,
                                           withr::local_tempdir(),
                                           auteur = "test")
  expect_equal(bilan$controles, 2L)
  expect_length(bilan$avertissements, 0L)
  v1 <- ligne_controle(con, k1)
  expect_true(v1$a_position_mesuree)
  expect_equal(v1$precision_position_m, 0.4)
  expect_false(v1$rattache_par_identite)
  expect_lt(sqrt((v1$x - 600151.2)^2 + (v1$y - 6700099.6)^2), 0.05)
  v2 <- ligne_controle(con, k2)
  expect_false(v2$a_position_mesuree)
  expect_true(v2$sans_position_mesuree)
  expect_true(v2$rattache_par_identite)
  expect_true(is.na(v2$precision_position_m))
  p2 <- Filter(function(e) e$id == k2, bilan$entrees)[[1L]]$payload
  expect_false("geometrie" %in% names(p2))
  # Le rejeu n'ecrit rien de plus.
  encore <- sommier_importer_qfield_travaux(con, f$foret, dossier,
                                            withr::local_tempdir(),
                                            auteur = "test")
  expect_equal(encore$controles, 0L)
  expect_true(sommier_verifier(con, f$foret)$valide)
})

test_that("un POINT EMPTY de la couche vaut une absence de mesure, pas (0, 0)", {
  skip_if_not_installed("sf")
  skip_if_not_installed("xml2")
  con <- base_travaux_qfield()
  f <- foret_tournee(con)
  dossier <- file.path(withr::local_tempdir(), "travaux")
  sommier_projet_qfield_travaux(con, f$foret, dossier, "P. O.")
  k <- uuid_v4()
  saisir(dossier, "controles", controle(k, f$placette, 18, "2026-09-03"))
  # Le drapeau n'est pas rempli : la geometrie vide suffit a dire « sans ».
  ecrire_positions(dossier, k, NA_real_, NA_real_, NA_real_, NA, NA)
  bilan <- sommier_importer_qfield_travaux(con, f$foret, dossier,
                                           withr::local_tempdir(),
                                           auteur = "test")
  expect_equal(bilan$controles, 1L)
  v <- ligne_controle(con, k)
  expect_false(v$a_position_mesuree)
  expect_true(v$sans_position_mesuree)
  expect_true(v$sans_point)
})

test_that("une tournee sans la couche positions_controles s'importe comme avant", {
  skip_if_not_installed("sf")
  skip_if_not_installed("xml2")
  con <- base_travaux_qfield()
  f <- foret_tournee(con)
  dossier <- file.path(withr::local_tempdir(), "travaux")
  sommier_projet_qfield_travaux(con, f$foret, dossier, "P. O.")
  expect_false("positions_controles" %in% sf::st_layers(
    file.path(dossier, "travaux.gpkg"))$name)
  k <- uuid_v4()
  saisir(dossier, "controles", controle(k, f$placette, 18, "2026-09-04"))
  bilan <- sommier_importer_qfield_travaux(con, f$foret, dossier,
                                           withr::local_tempdir(),
                                           auteur = "test")
  expect_equal(bilan$controles, 1L)
  expect_length(bilan$avertissements, 0L)
  expect_false(any(c("geometrie", "precision_m", "rattache_par_identite",
                     "sans_position_mesuree") %in%
                     names(bilan$entrees[[1L]]$payload)))
  v <- ligne_controle(con, k)
  expect_false(v$a_position_mesuree)
  expect_true(is.na(v$sans_position_mesuree))
})

test_that("une position invalide refuse la tournee, rien n'est ecrit", {
  skip_if_not_installed("sf")
  skip_if_not_installed("xml2")
  con <- base_travaux_qfield()
  f <- foret_tournee(con)
  avant <- sommier_verifier(con, f$foret)$hash_tete
  essayer <- function(motif, ...) {
    dossier <- file.path(withr::local_tempdir(), "travaux")
    sommier_projet_qfield_travaux(con, f$foret, dossier, "P. O.")
    k <- uuid_v4()
    saisir(dossier, "controles", controle(k, f$placette, 18, jour_position()))
    ecrire_positions(dossier, k, ...)
    expect_error(
      sommier_importer_qfield_travaux(con, f$foret, dossier,
                                      withr::local_tempdir(),
                                      auteur = "test"),
      motif)
    expect_equal(sommier_verifier(con, f$foret)$hash_tete, avant)
    expect_equal(nrow(DBI::dbGetQuery(
      con, "SELECT 1 FROM entree_sommier WHERE id = $1", params = list(k))), 0L)
  }
  # Des metres declares en degres : hors des bornes WGS 84.
  essayer("rien n'est ecrit.*hors des bornes WGS 84",
          600150, 6700100, 0.4, FALSE, FALSE, crs = 4326)
  # Une position qui contredit son drapeau.
  essayer("sans_position_mesuree.*geometrie",
          600150, 6700100, 0.4, FALSE, TRUE)
  # Une precision sans position.
  essayer("precision_m", NA_real_, NA_real_, 3, TRUE, TRUE)
})

test_that("une position sans SCR, un doublon et un orphelin sont dits", {
  skip_if_not_installed("sf")
  skip_if_not_installed("xml2")
  con <- base_travaux_qfield()
  f <- foret_tournee(con)
  # Sans SCR : refuse.
  dossier <- file.path(withr::local_tempdir(), "travaux")
  sommier_projet_qfield_travaux(con, f$foret, dossier, "P. O.")
  k <- uuid_v4()
  saisir(dossier, "controles", controle(k, f$placette, 18, "2026-09-10"))
  ecrire_positions(dossier, k, 600150, 6700100, 0.4, FALSE, FALSE, crs = NA)
  expect_error(sommier_importer_qfield_travaux(con, f$foret, dossier,
                                               withr::local_tempdir(),
                                               auteur = "test"),
               "pas de systeme de coordonnees")
  # Deux lignes pour un meme controle : refuse.
  ecrire_positions(dossier, c(k, k), c(600150, 600151), c(6700100, 6700100),
                   c(0.4, 0.4), c(FALSE, FALSE), c(FALSE, FALSE))
  expect_error(sommier_importer_qfield_travaux(con, f$foret, dossier,
                                               withr::local_tempdir(),
                                               auteur = "test"),
               "deux positions pour le controle")
  # Une ligne pour un controle absent : ignoree, et dite.
  orphelin <- uuid_v4()
  ecrire_positions(dossier, c(k, orphelin), c(600150, 600151),
                   c(6700100, 6700100), c(0.4, 0.4), c(FALSE, FALSE),
                   c(FALSE, FALSE))
  av <- character(0)
  bilan <- withCallingHandlers(
    sommier_importer_qfield_travaux(con, f$foret, dossier,
                                    withr::local_tempdir(), auteur = "test"),
    warning = function(w) {
      av <<- c(av, conditionMessage(w))
      invokeRestart("muffleWarning")
    })
  expect_equal(bilan$controles, 1L)
  expect_match(bilan$avertissements, orphelin, fixed = TRUE)
  expect_match(av, "controle absent de la tournee")
})

test_that("une position hors WGS 84 par l'API R : refus clair, rien n'est ecrit", {
  skip_if_not_installed("sf")
  con <- base_travaux_qfield()
  f <- foret_tournee(con)
  avant <- sommier_verifier(con, f$foret)$hash_tete
  expect_error(
    sommier_controler_placette(
      con, f$placette, 20, 15, "agent-01", visite_le = "2026-08-30T09:00:00Z",
      geometrie = list(type = "Point", coordinates = c(600150, 6700100))),
    "point WGS 84")
  expect_equal(sommier_verifier(con, f$foret)$hash_tete, avant)
})
