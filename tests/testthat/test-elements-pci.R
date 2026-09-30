# Elements du plan cadastral : selection au tampon, situation, texte cite,
# numerotation. Deux feuilles reelles jointes au depot (voir
# fixtures/PROVENANCE.md) : Couchey A01 et Loury ZK01.

fond_fixture <- function(feuille, env = parent.frame()) {
  skip_if_not_installed("sf")
  archive <- testthat::test_path("fixtures", paste0("edigeo-", feuille,
                                                    ".tar.bz2"))
  skip_if_not(file.exists(archive), "Fixture EDIGEO absente.")
  dossier <- withr::local_tempdir(.local_envir = env)
  utils::untar(archive, exdir = dossier, tar = "internal")
  structure(
    list(feuilles = data.frame(feuille = feuille, thf = fichier_thf(dossier),
                               stringsAsFactors = FALSE),
         code_insee = substr(feuille, 1L, 5L), source = "fixture locale"),
    class = "sommier_fond_pci"
  )
}

# Toute la feuille : l'emprise est la boite de ses parcelles.
emprise_feuille <- function(fond) {
  parcelles <- sommier_fond_pci_lire(fond, "parcelles")
  boite <- sf::st_as_sfc(sf::st_bbox(sf::st_as_sfc(parcelles$wkt, crs = 2154)))
  data.frame(wkt = sf::st_as_text(boite), stringsAsFactors = FALSE)
}

carre <- function(x0, y0, cote) {
  sprintf("POLYGON((%1$f %2$f, %3$f %2$f, %3$f %4$f, %1$f %4$f, %1$f %2$f))",
          x0, y0, x0 + cote, y0 + cote)
}

test_that("les categories retenues materialisent quelque chose au sol", {
  expect_true(all(SOMMIER_CATEGORIES_PCI$couche %in% names(SOMMIER_COUCHES_PCI)))
  expect_false(any(c("parcelles") %in% SOMMIER_CATEGORIES_PCI$couche))
  # Un prefixe par categorie : deux categories ne partagent pas une serie.
  expect_equal(anyDuplicated(SOMMIER_CATEGORIES_PCI$prefixe), 0L)
})

test_that("le millesime se lit dans la declaration du lot", {
  fond <- fond_fixture("45188000ZK01")
  expect_equal(millesime_lot(fond$feuilles$thf), as.Date("2026-02-17"))
  # Un lot sans date d'echange n'en recoit pas d'inventee.
  thf <- file.path(withr::local_tempdir(), "E0000A01.THF")
  writeLines("BOMT 12:E0000A01.THF", thf)
  expect_true(is.na(millesime_lot(thf)))
  expect_true(is.na(millesime_lot(NA_character_)))
})

test_that("toutes les couches physiques d'une feuille sont rassemblees", {
  fond <- fond_fixture("45188000ZK01")
  e <- sommier_elements_pci(fond, emprise_feuille(fond))

  compte <- table(e$couche)
  expect_equal(compte[["bornes"]], 282L)
  expect_equal(compte[["points"]], 2L)
  expect_equal(compte[["signes"]], 1L)
  expect_equal(compte[["details"]], 2L)
  expect_equal(compte[["surfaces"]], 1L)
  expect_equal(compte[["cours_eau"]], 3L)
  expect_equal(compte[["voies"]], 11L)
  expect_equal(compte[["batiments"]], 32L)
  # Ce qui ne pose rien au sol n'entre pas : parcelles, lieux-dits, et les
  # positions d'etiquettes de `ID_S_OBJ_Z_1_2_2`.
  expect_false(any(c("parcelles", "lieux_dits") %in% e$couche))

  expect_setequal(names(e), COLONNES_ELEMENTS)
  expect_true(all(e$millesime == as.Date("2026-02-17")))
  expect_equal(attr(e, "tampon_m"), 20)
})

test_that("le texte du plan est cite, sans devenir une nature", {
  fond <- fond_fixture("45188000ZK01")
  e <- sommier_elements_pci(fond, emprise_feuille(fond))
  points <- e[e$couche == "points", ]

  pylone <- points[points$sym == "50", ]
  expect_equal(pylone$texte, "pylone télécom")
  # Le texte nomme ici l'objet, mais rien ne le garantit ailleurs : la nature
  # d'un detail reste celle d'une table fournie, ou inconnue.
  expect_true(is.na(pylone$nature))
  expect_true(is.na(pylone$nature_source))

  # Le signe de limite porte son orientation ; sa couche dit ce qu'il est.
  signe <- e[e$couche == "signes", ]
  expect_equal(signe$orientation, 141.8, tolerance = 1e-3)
  expect_equal(signe$nature_source, "couche")
})

test_that("une etiquette rattachee a son objet fournit le texte", {
  # Sur Couchey, les lignes de code 19 ne portent pas de TEX : le texte vient
  # des etiquettes `TLINE_id_LABEL`. C'est le nom de la commune voisine, pose
  # le long de la limite - la preuve qu'un texte ne dit pas toujours la nature.
  fond <- fond_fixture("212000000A01")
  e <- sommier_elements_pci(fond, emprise_feuille(fond))
  nommes <- e[e$couche == "details" & !is.na(e$texte), ]
  expect_equal(nrow(nommes), 3L)
  expect_true(all(nommes$sym == "19"))
  expect_true("COMMUNE DE FLAVIGNEROT" %in% nommes$texte)
  expect_true(all(is.na(nommes$nature)))
})

test_that("un nom pose mot par mot n'est pas recompose", {
  # Le plan ecrit « Route de la Vallee Jaune » un mot par attribut, dans un
  # ordre qui n'est pas celui de la lecture. Recomposer serait inventer.
  morceaux <- data.frame(TEX = c("Jaune", "Rue de la Tuilerie", NA),
                         TEX2 = c("de", "Rue de la Tuilerie", NA),
                         TEX3 = c("Vallée", NA, " "),
                         stringsAsFactors = FALSE)
  lu <- textes_objets(morceaux)
  expect_equal(lu$texte, c(NA, "Rue de la Tuilerie", NA))
  expect_equal(lu$morcele, c(TRUE, FALSE, FALSE))

  fond <- fond_fixture("45188000ZK01")
  e <- sommier_elements_pci(fond, emprise_feuille(fond))
  voies <- e[e$couche == "voies", ]
  expect_true(any(voies$texte_morcele))
  expect_true(all(is.na(voies$texte[voies$texte_morcele])))
  expect_true("Route de Chilleurs (R D 2152)" %in% voies$texte)
})

test_that("une table fournie nomme les details qu'elle couvre", {
  fond <- fond_fixture("45188000ZK01")
  e <- sommier_elements_pci(fond, emprise_feuille(fond),
                            symboles = c("21" = "mur"))
  mur <- e[e$couche == "details" & e$sym == "21", ]
  expect_equal(mur$nature, "mur")
  expect_equal(mur$nature_source, "appelant")
  # Hors table, rien n'est comble.
  autre <- e[e$couche == "details" & e$sym == "31", ]
  expect_true(is.na(autre$nature))
  # La table ne s'applique qu'aux details : une borne reste une borne.
  expect_true(all(e$nature[e$couche == "bornes"] == "borne"))
})

test_that("la numerotation suit le cadastre et ne varie pas d'un appel a l'autre", {
  fond <- fond_fixture("45188000ZK01")
  un <- sommier_elements_pci(fond, emprise_feuille(fond))
  deux <- sommier_elements_pci(fond, emprise_feuille(fond))
  expect_identical(un$numero, deux$numero)
  expect_identical(un$id, deux$id)

  expect_equal(anyDuplicated(un$id), 0L)
  expect_true(all(startsWith(un$id, "45188000ZK01:Objet_")))
  bornes <- un[un$couche == "bornes", ]
  expect_equal(bornes$numero[1:2], c("B-001", "B-002"))
  # D'ouest en est : le premier numero est le plus a l'ouest.
  expect_equal(bornes$x[[1L]], min(bornes$x))
  expect_equal(un$numero[un$couche == "points"], c("P-001", "P-002"))
})

test_that("le tampon retient ce qui borde, et la distance mesure", {
  skip_if_not_installed("sf")
  emprise <- data.frame(wkt = carre(1000, 1000, 100), stringsAsFactors = FALSE)
  objets <- data.frame(
    couche = "bornes", feuille = "F", objet = paste0("Objet_", 1:3),
    wkt = c("POINT (1050 1050)", "POINT (1110 1050)", "POINT (1130 1050)"),
    stringsAsFactors = FALSE
  )
  retenus <- restreindre_emprise(objets, emprise, 20)
  expect_equal(retenus$objet, c("Objet_1", "Objet_2"))

  situes <- situer_elements(retenus, emprise)
  expect_equal(situes$situation, c("foret", "tampon"))
  # 50 m du bord pour la borne au centre, 10 m pour celle du tampon.
  expect_equal(situes$distance_limite_m, c(50, 10))
})

test_that("sans emprise, ni tampon ni situation n'ont de sens", {
  fond <- fond_fixture("45188000ZK01")
  expect_error(sommier_elements_pci(fond, NULL), "obligatoire")
  expect_error(sommier_elements_pci(data.frame(), data.frame(wkt = "x")),
               "sommier_fond_pci")
})

test_that("une emprise loin de tout rend un tableau vide de meme forme", {
  fond <- fond_fixture("45188000ZK01")
  loin <- data.frame(wkt = carre(100000, 6000000, 10), stringsAsFactors = FALSE)
  e <- sommier_elements_pci(fond, loin)
  expect_equal(nrow(e), 0L)
  expect_setequal(names(e), COLONNES_ELEMENTS)
})

test_that("l'export GeoPackage ecrit une couche par type de geometrie", {
  fond <- fond_fixture("45188000ZK01")
  e <- sommier_elements_pci(fond, emprise_feuille(fond))
  chemin <- file.path(withr::local_tempdir(), "elements.gpkg")

  ecrits <- sommier_exporter_elements_pci(e, chemin)
  expect_equal(sum(ecrits), nrow(e))
  couches <- sf::st_layers(chemin)
  expect_setequal(couches$name,
                  c("elements_points", "elements_lignes", "elements_surfaces"))
  points <- sf::read_sf(chemin, layer = "elements_points")
  expect_equal(nrow(points), sum(e$couche %in% c("bornes", "points", "signes")))
  expect_equal(sf::st_crs(points)$epsg, 2154L)
  expect_true(all(c("id", "numero", "situation") %in% names(points)))

  # Reecrire remplace, sans empiler.
  sommier_exporter_elements_pci(e, chemin)
  expect_equal(nrow(sf::read_sf(chemin, layer = "elements_points")),
               nrow(points))

  expect_error(sommier_exporter_elements_pci(e, "elements.shp"), "gpkg")
  expect_error(sommier_exporter_elements_pci(data.frame(x = 1), chemin),
               "sommier_elements_pci")
})

test_that("l'echelle d'origine de chaque feuille se lit dans le lot", {
  # `EOR` de la subdivision de section : c'est elle qui fixe la precision
  # graphique du trace, et donc la tolerance d'un ecart au terrain.
  zk01 <- fond_fixture("45188000ZK01")
  expect_true(all(sommier_elements_pci(zk01, emprise_feuille(zk01))$echelle ==
                    2000))
  a01 <- fond_fixture("212000000A01")
  expect_true(all(sommier_elements_pci(a01, emprise_feuille(a01))$echelle ==
                    5000))
})
