# Parcelles du jeu de demonstration

Les trois parcelles cadastrales de la fixture Couchey de `nemetonshiny`,
reprises a l'identique : memes identifiants, memes contenances, memes
contours. Les deux paquets decrivent ainsi le meme terrain, ce qui
permet de rapprocher un sommier des indicateurs nemeton calcules dessus.

## Usage

``` r
SOMMIER_PARCELLES_COUCHEY
```

## Format

`data.frame` de 3 lignes : `numero`, `geo_parcelle`, `section`,
`contenance_m2`, `surface_ha`, `wkt_4326`.

## Details

La fixture d'origine se decrit elle-meme comme « 3 mock cadastral
parcels » : la geometrie et les identifiants sont plausibles et situes
dans Couchey, mais ce ne sont pas des donnees cadastrales officielles.
Le code INSEE 21200 y est documente comme verifie contre geo.api.gouv.fr
et IGN ADMINEXPRESS, apres correction d'une valeur anterieure erronee
(21189, qui designe Corberon).

Les contours sont en WGS84 (EPSG:4326) comme dans la fixture ; ils sont
reprojetes en Lambert-93 a l'insertion, le schema du sommier stockant en
EPSG:2154.

## Examples

``` r
SOMMIER_PARCELLES_COUCHEY[, c("geo_parcelle", "surface_ha")]
#>    geo_parcelle surface_ha
#> 1 21200000A0054        2.5
#> 2 21200000A0055        1.8
#> 3 21200000A0056        3.2
```
