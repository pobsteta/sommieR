# Verification du sommier d'une foret en base

Lit la chaine puis la verifie avec
[`sommier_verifier_chaine()`](https://pobsteta.github.io/sommieR/reference/sommier_verifier_chaine.md).
Le nom est celui du brief (section 6.3), qui la veut "exposee dans le
package (utilisable par un auditeur tiers sur un export) et executee a
chaque ouverture de projet dans nemetonShiny".

## Usage

``` r
sommier_verifier(con, foret_id, depuis_seq = NULL, hash_prev_initial = NULL)
```

## Arguments

- con:

  Connexion DBI.

- foret_id:

  UUID de la foret.

- depuis_seq:

  Verifier a partir de cette sequence. La verification d'un fragment
  exige `hash_prev_initial`.

- hash_prev_initial:

  Empreinte precedant `depuis_seq`.

## Value

Un objet `sommier_rapport`.
