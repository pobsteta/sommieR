# Payload du registre 9 - peuplement remarquable (imprime A50 r/p)

Payload du registre 9 - peuplement remarquable (imprime A50 r/p)

## Usage

``` r
registre9_peuplement(
  appellation,
  interet,
  composition = NULL,
  age_ans = NULL,
  surface_ha = NULL,
  hauteur_dominante_m = NULL,
  surface_terriere_m2ha = NULL,
  observations = NULL,
  geometrie = NULL
)
```

## Arguments

- appellation:

  Nom du peuplement.

- interet:

  Ce qui fonde le caractere remarquable.

- composition:

  Composition en essences, en dixiemes : liste nommee dont les valeurs
  somment a 10 (facultatif).

- age_ans, surface_ha, hauteur_dominante_m, surface_terriere_m2ha:

  Mesures du releve (facultatif).

- observations:

  Observations libres (facultatif).

- geometrie:

  Emprise de l'objet, en WGS84 : voir
  [`geom_polygone()`](https://pobsteta.github.io/sommieR/reference/geometries.md).
  Facultative — un gestionnaire sans releve continue de saisir sans, et
  son sommier reste conforme.

## Value

Une liste nommee, prete a etre passee a
[`sommier_entree()`](https://pobsteta.github.io/sommieR/reference/sommier_entree.md).

## Examples

``` r
registre9_peuplement(
  appellation = "Futaie de la Combe", interet = "Hetraie-sapiniere agee",
  composition = list(HET = 6, SAP = 4), surface_ha = 12.4,
  hauteur_dominante_m = 34
)
#> $type_fiche
#> [1] "peuplement"
#> 
#> $appellation
#> [1] "Futaie de la Combe"
#> 
#> $interet
#> [1] "Hetraie-sapiniere agee"
#> 
#> $composition
#> $composition$HET
#> [1] 6
#> 
#> $composition$SAP
#> [1] 4
#> 
#> 
#> $surface_ha
#> [1] 12.4
#> 
#> $hauteur_dominante_m
#> [1] 34
#> 
```
