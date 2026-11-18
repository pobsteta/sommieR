# Parcelles du jeu de demonstration de Marsannay

Trois parcelles de la foret communale de Marsannay-la-Cote (Cote-d'Or,
INSEE 21390), a la foret ONF `F21866Z`, avec leurs references, leurs
contenances et leurs contours **reels** : ceux du cadastre de la DGFiP
(livraison etalab), reperes par l'ONF comme appartenant a la foret
`F21866Z` ; proprietaire « Commune ». Les references sont sur quatorze
caracteres (`213900000A0033`).

## Usage

``` r
SOMMIER_PARCELLES_MARSANNAY
```

## Format

Un `data.frame` de trois lignes : `numero`, `geo_parcelle`, `section`,
`contenance_m2`, `surface_ha`, `ugf`, `wkt_4326`.

## Source

Cadastre DGFiP (etalab) ; parcellaire de la foret `F21866Z` (ONF),
extraits le 2026-10-15.

## Details

Comme pour
[SOMMIER_PARCELLES_COUCHEY](https://pobsteta.github.io/sommieR/reference/SOMMIER_PARCELLES_COUCHEY.md),
les contours sont authentiques et les ecritures que
[`sommier_demo_marsannay()`](https://pobsteta.github.io/sommieR/reference/sommier_demo_marsannay.md)
inscrit dessus sont inventees. Les trois parcelles se touchent, la A 33
et la A 34 par un cote commun. `ugf` est le numero de l'unite de gestion
fonciere de l'ONF.

## See also

[`sommier_demo_marsannay()`](https://pobsteta.github.io/sommieR/reference/sommier_demo_marsannay.md)

## Examples

``` r
SOMMIER_PARCELLES_MARSANNAY[, c("geo_parcelle", "surface_ha")]
#>     geo_parcelle surface_ha
#> 1 213900000A0033     3.0875
#> 2 213900000A0034     3.5375
#> 3 213900000A0039     6.4700
```
