# Niveau de concurrence d'une placette, depuis les plants

Regle de passage du critere binaire par plant (concurrence ou non, guide
2014 p. 52) au niveau de placette : on compte la part des plants vivants
concurrences par la vegetation, puis on la lit dans
[SOMMIER_DEFINITIONS_CONCURRENCE](https://pobsteta.github.io/sommieR/reference/SOMMIER_DEFINITIONS_CONCURRENCE.md).
Un seul niveau couvre l'herbacee et la ligneuse (fougere aigle, ronce) :
il se calcule sur le comptage commun (un plant touche par l'une ou
l'autre compte une fois). La nature (herbacee, ligneuse, mixte) se note
a part, en `observations` : elle decrit, elle ne decide pas.

Sans plant vivant compte, le resultat est `NA` : jamais un niveau
devine.

## Usage

``` r
sommier_niveau_concurrence(nb_concurrences, nb_vivants)
```

## Arguments

- nb_concurrences:

  Plants vivants au contact de la vegetation concurrente.

- nb_vivants:

  Plants vivants comptes.

## Value

Un element de
[SOMMIER_CONCURRENCES](https://pobsteta.github.io/sommieR/reference/SOMMIER_CONCURRENCES.md),
ou `NA_character_`.

## See also

[`registre6_controle()`](https://pobsteta.github.io/sommieR/reference/registre6_controle.md)
