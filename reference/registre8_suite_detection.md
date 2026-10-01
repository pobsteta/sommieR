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
  observations = NULL,
  geometrie = NULL,
  precision_m = NULL,
  source_gnss = NULL,
  operateur = NULL,
  visite_le = NULL,
  releve_uuid = NULL,
  photos = NULL
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

- geometrie:

  Position relevee sur le terrain, en WGS84 : un point (voir
  [`geom_point()`](https://pobsteta.github.io/sommieR/reference/geometries.md))
  (facultatif).

- precision_m, source_gnss:

  Precision et source declarees par le recepteur GNSS (facultatif).

- operateur:

  Agent qui a constate (facultatif).

- visite_le:

  Instant de la visite, tel que l'appareil l'a note (facultatif).

- releve_uuid:

  Identifiant du releve dans l'outil de terrain (facultatif).

- photos:

  Photos par leur empreinte, comme pour une reconnaissance de limite :
  voir
  [`registre2_foncier()`](https://pobsteta.github.io/sommieR/reference/registre2_foncier.md)
  et
  [`sommier_deposer_photo()`](https://pobsteta.github.io/sommieR/reference/sommier_deposer_photo.md)
  (facultatif).

## Value

Une liste nommee, prete a etre passee a
[`sommier_entree()`](https://pobsteta.github.io/sommieR/reference/sommier_entree.md).
