# Inscription des coupes SUFOSAT comme detections

Inscrit au registre 8, comme detections a verifier, les coupes rases
detectees par SUFOSAT qu'aucun martelage n'explique : celles que le
rapport signale sous la balance. Une fois inscrites, elles se confirment
ou s'ecartent sur le terrain comme toute detection.

## Usage

``` r
sommier_inscrire_coupes_sufosat(con, foret_id, coupes, auteur)
```

## Arguments

- con:

  Connexion DBI.

- foret_id:

  UUID de la foret.

- coupes:

  Coupes detectees, telles que les rend
  [`sommier_coupes_sufosat()`](https://pobsteta.github.io/sommieR/reference/sommier_coupes_sufosat.md).

- auteur:

  Compte qui inscrit.

## Value

Invisiblement, les entrees chainees (une liste vide si rien n'est a
inscrire).

## Details

**Un pas explicite.** Une coupe detectee n'est au registre que si le
gestionnaire l'y met : c'est une ecriture dans la chaine, et elle se
decide. Chaque coupe entre en NDP 1, source `sufosat`, nature `autre` -
SUFOSAT ne dit pas si c'est une coupe de regeneration, une coupe
sanitaire ou un chablis ; le terrain le dira.

**Pas de doublon.** Une coupe deja inscrite - meme unite, meme annee,
meme source - ne l'est pas une seconde fois, qu'elle soit encore en
attente ou deja suivie.

## See also

[`sommier_coupes_sufosat()`](https://pobsteta.github.io/sommieR/reference/sommier_coupes_sufosat.md),
[`sommier_projet_qfield_detections()`](https://pobsteta.github.io/sommieR/reference/sommier_projet_qfield_detections.md)
