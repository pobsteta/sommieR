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
