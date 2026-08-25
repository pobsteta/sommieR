# Lecture d'une couche du PCI vecteur

Lit une couche EDIGEO sur les feuilles telechargees, restreinte a
l'emprise de la foret.

## Usage

``` r
sommier_fond_pci_lire(
  fond,
  couche = "bornes",
  emprise = NULL,
  marge_m = 100,
  symboles = NULL
)
```

## Arguments

- fond:

  Objet `sommier_fond_pci`.

- couche:

  L'une des noms de
  [SOMMIER_COUCHES_PCI](https://pobsteta.github.io/sommieR/reference/SOMMIER_COUCHES_PCI.md).

- emprise:

  Couche des unites de gestion, ou `data.frame` a colonne `wkt` en
  Lambert-93.

- marge_m:

  Marge autour de l'emprise, en metres.

- symboles:

  Vecteur nomme donnant la nature de chaque code `SYM`, par exemple
  `c("21" = "mur", "22" = "fosse")`. Il vous appartient : le paquet n'en
  embarque aucun tant qu'une source n'est pas citable.

## Value

Un `data.frame` : `feuille`, `objet`, `sym`, `nature`, `wkt`.

## Details

**La nature d'un detail n'est pas devinee.** `TLINE_id` porte un
attribut `SYM` qui distingue mur, fosse, haie et cloture, mais sa
nomenclature ne figure ni dans le `.DIC` ni dans le `.SCD` de l'archive
: elle appartient a la symbolisation du plan, publiee ailleurs. Le code
est donc rendu tel quel, et `symboles` permet de fournir la
correspondance. Sans elle, `nature` reste `NA` - un paquet dont l'objet
est la valeur probante ne peut pas afficher « fosse » la ou le terrain
montre un mur.

Le systeme de coordonnees vient de la **declaration du lot**. EDIGEO est
auto-descripteur : le fichier `.GEO` porte le referentiel employe
(`LAMB93` pour la metropole, `CC42` a `CC50` pour les livraisons
`edigeo-cc`). Le pilote de GDAL, lui, rend un proj4 sans code EPSG. On
lit donc la declaration a la source, et la sortie est ramenee en
Lambert-93 quel que soit le lot. Un referentiel non reconnu est signale
plutot que reinterprete - reprojeter au hasard poserait la feuille a
cote de la foret.

## Examples

``` r
# Necessite `sf` et un fond telecharge :
# sommier_fond_pci_lire(fond, "bornes")
```
