# Algorithmes de signature reconnus

- `RS256` : RSASSA-PKCS1-v1_5 avec SHA-256, algorithme par defaut de
  Keycloak et d'AgentConnect.

- `ES256` : ECDSA sur P-256 avec SHA-256.

## Usage

``` r
SOMMIER_ALGOS_JWS
```

## Format

An object of class `character` of length 2.

## Details

`ES256` demande une conversion, parce que JOSE veut la signature en
`R||S` brut la ou OpenSSL la produit encodee en DER.
[`ecdsa_der_vers_brut()`](https://pobsteta.github.io/sommieR/reference/ecdsa_der_vers_brut.md)
et
[`ecdsa_brut_vers_der()`](https://pobsteta.github.io/sommieR/reference/ecdsa_brut_vers_der.md)
la font dans les deux sens.

Seule la courbe P-256 est acceptee : `ES384` et `ES512` supposent des
composantes de 48 et 66 octets, et les rembourrer a 32 tronquerait la
signature.
