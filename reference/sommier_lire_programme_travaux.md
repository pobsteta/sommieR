# Lire le programme de travaux de nemetonshiny

Lit la couche `actions` de `<projet>-programme-travaux.gpkg`, tel que
l'ecrit `export_action_plan_gpkg()` de nemetonshiny : une ligne par
action du plan d'action, l'identifiant de l'action dans la colonne `id`.
C'est le point de depart du chemin de l'`action_id` : voir
[`sommier_actions_realisees()`](https://pobsteta.github.io/sommieR/reference/sommier_actions_realisees.md).

## Usage

``` r
sommier_lire_programme_travaux(fichier)
```

## Arguments

- fichier:

  Chemin du GeoPackage du programme.

## Value

Un `data.frame` sans geometrie : `action_id` (la colonne `id` du
programme), `ug_id`, puis celles des colonnes `type`, `annee_civile`,
`surface_ha` et `statut` que le fichier porte.

## See also

[`sommier_projet_qfield_travaux()`](https://pobsteta.github.io/sommieR/reference/sommier_projet_qfield_travaux.md)
