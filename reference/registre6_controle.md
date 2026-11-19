# Payload du registre 6 - controle d'une placette

Un passage sur une placette : ce qu'on y compte. Le taux de reprise, la
densite a l'hectare et la part d'abroutis ne s'inscrivent pas : la vue
`v_controle_plantation` les calcule, et l'age de la plantation se deduit
de l'annee des travaux suivis.

## Usage

``` r
registre6_controle(
  placette_id,
  nb_total,
  nb_vivants,
  h_moy_cm = NULL,
  nb_abroutis = NULL,
  concurrence = NULL,
  besoin = NULL,
  operateur = NULL,
  visite_le = NULL,
  releve_uuid = NULL,
  photos = NULL,
  observations = NULL,
  nb_plants_vivants = NULL,
  nb_plants_concurrences = NULL,
  concurrence_calculee = NULL
)
```

## Arguments

- placette_id:

  UUID de la placette controlee.

- nb_total, nb_vivants:

  Plants comptes, et vivants parmi eux.

- h_moy_cm:

  Hauteur moyenne des tiges objectif, en cm.

- nb_abroutis:

  Plants vivants abroutis.

- concurrence:

  L'un de
  [SOMMIER_CONCURRENCES](https://pobsteta.github.io/sommieR/reference/SOMMIER_CONCURRENCES.md),
  defini dans
  [SOMMIER_DEFINITIONS_CONCURRENCE](https://pobsteta.github.io/sommieR/reference/SOMMIER_DEFINITIONS_CONCURRENCE.md).

- besoin:

  Le travail qui s'impose ensuite : un code de
  [SOMMIER_CODES_TRAVAUX](https://pobsteta.github.io/sommieR/reference/SOMMIER_CODES_TRAVAUX.md),
  ou `"aucun"`.

- operateur:

  Agent qui a controle.

- visite_le:

  Instant du controle.

- releve_uuid:

  Identifiant du releve de terrain.

- photos:

  Photos, par leur empreinte.

- observations:

  Observations libres.

- nb_plants_vivants, nb_plants_concurrences:

  Facultatifs : le comptage dont `concurrence` est tiree, pour qu'on
  puisse la verifier. Plants vivants sur lesquels le contact avec la
  vegetation a ete note (au plus `nb_vivants`), et parmi eux ceux au
  contact de la vegetation concurrente. Ajout seul : `NULL` est accepte,
  et un controle sans ces champs se relit a l'identique. Lis avec
  [`sommier_niveau_concurrence()`](https://pobsteta.github.io/sommieR/reference/sommier_niveau_concurrence.md).
  Quand les deux sont fournis : si `concurrence` est absent, il est
  **deduit** par
  [`sommier_niveau_concurrence()`](https://pobsteta.github.io/sommieR/reference/sommier_niveau_concurrence.md)
  ; s'il est saisi et contredit les comptages, il est **conserve tel que
  saisi**, un avertissement le dit et le niveau calcule est inscrit au
  payload sous `concurrence_calculee`.

- concurrence_calculee:

  Ne se saisit pas : c'est la trace que la fonction inscrit quand le
  niveau saisi contredit les comptages. Accepte pour que la relecture
  d'un payload ecrit se rejoue (il est recalcule).

## Value

Une liste nommee, prete a etre passee a
[`sommier_entree()`](https://pobsteta.github.io/sommieR/reference/sommier_entree.md).

## See also

[`sommier_controler_placette()`](https://pobsteta.github.io/sommieR/reference/sommier_controler_placette.md)
