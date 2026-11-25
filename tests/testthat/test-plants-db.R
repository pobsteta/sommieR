# Les plants pointes et suivis d'un passage a l'autre, contre une base reelle
# (mission 054, brief travaux-2).

base_plants <- function(env = parent.frame()) {
  con <- sauter_sans_base()
  withr::defer(DBI::dbDisconnect(con), envir = env)
  sommier_init_schema(con)
  con
}

# Une unite, une plantation de chene (essence objectif CHS) et une placette.
foret_plants <- function(con) {
  foret <- foret_creer(con, paste0("Foret plants-", substr(uuid_v4(), 1L, 8L)),
                       "communal")
  ug <- ug_creer(con, foret, "35", "2010-01-01")
  DBI::dbExecute(con,
    "INSERT INTO ug_geometrie (ug_uuid, version, geom, source, date_debut)
     VALUES ($1, 1, ST_Multi(ST_GeomFromText('POLYGON((600000 6700000,
       600300 6700000, 600300 6700200, 600000 6700200, 600000 6700000))',
       2154)), 'test', '2010-01-01')", params = list(ug))
  plantation <- sommier_ajouter(con, sommier_entree(
    foret_id = foret, registre = 6L, date_evenement = "2024-11-20",
    auteur = "agent-01", ug_uuid = ug,
    payload = registre6_travaux(2024, "plantation", code_travaux = "PL",
                                quantite = 2, unite = "ha", prevu = "prevu",
                                essence_objectif = "CHS")))[[1L]]$id
  placette <- sommier_installer_placette(
    con, plantation, "P35-01", pt_wgs(0, 0), "agent-01",
    date_evenement = "2024-12-01")[[1L]]$id
  list(foret = foret, ug = ug, plantation = plantation, placette = placette)
}

# Un point a (dx, dy) metres du centre de la placette (Lambert-93), en WGS 84.
pt_wgs <- function(dx, dy) {
  m <- sf::st_coordinates(sf::st_transform(
    sf::st_sfc(sf::st_point(c(600150 + dx, 6700100 + dy)), crs = 2154), 4326))
  geom_point(m[1L, 1L], m[1L, 2L])
}

pointer <- function(con, placette, numero, jour = "2025-06-10", ...) {
  sommier_pointer_plant(con, placette, pt_wgs(numero, 1), numero, "agent-01",
                        date_evenement = jour, ...)[[1L]]$id
}

etat <- function(id, e, ...) list(plant_id = id, etat = e, ...)

nb_entrees <- function(con, foret) {
  DBI::dbGetQuery(con, "SELECT count(*)::int AS n FROM entree_sommier
                         WHERE foret_id = $1", params = list(foret))$n
}

test_that("un plant s'inscrit au registre 6, rattache a sa placette, la chaine se verifie", {
  con <- base_plants()
  f <- foret_plants(con)
  e <- sommier_pointer_plant(
    con, f$placette, pt_wgs(1.5, 2), 1, "agent-01", date_evenement = "2025-06-10",
    distance_m = 2.5, azimut_mag = 36.5, unite_azimut = "deg",
    azimut_geo_deg = 37, modele_geomagnetique = "WMM2025")[[1L]]
  expect_equal(e$schema_version, "r6-1.3.0")
  v <- DBI::dbGetQuery(con, "SELECT * FROM v_plant WHERE foret_id = $1",
                       params = list(f$foret))
  expect_equal(nrow(v), 1L)
  expect_equal(v$id, e$id)
  expect_equal(v$placette_id, f$placette)
  expect_equal(v$code_placette, "P35-01")
  expect_equal(v$numero, 1L)
  # L'essence est celle des travaux suivis, a defaut d'etre donnee.
  expect_equal(v$essence, "CHS")
  expect_false(v$regarni)
  expect_false(is.na(v$distance_m))
  autre <- pointer(con, f$placette, 2, essence = "PEO")
  expect_equal(DBI::dbGetQuery(con, "SELECT essence FROM v_plant WHERE id = $1",
                               params = list(autre))$essence, "PEO")
  expect_true(sommier_verifier(con, f$foret)$valide)
})

test_that("un plant refuse : placette inconnue, numero deja pris, UUID deja inscrit", {
  con <- base_plants()
  f <- foret_plants(con)
  id <- pointer(con, f$placette, 1)
  n <- nb_entrees(con, f$foret)
  expect_error(sommier_pointer_plant(con, uuid_v4(), pt_wgs(1, 1), 1,
                                     "agent-01"), "Placette inconnue")
  expect_error(sommier_pointer_plant(con, f$placette, pt_wgs(1, 1), 1,
                                     "agent-01"), "deja pris")
  expect_error(sommier_pointer_plant(con, f$placette, pt_wgs(1, 1), 9,
                                     "agent-01", id = id))
  # Une plantation n'est pas une placette.
  expect_error(sommier_pointer_plant(con, f$plantation, pt_wgs(1, 1), 3,
                                     "agent-01"), "Placette inconnue")
  expect_equal(nb_entrees(con, f$foret), n)
})

test_that("un controle porte l'etat de ses plants : totaux deduits, contradiction refusee avant toute ecriture", {
  con <- base_plants()
  f <- foret_plants(con)
  p <- vapply(1:4, function(i) pointer(con, f$placette, i), "")
  etats <- list(etat(p[1], "sain", hauteur_cm = 40L, cause_detail = "abroutissement"),
                etat(p[2], "atteint", cause_groupe = "animaux", hauteur_cm = 50L),
                etat(p[3], "mort"), etat(p[4], "absent"))
  n <- nb_entrees(con, f$foret)
  expect_error(sommier_controler_placette(
    con, f$placette, 4, 3, "agent-01", visite_le = "2025-06-10T09:00:00Z",
    plants = etats), "nb_vivants")
  expect_equal(nb_entrees(con, f$foret), n)
  k <- sommier_controler_placette(con, f$placette, auteur = "agent-01",
                                  visite_le = "2025-06-10T09:00:00Z",
                                  plants = etats)[[1L]]
  v <- DBI::dbGetQuery(con, "SELECT nb_total, nb_vivants, nb_abroutis, h_moy_cm,
    taux_reprise_pct FROM v_controle_plantation WHERE id = $1",
    params = list(k$id))
  expect_equal(unlist(v[1, 1:4]), c(nb_total = 4, nb_vivants = 2,
                                    nb_abroutis = 1, h_moy_cm = 45))
  expect_equal(v$taux_reprise_pct, 50)
  # Deuxieme passage : chaque plant a deux etats, uuid et numero inchanges.
  sommier_controler_placette(
    con, f$placette, auteur = "agent-01", visite_le = "2026-06-10T09:00:00Z",
    plants = list(etat(p[1], "sain"), etat(p[2], "mort"),
                  etat(p[3], "mort"), etat(p[4], "absent")))
  ep <- DBI::dbGetQuery(con, "SELECT plant_id::text, numero, count(*)::int AS n
    FROM v_etat_plant WHERE foret_id = $1 GROUP BY 1, 2 ORDER BY 2",
    params = list(f$foret))
  expect_equal(ep$n, rep(2L, 4L))
  expect_equal(ep$plant_id, p)
  expect_true(sommier_verifier(con, f$foret)$valide)
})

test_that("un plant mort ou absent le reste ; un plant vivant doit avoir un etat", {
  con <- base_plants()
  f <- foret_plants(con)
  p <- vapply(1:3, function(i) pointer(con, f$placette, i), "")
  sommier_controler_placette(con, f$placette, auteur = "agent-01",
    visite_le = "2025-06-10T09:00:00Z",
    plants = list(etat(p[1], "sain"), etat(p[2], "mort"), etat(p[3], "absent")))
  n <- nb_entrees(con, f$foret)
  # Un mort redit vivant : refuse.
  expect_error(sommier_controler_placette(con, f$placette, auteur = "agent-01",
    visite_le = "2026-06-10T09:00:00Z",
    plants = list(etat(p[1], "sain"), etat(p[2], "sain"))), "mort")
  # Un vivant sans etat : refuse.
  expect_error(sommier_controler_placette(con, f$placette, auteur = "agent-01",
    visite_le = "2026-06-10T09:00:00Z", plants = list(etat(p[2], "mort"))),
    "il en faut un")
  # Un plant d'une autre placette ou inconnu : refuse.
  expect_error(sommier_controler_placette(con, f$placette, auteur = "agent-01",
    visite_le = "2026-06-10T09:00:00Z",
    plants = list(etat(p[1], "sain"), etat(uuid_v4(), "sain"))), "inconnu")
  expect_equal(nb_entrees(con, f$foret), n)
  # Un mort ou un absent omis : refuse (il sortirait de nb_total).
  expect_error(sommier_controler_placette(con, f$placette, auteur = "agent-01",
    visite_le = "2026-06-10T09:00:00Z", plants = list(etat(p[1], "sain"))),
    "il en faut un")
  expect_equal(nb_entrees(con, f$foret), n)
  # Non observe : un plant sans mesure, hors totaux ; mort et absent redits.
  k <- sommier_controler_placette(con, f$placette, auteur = "agent-01",
    visite_le = "2026-06-10T09:00:00Z",
    plants = list(etat(p[1], "non_observe"), etat(p[2], "mort"),
                  etat(p[3], "absent")))[[1L]]
  v <- DBI::dbGetQuery(con, "SELECT nb_total, nb_vivants FROM v_controle_plantation
                             WHERE id = $1", params = list(k$id))
  expect_equal(unlist(v[1, ]), c(nb_total = 2, nb_vivants = 0))
})

test_that("un regarni remplace un mort ou un absent ; le remplace sort des totaux suivants", {
  con <- base_plants()
  f <- foret_plants(con)
  p <- vapply(1:3, function(i) pointer(con, f$placette, i), "")
  sommier_controler_placette(con, f$placette, auteur = "agent-01",
    visite_le = "2025-06-10T09:00:00Z",
    plants = list(etat(p[1], "sain"), etat(p[2], "mort"), etat(p[3], "atteint")))
  # Refus : plant vivant, inconnu, regarni sans remplace_uuid.
  expect_error(pointer(con, f$placette, 4, jour = "2026-06-10", regarni = TRUE,
                       remplace_uuid = p[3]), "mort ou absent")
  expect_error(pointer(con, f$placette, 4, jour = "2026-06-10", regarni = TRUE,
                       remplace_uuid = uuid_v4()), "inconnu")
  expect_error(pointer(con, f$placette, 4, jour = "2026-06-10", regarni = TRUE),
               "remplace_uuid")
  r <- pointer(con, f$placette, 4, jour = "2026-06-10", regarni = TRUE,
               remplace_uuid = p[2])
  # Un second regarni du meme plant : refuse.
  expect_error(pointer(con, f$placette, 5, jour = "2026-06-10", regarni = TRUE,
                       remplace_uuid = p[2]), "deja remplace")
  expect_equal(DBI::dbGetQuery(con, "SELECT remplace_par::text AS r FROM v_plant
                                     WHERE id = $1", params = list(p[2]))$r, r)
  # Le jour de la pose, le mort compte encore : 4 plants.
  k2 <- sommier_controler_placette(con, f$placette, auteur = "agent-01",
    visite_le = "2026-06-10T09:00:00Z",
    plants = list(etat(p[1], "sain"), etat(p[2], "mort"), etat(p[3], "atteint"),
                  etat(r, "sain")))[[1L]]
  expect_null(k2$payload$plants_remplaces)
  # Au controle suivant, il sort ; omis, rien ne manque ; liste, il ne compte pas.
  k3 <- sommier_controler_placette(con, f$placette, auteur = "agent-01",
    visite_le = "2027-06-10T09:00:00Z",
    plants = list(etat(p[1], "sain"), etat(p[2], "mort"), etat(p[3], "atteint"),
                  etat(r, "sain")))[[1L]]
  expect_equal(k3$payload$plants_remplaces, list(p[2]))
  v <- DBI::dbGetQuery(con, "SELECT visite_le::text, nb_total, nb_vivants
    FROM v_controle_plantation WHERE foret_id = $1 ORDER BY visite_le",
    params = list(f$foret))
  expect_equal(v$nb_total, c(3, 4, 3))
  k4 <- sommier_controler_placette(con, f$placette, auteur = "agent-01",
    visite_le = "2028-06-10T09:00:00Z",
    plants = list(etat(p[1], "sain"), etat(p[3], "atteint"), etat(r, "sain")))[[1L]]
  expect_equal(k4$payload$nb_total, 3)
  # Suivi : mortalite entre passages et regarnis, quand des plants existent.
  s <- sommier_suivi_plantations(con, f$foret)
  expect_true(all(c("mortalite_passage_pct", "nb_regarnis") %in% names(s)))
  expect_equal(sum(s$nb_regarnis, na.rm = TRUE), 1L)
  expect_equal(s$mortalite_passage_pct[s$annee_controle == 2025], NA_real_)
  expect_true(sommier_verifier(con, f$foret)$valide)
})

test_that("un controle sans plants reste valide ; une entree r6-1.2.0 se relit, la chaine tient", {
  con <- base_plants()
  f <- foret_plants(con)
  ancien <- sommier_entree(
    foret_id = f$foret, registre = 6L, date_evenement = "2025-06-10",
    auteur = "agent-01", ug_uuid = f$ug,
    payload = registre6_controle(f$placette, 20, 17))
  ancien$schema_version <- "r6-1.2.0"
  sommier_ajouter(con, ancien)
  p <- pointer(con, f$placette, 1)
  sommier_controler_placette(con, f$placette, auteur = "agent-01",
    visite_le = "2026-06-10T09:00:00Z", plants = list(etat(p, "sain")))
  # Un controle par totaux (QField) apres des plants : valide.
  sommier_controler_placette(con, f$placette, 20, 15, "agent-01",
                             visite_le = "2027-06-10T09:00:00Z")
  versions <- DBI::dbGetQuery(con, "SELECT schema_version FROM entree_sommier
    WHERE foret_id = $1 AND payload ->> 'type_entree' = 'controle' ORDER BY seq",
    params = list(f$foret))$schema_version
  expect_equal(versions, c("r6-1.2.0", "r6-1.3.0", "r6-1.3.0"))
  expect_true(sommier_verifier(con, f$foret)$valide)
  expect_equal(nrow(DBI::dbGetQuery(con, "SELECT 1 FROM v_controle_plantation
    WHERE foret_id = $1", params = list(f$foret))), 3L)
})

test_that("le sommier imprime compte les plants sous leur placette, sans ligne par plant", {
  skip_if_not_installed("jsonlite")
  con <- base_plants()
  f <- foret_plants(con)
  p <- vapply(1:3, function(i) pointer(con, f$placette, i), "")
  sommier_controler_placette(con, f$placette, auteur = "agent-01",
    visite_le = "2025-06-10T09:00:00Z",
    plants = list(etat(p[1], "sain"), etat(p[2], "mort"), etat(p[3], "absent")))
  s <- sommier_registre(con, f$foret)
  expect_false("plant" %in% s$ecritures$type_entree)
  l <- s$ecritures$contenu[s$ecritures$type_entree %in% "placette"]
  expect_match(l, "plants pointes : 3 (1 vivants, 1 morts, 1 absents)", fixed = TRUE)
  k <- s$ecritures$contenu[s$ecritures$type_entree %in% "controle"]
  expect_match(k, "plants : 3 (1 vivants, 1 morts, 1 absents)", fixed = TRUE)
  # non_observe se dit "non observes", jamais "sans etat".
  expect_equal(decompte_etats(c("sain", "non_observe")),
               "2 (1 vivants, 0 morts, 0 absents, 1 non observes)")
  # La chaine, elle, garde les plants.
  expect_true(s$verification$valide)
  expect_equal(nrow(sommier_lire(con, f$foret)), 1L + 1L + 3L + 1L)
})

# ---------------------------------------------------------------------------
# L'import de la tournee

couche_plants <- function(placette, lignes) {
  # lignes : liste de list(uuid, numero, dx, dy, regarni, remplace, pointe)
  d <- do.call(rbind, lapply(lignes, function(l) data.frame(
    uuid = l$uuid, placette_uuid = placette, numero = l$numero,
    essence = "CHS", regarni = !is.null(l$remplace),
    remplace_uuid = if (is.null(l$remplace)) NA_character_ else l$remplace,
    pointe_le = as.POSIXct(l$pointe %||% "2026-06-10 08:00:00", tz = "UTC"),
    distance_m = 2, azimut_mag = 10, unite_azimut = "deg",
    declinaison_deg = 1, convergence_deg = 0.5, azimut_geo_deg = 11,
    modele_geomagnetique = "WMM2025", stringsAsFactors = FALSE)))
  x <- vapply(lignes, function(l) 600150 + l$dx, 0)
  y <- vapply(lignes, function(l) 6700100 + l$dy, 0)
  sf::st_sf(d, geom = sf::st_sfc(lapply(seq_along(x), function(i)
    sf::st_point(c(x[i], y[i]))), crs = 2154))
}

couche_etats <- function(controle, etats) {
  do.call(rbind, lapply(etats, function(e) data.frame(
    uuid = uuid_v4(), controle_uuid = controle, plant_uuid = e$plant,
    etat = e$etat, cause_groupe = e$cause_groupe %||% NA_character_,
    cause_detail = e$cause_detail %||% NA_character_,
    hauteur_cm = e$hauteur %||% NA_integer_, stringsAsFactors = FALSE)))
}

ligne_controle <- function(uuid, placette, jour, total, vivants,
                           h = NA_integer_, abroutis = NA_integer_) {
  sf::st_sf(uuid = uuid, placette_uuid = placette, nb_total = total,
            nb_vivants = vivants, h_moy_cm = h, nb_abroutis = abroutis,
            concurrence = NA_character_, besoin = "aucun",
            visite_le = as.POSIXct(paste(jour, "09:00:00"), tz = "UTC"),
            operateur = "P. O.", observations = NA_character_,
            geometry = sf::st_sfc(sf::st_point(c(600150, 6700100)), crs = 2154))
}

projet_tournee <- function(con, f) {
  dossier <- file.path(withr::local_tempdir(.local_envir = parent.frame(2)),
                       "travaux")
  sommier_projet_qfield_travaux(con, f$foret, dossier, "P. O.")
  dossier
}

ecrire_couche_g <- function(dossier, x, nom) {
  suppressWarnings(sf::st_write(x, file.path(dossier, "travaux.gpkg"),
                                layer = nom, append = TRUE, quiet = TRUE))
}

test_that("l'import inscrit plants et etats, rejoue sans doublon ; sans les couches, comme avant", {
  skip_if_not_installed("sf"); skip_if_not_installed("xml2")
  con <- base_plants()
  f <- foret_plants(con)
  depot <- file.path(withr::local_tempdir(), "photos")
  # Une tournee sans les couches de plants : comme avant.
  d0 <- projet_tournee(con, f)
  ecrire_couche_g(d0, ligne_controle(uuid_v4(), f$placette, "2025-06-10", 20, 17),
                  "controles")
  b0 <- sommier_importer_qfield_travaux(con, f$foret, d0, depot, "agent-01")
  expect_equal(c(b0$plants, b0$controles), c(0L, 1L))

  g <- foret_plants(con)  # autre foret : isole le test
  dossier <- projet_tournee(con, g)
  u <- c(uuid_v4(), uuid_v4(), uuid_v4())
  ecrire_couche_g(dossier, couche_plants(g$placette, list(
    list(uuid = u[1], numero = 1, dx = 1, dy = 1),
    list(uuid = u[2], numero = 2, dx = -1, dy = 1),
    list(uuid = u[3], numero = 3, dx = 2, dy = -1))), "plants")
  k <- uuid_v4()
  ecrire_couche_g(dossier, ligne_controle(k, g$placette, "2026-06-10", 3, 2,
                                          h = 45L, abroutis = 1L), "controles")
  ecrire_couche_g(dossier, couche_etats(k, list(
    list(plant = u[1], etat = "sain", hauteur = 40L, cause_detail = "abroutissement"),
    list(plant = u[2], etat = "atteint", hauteur = 50L, cause_groupe = "animaux"),
    list(plant = u[3], etat = "mort"))), "etats_plants")
  b <- sommier_importer_qfield_travaux(con, g$foret, dossier, depot, "agent-01")
  expect_equal(c(b$plants, b$controles), c(3L, 1L))
  v <- DBI::dbGetQuery(con, "SELECT numero, essence FROM v_plant WHERE foret_id = $1
                              ORDER BY numero", params = list(g$foret))
  expect_equal(v$numero, 1:3)
  expect_equal(nrow(DBI::dbGetQuery(con, "SELECT 1 FROM v_etat_plant
                                         WHERE foret_id = $1", params = list(g$foret))), 3L)
  n <- nb_entrees(con, g$foret)
  b2 <- sommier_importer_qfield_travaux(con, g$foret, dossier, depot, "agent-01")
  expect_equal(c(b2$plants, b2$controles), c(0L, 0L))
  expect_equal(nb_entrees(con, g$foret), n)
  expect_true(sommier_verifier(con, g$foret)$valide)
})

test_that("une tournee dont un plant ou un etat est fautif n'ecrit rien du tout", {
  skip_if_not_installed("sf"); skip_if_not_installed("xml2")
  con <- base_plants()
  depot <- file.path(withr::local_tempdir(), "photos")
  essai <- function(modif, motif) {
    g <- foret_plants(con)
    dossier <- projet_tournee(con, g)
    u <- c(uuid_v4(), uuid_v4())
    k <- uuid_v4()
    plants <- list(list(uuid = u[1], numero = 1, dx = 1, dy = 1),
                   list(uuid = u[2], numero = 2, dx = 2, dy = 1))
    etats <- list(list(plant = u[1], etat = "sain"), list(plant = u[2], etat = "mort"))
    total <- 2; vivants <- 1
    placette <- g$placette
    cfg <- modif(list(u = u, k = k, plants = plants, etats = etats,
                      total = total, vivants = vivants, placette = placette))
    ecrire_couche_g(dossier, couche_plants(cfg$placette, cfg$plants), "plants")
    ecrire_couche_g(dossier, ligne_controle(k, g$placette, "2026-06-10",
                                            cfg$total, cfg$vivants), "controles")
    ecrire_couche_g(dossier, couche_etats(cfg$k_etats %||% k, cfg$etats), "etats_plants")
    n <- nb_entrees(con, g$foret)
    expect_error(sommier_importer_qfield_travaux(con, g$foret, dossier, depot,
                                                 "agent-01"), motif)
    expect_equal(nb_entrees(con, g$foret), n)
  }
  essai(function(c) { c$placette <- uuid_v4(); c }, "sans placette")
  essai(function(c) { c$etats[[1]]$plant <- uuid_v4(); c }, "plant inconnu")
  essai(function(c) { c$etats[[3]] <- c$etats[[1]]; c }, "deux etats du meme plant")
  essai(function(c) { c$total <- 3; c }, "ne concorde pas")
  essai(function(c) { c$etats <- c$etats[1]; c$total <- 1; c }, "il en faut un")
  essai(function(c) { c$plants[[2]]$numero <- 1; c }, "pris deux fois")
  essai(function(c) { c$plants[[2]]$remplace <- c$u[1]; c }, "mort ou absent")
  essai(function(c) { c$k_etats <- uuid_v4(); c }, "controle absent de la tournee")
})

test_that("sonde : 2 sains et 2 morts, morts omis au passage 2, est refuse ; le taux ne bondit pas", {
  con <- base_plants()
  f <- foret_plants(con)
  p <- vapply(1:4, function(i) pointer(con, f$placette, i), "")
  sommier_controler_placette(con, f$placette, auteur = "agent-01",
    visite_le = "2025-06-10T09:00:00Z",
    plants = list(etat(p[1], "sain"), etat(p[2], "sain"),
                  etat(p[3], "mort"), etat(p[4], "mort")))
  n <- nb_entrees(con, f$foret)
  expect_error(sommier_controler_placette(con, f$placette, auteur = "agent-01",
    visite_le = "2026-06-10T09:00:00Z",
    plants = list(etat(p[1], "sain"), etat(p[2], "sain"))), "il en faut un")
  expect_equal(nb_entrees(con, f$foret), n)
})

test_that("un etat dans un controle date avant le pointage du plant est refuse", {
  con <- base_plants()
  f <- foret_plants(con)
  p <- pointer(con, f$placette, 1, jour = "2026-06-10")
  n <- nb_entrees(con, f$foret)
  expect_error(sommier_controler_placette(con, f$placette, auteur = "agent-01",
    visite_le = "2026-05-01T09:00:00Z", plants = list(etat(p, "sain"))),
    "avant son pointage")
  expect_equal(nb_entrees(con, f$foret), n)
})

# ---------------------------------------------------------------------------
# Mission 057 : robustesse du suivi des plants

test_that("la base refuse deux plants de meme numero dans la meme placette, meme en concurrence", {
  con <- base_plants()
  f <- foret_plants(con)
  # Deux ecritures concurrentes : chacune passe la verification applicative
  # (aucune des deux n'est encore ecrite), seule la base les departage.
  a <- entree_plant(con, f$placette, pt_wgs(1, 1), 7L, "agent-01",
                    date_evenement = "2025-06-10")
  b <- entree_plant(con, f$placette, pt_wgs(2, 1), 7L, "agent-01",
                    date_evenement = "2025-06-10")
  sommier_ajouter(con, a)
  n <- nb_entrees(con, f$foret)
  expect_error(sommier_ajouter(con, b), "plant_numero_par_placette_unique")
  expect_equal(nb_entrees(con, f$foret), n)
  expect_true(sommier_verifier(con, f$foret)$valide)
  # Le meme numero dans une autre placette, et un autre numero dans la meme,
  # restent permis.
  autre <- sommier_installer_placette(con, f$plantation, "P35-02", pt_wgs(0, 0),
                                      "agent-01",
                                      date_evenement = "2024-12-01")[[1L]]$id
  expect_no_error(pointer(con, autre, 7))
  expect_no_error(pointer(con, f$placette, 8))
  # L'insertion directe, hors de l'API, est refusee de la meme facon.
  expect_error(
    DBI::dbExecute(con, paste0("INSERT INTO entree_sommier
      (foret_id, registre, seq, date_evenement, auteur, payload,
       schema_version, hash_prev, hash)
      SELECT foret_id, registre, 9999, date_evenement, auteur, payload,
             schema_version, hash_prev, '\\x0000000000000000000000000000000000000000000000000000000000000001'::bytea
        FROM entree_sommier
       WHERE foret_id = '", f$foret, "' AND payload ->> 'type_entree' = 'plant'
         AND payload ->> 'numero' = '8'")),
    "plant_numero_par_placette_unique")
})

test_that("une correction de plant garde son numero ; l'index ne la bloque pas", {
  con <- base_plants()
  f <- foret_plants(con)
  p <- pointer(con, f$placette, 3)
  e <- DBI::dbGetQuery(con, "SELECT payload::text AS payload, ug_uuid::text AS ug
                              FROM entree_sommier WHERE id = $1",
                       params = list(p))
  payload <- registre6_plant(placette_id = f$placette, numero = 3L,
                             geometrie = pt_wgs(3, 2), essence = "CHS")
  expect_no_error(sommier_ajouter(con, sommier_entree(
    foret_id = f$foret, registre = 6L, date_evenement = "2025-06-11",
    auteur = "agent-01", ug_uuid = f$ug, corrige_id = p, payload = payload)))
  expect_equal(nrow(DBI::dbGetQuery(con, "SELECT 1 FROM v_plant
    WHERE foret_id = $1", params = list(f$foret))), 1L)
})

test_that("l'installation du schema : sans doublon elle passe, avec un doublon elle echoue clairement sans rien modifier", {
  con <- base_plants()
  f <- foret_plants(con)
  pointer(con, f$placette, 1)
  expect_no_error(sommier_init_schema(con))
  expect_no_error(sommier_init_schema(con))
  existe <- function() DBI::dbGetQuery(con, "SELECT count(*)::int AS n FROM
    pg_indexes WHERE indexname = 'plant_numero_par_placette_unique'")$n
  expect_equal(existe(), 1L)
  n <- nb_entrees(con, f$foret)
  # Un doublon fabrique (l'index retire le temps de l'essai) : tout est dans
  # une transaction annulee, la base d'essai reste saine pour les autres tests.
  a <- entree_plant(con, f$placette, pt_wgs(5, 1), 2L, "agent-01",
                    date_evenement = "2025-06-10")
  b <- entree_plant(con, f$placette, pt_wgs(6, 1), 2L, "agent-01",
                    date_evenement = "2025-06-10")
  expect_error(
    transaction(con, {
      DBI::dbExecute(con, "DROP INDEX plant_numero_par_placette_unique")
      sommier_ajouter(con, a)
      sommier_ajouter(con, b)
      sommier_init_schema(con)
    }),
    "Installation refusee : deux plants portent le meme numero")
  expect_equal(existe(), 1L)
  expect_equal(nb_entrees(con, f$foret), n)
  expect_no_error(sommier_init_schema(con))
})

test_that("le jour d'un pointage et d'un controle est celui de Paris, pas d'UTC", {
  con <- base_plants()
  # (a) Controle a 00 h 30 a Paris le 16 (22 h 30 UTC le 15), plant pointe a
  # midi a Paris le 16 : meme jour civil, accepte. En UTC, le controle (15)
  # aurait precede le pointage (16).
  f <- foret_plants(con)
  p <- sommier_pointer_plant(con, f$placette, pt_wgs(1, 1), 1, "agent-01",
                             pointe_le = "2026-06-16T10:00:00Z")[[1L]]
  expect_equal(p$date_evenement, "2026-06-16")
  k <- sommier_controler_placette(con, f$placette, auteur = "agent-01",
    visite_le = "2026-06-15T22:30:00Z", plants = list(etat(p$id, "sain")))[[1L]]
  expect_equal(k$date_evenement, "2026-06-16")
  expect_equal(DBI::dbGetQuery(con, "SELECT visite_le::text AS d
    FROM v_controle_plantation WHERE id = $1", params = list(k$id))$d, "2026-06-16")
  # (b) Symetrique : controle a 23 h 30 a Paris le 15 (21 h 30 UTC), plant
  # pointe a 00 h 30 a Paris le 16 (22 h 30 UTC le 15) : le plant est pose
  # apres le controle, refuse. En UTC, les deux etaient du 15.
  g <- foret_plants(con)
  q <- sommier_pointer_plant(con, g$placette, pt_wgs(1, 1), 1, "agent-01",
                             pointe_le = "2026-06-15T22:30:00Z")[[1L]]
  expect_equal(q$date_evenement, "2026-06-16")
  n <- nb_entrees(con, g$foret)
  expect_error(sommier_controler_placette(con, g$placette, auteur = "agent-01",
    visite_le = "2026-06-15T21:30:00Z", plants = list(etat(q$id, "sain"))),
    "avant son pointage")
  expect_equal(nb_entrees(con, g$foret), n)
  # (c) Un plant pointe a 23 h 30 a Paris (21 h 30 UTC) le 15, controle le
  # meme jour : accepte, et le plant est du 15.
  h <- foret_plants(con)
  r <- sommier_pointer_plant(con, h$placette, pt_wgs(1, 1), 1, "agent-01",
                             pointe_le = "2026-06-15T21:30:00Z")[[1L]]
  expect_equal(r$date_evenement, "2026-06-15")
  expect_no_error(sommier_controler_placette(con, h$placette, auteur = "agent-01",
    visite_le = "2026-06-15T21:45:00Z", plants = list(etat(r$id, "sain"))))
  # Deux controles le meme jour civil a Paris : refuses (22 h 30 UTC le 15 et
  # 08 h UTC le 16 sont du 16).
  expect_error(sommier_controler_placette(con, f$placette, auteur = "agent-01",
    visite_le = "2026-06-16T08:00:00Z", plants = list(etat(p$id, "sain"))),
    "deja ete controlee")
})

test_that("l'import compte le jour en heure de Paris : meme jour accepte, pointage posterieur refuse", {
  skip_if_not_installed("sf"); skip_if_not_installed("xml2")
  con <- base_plants()
  depot <- file.path(withr::local_tempdir(), "photos")
  cas <- function(pointe, visite) {
    g <- foret_plants(con)
    dossier <- projet_tournee(con, g)
    u <- uuid_v4(); k <- uuid_v4()
    ecrire_couche_g(dossier, couche_plants(g$placette, list(
      list(uuid = u, numero = 1, dx = 1, dy = 1, pointe = pointe))), "plants")
    lc <- ligne_controle(k, g$placette, "2026-06-15", 1, 1)
    lc$visite_le <- as.POSIXct(visite, tz = "UTC")
    ecrire_couche_g(dossier, lc, "controles")
    ecrire_couche_g(dossier, couche_etats(k, list(list(plant = u, etat = "sain"))),
                    "etats_plants")
    list(g = g, dossier = dossier)
  }
  a <- cas("2026-06-16 10:00:00", "2026-06-15 22:30:00")
  b <- sommier_importer_qfield_travaux(con, a$g$foret, a$dossier, depot, "agent-01")
  expect_equal(c(b$plants, b$controles), c(1L, 1L))
  expect_equal(DBI::dbGetQuery(con, "SELECT pointe_le::text AS d FROM v_plant
    WHERE foret_id = $1", params = list(a$g$foret))$d, "2026-06-16")
  z <- cas("2026-06-15 22:30:00", "2026-06-15 21:30:00")
  n <- nb_entrees(con, z$g$foret)
  expect_error(sommier_importer_qfield_travaux(con, z$g$foret, z$dossier, depot,
                                               "agent-01"), "avant son pointage")
  expect_equal(nb_entrees(con, z$g$foret), n)
})

test_that("l'import refuse un plant mort au passage 1 sans etat au passage 2, sans rien ecrire", {
  skip_if_not_installed("sf"); skip_if_not_installed("xml2")
  con <- base_plants()
  depot <- file.path(withr::local_tempdir(), "photos")
  # (1) Les deux passages dans la meme tournee.
  g <- foret_plants(con)
  dossier <- projet_tournee(con, g)
  u <- c(uuid_v4(), uuid_v4()); k1 <- uuid_v4(); k2 <- uuid_v4()
  ecrire_couche_g(dossier, couche_plants(g$placette, list(
    list(uuid = u[1], numero = 1, dx = 1, dy = 1),
    list(uuid = u[2], numero = 2, dx = 2, dy = 1))), "plants")
  ecrire_couche_g(dossier, rbind(
    ligne_controle(k1, g$placette, "2026-06-10", 2, 1),
    ligne_controle(k2, g$placette, "2027-06-10", 1, 1)), "controles")
  ecrire_couche_g(dossier, rbind(
    couche_etats(k1, list(list(plant = u[1], etat = "sain"),
                          list(plant = u[2], etat = "mort"))),
    couche_etats(k2, list(list(plant = u[1], etat = "sain")))), "etats_plants")
  n <- nb_entrees(con, g$foret)
  expect_error(sommier_importer_qfield_travaux(con, g$foret, dossier, depot,
                                               "agent-01"), "il en faut un")
  expect_equal(nb_entrees(con, g$foret), n)
  # (2) Le passage 1 est deja au registre ; la tournee ne porte que le 2.
  h <- foret_plants(con)
  p <- vapply(1:2, function(i) pointer(con, h$placette, i), "")
  sommier_controler_placette(con, h$placette, auteur = "agent-01",
    visite_le = "2025-06-10T09:00:00Z",
    plants = list(etat(p[1], "sain"), etat(p[2], "mort")))
  d2 <- projet_tournee(con, h)
  k <- uuid_v4()
  ecrire_couche_g(d2, ligne_controle(k, h$placette, "2026-06-10", 1, 1),
                  "controles")
  ecrire_couche_g(d2, couche_etats(k, list(list(plant = p[1], etat = "sain"))),
                  "etats_plants")
  n2 <- nb_entrees(con, h$foret)
  expect_error(sommier_importer_qfield_travaux(con, h$foret, d2, depot,
                                               "agent-01"), "il en faut un")
  expect_equal(nb_entrees(con, h$foret), n2)
})

# La demonstration de Couchey exerce tout le lot 2 (mission 062) : les trois
# placettes de la plantation 2022 de l'UG 35 recoivent leurs plants et leurs
# etats aux controles de 2023 et 2025.
test_that("la demonstration de Couchey pointe des plants et les suit en 2023 et 2025", {
  con <- base_plants()
  demo <- sommier_demo_couchey(con, suffixe = paste0("plants-", substr(uuid_v4(), 1L, 8L)))
  foret <- demo$foret_id
  q <- function(sql) DBI::dbGetQuery(con, sql, params = list(foret))

  # Les plants : 20 par placette, plus un regarni sur deux d'entre elles.
  p <- q("SELECT code_placette, count(*)::int AS n,
                 count(*) FILTER (WHERE regarni)::int AS regarnis,
                 count(DISTINCT numero)::int AS numeros,
                 count(DISTINCT essence)::int AS essences, min(essence) AS essence
            FROM v_plant WHERE foret_id = $1 GROUP BY 1 ORDER BY 1")
  expect_equal(p$code_placette, c("P35-01", "P35-02", "P35-03"))
  expect_equal(p$n, c(21L, 20L, 21L))
  expect_equal(p$numeros, p$n)               # numeros uniques par placette
  expect_equal(p$regarnis, c(1L, 0L, 1L))
  expect_equal(p$essence, rep("CHS", 3L))    # essence de la plantation
  expect_equal(p$essences, rep(1L, 3L))
  # Leur position est construite, et le dit (mission 065).
  m <- q("SELECT DISTINCT methode_pointage FROM v_plant WHERE foret_id = $1")
  expect_equal(m$methode_pointage, "construit")
  # Chaque regarni remplace un plant mort ou absent de sa placette.
  r <- q("SELECT r.etat FROM v_plant g JOIN v_plant o ON o.id = g.remplace_uuid
            AND o.placette_id = g.placette_id
            JOIN v_etat_plant r ON r.plant_id = o.id
           WHERE g.foret_id = $1 AND g.regarni")
  expect_true(all(r$etat %in% c("mort", "absent")))
  expect_equal(nrow(r), 4L)  # deux regarnis, vus a deux controles

  # Un etat par plant actif et par controle ; les morts en gardent un.
  e <- q("SELECT extract(year FROM visite_le)::int AS an, code_placette,
                 count(*)::int AS n, count(*) FILTER (WHERE etat = 'mort')::int AS morts
            FROM v_etat_plant WHERE foret_id = $1 GROUP BY 1, 2 ORDER BY 1, 2")
  expect_equal(e$an, rep(c(2023L, 2025L), each = 3L))
  expect_equal(e$n, c(20L, 20L, 20L, 21L, 20L, 21L))
  expect_gt(min(e$morts), 0L)

  # Les totaux du controle, derives des etats, sont ceux de la demonstration.
  c6 <- q("SELECT code_placette, extract(year FROM visite_le)::int AS an,
                  nb_total, nb_vivants FROM v_controle_plantation
            WHERE foret_id = $1 ORDER BY 2, 1")
  expect_equal(c6$nb_total, rep(20L, 6L))
  expect_equal(c6$nb_vivants, c(17L, 18L, 15L, 16L, 17L, 13L))

  # Le suivi rend une mortalite entre passages et des regarnis non nuls en 2025.
  s <- sommier_suivi_plantations(con, foret)
  s25 <- s[s$annee_controle == 2025L, ]
  expect_gt(s25$mortalite_passage_pct, 0)
  expect_equal(s25$nb_regarnis, 2L)
  expect_equal(s[s$annee_controle == 2023L, ]$nb_regarnis, 0L)

  # La chaine se verifie, plants compris.
  expect_true(sommier_verifier(con, foret)$valide)
})

# ---------------------------------------------------------------------------
# Mission 065 : les plants vivants a l'aller, et la methode de pointage.

# Une placette portant : p1 sain, p2 atteint, p3 mort (remplace par r), p4 sain
# puis non observe, p5 absent (remplace par r5). Renvoie les UUID.
plants_suivis <- function(con, f) {
  p <- vapply(1:5, function(i) pointer(con, f$placette, i,
                                       jour = "2025-06-10"), "")
  sommier_controler_placette(con, f$placette, auteur = "agent-01",
    visite_le = "2025-09-15T09:00:00Z",
    plants = list(etat(p[1], "sain", hauteur_cm = 30L),
                  etat(p[2], "atteint", cause_groupe = "animaux",
                       cause_detail = "abroutissement", hauteur_cm = 25L),
                  etat(p[3], "mort"), etat(p[4], "sain", hauteur_cm = 41L),
                  etat(p[5], "absent")))
  r <- pointer(con, f$placette, 6, jour = "2026-02-01", regarni = TRUE,
               remplace_uuid = p[3])
  r5 <- pointer(con, f$placette, 7, jour = "2026-02-01", regarni = TRUE,
                remplace_uuid = p[5])
  sommier_controler_placette(con, f$placette, auteur = "agent-01",
    visite_le = "2026-06-10T09:00:00Z",
    plants = list(etat(p[1], "sain", hauteur_cm = 38L),
                  etat(p[2], "atteint", hauteur_cm = 27L),
                  etat(p[3], "mort"), etat(p[4], "non_observe"),
                  etat(p[5], "absent"), etat(r, "sain", hauteur_cm = 20L),
                  etat(r5, "atteint", hauteur_cm = 18L)))
  list(p = p, r = r, r5 = r5)
}

test_that("le projet recoit les plants vivants avec leur dernier etat ; morts, absents et remplaces restent au registre", {
  skip_if_not_installed("sf"); skip_if_not_installed("xml2")
  con <- base_plants()
  f <- foret_plants(con)
  s <- plants_suivis(con, f)
  d <- projet_tournee(con, f)
  gpkg <- file.path(d, "travaux.gpkg")
  expect_true(all(c("plants", "etats_plants") %in% sf::st_layers(gpkg)$name))
  pl <- sf::read_sf(gpkg, layer = "plants")
  et <- as.data.frame(sf::read_sf(gpkg, layer = "etats_plants"))
  # Vivants : p1, p2, p4 (dernier etat mesure : sain au passage 1), r, r5.
  attendus <- c(s$p[1], s$p[2], s$p[4], s$r, s$r5)
  expect_setequal(pl$uuid, attendus)
  expect_false(any(c(s$p[3], s$p[5]) %in% pl$uuid))  # mort, absent
  expect_equal(nrow(pl), 5L)
  # Numero, placette, regarni et remplace_uuid sont ceux du registre.
  pl <- pl[order(pl$numero), ]
  expect_equal(pl$numero, c(1L, 2L, 4L, 6L, 7L))
  expect_true(all(pl$placette_uuid == f$placette))
  expect_equal(pl$regarni, c(FALSE, FALSE, FALSE, TRUE, TRUE))
  expect_equal(pl$remplace_uuid, c(NA, NA, NA, s$p[3], s$p[5]))
  # La position, en Lambert-93 : celle du registre (p1 a 1 m a l'est, 1 m au nord).
  expect_equal(sf::st_crs(pl)$epsg, 2154L)
  xy <- sf::st_coordinates(pl)
  expect_equal(xy[1, ], c(X = 600151, Y = 6700101), tolerance = 0.01)
  expect_equal(xy[2, ], c(X = 600152, Y = 6700101), tolerance = 0.01)
  # Le dernier etat, avec sa cause et sa hauteur.
  e <- function(u) et[et$plant_uuid == u, ]
  expect_equal(e(s$p[1])$etat, "sain"); expect_equal(e(s$p[1])$hauteur_cm, 38L)
  expect_equal(e(s$p[2])$etat, "atteint")
  expect_equal(e(s$p[4])$etat, "sain"); expect_equal(e(s$p[4])$hauteur_cm, 41L)
  expect_equal(e(s$r5)$etat, "atteint")
  expect_equal(nrow(et), 5L)
  expect_true(all(et$etat %in% c("sain", "atteint")))
  expect_false(anyDuplicated(et$uuid) > 0L)
  # Le controle de l'etat est celui du dernier passage qui l'a mesure.
  ctl <- DBI::dbGetQuery(con, "SELECT id::text AS id, visite_le::text AS jour
    FROM v_controle_plantation WHERE foret_id = $1", params = list(f$foret))
  expect_equal(ctl$jour[match(e(s$p[1])$controle_uuid, ctl$id)], "2026-06-10")
  expect_equal(ctl$jour[match(e(s$p[4])$controle_uuid, ctl$id)], "2025-09-15")
  # La cause du dernier etat de p2 : le passage 2 n'en porte pas.
  expect_true(is.na(e(s$p[2])$cause_detail))
  # Rien n'a ete ecrit au registre par la preparation du projet.
  expect_true(sommier_verifier(con, f$foret)$valide)
})

test_that("une placette sans plant : le projet est celui d'avant, sans couches de plants", {
  skip_if_not_installed("sf"); skip_if_not_installed("xml2")
  con <- base_plants()
  f <- foret_plants(con)
  sommier_controler_placette(con, f$placette, nb_total = 20, nb_vivants = 17,
                             auteur = "agent-01",
                             visite_le = "2025-09-15T09:00:00Z")
  d <- projet_tournee(con, f)
  couches <- sf::st_layers(file.path(d, "travaux.gpkg"))$name
  expect_false(any(c("plants", "etats_plants") %in% couches))
  expect_true(all(c("placettes", "controles", "photos") %in% couches))
  # Des plants tous morts ne partent pas non plus : pas de couche vide.
  g <- foret_plants(con)
  p <- pointer(con, g$placette, 1)
  sommier_controler_placette(con, g$placette, auteur = "agent-01",
    visite_le = "2025-09-15T09:00:00Z", plants = list(etat(p, "mort")))
  d2 <- projet_tournee(con, g)
  expect_false("plants" %in% sf::st_layers(file.path(d2, "travaux.gpkg"))$name)
})

test_that("aller-retour : etats du nouveau controle, aucun plant duplique, aucun numero change, chaine intacte", {
  skip_if_not_installed("sf"); skip_if_not_installed("xml2")
  con <- base_plants()
  f <- foret_plants(con)
  s <- plants_suivis(con, f)
  d <- projet_tournee(con, f)
  depot <- file.path(withr::local_tempdir(), "photos")
  avant <- DBI::dbGetQuery(con, "SELECT id::text AS id, numero, placette_id::text
    AS placette FROM v_plant WHERE foret_id = $1 ORDER BY numero",
    params = list(f$foret))
  n <- nb_entrees(con, f$foret)
  # Aller seul rapporte tel quel : rien a ecrire, rien n'est refuse.
  b0 <- sommier_importer_qfield_travaux(con, f$foret, d, depot, "agent-01")
  expect_equal(c(b0$plants, b0$controles), c(0L, 0L))
  expect_equal(nb_entrees(con, f$foret), n)
  # Le forestier renote les plants vivants au controle suivant.
  k <- uuid_v4()
  ecrire_couche_g(d, ligne_controle(k, f$placette, "2027-06-10", 5, 4),
                  "controles")
  ecrire_couche_g(d, couche_etats(k, list(
    list(plant = s$p[1], etat = "sain", hauteur = 45L),
    list(plant = s$p[2], etat = "mort"),
    list(plant = s$p[4], etat = "sain", hauteur = 50L),
    list(plant = s$r, etat = "sain", hauteur = 31L),
    list(plant = s$r5, etat = "sain", hauteur = 29L))), "etats_plants")
  b <- sommier_importer_qfield_travaux(con, f$foret, d, depot, "agent-01")
  expect_equal(c(b$plants, b$controles), c(0L, 1L))
  apres <- DBI::dbGetQuery(con, "SELECT id::text AS id, numero, placette_id::text
    AS placette FROM v_plant WHERE foret_id = $1 ORDER BY numero",
    params = list(f$foret))
  expect_equal(apres, avant)                      # ni doublon, ni numero change
  expect_equal(nb_entrees(con, f$foret), n + 1L)  # le seul controle
  v <- DBI::dbGetQuery(con, "SELECT etat, hauteur_cm FROM v_etat_plant
    WHERE controle_id = $1 ORDER BY numero", params = list(k))
  expect_equal(nrow(v), 5L)
  expect_equal(v$etat[2], "mort")
  c3 <- DBI::dbGetQuery(con, "SELECT nb_total, nb_vivants FROM v_controle_plantation
                               WHERE id = $1", params = list(k))
  expect_equal(c(c3$nb_total, c3$nb_vivants), c(5L, 4L))
  expect_true(sommier_verifier(con, f$foret)$valide)
  # Rejouer ne change rien.
  b2 <- sommier_importer_qfield_travaux(con, f$foret, d, depot, "agent-01")
  expect_equal(c(b2$plants, b2$controles), c(0L, 0L))
  expect_equal(nb_entrees(con, f$foret), n + 1L)
})

test_that("SOMMIER_METHODES_POINTAGE : les quatre valeurs de Surculus, chacune acceptee, toute autre refusee sans rien ecrire", {
  expect_equal(SOMMIER_METHODES_POINTAGE,
               c("relatif_boussole", "relatif_saisie", "gnss_plant", "construit"))
  con <- base_plants()
  f <- foret_plants(con)
  ids <- vapply(seq_along(SOMMIER_METHODES_POINTAGE), function(i) {
    pointer(con, f$placette, i, methode_pointage = SOMMIER_METHODES_POINTAGE[[i]])
  }, "")
  v <- DBI::dbGetQuery(con, "SELECT id::text AS id, methode_pointage FROM v_plant
                              WHERE foret_id = $1", params = list(f$foret))
  expect_equal(v$methode_pointage[match(ids, v$id)], SOMMIER_METHODES_POINTAGE)
  # Hors liste : refus a l'ecriture, rien n'est ecrit.
  n <- nb_entrees(con, f$foret)
  for (faux in c("gps", "GNSS_PLANT", "relatif", "boussole_telephone")) {
    expect_error(pointer(con, f$placette, 9, methode_pointage = faux),
                 "methode_pointage")
  }
  expect_error(registre6_plant(f$placette, 9, pt_wgs(1, 1),
                               methode_pointage = "gps"), "doit valoir l'une de")
  expect_equal(nb_entrees(con, f$foret), n)
  # Facultative : sans elle, le payload ne la porte pas (hachage inchange).
  sans <- pointer(con, f$placette, 10)
  expect_false(DBI::dbGetQuery(con, "SELECT payload ? 'methode_pointage' AS a
    FROM entree_sommier WHERE id = $1", params = list(sans))$a)
  expect_true(is.na(DBI::dbGetQuery(con, "SELECT methode_pointage FROM v_plant
                                           WHERE id = $1",
                                    params = list(sans))$methode_pointage))
  expect_true(sommier_verifier(con, f$foret)$valide)
})

test_that("l'import refuse une methode de pointage hors liste, rien n'est ecrit, et accepte chaque valeur de la liste", {
  skip_if_not_installed("sf"); skip_if_not_installed("xml2")
  con <- base_plants()
  depot <- file.path(withr::local_tempdir(), "photos")
  tournee <- function(methodes) {
    g <- foret_plants(con)
    dossier <- projet_tournee(con, g)
    u <- vapply(methodes, function(m) uuid_v4(), "")
    couche <- couche_plants(g$placette, lapply(seq_along(u), function(i)
      list(uuid = u[[i]], numero = i, dx = i, dy = 1)))
    couche$methode_pointage <- methodes
    ecrire_couche_g(dossier, couche, "plants")
    list(g = g, dossier = dossier)
  }
  t1 <- tournee(c("relatif_boussole", "relatif_saisie", "gps"))
  n <- nb_entrees(con, t1$g$foret)
  expect_error(sommier_importer_qfield_travaux(con, t1$g$foret, t1$dossier,
                                               depot, "agent-01"),
               "methode_pointage.*gps")
  expect_equal(nb_entrees(con, t1$g$foret), n)
  t2 <- tournee(SOMMIER_METHODES_POINTAGE)
  b <- sommier_importer_qfield_travaux(con, t2$g$foret, t2$dossier, depot,
                                       "agent-01")
  expect_equal(b$plants, 4L)
  v <- DBI::dbGetQuery(con, "SELECT methode_pointage FROM v_plant
                              WHERE foret_id = $1 ORDER BY numero",
                       params = list(t2$g$foret))
  expect_equal(v$methode_pointage, SOMMIER_METHODES_POINTAGE)
  # Une colonne absente ou vide : plant sans methode, pas une faute.
  t3 <- tournee(c(NA_character_))
  expect_equal(sommier_importer_qfield_travaux(con, t3$g$foret, t3$dossier,
                                               depot, "agent-01")$plants, 1L)
})
