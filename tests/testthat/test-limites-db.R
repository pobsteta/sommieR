# Suivi des limites contre une base reelle : le projet QField, le retour du
# terrain, les photos, et ce qui se verifie ensuite.

base_limites <- function(env = parent.frame()) {
  con <- sauter_sans_base()
  withr::defer(DBI::dbDisconnect(con), envir = env)
  sommier_init_schema(con)
  con
}

fond_zk01 <- function(env = parent.frame()) {
  skip_if_not_installed("sf")
  archive <- testthat::test_path("fixtures", "edigeo-45188000ZK01.tar.bz2")
  skip_if_not(file.exists(archive), "Fixture EDIGEO absente.")
  dossier <- withr::local_tempdir(.local_envir = env)
  utils::untar(archive, exdir = dossier, tar = "internal")
  structure(
    list(feuilles = data.frame(feuille = "45188000ZK01",
                               thf = fichier_thf(dossier),
                               stringsAsFactors = FALSE),
         code_insee = "45188", source = "fixture locale"),
    class = "sommier_fond_pci"
  )
}

# Une foret d'une unite, posee sur la parcelle de la feuille ZK01 qui a le
# plus de bornes a ses abords.
foret_zk01 <- function(con, fond) {
  parcelles <- sommier_fond_pci_lire(fond, "parcelles")
  bornes <- sommier_fond_pci_lire(fond, "bornes")
  voisines <- lengths(sf::st_is_within_distance(
    sf::st_as_sfc(parcelles$wkt, crs = 2154),
    sf::st_as_sfc(bornes$wkt, crs = 2154), 20
  ))
  foret <- foret_creer(con, paste0("Foret limites-", substr(uuid_v4(), 1L, 8L)),
                       "communal")
  ug <- ug_creer(con, foret, "ZK 1", "2010-01-01")
  DBI::dbExecute(
    con,
    "INSERT INTO ug_geometrie (ug_uuid, version, geom, source, date_debut)
     VALUES ($1, 1, ST_Multi(ST_GeomFromText($2, 2154)), 'test', '2010-01-01')",
    params = list(ug, parcelles$wkt[[which.max(voisines)]])
  )
  foret
}

# Ce que ferait l'agent dans QField : des constats, et des photos rangees
# dans DCIM/.
saisir <- function(dossier, constats, photos = NULL) {
  gpkg <- file.path(dossier, "terrain.gpkg")
  sf::st_write(constats, gpkg, layer = "constats", append = TRUE, quiet = TRUE)
  if (!is.null(photos)) {
    for (i in seq_len(nrow(photos))) {
      file.copy(testthat::test_path("fixtures", photos$source[[i]]),
                file.path(dossier, photos$fichier[[i]]))
    }
    sf::st_write(photos[, c("uuid", "constat_uuid", "fichier")], gpkg,
                 layer = "photos", append = TRUE, quiet = TRUE)
  }
}

constat <- function(uuid, element_id, etat, x, y,
                    visite = "2026-10-12 10:31:05", precision = 0.02) {
  sf::st_sf(uuid = uuid, element_id = element_id, etat = etat,
            visite_le = as.POSIXct(visite, tz = "UTC"),
            operateur = "P. O.", precision_m = precision,
            source_gnss = "rtk", observations = NA_character_,
            geometry = sf::st_sfc(sf::st_point(c(x, y)), crs = 2154))
}

test_that("le projet QField s'engendre, s'ouvre et propose l'element proche", {
  con <- base_limites()
  fond <- fond_zk01()
  foret <- foret_zk01(con, fond)
  elements <- sommier_elements_pci(fond, sommier_couche_ug(con, foret))
  bornes <- elements[elements$couche == "bornes", ]
  expect_gt(nrow(bornes), 10L)

  dossier <- file.path(withr::local_tempdir(), "limites")
  qgs <- sommier_projet_qfield(con, foret, elements, dossier,
                               operateur = "P. & O.")
  expect_true(file.exists(qgs))
  expect_true(dir.exists(file.path(dossier, "DCIM")))
  # Jamais d'ecrasement : une tournee non rapatriee est peut-etre dedans.
  expect_error(sommier_projet_qfield(con, foret, elements, dossier,
                                     operateur = "P. O."), "existe deja")

  xml <- paste(readLines(qgs, encoding = "UTF-8"), collapse = "\n")
  expect_match(xml, "P. &amp; O.", fixed = TRUE)
  expect_no_match(xml, "@@|111111")
  gpkg <- file.path(dossier, "terrain.gpkg")
  expect_equal(nrow(sf::read_sf(gpkg, "elements")), nrow(elements))
  points <- sf::read_sf(gpkg, "elements_points")
  expect_true(all(points$a_visiter == "a_voir"))
  expect_equal(nrow(sf::read_sf(gpkg, "constats")), 0L)

  saisir(dossier, constat(uuid_v4(), bornes$id[[1L]], "en_place",
                          bornes$x[[1L]] + 0.5, bornes$y[[1L]]))
  ouvert <- ouvrir_dans_qgis(qgs)
  expect_true(ouvert$lu)
  expect_true(all(vapply(ouvert$couches, function(c) isTRUE(c$valide),
                         logical(1))))
  # Les identifiants tiennent a la relecture : sans eux, la relation et
  # overlay_nearest() se perdent.
  expect_true(all(c("limites_constats", "limites_photos", "limites_unites",
                    "limites_elements_points") %in% names(ouvert$couches)))
  expect_true(ouvert$couches$limites_elements_points$lecture_seule)
  expect_false(ouvert$couches$limites_constats$lecture_seule)
  expect_equal(ouvert$relations[[1L]]$id, "photos_du_constat")
  expect_true(ouvert$relations[[1L]]$valide)
  expect_equal(ouvert$variables$operateur, "P. & O.")
  # A 50 cm de la borne, le formulaire la propose.
  expect_equal(ouvert$propositions[[1L]]$propose, bornes$id[[1L]])
  # Sans ortho fournie, la couche hors ligne est retiree, pas laissee cassee.
  expect_false("limites_ortho" %in% names(ouvert$couches))
  expect_false(file.exists(file.path(dossier, "ortho.tif")))
})

test_that("l'ortho hors ligne voyage avec le projet, et « hors plan » vide l'element", {
  con <- base_limites()
  fond <- fond_zk01()
  foret <- foret_zk01(con, fond)
  ug <- sommier_couche_ug(con, foret)
  elements <- sommier_elements_pci(fond, ug)
  b <- elements[elements$couche == "bornes", ][1:2, ]

  # Une ortho de trois bandes, rasterisee sur la foret : sans reseau, elle
  # tient lieu de celle de l'IGN.
  gpkg <- withr::local_tempfile(fileext = ".gpkg")
  sf::st_write(sf::st_sf(v = 1, geometry = sf::st_as_sfc(ug$wkt, crs = 2154)),
               gpkg, quiet = TRUE)
  ortho <- withr::local_tempfile(fileext = ".tif")
  sf::gdal_utils("rasterize", gpkg, ortho, options = c(
    "-burn", "90", "-burn", "120", "-burn", "60", "-tr", "5", "5",
    "-ot", "Byte", "-init", "0"))
  expect_error(sommier_projet_qfield(con, foret, elements,
                                     file.path(withr::local_tempdir(), "x"),
                                     operateur = "P. O.", ortho = "absente.tif"),
               "introuvable")

  dossier <- file.path(withr::local_tempdir(), "limites")
  qgs <- sommier_projet_qfield(con, foret, elements, dossier,
                               operateur = "P. O.", ortho = ortho)
  expect_true(file.exists(file.path(dossier, "ortho.tif")))
  saisir(dossier, rbind(
    # Hors plan, pose sur une borne : le formulaire ne doit rien garder.
    constat(uuid_v4(), NA_character_, "hors_plan", b$x[[1L]], b$y[[1L]]),
    # Pose pres de la premiere borne, mais l'agent a choisi la seconde.
    constat(uuid_v4(), b$id[[2L]], "en_place", b$x[[1L]], b$y[[1L]])
  ))
  ouvert <- ouvrir_dans_qgis(qgs)
  expect_true(ouvert$couches$limites_ortho$valide)
  expect_null(ouvert$propositions[[1L]]$reevalue)
  expect_equal(ouvert$propositions[[1L]]$propose, b$id[[1L]])
  expect_equal(ouvert$propositions[[2L]]$reevalue, b$id[[2L]])
})

test_that("le retour du terrain s'importe, une fois, photos comprises", {
  con <- base_limites()
  fond <- fond_zk01()
  foret <- foret_zk01(con, fond)
  elements <- sommier_elements_pci(fond, sommier_couche_ug(con, foret))
  b <- elements[elements$couche == "bornes", ][1:2, ]
  dossier <- file.path(withr::local_tempdir(), "limites")
  depot <- file.path(withr::local_tempdir(), "photos")
  sommier_projet_qfield(con, foret, elements, dossier, operateur = "P. O.")

  u <- c(uuid_v4(), uuid_v4(), uuid_v4())
  saisir(
    dossier,
    rbind(constat(u[[1L]], b$id[[1L]], "en_place", b$x[[1L]], b$y[[1L]]),
          constat(u[[2L]], b$id[[2L]], "non_retrouve", b$x[[2L]], b$y[[2L]],
                  precision = 3.5),
          constat(u[[3L]], NA_character_, "hors_plan", b$x[[2L]] + 40,
                  b$y[[2L]], precision = 4)),
    data.frame(uuid = c(uuid_v4(), uuid_v4()), constat_uuid = u[c(1L, 3L)],
               fichier = c("DCIM/limites_1.jpg", "DCIM/limites_2.jpg"),
               source = c("photo-exif-ii.jpg", "photo-sans-exif.jpg"),
               stringsAsFactors = FALSE)
  )

  bilan <- sommier_importer_qfield(con, foret, dossier, depot, auteur = "test")
  expect_equal(bilan$ecrits, 3L)
  expect_equal(bilan$photos, 2L)
  expect_true(sommier_verifier(con, foret)$valide)

  # L'UUID de QField devient celui de l'entree : reimporter n'ecrit rien.
  encore <- sommier_importer_qfield(con, foret, dossier, depot, auteur = "test")
  expect_equal(encore$ecrits, 0L)
  expect_equal(encore$deja_presents, 3L)

  vus <- DBI::dbGetQuery(
    con, "SELECT * FROM v_reconnaissance_limite WHERE foret_id = $1
           ORDER BY seq", params = list(foret))
  expect_equal(vus$etat, c("en_place", "non_retrouve", "hors_plan"))
  expect_equal(vus$element_numero[1:2], b$numero)
  expect_equal(vus$nb_photos, c(1L, 0L, 1L))
  expect_equal(as.numeric(vus$precision_m), c(0.02, 3.5, 4))
  expect_true(all(!is.na(vus$geom)))
  expect_setequal(vus$id, u)

  # Le constat recopie l'element et la photo par son empreinte ; l'EXIF est
  # une declaration de l'appareil, recopiee telle quelle.
  payload <- bilan$entrees[[1L]]$payload
  expect_equal(payload$element_pci$millesime, "2026-02-17")
  expect_equal(payload$photos[[1L]]$exif_position, "47.977000,2.030667")
  expect_length(list.files(depot), 2L)

  # La derniere visite colore le projet suivant.
  suivant <- file.path(withr::local_tempdir(), "limites-2")
  sommier_projet_qfield(con, foret, elements, suivant, operateur = "P. O.")
  points <- sf::read_sf(file.path(suivant, "terrain.gpkg"), "elements_points")
  expect_equal(points$a_visiter[points$id == b$id[[1L]]], "vu")
  expect_equal(points$a_visiter[points$id == b$id[[2L]]], "perdu")
})

test_that("un import fautif n'ecrit rien", {
  con <- base_limites()
  fond <- fond_zk01()
  foret <- foret_zk01(con, fond)
  elements <- sommier_elements_pci(fond, sommier_couche_ug(con, foret))
  b <- elements[elements$couche == "bornes", ][1:2, ]
  dossier <- file.path(withr::local_tempdir(), "limites")
  sommier_projet_qfield(con, foret, elements, dossier, operateur = "P. O.")
  saisir(dossier, rbind(
    constat(uuid_v4(), b$id[[1L]], "en_place", b$x[[1L]], b$y[[1L]]),
    constat(uuid_v4(), b$id[[2L]], "deplace", b$x[[2L]], b$y[[2L]])
  ))
  expect_error(
    sommier_importer_qfield(con, foret, dossier, withr::local_tempdir(),
                            auteur = "test"),
    "etat inconnu \\(deplace\\)"
  )
  expect_equal(nrow(sommier_lire(con, foret)), 0L)
})

test_that("une photo alteree se voit, une photo perdue ne rompt pas la chaine", {
  con <- base_limites()
  fond <- fond_zk01()
  foret <- foret_zk01(con, fond)
  elements <- sommier_elements_pci(fond, sommier_couche_ug(con, foret))
  b <- elements[elements$couche == "bornes", ][1:2, ]
  dossier <- file.path(withr::local_tempdir(), "limites")
  depot <- file.path(withr::local_tempdir(), "photos")
  sommier_projet_qfield(con, foret, elements, dossier, operateur = "P. O.")
  u <- c(uuid_v4(), uuid_v4())
  saisir(
    dossier,
    rbind(constat(u[[1L]], b$id[[1L]], "en_place", b$x[[1L]], b$y[[1L]]),
          constat(u[[2L]], b$id[[2L]], "endommage", b$x[[2L]], b$y[[2L]])),
    data.frame(uuid = c(uuid_v4(), uuid_v4()), constat_uuid = u,
               fichier = c("DCIM/a.jpg", "DCIM/b.jpg"),
               source = c("photo-exif-ii.jpg", "photo-sans-exif.jpg"),
               stringsAsFactors = FALSE)
  )
  sommier_importer_qfield(con, foret, dossier, depot, auteur = "test")
  expect_true(all(sommier_verifier_photos(con, foret, depot)$statut ==
                    "conforme"))

  # Le manifeste emporte les photos, et le destinataire les confronte.
  export <- withr::local_tempdir()
  manifeste <- file.path(export, "sommier.json")
  sommier_exporter_manifeste(con, foret, manifeste, depot = depot)
  expect_length(list.files(file.path(export, "photos")), 2L)
  expect_true(sommier_verifier_manifeste(manifeste,
                                         photos = file.path(export, "photos"))$valide)

  photos <- sort(list.files(depot, full.names = TRUE))
  # Un octet change : l'empreinte ne tient plus.
  octets <- readBin(photos[[1L]], "raw", file.size(photos[[1L]]))
  octets[[length(octets)]] <- xor(octets[[length(octets)]], as.raw(1L))
  writeBin(octets, photos[[1L]])
  # Une photo effacee : perdue pour la lecture, pas pour la chaine.
  unlink(photos[[2L]])

  statut <- sommier_verifier_photos(con, foret, depot)
  expect_setequal(statut$statut, c("alteree", "manquante"))
  expect_true(sommier_verifier(con, foret)$valide)

  # Meme lecture sur le manifeste : l'alteration est une anomalie, l'absence
  # une reserve.
  copies <- sort(list.files(file.path(export, "photos"), full.names = TRUE))
  writeBin(octets, copies[basename(copies) == basename(photos[[1L]])])
  unlink(copies[basename(copies) == basename(photos[[2L]])])
  rapport <- sommier_verifier_manifeste(manifeste,
                                        photos = file.path(export, "photos"))
  expect_false(rapport$valide)
  expect_equal(rapport$anomalies$type, "photo_alteree")
  expect_true(any(grepl("absente", rapport$reserves)))
})

test_that("le rapport montre ce que le terrain a vu, et la version publique le tait", {
  skip_if(!nzchar(Sys.which("quarto")), "Quarto n'est pas installe.")
  con <- base_limites()
  fond <- fond_zk01()
  foret <- foret_zk01(con, fond)
  elements <- sommier_elements_pci(fond, sommier_couche_ug(con, foret))
  b <- elements[elements$couche == "bornes", ][1:3, ]
  dossier <- file.path(withr::local_tempdir(), "limites")
  depot <- file.path(withr::local_tempdir(), "photos")
  sommier_projet_qfield(con, foret, elements, dossier, operateur = "P. O.")
  u <- c(uuid_v4(), uuid_v4(), uuid_v4(), uuid_v4())
  pointe <- constat(u[[3L]], b$id[[3L]], "endommage", b$x[[3L]], b$y[[3L]],
                    precision = NA_real_)
  saisir(
    dossier,
    rbind(
      # Mesure a 50 cm du plan, precision 2 cm : dans la tolerance.
      constat(u[[1L]], b$id[[1L]], "en_place", b$x[[1L]] + 0.5, b$y[[1L]]),
      # A 3 m, precision 2 cm : hors tolerance, sans verdict de deplacement.
      constat(u[[2L]], b$id[[2L]], "en_place", b$x[[2L]] + 3, b$y[[2L]]),
      # Sans precision : un pointe sur la carte.
      pointe,
      constat(u[[4L]], NA_character_, "hors_plan", b$x[[1L]] + 40, b$y[[1L]])
    ),
    data.frame(uuid = c(uuid_v4(), uuid_v4()), constat_uuid = u[c(1L, 2L)],
               fichier = c("DCIM/a.jpg", "DCIM/b.jpg"),
               source = c("photo-exif-ii.jpg", "photo-exif-mm.jpg"),
               stringsAsFactors = FALSE)
  )
  sommier_importer_qfield(con, foret, dossier, depot, auteur = "test")

  lus <- lire_reconnaissances(con, foret)$constats
  # Au centimetre pres : le payload porte la position en WGS84 a sept
  # decimales, et l'element a ses coordonnees au centimetre.
  expect_equal(lus$ecart_m[lus$id == u[[1L]]], 0.5, tolerance = 0.02)
  # Sans les elements du plan, l'echelle est inconnue : tolerance de 1 m.
  expect_true(lus$compatible[lus$id == u[[1L]]])
  # Avec eux, la feuille ZK01 est au 1/2000 : 0,4 m de precision graphique,
  # et 50 cm depassent 0,42 m.
  a_echelle <- lire_reconnaissances(con, foret, elements = elements)$constats
  expect_equal(unique(a_echelle$tolerance_plan_m[!is.na(a_echelle$element_id)]),
               0.4)
  expect_false(a_echelle$compatible[a_echelle$id == u[[1L]]])
  expect_false(lus$compatible[lus$id == u[[2L]]])
  expect_false(lus$mesure[lus$id == u[[3L]]])
  expect_true(is.na(lus$ecart_m[lus$id == u[[3L]]]))

  # Les deux photos sont identiques a l'image pres de l'ordre des octets de
  # leur EXIF : deux empreintes, deux vignettes. On altere la seconde.
  photos <- list.files(depot, full.names = TRUE)
  alteree <- photos[[2L]]
  octets <- readBin(alteree, "raw", file.size(alteree))
  octets[[length(octets)]] <- xor(octets[[length(octets)]], as.raw(1L))
  writeBin(octets, alteree)

  chemin <- withr::local_tempfile(fileext = ".html")
  sommier_rapport_quarto(con, foret, chemin, format = "html",
                         fond_pci = elements, photos = depot)
  html <- paste(readLines(chemin, warn = FALSE, encoding = "UTF-8"),
                collapse = "\n")
  expect_match(html, "Vérification des limites sur le terrain", fixed = TRUE)
  expect_no_match(html, "Le plan cadastral (EDIGEO) n", fixed = TRUE)
  expect_match(html, "Ce que la photo atteste", fixed = TRUE)
  expect_match(html, "hors tolérance", fixed = TRUE)
  expect_match(html, "pointé", fixed = TRUE)
  expect_match(html, "Hors plan", fixed = TRUE)
  expect_match(html, "Planche photographique", fixed = TRUE)
  # Pandoc rend l'apostrophe typographique : on s'arrete avant elle.
  expect_match(html, "contenu altéré depuis l", fixed = TRUE)
  expect_match(html, "Déclaré par l", fixed = TRUE)
  expect_match(html, "(EXIF)", fixed = TRUE)
  expect_no_match(html, "déplacé", fixed = TRUE)
  # Une seule vignette : celle dont l'empreinte tient.
  expect_equal(lengths(regmatches(html, gregexpr("<figure style=", html))), 1L)

  public <- withr::local_tempfile(fileext = ".html")
  sommier_rapport_quarto(con, foret, public, format = "html",
                         fond_pci = elements, photos = depot, public = TRUE)
  html <- paste(readLines(public, warn = FALSE, encoding = "UTF-8"),
                collapse = "\n")
  expect_match(html, "Version publique", fixed = TRUE)
  expect_no_match(html, "Planche photographique", fixed = TRUE)
  expect_no_match(html, "<figure style=", fixed = TRUE)
})
