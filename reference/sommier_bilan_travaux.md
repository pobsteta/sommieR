# Bilan des travaux : cout a l'hectare et ecart au prevu

Rend ce que les travaux ont coute, unite par unite et famille par
famille, rapporte a la surface de l'unite ; et, annee par annee, les
hectares traites selon qu'ils etaient prevus, reportes ou non prevus.

## Usage

``` r
sommier_bilan_travaux(con, foret_id, debut = NULL, fin = NULL)
```

## Arguments

- con:

  Connexion DBI.

- foret_id:

  UUID de la foret.

- debut, fin:

  Bornes de la periode, sur la date de l'intervention.

## Value

Une liste : `cout` (`ug`, `famille`, `montant_eur`, `surface_ug_ha`,
`cout_ha_eur`, `n`), `prevu` (`annee`, `prevu`, `hectares`, `n`,
`n_sans_hectares`), et `hors_ug_eur` (montant des travaux hors unite).

## Details

**La famille** vient du code
([SOMMIER_CODES_TRAVAUX](https://pobsteta.github.io/sommieR/reference/SOMMIER_CODES_TRAVAUX.md))
; une intervention sans code, inscrite avant la v0.28.0, est rangee "non
codee".

**Le cout a l'hectare** rapporte le montant cumule d'une unite a la
surface de son contour en vigueur. Les travaux hors unite de gestion
(une desserte) sont comptes a part, sans hectare.

**Les hectares** d'une intervention sont sa quantite quand elle est en
hectares, a defaut l'aire de sa geometrie quand c'en est une surface ;
une intervention mesuree autrement (des metres de cloture, des tiges)
n'en a pas, et le dit.

## See also

[`sommier_suivi_plantations()`](https://pobsteta.github.io/sommieR/reference/sommier_suivi_plantations.md)
