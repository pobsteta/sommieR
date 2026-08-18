# Payload du registre 5 - coupes et recoltes

Construit et valide le payload d'une entree du registre 5 (imprimes
A50E, A50F et A50I). Les champs facultatifs laisses a `NULL` sont
absents du JSON : ils ne sont pas ecrits comme `null`, afin qu'ajouter
une precision plus tard ne ressemble pas a une correction de valeur.

## Usage

``` r
registre5_coupe(
  type_entree,
  exercice,
  nature_coupe,
  volume_m3,
  surface_ha = NULL,
  essence = NULL,
  coupon = NULL,
  observations = NULL
)
```

## Arguments

- type_entree:

  L'un de
  [SOMMIER_TYPES_COUPE](https://pobsteta.github.io/sommieR/reference/SOMMIER_TYPES_COUPE.md).

- exercice:

  Annee de l'exercice budgetaire (entier).

- nature_coupe:

  Nature de la coupe (texte libre normalise par le gestionnaire :
  amelioration, reguliere, sanitaire, emprise...).

- volume_m3:

  Volume en metres cubes (positif ou nul).

- surface_ha:

  Surface parcourue en hectares (facultatif).

- essence:

  Essence ou groupe d'essences (facultatif).

- coupon:

  Identifiant du coupon ou de la subdivision (facultatif).

- observations:

  Observations libres (facultatif).

## Value

Une liste nommee, prete a etre passee a
[`sommier_entree()`](https://pobsteta.github.io/sommieR/reference/sommier_entree.md).

## Examples

``` r
registre5_coupe(
  type_entree = "martelage", exercice = 2026,
  nature_coupe = "amelioration", volume_m3 = 342.5,
  surface_ha = 12.4, essence = "HET"
)
#> $type_entree
#> [1] "martelage"
#> 
#> $exercice
#> [1] 2026
#> 
#> $nature_coupe
#> [1] "amelioration"
#> 
#> $volume_m3
#> [1] 342.5
#> 
#> $surface_ha
#> [1] 12.4
#> 
#> $essence
#> [1] "HET"
#> 
```
