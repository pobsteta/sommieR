# Geometrie en base : colonne derivee, declencheur, vue, export.

base_geo <- function() {
  con <- sauter_sans_base()
  withr::defer(DBI::dbDisconnect(con), envir = parent.frame())
  sommier_init_schema(con)
  con
}

foret_geo <- function(con, nom = "Foret localisee") {
  foret_creer(con, paste0(nom, " ", substr(uuid_v4(), 1L, 8L)), "domanial")
}

test_that("la colonne derivee est posee par la base, en Lambert-93", {
  # Le calcul appartient a la base et non a l'application : une entree ecrite
  # par un autre client doit porter la meme geometrie derivee.
  con <- base_geo()
  foret <- foret_geo(con)
  ug <- ug_creer(con, foret, "1", "2010-01-01")
  sommier_ajouter(con, sommier_entree(
    foret_id = foret, registre = 9L, ug_uuid = ug,
    date_evenement = "2024-05-01", auteur = "a",
    payload = registre9_arbre("Chene", "CHS", "Age",
                              geometrie = geom_point(4.951, 47.271))
  ))

  pose <- DBI::dbGetQuery(
    con, "SELECT ST_SRID(geom) AS srid, ST_GeometryType(geom) AS type
            FROM entree_sommier WHERE foret_id = $1",
    params = parametres(list(foret))
  )
  expect_equal(pose$srid, 2154L)
  expect_equal(pose$type, "ST_Point")
})

test_that("une entree sans geometrie laisse la colonne vide", {
  con <- base_geo()
  foret <- foret_geo(con)
  sommier_ajouter(con, sommier_entree(
    foret_id = foret, registre = 4L, date_evenement = "2024-05-01",
    auteur = "a", payload = registre4_voirie("Piste", "empierree",
                                             longueur_m = 100)
  ))
  vide <- DBI::dbGetQuery(
    con, "SELECT geom IS NULL AS sans FROM entree_sommier WHERE foret_id = $1",
    params = parametres(list(foret))
  )
  expect_true(vide$sans)
  expect_equal(nrow(sommier_objets_localises(con, foret)), 0L)
})

test_that("la chaine reste verifiable, en base et hors ligne", {
  # L'enjeu du lot : la geometrie est dans le payload, donc dans l'empreinte.
  # Un aller-retour par la base et par le manifeste doit rendre la meme
  # empreinte de tete, ligne et polygone compris.
  con <- base_geo()
  foret <- foret_geo(con)
  ug <- ug_creer(con, foret, "1", "2010-01-01")
  sommier_ajouter(con, sommier_entree(
    foret_id = foret, registre = 4L, date_evenement = "2024-01-01",
    auteur = "a",
    payload = registre4_voirie(
      "Piste", "empierree", longueur_m = 620,
      geometrie = geom_ligne(rbind(c(4.950, 47.270), c(4.952, 47.271),
                                   c(4.954, 47.272)))
    )
  ))
  sommier_ajouter(con, sommier_entree(
    foret_id = foret, registre = 8L, ug_uuid = ug,
    date_evenement = "2024-02-01", auteur = "a",
    payload = registre8_phenomene(
      "tempete", "Coup de vent", surface_ha = 0.8,
      geometrie = geom_polygone(rbind(c(4.950, 47.270), c(4.952, 47.270),
                                      c(4.952, 47.272)))
    )
  ))

  en_base <- sommier_verifier(con, foret)
  expect_true(en_base$valide)

  chemin <- withr::local_tempfile(fileext = ".json")
  sommier_exporter_manifeste(con, foret, chemin)
  hors_ligne <- sommier_verifier_manifeste(chemin)
  expect_true(hors_ligne$valide)
  expect_equal(hors_ligne$hash_tete, en_base$hash_tete)
})

test_that("la vue des objets nomme tout ce qu'elle porte", {
  # Un trait sans etiquette sur une carte est pire qu'un nom approximatif.
  con <- base_geo()
  foret <- foret_geo(con)
  sommier_ajouter(con, sommier_entree(
    foret_id = foret, registre = 2L, date_evenement = "2017-09-14",
    auteur = "a",
    payload = registre2_foncier(
      "bornage", "Refection de la limite nord", nb_bornes = 6,
      geometrie = geom_ligne(rbind(c(4.950, 47.272), c(4.956, 47.272)))
    )
  ))
  objets <- sommier_objets_localises(con, foret)
  expect_equal(nrow(objets), 1L)
  expect_equal(objets$designation, "Refection de la limite nord")
  expect_equal(objets$type_objet, "bornage")
  expect_false(is.na(objets$wkt))
})

test_that("les objets se filtrent par registre et par periode", {
  con <- base_geo()
  foret <- foret_geo(con)
  ug <- ug_creer(con, foret, "1", "2010-01-01")
  sommier_ajouter(con, sommier_entree(
    foret_id = foret, registre = 9L, ug_uuid = ug,
    date_evenement = "2019-06-03", auteur = "a",
    payload = registre9_espece("Sabot de Venus", "Cypripedium calceolus",
                               geometrie = geom_point(4.9546, 47.2718))
  ))
  sommier_ajouter(con, sommier_entree(
    foret_id = foret, registre = 8L, ug_uuid = ug,
    date_evenement = "2024-02-01", auteur = "a",
    payload = registre8_phenomene(
      "tempete", "Coup de vent", surface_ha = 0.8,
      geometrie = geom_polygone(rbind(c(4.950, 47.270), c(4.952, 47.270),
                                      c(4.952, 47.272)))
    )
  ))

  expect_equal(nrow(sommier_objets_localises(con, foret, registres = 9L)), 1L)
  expect_equal(nrow(sommier_objets_localises(con, foret, registres = c(8L, 9L))), 2L)
  expect_equal(
    nrow(sommier_objets_localises(con, foret, debut = "2024-01-01",
                                  fin = "2024-12-31")), 1L
  )
})

test_that("une entree rectifiee sort de la carte sans sortir de la chaine", {
  # Une borne deplacee montre sa position actuelle ; l'ancienne reste chainee.
  con <- base_geo()
  foret <- foret_geo(con)
  # `sommier_ajouter()` rend la liste des entrees chainees, pas une entree.
  premiere <- sommier_ajouter(con, sommier_entree(
    foret_id = foret, registre = 2L, date_evenement = "2017-09-14",
    auteur = "a",
    payload = registre2_foncier("bornage", "Borne 12",
                                geometrie = geom_point(4.9500, 47.2720))
  ))
  sommier_ajouter(con, sommier_entree(
    foret_id = foret, registre = 2L, date_evenement = "2018-03-02",
    auteur = "a", corrige_id = premiere[[1L]]$id,
    payload = registre2_foncier("bornage", "Borne 12",
                                geometrie = geom_point(4.9505, 47.2721))
  ))

  objets <- sommier_objets_localises(con, foret)
  expect_equal(nrow(objets), 1L)
  expect_match(objets$wkt, "^POINT")
  # Les deux entrees restent dans la chaine.
  expect_equal(sommier_verifier(con, foret)$n_entrees, 2L)
})

test_that("l'export des objets rend une couche relisible", {
  con <- base_geo()
  foret <- foret_geo(con)
  sommier_ajouter(con, sommier_entree(
    foret_id = foret, registre = 4L, date_evenement = "2016-06-01",
    auteur = "a",
    payload = registre4_equipement("equipement", "Place de depot",
                                   nom = "PD-01",
                                   geometrie = geom_point(4.9518, 47.2706))
  ))

  chemin <- withr::local_tempfile(fileext = ".geojson")
  resultat <- sommier_exporter_sig(con, foret, chemin, couche = "objets")
  expect_equal(resultat$n_objets, 1L)

  lu <- jsonlite::fromJSON(chemin, simplifyVector = FALSE)
  expect_equal(lu$features[[1]]$properties$designation, "PD-01")
  # Le GeoJSON sort en WGS84, comme la couche des unites.
  coords <- unlist(lu$features[[1]]$geometry$coordinates)
  expect_equal(coords[[1]], 4.9518, tolerance = 1e-4)
  expect_equal(coords[[2]], 47.2706, tolerance = 1e-4)
})

test_that("un sommier sans objet localise refuse l'export plutot que de le vider", {
  con <- base_geo()
  foret <- foret_geo(con)
  sommier_ajouter(con, sommier_entree(
    foret_id = foret, registre = 4L, date_evenement = "2016-06-01",
    auteur = "a", payload = registre4_voirie("Piste", "empierree",
                                             longueur_m = 100)
  ))
  expect_error(
    sommier_exporter_sig(con, foret, withr::local_tempfile(fileext = ".geojson"),
                         couche = "objets"),
    "Aucune entree localisee"
  )
})

test_that("le jeu de demonstration porte des objets localises", {
  con <- base_geo()
  demo <- sommier_demo_couchey(con, suffixe = substr(uuid_v4(), 1L, 8L))
  objets <- sommier_objets_localises(con, demo$foret_id)
  expect_gte(nrow(objets), 13L)
  expect_setequal(sort(unique(objets$registre)), c(2L, 4L, 8L, 9L))
  expect_true(all(c("ST_Point", "ST_LineString", "ST_Polygon") %in%
                    objets$type_geometrie))
  expect_true(sommier_verifier(con, demo$foret_id)$valide)
})

test_that("les objets s'exportent aussi en GeoPackage", {
  # `sf` est installe sur le runner : ce chemin y est reellement exerce.
  skip_if_not_installed("sf")
  con <- base_geo()
  foret <- foret_geo(con)
  sommier_ajouter(con, sommier_entree(
    foret_id = foret, registre = 4L, date_evenement = "2016-06-01",
    auteur = "a",
    payload = registre4_voirie(
      "Piste", "empierree", longueur_m = 620,
      geometrie = geom_ligne(rbind(c(4.950, 47.270), c(4.952, 47.271)))
    )
  ))

  chemin <- withr::local_tempfile(fileext = ".gpkg")
  resultat <- sommier_exporter_sig(con, foret, chemin, format = "gpkg",
                                   couche = "objets")
  expect_equal(resultat$n_objets, 1L)

  relu <- sf::read_sf(chemin)
  expect_equal(relu$designation, "Piste")
  # Le GeoPackage porte son systeme : il reste en Lambert-93, ou les
  # longueurs se mesurent en metres.
  expect_equal(sf::st_crs(relu)$epsg, 2154L)
})
