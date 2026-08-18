# Payload du registre 8 - equilibre foret-gibier

Constat d'equilibre entre la foret et les populations de grand gibier,
obligatoire dans les PSG depuis la LAAAF de 2014. Alimente la famille R
(r4_abroutissement) de nemeton.

## Usage

``` r
registre8_equilibre_gibier(
  saison,
  surface_sensible_ha,
  taux_abroutissement_pct = NULL,
  methode = NULL,
  diagnostic = NULL,
  observations = NULL
)
```

## Arguments

- saison:

  Saison cynegetique, au format `"AAAA-AAAA"`.

- surface_sensible_ha:

  Surface sensible aux degats, en hectares.

- taux_abroutissement_pct:

  Taux d'abroutissement constate, 0 a 100 (facultatif).

- methode:

  Methode de constat : enclos-exclos, indice de consommation,
  observation directe (facultatif).

- diagnostic:

  Diagnostic porte : `"equilibre"`, `"desequilibre_leger"`,
  `"desequilibre_marque"` (facultatif).

- observations:

  Observations libres (facultatif).

## Value

Une liste nommee, prete a etre passee a
[`sommier_entree()`](https://pobsteta.github.io/sommieR/reference/sommier_entree.md).

## Examples

``` r
registre8_equilibre_gibier(
  saison = "2025-2026", surface_sensible_ha = 42,
  taux_abroutissement_pct = 23.5, diagnostic = "desequilibre_leger"
)
#> $type_entree
#> [1] "equilibre_gibier"
#> 
#> $saison
#> [1] "2025-2026"
#> 
#> $surface_sensible_ha
#> [1] 42
#> 
#> $taux_abroutissement_pct
#> [1] 23.5
#> 
#> $diagnostic
#> [1] "desequilibre_leger"
#> 
```
