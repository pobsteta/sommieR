# Payload du registre 8 - suite donnee a une detection

Constat de terrain confirmant ou ecartant une detection. Produit par
[`sommier_valider_detection()`](https://pobsteta.github.io/sommieR/reference/sommier_valider_detection.md)
; rarement construit a la main.

## Usage

``` r
registre8_suite_detection(
  statut,
  detection_id,
  nature,
  description,
  surface_ha = NULL,
  volume_impacte_m3 = NULL,
  observations = NULL
)
```

## Arguments

- statut:

  `"confirme"` ou `"ecarte"`.

- detection_id:

  UUID de l'entree de detection concernee.

- nature:

  L'une de
  [SOMMIER_NATURES_PHENOMENE](https://pobsteta.github.io/sommieR/reference/SOMMIER_NATURES_PHENOMENE.md).

- description:

  Constat de terrain.

- surface_ha:

  Surface constatee en hectares (facultatif).

- volume_impacte_m3:

  Volume de bois affecte (facultatif).

- observations:

  Observations libres (facultatif).

## Value

Une liste nommee, prete a etre passee a
[`sommier_entree()`](https://pobsteta.github.io/sommieR/reference/sommier_entree.md).
