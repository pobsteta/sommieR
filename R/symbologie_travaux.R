# La symbologie des couches de travaux.gpkg, alignee sur celle de Marculus
# (brief vers-sommier du 2026-10-16 ; CarteScreen.kt et couches-gpkg.md de
# marculus@aa7bc6e). Les couleurs et les epaisseurs vivent ICI, en un seul
# endroit : une evolution de Marculus se reporte en changeant cette liste.
# Groma applique le meme tableau (qfield/symbologie.py).
SYMBOLOGIE_MARCULUS <- list(
  # Parcelles : remplissage par proprietaire, cyclique dans l'ordre
  # d'apparition, opacite 0x33 (51/255, soit 20 %), contour de la meme
  # couleur (4 px, soit 0,9 mm) ; sans proprietaire : gris-vert.
  parcelles = list(
    palette = c("#1E88E5", "#43A047", "#F4511E", "#8E24AA", "#FDD835",
                "#00ACC1", "#6D4C41", "#EC407A"),
    sans_proprietaire = "#374742", opacite = 51L, contour_mm = 0.9,
    champ = "proprietaire", etiquette = "numero", visible = TRUE
  ),
  # Houppiers : contour seul, aucun remplissage, masques par defaut
  # (des milliers d'objets). Info-bulle : hauteur d'apex h_max.
  houppier = list(contour = "#2E7D32", contour_mm = 0.4, visible = FALSE,
                  info_bulle = "h_max"),
  # Desserte : trait ocre de 6 px (1,4 mm). Info-bulle : nom et nature.
  desserte = list(contour = "#B35C00", contour_mm = 1.4, visible = TRUE,
                  info_bulle = c("nom", "nature"))
)

# Identifiants des couches dans le modele ; houppier et desserte n'y sont pas
# encore : leur style s'applique des qu'une version du modele les apporte
# sous ces identifiants.
ID_COUCHE_STYLE <- c(parcelles = "travaux_parcelles",
                     houppier = "travaux_houppier",
                     desserte = "travaux_desserte")

rgba_symbologie <- function(hex, alpha = 255L) {
  paste(c(grDevices::col2rgb(hex)[, 1L], alpha), collapse = ",")
}

symbole_fill_xml <- function(remplissage, contour, largeur_mm,
                             style = "solid") {
  sprintf(paste0(
    '<symbol name="0" type="fill" alpha="1" force_rhr="0" clip_to_extent="1">',
    '<layer class="SimpleFill" enabled="1" locked="0" pass="0">',
    '<Option type="Map">',
    '<Option name="color" type="QString" value="%s"/>',
    '<Option name="style" type="QString" value="%s"/>',
    '<Option name="outline_color" type="QString" value="%s"/>',
    '<Option name="outline_style" type="QString" value="solid"/>',
    '<Option name="outline_width" type="QString" value="%s"/>',
    '<Option name="outline_width_unit" type="QString" value="MM"/>',
    '</Option></layer></symbol>'),
    remplissage, style, contour, format(largeur_mm))
}

# Une categorie par proprietaire (ordre d'apparition), couleur reprise
# cycliquement dans la palette ; une categorie "sans proprietaire" en
# derniere, qui recoit aussi les valeurs non listees.
renderer_parcelles_xml <- function(proprietaires) {
  s <- SYMBOLOGIE_MARCULUS$parcelles
  noms <- unique(proprietaires[!is.na(proprietaires) & nzchar(proprietaires)])
  couleurs <- c(s$palette[(seq_along(noms) - 1L) %% length(s$palette) + 1L],
                s$sans_proprietaire)
  noms <- c(noms, "")
  cats <- vapply(seq_along(noms), function(i) {
    sprintf('<category symbol="%d" value="%s" label="%s" render="true"/>',
            i - 1L, echapper_xml(noms[[i]]),
            echapper_xml(if (nzchar(noms[[i]])) noms[[i]]
                         else "Sans proprietaire"))
  }, character(1))
  syms <- vapply(seq_along(couleurs), function(i) {
    sub('name="0"', sprintf('name="%d"', i - 1L),
        symbole_fill_xml(rgba_symbologie(couleurs[[i]], s$opacite),
                         rgba_symbologie(couleurs[[i]]), s$contour_mm),
        fixed = TRUE)
  }, character(1))
  sprintf(paste0('<renderer-v2 type="categorizedSymbol" attr="%s" ',
                 'symbollevels="0" forceraster="0" enableorderby="0" ',
                 'referencescale="-1"><categories>%s</categories>',
                 '<symbols>%s</symbols></renderer-v2>'),
          s$champ, paste(cats, collapse = ""), paste(syms, collapse = ""))
}

# Houppiers : contour seul, remplissage transparent.
renderer_houppier_xml <- function() {
  s <- SYMBOLOGIE_MARCULUS$houppier
  sprintf(paste0('<renderer-v2 type="singleSymbol" symbollevels="0" ',
                 'forceraster="0" enableorderby="0" referencescale="-1">',
                 '<symbols>%s</symbols></renderer-v2>'),
          symbole_fill_xml("0,0,0,0", rgba_symbologie(s$contour),
                           s$contour_mm, style = "no"))
}

# Desserte : ligne simple ocre.
renderer_desserte_xml <- function() {
  s <- SYMBOLOGIE_MARCULUS$desserte
  sprintf(paste0(
    '<renderer-v2 type="singleSymbol" symbollevels="0" forceraster="0" ',
    'enableorderby="0" referencescale="-1"><symbols>',
    '<symbol name="0" type="line" alpha="1" force_rhr="0" clip_to_extent="1">',
    '<layer class="SimpleLine" enabled="1" locked="0" pass="0">',
    '<Option type="Map">',
    '<Option name="line_color" type="QString" value="%s"/>',
    '<Option name="line_width" type="QString" value="%s"/>',
    '<Option name="line_width_unit" type="QString" value="MM"/>',
    '<Option name="capstyle" type="QString" value="round"/>',
    '<Option name="joinstyle" type="QString" value="round"/>',
    '</Option></layer></symbol></symbols></renderer-v2>'),
    rgba_symbologie(s$contour), format(s$contour_mm))
}

# Etiquette au centre de la surface : le numero de la parcelle.
etiquette_xml <- function(champ) {
  sprintf(paste0(
    '<labeling type="simple"><settings calloutType="simple">',
    '<text-style fieldName="%s" fontSize="9" textColor="0,0,0,255">',
    '<text-buffer bufferDraw="1" bufferSize="0.8" ',
    'bufferColor="255,255,255,255"/></text-style>',
    '<placement placement="1" quadOffset="4" centroidWhole="0"/>',
    '<rendering scaleVisibility="1" scaleMax="10000" scaleMin="0"/>',
    '</settings></labeling>'), champ)
}

# Pose rendu, etiquette, info-bulle et visibilite par defaut d'une couche du
# projet. Une couche absente du projet est laissee telle quelle.
styler_couche_projet <- function(qgs, id, renderer, etiquette = NULL,
                                 visible = TRUE, info_bulle = NULL) {
  xml <- xml2::read_xml(qgs)
  couche <- xml2::xml_find_first(xml, sprintf("//maplayer[id='%s']", id))
  if (inherits(couche, "xml_missing")) {
    return(invisible(FALSE))
  }
  nouveau <- xml2::xml_find_first(xml2::read_xml(renderer), "/*")
  ancien <- xml2::xml_find_first(couche, "renderer-v2")
  if (inherits(ancien, "xml_missing")) {
    xml2::xml_add_child(couche, nouveau)
  } else {
    xml2::xml_replace(ancien, nouveau)
  }
  xml2::xml_remove(xml2::xml_find_all(couche, "labeling"))
  if (!is.null(etiquette)) {
    xml2::xml_add_sibling(xml2::xml_find_first(couche, "renderer-v2"),
                          xml2::xml_find_first(xml2::read_xml(etiquette), "/*"),
                          .where = "after")
  }
  if (!is.null(info_bulle)) {
    bulle <- xml2::xml_find_first(couche, "mapTip")
    modele <- paste0("[% ", paste(sprintf('"%s"', info_bulle),
                                  collapse = " || ' ' || "), " %]")
    if (inherits(bulle, "xml_missing")) {
      bulle <- xml2::xml_add_child(couche, "mapTip")
    }
    xml2::xml_set_text(bulle, modele)
    xml2::xml_set_attr(bulle, "enabled", "1")
  }
  noeud <- xml2::xml_find_first(
    xml, sprintf("//layer-tree-layer[@id='%s']", id))
  if (!inherits(noeud, "xml_missing")) {
    xml2::xml_set_attr(noeud, "checked",
                       if (visible) "Qt::Checked" else "Qt::Unchecked")
  }
  xml2::write_xml(xml, qgs)
  invisible(TRUE)
}

# Applique le tableau de Marculus aux couches presentes du projet.
poser_symbologie_travaux <- function(qgs, proprietaires = character()) {
  s <- SYMBOLOGIE_MARCULUS
  styler_couche_projet(qgs, ID_COUCHE_STYLE[["parcelles"]],
                       renderer_parcelles_xml(proprietaires),
                       etiquette_xml(s$parcelles$etiquette),
                       visible = s$parcelles$visible)
  styler_couche_projet(qgs, ID_COUCHE_STYLE[["houppier"]],
                       renderer_houppier_xml(), visible = s$houppier$visible,
                       info_bulle = s$houppier$info_bulle)
  styler_couche_projet(qgs, ID_COUCHE_STYLE[["desserte"]],
                       renderer_desserte_xml(), visible = s$desserte$visible,
                       info_bulle = s$desserte$info_bulle)
  invisible(qgs)
}
