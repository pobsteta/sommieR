test_that("le registre 1 construit un payload valide", {
  p <- registre1_validation("visa_annuel", "commune", "Maire de Chaux",
                            exercice = 2026)
  expect_equal(p$type_validation, "visa_annuel")
  expect_equal(p$autorite, "commune")
  expect_equal(p$exercice, 2026)
})

test_that("un visa annuel sans exercice est refuse", {
  # Le visa de l'imprime A10 est annuel : sans exercice il ne se rattache a
  # aucune periode et le controle de tenue devient invérifiable.
  expect_error(registre1_validation("visa_annuel", "onf", "Chef de service"),
               "exercice")
  expect_error(registre1_validation("visa_direction", "onf", "Directeur"),
               "exercice")
  # Un arrete, lui, n'est pas rattache a un exercice.
  expect_silent(registre1_validation("arrete", "prefet", "Prefet du Jura",
                                     reference = "AP-2026-114"))
})

test_that("les types et autorites hors domaine sont refuses", {
  expect_error(registre1_validation("inconnu", "onf", "X", exercice = 2026),
               "type_validation")
  expect_error(registre1_validation("arrete", "voisin", "X"), "autorite")
  expect_error(registre1_validation("arrete", "onf", "X", portee = "autre"),
               "portee")
})

test_that("le registre 1 s'ancre a l'echelle de la foret", {
  expect_error(
    sommier_entree(FORET_TEST, 1L, "2026-03-01", "a1",
                   registre1_validation("visa_annuel", "commune", "Maire",
                                        exercice = 2026),
                   ug_uuid = UG_TEST),
    "echelle de la foret"
  )
})

test_that("une entree de registre 1 se chaine et se verifie", {
  e <- sommier_entree(
    FORET_TEST, 1L, "2026-03-01", "a1",
    registre1_validation("visa_annuel", "commune", "Maire", exercice = 2026),
    date_saisie = "2026-08-18T10:00:00Z"
  )
  expect_equal(e$schema_version, "r1-1.0.0")
  expect_true(sommier_verifier_chaine(sommier_chainer(list(e)))$valide)
})
