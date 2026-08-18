# Enregistrement canonique d'une entree

Construit la liste nommee effectivement serialisee puis hachee. Isolee
dans sa propre fonction pour qu'un verificateur tiers puisse la
reproduire, et pour que les tests puissent constater exactement ce qui
est couvert.

## Usage

``` r
sommier_enregistrement_canonique(entree)
```

## Arguments

- entree:

  Liste nommee decrivant l'entree (voir
  [SOMMIER_CHAMPS_EMPREINTE](https://pobsteta.github.io/sommieR/reference/SOMMIER_CHAMPS_EMPREINTE.md)).

## Value

Une liste nommee prete pour
[`jcs()`](https://pobsteta.github.io/sommieR/reference/jcs.md).
