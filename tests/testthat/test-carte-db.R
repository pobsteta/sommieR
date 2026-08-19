# Couche cartographique : geometries d'unites de gestion et indicateurs.

base_carte <- function() {
  con <- sauter_sans_base()
  withr::defer(DBI::dbDisconnect(con), envir = parent.frame())
  sommier_init_schema(con)
  con
}

# Carre de `cote_m` metres de cote, coin sud-ouest a l'origine Lambert-93.
carre <- function(cote_m, decalage = 0) {
  sprintf("POLYGON((%1$d %1$d, %2$d %1$d, %2$d %2$d, %1$d %2$d, %1$d %1$d))",
          decalage, decalage + cote_m)
}

poser_geometrie <- function(con, ug, wkt, version = 1L, debut = "2010-01-01",
                            fin = NA) {
  # `NULL` dans une liste de parametres la raccourcit au lieu d'y poser un
  # NULL : on passe donc NA, que le pilote traduit en NULL SQL.
  DBI::dbExecute(
    con,
    "INSERT INTO ug_geometrie (ug_uuid, version, geom, date_debut, date_fin)
     VALUES ($1, $2, ST_Multi(ST_GeomFromText($3, 2154)), $4::date, $5::date)",
    params = parametres(list(ug, version, wkt, debut, NA_character_))
  )
  if (!is.na(fin)) {
    DBI::dbExecute(
      con,
      "UPDATE ug_geometrie SET date_fin = $3::date
        WHERE ug_uuid = $1 AND version = $2",
      params = parametres(list(ug, version, fin))
    )
  }
}

test_that("la geometrie rendue est celle en vigueur a la date demandee", {
  # Le contour d'une unite change avec les revisions d'amenagement : une carte
  # editee pour une periode passee doit montrer le parcellaire de l'epoque.
  con <- base_carte()
  foret <- foret_creer(con, "Foret cartographiee", "domanial")
  ug <- ug_creer(con, foret, "1", "2010-01-01")
  poser_geometrie(con, ug, carre(100), version = 1L,
                  debut = "2010-01-01", fin = "2019-12-31")
  poser_geometrie(con, ug, carre(200), version = 2L, debut = "2020-01-01")

  ancienne <- sommier_geometrie_ug(con, foret, a_la_date = "2015-06-01")
  courante <- sommier_geometrie_ug(con, foret, a_la_date = "2025-06-01")

  expect_equal(nrow(ancienne), 1L)
  expect_equal(ancienne$surface_ha, 1)      # 100 m de cote = 1 ha
  expect_equal(courante$surface_ha, 4)      # 200 m de cote = 4 ha
})

test_that("une unite sans contour est rendue, avec un WKT absent", {
  # L'escamoter ici retirerait a l'appelant le choix de la signaler.
  con <- base_carte()
  foret <- foret_creer(con, "Foret partielle", "domanial")
  ug_creer(con, foret, "7", "2010-01-01")

  geo <- sommier_geometrie_ug(con, foret)
  expect_equal(nrow(geo), 1L)
  expect_true(is.na(geo$wkt))
  expect_true(is.na(geo$surface_ha))
})

test_that("une unite fermee sort de la couche a la date demandee", {
  con <- base_carte()
  foret <- foret_creer(con, "Foret remaniee", "domanial")
  ug <- ug_creer(con, foret, "3", "2010-01-01")
  poser_geometrie(con, ug, carre(100))
  DBI::dbExecute(con, "UPDATE ug SET date_fin = '2018-12-31' WHERE uuid = $1",
                 params = parametres(list(ug)))

  expect_equal(nrow(sommier_geometrie_ug(con, foret, "2015-01-01")), 1L)
  expect_equal(nrow(sommier_geometrie_ug(con, foret, "2020-01-01")), 0L)
})

test_that("les indicateurs comptent par unite, et zero n'est pas rien", {
  con <- base_carte()
  foret <- foret_creer(con, "Foret indicee", "communal", surface_ha = 50)
  exercice_definir(con, foret, 2024, 100)
  travaillee <- ug_creer(con, foret, "1", "2010-01-01")
  vierge <- ug_creer(con, foret, "2", "2010-01-01")

  ecrire <- function(registre, payload, date, unite) {
    sommier_ajouter(con, sommier_entree(
      foret_id = foret, registre = registre, date_evenement = date,
      auteur = "agent-01", ug_uuid = unite, payload = payload
    ))
  }
  ecrire(5L, registre5_coupe("martelage", 2024, "amelioration",
                             volume_m3 = 120, surface_ha = 2),
         "2024-03-01", travaillee)
  # La meme coupe, exploitee : deja comptee au martelage, elle ne doit pas
  # doubler le prelevement porte sur la carte.
  ecrire(5L, registre5_coupe("coupe_realisee", 2024, "amelioration",
                             volume_m3 = 118),
         "2024-09-01", travaillee)
  ecrire(6L, registre6_travaux(2024, "plantation", quantite = 2, unite = "ha",
                               montant_eur = 3000),
         "2024-04-01", travaillee)

  ind <- sommier_indicateurs_ug(con, foret, "2024-01-01", "2024-12-31")
  ind <- ind[order(ind$uuid == vierge), , drop = FALSE]
  travail <- ind[ind$uuid == travaillee, ]
  rien <- ind[ind$uuid == vierge, ]

  expect_equal(nrow(ind), 2L)
  expect_equal(as.numeric(travail$volume_martele_m3), 120)
  expect_equal(as.numeric(travail$surface_coupee_ha), 2)
  expect_equal(as.numeric(travail$montant_travaux_eur), 3000)
  expect_equal(as.numeric(travail$n_entrees), 3)
  # Une unite sans ecriture figure a zero : sur une choroplethe, elle doit se
  # teinter, non disparaitre.
  expect_equal(nrow(rien), 1L)
  expect_equal(as.numeric(rien$volume_martele_m3), 0)
  expect_equal(as.numeric(rien$n_entrees), 0)
})

test_that("les indicateurs se bornent a la periode", {
  con <- base_carte()
  foret <- foret_creer(con, "Foret bornee", "domanial")
  exercice_definir(con, foret, 2024, 100)
  ug <- ug_creer(con, foret, "1", "2010-01-01")
  sommier_ajouter(con, sommier_entree(
    foret_id = foret, registre = 5L, date_evenement = "2024-03-01",
    auteur = "a", ug_uuid = ug,
    payload = registre5_coupe("martelage", 2024, "amelioration", 90)
  ))

  dedans <- sommier_indicateurs_ug(con, foret, "2024-01-01", "2024-12-31")
  dehors <- sommier_indicateurs_ug(con, foret, "2025-01-01", "2025-12-31")
  expect_equal(as.numeric(dedans$volume_martele_m3), 90)
  expect_equal(as.numeric(dehors$volume_martele_m3), 0)

  expect_error(sommier_indicateurs_ug(con, foret, "2025-01-01", "2024-01-01"),
               "precede")
})

test_that("une ecriture hors unite de gestion n'est portee sur aucune carte", {
  # Imprime A50H : elle ne se localise nulle part, la compter ferait mentir la
  # carte sur ce qu'elle montre.
  con <- base_carte()
  foret <- foret_creer(con, "Foret hors unite", "communal")
  ug <- ug_creer(con, foret, "1", "2010-01-01")
  sommier_ajouter(con, sommier_entree(
    foret_id = foret, registre = 6L, date_evenement = "2024-08-01",
    auteur = "a", payload = registre6_travaux(2024, "entretien desserte",
                                              montant_eur = 900)
  ))

  ind <- sommier_indicateurs_ug(con, foret, "2024-01-01", "2024-12-31")
  expect_equal(nrow(ind), 1L)
  expect_equal(ind$uuid, ug)
  expect_equal(as.numeric(ind$montant_travaux_eur), 0)
})

test_that("la couche joint geometries et indicateurs, et signale les manques", {
  con <- base_carte()
  foret <- foret_creer(con, "Foret mixte", "communal")
  exercice_definir(con, foret, 2024, 100)
  cartographiee <- ug_creer(con, foret, "1", "2010-01-01")
  ug_creer(con, foret, "2", "2010-01-01")   # sans contour
  poser_geometrie(con, cartographiee, carre(100))
  sommier_ajouter(con, sommier_entree(
    foret_id = foret, registre = 5L, date_evenement = "2024-03-01",
    auteur = "a", ug_uuid = cartographiee,
    payload = registre5_coupe("martelage", 2024, "amelioration", 45)
  ))

  couche <- sommier_couche_ug(con, foret, "2024-01-01", "2024-12-31")
  expect_equal(nrow(couche), 1L)
  expect_equal(couche$numero_affichage, "1")
  expect_equal(as.numeric(couche$volume_martele_m3), 45)
  expect_match(couche$wkt, "^MULTIPOLYGON")
  # Ce que la carte omet doit se dire : sans cet attribut, elle laisserait
  # croire la foret entierement cartographiee.
  expect_equal(attr(couche, "unites_sans_geometrie"), "2")
})

test_that("la couche date les contours de la fin de periode, pas du jour", {
  # Une carte qui accompagne un bilan doit montrer le parcellaire de l'epoque.
  con <- base_carte()
  foret <- foret_creer(con, "Foret revisee", "domanial")
  ug <- ug_creer(con, foret, "1", "2010-01-01")
  poser_geometrie(con, ug, carre(100), version = 1L,
                  debut = "2010-01-01", fin = "2019-12-31")
  poser_geometrie(con, ug, carre(300), version = 2L, debut = "2020-01-01")

  ancienne <- sommier_couche_ug(con, foret, "2012-01-01", "2015-12-31")
  expect_equal(ancienne$surface_ha, 1)

  # `a_la_date` explicite l'emporte sur la borne de fin.
  forcee <- sommier_couche_ug(con, foret, "2012-01-01", "2015-12-31",
                              a_la_date = "2024-01-01")
  expect_equal(forcee$surface_ha, 9)
})
