# PCI vecteur : ce qui se verifie sans reseau, et ce qui l'exige.

test_that("les couches annoncees sont celles du modele EDIGEO", {
  expect_equal(SOMMIER_COUCHES_PCI[["bornes"]], "BORNE_id")
  expect_equal(SOMMIER_COUCHES_PCI[["details"]], "TLINE_id")
  expect_setequal(names(SOMMIER_COUCHES_PCI),
                  c("bornes", "details", "parcelles", "voies"))
})

test_that("sommier_fond_pci_lire refuse ce qui ne vient pas du telechargement", {
  expect_error(sommier_fond_pci_lire(data.frame(x = 1)), "sommier_fond_pci")
})

test_that("une couche inconnue est refusee avant toute lecture", {
  fond <- structure(
    list(feuilles = data.frame(feuille = "212000000A01", thf = "absent.THF"),
         code_insee = "21200", source = "test"),
    class = "sommier_fond_pci"
  )
  skip_if_not_installed("sf")
  expect_error(sommier_fond_pci_lire(fond, couche = "fosses"), "couche")
})

test_that("une projection inattendue est signalee, jamais reinterpretee", {
  # Les livraisons `edigeo-cc` sont en coniques conformes par zone. Les
  # reprojeter au hasard poserait la feuille a cote de la foret sans que rien
  # ne l'annonce - c'est le defaut du GeoJSON en Lambert-93 corrige en v0.6.0.
  skip_if_not_installed("sf")
  point <- sf::st_sfc(sf::st_point(c(1650000, 2200000)), crs = 3946)
  expect_error(poser_lambert93(point, "feuille-cc.THF"),
               "projection inattendue")

  # Et le Lambert-93 reconnu se pose sans bruit, meme prive de son code EPSG.
  # `st_crs<-` avertit qu'il ne reprojette pas : c'est precisement ce qu'on
  # veut ici - la donnee est deja en Lambert-93, il lui manque son etiquette.
  sans_epsg <- suppressWarnings(sf::st_set_crs(
    sf::st_sfc(sf::st_point(c(847500, 6687400))),
    sf::st_crs(sf::st_crs(2154)$proj4string)
  ))
  expect_equal(sf::st_crs(poser_lambert93(sans_epsg, "f.THF"))$epsg, 2154L)
})

test_that("la nature d'un detail n'est pas devinee", {
  # `SYM` distingue mur, fosse et haie, mais sa nomenclature ne figure ni dans
  # le .DIC ni dans le .SCD de l'archive. Sans table fournie, la nature reste
  # inconnue plutot qu'inventee.
  details <- data.frame(sym = c("21", "22", "31"), stringsAsFactors = FALSE)
  sans <- appliquer_symboles(details, NULL)
  expect_true(all(is.na(sans)))

  avec <- appliquer_symboles(details, c("21" = "mur", "22" = "fosse"))
  expect_equal(avec, c("mur", "fosse", NA))
})

test_that("le PCI se telecharge feuille par feuille, et seulement les utiles", {
  skip_on_cran()
  testthat::skip_if_offline()
  skip_if_not_installed("sf")
  cache <- withr::local_tempdir()

  # Couchey compte dix-sept feuilles ; une foret en touche une ou deux.
  emprise <- data.frame(wkt = paste0(
    "POLYGON((847400 6687300, 847900 6687300, 847900 6687600, ",
    "847400 6687600, 847400 6687300))"
  ))
  toutes <- sommier_feuilles_pci("21200", cache = cache)
  autour <- sommier_feuilles_pci("21200", emprise = emprise, cache = cache)
  expect_gt(nrow(toutes), nrow(autour))
  expect_gt(nrow(autour), 0L)

  fond <- sommier_fond_pci("21200", autour$feuille, cache = cache)
  expect_equal(nrow(fond$feuilles), nrow(autour))
  expect_true(all(file.exists(fond$feuilles$thf)))

  bornes <- sommier_fond_pci_lire(fond, "bornes")
  expect_gt(nrow(bornes), 0L)
  expect_match(bornes$wkt[[1L]], "^POINT")
  # Ce que les livraisons GeoJSON n'exposent pas, et qui motive ce lot.
  details <- sommier_fond_pci_lire(fond, "details")
  expect_gt(nrow(details), 0L)
  expect_false(all(is.na(details$sym)))

  # Deuxieme appel : l'archive deja decompressee ne se retelecharge pas.
  horodatage <- file.info(fond$feuilles$thf[[1L]])$mtime
  encore <- sommier_fond_pci("21200", autour$feuille, cache = cache)
  expect_equal(file.info(encore$feuilles$thf[[1L]])$mtime, horodatage)
})
