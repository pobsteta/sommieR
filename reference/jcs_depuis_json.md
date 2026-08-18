# Recanonisation d'un document JSON existant

Utile pour verifier une chaine a partir d'un export : le payload y est
du texte JSON, qu'il faut recanoniser avant de recalculer l'empreinte.

## Usage

``` r
jcs_depuis_json(texte)
```

## Arguments

- texte:

  Chaine de caracteres contenant un document JSON.

## Value

La forme canonique JCS de ce document.

## Examples

``` r
jcs_depuis_json('{"b":1,"a":2}')
#> [1] "{\"a\":2,\"b\":1}"
#> {"a":2,"b":1}
```
