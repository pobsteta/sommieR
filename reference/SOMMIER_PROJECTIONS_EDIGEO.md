# Projections declarees par les lots EDIGEO

Correspondance entre le code de reference porte par le fichier `.GEO`
d'une archive EDIGEO et le code EPSG de la projection.

## Usage

``` r
SOMMIER_PROJECTIONS_EDIGEO
```

## Details

EDIGEO est auto-descripteur : le lot declare son referentiel dans son
fichier `.GEO`, sous la forme `RELSA06:LAMB93` pour la metropole. On le
lit donc plutot que de reconnaitre une chaine proj4 - la declaration est
l'intention du producteur, le proj4 n'en est qu'une traduction par le
pilote, et elle arrive sans code EPSG.

Les livraisons `edigeo-cc` declarent une conique conforme par zone, de
CC42 a CC50, soit les codes EPSG 3942 a 3950.
