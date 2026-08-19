# Brief — Lot 1 : cartes à modèle constant

*Établi le 19 août 2026, à partir de l'état du dépôt en v0.5.0.*

## Pourquoi

Le rapport de gestion antérieure est aujourd'hui entièrement tabulaire. Or
une forêt se lit sur une carte : un gestionnaire qui reçoit « 34 m³ martelés
en 2022 » ne sait pas *où*, alors que le sommier le sait — chaque entrée porte
un `ug_uuid`, et chaque unité de gestion un contour daté.

Ce lot exploite **ce que le sommier possède déjà**, sans toucher au modèle de
données ni à la chaîne de hachage. Il sert aussi de banc d'essai à la mise en
page cartographique du document, avant les lots 2 et 3 qui, eux, engagent le
schéma et des données tierces.

## Ce qui existe

* `ug_geometrie` (`inst/sql/001_schema.sql:86`) : `MULTIPOLYGON` en EPSG:2154,
  **versionné et daté** (`version`, `date_debut`, `date_fin`). C'est la seule
  géométrie du sommier.
* `v_coupe` et `v_travaux` (`inst/sql/002_vues.sql`) portent `ug_uuid` : les
  volumes et les montants se rattachent donc à une unité sans jointure
  supplémentaire.
* `sommier_exporter_sig()` sait déjà lire la géométrie en vigueur à une date
  et la rendre en GeoJSON ou GeoPackage.

## Périmètre

Trois cartes, dans les trois chapitres qui ont quelque chose à montrer :

| Chapitre | Carte |
|---|---|
| 1 Identification | contour des unités de gestion, numérotées, avec leur surface |
| 2 Coupes et récoltes | unités teintées par volume martelé sur la période |
| 3 Travaux | unités teintées par montant de travaux sur la période |

**Hors périmètre, et volontairement** : les chapitres 1.1, 2.1, 5 et 9 n'ont
rien de spatial à porter. Une carte décorative dans un document réglementaire
coûte la confiance qu'elle prétend gagner ; on n'en met pas.

## Décisions de conception

1. **Les données de carte sont extraites avant le rendu**, comme le reste du
   rapport, et déposées dans le RDS que le document lit. La règle en vigueur
   ne change pas : aucun identifiant de connexion ne circule dans le document,
   et le rendu se rejoue des mois plus tard sur le même instantané.

2. **La géométrie voyage en WKT**, pas en GeoJSON. `sf::st_as_sfc()` a une
   méthode caractère pour le WKT ; lire une géométrie GeoJSON nue dépendrait
   du pilote GDAL. C'est le choix déjà retenu par `sommier_exporter_sig()`,
   et le RDS n'a pas à contenir un objet `sf` — il n'exige alors pas `sf` pour
   être relu.

3. **Lambert-93 conservé.** Une carte se mesure en mètres ; le document n'a
   pas besoin du WGS84, qui déformerait les surfaces et les distances.

4. **Le document reste rendable sans `sf`.** `sf` est en `Suggests` : s'il
   manque, ou si aucune unité n'a de contour connu, le chapitre affiche une
   phrase qui le dit et poursuit. Un rapport de gestion ne doit pas échouer
   parce qu'une illustration manque.

5. **Une unité sans géométrie est signalée, jamais inventée** — même règle que
   l'export SIG : la faire figurer sans contour créerait une entité fantôme,
   l'omettre en silence laisserait croire la forêt entièrement cartographiée.

6. **Choroplèthe à classes explicites.** L'échelle de teintes porte sa légende
   avec ses bornes chiffrées ; une carte teintée sans légende n'est qu'une
   impression.

## Livrables

* `sommier_geometrie_ug()` — contours en vigueur à une date, avec numéro
  d'affichage et surface calculée par PostGIS.
* `sommier_indicateurs_ug()` — par unité et sur une période : nombre
  d'entrées, volume martelé, surface coupée, montant et quantité de travaux.
* Les deux joints et déposés dans le RDS par `sommier_rapport_quarto()`.
* Trois blocs de carte dans `inst/quarto/gestion-anterieure.qmd`.
* Tests contre PostGIS : géométrie en vigueur à la date, unité sans contour,
  indicateurs nuls contre indicateurs absents.

## Critères d'acceptation

* Le document engendré sur le jeu de démonstration porte trois cartes.
* Une base sans aucune géométrie produit le même document, sans carte et avec
  la mention correspondante — et sans erreur.
* Les unités sans contour apparaissent nommément dans le document.
* Aucune modification de `entree_sommier`, des payloads, ni des empreintes :
  le lot est vérifiable en comparant les empreintes de tête avant et après.
