# Indicateurs par unite de gestion

Agrege par unite de gestion, sur une periode, ce que le sommier permet
de porter sur une carte : entrees, volumes marteles, surfaces coupees,
travaux.

## Usage

``` r
sommier_indicateurs_ug(con, foret_id, debut = NULL, fin = NULL)
```

## Arguments

- con:

  Connexion DBI.

- foret_id:

  UUID de la foret.

- debut, fin:

  Bornes de la periode (`NULL` : sans borne).

## Value

Un `data.frame` : `uuid`, `n_entrees`, `volume_martele_m3`,
`surface_coupee_ha`, `montant_travaux_eur`, `n_travaux`.

## Details

Les entrees **hors unite de gestion** (`ug_uuid` nul, imprime A50H pour
les travaux) sont exclues : elles ne se placent nulle part, et les
compter dans un total cartographie ferait mentir la carte sur ce qu'elle
montre.

Le volume martele exclut `coupe_realisee`, comme la balance de
possibilite : la meme coupe est d'abord martelee puis exploitee,
l'imputer deux fois doublerait le prelevement.

Une unite sans aucune ecriture figure avec des zeros, non par son
absence. La distinction porte : une unite ou rien n'a ete fait n'est pas
une unite inconnue, et sur une carte choroplethe la premiere doit se
teinter.

## See also

[`sommier_geometrie_ug()`](https://pobsteta.github.io/sommieR/reference/sommier_geometrie_ug.md)

## Examples

``` r
# Necessite une connexion :
# sommier_indicateurs_ug(con, foret, "2016-01-01", "2025-12-31")
```
