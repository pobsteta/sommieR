# Signataire adosse a une cle privee

L'algorithme se deduit de la cle : `RS256` pour une cle RSA, `ES256`
pour une cle ECDSA sur P-256.

## Usage

``` r
signataire_cle(cle, claims, kid = NULL, certificat = NULL)
```

## Arguments

- cle:

  Cle privee lue par
  [`openssl::read_key()`](https://jeroen.r-universe.dev/openssl/reference/read_key.html),
  RSA ou ECDSA P-256.

- claims:

  Liste nommee des claims d'identite.

- kid:

  Identifiant de cle (facultatif).

- certificat:

  Certificat X.509 du signataire, en DER (`raw`).

## Value

Un objet `sommier_signataire`.

## Details

Il n'est volontairement pas demandable. Laisser l'appelant declarer
`alg` tout en passant une cle d'un autre type produirait un en-tete
annoncant `RS256` au-dessus d'une signature ECDSA : invalide partout, y
compris ici, et decouvert seulement au moment ou quelqu'un cherche a
verifier le visa - c'est-a-dire trop tard.

La conversion vers le format JOSE est faite ici : `openssl` signe en
DER, `ES256` veut du `R||S`, voir
[`ecdsa_der_vers_brut()`](https://pobsteta.github.io/sommieR/reference/ecdsa_der_vers_brut.md).

## Examples

``` r
cle <- openssl::rsa_keygen(2048)
signataire_cle(cle, claims = list(sub = "agent-01", name = "Maire"))
#> <signataire de sommier>
#>   sub : agent-01
#>   alg : RS256

# Une cle ECDSA donne un signataire ES256, sans rien declarer.
signataire_cle(openssl::ec_keygen("P-256"), claims = list(sub = "agent-02"))
#> <signataire de sommier>
#>   sub : agent-02
#>   alg : ES256
```
