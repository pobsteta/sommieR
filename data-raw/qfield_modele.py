"""Modele du projet QGIS/QField du suivi des limites.

Produit, une fois pour toutes, les deux fichiers que `sommier_projet_qfield()`
copie a chaque tournee :

* inst/qgis/terrain.gpkg  -- le GeoPackage, couches vides, schema definitif ;
* inst/qgis/limites.qgs   -- le projet : styles, formulaires, relation ;
* inst/qgis/limites_attachments.zip -- la base de styles que le projet
  reference ; elle voyage avec lui, sous le meme nom.

Pourquoi un script plutot qu'un .qgs ecrit a la main : un projet QGIS est un
XML de plusieurs milliers de lignes, dont les formulaires, les relations et
les widgets de piece jointe n'ont pas de schema publie. Le faire ecrire par
QGIS lui-meme est la seule facon d'etre sur qu'il le relit. R ne touche ensuite
qu'aux donnees et a quelques valeurs repere (@@...@@).

A relancer apres toute modification, avec QGIS >= 3.40 (QField 4) :

    QT_QPA_PLATFORM=offscreen python3 data-raw/qfield_modele.py

Le nom des couches et des champs est un contrat avec R/qfield.R : le changer
ici impose de le changer la-bas.
"""

import json
import os
import sys

from qgis.core import (
    Qgis, QgsApplication, QgsAttributeEditorContainer, QgsAttributeEditorField,
    QgsAttributeEditorRelation, QgsAttributeEditorTextElement,
    QgsCategorizedSymbolRenderer, QgsCoordinateReferenceSystem,
    QgsDefaultValue, QgsEditFormConfig, QgsEditorWidgetSetup, QgsFeature,
    QgsField, QgsFieldConstraints, QgsFields, QgsFillSymbol,
    QgsLineSymbol, QgsMarkerSymbol, QgsPalLayerSettings, QgsProject,
    QgsRasterLayer, QgsReferencedRectangle, QgsRectangle, QgsRelation,
    QgsRendererCategory, QgsTextFormat, QgsVectorFileWriter, QgsVectorLayer,
    QgsVectorLayerSimpleLabeling, QgsWkbTypes, QgsCoordinateTransformContext,
)
from qgis.PyQt.QtCore import QMetaType

RACINE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SORTIE = os.path.join(RACINE, "inst", "qgis")
GPKG = os.path.join(SORTIE, "terrain.gpkg")
QGS = os.path.join(SORTIE, "limites.qgs")
L93 = QgsCoordinateReferenceSystem("EPSG:2154")

TEXTE, REEL, DATE, INSTANT = (QMetaType.Type.QString, QMetaType.Type.Double,
                              QMetaType.Type.QDate, QMetaType.Type.QDateTime)

# Les colonnes de chaque couche. Les couches de donnees sont reecrites par R a
# chaque projet ; les couches de saisie (constats, photos) gardent ce schema.
ELEMENTS = [("id", TEXTE), ("numero", TEXTE), ("categorie", TEXTE),
            ("nature", TEXTE), ("texte", TEXTE),
            ("designation", TEXTE), ("situation", TEXTE),
            ("distance_limite_m", REEL), ("millesime", DATE),
            ("derniere_visite", DATE), ("dernier_etat", TEXTE),
            ("a_visiter", TEXTE), ("x", REEL), ("y", REEL)]
COUCHES = [
    ("elements_points", "MultiPoint", ELEMENTS),
    ("elements_lignes", "MultiLineString", ELEMENTS),
    ("elements_surfaces", "MultiPolygon", ELEMENTS),
    ("elements", "Point", [("id", TEXTE), ("numero", TEXTE),
                           ("libelle", TEXTE)]),
    ("constats", "Point", [("uuid", TEXTE), ("element_id", TEXTE),
                           ("etat", TEXTE), ("visite_le", INSTANT),
                           ("operateur", TEXTE), ("precision_m", REEL),
                           ("source_gnss", TEXTE), ("observations", TEXTE)]),
    ("photos", "NoGeometry", [("uuid", TEXTE), ("constat_uuid", TEXTE),
                              ("fichier", TEXTE), ("prise_le", INSTANT)]),
    ("foret", "MultiPolygon", [("nom", TEXTE)]),
    ("tampon", "MultiPolygon", [("tampon_m", REEL)]),
    ("ug", "MultiPolygon", [("numero", TEXTE)]),
    ("parcelles", "MultiPolygon", [("reference", TEXTE),
                                   ("designation", TEXTE)]),
]

ETATS = [("En place", "en_place"), ("Endommagé", "endommage"),
         ("Non retrouvé", "non_retrouve"), ("Détruit", "detruit"),
         ("Inaccessible", "inaccessible"), ("Hors plan", "hors_plan")]

# « a_voir » : jamais vu, ou reste inaccessible. Les autres categories
# disent le dernier etat constate.
A_VISITER = [("a_voir", "À voir", "#D32F2F"),
             ("ancienne", "Vu il y a longtemps", "#F57C00"),
             ("vu", "Vu en place", "#388E3C"),
             ("defaut", "Vu, endommagé", "#FBC02D"),
             ("perdu", "Non retrouvé ou détruit", "#212121")]


def ecrire_gpkg():
    if os.path.exists(GPKG):
        os.remove(GPKG)
    for nom, geometrie, champs in COUCHES:
        fields = QgsFields()
        for champ, type_ in champs:
            fields.append(QgsField(champ, type_))
        options = QgsVectorFileWriter.SaveVectorOptions()
        options.driverName = "GPKG"
        options.layerName = nom
        options.actionOnExistingFile = (
            QgsVectorFileWriter.CreateOrOverwriteLayer if os.path.exists(GPKG)
            else QgsVectorFileWriter.CreateOrOverwriteFile)
        wkb = QgsWkbTypes.parseType(geometrie)
        writer = QgsVectorFileWriter.create(
            GPKG, fields, wkb, L93, QgsCoordinateTransformContext(), options)
        if writer.hasError() != QgsVectorFileWriter.NoError:
            sys.exit("Ecriture impossible : %s (%s)" % (nom, writer.errorMessage()))
        del writer


# Identifiants de couche qui s'ecartent du nom de table. `limites_ug` etait
# remplace par un UUID a la relecture, comme les identifiants sans tiret
# bas ; `limites_unites` tient.
IDENTIFIANTS = {"ug": "unites"}


def ecrire_leurre(chemin):
    """Un GeoTIFF de 2 x 2 pixels en Lambert-93, trois bandes."""
    from osgeo import gdal, osr
    gdal.UseExceptions()
    pilote = gdal.GetDriverByName("GTiff")
    image = pilote.Create(chemin, 2, 2, 3, gdal.GDT_Byte)
    image.SetGeoTransform((600000, 1, 0, 6700000, 0, -1))
    systeme = osr.SpatialReference()
    systeme.ImportFromEPSG(2154)
    image.SetProjection(systeme.ExportToWkt())
    image = None


def couche(nom, titre=None):
    c = QgsVectorLayer("%s|layername=%s" % (GPKG, nom), titre or nom, "ogr")
    if not c.isValid():
        sys.exit("Couche invalide : " + nom)
    # L'identifiant est le nom de la table, prefixe : stable d'une generation
    # a l'autre, et c'est par lui que `overlay_nearest()` designe la couche.
    # Le prefixe n'est pas decoratif : a la relecture, QGIS remplace par un
    # UUID tout identifiant sans tiret bas, et la relation se perd.
    c.setId("limites_" + IDENTIFIANTS.get(nom, nom))
    return c


def widget(c, champ, type_, config=None):
    c.setEditorWidgetSetup(c.fields().indexOf(champ),
                           QgsEditorWidgetSetup(type_, config or {}))


def defaut(c, champ, expression, a_la_mise_a_jour=False):
    c.setDefaultValueDefinition(c.fields().indexOf(champ),
                                QgsDefaultValue(expression, a_la_mise_a_jour))


def etiqueter(c, champ, taille=8):
    reglage = QgsPalLayerSettings()
    reglage.fieldName = champ
    fmt = QgsTextFormat()
    fmt.setSize(taille)
    reglage.setFormat(fmt)
    c.setLabeling(QgsVectorLayerSimpleLabeling(reglage))
    c.setLabelsEnabled(True)


def symbole(geometrie, couleur):
    if geometrie == "point":
        return QgsMarkerSymbol.createSimple(
            {"name": "circle", "color": couleur, "size": "3",
             "outline_color": "#FFFFFF", "outline_width": "0.4"})
    if geometrie == "ligne":
        return QgsLineSymbol.createSimple({"color": couleur, "width": "0.8"})
    return QgsFillSymbol.createSimple(
        {"color": couleur + "55", "outline_color": couleur,
         "outline_width": "0.5"})


def styler_elements(c, geometrie):
    categories = [QgsRendererCategory(valeur, symbole(geometrie, couleur),
                                      libelle)
                  for valeur, libelle, couleur in A_VISITER]
    c.setRenderer(QgsCategorizedSymbolRenderer("a_visiter", categories))
    etiqueter(c, "numero")
    c.setReadOnly(True)


def principal():
    ecrire_gpkg()
    projet = QgsProject.instance()
    projet.clear()
    projet.setFileName(QGS)
    projet.setCrs(L93)
    projet.setTitle("@@TITRE@@")
    projet.writeEntryBool("Paths", "/Absolute", False)

    # --- Donnees en lecture seule --------------------------------------
    points = couche("elements_points", "Éléments du plan (points)")
    lignes = couche("elements_lignes", "Éléments du plan (lignes)")
    surfaces = couche("elements_surfaces", "Éléments du plan (surfaces)")
    for c, g in ((points, "point"), (lignes, "ligne"), (surfaces, "surface")):
        styler_elements(c, g)

    # Les ancres : un point par element, pour la liste de choix du constat.
    ancres = couche("elements", "Éléments (liste)")
    ancres.setReadOnly(True)
    ancres.renderer().setSymbol(QgsMarkerSymbol.createSimple(
        {"name": "circle", "size": "0.1", "color": "#00000000",
         "outline_style": "no"}))

    foret = couche("foret", "Forêt")
    foret.setRenderer(foret.renderer().__class__(QgsFillSymbol.createSimple(
        {"color": "#2E7D3222", "outline_color": "#1B5E20",
         "outline_width": "0.8"})))
    tampon = couche("tampon", "Tampon")
    tampon.setRenderer(tampon.renderer().__class__(QgsFillSymbol.createSimple(
        {"style": "no", "outline_color": "#616161", "outline_style": "dash",
         "outline_width": "0.4"})))
    ug = couche("ug", "Unités de gestion")
    ug.setRenderer(ug.renderer().__class__(QgsFillSymbol.createSimple(
        {"style": "no", "outline_color": "#33691E", "outline_width": "0.3"})))
    etiqueter(ug, "numero", 9)
    parcelles = couche("parcelles", "Parcelles cadastrales")
    parcelles.setRenderer(parcelles.renderer().__class__(
        QgsFillSymbol.createSimple({"style": "no", "outline_color": "#9E9E9E",
                                    "outline_width": "0.2"})))
    for c in (foret, tampon, ug, parcelles):
        c.setReadOnly(True)

    # --- Saisie : les constats -----------------------------------------
    constats = couche("constats", "Constats")
    constats.renderer().setSymbol(QgsMarkerSymbol.createSimple(
        {"name": "diamond", "color": "#1565C0", "size": "3.5",
         "outline_color": "#FFFFFF"}))
    widget(constats, "uuid", "Hidden")
    defaut(constats, "uuid", "uuid('WithoutBraces')")
    widget(constats, "element_id", "ValueRelation", {
        "Layer": ancres.id(), "LayerName": ancres.name(),
        "Key": "id", "Value": "libelle", "OrderByValue": True,
        "AllowNull": True, "UseCompleter": True})
    # L'element le plus proche, a 30 m au plus : les bornes d'abord, puis les
    # lignes, puis les surfaces. L'agent peut en choisir un autre : son choix
    # est garde (coalesce sur la valeur deja saisie). Reevaluee a chaque
    # changement, la valeur se vide quand l'etat passe a « Hors plan » - la
    # recette de terrain montrait sinon un element propose a un constat qui
    # n'en a pas.
    defaut(constats, "element_id", (
        "if(\"etat\" = 'hors_plan', NULL, coalesce(\"element_id\","
        "array_first(overlay_nearest('limites_elements_points', \"id\", limit:=1, max_distance:=30)),"
        "array_first(overlay_nearest('limites_elements_lignes', \"id\", limit:=1, max_distance:=30)),"
        "array_first(overlay_nearest('limites_elements_surfaces', \"id\", limit:=1, max_distance:=30))))"),
        a_la_mise_a_jour=True)
    widget(constats, "etat", "ValueMap",
           {"map": [{libelle: valeur} for libelle, valeur in ETATS]})
    i = constats.fields().indexOf("etat")
    constats.setFieldConstraint(i, QgsFieldConstraints.ConstraintNotNull,
                                QgsFieldConstraints.ConstraintStrengthHard)
    constats.setConstraintExpression(
        constats.fields().indexOf("element_id"),
        "\"etat\" = 'hors_plan' OR \"element_id\" IS NOT NULL",
        "Un constat répond à un élément du plan, sauf « Hors plan ».")
    constats.setFieldConstraint(constats.fields().indexOf("element_id"),
                                QgsFieldConstraints.ConstraintExpression,
                                QgsFieldConstraints.ConstraintStrengthHard)
    widget(constats, "visite_le", "DateTime",
           {"field_format": "yyyy-MM-ddTHH:mm:ss", "display_format":
            "dd/MM/yyyy HH:mm", "calendar_popup": True, "allow_null": False})
    defaut(constats, "visite_le", "now()")
    widget(constats, "operateur", "TextEdit")
    defaut(constats, "operateur", "@operateur")
    widget(constats, "precision_m", "TextEdit")
    defaut(constats, "precision_m", "@position_horizontal_accuracy")
    widget(constats, "source_gnss", "TextEdit")
    defaut(constats, "source_gnss", "@position_source_name")
    for champ in ("precision_m", "source_gnss"):
        config = constats.editFormConfig()
        config.setReadOnly(constats.fields().indexOf(champ), True)
        constats.setEditFormConfig(config)
    widget(constats, "observations", "TextEdit", {"IsMultiline": True})
    for champ, alias in (("element_id", "Élément du plan"), ("etat", "État"),
                         ("visite_le", "Visite"), ("operateur", "Opérateur"),
                         ("precision_m", "Précision GNSS (m)"),
                         ("source_gnss", "Source GNSS"),
                         ("observations", "Observations")):
        constats.setFieldAlias(constats.fields().indexOf(champ), alias)
    etiqueter(constats, "etat", 7)

    # --- Saisie : les photos --------------------------------------------
    photos = couche("photos", "Photos")
    widget(photos, "uuid", "Hidden")
    defaut(photos, "uuid", "uuid('WithoutBraces')")
    widget(photos, "constat_uuid", "Hidden")
    widget(photos, "fichier", "ExternalResource", {
        "DocumentViewer": 1, "DocumentViewerHeight": 0,
        "DocumentViewerWidth": 0, "FileWidget": True, "FileWidgetButton": True,
        "RelativeStorage": 1, "StorageMode": 0, "FullUrl": False})
    photos.setFieldAlias(photos.fields().indexOf("fichier"), "Photo")
    widget(photos, "prise_le", "DateTime",
           {"field_format": "yyyy-MM-ddTHH:mm:ss",
            "display_format": "dd/MM/yyyy HH:mm", "allow_null": True})
    defaut(photos, "prise_le", "now()")
    photos.setFieldAlias(photos.fields().indexOf("prise_le"), "Prise le")
    # QField range les photos prises sous ce nom, dans le dossier du projet.
    photos.setCustomProperty("QFieldSync/attachment_naming", json.dumps({
        "fichier": "'DCIM/limites_' || format_date(now(), 'yyyyMMdd_HHmmss_zzz') || '.{extension}'"}))

    projet.addMapLayers([constats, points, lignes, surfaces, ancres, ug,
                         foret, tampon, parcelles, photos])

    relation = QgsRelation()
    relation.setId("photos_du_constat")
    relation.setName("Photos du constat")
    relation.setReferencingLayer(photos.id())
    relation.setReferencedLayer(constats.id())
    relation.addFieldPair("constat_uuid", "uuid")
    relation.setStrength(Qgis.RelationshipStrength.Composition)
    if not relation.isValid():
        sys.exit("Relation invalide : " + relation.validationError())
    projet.relationManager().addRelation(relation)

    # Formulaire des photos : la consigne de prise de vue, puis la photo.
    config = photos.editFormConfig()
    config.setLayout(QgsEditFormConfig.TabLayout)
    racine = config.invisibleRootContainer()
    racine.clear()
    consigne = QgsAttributeEditorTextElement("Consigne", racine)
    consigne.setText(
        "Cadrer l'élément de limite. Éviter les personnes et les véhicules : "
        "la photo est une pièce du sommier, et peut être montrée.")
    racine.addChildElement(consigne)
    for champ in ("fichier", "prise_le"):
        racine.addChildElement(QgsAttributeEditorField(
            champ, photos.fields().indexOf(champ), racine))
    photos.setEditFormConfig(config)

    # Formulaire des constats : les champs, puis les photos.
    config = constats.editFormConfig()
    config.setLayout(QgsEditFormConfig.TabLayout)
    racine = config.invisibleRootContainer()
    racine.clear()
    for champ in ("element_id", "etat", "visite_le", "operateur",
                  "precision_m", "source_gnss", "observations"):
        racine.addChildElement(QgsAttributeEditorField(
            champ, constats.fields().indexOf(champ), racine))
    racine.addChildElement(QgsAttributeEditorRelation(relation, racine))
    constats.setEditFormConfig(config)

    # Fond : l'orthophotographie de l'IGN, qui ne s'affiche qu'avec du reseau.
    ortho = QgsRasterLayer(
        "contextualWMSLegend=0&crs=EPSG:3857&dpiMode=7&format=image/jpeg"
        "&layers=ORTHOIMAGERY.ORTHOPHOTOS&styles=normal"
        "&tileMatrixSet=PM_0_19&url=https://data.geopf.fr/wmts?"
        "SERVICE%3DWMTS%26REQUEST%3DGetCapabilities",
        "Orthophotographie IGN (réseau)", "wms")
    projet.addMapLayer(ortho)

    # L'ortho hors ligne : un GeoTIFF que sommier_projet_qfield() copie a cote
    # du projet (voir sommier_ortho_ign()). Un leurre de trois bandes sert a
    # construire la couche ici ; R retire la couche quand aucune ortho n'est
    # fournie, plutot que de laisser QField signaler un fichier absent.
    leurre = os.path.join(SORTIE, "ortho.tif")
    ecrire_leurre(leurre)
    locale = QgsRasterLayer(leurre, "Orthophotographie (hors ligne)", "gdal")
    if not locale.isValid():
        sys.exit("Ortho locale invalide.")
    locale.setId("limites_ortho")
    projet.addMapLayer(locale)

    racine_arbre = projet.layerTreeRoot()
    for c in (ancres, photos):
        noeud = racine_arbre.findLayer(c.id())
        if noeud is not None:
            noeud.setItemVisibilityChecked(False)
    # Les orthos en dessous de tout, la locale au-dessus de celle du reseau :
    # sans reseau, la seconde reste vide et laisse voir la premiere.
    for couche_fond in (locale, ortho):
        noeud = racine_arbre.findLayer(couche_fond.id())
        clone = noeud.clone()
        racine_arbre.insertChildNode(-1, clone)
        racine_arbre.removeChildNode(noeud)

    projet.setCustomVariables({
        "operateur": "@@OPERATEUR@@",
        "sommier_foret": "@@FORET@@",
        "qfield_version_minimale": "4.3",
    })
    projet.viewSettings().setDefaultViewExtent(QgsReferencedRectangle(
        QgsRectangle(111111, 2222222, 333333, 4444444), L93))
    metadonnees = projet.metadata()
    metadonnees.setTitle("@@TITRE@@")
    metadonnees.setAbstract(
        "Vérification des limites sur le terrain. Projet engendré par sommieR "
        "; à ouvrir avec QField 4.3 ou plus récent (recetté sous QField "
        "4.3.4, Android). Les éléments du plan sont "
        "en lecture seule ; un constat par élément visité, avec ses photos.")
    projet.setMetadata(metadonnees)

    if not projet.write():
        sys.exit("Ecriture du projet impossible.")
    # QGIS laisse une sauvegarde de l'ecriture precedente : elle n'a rien a
    # faire dans le paquet.
    if os.path.exists(QGS + "~"):
        os.remove(QGS + "~")
    for reste in (leurre, leurre + ".aux.xml"):
        if os.path.exists(reste):
            os.remove(reste)
    print("Ecrit :", QGS, "et", GPKG)


if __name__ == "__main__":
    QgsApplication.setPrefixPath("/usr", True)
    application = QgsApplication([], False)
    application.initQgis()
    try:
        principal()
    finally:
        application.exitQgis()
