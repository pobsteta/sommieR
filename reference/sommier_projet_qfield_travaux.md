# Projet QField pour les travaux et le suivi des plantations

Ecrit un dossier autonome - un projet QGIS, un GeoPackage et un dossier
`DCIM/` vide - que l'on copie sur le telephone ou la tablette et que
l'on ouvre avec QField. On y releve les travaux faits, chacun dessine en
surface, en ligne ou en point selon son code, on y installe des
placettes de suivi et on y saisit leurs controles.

## Usage

``` r
sommier_projet_qfield_travaux(
  con,
  foret_id,
  dossier,
  operateur,
  fond = NULL,
  ortho = NULL,
  programme = NULL,
  depot = NULL
)
```

## Arguments

- con:

  Connexion DBI.

- foret_id:

  UUID de la foret.

- dossier:

  Dossier a creer. Il ne doit pas exister : une tournee non rapatriee ne
  doit jamais etre ecrasee.

- operateur:

  Nom de l'operateur, propose par defaut a chaque saisie.

- fond:

  Parcellaire cadastral pour se reperer, tel que le rend
  [`sommier_fond_lire()`](https://pobsteta.github.io/sommieR/reference/sommier_fond_lire.md)
  (facultatif).

- ortho:

  GeoTIFF d'orthophotographie a joindre au projet, tel que l'ecrit
  [`sommier_ortho_ign()`](https://pobsteta.github.io/sommieR/reference/sommier_ortho_ign.md)
  (facultatif). Il est converti en un seul fichier `ortho.mbtiles`,
  tuile en EPSG:3857 (zooms 12 a 18, tuiles PNG, fond hors emprise
  transparent), avec `attribution` et `date_mise_a_jour` (AAAA-MM-JJ, la
  date du GeoTIFF) dans sa table `metadata`. Il remplace `ortho.tif` :
  QField et Surculus le lisent sans reseau. Necessite `sf` et `RSQLite`.

- programme:

  Chemin du `<projet>-programme-travaux.gpkg` de nemetonshiny
  (facultatif), lu par
  [`sommier_lire_programme_travaux()`](https://pobsteta.github.io/sommieR/reference/sommier_lire_programme_travaux.md)
  : ses actions sont versees dans la table `programme` du projet, et
  l'import refuse un `action_id` saisi qui n'y figure pas.

- depot:

  Repertoire du depot de photos (facultatif). S'il est donne, la tournee
  emporte les photos du **dernier controle de chaque placette**, pour
  que l'agent les voie au passage suivant : les fichiers sous
  `DCIM/<uuid>.<extension>`, une ligne de la couche `photos` par photo
  (rattachee au controle precedent, qui n'est pas dans la tournee). Une
  photo absente du depot ou alteree (empreinte differente) n'est pas
  versee, et un avertissement le dit. Ces lignes restent telles quelles
  au retour : elles ne rattachent aucune photo a un controle de la
  tournee, donc l'import ne les redepose jamais. **Elles ne sont
  visibles que pour Surculus**, qui lit la couche `photos` ; la relation
  `photos_du_controle` de QField, elle, ne montre que les photos des
  controles de la tournee. La couche `photos_terrain` n'est **pas**
  ecrite a l'aller : c'est Surculus qui la cree.

## Value

Invisiblement, le chemin du projet `.qgs`.

## Details

**Un troisieme projet**, a cote de ceux des limites et des detections,
sur le meme principe : le modele a ete produit une fois par QGIS
(`data-raw/qfield_modele.py`), cette fonction le copie et en remplit les
couches.

**Les codes viennent de
[SOMMIER_CODES_TRAVAUX](https://pobsteta.github.io/sommieR/reference/SOMMIER_CODES_TRAVAUX.md)**,
ecrits a chaque projet : la couche des surfaces ne propose que les codes
qui admettent une surface, et l'unite par defaut est la premiere du
code.

**Les placettes deja installees sont dans le projet**, colorees selon
leur dernier controle : besoin signale, sans besoin, jamais controlee.
On les controle en ajoutant un controle a la placette ; on en installe
une nouvelle en placant un point, rattache a des travaux de la liste des
travaux suivis (ceux d'une unite de gestion).

**Le champ `action_id`** des trois couches de travaux est celui de
l'action du programme que le travaux realise : l'operateur la choisit
dans la liste tiree du programme (table `programme`). Elle passe telle
quelle au registre 6.

**La couche `photos_terrain`** est celle de Surculus (`docs/spec.md` §
5, amendee le 2026-10-28) : POINT, une ligne par photo, `photo_uuid` (=
`photos.uuid`), `sujet` (`placette` ou `plant`), `placette_uuid`,
`plant_uuid`, `azimut_visee_mag_deg`, `declinaison_deg`,
`modele_geomagnetique`, `precision_m`, `source_gnss`,
`referentiel_source` (`RGF93` ou `WGS84`), `age_fix_ms`, `simulee`,
`sha256`.
[`sommier_importer_qfield_travaux()`](https://pobsteta.github.io/sommieR/reference/sommier_importer_qfield_travaux.md)
la lit au retour, si elle est presente, et refuse la tournee d'une
couche aux colonnes manquantes (`photo_uuid`, `sujet`, `sha256`) ou
inattendues.

**La symbologie est celle de Marculus** (brief du 2026-10-16) :
parcelles coloriees par proprietaire (remplissage a 20 %, contour plein,
numero de la parcelle au centre ; gris-vert sans proprietaire),
houppiers en contour seul masques par defaut, desserte ocre. Les
couleurs sont dans une seule liste interne (`SYMBOLOGIE_MARCULUS`,
`R/symbologie_travaux.R`).

## See also

[`sommier_importer_qfield_travaux()`](https://pobsteta.github.io/sommieR/reference/sommier_importer_qfield_travaux.md)
