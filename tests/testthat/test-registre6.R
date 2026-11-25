# Registre 6 : l'intervention codee, la placette et le controle - sans base.

polygone <- function() {
  geom_polygone(rbind(c(4.95, 47.27), c(4.952, 47.27), c(4.952, 47.272)))
}

test_that("une intervention d'avant la v0.28.0 se relit a l'identique", {
  # Sans type ni code : c'est ainsi que sont chainees les interventions
  # anterieures, et leur relecture ne doit pas changer un octet.
  ancienne <- registre6_travaux(2022, "plantation", nb_plants = 1050,
                                quantite = 1.75, unite = "ha",
                                taux_reprise_pct = 78)
  expect_null(ancienne$type_entree)
  expect_identical(jcs(valider_payload(6L, ancienne)), jcs(ancienne))
  expect_equal(SOMMIER_SCHEMA_VERSIONS[["6"]], "r6-1.3.0")
})

test_that("une intervention codee, localisee, se relit a l'identique", {
  p <- registre6_travaux(2026, "plantation de chene", code_travaux = "PL",
                         quantite = 1.2, unite = "ha", prevu = "prevu",
                         execution = "entreprise", intervenant = "ETF Martin",
                         date_reception = "2026-12-02", geometrie = polygone())
  relu <- jsonlite::fromJSON(jsonlite::toJSON(p, auto_unbox = TRUE,
                                              digits = NA),
                             simplifyVector = TRUE)
  expect_identical(jcs(valider_payload(6L, relu)), jcs(p))
})

test_that("le code fixe l'unite et la forme", {
  expect_error(registre6_travaux(2026, "x", code_travaux = "ZZ"),
               "code_travaux")
  expect_error(registre6_travaux(2026, "plantation", code_travaux = "PL",
                                 quantite = 3, unite = "km"),
               "se mesurent en ha")
  # Une cloture se trace en ligne, pas en surface.
  expect_error(registre6_travaux(2026, "cloture", code_travaux = "PG",
                                 geometrie = polygone()),
               "LineString")
  expect_silent(registre6_travaux(
    2026, "cloture", code_travaux = "PG", quantite = 250, unite = "m",
    geometrie = geom_ligne(rbind(c(4.95, 47.27), c(4.952, 47.271)))
  ))
  formes <- unlist(strsplit(SOMMIER_CODES_TRAVAUX$formes, ",\\s*"))
  expect_true(all(formes %in% c("point", "ligne", "surface")))
  # Deux unites, deux formes admises : un cloisonnement en m ou en ha, un
  # regarni en surface ou en point.
  expect_silent(registre6_travaux(2026, "cloisonnement", code_travaux = "CL",
                                  quantite = 2, unite = "ha"))
  expect_silent(registre6_travaux(2026, "regarni", code_travaux = "RG",
                                  quantite = 40, unite = "plants",
                                  geometrie = geom_point(4.95, 47.27)))
  expect_error(registre6_travaux(2026, "cloisonnement", code_travaux = "CL",
                                 quantite = 2, unite = "plants"),
               "m ou ha")
  expect_false(anyDuplicated(SOMMIER_CODES_TRAVAUX$code) > 0L)
})

test_that("hors prevu, un motif est exige", {
  expect_error(registre6_travaux(2026, "x", prevu = "non_prevu"),
               "motif_ecart")
  expect_error(registre6_travaux(2026, "x", prevu = "reporte"),
               "motif_ecart")
  expect_silent(registre6_travaux(2026, "x", prevu = "non_prevu",
                                  motif_ecart = "Chablis"))
  expect_error(registre6_travaux(2026, "x", prevu = "peut-etre"), "prevu")
})

test_that("une placette a un centre, et se relit", {
  expect_error(registre6_placette("P1", uuid_v4(), NULL), "obligatoire")
  expect_error(registre6_placette("P1", uuid_v4(), polygone()), "Point")
  p <- registre6_placette("P35-01", uuid_v4(), geom_point(4.95, 47.27))
  expect_equal(p$type_entree, "placette")
  expect_equal(p$rayon_m, 3.99)
  expect_identical(valider_payload(6L, p), p)
})

test_that("un controle ne compte pas plus de vivants que de plants", {
  id <- uuid_v4()
  expect_error(registre6_controle(id, 10, 12), "Plus de plants vivants")
  expect_error(registre6_controle(id, 10, 8, nb_abroutis = 9), "abroutis")
  expect_error(registre6_controle(id, 10, 8, besoin = "ZZ"), "besoin")
  c1 <- registre6_controle(id, 20, 17, h_moy_cm = 45, nb_abroutis = 3,
                           concurrence = "forte", besoin = "DG",
                           visite_le = "2025-06-10T10:00:00Z")
  expect_equal(c1$type_entree, "controle")
  expect_identical(valider_payload(6L, c1), c1)
  # Le taux, la densite et la part d'abroutis ne s'inscrivent pas.
  expect_false(any(c("taux_reprise_pct", "densite_ha") %in% names(c1)))
})

test_that("un type inconnu est refuse a la relecture", {
  expect_error(valider_payload(6L, list(type_entree = "chantier", annee = 1)),
               "type_entree")
})

test_that("les trois niveaux de concurrence sont definis et ordonnes", {
  d <- SOMMIER_DEFINITIONS_CONCURRENCE
  expect_identical(d$niveau, SOMMIER_CONCURRENCES)
  expect_equal(d$part_plants_min_pct[-1], d$part_plants_max_pct[-3])
  expect_equal(d$part_plants_min_pct[1], 0)
  expect_true(is.infinite(d$part_plants_max_pct[3]))
})

test_that("la regle de passage du plant a la placette suit les seuils", {
  expect_identical(sommier_niveau_concurrence(0, 10), "faible")
  expect_identical(sommier_niveau_concurrence(1, 10), "faible")
  expect_identical(sommier_niveau_concurrence(2, 10), "moyenne")
  expect_identical(sommier_niveau_concurrence(4, 10), "moyenne")
  expect_identical(sommier_niveau_concurrence(5, 10), "forte")
  expect_identical(sommier_niveau_concurrence(10, 10), "forte")
  # sans plant vivant : jamais un niveau devine
  expect_identical(sommier_niveau_concurrence(0, 0), NA_character_)
  expect_error(sommier_niveau_concurrence(11, 10), "Plus de plants")
  # le niveau rendu est accepte par le controle
  c1 <- registre6_controle("11111111-1111-4111-8111-111111111111", 10, 10,
                           concurrence = sommier_niveau_concurrence(5, 10))
  expect_identical(c1$concurrence, "forte")
})

test_that("un seul critere decide : 60 % au contact, vegetation au pied -> forte", {
  # la position de la vegetation est descriptive : elle ne change pas le niveau
  expect_identical(sommier_niveau_concurrence(6, 10), "forte")
  expect_match(SOMMIER_DEFINITIONS_CONCURRENCE$critere_hauteur[1], "pied")
})

test_that("le comptage de la concurrence est conserve, facultatif, ajout seul", {
  id <- "11111111-1111-4111-8111-111111111111"
  sans <- registre6_controle(id, 10, 9, concurrence = "faible")
  expect_null(sans$nb_plants_vivants)
  expect_identical(jcs(registre6_depuis_payload(sans)), jcs(sans))
  c1 <- registre6_controle(id, 10, 9, concurrence = "forte",
                           nb_plants_vivants = 8, nb_plants_concurrences = 5)
  expect_equal(c1$nb_plants_vivants, 8)
  expect_equal(c1$nb_plants_concurrences, 5)
  expect_identical(jcs(registre6_depuis_payload(c1)), jcs(c1))
  expect_identical(
    sommier_niveau_concurrence(c1$nb_plants_concurrences,
                               c1$nb_plants_vivants), "forte")
  expect_error(registre6_controle(id, 10, 9, nb_plants_vivants = 10),
               "Plus de plants notes")
  expect_error(registre6_controle(id, 10, 9, nb_plants_vivants = 8,
                                  nb_plants_concurrences = 9),
               "Plus de plants au contact")
})

test_that("un comptage de plants au contact sans vivants notes est garde brut", {
  id <- "11111111-1111-4111-8111-111111111111"
  expect_warning(c1 <- registre6_controle(id, 10, 9, nb_plants_concurrences = 2),
                 "sans plants vivants notes")
  expect_equal(c1$nb_plants_concurrences, 2)
  expect_null(c1$nb_plants_vivants)
  expect_null(c1$concurrence)
  expect_null(c1$concurrence_calculee)
  # Avec un niveau saisi : rien a comparer, le comptage isole est signale.
  expect_warning(c2 <- registre6_controle(
    id, 10, 9, concurrence = "forte", nb_plants_concurrences = 2),
    "sans plants vivants notes")
  expect_equal(c2$concurrence, "forte")
  # Rejouable, et jusqu'a l'entree.
  expect_no_warning(rejoue <- registre6_depuis_payload(c1))
  expect_equal(rejoue, c1)
  e <- sommier_entree(foret_id = id, registre = 6L,
                      date_evenement = as.Date("2026-11-18"), auteur = "t",
                      ndp = 0L, payload = c1)
  expect_equal(e$payload$nb_plants_concurrences, 2)
})

test_that("la concurrence absente est deduite des comptages, la contradiction est acceptee et signalee", {
  id <- "11111111-1111-4111-8111-111111111111"
  # Absente : deduite (5 sur 8 = 62,5 % : forte).
  d <- registre6_controle(id, 10, 9, nb_plants_vivants = 8,
                          nb_plants_concurrences = 5)
  expect_equal(d$concurrence, "forte")
  expect_null(d$concurrence_calculee)
  # Saisie coherente : rien a signaler.
  expect_no_warning(c <- registre6_controle(
    id, 10, 9, concurrence = "forte", nb_plants_vivants = 8,
    nb_plants_concurrences = 5))
  expect_null(c$concurrence_calculee)
  # Saisie contredite : acceptee telle quelle, ecart signale et inscrit.
  expect_warning(
    x <- registre6_controle(id, 10, 9, concurrence = "faible",
                            nb_plants_vivants = 8, nb_plants_concurrences = 5),
    "saisie conservee")
  expect_equal(x$concurrence, "faible")
  expect_equal(x$concurrence_calculee, "forte")
  # La relecture du payload ecrit se rejoue, sans nouvel avertissement.
  expect_no_warning(r <- registre6_depuis_payload(x))
  expect_identical(jcs(r), jcs(x))
  # Un seul comptage (ou aucun) : rien n'est deduit, comme avant.
  expect_null(registre6_controle(id, 10, 9)$concurrence)
  expect_null(registre6_controle(id, 10, 9, nb_plants_vivants = 8)$concurrence)
})

test_that("0 plant vivant note sur 0 : aucun niveau a deduire, l'entree s'ecrit comme avant", {
  id <- "11111111-1111-4111-8111-111111111111"
  expect_no_warning(a <- registre6_controle(
    id, 10, 9, nb_plants_vivants = 0, nb_plants_concurrences = 0))
  expect_null(a$concurrence)
  expect_null(a$concurrence_calculee)
  expect_no_error(jcs(a))
  expect_no_warning(b <- registre6_controle(
    id, 10, 9, concurrence = "faible", nb_plants_vivants = 0,
    nb_plants_concurrences = 0))
  expect_equal(b$concurrence, "faible")
  expect_null(b$concurrence_calculee)
  expect_no_error(jcs(b))
  # Jusqu'a l'ecriture : l'entree se construit.
  e <- sommier_entree(foret_id = id, registre = 6L,
                      date_evenement = as.Date("2026-11-18"), auteur = "t",
                      ndp = 0L, payload = b)
  expect_equal(e$payload$nb_plants_vivants, 0)
})

# Mission 052 : la position mesuree du controle (brief surculus du 2026-10-22).
test_that("un controle porte sa position mesuree, sa precision et son rattachement", {
  id <- "11111111-1111-4111-8111-111111111111"
  x <- registre6_controle(id, 10, 9, geometrie = geom_point(4.9325, 47.2591),
                          precision_m = 0.4, rattache_par_identite = FALSE,
                          sans_position_mesuree = FALSE)
  expect_equal(x$geometrie$type, "Point")
  expect_equal(x$geometrie$coordinates, c(4.9325, 47.2591))
  expect_equal(x$precision_m, 0.4)
  expect_false(x$rattache_par_identite)
  expect_false(x$sans_position_mesuree)
  # Un controle francais tombe en France.
  expect_true(x$geometrie$coordinates[1] > -5.5 && x$geometrie$coordinates[1] < 10 &&
                x$geometrie$coordinates[2] > 41 && x$geometrie$coordinates[2] < 51.5)
  # Le rejeu du payload ecrit rend le meme payload.
  expect_identical(jcs(registre6_depuis_payload(x)), jcs(x))
  # Les noms sont ceux de Surculus.
  expect_true(all(c("geometrie", "precision_m", "rattache_par_identite",
                    "sans_position_mesuree") %in% names(x)))
})

test_that("un controle sans position mesuree n'a ni point ni precision, jamais (0, 0)", {
  id <- "11111111-1111-4111-8111-111111111111"
  x <- registre6_controle(id, 10, 9, sans_position_mesuree = TRUE,
                          rattache_par_identite = TRUE)
  expect_true(x$sans_position_mesuree)
  expect_true(x$rattache_par_identite)
  expect_false("geometrie" %in% names(x))
  expect_false("precision_m" %in% names(x))
  expect_error(registre6_controle(id, 10, 9, sans_position_mesuree = TRUE,
                                  geometrie = geom_point(0, 0)),
               "sans_position_mesuree.*geometrie")
  expect_error(registre6_controle(id, 10, 9, sans_position_mesuree = TRUE,
                                  precision_m = 3), "precision_m")
  expect_error(registre6_controle(id, 10, 9, precision_m = 3),
               "il faut une `geometrie`")
  expect_error(registre6_controle(id, 10, 9, sans_position_mesuree = "oui"),
               "TRUE ou FALSE")
})

test_that("un controle a l'ancienne s'ecrit comme avant", {
  id <- "11111111-1111-4111-8111-111111111111"
  x <- registre6_controle(id, 10, 9, h_moy_cm = 40)
  expect_setequal(names(x), c("type_entree", "placette_id", "nb_total",
                              "nb_vivants", "h_moy_cm"))
})

test_that("une position hors WGS 84 est refusee avec un message clair", {
  id <- "11111111-1111-4111-8111-111111111111"
  # Des metres Lambert-93 pris pour des degres.
  lambert <- list(type = "Point", coordinates = c(600150, 6700100))
  expect_error(registre6_controle(id, 10, 9, geometrie = lambert),
               "point WGS 84.*longitude")
  expect_error(registre6_controle(id, 10, 9,
                                  geometrie = list(type = "Point",
                                                   coordinates = c(4.9, 95))),
               "point WGS 84.*latitude")
  expect_error(registre6_controle(id, 10, 9,
                                  geometrie = geom_ligne(rbind(c(4.9, 47), c(4.91, 47.01)))),
               "point WGS 84")
  expect_error(registre6_controle(id, 10, 9, geometrie = geom_point(4.9, 47),
                                  precision_m = -1), "precision_m")
})

test_that("une precision de 0 ou negative est refusee (strictement positive)", {
  id <- "11111111-1111-4111-8111-111111111111"
  for (p in c(0, -1)) {
    expect_error(registre6_controle(id, 10, 9, geometrie = geom_point(4.9, 47),
                                    precision_m = p), "strictement positive")
  }
  expect_equal(registre6_controle(id, 10, 9, geometrie = geom_point(4.9, 47),
                                  precision_m = 0.01)$precision_m, 0.01)
})
