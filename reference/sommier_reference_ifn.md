# Prelevement de reference de l'IFN pour une foret

Situe la foret dans sa sylvoecoregion
([`sommier_ser()`](https://pobsteta.github.io/sommieR/reference/sommier_ser.md))
et rend le prelevement que l'IFN y observe, en m3/ha/an, toutes essences
confondues : la reference qu'attend l'argument `reference_ifn` de
[`sommier_rapport_quarto()`](https://pobsteta.github.io/sommieR/reference/sommier_rapport_quarto.md),
et `reference_m3_ha_an` de
[`sommier_amenagement()`](https://pobsteta.github.io/sommieR/reference/sommier_amenagement.md).

## Usage

``` r
sommier_reference_ifn(emprise, cache = NULL)
```

## Arguments

- emprise:

  Couche des unites de gestion
  ([`sommier_couche_ug()`](https://pobsteta.github.io/sommieR/reference/sommier_couche_ug.md)),
  ou `data.frame` a colonne `wkt` en Lambert-93.

- cache:

  Repertoire de cache de la couche des SER.

## Value

Une liste : `taux_m3_ha_an`, `ser`, `nom`, `millesime`, `source`,
`n_essences`, `plusieurs` (la foret touche plusieurs SER).

## Details

Le taux vient de nemeton (`ifn_prelevement_essence_ser()`), qui le tire
des donnees brutes de l'IFN : arbres coupes et vidanges entre deux
visites d'une placette, ramenes a l'annee. C'est la somme des taux
`maille` des essences de la SER - le volume preleve par hectare de foret
de la SER, toutes proprietes confondues. **Ce qui a ete coupe, non ce
qui devait l'etre** : il situe une possibilite, il ne la juge pas.

nemeton n'est pas sur le CRAN ; il s'installe depuis GitHub
(`pak::pak("pobsteta/nemeton")`). Ses tables IFN sont livrees avec le
paquet : aucun appel reseau, hors le premier telechargement de la couche
des SER.

## See also

[`sommier_ser()`](https://pobsteta.github.io/sommieR/reference/sommier_ser.md),
[`sommier_rapport_quarto()`](https://pobsteta.github.io/sommieR/reference/sommier_rapport_quarto.md)

## Examples

``` r
# Necessite nemeton et, au premier appel, un acces reseau :
# ref <- sommier_reference_ifn(sommier_couche_ug(con, foret))
# sommier_rapport_quarto(con, foret, "rapport.pdf", format = "pdf",
#                        reference_ifn = ref)
```
