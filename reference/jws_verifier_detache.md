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

## Details

Une signature `ES256` est reconvertie en DER avant d'etre soumise a
[`openssl::signature_verify()`](https://jeroen.r-universe.dev/openssl/reference/signatures.html),
qui n'accepte que ce format. Sa longueur est d'abord verifiee : `ES256`
impose exactement 64 octets, et une signature plus courte revele une
implementation qui a concatene deux `bignum` sans les rembourrer. La
refuser franchement vaut mieux que de la reconvertir en un DER
syntaxiquement correct mais portant un `r` faux.

## Examples

``` r
cle <- openssl::rsa_keygen(2048)
s <- signataire_cle(cle, claims = list(sub = "agent-01"))
charge <- openssl::rand_bytes(32)
jws <- jws_signer_detache(charge, s)
jws_verifier_detache(jws, charge, cle$pubkey)
#> [1] TRUE
```
