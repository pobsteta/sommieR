# Ces tests exigent une base PostgreSQL/PostGIS joignable et le pilote
# RPostgres. Ils sont ignores sinon : le noyau du package se teste
# entierement hors base, seule la couche d'acces a besoin d'un serveur.
#
#   createdb sommier_test && SOMMIER_TEST_DB=sommier_test Rscript -e \
#     'testthat::test_local()'

base_prete <- function() {
  con <- sauter_sans_base()
  withr::defer(DBI::dbDisconnect(con), envir = parent.frame())
  sommier_init_schema(con)
  con
}

test_that("le schema se deploie et se rejoue sans dommage", {
  con <- base_prete()
  expect_silent(sommier_init_schema(con))     # idempotent
  expect_true(DBI::dbExistsTable(con, "entree_sommier"))
})

test_that("une entree ecrite se relit et se verifie", {
  con <- base_prete()
  foret <- foret_creer(con, "Foret test", "communal", surface_ha = 500)
  ug <- ug_creer(con, foret, "1", "2020-01-01")

  sommier_ajouter(con, sommier_entree(
    foret_id = foret, registre = 5L, date_evenement = "2026-03-01",
    auteur = "agent-01", ug_uuid = ug,
    payload = registre5_coupe("martelage", 2026, "amelioration", 120)
  ))

  lues <- sommier_lire(con, foret)
  expect_equal(nrow(lues), 1L)
  expect_equal(lues$seq, 1)
  expect_true(sommier_verifier(con, foret)$valide)
})

test_that("la sequence progresse et la chaine reste valide sur plusieurs ecritures", {
  con <- base_prete()
  foret <- foret_creer(con, "Foret test", "domanial")
  for (i in 1:5) {
    sommier_ajouter(con, sommier_entree(
      foret_id = foret, registre = 5L, date_evenement = "2026-03-01",
      auteur = "agent-01",
      payload = registre5_coupe("martelage", 2026, "amelioration", 10 * i)
    ))
  }
  expect_equal(sommier_lire(con, foret)$seq, 1:5)
  expect_true(sommier_verifier(con, foret)$valide)
})

test_that("l'ecriture par lot chaine dans l'ordre fourni", {
  con <- base_prete()
  foret <- foret_creer(con, "Foret test", "domanial")
  entrees <- lapply(1:3, function(i) sommier_entree(
    foret_id = foret, registre = 6L, date_evenement = "2026-04-01",
    auteur = "agent-01", payload = registre6_travaux(2026, paste0("travaux ", i))
  ))
  sommier_ajouter(con, entrees)
  expect_true(sommier_verifier(con, foret)$valide)
  expect_equal(nrow(sommier_lire(con, foret, registre = 6L)), 3L)
})

test_that("la base refuse toute mutation d'une entree", {
  con <- base_prete()
  foret <- foret_creer(con, "Foret test", "communal")
  sommier_ajouter(con, sommier_entree(
    foret_id = foret, registre = 5L, date_evenement = "2026-03-01",
    auteur = "agent-01",
    payload = registre5_coupe("martelage", 2026, "amelioration", 10)
  ))
  expect_error(
    DBI::dbExecute(con, "UPDATE entree_sommier SET auteur = 'pirate'"),
    "append-only"
  )
  expect_error(DBI::dbExecute(con, "DELETE FROM entree_sommier"), "append-only")
  expect_error(DBI::dbExecute(con, "TRUNCATE entree_sommier"), "append-only")
})

test_that("la balance A50E se calcule comme l'imprime", {
  con <- base_prete()
  foret <- foret_creer(con, "Foret test", "communal")
  exercice_definir(con, foret, 2025, 100)
  exercice_definir(con, foret, 2026, 100)

  ajouter <- function(type, annee, volume) {
    sommier_ajouter(con, sommier_entree(
      foret_id = foret, registre = 5L,
      date_evenement = paste0(annee, "-03-01"), auteur = "agent-01",
      payload = registre5_coupe(type, annee, "amelioration", volume)
    ))
  }
  ajouter("martelage", 2025, 120)
  ajouter("produit_accidentel", 2025, 5)
  ajouter("coupe_realisee", 2025, 118)   # ne compte pas dans le martele
  ajouter("martelage", 2026, 60)

  bal <- sommier_balance_possibilite(con, foret)
  expect_equal(bal$volume_martele_m3, c(125, 60))
  expect_equal(bal$volume_realise_m3, c(118, 0))
  expect_equal(bal$balance_exercice_m3, c(25, -40))
  expect_equal(bal$balance_cumulee_m3, c(25, -15))
})

test_that("une correction sort des vues sans sortir de la chaine", {
  con <- base_prete()
  foret <- foret_creer(con, "Foret test", "communal")
  exercice_definir(con, foret, 2026, 100)

  premiere <- sommier_ajouter(con, sommier_entree(
    foret_id = foret, registre = 5L, date_evenement = "2026-03-01",
    auteur = "agent-01",
    payload = registre5_coupe("martelage", 2026, "amelioration", 120)
  ))[[1]]

  sommier_ajouter(con, sommier_entree(
    foret_id = foret, registre = 5L, date_evenement = "2026-03-01",
    auteur = "agent-02", corrige_id = premiere$id,
    payload = registre5_coupe("martelage", 2026, "amelioration", 95)
  ))

  expect_equal(sommier_balance_possibilite(con, foret)$volume_martele_m3, 95)
  expect_equal(nrow(sommier_lire(con, foret)), 2L)   # la chaine garde tout
  expect_true(sommier_verifier(con, foret)$valide)
})

test_that("une scission clot le parent et cree les enfants", {
  con <- base_prete()
  foret <- foret_creer(con, "Foret test", "domanial")
  parent <- ug_creer(con, foret, "12", "2010-01-01")
  enfants <- ug_scinder(con, parent, list(
    list(numero_affichage = "12a"), list(numero_affichage = "12b")
  ), date_effet = "2026-01-01")

  expect_length(enfants, 2L)
  expect_equal(ug_lire(con, parent)$date_fin, as.Date("2026-01-01"))
  expect_setequal(ug_lire(con, foret_id = foret, actives_seulement = TRUE)$numero_affichage,
                  c("12a", "12b"))
  filiation <- DBI::dbGetQuery(con, "SELECT * FROM ug_filiation")
  expect_equal(nrow(filiation), 2L)
  expect_true(all(filiation$type_filiation == "scission"))
})

test_that("une fusion enregistre plusieurs parents", {
  # Le cas que `parent_uuid` seul ne sait pas representer.
  con <- base_prete()
  foret <- foret_creer(con, "Foret test", "domanial")
  a <- ug_creer(con, foret, "20", "2010-01-01")
  b <- ug_creer(con, foret, "21", "2010-01-01")
  nouveau <- ug_fusionner(con, c(a, b), "20-21", "2026-01-01")

  filiation <- DBI::dbGetQuery(
    con, "SELECT * FROM ug_filiation WHERE enfant_uuid = $1", params = list(nouveau)
  )
  expect_equal(nrow(filiation), 2L)
  expect_setequal(filiation$parent_uuid, c(a, b))
  expect_equal(nrow(ug_lire(con, foret_id = foret, actives_seulement = TRUE)), 1L)
})

test_that("les entrees d'une unite cloturee restent lisibles", {
  # C'est tout l'interet d'un identifiant stable : le redecoupage ne doit pas
  # rendre l'historique illisible.
  con <- base_prete()
  foret <- foret_creer(con, "Foret test", "domanial")
  parent <- ug_creer(con, foret, "12", "2010-01-01")
  sommier_ajouter(con, sommier_entree(
    foret_id = foret, registre = 6L, date_evenement = "2015-04-01",
    auteur = "agent-01", ug_uuid = parent,
    payload = registre6_travaux(2015, "plantation", nb_plants = 800)
  ))
  ug_scinder(con, parent, list(list(numero_affichage = "12a"),
                               list(numero_affichage = "12b")), "2026-01-01")

  lues <- sommier_lire(con, foret, registre = 6L)
  expect_equal(lues$ug_uuid, parent)
  expect_true(sommier_verifier(con, foret)$valide)
})

test_that("le manifeste exporte se verifie hors ligne", {
  con <- base_prete()
  foret <- foret_creer(con, "Foret test", "communal")
  sommier_ajouter(con, sommier_entree(
    foret_id = foret, registre = 5L, date_evenement = "2026-03-01",
    auteur = "agent-01",
    payload = registre5_coupe("martelage", 2026, "amelioration", 120)
  ))
  chemin <- withr::local_tempfile(fileext = ".json")
  sommier_exporter_manifeste(con, foret, chemin)
  expect_true(sommier_verifier_manifeste(chemin)$valide)
})
