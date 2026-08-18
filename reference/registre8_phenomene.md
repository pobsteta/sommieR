# Payload du registre 8 - phenomene (imprime A50K)

Une ligne du journal chronologique des phenomenes interessant la vie de
la foret. C'est le registre qui, avec les registres 5 et 6, constitue
l'historique de gestion anterieure exige par les trois referentiels.

## Usage

``` r
registre8_phenomene(
  nature,
  description,
  surface_ha = NULL,
  volume_impacte_m3 = NULL,
  intensite = NULL,
  observations = NULL
)
```

## Arguments

- nature:

  L'une de
  [SOMMIER_NATURES_PHENOMENE](https://pobsteta.github.io/sommieR/reference/SOMMIER_NATURES_PHENOMENE.md).

- description:

  Description du phenomene.

- surface_ha:

  Surface affectee en hectares (facultatif).

- volume_impacte_m3:

  Volume de bois affecte (facultatif).

- intensite:

  Intensite ou gravite, echelle libre du gestionnaire (facultatif).

- observations:

  Observations libres (facultatif).

## Value

Une liste nommee, prete a etre passee a
[`sommier_entree()`](https://pobsteta.github.io/sommieR/reference/sommier_entree.md).

## Examples

``` r
registre8_phenomene(
  nature = "tempete", description = "Coup de vent du 12 mars",
  surface_ha = 8.5, volume_impacte_m3 = 340
)
#> $type_entree
#> [1] "phenomene"
#> 
#> $nature
#> [1] "tempete"
#> 
#> $description
#> [1] "Coup de vent du 12 mars"
#> 
#> $surface_ha
#> [1] 8.5
#> 
#> $volume_impacte_m3
#> [1] 340
#> 
```
