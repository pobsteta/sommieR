# Contours des unites de gestion

Rend, pour une foret, la geometrie en vigueur a une date de chaque unite
de gestion active, en WKT.

## Usage

``` r
sommier_geometrie_ug(con, foret_id, a_la_date = Sys.Date())
```

## Arguments

- con:

  Connexion DBI.

- foret_id:

  UUID de la foret.

- a_la_date:

  Date de reference (defaut : aujourd'hui).

## Value

Un `data.frame` : `uuid`, `numero_affichage`, `surface_ha` (calculee par
PostGIS sur le contour, `NA` faute de contour), `wkt`.

## Details

Seule la version de geometrie en vigueur a la date demandee est rendue :
`ug_geometrie` est versionnee, et le contour d'une unite change avec les
revisions d'amenagement. Une carte editee pour une periode passee doit
montrer le parcellaire de l'epoque, non celui d'aujourd'hui.

La geometrie sort en **WKT et en Lambert-93**, les deux volontairement.
Le WKT parce que
[`sf::st_as_sfc()`](https://r-spatial.github.io/sf/reference/st_as_sfc.html)
a une methode caractere pour lui, la ou lire une geometrie GeoJSON nue
dependrait du pilote GDAL ; le Lambert-93 parce qu'une carte se mesure
en metres, et que reprojeter ici deformerait les surfaces que la colonne
`surface_ha` annonce.

Une unite sans contour connu est **rendue avec un WKT `NA`** plutot
qu'omise : c'est a l'appelant de decider s'il la signale ou l'ignore, et
l'escamoter ici lui retirerait ce choix.

## See also

[`sommier_indicateurs_ug()`](https://pobsteta.github.io/sommieR/reference/sommier_indicateurs_ug.md),
[`sommier_exporter_sig()`](https://pobsteta.github.io/sommieR/reference/sommier_exporter_sig.md)

## Examples

``` r
# Necessite une connexion :
# sommier_geometrie_ug(con, foret)
```
