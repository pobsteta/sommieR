# Codes des travaux sylvicoles

La nomenclature fermee des travaux du registre 6, celle du brief metier
du suivi sylvicole : le code qu'on agrege, a cote du libelle libre de
l'A50J. Chaque code fixe sa famille, les unites admises pour sa quantite
et les formes admises pour sa geometrie (`point`, `ligne`, `surface`).
Une plantation se mesure en hectares, ses plants dans `nb_plants`.

## Usage

``` r
SOMMIER_CODES_TRAVAUX
```

## Format

Un `data.frame` : `code`, `famille`, `libelle`, `unites` et `formes`
(une ou plusieurs valeurs, separees par une virgule).

## See also

[`registre6_travaux()`](https://pobsteta.github.io/sommieR/reference/registre6_travaux.md)
