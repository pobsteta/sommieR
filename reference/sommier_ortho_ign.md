# Orthophotographie de l'IGN sur l'emprise d'une foret

Telecharge, sur l'emprise de la foret elargie de `marge_m`, un extrait
de l'orthophotographie de l'IGN (Geoplateforme, service WMS), et l'ecrit
en GeoTIFF Lambert-93. C'est le fond hors ligne du projet QField : en
foret, le reseau manque souvent.

## Usage

``` r
sommier_ortho_ign(
  emprise,
  chemin,
  resolution_m = 0.5,
  marge_m = 100,
  couche = "ORTHOIMAGERY.ORTHOPHOTOS",
  service = SOMMIER_SOURCE_ORTHO
)
```

## Arguments

- emprise:

  Couche des unites de gestion
  ([`sommier_couche_ug()`](https://pobsteta.github.io/sommieR/reference/sommier_couche_ug.md)),
  ou `data.frame` a colonne `wkt` en Lambert-93.

- chemin:

  Fichier `.tif` a ecrire. Il ne doit pas exister.

- resolution_m:

  Taille du pixel, en metres.

- marge_m:

  Marge autour de l'emprise, en metres.

- couche:

  Couche WMS a extraire : l'ortho en couleurs par defaut,
  `"ORTHOIMAGERY.ORTHOPHOTOS.IRC"` pour l'infrarouge, qui distingue
  mieux feuillus et resineux.

- service:

  Adresse du service WMS.

## Value

Invisiblement, `chemin`.

## Details

Le telechargement est explicite, comme celui du fond cadastral : ni le
projet ni le rapport n'en declenchent. La couche par defaut est
`ORTHOIMAGERY.ORTHOPHOTOS`, la mosaique la plus recente ; le service ne
dit pas la date de prise de vue de chaque dalle. Donnee de l'IGN, sous
Licence Ouverte ; un decor, jamais une ecriture.

A 0,5 m, une foret de trois kilometres de cote tient en une dizaine de
megaoctets (compression JPEG). GDAL, deja la par `sf`, decoupe la
requete en dalles.

## See also

[`sommier_projet_qfield()`](https://pobsteta.github.io/sommieR/reference/sommier_projet_qfield.md)

## Examples

``` r
# Necessite un acces reseau :
# sommier_ortho_ign(sommier_couche_ug(con, foret), "ortho.tif")
```
