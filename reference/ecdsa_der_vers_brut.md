# Conversion d'une signature ECDSA du DER vers le format JOSE

OpenSSL encode une signature ECDSA en DER
(`SEQUENCE { INTEGER r, INTEGER s }`), JOSE l'attend en `R||S` : les
deux composantes concatenees, chacune sur la taille de la courbe.

## Usage

``` r
ecdsa_der_vers_brut(der, taille = TAILLE_COMPOSANTE_ES256)
```

## Arguments

- der:

  Signature encodee en DER (`raw`).

- taille:

  Taille d'une composante, en octets. 32 pour P-256.

## Value

Un vecteur `raw` de `2 * taille` octets.

## Details

Le rembourrage n'est pas une precaution de style.
[`openssl::ecdsa_parse()`](https://jeroen.r-universe.dev/openssl/reference/signatures.html)
rend deux `bignum`, et un `bignum` ne porte pas ses zeros de tete : une
composante dont le premier octet est nul s'y presente sur 31 octets. Sur
4 000 signatures P-256 mesurees, 29 - soit 0,72 % - ont au moins une
composante courte. Les concatener telles quelles produirait une
signature de 63 octets, refusee par toute autre implementation JOSE, et
le defaut ne se manifesterait qu'une fois sur cent quarante.

## See also

[`ecdsa_brut_vers_der()`](https://pobsteta.github.io/sommieR/reference/ecdsa_brut_vers_der.md)
