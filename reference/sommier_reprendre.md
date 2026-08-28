# Ecriture d'une reprise dans le sommier

Ecrit un lot d'entrees transcrites, en une transaction, et rend le
compte-rendu de ce qui est entre : combien d'entrees, par registre, sur
quelle periode, depuis quelles pieces.

## Usage

``` r
sommier_reprendre(con, entrees)
```

## Arguments

- con:

  Connexion DBI.

- entrees:

  Un objet `sommier_reprise` ou une liste d'objets `sommier_reprise`,
  tous de la meme foret.

## Value

Invisiblement, un objet de classe `sommier_compte_rendu_reprise`.

## Details

La fonction n'accepte que des entrees construites par
[`sommier_reprise()`](https://pobsteta.github.io/sommieR/reference/sommier_reprise.md).
Ce n'est pas une precaution de typage : une transcription passee par
[`sommier_entree()`](https://pobsteta.github.io/sommieR/reference/sommier_entree.md)
pourrait etre antidatee et se donner pour un constat, et c'est
exactement ce que ce lot interdit.

L'empreinte reste calculee cote R, entree par entree, y compris pour un
lot de plusieurs milliers : la canonisation ne se delegue pas a la base,
sans quoi la chaine ne serait plus verifiable hors serveur.

## See also

[`sommier_reprise()`](https://pobsteta.github.io/sommieR/reference/sommier_reprise.md),
[`sommier_provenance()`](https://pobsteta.github.io/sommieR/reference/sommier_provenance.md)
