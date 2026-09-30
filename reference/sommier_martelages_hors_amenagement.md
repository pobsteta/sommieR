# Martelages qu'aucun amenagement ne couvre

Les prelevements imputes a un exercice hors de toute periode
d'amenagement. Ils ne se comparent a rien, et la balance ne peut pas les
compter ; ils ne sont pas perdus pour autant.

## Usage

``` r
sommier_martelages_hors_amenagement(con, foret_id)
```

## Arguments

- con:

  Connexion DBI.

- foret_id:

  UUID de la foret.

## Value

Un `data.frame` : `id`, `exercice`, `type_entree`, `nature_coupe`,
`volume_m3`, `date_evenement`.
