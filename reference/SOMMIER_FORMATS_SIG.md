# Formats d'export cartographique

`geojson` n'exige rien de plus que PostGIS : la geometrie est rendue par
`ST_AsGeoJSON` et assemblee en R. `gpkg` passe par le paquet `sf`, qui
doit etre installe.

Le brief prevoit a terme un GeoPackage accompagne du manifeste
([`sommier_exporter_manifeste()`](https://pobsteta.github.io/sommieR/reference/sommier_exporter_manifeste.md)).
Le GeoJSON est propose en plus parce qu'il ne demande aucune dependance
: un destinataire peut ouvrir l'export sans installer quoi que ce soit,
ce qui sert le « partage sans confiance » recherche.

## Usage

``` r
SOMMIER_FORMATS_SIG
```

## Format

An object of class `character` of length 2.
