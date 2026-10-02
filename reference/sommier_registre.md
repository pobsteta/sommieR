# Sommier : le registre, ecriture par ecriture

Extrait le sommier tel qu'il est chaine : une ligne par ecriture,
registre par registre, dans l'ordre de la chaine, rectifiees comprises.
C'est l'inverse du bilan de gestion : ni somme, ni carte, ni estimation,
rien qui ne soit dans la chaine.

## Usage

``` r
sommier_registre(con, foret_id, registres = 1:9, jusqu_au_visa = NULL)
```

## Arguments

- con:

  Connexion DBI.

- foret_id:

  UUID de la foret.

- registres:

  Registres a extraire (1 a 9).

- jusqu_au_visa:

  Exercice dont le visa arrete l'edition ; `NULL` pour tout le sommier.

## Value

Un objet de classe `sommier_registre` : `foret` (nom, regime),
`ecritures` (`data.frame`, une ligne par ecriture : `seq`, `registre`,
`type_entree`, `date_evenement`, `date_saisie`, `auteur`, `ndp`, `ug`,
`provenance`, `piece`, `rectifie`, `rectifiee_par`, `contenu`,
`payload`, `schema_version`, `hash`), `tenue` (fiche A10, par exercice),
`ancrages`, `verification` (etat de la chaine extraite), `visa` (le visa
qui arrete l'edition, s'il y en a un), `registres`.

## Details

**Les rectifiees restent.** Le classeur papier interdisait la rature et
imposait la mention rectificative : une ecriture rectifiee figure a sa
place, avec le numero de celle qui la rectifie (`rectifiee_par`), et la
rectification porte le numero de sa cible (`rectifie`).

**Chaque ligne dit d'ou elle vient.** Une transcription porte sa piece
(`payload$reprise`, voir
[`sommier_reprise()`](https://pobsteta.github.io/sommieR/reference/sommier_reprise.md))
; un constat n'en porte pas.

**La fiche A10 ouvre le sommier.** Pour chaque exercice depuis
l'ouverture, les actes de visa du registre 1, signes et horodates ou non
; un exercice sans acte est dit non vise. Les ancrages suivent.

**Une edition peut s'arreter a un visa.** `jusqu_au_visa` imprime le
sommier tel qu'il etait quand l'exercice a ete vise : les ecritures
jusqu'a la tete signee, pas au-dela. La chaine est alors verifiee
jusqu'a cette tete, et l'extraction dit si elle concorde avec
l'empreinte visee.

## See also

[`sommier_registre_quarto()`](https://pobsteta.github.io/sommieR/reference/sommier_registre_quarto.md),
[`sommier_exporter_manifeste()`](https://pobsteta.github.io/sommieR/reference/sommier_exporter_manifeste.md)
