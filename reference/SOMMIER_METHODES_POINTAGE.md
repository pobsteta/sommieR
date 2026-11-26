# Methodes de pointage d'un plant

Comment la position d'un plant a ete obtenue, en quatre valeurs fermees,
**propres a sommieR** (definies le 2026-11-25, mission 065 ; Surculus
n'a pas ce vocabulaire) : `relatif_boussole` et `relatif_saisie` (le
plant est pointe **relativement au piquet** de la placette ; l'azimut
vient de la boussole du telephone ou est saisi), `gnss_plant` (position
GNSS prise sur le plant lui-meme) et `construit` (position de
demonstration ou reconstituee, jamais mesuree). La seule trace voisine
chez Surculus est `source_azimut` (`boussole_telephone` ou `saisie`,
`docs/formats/journal-valeurs-v1.md`).

## Usage

``` r
SOMMIER_METHODES_POINTAGE
```

## Format

An object of class `character` of length 4.

## See also

[`registre6_plant()`](https://pobsteta.github.io/sommieR/reference/registre6_plant.md)
