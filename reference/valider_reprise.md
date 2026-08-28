# Validation d'un bloc de reprise

Revalide un bloc de provenance deja construit - utile a la relecture
d'un export, ou les payloads arrivent en JSON sans etre passes par
[`reprise_source()`](https://pobsteta.github.io/sommieR/reference/reprise_source.md).

## Usage

``` r
valider_reprise(reprise)
```

## Arguments

- reprise:

  Liste nommee.

## Value

Le bloc valide, normalise.

## Examples

``` r
valider_reprise(list(source = "tableur", reference = "Suivi coupes.xlsx"))
#> $source
#> [1] "tableur"
#> 
#> $reference
#> [1] "Suivi coupes.xlsx"
#> 
```
