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

  Nom de l'operateur, propose par defaut a chaque saisie.

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

## See also

[`sommier_importer_qfield_travaux()`](https://pobsteta.github.io/sommieR/reference/sommier_importer_qfield_travaux.md)
