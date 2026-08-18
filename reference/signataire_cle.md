# Signataire adosse a une cle privee

Signataire adosse a une cle privee

## Usage

``` r
signataire_cle(cle, claims, kid = NULL)
```

## Arguments

- cle:

  Cle privee lue par
  [`openssl::read_key()`](https://jeroen.r-universe.dev/openssl/reference/read_key.html).

- claims:

  Liste nommee des claims d'identite.

- kid:

  Identifiant de cle (facultatif).

## Value

Un objet `sommier_signataire`.

## Examples

``` r
cle <- openssl::rsa_keygen(2048)
signataire_cle(cle, claims = list(sub = "agent-01", name = "Maire"))
#> <signataire de sommier>
#>   sub : agent-01
#>   alg : RS256
```
