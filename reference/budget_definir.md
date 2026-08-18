# Fixation du budget previsionnel

Inscrit ou revise le montant prevu pour un poste et un exercice.

## Usage

``` r
budget_definir(con, foret_id, annee, poste, montant_eur)
```

## Arguments

- con:

  Connexion DBI.

- foret_id:

  UUID de la foret.

- annee:

  Exercice budgetaire.

- poste:

  L'un des postes de
  [SOMMIER_POSTES_COMPTABLES](https://pobsteta.github.io/sommieR/reference/SOMMIER_POSTES_COMPTABLES.md).

- montant_eur:

  Montant prevu, positif ou nul. Le sens vient du poste.

## Value

Invisiblement, le nombre de lignes ecrites.

## Details

Le previsionnel **n'est pas** une entree de sommier. Le brief le pose
clairement : « le programme previsionnel appartient a l'amenagement ou
au PSG ; le sommier n'enregistre que le realise et le constate ». Il vit
donc a cote du registre, comme la possibilite annuelle, et il est
**mutable** : un budget se revise, et cette revision n'a pas a etre
opposable. Ce qui doit l'etre, c'est le realise - et celui-la est dans
la chaine.

## See also

[`sommier_execution_budgetaire()`](https://pobsteta.github.io/sommieR/reference/sommier_execution_budgetaire.md)
