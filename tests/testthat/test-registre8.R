test_that("un phenomene se construit et se valide", {
  p <- registre8_phenomene("tempete", "Coup de vent du 12 mars",
                           surface_ha = 8.5, volume_impacte_m3 = 340)
  expect_equal(p$type_entree, "phenomene")
  expect_equal(p$nature, "tempete")
  expect_error(registre8_phenomene("meteorite", "x"), "nature")
  expect_error(registre8_phenomene("tempete", "x", surface_ha = -1), "surface_ha")
})

test_that("la saison cynegetique enjambe deux annees consecutives", {
  # Elle court du 1er avril au 31 mars : elle ne peut ni tenir dans une seule
  # annee civile, ni en couvrir deux non consecutives.
  expect_silent(registre8_tableau_chasse("2025-2026", "chevreuil", 12))
  expect_error(registre8_tableau_chasse("2025-2027", "chevreuil", 12),
               "consecutives")
  expect_error(registre8_tableau_chasse("2026-2025", "chevreuil", 12),
               "consecutives")
  expect_error(registre8_tableau_chasse("2025", "chevreuil", 12), "AAAA-AAAA")
})

test_that("un tableau de chasse porte le realise et l'attribue", {
  p <- registre8_tableau_chasse("2025-2026", "chevreuil", nombre = 12,
                                classe_age = "adulte", sexe = "male",
                                attribue = 15)
  expect_equal(p$nombre, 12)
  expect_equal(p$attribue, 15)
  expect_error(registre8_tableau_chasse("2025-2026", "cerf", 1, sexe = "autre"),
               "sexe")
  expect_error(registre8_tableau_chasse("2025-2026", "cerf", -1), "nombre")
})

test_that("l'equilibre foret-gibier borne le taux d'abroutissement", {
  p <- registre8_equilibre_gibier("2025-2026", surface_sensible_ha = 42,
                                  taux_abroutissement_pct = 23.5,
                                  diagnostic = "desequilibre_leger")
  expect_equal(p$taux_abroutissement_pct, 23.5)
  expect_error(
    registre8_equilibre_gibier("2025-2026", 42, taux_abroutissement_pct = 101),
    "taux_abroutissement_pct"
  )
  expect_error(registre8_equilibre_gibier("2025-2026", 42, diagnostic = "bof"),
               "diagnostic")
})

test_that("une detection porte sa source et n'est pas un constat", {
  p <- registre8_detection("crise_sanitaire", "fordead",
                           "Deperissement sur pessiere", surface_ha = 3.2,
                           indice = 0.42)
  expect_equal(p$type_entree, "detection")
  expect_equal(p$source, "fordead")
})

test_that("le registre 8 redirige sur le constructeur de son type", {
  # La discriminante voyage dans le payload : c'est elle qui doit choisir le
  # constructeur a la relecture d'un export.
  for (p in list(
    registre8_phenomene("gel", "Gel tardif"),
    registre8_tableau_chasse("2025-2026", "sanglier", 4),
    registre8_equilibre_gibier("2025-2026", 10),
    registre8_detection("secheresse", "fast", "Stress hydrique")
  )) {
    expect_equal(valider_payload(8L, p), p)
  }
  expect_error(valider_payload(8L, list(nature = "gel")), "type_entree")
  expect_error(valider_payload(8L, list(type_entree = "autre")), "type_entree")
})

test_that("le registre 8 admet les deux echelles d'ancrage", {
  # Une tempete frappe des unites identifiees ; un tableau de chasse est a
  # l'echelle de la foret.
  expect_silent(sommier_entree(FORET_TEST, 8L, "2026-03-01", "a1",
                               registre8_phenomene("tempete", "x"),
                               ug_uuid = UG_TEST))
  expect_silent(sommier_entree(FORET_TEST, 8L, "2026-03-01", "a1",
                               registre8_tableau_chasse("2025-2026", "cerf", 2)))
})

test_that("une entree de registre 8 se chaine et se verifie", {
  e <- sommier_entree(FORET_TEST, 8L, "2026-03-01", "a1",
                      registre8_phenomene("incendie", "Depart de feu"),
                      date_saisie = "2026-08-18T10:00:00Z")
  expect_equal(e$schema_version, "r8-1.0.0")
  expect_true(sommier_verifier_chaine(sommier_chainer(list(e)))$valide)
})
