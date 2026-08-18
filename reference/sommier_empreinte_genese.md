# Empreinte de genese d'une foret

Premier maillon de la chaine : l'empreinte precedente de l'entree de
sequence 1. Conformement au brief (section 6.2), il s'agit du SHA-256 de
l'identifiant de la foret, pris sur ses octets UTF-8 en forme canonique
minuscule.

## Usage

``` r
sommier_empreinte_genese(foret_id)
```

## Arguments

- foret_id:

  Identifiant UUID de la foret.

## Value

Un vecteur `raw` de 32 octets.

## Examples

``` r
sommier_empreinte_genese("3f2b1c4d-5e6f-4a7b-8c9d-0e1f2a3b4c5d")
#>  [1] b1 65 63 de 17 c7 e5 3b 8b 65 27 69 af 15 b2 d5 7f fc 15 98 7a 7b 16 e6 f7
#> [26] f7 ce 1f 86 c9 de e5
```
