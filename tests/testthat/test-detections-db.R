# Verification des detections sur le terrain : les contours, l'inscription
# des coupes SUFOSAT, le projet QField et le retour du terrain.

base_detections <- function(env = parent.frame()) {
  con <- sauter_sans_base()
  withr::defer(DBI::dbDisconnect(con), envir = env)
  sommier_init_schema(con)
  con
}

# Une foret d'une unite de 300 x 200 m (6 ha), et deux detections en
# attente : un deperissement RECONFORT, une coupe rase SUFOSAT.
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

# Un raster de 10 m sur l'emprise de l'unite, `valeur` dans le carre donne,
# `fond` ailleurs.
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

test_that("le contour d'une detection est fait de ses pixels, a defaut de l'unite", {
  con <- base_detections()
  f <- foret_detections(con)
  # Un hectare deperissant (classe 3) dans une unite saine (classe 1).
  reconfort <- raster_carre(600050, 6700050, 600150, 6700150, 3, fond = 1)

  contours <- sommier_contours_detections(con, f$foret, reconfort = reconfort)
  r <- contours[contours$detection_id == f$reconfort, ]
  expect_equal(r$contour_source, "pixels")
  expect_equal(r$contour_ha, 1)
  # Sans raster SUFOSAT, la coupe se montre par son unite entiere.
  s <- contours[contours$detection_id == f$sufosat, ]
  expect_equal(s$contour_source, "unite")
  expect_equal(s$contour_ha, 6)

  # La classe minimale retenue : en exigeant 3, le meme hectare reste ; une
  # unite toute saine ne donne aucun pixel, et l'unite reprend la main.
  sain <- raster_carre(600050, 6700050, 600150, 6700150, 1, fond = 1)
  r <- sommier_contours_detections(con, f$foret, reconfort = sain)
  expect_equal(r$contour_source[r$detection_id == f$reconfort], "unite")

  # SUFOSAT : les pixels de l'annee de la detection, au-dessus du seuil.
  dates <- raster_carre(600200, 6700000, 600250, 6700100, 19240)
  proba <- raster_carre(600200, 6700000, 600250, 6700100, 95)
  s <- sommier_contours_detections(con, f$foret,
                                   sufosat = list(dates = dates, proba = proba))
  expect_equal(s$contour_source[s$detection_id == f$sufosat], "pixels")
  expect_equal(s$contour_ha[s$detection_id == f$sufosat], 0.5)
})

test_that("les coupes SUFOSAT sans martelage s'inscrivent une fois", {
  con <- base_detections()
  f <- foret_detections(con)
  coupes <- data.frame(ug = c("12", "12"), annee = c(2021L, 2023L),
                       surface_ha = c(2.4, 0.8),
                       date_mediane = as.Date(c("2021-09-01", "2023-08-15")),
                       debut = as.Date(c("2021-07-01", "2023-08-01")),
                       fin = as.Date(c("2021-10-01", "2023-09-01")),
                       proba_moyenne = c(97.5, 92), stringsAsFactors = FALSE)
  attr(coupes, "seuil_proba") <- 90
  # Un martelage de 2022 explique la coupe de 2023 (exercice N - 1).
  sommier_ajouter(con, sommier_entree(
    foret_id = f$foret, registre = 5L, date_evenement = "2022-10-01",
    auteur = "test", ug_uuid = f$ug,
    payload = list(type_entree = "martelage", exercice = 2022L,
                   nature_coupe = "amelioration", volume_m3 = 120)
  ))

  inscrites <- sommier_inscrire_coupes_sufosat(con, f$foret, coupes, "test")
  expect_length(inscrites, 1L)
  p <- inscrites[[1L]]$payload
  expect_equal(p$source, "sufosat")
  expect_equal(p$nature, "autre")
  expect_equal(p$surface_ha, 2.4)
  expect_match(p$observations, ">= 90 %", fixed = TRUE)
  expect_equal(inscrites[[1L]]$ndp, 1L)
  # Inscrire de nouveau n'ecrit rien.
  expect_length(sommier_inscrire_coupes_sufosat(con, f$foret, coupes, "test"),
                0L)
  expect_true(sommier_verifier(con, f$foret)$valide)
})

test_that("une detection ne se suit qu'une fois", {
  con <- base_detections()
  f <- foret_detections(con)
  sommier_valider_detection(con, f$reconfort, "agent-01", "confirme",
                            "Deperissement confirme")
  expect_error(
    sommier_valider_detection(con, f$reconfort, "agent-01", "ecarte", "x"),
    "deja une suite"
  )
})

test_that("le projet des detections s'engendre, s'ouvre et propose la detection", {
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
  # Par surface detectee decroissante - celle du registre, non celle du
  # contour : la coupe d'un demi-hectare, montree par son unite de 6 ha, vient
  # apres le deperissement d'un hectare.
  expect_equal(d$numero, c("D01", "D02"))
  expect_equal(d$id, c(f$reconfort, f$sufosat))
  expect_match(d$libelle[[1L]], "^D01 - unite 12 - RECONFORT, 1,0 ha")
  expect_equal(d$contour, c("pixels", "unite"))

  # Au milieu de l'hectare deperissant ; puis une detection confirmee sans
  # nature, que le formulaire refuse.
  saisir_constats(dossier, rbind(
    constat_detection(uuid_v4(), f$reconfort, "confirme", "crise_sanitaire",
                      600100, 6700100),
    constat_detection(uuid_v4(), f$sufosat, "confirme", NA, 600250, 6700150)
  ))
  ouvert <- ouvrir_dans_qgis(qgs)
  expect_true(ouvert$lu)
  expect_true(all(vapply(ouvert$couches, function(c) isTRUE(c$valide),
                         logical(1))))
  expect_true(all(c("detections_constats", "detections_photos",
                    "detections_detections", "detections_unites") %in%
                    names(ouvert$couches)))
  expect_true(ouvert$couches$detections_detections$lecture_seule)
  expect_false("detections_ortho" %in% names(ouvert$couches))
  expect_true(ouvert$relations[[1L]]$valide)
  expect_equal(ouvert$variables$operateur, "P. & O.")
  expect_equal(ouvert$propositions[[1L]]$propose, f$reconfort)
  expect_length(ouvert$propositions[[1L]]$refus, 0L)
  expect_equal(unlist(ouvert$propositions[[2L]]$refus), "nature")
})

test_that("le retour du terrain s'importe une fois ; non vu n'ecrit rien", {
  con <- base_detections()
  f <- foret_detections(con)
  dossier <- file.path(withr::local_tempdir(), "detections")
  depot <- file.path(withr::local_tempdir(), "photos")
  sommier_projet_qfield_detections(con, f$foret, dossier, "P. O.")

  u <- c(uuid_v4(), uuid_v4())
  saisir_constats(dossier, rbind(
    constat_detection(u[[1L]], f$reconfort, "confirme", "crise_sanitaire",
                      600100, 6700100),
    constat_detection(u[[2L]], f$sufosat, "non_vu", NA, 600250, 6700150)
  ))
  file.copy(testthat::test_path("fixtures", "photo-exif-ii.jpg"),
            file.path(dossier, "DCIM", "detections_1.jpg"))
  sf::st_write(data.frame(uuid = uuid_v4(), constat_uuid = u[[1L]],
                          fichier = "DCIM/detections_1.jpg"),
               file.path(dossier, "detections.gpkg"), layer = "photos",
               append = TRUE, quiet = TRUE)

  bilan <- sommier_importer_qfield_detections(con, f$foret, dossier, depot,
                                              auteur = "test")
  expect_equal(bilan$ecrits, 1L)
  expect_equal(bilan$non_vus, 1L)
  expect_equal(bilan$photos, 1L)
  e <- bilan$entrees[[1L]]
  expect_equal(e$id, u[[1L]])
  expect_equal(e$ndp, 0L)
  expect_equal(e$corrige_id, f$reconfort)
  expect_equal(e$schema_version, "r8-1.3.0")
  expect_equal(e$payload$statut_detection, "confirme")
  expect_equal(e$payload$nature, "crise_sanitaire")
  expect_equal(e$payload$geometrie$type, "Point")
  expect_equal(e$payload$operateur, "P. O.")
  expect_length(e$payload$photos, 1L)
  expect_true(all(sommier_verifier_photos(con, f$foret, depot)$statut ==
                    "intacte"))

  # La coupe non vue reste en attente ; le deperissement en sort.
  attente <- DBI::dbGetQuery(
    con, "SELECT id::text AS id FROM v_detection_en_attente WHERE foret_id = $1",
    params = list(f$foret))$id
  expect_equal(attente, f$sufosat)

  encore <- sommier_importer_qfield_detections(con, f$foret, dossier, depot,
                                               auteur = "test")
  expect_equal(encore$ecrits, 0L)
  expect_equal(encore$deja_presents, 1L)
  expect_true(sommier_verifier(con, f$foret)$valide)
})

test_that("un import fautif n'ecrit rien ; une detection deja suivie est signalee", {
  con <- base_detections()
  f <- foret_detections(con)
  dossier <- file.path(withr::local_tempdir(), "detections")
  sommier_projet_qfield_detections(con, f$foret, dossier, "P. O.")
  saisir_constats(dossier, rbind(
    constat_detection(uuid_v4(), f$reconfort, "confirme", NA, 600100, 6700100),
    constat_detection(uuid_v4(), f$sufosat, "detruit", NA, 600250, 6700150),
    constat_detection(uuid_v4(), f$sufosat, "ecarte", "grele", 600250, 6700150)
  ))
  n <- nrow(sommier_lire(con, f$foret))
  erreur <- tryCatch(
    sommier_importer_qfield_detections(con, f$foret, dossier,
                                       withr::local_tempdir(), auteur = "test"),
    error = conditionMessage
  )
  expect_match(erreur, "appelle sa nature")
  expect_match(erreur, "etat inconnu \\(detruit\\)")
  expect_match(erreur, "nature inconnue \\(grele\\)")
  expect_equal(nrow(sommier_lire(con, f$foret)), n)

  # Deux constats qui tranchent la meme detection : un seul doit rester.
  autre <- file.path(withr::local_tempdir(), "detections")
  sommier_projet_qfield_detections(con, f$foret, autre, "P. O.")
  saisir_constats(autre, rbind(
    constat_detection(uuid_v4(), f$sufosat, "ecarte", NA, 600250, 6700150),
    constat_detection(uuid_v4(), f$sufosat, "confirme", "autre", 600250,
                      6700150)
  ))
  expect_error(
    sommier_importer_qfield_detections(con, f$foret, autre,
                                       withr::local_tempdir(), auteur = "test"),
    "D02 : plusieurs constats"
  )

  # Suivie a la main entre-temps : l'import ne la suit pas une seconde fois.
  troisieme <- file.path(withr::local_tempdir(), "detections")
  sommier_projet_qfield_detections(con, f$foret, troisieme, "P. O.")
  saisir_constats(troisieme, constat_detection(
    uuid_v4(), f$reconfort, "ecarte", NA, 600100, 6700100))
  sommier_valider_detection(con, f$reconfort, "agent-01", "confirme",
                            "Vu par ailleurs")
  bilan <- sommier_importer_qfield_detections(con, f$foret, troisieme,
                                              withr::local_tempdir(),
                                              auteur = "test")
  expect_equal(bilan$ecrits, 0L)
  expect_equal(bilan$deja_suivies, "D01")
})

test_that("le rapport montre les suites, leurs photos, et le sort des coupes", {
  con <- base_detections()
  f <- foret_detections(con)
  depot <- file.path(withr::local_tempdir(), "photos")
  dossier <- file.path(withr::local_tempdir(), "detections")
  sommier_projet_qfield_detections(con, f$foret, dossier, "P. O.")
  u <- c(uuid_v4(), uuid_v4())
  constats <- rbind(
    constat_detection(u[[1L]], f$reconfort, "confirme", "crise_sanitaire",
                      600100, 6700100),
    constat_detection(u[[2L]], f$sufosat, "ecarte", NA, 600250, 6700150)
  )
  constats$surface_ha[[1L]] <- 0.8
  constats$observations[[2L]] <- "Trouee ancienne, deja recrue"
  saisir_constats(dossier, constats)
  file.copy(testthat::test_path("fixtures", "photo-exif-ii.jpg"),
            file.path(dossier, "DCIM", "detections_1.jpg"))
  sf::st_write(data.frame(uuid = uuid_v4(), constat_uuid = u[[1L]],
                          fichier = "DCIM/detections_1.jpg"),
               file.path(dossier, "detections.gpkg"), layer = "photos",
               append = TRUE, quiet = TRUE)
  sommier_importer_qfield_detections(con, f$foret, dossier, depot, "test")

  lu <- lire_suites_detection(con, f$foret)
  k <- lu$suites[order(lu$suites$source), ]
  expect_equal(k$statut, c("confirme", "ecarte"))
  expect_equal(k$source, c("reconfort", "sufosat"))
  expect_equal(k$surface_detectee, c(1, 0.5))
  expect_equal(k$surface_constatee, c(0.8, NA))
  expect_equal(k$nb_photos, c(1L, 0L))
  expect_equal(nrow(lu$photos), 1L)
  expect_equal(lu$photos$numero, "12 · RECONFORT")

  # Le sort des coupes SUFOSAT sans martelage : 2019 a ete inscrite puis
  # ecartee, 2021 n'est pas inscrite.
  sans <- data.frame(ug = c("12", "12"), annee = c(2019L, 2021L),
                     surface_ha = c(0.5, 1.2), stringsAsFactors = FALSE)
  sort <- suite_des_coupes(con, f$foret, sans)
  expect_equal(sort$suite, c("ecarte", "non_inscrite"))

  skip_if(!nzchar(Sys.which("quarto")), "Quarto n'est pas installe.")
  chemin <- withr::local_tempfile(fileext = ".html")
  coupes <- data.frame(ug = c("12", "12"), annee = c(2019L, 2021L),
                       surface_ha = c(0.5, 1.2),
                       date_mediane = as.Date(c("2019-08-28", "2021-09-01")),
                       debut = as.Date(c("2019-08-01", "2021-08-01")),
                       fin = as.Date(c("2019-09-01", "2021-10-01")),
                       proba_moyenne = c(95, 96), stringsAsFactors = FALSE)
  attr(coupes, "seuil_proba") <- 90
  attr(coupes, "surface_min_ha") <- 0.5
  sommier_rapport_quarto(con, f$foret, chemin, format = "html", photos = depot,
                         referentiel = "amenagement", coupes_detectees = coupes)
  html <- paste(readLines(chemin, warn = FALSE, encoding = "UTF-8"),
                collapse = "\n")
  # La coupe de 2019, ecartee, sort du compte ; celle de 2021 n'est pas
  # inscrite et le rapport le dit.
  expect_match(html, "SUFOSAT détecte 1 coupe(s)", fixed = TRUE)
  expect_match(html, "sur le terrain, hors du compte : 12 en 2019", fixed = TRUE)
  expect_match(html, "pas encore proposées", fixed = TRUE)
  expect_match(html, "Suites données sur le terrain", fixed = TRUE)
  # Rendu sans plan cadastral : la section le dit, au lieu de disparaitre.
  expect_match(html, "Le plan cadastral (EDIGEO) n", fixed = TRUE)
  expect_match(html, "crise sanitaire", fixed = TRUE)
  expect_match(html, "Des bois à exploiter hors martelage", fixed = TRUE)
  expect_match(html, "Trouee ancienne", fixed = TRUE)
  expect_match(html, "Planche photographique", fixed = TRUE)
  expect_equal(lengths(regmatches(html, gregexpr("<figure style=", html))), 1L)

  public <- withr::local_tempfile(fileext = ".html")
  sommier_rapport_quarto(con, f$foret, public, format = "html", photos = depot,
                         public = TRUE)
  html <- paste(readLines(public, warn = FALSE, encoding = "UTF-8"),
                collapse = "\n")
  expect_match(html, "Suites données sur le terrain", fixed = TRUE)
  expect_match(html, "Version publique", fixed = TRUE)
  expect_no_match(html, "<figure style=", fixed = TRUE)
})
