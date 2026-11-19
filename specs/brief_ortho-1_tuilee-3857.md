# Brief — L'ortho de la tournée en un fichier tuilé EPSG:3857, lisible sans réseau

*Établi le 27 octobre 2026 depuis le dépôt `surculus`, à partir de sommieR 0.38.0
(`f0229b9`). Décision de Pascal du 2026-10-27 (« 4 oui », `pilotage/journal.md`) ; cible (f)
de l'ADR 0009 de Surculus (`docs/adr/0009-carte-hors-ligne.md`), acceptée par Pascal le
2026-10-21. À déposer dans `specs/` de sommieR sous le nom `brief_ortho-1_tuilee-3857.md` (ou dans le domaine que la session sommieR jugera
juste, par exemple `travaux`).*

## Le constat

- `sommier_ortho_ign()` (`R/qfield.R` l. 469 et suivantes) télécharge l'ortho de l'IGN en
  **EPSG:2154** (`&CRS=EPSG:2154`, l. 493) et l'écrit en GeoTIFF ; `joindre_ortho()` (l. 360-363)
  la copie dans la tournée sous le nom **`ortho.tif`**.
- Surculus, comme Marculus et Groma, dessine sa carte avec osmdroid, en **Web Mercator
  (EPSG:3857)**, par tuiles. Il ne lit pas un GeoTIFF en Lambert 93.
- Depuis le 2026-10-27 (mission 055 de Surculus, décision de Pascal « exactement comme
  marculus »), Surculus ne précharge plus l'ortho de l'IGN : ses fonds IGN et OpenStreetMap se
  chargent **en ligne**. La seule ortho lisible **sans réseau** est l'« Ortho chantier » : un
  `ortho.mbtiles` ou un `ortho.gpkg` en EPSG:3857 dans le dossier de la tournée.
- Résultat aujourd'hui : **en forêt sans réseau, aucune ortho ne s'affiche** dans Surculus.

## Ce qui est demandé

1. Que la tournée produite pour Surculus (`sommier_projet_qfield_travaux()`) porte, à côté de
   `travaux.gpkg`, **un seul fichier tuilé en EPSG:3857** couvrant l'emprise de la tournée :
   au choix de sommieR :
   - `ortho.gpkg` : tuiles raster GeoPackage, `srs_id` 3857, grille
     `TILING_SCHEME=GoogleMapsCompatible` (lignes comptées depuis le nord) ;
   - ou `ortho.mbtiles` conforme à la spécification MBTiles, donc en **TMS** (lignes
     comptées depuis le sud). Un MBTiles en XYZ serait lu à l'envers par Surculus
     (`gpkg/.../OrthoTuilee.kt` l. 31 et 37).

   Zooms : **12 à 18**, ceux que Groma précharge (`ZoneTuiles.kt`, cité par l'ADR 0009 de
   Surculus) ; Surculus agrandit lui-même au-delà.
2. Que ce fichier **remplace** `ortho.tif` (cible (f) de l'ADR 0009 : un seul fichier, lu par
   QField et par Surculus), si QField le lit aussi ; sinon qu'il s'y ajoute, et que sommieR dise
   lequel des deux QField utilise.
3. L'attribution de l'IGN et la date de la prise de vue dans les métadonnées du fichier
   (table `metadata` du MBTiles, ou description de la table du GPKG). Surculus ne l'affiche pas
   encore pour l'Ortho chantier : il le fera de son côté (Licence Ouverte : mention de la
   source).

## Ce que Surculus en fera

- Il propose l'« Ortho chantier » dans son menu « Fond de carte » et **ouvre la carte dessus**
  tant que l'utilisateur n'a pas choisi un autre fond (décisions de Pascal du 2026-10-27).
- Lecture déjà écrite (`FichierOrtho`, mission 055) : il suffit que le fichier existe.

## Ce qui n'est pas demandé

- Aucun changement de `travaux.gpkg` ni de l'import.
- Aucun préchargement côté Surculus.


---

## Complément du 2026-10-29 : métadonnées (issue #68)

*Brief `2026-10-29-ortho-metadonnees`, de Surculus (mission 059), décision de Pascal du 2026-10-29. Précise le point 3 ci-dessus.*

Dans `metadata` de `ortho.mbtiles` : `attribution` (source, licence comprise si elle doit s'afficher ; clé de la spécification MBTiles 1.3) et `date_mise_a_jour` (AAAA-MM-JJ ; convention sommieR/Surculus, hors norme MBTiles). Exemple : « © IGN, BD ORTHO®, Géoplateforme, Licence Ouverte 2.0 » et « 2026-10-27 ». Surculus affiche « Ortho chantier · <attribution> · mise à jour le <date> » ; sans date il n'ajoute rien, sans attribution il écrit « source non indiquée par le fichier », et il n'ajoute jamais la licence de lui-même. Si sommieR change le nom de la clé de date, répondre dans `~/dev/briefs/vers-surculus/`.

## Ce que sommieR a réalisé (0.43.0, mission 025)

- `ortho.mbtiles` (MBTiles, TMS, tuiles PNG), EPSG:3857, zooms 12 à 18 : l'emprise est calée sur les tuiles du zoom 12 pour que la pyramide descende jusque-là ; fond transparent ; tuiles vides non écrites. Il remplace `ortho.tif` dans la tournée des travaux seulement (QField lit le MBTiles par GDAL).
- Métadonnées `attribution` (« © IGN, BD ORTHO®, Géoplateforme, Licence Ouverte 2.0 ») et `date_mise_a_jour` (AAAA-MM-JJ ; le nom de la clé ne change pas). La date est celle du GeoTIFF, écrit au téléchargement.
- Code : `R/ortho_tuilee.R` ; test : `tests/testthat/test-ortho-tuilee.R`.
