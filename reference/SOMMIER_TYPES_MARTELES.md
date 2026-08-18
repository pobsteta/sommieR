# Types d'entree imputables a la balance de possibilite

La balance A50E confronte a la possibilite les **volumes marteles**,
soit les coupes et les produits accidentels. `coupe_realisee` en est
exclu a dessein : la meme coupe est d'abord martelee (imprime A50E) puis
exploitee (imprime A50F), l'imputer deux fois doublerait le prelevement
constate.

## Usage

``` r
SOMMIER_TYPES_MARTELES
```

## Format

An object of class `character` of length 3.

## See also

[`sommier_balance_possibilite()`](https://pobsteta.github.io/sommieR/reference/sommier_balance_possibilite.md)
