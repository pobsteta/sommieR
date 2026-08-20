# Payload du registre 9 - habitat remarquable (imprime A50 r/h)

Payload du registre 9 - habitat remarquable (imprime A50 r/h)

## Usage

``` r
registre9_habitat(
  type_habitat,
  surface_ha,
  code_natura2000 = NULL,
  etat_conservation = NULL,
  localisation = NULL,
  observations = NULL,
  geometrie = NULL
)
```

## Arguments

- type_habitat:

  Type d'habitat naturel.

- surface_ha:

  Surface en hectares.

- code_natura2000:

  Code Natura 2000 (facultatif).

- etat_conservation:

  `"favorable"`, `"degrade"`, `"defavorable"` (facultatif).

- localisation:

  Localisation en clair (facultatif).

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
