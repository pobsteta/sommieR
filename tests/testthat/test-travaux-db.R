# Placettes et controles en base : les refus, et ce que les vues calculent.

base_travaux <- function(env = parent.frame()) {
  con <- sauter_sans_base()
  withr::defer(DBI::dbDisconnect(con), envir = env)
  sommier_init_schema(con)
  con
}

# Deux unites, une plantation 2022 dans la premiere.
foret_travaux <- function(con) {
  foret <- foret_creer(con, paste0("Foret travaux-", substr(uuid_v4(), 1L, 8L)),
                       "communal")
  ug <- c(a = ug_creer(con, foret, "35", "2010-01-01"),
          b = ug_creer(con, foret, "12", "2010-01-01"))
  ecrire <- function(payload, date, unite) {
    sommier_ajouter(con, sommier_entree(
      foret_id = foret, registre = 6L, date_evenement = date,
      auteur = "agent-01", ug_uuid = unite, payload = payload
    ))[[1L]]$id
  }
  plantation <- ecrire(registre6_travaux(
    2022, "plantation", nb_plants = 1050, quantite = 1.75, unite = "ha",
    code_travaux = "PL", prevu = "prevu"
  ), "2022-11-08", ug[["a"]])
  ancienne <- ecrire(registre6_travaux(2020, "degagement", quantite = 1,
                                       unite = "ha"), "2020-06-01", ug[["b"]])
  list(foret = foret, ug = ug, plantation = plantation, ancienne = ancienne)
}

test_that("une placette suit des travaux de sa foret et de son unite", {
  con <- base_travaux()
  f <- foret_travaux(con)
  p <- sommier_installer_placette(con, f$plantation, "P35-01",
                                  geom_point(4.93, 47.26), "agent-01",
                                  date_evenement = "2022-12-02")[[1L]]
  expect_equal(p$ug_uuid, f$ug[["a"]])
  expect_equal(p$registre, 6L)
  expect_error(sommier_installer_placette(con, f$plantation, "P35-01",
                                          geom_point(4.93, 47.26), "agent-01"),
               "deja pris")
  expect_error(sommier_installer_placette(con, uuid_v4(), "P35-02",
                                          geom_point(4.93, 47.26), "agent-01"),
               "pas une intervention")
  # Une placette n'est pas un travail : elle ne peut pas en suivre une autre.
  expect_error(sommier_installer_placette(con, p$id, "P35-03",
                                          geom_point(4.93, 47.26), "agent-01"),
               "pas une intervention")
})

test_that("un controle se calcule, et ne se double pas le meme jour", {
  con <- base_travaux()
  f <- foret_travaux(con)
  p <- sommier_installer_placette(con, f$plantation, "P35-01",
                                  geom_point(4.93, 47.26), "agent-01",
                                  date_evenement = "2022-12-02")[[1L]]
  sommier_controler_placette(con, p$id, 20, 17, "agent-01",
                             visite_le = "2023-06-11T09:30:00Z",
                             h_moy_cm = 38, nb_abroutis = 3, besoin = "DG")
  sommier_controler_placette(con, p$id, 20, 16, "agent-01",
                             visite_le = "2025-06-11T09:30:00Z",
                             h_moy_cm = 92, nb_abroutis = 1, besoin = "aucun")
  expect_error(sommier_controler_placette(con, p$id, 20, 15, "agent-01",
                                          visite_le = "2025-06-11T15:00:00Z"),
               "deja ete controlee")
  expect_error(sommier_controler_placette(con, uuid_v4(), 20, 15, "agent-01"),
               "Placette inconnue")
  expect_error(sommier_controler_placette(con, f$plantation, 20, 15,
                                          "agent-01"),
               "Placette inconnue")

  k <- DBI::dbGetQuery(con, "
    SELECT age_ans, taux_reprise_pct::float8 AS taux,
           densite_ha::float8 AS densite, abroutis_pct::float8 AS abroutis,
           code_placette, besoin
      FROM v_controle_plantation WHERE placette_id = $1 ORDER BY visite_le",
    params = list(p$id))
  expect_equal(k$age_ans, c(1L, 3L))
  expect_equal(k$taux, c(85, 80))
  # 17 vivants sur 50 m2 (pi x 3,99^2) : 3 399 tiges/ha.
  expect_equal(k$densite, c(round(17 * 1e4 / (pi * 3.99^2)),
                            round(16 * 1e4 / (pi * 3.99^2))))
  # PostgreSQL arrondit 6,25 a 6,3 ; round() de R arrondirait au pair.
  expect_equal(k$abroutis, c(17.6, 6.3))
  expect_equal(k$besoin, c("DG", "aucun"))
  expect_true(sommier_verifier(con, f$foret)$valide)
})

test_that("v_travaux ne compte que les interventions, anciennes comprises", {
  con <- base_travaux()
  f <- foret_travaux(con)
  p <- sommier_installer_placette(con, f$plantation, "P35-01",
                                  geom_point(4.93, 47.26), "agent-01")[[1L]]
  sommier_controler_placette(con, p$id, 20, 17, "agent-01")
  t <- DBI::dbGetQuery(con, "
    SELECT id::text AS id, code_travaux, prevu FROM v_travaux
     WHERE foret_id = $1 ORDER BY annee", params = list(f$foret))
  expect_equal(t$id, c(f$ancienne, f$plantation))
  expect_equal(t$code_travaux, c(NA, "PL"))
  pl <- DBI::dbGetQuery(con, "
    SELECT code_placette, annee_travaux, code_travaux FROM v_placette
     WHERE foret_id = $1", params = list(f$foret))
  expect_equal(pl$annee_travaux, 2022L)
  expect_equal(pl$code_travaux, "PL")
  # Le bilan ne compte pas la placette ni le controle parmi les travaux.
  ga <- sommier_gestion_anterieure(con, f$foret)
  expect_equal(sum(ga$sections$travaux$n), 2)
})

test_that("le suivi rend la reprise par age, et ce qu'il reste a programmer", {
  con <- base_travaux()
  f <- foret_travaux(con)
  ids <- vapply(1:2, function(i) {
    sommier_installer_placette(con, f$plantation, sprintf("P35-0%d", i),
                               geom_point(4.93, 47.26), "agent-01",
                               date_evenement = "2022-12-02")[[1L]]$id
  }, character(1))
  sommier_controler_placette(con, ids[[1L]], 20, 14, "agent-01",
                             visite_le = "2023-06-11T09:00:00Z", besoin = "RG")
  sommier_controler_placette(con, ids[[2L]], 20, 16, "agent-01",
                             visite_le = "2023-06-12T09:00:00Z", besoin = "DG")
  sommier_controler_placette(con, ids[[1L]], 20, 18, "agent-01",
                             visite_le = "2025-06-11T09:00:00Z",
                             besoin = "aucun")

  s <- sommier_suivi_plantations(con, f$foret)
  expect_equal(s$age_ans, c(1L, 3L))
  expect_equal(s$n_placettes, c(2L, 1L))
  # n+1 : 70 % et 80 %, soit 75 % en moyenne ; RG et DG signales.
  expect_equal(s$taux_reprise_pct, c(75, 90))
  expect_equal(s$besoins, c("DG, RG", NA))

  # La premiere placette n'a plus de besoin a son dernier controle ; la
  # seconde garde le sien.
  a <- placettes_a_programmer(con, f$foret)
  expect_equal(a$code_placette, "P35-02")
  expect_equal(a$besoin, "DG")

  i <- sommier_indicateurs_ug(con, f$foret)
  # Dernier controle de chaque placette : 90 % et 80 %.
  expect_equal(i$dernier_taux_reprise_pct[i$uuid == f$ug[["a"]]], 85)
  expect_true(is.na(i$dernier_taux_reprise_pct[i$uuid == f$ug[["b"]]]))
})

test_that("le bilan des travaux range par famille et par ecart au prevu", {
  con <- base_travaux()
  f <- foret_travaux(con)
  DBI::dbExecute(con,
    "INSERT INTO ug_geometrie (ug_uuid, version, geom, source, date_debut)
     VALUES ($1, 1, ST_Multi(ST_GeomFromText('POLYGON((600000 6700000,
       600200 6700000, 600200 6700100, 600000 6700100, 600000 6700000))',
       2154)), 'test', '2010-01-01')", params = list(f$ug[["a"]]))
  ecrire <- function(payload, date, unite = NULL) {
    sommier_ajouter(con, sommier_entree(
      foret_id = f$foret, registre = 6L, date_evenement = date,
      auteur = "agent-01", ug_uuid = unite, payload = payload))
  }
  ecrire(registre6_travaux(2023, "degagement", code_travaux = "DG",
                           quantite = 1.5, unite = "ha", montant_eur = 600,
                           prevu = "non_prevu", motif_ecart = "Ronce"),
         "2023-06-01", f$ug[["a"]])
  ecrire(registre6_travaux(2023, "cloture", code_travaux = "PG", quantite = 300,
                           unite = "m", montant_eur = 1800, prevu = "prevu"),
         "2023-09-01", f$ug[["a"]])
  ecrire(registre6_travaux(2023, "fosses", code_travaux = "DS", quantite = 100,
                           unite = "m", montant_eur = 500, prevu = "prevu"),
         "2023-10-01")

  b <- sommier_bilan_travaux(con, f$foret, "2023-01-01", "2023-12-31")
  cout <- b$cout[b$cout$ug == "35", ]
  expect_equal(sort(cout$famille), c("education", "protection"))
  # L'unite fait 2 ha : 600 EUR de degagement, soit 300 EUR/ha.
  expect_equal(cout$cout_ha_eur[cout$famille == "education"], 300)
  expect_equal(b$hors_ug_eur, 500)
  p <- b$prevu
  expect_equal(p$hectares[p$prevu == "non_prevu"], 1.5)
  # Cloture et fosses en metres : prevus, sans hectare.
  expect_equal(p$n_sans_hectares[p$prevu == "prevu"], 2L)
  # Hors periode, rien.
  vide <- sommier_bilan_travaux(con, f$foret, "2030-01-01", "2030-12-31")
  expect_equal(nrow(vide$cout), 0L)

  i <- sommier_indicateurs_ug(con, f$foret)
  # 2 400 EUR dans l'unite a sa plantation pres (sans montant) : 1 200 EUR/ha.
  expect_equal(i$cout_travaux_ha[i$uuid == f$ug[["a"]]], 1200)
})
