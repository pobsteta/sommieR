# Payload du registre 8 - detection par teledetection

Un phenomene propose par une chaine de teledetection (FORDEAD, FAST), en
attente de validation terrain.

## Usage

``` r
registre8_detection(
  nature,
  source,
  description,
  surface_ha = NULL,
  indice = NULL,
  date_detection = NULL,
  observations = NULL
)
```

## Arguments

- nature:

  L'une de
  [SOMMIER_NATURES_PHENOMENE](https://pobsteta.github.io/sommieR/reference/SOMMIER_NATURES_PHENOMENE.md).

- source:

  Chaine de detection : `"fordead"`, `"fast"`, ou autre.

- description:

  Description de la detection.

- surface_ha:

  Surface detectee en hectares (facultatif).

- indice:

  Valeur de l'indice ayant declenche la detection (facultatif).

- date_detection:

  Date de l'observation satellitaire (facultatif).

- observations:

  Observations libres (facultatif).

## Value

Une liste nommee, prete a etre passee a
[`sommier_entree()`](https://pobsteta.github.io/sommieR/reference/sommier_entree.md).

## Details

Une detection **n'est pas** un constat : elle porte le NDP de sa source,
et non NDP 0. C'est
[`sommier_valider_detection()`](https://pobsteta.github.io/sommieR/reference/sommier_valider_detection.md)
qui, apres passage sur le terrain, inscrit l'entree NDP 0 qui la
confirme ou l'ecarte. Le sommier reste ainsi le receptacle NDP 0 de la
plateforme sans se fermer aux propositions moins precises.

## See also

[`sommier_importer_detections()`](https://pobsteta.github.io/sommieR/reference/sommier_importer_detections.md),
[`sommier_valider_detection()`](https://pobsteta.github.io/sommieR/reference/sommier_valider_detection.md)

## Examples

``` r
registre8_detection(
  nature = "crise_sanitaire", source = "fordead",
  description = "Deperissement detecte sur pessiere",
  surface_ha = 3.2, indice = 0.42
)
#> $type_entree
#> [1] "detection"
#> 
#> $nature
#> [1] "crise_sanitaire"
#> 
#> $source
#> [1] "fordead"
#> 
#> $description
#> [1] "Deperissement detecte sur pessiere"
#> 
#> $surface_ha
#> [1] 3.2
#> 
#> $indice
#> [1] 0.42
#> 
```
