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
