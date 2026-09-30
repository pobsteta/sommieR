# Couches du PCI vecteur (EDIGEO)

Ce que le Plan Cadastral Informatise porte et que les livraisons GeoJSON
d'Etalab ecartent : les bornes, les signes de limite, et les details
topographiques - ponctuels, lineaires et surfaciques -, avec les cours
d'eau, les voies et les batiments.

## Usage

``` r
SOMMIER_COUCHES_PCI
```

## Details

Les noms sont ceux des couches EDIGEO, tels que le pilote de GDAL les
expose : `bornes` correspond a `BORNE_id`, `details` a `TLINE_id`,
`points` a `TPOINT_id`, `surfaces` a `TSURF_id`, `signes` a
`SYMBLIM_id`.
