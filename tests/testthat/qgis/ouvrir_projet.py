"""Ouvre un projet engendre par sommier_projet_qfield() comme le ferait QGIS,
et rend en JSON ce que les tests verifient : couches valides, identifiants,
relation, et l'element que le formulaire proposerait pour chaque constat.

    QT_QPA_PLATFORM=offscreen python3 ouvrir_projet.py limites.qgs
"""
import json
import sys

from qgis.core import (QgsApplication, QgsExpression, QgsExpressionContext,
                       QgsExpressionContextUtils, QgsFeature, QgsProject)

QgsApplication.setPrefixPath("/usr", True)
application = QgsApplication([], False)
application.initQgis()
projet = QgsProject.instance()
resultat = {"lu": projet.read(sys.argv[1]), "titre": projet.title(),
            "couches": {}, "relations": [], "propositions": [],
            "variables": projet.customVariables()}
for identifiant, couche in projet.mapLayers().items():
    resultat["couches"][identifiant] = {
        "valide": couche.isValid(),
        "lecture_seule": couche.readOnly(),
        "objets": couche.featureCount() if hasattr(couche, "featureCount") else None,
    }
for relation in projet.relationManager().relations().values():
    resultat["relations"].append({"id": relation.id(), "valide": relation.isValid()})
constats = projet.mapLayer("limites_constats")
if constats is not None:
    expression = QgsExpression(constats.defaultValueDefinition(
        constats.fields().indexOf("element_id")).expression())
    def evaluer(entite):
        contexte = QgsExpressionContext(
            QgsExpressionContextUtils.globalProjectLayerScopes(constats))
        contexte.setFeature(entite)
        valeur = expression.evaluate(contexte)
        return valeur if valeur else None

    for saisi in constats.getFeatures():
        # Un constat neuf a cet endroit, puis le constat tel qu'il a ete saisi
        # (la valeur est reevaluee a chaque changement d'attribut).
        nouveau = QgsFeature(constats.fields())
        nouveau.setGeometry(saisi.geometry())
        resultat["propositions"].append({
            "uuid": saisi["uuid"], "propose": evaluer(nouveau),
            "reevalue": evaluer(saisi)})
application.exitQgis()
print("JSON:" + json.dumps(resultat))
