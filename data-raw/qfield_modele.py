"""Modeles des projets QGIS/QField de terrain : limites et detections.

Produit, une fois pour toutes, les fichiers que `sommier_projet_qfield()`
copie a chaque tournee des limites :

* inst/qgis/terrain.gpkg  -- le GeoPackage, couches vides, schema definitif ;
* inst/qgis/limites.qgs   -- le projet : styles, formulaires, relation ;
* inst/qgis/limites_attachments.zip -- la base de styles que le projet
  reference ; elle voyage avec lui, sous le meme nom.

et ceux que `sommier_projet_qfield_detections()` copie a chaque tournee des
detections : inst/qgis/detections.gpkg, detections.qgs et, s'il y a lieu,
detections_attachments.zip.

Pourquoi un script plutot qu'un .qgs ecrit a la main : un projet QGIS est un
XML de plusieurs milliers de lignes, dont les formulaires, les relations et
les widgets de piece jointe n'ont pas de schema publie. Le faire ecrire par
QGIS lui-meme est la seule facon d'etre sur qu'il le relit. R ne touche ensuite
qu'aux donnees et a quelques valeurs repere (@@...@@).

A relancer apres toute modification, avec QGIS >= 3.40 (QField 4) :

    QT_QPA_PLATFORM=offscreen python3 data-raw/qfield_modele.py limites
    QT_QPA_PLATFORM=offscreen python3 data-raw/qfield_modele.py detections

Chaque modele se regenere seul : un modele deja recette sur le terrain n'est
pas reecrit quand on touche a l'autre.

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
    QgsDefaultValue, QgsEditFormConfig, QgsEditorWidgetSetup, QgsExpression,
    QgsFeature, QgsOptionalExpression,
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
                           ("libelle", TEXTE), ("forme", TEXTE)]),
    ("constats", "Point", [("uuid", TEXTE), ("type_element", TEXTE),
                           ("element_id", TEXTE),
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
    ("etats", "NoGeometry", [("forme", TEXTE), ("valeur", TEXTE),
                             ("libelle", TEXTE)]),
]

# Le type d'element, puis les etats de chaque type, dans l'ordre du
# formulaire. Contrat avec SOMMIER_ETATS_PAR_FORME (R/registre2.R) : un test
# verifie que la table du modele et la constante disent la meme chose.
TYPES = [("Point (borne, signe…)", "point"), ("Ligne", "ligne"),
         ("Surface", "surface"), ("Hors plan", "hors_plan")]
ETATS_PAR_FORME = {
    "point": [("en_place", "En place"), ("endommage", "Endommagé"),
              ("non_retrouve", "Non retrouvé"), ("detruit", "Détruit"),
              ("inaccessible", "Inaccessible")],
    "ligne": [("visible", "Visible"),
              ("partiellement_visible", "Partiellement visible"),
              ("peu_visible", "Peu visible"), ("non_visible", "Non visible"),
              ("inaccessible", "Inaccessible")],
    "surface": [("conforme", "Conforme au plan"), ("modifiee", "Modifiée"),
                ("degradee", "Dégradée"), ("disparue", "Disparue"),
                ("inaccessible", "Inaccessible")],
    "hors_plan": [("hors_plan", "Hors plan")],
}
COUCHE_DE_FORME = {"point": "limites_elements_points",
                   "ligne": "limites_elements_lignes",
                   "surface": "limites_elements_surfaces"}

# « a_voir » : jamais vu, ou reste inaccessible. Les autres categories
# disent le dernier etat constate.
A_VISITER = [("a_voir", "À voir", "#D32F2F"),
             ("ancienne", "Vu il y a longtemps", "#F57C00"),
             ("vu", "Vu en place", "#388E3C"),
             ("defaut", "Vu, en défaut", "#FBC02D"),
             ("perdu", "Non retrouvé ou détruit", "#212121")]


def ecrire_gpkg(couches=COUCHES, gpkg=GPKG):
    if os.path.exists(gpkg):
        os.remove(gpkg)
    for nom, geometrie, champs in couches:
        fields = QgsFields()
        for champ, type_ in champs:
            fields.append(QgsField(champ, type_))
        options = QgsVectorFileWriter.SaveVectorOptions()
        options.driverName = "GPKG"
        options.layerName = nom
        options.actionOnExistingFile = (
            QgsVectorFileWriter.CreateOrOverwriteLayer if os.path.exists(gpkg)
            else QgsVectorFileWriter.CreateOrOverwriteFile)
        wkb = QgsWkbTypes.parseType(geometrie)
        writer = QgsVectorFileWriter.create(
            gpkg, fields, wkb, L93, QgsCoordinateTransformContext(), options)
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


def couche(nom, titre=None, gpkg=GPKG, prefixe="limites_"):
    c = QgsVectorLayer("%s|layername=%s" % (gpkg, nom), titre or nom, "ogr")
    if not c.isValid():
        sys.exit("Couche invalide : " + nom)
    # L'identifiant est le nom de la table, prefixe : stable d'une generation
    # a l'autre, et c'est par lui que `overlay_nearest()` designe la couche.
    # Le prefixe n'est pas decoratif : a la relecture, QGIS remplace par un
    # UUID tout identifiant sans tiret bas, et la relation se perd.
    c.setId(prefixe + IDENTIFIANTS.get(nom, nom))
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
    # Le voile se donne en « r,g,b,a » : QGIS lit un « #RRGGBBAA » comme
    # « #AARRGGBB », et un « à voir » rouge sortait bleu marine.
    r, g, b = (int(couleur[i:i + 2], 16) for i in (1, 3, 5))
    return QgsFillSymbol.createSimple(
        {"color": "%d,%d,%d,85" % (r, g, b), "outline_color": couleur,
         "outline_width": "0.5"})


def styler_elements(c, geometrie):
    categories = [QgsRendererCategory(valeur, symbole(geometrie, couleur),
                                      libelle)
                  for valeur, libelle, couleur in A_VISITER]
    c.setRenderer(QgsCategorizedSymbolRenderer("a_visiter", categories))
    etiqueter(c, "numero")
    c.setReadOnly(True)


def remplir_etats():
    etats = QgsVectorLayer("%s|layername=etats" % GPKG, "etats", "ogr")
    etats.startEditing()
    for forme, liste in ETATS_PAR_FORME.items():
        for valeur, libelle in liste:
            f = QgsFeature(etats.fields())
            f["forme"], f["valeur"], f["libelle"] = forme, valeur, libelle
            etats.addFeature(f)
    if not etats.commitChanges():
        sys.exit("Table des etats : " + str(etats.commitErrors()))


def etats_du_type():
    """L'expression vraie si l'etat est de la liste du type choisi."""
    return "CASE " + " ".join(
        "WHEN \"type_element\" = '%s' THEN \"etat\" IN (%s)" % (
            forme, ", ".join("'%s'" % v for v, _ in liste))
        for forme, liste in ETATS_PAR_FORME.items()) + " ELSE FALSE END"


def principal():
    ecrire_gpkg()
    remplir_etats()
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

    # La table des etats par type : la liste du formulaire.
    etats = couche("etats", "États par type d'élément")
    etats.setReadOnly(True)

    # --- Saisie : les constats -----------------------------------------
    constats = couche("constats", "Constats")
    constats.renderer().setSymbol(QgsMarkerSymbol.createSimple(
        {"name": "diamond", "color": "#1565C0", "size": "3.5",
         "outline_color": "#FFFFFF"}))
    idx = constats.fields().indexOf
    widget(constats, "uuid", "Hidden")
    defaut(constats, "uuid", "uuid('WithoutBraces')")

    # Le type d'abord : point, ligne, surface ou hors plan. Par defaut, celui
    # de l'element le plus proche, toutes formes confondues : la recette de
    # terrain, avec les bornes toujours prioritaires a 30 m, ne pouvait viser
    # que la borne. Il reste une priorite, courte : a 2 m d'une borne, on est
    # venu pour elle - a Loury, une borne au bord d'un cours d'eau avait le
    # contour de la surface a 38 cm. Calcule a la creation seulement : l'agent
    # le change d'un geste, et son choix tient.
    # Pour une surface, la distance a son contour : un point pris dedans en
    # serait sinon toujours a zero metre, et la surface gagnerait contre la
    # borne posee sur son bord. C'est d'ailleurs le contour que l'on constate.
    def distance(couche, contour=False):
        cible = "array_first(overlay_nearest('%s', $geometry, limit:=1, " \
                "max_distance:=30))" % couche
        if contour:
            cible = "boundary(%s)" % cible
        return "coalesce(distance($geometry, %s), 9999)" % cible
    defaut(constats, "type_element", (
        "with_variable('dp', %s, with_variable('dl', %s, with_variable('ds', %s, "
        "CASE WHEN @dp = 9999 AND @dl = 9999 AND @ds = 9999 THEN NULL "
        "WHEN @dp <= 2 OR (@dp <= @dl AND @dp <= @ds) THEN 'point' "
        "WHEN @dl <= @ds THEN 'ligne' ELSE 'surface' END)))") % (
            distance(COUCHE_DE_FORME["point"]),
            distance(COUCHE_DE_FORME["ligne"]),
            distance(COUCHE_DE_FORME["surface"], contour=True)))
    widget(constats, "type_element", "ValueMap",
           {"map": [{libelle: valeur} for libelle, valeur in TYPES]})
    constats.setFieldConstraint(idx("type_element"),
                                QgsFieldConstraints.ConstraintNotNull,
                                QgsFieldConstraints.ConstraintStrengthHard)

    # L'element, parmi ceux du type choisi : la liste est filtree, et le plus
    # proche du type a 30 m est propose. Un choix de l'agent est garde tant
    # qu'il est du bon type ; changer de type le remplace.
    widget(constats, "element_id", "ValueRelation", {
        "Layer": ancres.id(), "LayerName": ancres.name(),
        "Key": "id", "Value": "libelle", "OrderByValue": True,
        "AllowNull": True, "UseCompleter": True,
        "FilterExpression": "\"forme\" = current_value('type_element')"})
    defaut(constats, "element_id", (
        "CASE WHEN \"type_element\" IS NULL OR \"type_element\" = 'hors_plan' "
        "THEN NULL "
        "WHEN \"element_id\" IS NOT NULL AND attribute(get_feature("
        "'limites_elements', 'id', \"element_id\"), 'forme') = \"type_element\" "
        "THEN \"element_id\" " + " ".join(
            "WHEN \"type_element\" = '%s' THEN array_first(overlay_nearest("
            "'%s', \"id\", limit:=1, max_distance:=30))" % (forme, couche)
            for forme, couche in COUCHE_DE_FORME.items()) + " END"),
        a_la_mise_a_jour=True)
    constats.setConstraintExpression(
        idx("element_id"),
        "(\"type_element\" = 'hors_plan' AND \"element_id\" IS NULL) OR "
        "(\"type_element\" <> 'hors_plan' AND \"element_id\" IS NOT NULL)",
        "Un constat répond à un élément du plan, sauf « Hors plan ».")
    constats.setFieldConstraint(idx("element_id"),
                                QgsFieldConstraints.ConstraintExpression,
                                QgsFieldConstraints.ConstraintStrengthHard)

    # L'etat, parmi ceux du type : obligatoire, sans valeur vide, et vide de
    # nouveau si l'on change de type (un etat de borne n'a pas de sens pour
    # une ligne). « Hors plan » n'a qu'un etat, pose d'office.
    widget(constats, "etat", "ValueRelation", {
        "Layer": etats.id(), "LayerName": etats.name(),
        "Key": "valeur", "Value": "libelle", "OrderByValue": False,
        "AllowNull": False, "UseCompleter": False,
        "FilterExpression": "\"forme\" = current_value('type_element')"})
    defaut(constats, "etat", (
        "CASE WHEN \"type_element\" = 'hors_plan' THEN 'hors_plan' "
        "WHEN " + etats_du_type() + " THEN \"etat\" END"),
        a_la_mise_a_jour=True)
    constats.setFieldConstraint(idx("etat"),
                                QgsFieldConstraints.ConstraintNotNull,
                                QgsFieldConstraints.ConstraintStrengthHard)
    constats.setConstraintExpression(
        idx("etat"), etats_du_type(),
        "L'état doit être choisi dans la liste du type d'élément.")
    constats.setFieldConstraint(idx("etat"),
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
    for champ, alias in (("type_element", "Type d'élément"),
                         ("element_id", "Élément du plan"), ("etat", "État"),
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
                         foret, tampon, parcelles, photos, etats])

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
    for champ in ("type_element", "element_id", "etat", "visite_le",
                  "operateur", "precision_m", "source_gnss", "observations"):
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
    for c in (ancres, photos, etats):
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


# ===========================================================================
# Le projet des detections
# ===========================================================================

GPKG_D = os.path.join(SORTIE, "detections.gpkg")
QGS_D = os.path.join(SORTIE, "detections.qgs")

COUCHES_D = [
    ("detections", "MultiPolygon", [("id", TEXTE), ("numero", TEXTE),
                                    ("libelle", TEXTE), ("ug", TEXTE),
                                    ("source", TEXTE), ("nature", TEXTE),
                                    ("surface_ha", REEL),
                                    ("date_detection", DATE),
                                    ("description", TEXTE),
                                    ("contour", TEXTE)]),
    ("constats", "Point", [("uuid", TEXTE), ("detection_id", TEXTE),
                           ("etat", TEXTE), ("nature", TEXTE),
                           ("surface_ha", REEL), ("volume_m3", REEL),
                           ("visite_le", INSTANT), ("operateur", TEXTE),
                           ("precision_m", REEL), ("source_gnss", TEXTE),
                           ("observations", TEXTE)]),
    ("photos", "NoGeometry", [("uuid", TEXTE), ("constat_uuid", TEXTE),
                              ("fichier", TEXTE), ("prise_le", INSTANT)]),
    ("foret", "MultiPolygon", [("nom", TEXTE)]),
    ("ug", "MultiPolygon", [("numero", TEXTE)]),
    ("parcelles", "MultiPolygon", [("reference", TEXTE),
                                   ("designation", TEXTE)]),
]

# Les etats d'un constat, et leur couleur sur la carte.
ETATS_D = [("confirme", "Confirmé", "#C62828"),
           ("ecarte", "Écarté", "#757575"),
           ("non_vu", "Non vu", "#F57C00")]

# La nature retenue : SOMMIER_NATURES_PHENOMENE, dans cet ordre-la.
NATURES_D = [("Crise sanitaire (scolytes, dépérissement…)", "crise_sanitaire"),
             ("Sécheresse", "secheresse"), ("Chablis (tempête)", "tempete"),
             ("Neige", "neige"), ("Gel", "gel"), ("Incendie", "incendie"),
             ("Inondation", "inondation"),
             ("Dégâts de gibier", "degat_gibier"),
             ("Autre (coupe programmée…)", "autre")]

# La source de la detection, et sa couleur.
SOURCES_D = [("reconfort", "RECONFORT (dépérissement)", "#E65100"),
             ("sufosat", "SUFOSAT (coupe rase)", "#6A1B9A"),
             ("", "Autre source", "#1565C0")]


def detections():
    ecrire_gpkg(COUCHES_D, GPKG_D)
    projet = QgsProject.instance()
    projet.clear()
    projet.setFileName(QGS_D)
    projet.setCrs(L93)
    projet.setTitle("@@TITRE@@")
    projet.writeEntryBool("Paths", "/Absolute", False)

    def c_(nom, titre):
        return couche(nom, titre, GPKG_D, "detections_")

    # --- Donnees en lecture seule --------------------------------------
    detections_ = c_("detections", "Détections à vérifier")
    # Un voile translucide : l'ortho doit rester lisible dessous. La couleur
    # se donne en « r,g,b,a » - QGIS lit un « #RRGGBBAA » comme « #AARRGGBB ».
    def voile(couleur):
        r, g, b = (int(couleur[i:i + 2], 16) for i in (1, 3, 5))
        return QgsFillSymbol.createSimple(
            {"color": "%d,%d,%d,70" % (r, g, b), "outline_color": couleur,
             "outline_width": "0.6"})
    detections_.setRenderer(QgsCategorizedSymbolRenderer("source", [
        QgsRendererCategory(valeur, voile(couleur), libelle)
        for valeur, libelle, couleur in SOURCES_D]))
    etiqueter(detections_, "numero", 9)
    foret = c_("foret", "Forêt")
    foret.setRenderer(foret.renderer().__class__(QgsFillSymbol.createSimple(
        {"style": "no", "outline_color": "#1B5E20", "outline_width": "0.8"})))
    ug = c_("ug", "Unités de gestion")
    ug.setRenderer(ug.renderer().__class__(QgsFillSymbol.createSimple(
        {"style": "no", "outline_color": "#33691E", "outline_width": "0.3"})))
    etiqueter(ug, "numero", 8)
    parcelles = c_("parcelles", "Parcelles cadastrales")
    parcelles.setRenderer(parcelles.renderer().__class__(
        QgsFillSymbol.createSimple({"style": "no", "outline_color": "#9E9E9E",
                                    "outline_width": "0.2"})))
    for c in (detections_, foret, ug, parcelles):
        c.setReadOnly(True)

    # --- Saisie : les constats -----------------------------------------
    constats = c_("constats", "Constats")
    constats.setRenderer(QgsCategorizedSymbolRenderer("etat", [
        QgsRendererCategory(valeur, QgsMarkerSymbol.createSimple(
            {"name": "diamond", "color": couleur, "size": "3.5",
             "outline_color": "#FFFFFF"}), libelle)
        for valeur, libelle, couleur in ETATS_D]))
    champ = constats.fields().indexOf
    widget(constats, "uuid", "Hidden")
    defaut(constats, "uuid", "uuid('WithoutBraces')")
    widget(constats, "detection_id", "ValueRelation", {
        "Layer": detections_.id(), "LayerName": detections_.name(),
        "Key": "id", "Value": "libelle", "OrderByValue": True,
        "AllowNull": False, "UseCompleter": True})
    # La detection sous les pieds de l'agent, ou la plus proche a 100 m. Son
    # choix est garde : coalesce sur la valeur deja saisie.
    defaut(constats, "detection_id", (
        "coalesce(\"detection_id\","
        "array_first(overlay_nearest('detections_detections', \"id\", "
        "limit:=1, max_distance:=100)))"), a_la_mise_a_jour=True)
    constats.setFieldConstraint(champ("detection_id"),
                                QgsFieldConstraints.ConstraintNotNull,
                                QgsFieldConstraints.ConstraintStrengthHard)
    widget(constats, "etat", "ValueMap",
           {"map": [{libelle: valeur} for valeur, libelle, _ in ETATS_D]})
    constats.setFieldConstraint(champ("etat"),
                                QgsFieldConstraints.ConstraintNotNull,
                                QgsFieldConstraints.ConstraintStrengthHard)
    widget(constats, "nature", "ValueMap",
           {"map": [{libelle: valeur} for libelle, valeur in NATURES_D]})
    # La nature n'a de sens que pour une detection confirmee ; elle y est
    # exigee. C'est ce que la teledetection ne sait pas dire.
    constats.setConstraintExpression(
        champ("nature"),
        "coalesce(\"etat\", '') <> 'confirme' OR \"nature\" IS NOT NULL",
        "Une détection confirmée appelle sa nature : sanitaire, chablis, "
        "sécheresse, coupe programmée…")
    constats.setFieldConstraint(champ("nature"),
                                QgsFieldConstraints.ConstraintExpression,
                                QgsFieldConstraints.ConstraintStrengthHard)
    for nom in ("surface_ha", "volume_m3"):
        widget(constats, nom, "Range", {"AllowNull": True, "Min": 0.0,
                                        "Max": 100000.0, "Precision": 2,
                                        "Step": 0.1, "Style": "SpinBox"})
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
    config = constats.editFormConfig()
    for nom in ("precision_m", "source_gnss"):
        config.setReadOnly(champ(nom), True)
    constats.setEditFormConfig(config)
    widget(constats, "observations", "TextEdit", {"IsMultiline": True})
    for nom, alias in (("detection_id", "Détection"), ("etat", "État"),
                       ("nature", "Nature retenue"),
                       ("surface_ha", "Surface constatée (ha)"),
                       ("volume_m3", "Volume touché (m³)"),
                       ("visite_le", "Visite"), ("operateur", "Opérateur"),
                       ("precision_m", "Précision GNSS (m)"),
                       ("source_gnss", "Source GNSS"),
                       ("observations", "Observations")):
        constats.setFieldAlias(champ(nom), alias)

    # --- Saisie : les photos --------------------------------------------
    photos = c_("photos", "Photos")
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
    photos.setCustomProperty("QFieldSync/attachment_naming", json.dumps({
        "fichier": "'DCIM/detections_' || format_date(now(), 'yyyyMMdd_HHmmss_zzz') || '.{extension}'"}))

    projet.addMapLayers([constats, detections_, ug, foret, parcelles, photos])

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

    config = photos.editFormConfig()
    config.setLayout(QgsEditFormConfig.TabLayout)
    racine = config.invisibleRootContainer()
    racine.clear()
    consigne = QgsAttributeEditorTextElement("Consigne", racine)
    consigne.setText(
        "Une vue d'ensemble, puis le détail qui fonde le constat : houppiers "
        "secs, souches fraîches, trouée. Éviter les personnes et les "
        "véhicules : la photo est une pièce du sommier.")
    racine.addChildElement(consigne)
    for nom in ("fichier", "prise_le"):
        racine.addChildElement(QgsAttributeEditorField(
            nom, photos.fields().indexOf(nom), racine))
    photos.setEditFormConfig(config)

    # Formulaire des constats : la detection et l'etat ; ce qui a ete vu, si
    # la detection est confirmee ; la visite ; les photos.
    config = constats.editFormConfig()
    config.setLayout(QgsEditFormConfig.TabLayout)
    racine = config.invisibleRootContainer()
    racine.clear()
    for nom in ("detection_id", "etat"):
        racine.addChildElement(QgsAttributeEditorField(nom, champ(nom), racine))
    vu = QgsAttributeEditorContainer("Ce qui a été constaté", racine)
    vu.setType(Qgis.AttributeEditorContainerType.GroupBox)
    vu.setVisibilityExpression(QgsOptionalExpression(
        QgsExpression("\"etat\" = 'confirme'"), True))
    for nom in ("nature", "surface_ha", "volume_m3"):
        vu.addChildElement(QgsAttributeEditorField(nom, champ(nom), vu))
    racine.addChildElement(vu)
    for nom in ("visite_le", "operateur", "precision_m", "source_gnss",
                "observations"):
        racine.addChildElement(QgsAttributeEditorField(nom, champ(nom), racine))
    racine.addChildElement(QgsAttributeEditorRelation(relation, racine))
    constats.setEditFormConfig(config)

    ortho = QgsRasterLayer(
        "contextualWMSLegend=0&crs=EPSG:3857&dpiMode=7&format=image/jpeg"
        "&layers=ORTHOIMAGERY.ORTHOPHOTOS&styles=normal"
        "&tileMatrixSet=PM_0_19&url=https://data.geopf.fr/wmts?"
        "SERVICE%3DWMTS%26REQUEST%3DGetCapabilities",
        "Orthophotographie IGN (réseau)", "wms")
    projet.addMapLayer(ortho)
    leurre = os.path.join(SORTIE, "ortho.tif")
    ecrire_leurre(leurre)
    locale = QgsRasterLayer(leurre, "Orthophotographie (hors ligne)", "gdal")
    if not locale.isValid():
        sys.exit("Ortho locale invalide.")
    locale.setId("detections_ortho")
    projet.addMapLayer(locale)

    racine_arbre = projet.layerTreeRoot()
    noeud = racine_arbre.findLayer(photos.id())
    if noeud is not None:
        noeud.setItemVisibilityChecked(False)
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
        "Vérification sur le terrain des détections de télédétection "
        "(RECONFORT, SUFOSAT). Projet engendré par sommieR ; à ouvrir avec "
        "QField 4.3 ou plus récent. Les détections sont en lecture seule ; "
        "un constat par détection visitée, avec ses photos.")
    projet.setMetadata(metadonnees)

    if not projet.write():
        sys.exit("Ecriture du projet impossible.")
    if os.path.exists(QGS_D + "~"):
        os.remove(QGS_D + "~")
    for reste in (leurre, leurre + ".aux.xml"):
        if os.path.exists(reste):
            os.remove(reste)
    print("Ecrit :", QGS_D, "et", GPKG_D)


if __name__ == "__main__":
    modeles = sys.argv[1:] or ["limites", "detections"]
    QgsApplication.setPrefixPath("/usr", True)
    application = QgsApplication([], False)
    application.initQgis()
    try:
        for modele in modeles:
            {"limites": principal, "detections": detections}[modele]()
    finally:
        application.exitQgis()
        # QGIS ecrit les statistiques du leurre en se fermant.
        reste = os.path.join(SORTIE, "ortho.tif.aux.xml")
        if os.path.exists(reste):
            os.remove(reste)
