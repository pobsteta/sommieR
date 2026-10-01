# Sylvoecoregion d'une foret

Rend la sylvoecoregion (SER) de l'IGN qui contient la foret : son code
et son nom. C'est a cette maille que l'IFN publie ses references - le
prelevement observe, le volume sur pied par essence -, et c'est donc
elle qui dit a quoi comparer une possibilite.

## Usage

``` r
sommier_ser(emprise, cache = NULL, force = FALSE)
```

## Arguments

- emprise:

  Couche des unites de gestion
  ([`sommier_couche_ug()`](https://pobsteta.github.io/sommieR/reference/sommier_couche_ug.md)),
  ou `data.frame` a colonne `wkt` en Lambert-93.

- cache:

  Repertoire de cache.

- force:

  Retelecharger la couche meme si elle est en cache.

## Value

Une liste : `code` (par exemple `"B70"`), `nom` (`"Sologne-Orleanais"`),
`plusieurs` (la foret touche-t-elle plusieurs SER ?) et `source`.

## Details

La couche des SER est celle que l'IGN publie
(`inventaire-forestier.ign.fr`, `ser_l93.zip`). Elle se telecharge une
fois, explicitement, et se garde en cache ; ni le rapport ni la balance
ne la demandent au reseau. La foret est situee par le point interieur de
l'union de ses unites : une foret a cheval sur deux SER est rattachee a
celle qui contient ce point, et la fonction le signale.

## See also

[`sommier_rapport_quarto()`](https://pobsteta.github.io/sommieR/reference/sommier_rapport_quarto.md)
et son argument `reference_ifn`.

## Examples

``` r
# Necessite un acces reseau au premier appel :
# sommier_ser(sommier_couche_ug(con, foret))
```
