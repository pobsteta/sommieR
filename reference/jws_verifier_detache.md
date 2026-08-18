# Verification d'une signature JWS detachee

Verification d'une signature JWS detachee

## Usage

``` r
jws_verifier_detache(jws, charge, cle_publique)
```

## Arguments

- jws:

  Jeton `en-tete..signature`.

- charge:

  Vecteur `raw` signe.

- cle_publique:

  Cle publique, lue par
  [`openssl::read_pubkey()`](https://jeroen.r-universe.dev/openssl/reference/read_key.html).

## Value

`TRUE` si la signature est valide, `FALSE` sinon.

## Examples

``` r
cle <- openssl::rsa_keygen(2048)
s <- signataire_cle(cle, claims = list(sub = "agent-01"))
charge <- openssl::rand_bytes(32)
jws <- jws_signer_detache(charge, s)
jws_verifier_detache(jws, charge, cle$pubkey)
#> [1] TRUE
```
