# Payload du registre 6 - placette de suivi

Une placette permanente installee pour suivre une plantation ou une
regeneration. Ses passages s'inscrivent ensuite en
[`registre6_controle()`](https://pobsteta.github.io/sommieR/reference/registre6_controle.md),
qui y renvoient : c'est le couple detection et suite du registre 8.

## Usage

``` r
registre6_placette(
  code_placette,
  travaux_id,
  geometrie,
  rayon_m = 3.99,
  materialisation = NULL,
  precision_m = NULL,
  source_gnss = NULL,
  observations = NULL
)
```

## Arguments

- code_placette:

  Code lisible, unique dans l'unite ("P35-03").

- travaux_id:

  UUID de l'intervention suivie (une plantation, une regeneration).

- geometrie:

  Le centre de la placette, un point en WGS84 (voir
  [`geom_point()`](https://pobsteta.github.io/sommieR/reference/geometries.md)).

- rayon_m:

  Rayon, en metres : 3,99 m font 50 m2.

- materialisation:

  Comment la placette se retrouve (piquet, peinture...).

- precision_m, source_gnss:

  Precision et source de la position.

- observations:

  Observations libres.

## Value

Une liste nommee, prete a etre passee a
[`sommier_entree()`](https://pobsteta.github.io/sommieR/reference/sommier_entree.md).

## See also

[`sommier_installer_placette()`](https://pobsteta.github.io/sommieR/reference/sommier_installer_placette.md)
