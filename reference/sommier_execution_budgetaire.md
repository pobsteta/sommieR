# Execution budgetaire

Confronte le realise du registre 7 au budget previsionnel, poste par
poste.

## Usage

``` r
sommier_execution_budgetaire(con, foret_id, exercice = NULL)
```

## Arguments

- con:

  Connexion DBI.

- foret_id:

  UUID de la foret.

- exercice:

  Restreindre a un exercice (facultatif).

## Value

Un `data.frame` : `exercice`, `poste`, `prevu_eur`, `realise_eur`,
`ecart_eur`, `execution_pct`.

## Details

Un poste budgete mais jamais execute apparait avec un realise nul, et un
poste execute hors budget avec un prevu nul : les deux sont des faits de
gestion, aucun ne doit disparaitre du tableau. `execution_pct` vaut `NA`
lorsque rien n'etait budgete, un taux sur une base nulle n'ayant pas de
sens - l'ecart en euros suffit a le dire.
