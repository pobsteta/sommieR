# Generation d'un UUID version 4

Utilise le generateur d'aleas cryptographique d'openssl : les
identifiants d'unites de gestion ne doivent jamais entrer en collision
ni etre devinables, puisqu'ils sont stables a vie.

## Usage

``` r
uuid_v4(n = 1L)
```

## Arguments

- n:

  Nombre d'identifiants a produire.

## Value

Un vecteur de caracteres.

## Examples

``` r
uuid_v4()
#> [1] "f1d7dcd1-6b62-4daa-b871-bbd683154af0"
```
