# Geometrie de payload : construction, validation, et surtout stabilite des
# octets - c'est elle qui decide si le chainage reste reproductible.

test_that("les constructeurs rendent du GeoJSON canonique", {
  expect_equal(geom_point(4.951, 47.271),
               list(type = "Point", coordinates = c(4.951, 47.271)))

  ligne <- geom_ligne(rbind(c(4.95, 47.27), c(4.952, 47.271)))
  expect_equal(ligne$type, "LineString")
  expect_length(ligne$coordinates, 2L)

  poly <- geom_polygone(rbind(c(4.95, 47.27), c(4.952, 47.27), c(4.952, 47.272)))
  expect_equal(poly$type, "Polygon")
  # L'anneau est referme : quatre sommets pour un triangle.
  expect_length(poly$coordinates[[1L]], 4L)
  expect_equal(poly$coordinates[[1L]][[1L]], poly$coordinates[[1L]][[4L]])
})

test_that("un aller-retour JSON rend exactement les memes octets", {
  # C'est l'invariant du lot : `jsonlite` simplifie un tableau de tableaux en
  # matrice, et une matrice ne se serialise pas comme une liste de couples. Si
  # la relecture ne renormalisait pas, l'empreinte recalculee ne retomberait
  # pas sur celle du registre.
  geometries <- list(
    geom_point(4.951, 47.271),
    geom_ligne(rbind(c(4.95, 47.27), c(4.952, 47.271), c(4.954, 47.272))),
    geom_polygone(rbind(c(4.95, 47.27), c(4.952, 47.27), c(4.952, 47.272)))
  )
  for (g in geometries) {
    relu <- jsonlite::fromJSON(
      jsonlite::toJSON(g, auto_unbox = TRUE, digits = NA), simplifyVector = TRUE
    )
    expect_identical(jcs(list(g = valider_geometrie(relu))), jcs(list(g = g)),
                     info = g$type)
  }
})

test_that("les coordonnees sont arrondies, pour que deux saisies coincident", {
  # Sept decimales valent le centimetre ; au-dela, deux releves du meme point
  # differeraient sur du bruit d'instrument et briseraient la reproductibilite.
  a <- geom_point(4.95123456789, 47.27123456789)
  b <- geom_point(4.95123456123, 47.27123456999)
  expect_identical(jcs(a), jcs(b))
  expect_equal(a$coordinates, c(4.9512346, 47.2712346))
})

test_that("des coordonnees projetees sont refusees", {
  # Le cas le plus probable : du Lambert-93 passe tel quel. Sans ce refus, la
  # foret se retrouverait au large de l'Afrique sans que rien ne l'annonce.
  expect_error(geom_point(847490, 6687454), "longitude")
  expect_error(geom_point(4.95, 6687454), "latitude")
})

test_that("un anneau non ferme est refuse a la relecture, referme a la saisie", {
  ouvert <- list(
    type = "Polygon",
    coordinates = list(list(c(4.95, 47.27), c(4.952, 47.27), c(4.952, 47.272)))
  )
  expect_error(valider_geometrie(ouvert), "non ferme")
  expect_silent(geom_polygone(rbind(c(4.95, 47.27), c(4.952, 47.27),
                                    c(4.952, 47.272))))
})

test_that("le type admis depend de l'objet decrit", {
  # Un arbre est un point, une voirie une ligne : accepter n'importe quoi
  # ferait de la verification une politesse.
  expect_error(
    registre9_arbre("Chene", "CHS", "Age",
                    geometrie = geom_ligne(rbind(c(4.95, 47.27),
                                                 c(4.952, 47.271)))),
    "geometrie\\$type"
  )
  expect_error(
    registre4_voirie("Piste", "empierree", longueur_m = 100,
                     geometrie = geom_point(4.95, 47.27)),
    "geometrie\\$type"
  )
})

test_that("la geometrie reste facultative", {
  # Un gestionnaire sans releve doit pouvoir tenir un sommier conforme.
  sans <- registre9_arbre("Chene", "CHS", "Age")
  expect_null(sans$geometrie)
  expect_false("geometrie" %in% names(sans))
})

test_that("la geometrie entre dans l'empreinte", {
  # C'est tout l'objet du lot : le contour d'une coupe devient aussi opposable
  # que son volume.
  sans <- sommier_chainer(list(entree_test(
    payload = registre5_coupe("martelage", 2026, "amelioration",
                              volume_m3 = 100)
  )))
  avec <- sommier_chainer(list(entree_test(
    payload = registre5_coupe(
      "martelage", 2026, "amelioration", volume_m3 = 100,
      geometrie = geom_polygone(rbind(c(4.95, 47.27), c(4.952, 47.27),
                                      c(4.952, 47.272)))
    )
  )))
  expect_false(identical(sans[[1L]]$hash, avec[[1L]]$hash))
})

test_that("un payload geolocalise se revalide a l'identique", {
  # `valider_payload()` rappelle le constructeur sur le payload relu : si la
  # geometrie ne repassait pas par la meme normalisation, la relecture d'un
  # export echouerait ou changerait les octets.
  payload <- registre8_phenomene(
    "tempete", "Coup de vent", surface_ha = 0.8,
    geometrie = geom_polygone(rbind(c(4.95, 47.27), c(4.952, 47.27),
                                    c(4.952, 47.272)))
  )
  relu <- jsonlite::fromJSON(
    jsonlite::toJSON(payload, auto_unbox = TRUE, digits = NA),
    simplifyVector = TRUE
  )
  expect_identical(jcs(valider_payload(8L, relu)), jcs(payload))
})
