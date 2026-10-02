# Registre 6 : l'intervention codee, la placette et le controle - sans base.

polygone <- function() {
  geom_polygone(rbind(c(4.95, 47.27), c(4.952, 47.27), c(4.952, 47.272)))
}

test_that("une intervention d'avant la v0.28.0 se relit a l'identique", {
  # Sans type ni code : c'est ainsi que sont chainees les interventions
  # anterieures, et leur relecture ne doit pas changer un octet.
  ancienne <- registre6_travaux(2022, "plantation", nb_plants = 1050,
                                quantite = 1.75, unite = "ha",
                                taux_reprise_pct = 78)
  expect_null(ancienne$type_entree)
  expect_identical(jcs(valider_payload(6L, ancienne)), jcs(ancienne))
  expect_equal(SOMMIER_SCHEMA_VERSIONS[["6"]], "r6-1.2.0")
})

test_that("une intervention codee, localisee, se relit a l'identique", {
  p <- registre6_travaux(2026, "plantation de chene", code_travaux = "PL",
                         quantite = 1.2, unite = "ha", prevu = "prevu",
                         execution = "entreprise", intervenant = "ETF Martin",
                         date_reception = "2026-12-02", geometrie = polygone())
  relu <- jsonlite::fromJSON(jsonlite::toJSON(p, auto_unbox = TRUE,
                                              digits = NA),
                             simplifyVector = TRUE)
  expect_identical(jcs(valider_payload(6L, relu)), jcs(p))
})

test_that("le code fixe l'unite et la forme", {
  expect_error(registre6_travaux(2026, "x", code_travaux = "ZZ"),
               "code_travaux")
  expect_error(registre6_travaux(2026, "plantation", code_travaux = "PL",
                                 quantite = 3, unite = "km"),
               "se mesurent en ha")
  # Une cloture se trace en ligne, pas en surface.
  expect_error(registre6_travaux(2026, "cloture", code_travaux = "PG",
                                 geometrie = polygone()),
               "LineString")
  expect_silent(registre6_travaux(
    2026, "cloture", code_travaux = "PG", quantite = 250, unite = "m",
    geometrie = geom_ligne(rbind(c(4.95, 47.27), c(4.952, 47.271)))
  ))
  formes <- unlist(strsplit(SOMMIER_CODES_TRAVAUX$formes, ",\\s*"))
  expect_true(all(formes %in% c("point", "ligne", "surface")))
  # Deux unites, deux formes admises : un cloisonnement en m ou en ha, un
  # regarni en surface ou en point.
  expect_silent(registre6_travaux(2026, "cloisonnement", code_travaux = "CL",
                                  quantite = 2, unite = "ha"))
  expect_silent(registre6_travaux(2026, "regarni", code_travaux = "RG",
                                  quantite = 40, unite = "plants",
                                  geometrie = geom_point(4.95, 47.27)))
  expect_error(registre6_travaux(2026, "cloisonnement", code_travaux = "CL",
                                 quantite = 2, unite = "plants"),
               "m ou ha")
  expect_false(anyDuplicated(SOMMIER_CODES_TRAVAUX$code) > 0L)
})

test_that("hors prevu, un motif est exige", {
  expect_error(registre6_travaux(2026, "x", prevu = "non_prevu"),
               "motif_ecart")
  expect_error(registre6_travaux(2026, "x", prevu = "reporte"),
               "motif_ecart")
  expect_silent(registre6_travaux(2026, "x", prevu = "non_prevu",
                                  motif_ecart = "Chablis"))
  expect_error(registre6_travaux(2026, "x", prevu = "peut-etre"), "prevu")
})

test_that("une placette a un centre, et se relit", {
  expect_error(registre6_placette("P1", uuid_v4(), NULL), "obligatoire")
  expect_error(registre6_placette("P1", uuid_v4(), polygone()), "Point")
  p <- registre6_placette("P35-01", uuid_v4(), geom_point(4.95, 47.27))
  expect_equal(p$type_entree, "placette")
  expect_equal(p$rayon_m, 3.99)
  expect_identical(valider_payload(6L, p), p)
})

test_that("un controle ne compte pas plus de vivants que de plants", {
  id <- uuid_v4()
  expect_error(registre6_controle(id, 10, 12), "Plus de plants vivants")
  expect_error(registre6_controle(id, 10, 8, nb_abroutis = 9), "abroutis")
  expect_error(registre6_controle(id, 10, 8, besoin = "ZZ"), "besoin")
  c1 <- registre6_controle(id, 20, 17, h_moy_cm = 45, nb_abroutis = 3,
                           concurrence = "forte", besoin = "DG",
                           visite_le = "2025-06-10T10:00:00Z")
  expect_equal(c1$type_entree, "controle")
  expect_identical(valider_payload(6L, c1), c1)
  # Le taux, la densite et la part d'abroutis ne s'inscrivent pas.
  expect_false(any(c("taux_reprise_pct", "densite_ha") %in% names(c1)))
})

test_that("un type inconnu est refuse a la relecture", {
  expect_error(valider_payload(6L, list(type_entree = "chantier", annee = 1)),
               "type_entree")
})
