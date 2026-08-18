test_that("la table des registres couvre les neuf du sommier unifie", {
  expect_equal(nrow(SOMMIER_REGISTRES), 9L)
  expect_equal(SOMMIER_REGISTRES$registre, 1:9)
  expect_true(all(SOMMIER_REGISTRES$echelle %in% c("foret", "ug", "mixte")))
  expect_equal(
    SOMMIER_REGISTRES$registre[SOMMIER_REGISTRES$implemente],
    SOMMIER_REGISTRES_OUVERTS
  )
})

test_that("le registre 5 construit un payload minimal valide", {
  p <- registre5_coupe("martelage", 2026, "amelioration", volume_m3 = 120)
  expect_equal(p$type_entree, "martelage")
  expect_equal(p$volume_m3, 120)
  # Les champs facultatifs absents ne doivent pas apparaitre : les ajouter
  # plus tard ne doit pas ressembler a une correction de valeur.
  expect_false("surface_ha" %in% names(p))
  expect_false("observations" %in% names(p))
})

test_that("le registre 5 refuse les valeurs hors domaine", {
  expect_error(registre5_coupe("inconnu", 2026, "x", 1), "type_entree")
  expect_error(registre5_coupe("martelage", 2026, "x", -1), "volume_m3")
  expect_error(registre5_coupe("martelage", 1200, "x", 1), "exercice")
  expect_error(registre5_coupe("martelage", 2026.5, "x", 1), "entier")
  expect_error(registre5_coupe("martelage", 2026, "", 1), "nature_coupe")
  expect_error(registre5_coupe("martelage", 2026, "x", 1, surface_ha = -2), "surface_ha")
})

test_that("les types imputables a la balance excluent la coupe realisee", {
  # La meme coupe est d'abord martelee (A50E) puis exploitee (A50F) :
  # l'imputer deux fois doublerait le prelevement constate.
  expect_false("coupe_realisee" %in% SOMMIER_TYPES_MARTELES)
  expect_true(all(SOMMIER_TYPES_MARTELES %in% SOMMIER_TYPES_COUPE))
})

test_that("le registre 6 construit un payload valide", {
  p <- registre6_travaux(2026, "plantation", nb_plants = 1200,
                         taux_reprise_pct = 87.5)
  expect_equal(p$nb_plants, 1200)
  expect_equal(p$taux_reprise_pct, 87.5)
})

test_that("le registre 6 borne le taux de reprise a 0-100", {
  expect_error(registre6_travaux(2026, "plantation", taux_reprise_pct = 101),
               "taux_reprise_pct")
  expect_error(registre6_travaux(2026, "plantation", taux_reprise_pct = -1),
               "taux_reprise_pct")
  expect_silent(registre6_travaux(2026, "plantation", taux_reprise_pct = 0))
  expect_silent(registre6_travaux(2026, "plantation", taux_reprise_pct = 100))
})

test_that("une quantite sans unite est refusee", {
  # Un nombre sans unite n'est pas exploitable dans un registre destine a
  # etre relu par un tiers des annees plus tard.
  expect_error(registre6_travaux(2026, "degagement", quantite = 4), "unite")
  expect_silent(registre6_travaux(2026, "degagement", quantite = 4, unite = "ha"))
})

test_that("les registres non ouverts sont refuses avec un message utile", {
  for (r in setdiff(1:9, SOMMIER_REGISTRES_OUVERTS)) {
    expect_error(valider_payload(r, list()), "non ouvert a l'ecriture")
  }
})

test_that("valider_payload revalide un payload deja construit", {
  p <- registre5_coupe("martelage", 2026, "amelioration", 120)
  expect_equal(valider_payload(5L, p), p)
  expect_error(valider_payload(5L, list(type_entree = "martelage")), "argument")
})
