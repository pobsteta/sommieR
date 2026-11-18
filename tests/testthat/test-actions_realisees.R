# Le realise rendu au plan d'action de nemetonshiny : six colonnes, rien que
# des travaux recus qui portent une action.

colonnes_contrat <- c("action_id", "travaux_id", "code_travaux",
                      "date_reception", "quantite", "unite")

test_that("le CSV d'exemple tient le contrat et se relit", {
  exemple <- test_path("fixtures", "actions-realisees-exemple.csv")
  x <- utils::read.csv(exemple, fileEncoding = "UTF-8",
                       colClasses = c(quantite = "numeric"))
  expect_identical(names(x), colonnes_contrat)
  expect_identical(COLONNES_ACTIONS_REALISEES, colonnes_contrat)
  expect_equal(sum(x$quantite[x$action_id == "act_20261105093012_k3x9a1" & x$unite == "ha"]),
               1.75)
  # Ecrit par la fonction du paquet, il redonne l'exemple ligne pour ligne.
  sortie <- withr::local_tempfile(fileext = ".csv")
  ecrire_actions_realisees(x[, colonnes_contrat], sortie)
  expect_identical(
    gsub('"', "", readLines(sortie)), readLines(exemple))
})

test_that("action_id est un champ facultatif du payload de travaux", {
  p <- registre6_travaux(2026, "plantation", action_id = "act_20261105093012_k3x9a1")
  expect_identical(p$action_id, "act_20261105093012_k3x9a1")
  expect_null(registre6_travaux(2026, "plantation")$action_id)
  expect_identical(valider_payload(6L, p)$action_id, "act_20261105093012_k3x9a1")
  expect_error(registre6_travaux(2026, "plantation", action_id = 12),
               "action_id")
})

test_that("seuls les travaux recus et portant une action sortent", {
  con <- sauter_sans_base()
  withr::defer(DBI::dbDisconnect(con))
  sommier_init_schema(con)
  foret <- foret_creer(con, paste0("Foret actions-", substr(uuid_v4(), 1L, 8L)),
                       "communal")
  ecrire <- function(date, ...) {
    sommier_ajouter(con, sommier_entree(
      foret_id = foret, registre = 6L, date_evenement = date,
      auteur = "agent-01", payload = registre6_travaux(2026, "travaux", ...)
    ))[[1L]]$id
  }
  recu <- ecrire("2026-03-12", code_travaux = "PL", quantite = 1.75,
                 unite = "ha", date_reception = "2026-03-12",
                 action_id = "act_20261105093012_k3x9a1")
  recu2 <- ecrire("2026-04-02", code_travaux = "RG", quantite = 120,
                  unite = "plants", date_reception = "2026-04-02",
                  action_id = "act_20261105093012_k3x9a1")
  # Non recu : pas de date de reception.
  ecrire("2026-05-01", code_travaux = "DG", quantite = 1, unite = "ha",
         action_id = "act_20261105093100_b5c6d7")
  # Sans action du plan.
  ecrire("2026-05-02", code_travaux = "DG", quantite = 1, unite = "ha",
         date_reception = "2026-05-02")
  # Hors de la periode de 2026, et sans quantite.
  hors <- ecrire("2027-01-10", code_travaux = "PG",
                 date_reception = "2027-01-10", action_id = "act_20261106101502_m4w8tb")

  x <- sommier_actions_realisees(con, foret)
  expect_identical(names(x), colonnes_contrat)
  expect_identical(x$travaux_id, c(recu, recu2, hors))
  expect_identical(x$action_id, c("act_20261105093012_k3x9a1", "act_20261105093012_k3x9a1", "act_20261106101502_m4w8tb"))
  expect_true(is.na(x$quantite[[3L]]))

  x <- sommier_actions_realisees(con, foret, debut = "2026-01-01",
                                 fin = "2026-12-31")
  expect_identical(x$travaux_id, c(recu, recu2))

  fichier <- withr::local_tempfile(fileext = ".csv")
  sommier_actions_realisees(con, foret, fichier = fichier)
  lu <- utils::read.csv(fichier, fileEncoding = "UTF-8")
  expect_identical(names(lu), colonnes_contrat)
  expect_equal(nrow(lu), 3L)

  vide <- foret_creer(con, paste0("Foret vide-", substr(uuid_v4(), 1L, 8L)),
                      "communal")
  expect_equal(nrow(sommier_actions_realisees(con, vide)), 0L)
})

test_that("le programme de nemetonshiny se lit : l'id devient action_id", {
  skip_if_not_installed("sf")
  x <- sommier_lire_programme_travaux(
    test_path("fixtures", "programme-travaux-exemple.gpkg"))
  expect_s3_class(x, "data.frame")
  expect_false(inherits(x, "sf"))
  expect_identical(x$action_id, c("act_20261105093012_k3x9a1", "act_20261105093044_p7q2zd", "act_20261106101502_m4w8tb"))
  expect_identical(x$ug_id, c("12", "12", "13"))
  expect_true(all(c("type", "annee_civile", "surface_ha", "statut") %in%
                    names(x)))
  expect_match(libelle_action_programme(x)[[1L]],
               "^act_20261105093012_k3x9a1 - UG 12 plantation 2026 1.75 ha$")
  expect_error(sommier_lire_programme_travaux("absent.gpkg"), "introuvable")
  # Un GeoPackage sans couche `actions` n'est pas un programme.
  autre <- withr::local_tempfile(fileext = ".gpkg")
  sf::st_write(sf::st_sf(a = 1, geometry = sf::st_sfc(sf::st_point(c(0, 0)),
                                                       crs = 2154)),
               autre, layer = "autre", quiet = TRUE)
  expect_error(sommier_lire_programme_travaux(autre), "couche `actions`")
})

test_that("la reprise tableur porte l'action_id au registre 6", {
  skip_if_not_installed("sf")
  con <- sauter_sans_base()
  withr::defer(DBI::dbDisconnect(con))
  sommier_init_schema(con)
  foret <- foret_creer(con, paste0("Foret tableur-", substr(uuid_v4(), 1L, 8L)),
                       "communal")
  tableur <- withr::local_tempfile(fileext = ".csv")
  writeLines(enc2utf8(c(
    "Année;Code;Nature;Quantité;Unité;Date réception;Action_id",
    "2026;PL;Plantation;1,75;ha;02/03/2026;act_20261105093012_k3x9a1",
    "2026;DG;Dégagement;1;ha;03/03/2026;"
  )), tableur, useBytes = TRUE)
  source <- reprise_source("tableur", "Programme 2026", detenteur = "ONF")
  sommier_reprendre_travaux(con, foret, tableur, auteur = "agent-01",
                            source = source)
  x <- sommier_actions_realisees(con, foret)
  expect_identical(x$action_id, "act_20261105093012_k3x9a1")
  expect_identical(x$code_travaux, "PL")
  expect_equal(x$quantite, 1.75)
})
