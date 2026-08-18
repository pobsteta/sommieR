# Ecriture d'entrees dans le sommier

Chaine puis insere une ou plusieurs entrees, en une transaction. La
position dans la chaine est determinee au moment de l'ecriture, a partir
de la tete courante lue en base : c'est le registre qui decide de la
sequence, pas l'appelant.

## Usage

``` r
sommier_ajouter(con, entrees)
```

## Arguments

- con:

  Connexion DBI.

- entrees:

  Un objet `sommier_entree` ou une liste d'objets `sommier_entree`, tous
  de la meme foret.

## Value

Invisiblement, la liste des entrees chainees telles qu'inserees (`seq`,
`hash_prev` et `hash` renseignes).

## Details

**Serialisation des ecritures.** L'insertion prend un
`pg_advisory_xact_lock(hashtext(foret_id::text))`, conformement au brief
(section 6.3). Sans ce verrou, deux transactions concurrentes liraient
la meme tete, calculeraient le meme `hash_prev` et forkeraient la
chaine. Le verrou est pris **avant** la lecture de la tete - le prendre
apres ne servirait a rien - et il est relache automatiquement a la fin
de la transaction.

`hashtext()` pouvant entrer en collision, deux forets differentes
peuvent partager un verrou : c'est sans consequence sur la correction
(elles s'attendent inutilement), et la contrainte
`UNIQUE (foret_id, seq)` reste le filet de securite si le verrou venait
a manquer.

## See also

[`sommier_entree()`](https://pobsteta.github.io/sommieR/reference/sommier_entree.md),
[`sommier_verifier()`](https://pobsteta.github.io/sommieR/reference/sommier_verifier.md)
