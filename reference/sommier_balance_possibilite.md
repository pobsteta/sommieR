# Balance de possibilite (imprime A50E)

Vue calculee, jamais saisie : `SUM(volumes marteles de l'exercice)`
moins la possibilite, cumulee par foret.

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

  Fenetre de resorption admise (defaut `NULL` : aucune colonne
  d'appreciation n'est ajoutee).

## Value

Un `data.frame` : `exercice`, `possibilite_m3_an`, `volume_martele_m3`,
`volume_realise_m3`, `balance_exercice_m3`, `balance_cumulee_m3`.

## Details

En foret publique, la balance se lit contre la possibilite de
l'amenagement regle. En foret privee, la meme mecanique sert de balance
de conformite au programme du PSG, avec une tolerance de plus ou moins
quatre ans : `tolerance_ans` ne change pas le calcul, il pose le nombre
d'exercices sur lequel la balance cumulee a vocation a se resorber.
