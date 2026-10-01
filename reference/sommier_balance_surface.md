# Balance en surface : la regeneration ouverte contre la regeneration prevue

Pour les amenagements qui fixent une surface a ouvrir en regeneration -
c'est ce que fixent les arretes recents de l'ONF, plus que des volumes
-, confronte exercice par exercice la surface ouverte par les martelages
de regeneration a la surface prevue, et en cumule l'ecart.

## Usage

``` r
sommier_balance_surface(con, foret_id, natures = SOMMIER_NATURES_REGENERATION)
```

## Arguments

- con:

  Connexion DBI.

- foret_id:

  UUID de la foret.

- natures:

  Natures de coupe qui ouvrent une surface en regeneration.

## Value

Un `data.frame` : `amenagement_id`, `amenagement`, `exercice`,
`surface_prevue_ha`, `surface_ouverte_ha`, `ecart_ha`,
`ecart_cumule_ha`, `surface_regeneration_ha` (le total de la periode).
Vide si aucun amenagement ne fixe de surface a regenerer.

## Details

**Prevue.** La surface a regenerer de la periode
(`surface_regeneration_ha`, celle du dernier avenant qui la revise),
repartie egalement sur les exercices de l'amenagement. L'arrete fixe un
total, pas un calendrier : le rythme regulier n'est qu'un repere.

**Ouverte.** La surface des martelages dont la nature releve de
`natures` (voir
[SOMMIER_NATURES_REGENERATION](https://pobsteta.github.io/sommieR/reference/SOMMIER_NATURES_REGENERATION.md)).
Une unite ne s'ouvre qu'une fois : une coupe secondaire puis definitive
sur la meme parcelle n'ouvrent pas deux fois la meme surface. Des
surfaces partielles saisies - 7,2 ha d'une parcelle de 39 -
s'additionnent d'un exercice a l'autre, sans depasser la surface de
l'unite. Un martelage sans surface saisie parcourt son unite (voir
`v_coupe`).

**L'ecart se cumule par amenagement**, jusqu'a l'exercice courant, comme
la balance en volume. Un ecart negatif est un retard de regeneration.

## See also

[`sommier_balance_possibilite()`](https://pobsteta.github.io/sommieR/reference/sommier_balance_possibilite.md),
[`sommier_amenagement()`](https://pobsteta.github.io/sommieR/reference/sommier_amenagement.md)
