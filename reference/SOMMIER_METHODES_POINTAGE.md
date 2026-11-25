# Methodes de pointage d'un plant

Comment la position d'un plant a ete obtenue, en quatre valeurs fermees,
reprises de Surculus : `relatif_boussole` et `relatif_saisie` (le plant
est pointe **relativement au piquet** de la placette, ADR 0003 de
Surculus ; l'azimut vient de la boussole du telephone ou est saisi :
`source_azimut` = `boussole_telephone` ou `saisie` dans
`docs/formats/journal-valeurs-v1.md`), `gnss_plant` (position GNSS prise
sur le plant lui-meme) et `construit` (position de demonstration ou
reconstituee, jamais mesuree).

## Usage

``` r
SOMMIER_METHODES_POINTAGE
```

## Format

An object of class `character` of length 4.

## See also

[`registre6_plant()`](https://pobsteta.github.io/sommieR/reference/registre6_plant.md)
