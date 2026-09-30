# Balance de possibilite (imprime A50E)

Vue calculee, jamais saisie : `SUM(volumes marteles de l'exercice)`
moins la possibilite, cumulee **par amenagement**. La possibilite vient
de l'acte qui la fixe - l'amenagement ou l'avenant, au registre 1 : voir
[`sommier_amenagement()`](https://pobsteta.github.io/sommieR/reference/sommier_amenagement.md).

## Usage

``` r
sommier_balance_possibilite(con, foret_id, tolerance_ans = NULL)
```

## Arguments

- con:

  Connexion DBI.

- foret_id:

  UUID de la foret.

- tolerance_ans:

  Fenetre de resorption admise, en annees de possibilite. Par defaut,
  celle que l'amenagement declare ; sans elle, aucune colonne
  d'appreciation n'est ajoutee.

## Value

Un `data.frame` : `amenagement_id`, `amenagement`, `exercice`,
`possibilite_m3_ha_an` et `surface_ha` (ce que l'acte fixe),
`possibilite_m3_an` (le volume qui s'en deduit), `volume_martele_m3`,
`prelevement_m3_ha` (le martele ramene a l'hectare, comparable a la
possibilite et a l'IFN), `volume_realise_m3`, `balance_exercice_m3`,
`balance_cumulee_m3`, `reference_acte`, `par_avenant`, `nature_volume`
(possibilite fixee, ou recolte prevue au document), et `conforme` quand
une tolerance s'applique.

## Details

Le cumul repart de zero avec chaque amenagement, et court jusqu'a
l'exercice courant. Un martelage impute a un exercice qu'aucun
amenagement ne couvre ne s'y trouve pas :
[`sommier_martelages_hors_amenagement()`](https://pobsteta.github.io/sommieR/reference/sommier_martelages_hors_amenagement.md)
le montre a part.

En foret publique, la balance se lit contre la possibilite de
l'amenagement regle. En foret privee, la meme mecanique sert de balance
de conformite au programme du PSG, avec une tolerance de plus ou moins
quatre ans : `tolerance_ans` ne change pas le calcul, il pose le nombre
d'exercices sur lequel la balance cumulee a vocation a se resorber.
