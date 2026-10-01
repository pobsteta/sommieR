"""Ouvre un projet engendre par sommier_projet_qfield() ou
sommier_projet_qfield_detections() comme le ferait QGIS, et rend en JSON ce
que les tests verifient : couches valides, identifiants, relation, l'element
ou la detection que le formulaire proposerait pour chaque constat, et les
champs dont il refuserait la saisie.

    QT_QPA_PLATFORM=offscreen python3 ouvrir_projet.py limites.qgs
"""
import json
import sys

from qgis.core import (QgsApplication, QgsExpression, QgsExpressionContext,
                       QgsExpressionContextUtils, QgsFeature,
                       QgsFieldConstraints, QgsProject, QgsVectorLayerUtils)

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
# Le projet des limites propose un element, celui des detections une
# detection.
constats, cle = projet.mapLayer("limites_constats"), "element_id"
if constats is None:
    constats, cle = projet.mapLayer("detections_constats"), "detection_id"
if constats is not None:
    expression = QgsExpression(constats.defaultValueDefinition(
        constats.fields().indexOf(cle)).expression())
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
        # Les contraintes du formulaire, sur le constat tel qu'il a ete saisi.
        refus = [constats.fields().at(i).name()
                 for i in range(constats.fields().count())
                 if not QgsVectorLayerUtils.validateAttribute(
                     constats, saisi, i,
                     QgsFieldConstraints.ConstraintStrengthHard)[0]]
        resultat["propositions"].append({
            "uuid": saisi["uuid"], "propose": evaluer(nouveau),
            "reevalue": evaluer(saisi), "refus": refus})
application.exitQgis()
print("JSON:" + json.dumps(resultat))
