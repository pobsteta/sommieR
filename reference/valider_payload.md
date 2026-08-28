# Validation d'un payload selon son registre

Revalide un payload deja construit - utile a la relecture d'un export,
ou les payloads arrivent en JSON sans etre passes par les constructeurs.

## Usage

``` r
valider_payload(registre, payload)
```

## Arguments

- registre:

  Numero de registre (1 a 9).

- payload:

  Liste nommee.

## Value

Le payload valide, normalise.

## Details

La cle `reprise` est admise dans le payload de n'importe quel registre :
elle porte la provenance d'une entree transcrite (voir
[`sommier_reprise()`](https://pobsteta.github.io/sommieR/reference/sommier_reprise.md)).
Elle est detachee avant l'appel au constructeur du registre - qui n'a
pas a la connaitre - validee par
[`valider_reprise()`](https://pobsteta.github.io/sommieR/reference/valider_reprise.md),
puis rattachee. C'est le seul champ commun aux neuf payloads, parce que
la question a laquelle il repond, celle de savoir d'ou vient cette
ecriture, se pose partout de la meme facon.
