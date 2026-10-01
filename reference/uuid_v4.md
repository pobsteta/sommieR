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
#> [1] "53cabcf2-4f99-488e-8772-6476f9611da3"
```
