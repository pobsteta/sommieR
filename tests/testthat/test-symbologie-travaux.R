# La symbologie de travaux.gpkg alignee sur Marculus (brief du 2026-10-16).
# Sans base : elle opere sur une copie du modele de projet.

projet_modele <- function(env = parent.frame()) {
  skip_if_not_installed("xml2")
  chemin <- file.path(withr::local_tempdir(.local_envir = env), "travaux.qgs")
  file.copy(system.file("qgis", "travaux.qgs", package = "sommieR"), chemin)
  chemin
}

couche_projet <- function(xml, id) {
  xml2::xml_find_first(xml, sprintf("//maplayer[id='%s']", id))
}

attr_option <- function(noeud, nom) {
  xml2::xml_attr(xml2::xml_find_first(
    noeud, sprintf(".//Option[@name='%s']", nom)), "value")
}

test_that("les parcelles sont coloriees par proprietaire, comme Marculus", {
  qgs <- projet_modele()
  props <- c("Commune", "Etat", "Commune", NA, "Prive")
  poser_symbologie_travaux(qgs, props)
  xml <- xml2::read_xml(qgs)
  rend <- xml2::xml_find_first(couche_projet(xml, "travaux_parcelles"),
                               "renderer-v2")
  expect_equal(xml2::xml_attr(rend, "type"), "categorizedSymbol")
  expect_equal(xml2::xml_attr(rend, "attr"), "proprietaire")
  cats <- xml2::xml_attr(xml2::xml_find_all(rend, ".//category"), "value")
  # Ordre d'apparition, puis la categorie sans proprietaire.
  expect_equal(cats, c("Commune", "Etat", "Prive", ""))
  syms <- xml2::xml_find_all(rend, ".//symbol")
  pal <- SYMBOLOGIE_MARCULUS$parcelles$palette
  # Remplissage a 0x33 (51), contour de la meme couleur, opaque.
  remplissages <- vapply(syms, attr_option, "", nom = "color")
  expect_equal(remplissages,
               c(unname(vapply(pal[1:3], rgba_symbologie, "", alpha = 51L)),
                 rgba_symbologie("#374742", 51L)))
  contours <- vapply(syms, attr_option, "", nom = "outline_color")
  expect_equal(contours[[1L]], "30,136,229,255")
  expect_equal(contours[[4L]], "55,71,66,255")
  # Etiquette au centre : le numero de la parcelle.
  etiq <- xml2::xml_find_first(couche_projet(xml, "travaux_parcelles"),
                               "labeling/settings/text-style")
  expect_equal(xml2::xml_attr(etiq, "fieldName"), "numero")
  # Le modele les desactivait : la couche doit les activer.
  expect_equal(xml2::xml_attr(couche_projet(xml, "travaux_parcelles"),
                              "labelsEnabled"), "1")
  noeud <- xml2::xml_find_first(
    xml, "//layer-tree-layer[@id='travaux_parcelles']")
  expect_equal(xml2::xml_attr(noeud, "checked"), "Qt::Checked")
})

test_that("la palette est cyclique au-dela de huit proprietaires", {
  skip_if_not_installed("xml2")
  rend <- xml2::read_xml(renderer_parcelles_xml(paste0("P", 1:9)))
  syms <- xml2::xml_find_all(rend, ".//symbol")
  contours <- vapply(syms, attr_option, "", nom = "outline_color")
  expect_equal(contours[[9L]], contours[[1L]])
  expect_equal(contours[[10L]], "55,71,66,255")
})

test_that("houppiers (contour seul, masque) et desserte (ocre) sont stylables", {
  qgs <- projet_modele()
  # Le modele n'a pas encore ces couches : on en pose deux de fortune.
  xml <- xml2::read_xml(qgs)
  for (id in c("travaux_houppier", "travaux_desserte")) {
    arbre <- xml2::xml_find_first(
      xml, "//layer-tree-layer[@id='travaux_foret']")
    xml2::xml_add_sibling(arbre, "layer-tree-layer", id = id,
                          checked = "Qt::Checked")
    m <- xml2::xml_add_child(xml2::xml_find_first(xml, "//projectlayers"),
                             "maplayer")
    xml2::xml_add_child(m, "id", id)
  }
  xml2::write_xml(xml, qgs)
  poser_symbologie_travaux(qgs)
  xml <- xml2::read_xml(qgs)
  h <- couche_projet(xml, "travaux_houppier")
  expect_equal(attr_option(h, "outline_color"), "46,125,50,255")
  expect_equal(attr_option(h, "style"), "no")
  expect_equal(xml2::xml_attr(xml2::xml_find_first(
    xml, "//layer-tree-layer[@id='travaux_houppier']"), "checked"),
    "Qt::Unchecked")
  expect_match(xml2::xml_text(xml2::xml_find_first(h, "mapTip")), "h_max")
  d <- couche_projet(xml, "travaux_desserte")
  expect_equal(attr_option(d, "line_color"), "179,92,0,255")
  expect_equal(xml2::xml_attr(xml2::xml_find_first(
    xml, "//layer-tree-layer[@id='travaux_desserte']"), "checked"),
    "Qt::Checked")
  expect_match(xml2::xml_text(xml2::xml_find_first(d, "mapTip")), "nature")
})

test_that("une couche absente du projet est laissee telle quelle", {
  qgs <- projet_modele()
  avant <- readLines(qgs, warn = FALSE)
  expect_false(styler_couche_projet(qgs, "inexistante",
                                    renderer_houppier_xml()))
  expect_equal(readLines(qgs, warn = FALSE), avant)
})
