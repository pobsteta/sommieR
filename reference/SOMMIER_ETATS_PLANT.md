# Etats d'un plant a un controle

La nomenclature du DSF (`etats-plants.yaml` de Surculus, DSF 2024 p. 8)
: `sain`, `atteint`, `mort`, `absent` ; plus `non_observe`, qui n'est
pas un etat mais une absence de mesure : le plant pointe n'a pas ete
retrouve ce jour-la. Il sort des totaux du controle et reste a chercher
au passage suivant. Un plant `atteint` compte comme vivant.

## Usage

``` r
SOMMIER_ETATS_PLANT
```

## Format

An object of class `character` of length 5.

## See also

[`registre6_controle()`](https://pobsteta.github.io/sommieR/reference/registre6_controle.md)
