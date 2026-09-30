# Fixation de la possibilite d'un exercice (obsolete)

Ecrit la possibilite d'un exercice dans la table `exercice`, hors de la
chaine. **La balance ne la lit plus** depuis sommieR 0.19.0 : la
possibilite est portee par l'acte d'amenagement, au registre 1 (voir
[`sommier_amenagement()`](https://pobsteta.github.io/sommieR/reference/sommier_amenagement.md)),
et une table reecrivable sans trace n'a pas a fixer ce a quoi des
prelevements attestes se comparent.

La fonction avertit a chaque appel, et refuse d'ecrire une fois la table
reprise par
[`sommier_reprendre_exercices()`](https://pobsteta.github.io/sommieR/reference/sommier_reprendre_exercices.md)
: une possibilite ne se modifie plus alors que par avenant.

## Usage

``` r
exercice_definir(con, foret_id, annee, possibilite_m3_an)
```

## Arguments

- con:

  Connexion DBI.

- foret_id:

  UUID de la foret.

- annee:

  Annee de l'exercice.

- possibilite_m3_an:

  Possibilite annuelle en metres cubes.

## Value

Invisiblement, le nombre de lignes ecrites.
