# Ce qui a ete constate, ce qui a ete transcrit

Compte par registre les entrees en vigueur selon leur provenance. C'est
la vue qui permet a un document engendre depuis le sommier de dire
lesquels de ses chiffres viennent d'une transcription - un tableau qui
melerait les deux sans le dire ferait passer la recopie pour de la
mesure.

## Usage

``` r
sommier_provenance(con, foret_id, debut = NULL, fin = NULL)
```

## Arguments

- con:

  Connexion DBI.

- foret_id:

  UUID de la foret.

- debut, fin:

  Bornes sur la date d'evenement (facultatif).

## Value

Un `data.frame` : `registre`, `nom`, `n_constate`, `n_transcrit`,
`n_pieces`, `transcrit_du`, `transcrit_au`.

## Details

Le comptage porte sur les entrees en vigueur (`v_entree_courante`) et
non sur la chaine entiere : ce sont elles qui alimentent les tableaux,
et une transcription rectifiee ne doit pas etre comptee deux fois.

## See also

[`sommier_reprendre()`](https://pobsteta.github.io/sommieR/reference/sommier_reprendre.md),
[`sommier_gestion_anterieure()`](https://pobsteta.github.io/sommieR/reference/sommier_gestion_anterieure.md)
