# Lecture des entrees d'un sommier

Rend les entrees sous la forme attendue par
[`sommier_verifier_chaine()`](https://pobsteta.github.io/sommieR/reference/sommier_verifier_chaine.md)
: les empreintes en hexadecimal, le payload en texte JSON, `date_saisie`
reformate en UTC a la seconde.

## Usage

``` r
sommier_lire(con, foret_id, registre = NULL, depuis_seq = NULL)
```

## Arguments

- con:

  Connexion DBI.

- foret_id:

  UUID de la foret.

- registre:

  Filtre facultatif sur le numero de registre.

- depuis_seq:

  Ne lire qu'a partir de cette sequence (verification d'un fragment a
  partir d'une ancre).

## Value

Un `data.frame`.

## Details

`date_saisie` est reserialise en `AAAA-MM-JJTHH:MM:SSZ`, exactement la
forme qui a ete hachee a l'ecriture. Laisser le pilote rendre un
`POSIXct` ferait dependre l'empreinte du fuseau de la session R, ce qui
rendrait la verification non reproductible d'un poste a l'autre.
