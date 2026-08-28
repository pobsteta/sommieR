# Piece dont une reprise est tiree

Construit et valide le bloc de provenance d'une entree transcrite. Sans
lui, une reprise est indiscernable d'une invention : c'est la reference
de la piece qui permet a un tiers d'aller voir.

## Usage

``` r
reprise_source(
  source,
  reference,
  date_piece = NULL,
  detenteur = NULL,
  observations = NULL
)
```

## Arguments

- source:

  Provenance, l'une de `SOMMIER_SOURCES_REPRISE$source`.

- reference:

  Reference de la piece, assez precise pour qu'on la retrouve : imprime
  et exercice, numero de deliberation, intitule et date de l'extrait.

- date_piece:

  Date de la piece elle-meme, si elle en porte une (facultatif) - elle
  ne se confond ni avec la date de l'evenement, ni avec celle de la
  transcription.

- detenteur:

  Qui detient l'original (facultatif).

- observations:

  Observations libres (facultatif) : etat de la piece, lacunes, passages
  illisibles.

## Value

Une liste nommee, a passer a
[`sommier_reprise()`](https://pobsteta.github.io/sommieR/reference/sommier_reprise.md).

## Details

Le bloc voyage dans le payload de l'entree, sous la cle `reprise`. Il
est donc couvert par l'empreinte au meme titre que le volume d'une coupe
: rectifier apres coup la piece citee n'est pas plus possible que
rectifier le volume.

## See also

[`sommier_reprise()`](https://pobsteta.github.io/sommieR/reference/sommier_reprise.md),
[SOMMIER_SOURCES_REPRISE](https://pobsteta.github.io/sommieR/reference/SOMMIER_SOURCES_REPRISE.md)

## Examples

``` r
reprise_source(
  source = "registre_signe",
  reference = "Sommier papier, imprime A50E, exercice 1998, folio 12",
  date_piece = "1999-01-15",
  detenteur = "Commune de Couchey"
)
#> $source
#> [1] "registre_signe"
#> 
#> $reference
#> [1] "Sommier papier, imprime A50E, exercice 1998, folio 12"
#> 
#> $date_piece
#> [1] "1999-01-15"
#> 
#> $detenteur
#> [1] "Commune de Couchey"
#> 
```
