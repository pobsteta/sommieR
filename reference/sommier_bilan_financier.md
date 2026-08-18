# Bilan financier (imprime A50G)

Recettes, depenses et solde par exercice, avec le cumul. Vue calculee :
rien n'est stocke, tout se deduit du registre 7.

## Usage

``` r
sommier_bilan_financier(con, foret_id)
```

## Arguments

- con:

  Connexion DBI.

- foret_id:

  UUID de la foret.

## Value

Un `data.frame` : `exercice`, `recettes_eur`, `depenses_eur`, les trois
rubriques de depense, `bois_delivres_eur`, `solde_eur`,
`solde_cumule_eur`.

## Details

`bois_delivres_eur` isole la valeur des bois delivres - l'affouage,
propre a la foret communale - parce que l'imprime A50G lui reserve sa
colonne et que le conseil municipal la lit pour elle-meme.
