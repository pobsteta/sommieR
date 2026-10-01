# Projet QGIS/QField pour verifier les detections sur le terrain

Ecrit un dossier autonome - un projet QGIS, un GeoPackage et un dossier
`DCIM/` vide - que l'on copie sur le telephone ou la tablette et que
l'on ouvre avec QField. On y trouve les detections en attente au
registre 8, chacune dessinee par les pixels qui l'ont produite, et une
couche ou saisir un constat par detection visitee, avec ses photos.

## Usage

``` r
sommier_projet_qfield_detections(
  con,
  foret_id,
  dossier,
  operateur,
  reconfort = NULL,
  sufosat = NULL,
  fond = NULL,
  ortho = NULL
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

  Nom de l'operateur, propose par defaut dans chaque constat.

- reconfort, sufosat:

  Rasters des detections, pour en dessiner les contours : voir
  [`sommier_contours_detections()`](https://pobsteta.github.io/sommieR/reference/sommier_contours_detections.md)
  (facultatifs).

- fond:

  Parcellaire cadastral pour se reperer, tel que le rend
  [`sommier_fond_lire()`](https://pobsteta.github.io/sommieR/reference/sommier_fond_lire.md)
  (facultatif).

- ortho:

  GeoTIFF d'orthophotographie a joindre au projet, tel que l'ecrit
  [`sommier_ortho_ign()`](https://pobsteta.github.io/sommieR/reference/sommier_ortho_ign.md)
  (facultatif).

## Value

Invisiblement, le chemin du projet `.qgs`.

## Details

**Un projet a part de celui des limites**, sur le meme principe : le
modele a ete produit une fois par QGIS (`data-raw/qfield_modele.py`),
cette fonction le copie et en remplit les couches.

**Les detections sont numerotees** D01, D02... par surface decroissante,
et portent un libelle - unite, source, surface, date - que le formulaire
montre. Leur contour est un decor, recalcule par
[`sommier_contours_detections()`](https://pobsteta.github.io/sommieR/reference/sommier_contours_detections.md)
depuis les rasters fournis ; sans raster, c'est l'unite entiere.

**Le formulaire.** Un nouveau constat propose la detection sous les
pieds de l'agent, ou la plus proche a 100 m, et remplit la date,
l'operateur, la precision et la source GNSS. L'etat - confirme, ecarte,
non vu - doit etre choisi. Une detection confirmee demande sa nature :
crise sanitaire, chablis, secheresse, coupe programmee... C'est ce que
la teledetection ne sait pas dire. La surface et le volume constates
sont facultatifs.

## See also

[`sommier_importer_qfield_detections()`](https://pobsteta.github.io/sommieR/reference/sommier_importer_qfield_detections.md),
[`sommier_inscrire_coupes_sufosat()`](https://pobsteta.github.io/sommieR/reference/sommier_inscrire_coupes_sufosat.md),
[`sommier_projet_qfield()`](https://pobsteta.github.io/sommieR/reference/sommier_projet_qfield.md)
pour les limites.
