test_that("la nomenclature couvre les quatre blocs de l'imprime A50G", {
  expect_setequal(
    unique(SOMMIER_POSTES_COMPTABLES$rubrique),
    c("produits", "travaux_entretien", "travaux_neufs", "autres_frais")
  )
  expect_setequal(unique(SOMMIER_POSTES_COMPTABLES$sens), c("recette", "depense"))
  # Un poste ne peut appartenir qu'a un sens : la rubrique `produits` est la
  # seule recette, tout le reste est depense.
  recettes <- SOMMIER_POSTES_COMPTABLES$rubrique[SOMMIER_POSTES_COMPTABLES$sens == "recette"]
  expect_true(all(recettes == "produits"))
  expect_false(anyDuplicated(SOMMIER_POSTES_COMPTABLES$poste) > 0L)
})

test_that("le sens et la rubrique sont deduits du poste", {
  # Ils ne se saisissent pas : ils ne peuvent donc pas contredire le poste.
  recette <- registre7_ecriture("bois_sur_pied", 2026, 18400)
  expect_equal(recette$sens, "recette")
  expect_equal(recette$rubrique, "produits")

  depense <- registre7_ecriture("reboisement", 2026, 4800)
  expect_equal(depense$sens, "depense")
  expect_equal(depense$rubrique, "travaux_neufs")
})

test_that("le montant est toujours positif", {
  # Porter le sens dans le signe est la source classique de doubles negations.
  expect_error(registre7_ecriture("reboisement", 2026, -4800), "montant_eur")
  expect_silent(registre7_ecriture("reboisement", 2026, 0))
})

test_that("les postes et dispositifs hors nomenclature sont refuses", {
  expect_error(registre7_ecriture("caisse_noire", 2026, 1), "poste")
  expect_error(
    registre7_ecriture("bois_sur_pied", 2026, 1, dispositif_fiscal = "niche"),
    "dispositif_fiscal"
  )
  expect_silent(
    registre7_ecriture("reboisement", 2026, 1, dispositif_fiscal = "defi_travaux")
  )
})

test_that("une quantite sans unite est refusee", {
  expect_error(registre7_ecriture("bois_sur_pied", 2026, 1, quantite = 10),
               "unite")
})

test_that("le registre 7 s'ancre a l'echelle de la foret", {
  expect_error(
    sommier_entree(FORET_TEST, 7L, "2026-03-01", "a1",
                   registre7_ecriture("bois_sur_pied", 2026, 100),
                   ug_uuid = UG_TEST),
    "echelle de la foret"
  )
})

test_that("un payload de registre 7 se revalide depuis un export", {
  # `sens` et `rubrique` sont dans le payload stocke mais ne sont pas des
  # arguments du constructeur : la relecture doit les ecarter puis les
  # recalculer, sans echouer ni les perdre.
  p <- registre7_ecriture("chasse_peche", 2026, 3200, reference = "TR-14")
  expect_equal(valider_payload(7L, p), p)
})

test_that("une entree de registre 7 se chaine et se verifie", {
  e <- sommier_entree(FORET_TEST, 7L, "2026-03-01", "a1",
                      registre7_ecriture("bois_sur_pied", 2026, 18400),
                      date_saisie = "2026-08-18T10:00:00Z")
  expect_equal(e$schema_version, "r7-1.0.0")
  expect_true(sommier_verifier_chaine(sommier_chainer(list(e)))$valide)
})
