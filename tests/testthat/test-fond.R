# Fond cadastral : ce qui se verifie sans reseau, et ce qui l'exige.

test_that("le code INSEE est controle avant tout appel", {
  # Un code errone doit echouer ici, pas apres un telechargement inutile.
  expect_error(sommier_fond_cadastral("212"), "cinq caracteres")
  expect_error(sommier_fond_cadastral("Couchey"), "cinq caracteres")
  expect_error(sommier_fond_cadastral("21200", couche = "bornes"),
               "couche")
})

test_that("la Corse passe, ses codes commencant par 2A ou 2B", {
  expect_silent(valider_code_insee("2A004"))
  expect_silent(valider_code_insee("2B033"))
})

test_that("les couches annoncees sont celles que la source publie", {
  # Verifie le 20 aout 2026 sur cadastre.data.gouv.fr : ni bornes ni fosses.
  # Ce n'est pas un detail de nomenclature - c'est ce qui renvoie ces objets
  # au constat du gestionnaire, registres 2 et 4, avec leur geometrie.
  expect_setequal(SOMMIER_COUCHES_CADASTRE,
                  c("parcelles", "sections", "batiments", "lieux_dits"))
  expect_false("bornes" %in% SOMMIER_COUCHES_CADASTRE)
  expect_false("fosses" %in% SOMMIER_COUCHES_CADASTRE)
})

test_that("un fond absent du cache se dit plutot que de se deviner", {
  fond <- structure(
    list(chemin = file.path(tempdir(), "absent.json.gz"),
         code_insee = "21200", couche = "parcelles",
         millesime = NA_character_, source = "test"),
    class = "sommier_fond"
  )
  skip_if_not_installed("sf")
  expect_error(sommier_fond_lire(fond), "absent du cache")
})

test_that("sommier_fond_lire refuse ce qui ne vient pas du telechargement", {
  expect_error(sommier_fond_lire(data.frame(x = 1)),
               "sommier_fond_cadastral")
})

test_that("le millesime absent ne se remplace pas par une date inventee", {
  # Un fond date a tort vaut moins qu'un fond non date.
  expect_true(is.na(millesime_publie("file:///introuvable/")))
})

test_that("le fond se telecharge, se met en cache et porte son millesime", {
  skip_on_cran()
  testthat::skip_if_offline()
  skip_if_not_installed("sf")
  cache <- withr::local_tempdir()

  fond <- sommier_fond_cadastral("21200", cache = cache)
  expect_true(file.exists(fond$chemin))
  expect_equal(fond$code_insee, "21200")
  expect_match(fond$millesime, "^[0-9]{4}-[0-9]{2}-[0-9]{2}$")

  # Deuxieme appel : le cache sert, et le millesime survit au redemarrage.
  horodatage <- file.info(fond$chemin)$mtime
  encore <- sommier_fond_cadastral("21200", cache = cache)
  expect_equal(file.info(encore$chemin)$mtime, horodatage)
  expect_equal(encore$millesime, fond$millesime)

  # L'emprise restreint : Couchey compte des milliers de parcelles, une foret
  # n'en couvre qu'une poignee.
  emprise <- data.frame(wkt = paste0(
    "POLYGON((847000 6687000, 848000 6687000, 848000 6688000, ",
    "847000 6688000, 847000 6687000))"
  ))
  commune <- sommier_fond_lire(fond)
  autour <- sommier_fond_lire(fond, emprise = emprise)
  expect_gt(nrow(commune), nrow(autour))
  expect_gt(nrow(autour), 0L)
  expect_equal(attr(autour, "millesime"), fond$millesime)
  expect_match(autour$wkt[[1L]], "POLYGON")
})
