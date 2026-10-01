# Coupes rases detectees par SUFOSAT, par unite et par annee

Agrege les rasters SUFOSAT - date de coupe (`AAJJJ`) et probabilite
(%) - par unite de gestion et par annee : surface detectee, date
mediane, probabilite moyenne.

## Usage

``` r
sommier_coupes_sufosat(
  dates,
  proba,
  emprise,
  seuil_proba = 90,
  surface_min_ha = 0.5
)
```

## Arguments

- dates, proba:

  Rasters SUFOSAT des dates (`AAJJJ`) et des probabilites (%), en
  Lambert-93, meme grille.

- emprise:

  Couche des unites de gestion
  ([`sommier_couche_ug()`](https://pobsteta.github.io/sommieR/reference/sommier_couche_ug.md)).

- seuil_proba:

  Probabilite minimale d'un pixel, en %.

- surface_min_ha:

  Surface minimale d'une detection, par unite et par annee.

## Value

Un `data.frame` : `ug`, `annee`, `surface_ha`, `date_mediane`, `debut`,
`fin`, `proba_moyenne`.

## Details

**Une detection, pas un constat.** SUFOSAT voit un couvert disparaitre ;
il ne dit pas si c'est une coupe de regeneration, une coupe sanitaire ou
un chablis. Le rapport s'en sert pour signaler une coupe qu'aucun
martelage n'explique (argument `coupes_detectees` de
[`sommier_rapport_quarto()`](https://pobsteta.github.io/sommieR/reference/sommier_rapport_quarto.md)),
et
[`sommier_importer_detections()`](https://pobsteta.github.io/sommieR/reference/sommier_importer_detections.md)
peut l'inscrire au registre 8 comme detection a verifier.

**Les petites surfaces sont ecartees.** Sous `surface_min_ha`, une
detection tient plus du liseret de lisiere que de la coupe. SUFOSAT
repose sur Sentinel-2 : il ne dit rien d'avant 2018.

La lecture passe par GDAL (via `sf`), sans autre dependance.
