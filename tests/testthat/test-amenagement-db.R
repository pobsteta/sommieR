# L'amenagement comme objet : la possibilite dans la chaine, et la balance
# qui en decoule.

base_amenagement <- function(env = parent.frame()) {
  con <- sauter_sans_base()
  withr::defer(DBI::dbDisconnect(con), envir = env)
  sommier_init_schema(con)
  con
}

marteler <- function(con, foret, annee, volume, type = "martelage") {
  sommier_ajouter(con, sommier_entree(
    foret_id = foret, registre = 5L, date_evenement = paste0(annee, "-03-01"),
    auteur = "agent-01",
    payload = registre5_coupe(type, annee, "amelioration", volume)
  ))
}

test_that("le bloc amenagement se valide avant d'entrer dans la chaine", {
  bloc <- valider_amenagement(list(
    id = "FD-TEST", annee_debut = 2026, annee_fin = 2045,
    possibilite_m3_an = 2400, ventilation = c(regeneration = 1700,
                                              amelioration = 700)
  ), "arrete")
  expect_equal(bloc$nature_volume, "possibilite")
  expect_equal(bloc$ventilation$regeneration, 1700)
  expect_error(valider_amenagement(list(id = "x", annee_debut = 2030,
                                        annee_fin = 2020,
                                        possibilite_m3_an = 1), "arrete"),
               "avant de commencer")
  expect_error(valider_amenagement(list(id = "x", annee_debut = 2026,
                                        annee_fin = 2045), "arrete"),
               "possibilite_m3_an")
  expect_error(valider_amenagement(list(
    id = "x", annee_debut = 2026, annee_fin = 2045, possibilite_m3_an = 2400,
    ventilation = c(regeneration = 1700, amelioration = 600)
  ), "arrete"), "ne totalise pas")
  # Un avenant change la possibilite, la fin, ou les deux - pas rien.
  expect_error(valider_amenagement(list(id = "x", a_partir_de = 2030),
                                   "avenant"), "ne peuvent manquer ensemble")
  # Seuls l'arrete, l'agrement et l'avenant portent un amenagement.
  expect_error(registre1_validation("deliberation", "commune", "Maire",
                                    amenagement = list(id = "x")),
               "arrete, un agrement ou un avenant")
  expect_equal(SOMMIER_SCHEMA_VERSIONS[["1"]], "r1-1.2.0")
})

test_that("la balance se calcule contre l'amenagement, et l'acte est cite", {
  con <- base_amenagement()
  foret <- foret_creer(con, "Foret amenagee", "domanial")
  amenager(con, foret, 2024, 2025, 100, reference = "Arrete du 2 janvier 2024")
  marteler(con, foret, 2024, 120)
  marteler(con, foret, 2025, 60)

  bal <- sommier_balance_possibilite(con, foret)
  expect_equal(bal$exercice, c(2024, 2025))
  expect_equal(bal$balance_cumulee_m3, c(20, -20))
  expect_equal(unique(bal$reference_acte), "Arrete du 2 janvier 2024")
  expect_true(sommier_verifier(con, foret)$valide)
})

test_that("deux amenagements ne se chevauchent pas", {
  con <- base_amenagement()
  foret <- foret_creer(con, "Foret amenagee", "domanial")
  amenager(con, foret, 2016, 2025, 100)
  expect_error(amenager(con, foret, 2025, 2034, 90), "TEST-2016-2025")
  expect_error(amenager(con, foret, 2016, 2025, 100), "existe deja")
})

test_that("le cumul repart de zero avec l'amenagement suivant", {
  con <- base_amenagement()
  foret <- foret_creer(con, "Foret amenagee", "domanial")
  amenager(con, foret, 2020, 2021, 100)
  amenager(con, foret, 2022, 2023, 50)
  marteler(con, foret, 2020, 150)
  marteler(con, foret, 2021, 150)
  marteler(con, foret, 2022, 40)
  bal <- sommier_balance_possibilite(con, foret)
  expect_equal(bal$balance_cumulee_m3, c(50, 100, -10, -60))
  expect_equal(bal$amenagement_id,
               rep(c("TEST-2020-2021", "TEST-2022-2023"), each = 2L))
})

test_that("un avenant change la possibilite a partir d'un exercice", {
  con <- base_amenagement()
  foret <- foret_creer(con, "Foret amenagee", "domanial")
  amenager(con, foret, 2020, 2023, 100)
  sommier_avenant_possibilite(con, foret, "TEST-2020-2023", a_partir_de = 2022,
                              autorite = "onf", nom_qualite = "Agent",
                              date_acte = "2022-01-10", auteur = "agent-01",
                              reference = "Avenant n 1",
                              possibilite_m3_an = 80)
  bal <- sommier_balance_possibilite(con, foret)
  # Le passe garde sa possibilite ; l'avenant vaut desormais, et il est cite.
  expect_equal(bal$possibilite_m3_an, c(100, 100, 80, 80))
  expect_equal(bal$par_avenant, c(FALSE, FALSE, TRUE, TRUE))
  expect_equal(bal$reference_acte[[3L]], "Avenant n 1")

  # Un avenant hors periode, ou a un amenagement inconnu, est refuse.
  expect_error(sommier_avenant_possibilite(
    con, foret, "TEST-2020-2023", a_partir_de = 2030, autorite = "onf",
    nom_qualite = "Agent", date_acte = "2030-01-10", auteur = "agent-01",
    possibilite_m3_an = 70), "hors de")
  expect_error(sommier_avenant_possibilite(
    con, foret, "INCONNU", a_partir_de = 2021, autorite = "onf",
    nom_qualite = "Agent", date_acte = "2021-01-10", auteur = "agent-01",
    possibilite_m3_an = 70), "inconnu")
})

test_that("un avenant qui avance la fin permet l'amenagement suivant", {
  con <- base_amenagement()
  foret <- foret_creer(con, "Foret amenagee", "domanial")
  amenager(con, foret, 2016, 2035, 100)
  expect_error(amenager(con, foret, 2026, 2045, 90), "Clore d'abord")
  sommier_avenant_possibilite(con, foret, "TEST-2016-2035", a_partir_de = 2026,
                              autorite = "ministre", nom_qualite = "Ministre",
                              date_acte = "2025-12-01", auteur = "agent-01",
                              annee_fin = 2025)
  amenager(con, foret, 2026, 2045, 90)
  amenagements <- DBI::dbGetQuery(
    con, "SELECT amenagement_id, annee_fin FROM v_amenagement
           WHERE foret_id = $1 ORDER BY annee_debut", params = list(foret))
  expect_equal(amenagements$annee_fin, c(2025L, 2045L))
})

test_that("un martelage hors amenagement est montre a part, pas perdu", {
  con <- base_amenagement()
  foret <- foret_creer(con, "Foret amenagee", "domanial")
  amenager(con, foret, 2024, 2025, 100)
  marteler(con, foret, 2019, 75)
  expect_false(2019 %in% sommier_balance_possibilite(con, foret)$exercice)
  hors <- sommier_martelages_hors_amenagement(con, foret)
  expect_equal(hors$exercice, 2019)
  expect_equal(as.numeric(hors$volume_m3), 75)
})

test_that("une recolte prevue se distingue d'une possibilite", {
  # L'arrete du massif de Lorris-Les Bordes (2019) fixe des surfaces par
  # groupe ; le volume n'est qu'au document, comme recolte previsible.
  con <- base_amenagement()
  foret <- foret_creer(con, "Foret amenagee", "domanial")
  amenager(con, foret, 2019, 2020, 37215, nature_volume = "recolte_prevue",
           groupes = c(regeneration = 2648.31, amelioration = 3016.81),
           surface_regeneration_ha = 2026.57)
  bal <- sommier_balance_possibilite(con, foret)
  expect_equal(unique(bal$nature_volume), "recolte_prevue")
  groupes <- DBI::dbGetQuery(
    con, "SELECT groupes::text AS g, surface_regeneration_ha FROM v_amenagement
           WHERE foret_id = $1", params = list(foret))
  expect_match(groupes$g, "2648.31", fixed = TRUE)
  expect_equal(as.numeric(groupes$surface_regeneration_ha), 2026.57)
  expect_error(amenager(con, foret, 2021, 2022, 1, nature_volume = "estimee"),
               "nature_volume")
})

test_that("la vraisemblance avertit sans refuser", {
  con <- base_amenagement()
  foret <- foret_creer(con, "Foret amenagee", "communal")
  # 820 m3/an sur 16,4 ha : 50 m3/ha/an, dix fois un prelevement de 5.
  expect_warning(
    amenager(con, foret, 2016, 2035, 820, surface_ha = 16.4,
             reference_m3_ha_an = 5),
    "un zero de trop"
  )
  # L'acte est ecrit quand meme.
  expect_equal(nrow(sommier_balance_possibilite(con, foret)) > 0L, TRUE)
  foret2 <- foret_creer(con, "Foret amenagee 2", "communal")
  expect_silent(amenager(con, foret2, 2016, 2035, 82, surface_ha = 16.4,
                         reference_m3_ha_an = 5))
})

test_that("la table exercice se reprend, et ne s'ecrit plus ensuite", {
  con <- base_amenagement()
  foret <- foret_creer(con, "Foret ancienne", "communal")
  expect_warning(exercice_definir(con, foret, 2020, 100), "obsolete")
  suppressWarnings({
    exercice_definir(con, foret, 2021, 100)
    exercice_definir(con, foret, 2022, 80)
  })
  # La balance ne lit plus la table.
  expect_equal(nrow(sommier_balance_possibilite(con, foret)), 0L)

  sommier_reprendre_exercices(con, foret, auteur = "agent-01")
  amenagements <- DBI::dbGetQuery(
    con, "SELECT amenagement_id, annee_debut, annee_fin,
                 possibilite_initiale_m3_an AS p, repris
            FROM v_amenagement WHERE foret_id = $1 ORDER BY annee_debut",
    params = list(foret))
  expect_equal(amenagements$amenagement_id,
               c("REPRISE-EXERCICES-2020-2021", "REPRISE-EXERCICES-2022-2022"))
  expect_equal(as.numeric(amenagements$p), c(100, 80))
  expect_true(all(amenagements$repris))
  expect_equal(sommier_balance_possibilite(con, foret)$possibilite_m3_an,
               c(100, 100, 80))

  # Apres reprise, la table ne fixe plus rien.
  expect_error(exercice_definir(con, foret, 2023, 500), "par avenant")
  expect_error(sommier_reprendre_exercices(con, foret, auteur = "agent-01"),
               "deja un amenagement")
  expect_true(sommier_verifier(con, foret)$valide)
})
