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
    possibilite_m3_ha_an = 4.4, surface_ha = 535.2,
    ventilation = c(regeneration = 3.1, amelioration = 1.3)
  ), "arrete")
  expect_equal(bloc$nature_volume, "possibilite")
  expect_equal(bloc$ventilation$regeneration, 3.1)
  expect_error(valider_amenagement(list(id = "x", annee_debut = 2030,
                                        annee_fin = 2020,
                                        possibilite_m3_ha_an = 1,
                                        surface_ha = 1), "arrete"),
               "avant de commencer")
  expect_error(valider_amenagement(list(id = "x", annee_debut = 2026,
                                        annee_fin = 2045, surface_ha = 10),
                                   "arrete"), "possibilite_m3_ha_an")
  # La possibilite est a l'hectare : sans surface, pas de volume annuel.
  expect_error(valider_amenagement(list(id = "x", annee_debut = 2026,
                                        annee_fin = 2045,
                                        possibilite_m3_ha_an = 4),
                                   "arrete"), "surface_ha")
  expect_error(valider_amenagement(list(
    id = "x", annee_debut = 2026, annee_fin = 2045, possibilite_m3_ha_an = 4.4,
    surface_ha = 10, ventilation = c(regeneration = 3, amelioration = 1)
  ), "arrete"), "ne totalise pas")
  # Un avenant change la possibilite, la surface ou la fin - pas rien.
  expect_error(valider_amenagement(list(id = "x", a_partir_de = 2030),
                                   "avenant"), "ne peuvent")
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
  # 1 m3/ha/an sur 100 ha : 100 m3/an, et le martele ramene a l'hectare.
  expect_equal(bal$possibilite_m3_ha_an, c(1, 1))
  expect_equal(bal$possibilite_m3_an, c(100, 100))
  expect_equal(bal$prelevement_m3_ha, c(1.2, 0.6))
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
                              possibilite_m3_ha_an = 0.8)
  bal <- sommier_balance_possibilite(con, foret)
  # Le passe garde sa possibilite ; l'avenant vaut desormais, et il est cite.
  expect_equal(bal$possibilite_m3_an, c(100, 100, 80, 80))
  expect_equal(bal$par_avenant, c(FALSE, FALSE, TRUE, TRUE))
  expect_equal(bal$reference_acte[[3L]], "Avenant n 1")

  # Un avenant hors periode, ou a un amenagement inconnu, est refuse.
  expect_error(sommier_avenant_possibilite(
    con, foret, "TEST-2020-2023", a_partir_de = 2030, autorite = "onf",
    nom_qualite = "Agent", date_acte = "2030-01-10", auteur = "agent-01",
    possibilite_m3_ha_an = 0.7), "hors de")
  expect_error(sommier_avenant_possibilite(
    con, foret, "INCONNU", a_partir_de = 2021, autorite = "onf",
    nom_qualite = "Agent", date_acte = "2021-01-10", auteur = "agent-01",
    possibilite_m3_ha_an = 0.7), "inconnu")
})

test_that("un avenant de surface change le volume sans changer le taux", {
  # Une distraction de 20 ha : le taux reste, le volume annuel suit.
  con <- base_amenagement()
  foret <- foret_creer(con, "Foret amenagee", "domanial")
  amenager(con, foret, 2020, 2021, 400)
  sommier_avenant_possibilite(con, foret, "TEST-2020-2021", a_partir_de = 2021,
                              autorite = "prefet", nom_qualite = "Prefet",
                              date_acte = "2021-01-10", auteur = "agent-01",
                              surface_ha = 80)
  bal <- sommier_balance_possibilite(con, foret)
  expect_equal(bal$possibilite_m3_ha_an, c(4, 4))
  expect_equal(bal$surface_ha, c(100, 80))
  expect_equal(bal$possibilite_m3_an, c(400, 320))
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
  amenager(con, foret, 2019, 2020, 440, nature_volume = "recolte_prevue",
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
  # 50 m3/ha/an saisis au lieu de 5 : dix fois le prelevement de reference.
  expect_warning(
    amenager(con, foret, 2016, 2035, 5000, reference_m3_ha_an = 5),
    "un zero de trop"
  )
  # L'acte est ecrit quand meme.
  expect_equal(nrow(sommier_balance_possibilite(con, foret)) > 0L, TRUE)
  foret2 <- foret_creer(con, "Foret amenagee 2", "communal")
  expect_silent(amenager(con, foret2, 2016, 2035, 500,
                         reference_m3_ha_an = 5))
})

test_that("la table exercice se reprend, et ne s'ecrit plus ensuite", {
  con <- base_amenagement()
  foret <- foret_creer(con, "Foret ancienne", "communal", surface_ha = 50)
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
                 possibilite_initiale_m3_an AS p,
                 possibilite_initiale_m3_ha_an AS taux, repris
            FROM v_amenagement WHERE foret_id = $1 ORDER BY annee_debut",
    params = list(foret))
  expect_equal(amenagements$amenagement_id,
               c("REPRISE-EXERCICES-2020-2021", "REPRISE-EXERCICES-2022-2022"))
  expect_equal(as.numeric(amenagements$p), c(100, 80))
  # Ramenee a l'hectare sur la surface de la foret : 100 m3/an sur 50 ha.
  expect_equal(as.numeric(amenagements$taux), c(2, 1.6))
  expect_true(all(amenagements$repris))
  expect_equal(sommier_balance_possibilite(con, foret)$possibilite_m3_an,
               c(100, 100, 80))

  # Apres reprise, la table ne fixe plus rien.
  expect_error(exercice_definir(con, foret, 2023, 500), "par avenant")
  expect_error(sommier_reprendre_exercices(con, foret, auteur = "agent-01"),
               "deja un amenagement")
  expect_true(sommier_verifier(con, foret)$valide)
})

test_that("un martelage parcourt par defaut toute son unite", {
  con <- base_amenagement()
  foret <- foret_creer(con, "Foret amenagee", "domanial")
  ug <- ug_creer(con, foret, "12", "2010-01-01")
  # Un carre de 200 m de cote : 4 ha.
  DBI::dbExecute(con, paste0(
    "INSERT INTO ug_geometrie (ug_uuid, version, geom, source, date_debut) ",
    "VALUES ($1, 1, ST_Multi(ST_GeomFromText('POLYGON((600000 6700000, ",
    "600200 6700000, 600200 6700200, 600000 6700200, 600000 6700000))', ",
    "2154)), 'test', '2010-01-01')"), params = list(ug))
  ecrire <- function(type, surface = NULL) {
    sommier_ajouter(con, sommier_entree(
      foret_id = foret, registre = 5L, date_evenement = "2024-03-01",
      auteur = "agent-01", ug_uuid = ug,
      payload = registre5_coupe(type, 2024, "amelioration", 100,
                                surface_ha = surface)
    ))
  }
  ecrire("martelage")
  ecrire("martelage", surface = 1.5)
  ecrire("coupe_realisee")
  coupes <- DBI::dbGetQuery(
    con, "SELECT type_entree, surface_ha, surface_source FROM v_coupe
           WHERE foret_id = $1 ORDER BY seq", params = list(foret))
  expect_equal(as.numeric(coupes$surface_ha), c(4, 1.5, NA))
  expect_equal(coupes$surface_source, c("unite", "saisie", NA))
  # La surface deduite n'entre pas dans la chaine.
  payload <- DBI::dbGetQuery(
    con, "SELECT payload ? 'surface_ha' AS a FROM entree_sommier
           WHERE foret_id = $1 ORDER BY seq LIMIT 1", params = list(foret))
  expect_false(payload$a)
})

test_that("la balance en surface suit la regeneration ouverte", {
  con <- base_amenagement()
  foret <- foret_creer(con, "Foret regeneree", "domanial")
  carre <- function(x0) sprintf(paste0(
    "ST_Multi(ST_GeomFromText('POLYGON((%1$d 6700000, %2$d 6700000, ",
    "%2$d 6700200, %1$d 6700200, %1$d 6700000))', 2154))"), x0, x0 + 200)
  unites <- c(A = ug_creer(con, foret, "A", "2010-01-01"),
              B = ug_creer(con, foret, "B", "2010-01-01"))
  for (i in seq_along(unites)) {
    DBI::dbExecute(con, paste0(
      "INSERT INTO ug_geometrie (ug_uuid, version, geom, source, date_debut) ",
      "VALUES ($1, 1, ", carre(600000 + (i - 1L) * 300), ", 'test', ",
      "'2010-01-01')"), params = list(unites[[i]]))
  }
  # 20 ha a ouvrir sur 2020-2023 : 5 ha par an en rythme regulier.
  amenager(con, foret, 2020, 2023, 400, surface_regeneration_ha = 20)
  marteler_ug <- function(unite, annee, nature, surface = NULL) {
    sommier_ajouter(con, sommier_entree(
      foret_id = foret, registre = 5L, date_evenement = paste0(annee, "-10-01"),
      auteur = "agent-01", ug_uuid = unites[[unite]],
      payload = registre5_coupe("martelage", annee, nature, 100,
                                surface_ha = surface)
    ))
  }
  marteler_ug("A", 2020, "Coupe d'ensemencement")   # toute l'unite : 4 ha
  marteler_ug("A", 2021, "secondaire")              # deja ouverte : 0
  marteler_ug("B", 2022, "regeneration", 1.5)       # partielle : 1,5 ha
  marteler_ug("B", 2023, "amelioration")            # n'ouvre rien

  bs <- sommier_balance_surface(con, foret)
  expect_equal(bs$exercice, 2020:2023)
  expect_equal(bs$surface_prevue_ha, rep(5, 4))
  expect_equal(bs$surface_ouverte_ha, c(4, 0, 1.5, 0), tolerance = 1e-6)
  expect_equal(bs$ecart_cumule_ha, c(-1, -6, -9.5, -14.5), tolerance = 1e-6)

  # Un avenant revise la surface a regenerer de la periode.
  sommier_avenant_possibilite(con, foret, "TEST-2020-2023", a_partir_de = 2022,
                              autorite = "onf", nom_qualite = "Agent",
                              date_acte = "2022-01-10", auteur = "agent-01",
                              surface_regeneration_ha = 8)
  expect_equal(unique(sommier_balance_surface(con, foret)$surface_prevue_ha), 2)

  # Sans surface a regenerer, pas de balance en surface.
  foret2 <- foret_creer(con, "Foret sans surface", "domanial")
  amenager(con, foret2, 2020, 2023, 400)
  expect_equal(nrow(sommier_balance_surface(con, foret2)), 0L)

  expect_equal(normaliser_nature("Coupe d'Ensemencement"),
               "coupe_d_ensemencement")
})
