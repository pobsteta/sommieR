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
