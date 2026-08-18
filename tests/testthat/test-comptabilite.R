base_compta <- function() {
  con <- sauter_sans_base()
  withr::defer(DBI::dbDisconnect(con), envir = parent.frame())
  sommier_init_schema(con)
  con
}

ecrire <- function(con, foret, poste, exercice, montant, ...) {
  sommier_ajouter(con, sommier_entree(
    foret_id = foret, registre = 7L,
    date_evenement = paste0(exercice, "-06-30"), auteur = "compta-01",
    payload = registre7_ecriture(poste, exercice, montant, ...)
  ))
}

test_that("le bilan financier somme recettes, depenses et solde", {
  con <- base_compta()
  foret <- foret_creer(con, "Foret test", "communal")

  ecrire(con, foret, "bois_sur_pied", 2025, 18400)
  ecrire(con, foret, "chasse_peche", 2025, 3200)
  ecrire(con, foret, "reboisement", 2025, 4800)
  ecrire(con, foret, "entretien_peuplements", 2025, 2100)
  ecrire(con, foret, "frais_garderie", 2025, 1500)
  ecrire(con, foret, "bois_sur_pied", 2026, 9000)
  ecrire(con, foret, "reboisement", 2026, 12000)

  bilan <- sommier_bilan_financier(con, foret)
  expect_equal(bilan$exercice, c(2025L, 2026L))
  expect_equal(bilan$recettes_eur, c(21600, 9000))
  expect_equal(bilan$depenses_eur, c(8400, 12000))
  expect_equal(bilan$solde_eur, c(13200, -3000))
  # Le cumul enchaine les soldes : 13200 puis 13200 - 3000.
  expect_equal(bilan$solde_cumule_eur, c(13200, 10200))
  expect_equal(bilan$travaux_neufs_eur, c(4800, 12000))
  expect_equal(bilan$autres_frais_eur, c(1500, 0))
})

test_that("l'affouage est isole dans le bilan", {
  # L'imprime A50G lui reserve sa colonne, et le conseil municipal la lit
  # pour elle-meme.
  con <- base_compta()
  foret <- foret_creer(con, "Foret communale", "communal")
  ecrire(con, foret, "bois_sur_pied", 2026, 10000)
  ecrire(con, foret, "bois_delivres", 2026, 2500)

  bilan <- sommier_bilan_financier(con, foret)
  expect_equal(bilan$bois_delivres_eur, 2500)
  expect_equal(bilan$recettes_eur, 12500)   # l'affouage reste une recette
})

test_that("une correction se repercute sur le bilan sans sortir de la chaine", {
  con <- base_compta()
  foret <- foret_creer(con, "Foret test", "domanial")
  premiere <- ecrire(con, foret, "bois_sur_pied", 2026, 18400)[[1]]

  sommier_ajouter(con, sommier_entree(
    foret_id = foret, registre = 7L, date_evenement = "2026-06-30",
    auteur = "compta-02", corrige_id = premiere$id,
    payload = registre7_ecriture("bois_sur_pied", 2026, 17950,
                                 observations = "Erreur de saisie")
  ))

  expect_equal(sommier_bilan_financier(con, foret)$recettes_eur, 17950)
  expect_equal(nrow(sommier_lire(con, foret)), 2L)   # la chaine garde tout
  expect_true(sommier_verifier(con, foret)$valide)
})

test_that("l'execution budgetaire confronte realise et previsionnel", {
  con <- base_compta()
  foret <- foret_creer(con, "Foret test", "communal")
  budget_definir(con, foret, 2026, "bois_sur_pied", 20000)
  budget_definir(con, foret, 2026, "reboisement", 5000)
  ecrire(con, foret, "bois_sur_pied", 2026, 18400)
  ecrire(con, foret, "reboisement", 2026, 6250)

  exec <- sommier_execution_budgetaire(con, foret, exercice = 2026)
  bois <- exec[exec$poste == "bois_sur_pied", ]
  expect_equal(bois$prevu_eur, 20000)
  expect_equal(bois$realise_eur, 18400)
  expect_equal(bois$ecart_eur, -1600)
  expect_equal(bois$execution_pct, 92)

  reboisement <- exec[exec$poste == "reboisement", ]
  expect_equal(reboisement$ecart_eur, 1250)
  expect_equal(reboisement$execution_pct, 125)
})

test_that("un poste budgete mais non execute reste visible", {
  # Un budget jamais consomme est un fait de gestion : il ne doit pas
  # disparaitre du tableau parce qu'aucune ecriture ne lui correspond.
  con <- base_compta()
  foret <- foret_creer(con, "Foret test", "domanial")
  budget_definir(con, foret, 2026, "equipement", 8000)

  exec <- sommier_execution_budgetaire(con, foret, exercice = 2026)
  expect_equal(nrow(exec), 1L)
  expect_equal(exec$prevu_eur, 8000)
  expect_equal(exec$realise_eur, 0)
  expect_equal(exec$ecart_eur, -8000)
  expect_equal(exec$execution_pct, 0)
})

test_that("un poste execute hors budget reste visible", {
  con <- base_compta()
  foret <- foret_creer(con, "Foret test", "domanial")
  ecrire(con, foret, "honoraires", 2026, 1200)

  exec <- sommier_execution_budgetaire(con, foret, exercice = 2026)
  expect_equal(nrow(exec), 1L)
  expect_equal(exec$prevu_eur, 0)
  expect_equal(exec$realise_eur, 1200)
  # Un taux d'execution sur une base nulle n'a pas de sens.
  expect_true(is.na(exec$execution_pct))
})

test_that("le budget se revise sans toucher au realise", {
  # Le previsionnel est mutable, le registre ne l'est pas.
  con <- base_compta()
  foret <- foret_creer(con, "Foret test", "communal")
  budget_definir(con, foret, 2026, "reboisement", 5000)
  ecrire(con, foret, "reboisement", 2026, 6250)
  budget_definir(con, foret, 2026, "reboisement", 7000)   # revision

  exec <- sommier_execution_budgetaire(con, foret, exercice = 2026)
  expect_equal(exec$prevu_eur, 7000)
  expect_equal(exec$realise_eur, 6250)
  expect_equal(nrow(sommier_lire(con, foret)), 1L)
  expect_true(sommier_verifier(con, foret)$valide)
})

test_that("budget_definir refuse un poste hors nomenclature", {
  con <- base_compta()
  foret <- foret_creer(con, "Foret test", "domanial")
  expect_error(budget_definir(con, foret, 2026, "caisse_noire", 100), "poste")
  expect_error(budget_definir(con, foret, 2026, "reboisement", -1), "montant_eur")
})

test_that("le tiers ne fuit pas par la vue de consultation", {
  # Donnee a caractere personnel : elle reste dans le payload pour qui en a
  # besoin, mais la vue courante ne la diffuse pas.
  con <- base_compta()
  foret <- foret_creer(con, "Foret test", "domanial")
  ecrire(con, foret, "bois_sur_pied", 2026, 5000, tiers = "Scierie Dupont")

  vue <- DBI::dbGetQuery(
    con, "SELECT * FROM v_comptabilite WHERE foret_id = $1", params = list(foret)
  )
  expect_false("tiers" %in% names(vue))
  brut <- DBI::dbGetQuery(
    con,
    "SELECT payload->>'tiers' AS tiers FROM entree_sommier WHERE foret_id = $1",
    params = list(foret)
  )
  expect_equal(brut$tiers, "Scierie Dupont")
})
