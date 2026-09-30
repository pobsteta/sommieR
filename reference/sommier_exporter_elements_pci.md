# Export des elements du plan cadastral en GeoPackage

Ecrit les elements de
[`sommier_elements_pci()`](https://pobsteta.github.io/sommieR/reference/sommier_elements_pci.md)
dans un GeoPackage, une couche par type de geometrie :
`elements_points`, `elements_lignes`, `elements_surfaces`.

## Usage

``` r
sommier_exporter_elements_pci(elements, chemin)
```

## Arguments

- elements:

  Tableau rendu par
  [`sommier_elements_pci()`](https://pobsteta.github.io/sommieR/reference/sommier_elements_pci.md).

- chemin:

  Fichier `.gpkg` de destination.

## Value

Invisiblement, le nombre d'elements ecrits par couche.

## Details

Trois couches plutot qu'une : un GeoPackage admet une couche a geometrie
mixte, mais QGIS et QField la lisent mal - la symbologie, les etiquettes
et la saisie supposent un seul type. Les attributs sont ceux du tableau,
en Lambert-93. Le fichier est remplace s'il existe, comme les autres
exports SIG : c'est une lecture du plan, pas une ecriture.

## Examples

``` r
# sommier_exporter_elements_pci(elements, "elements-pci.gpkg")
```
