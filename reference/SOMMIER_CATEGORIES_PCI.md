# Elements du plan cadastral retenus pour le suivi des limites

Les categories d'elements physiques que
[`sommier_elements_pci()`](https://pobsteta.github.io/sommieR/reference/sommier_elements_pci.md)
va chercher dans le PCI vecteur, avec le prefixe de leur numero court.

## Usage

``` r
SOMMIER_CATEGORIES_PCI
```

## Details

Ne sont retenues que les couches qui materialisent quelque chose sur le
terrain. `PARCELLE`, `SECTION`, `SUBDSECT`, `SUBDFISC`, `COMMUNE`,
`LIEUDIT` et `NUMVOIE` decoupent ou nomment le territoire sans rien
poser au sol ; la couche `ID_S_OBJ_Z_1_2_2` ne porte que la position des
etiquettes des numeros de parcelle. On les ecarte.

L'ordre des lignes est celui des tableaux du rapport : les bornes et les
signes de limite d'abord, qui disent la limite elle-meme, puis les
details qui la jalonnent.
