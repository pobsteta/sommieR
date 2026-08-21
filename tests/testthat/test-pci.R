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

# Un lot EDIGEO reduit a sa declaration de referentiel : de quoi verifier ce
# que le paquet en fait, sans telecharger une feuille.
lot_declarant <- function(reference, env = parent.frame()) {
  dossier <- withr::local_tempdir(.local_envir = env)
  thf <- file.path(dossier, "E0000A01.THF")
  writeLines("BOMT 12:E0000A01.THF", thf)
  if (!is.null(reference)) {
    writeLines(c("RTYSA03:GEO", paste0("RELSA06:", reference), "UNHST01:m"),
               file.path(dossier, "ED0A01SE.GEO"))
  }
  thf
}

test_that("le referentiel se lit dans la declaration du lot", {
  # EDIGEO est auto-descripteur : le `.GEO` porte le referentiel employe. Le
  # lire vaut mieux que reconnaitre une chaine proj4 - la declaration est
  # l'intention du producteur, le proj4 une traduction du pilote, rendue sans
  # code EPSG.
  expect_equal(projection_declaree(lot_declarant("LAMB93")), "LAMB93")
  expect_equal(projection_declaree(lot_declarant("CC47")), "CC47")
  expect_true(is.na(projection_declaree(lot_declarant(NULL))))
})

test_that("une conique conforme declaree est ramenee en Lambert-93", {
  # Les livraisons `edigeo-cc` sont en CC42 a CC50 : elles ne sont plus
  # refusees, elles sont reprojetees d'apres ce qu'elles declarent.
  skip_if_not_installed("sf")
  ramene <- poser_projection(sf::st_sfc(sf::st_point(c(1700000, 5300000))),
                             lot_declarant("CC47"))
  expect_equal(sf::st_crs(ramene)$epsg, 2154L)
})

test_that("un referentiel absent ou inconnu est signale, jamais devine", {
  # Reprojeter au hasard poserait la feuille a cote de la foret sans que rien
  # ne l'annonce - c'est le defaut du GeoJSON corrige en v0.6.0.
  skip_if_not_installed("sf")
  nu <- sf::st_sfc(sf::st_point(c(847500, 6687400)))
  expect_error(poser_projection(nu, lot_declarant(NULL)), "aucune declaration")
  expect_error(poser_projection(nu, lot_declarant("UTM31")),
               "referentiel declare")
})

test_that("une geometrie deja etiquetee n'est pas retouchee", {
  skip_if_not_installed("sf")
  l93 <- sf::st_sfc(sf::st_point(c(847500, 6687400)), crs = 2154)
  expect_equal(sf::st_crs(poser_projection(l93, lot_declarant("LAMB93")))$epsg,
               2154L)
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
