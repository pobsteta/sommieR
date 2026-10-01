# Indices d'un projet nemeton, par unite

Lit les indicateurs qu'un projet nemeton a calcules pour ses unites de
gestion (`data/indicators.parquet`) et en rend ceux qui eclairent la
possibilite : le volume sur pied, la part recente en coupe rase.

## Usage

``` r
sommier_lire_indices_nemeton(projet)
```

## Arguments

- projet:

  Dossier du projet nemeton (celui qui contient `data/`).

## Value

Un `data.frame` : `ug_id`, `libelle`, `numero`, `surface_ha`,
`volume_m3_ha` (P1), `coupe_rase_5ans_pct` (T3), `cadastral_refs`.
Attributs `date_calcul` et `source`.

## Details

**Des estimations, pas des ecritures.** Rien de ce qui est lu ici
n'entre dans la chaine. Les indices se passent au rapport
([`sommier_rapport_quarto()`](https://pobsteta.github.io/sommieR/reference/sommier_rapport_quarto.md),
argument `indices`), qui les presente comme tels, avec leur source et
leur date.

**Le rapprochement se fait par le numero de parcelle.** nemeton
identifie ses unites par un `ug_id` et un libelle (« Foret domaniale
d'Orleans - parcelle 1039 ») ; le sommier, par un UUID et un
`numero_affichage` (« 1039 »). Le numero est lu a la fin du libelle, et
le rapport dit combien d'unites il n'a pas su apparier plutot que d'en
deviner.

Le volume sur pied (`P1`, m3/ha) est calcule par nemeton sur la hauteur
LiDAR HD et les tarifs de l'IFN, le diametre et la densite pouvant etre
synthetises depuis la hauteur ; nemeton ne declare pas sa precision.
`T3` est la part de l'unite en coupe rase sur les cinq dernieres annees
(SUFOSAT) : une coupe plus ancienne n'y figure pas - voir
[`sommier_coupes_sufosat()`](https://pobsteta.github.io/sommieR/reference/sommier_coupes_sufosat.md)
pour l'historique.
