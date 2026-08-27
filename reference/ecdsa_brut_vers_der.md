# Conversion d'une signature ECDSA du format JOSE vers le DER

L'inverse
d'[`ecdsa_der_vers_brut()`](https://pobsteta.github.io/sommieR/reference/ecdsa_der_vers_brut.md)
:
[`openssl::signature_verify()`](https://jeroen.r-universe.dev/openssl/reference/signatures.html)
attend du DER, une signature JOSE n'en est pas.

## Usage

``` r
ecdsa_brut_vers_der(brut)
```

## Arguments

- brut:

  Signature `R||S` (`raw`), de longueur paire.

## Value

Un vecteur `raw` : la signature encodee en DER.

## See also

[`ecdsa_der_vers_brut()`](https://pobsteta.github.io/sommieR/reference/ecdsa_der_vers_brut.md)
