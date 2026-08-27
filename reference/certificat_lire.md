# Lecture d'un certificat X.509

Rend ce dont la validation d'un jeton d'horodatage a besoin, et que
[`openssl::read_cert()`](https://jeroen.r-universe.dev/openssl/reference/read_key.html)
n'expose pas : les bornes de validite comme dates, les extensions, et
les octets exacts sur lesquels porte la signature.

## Usage

``` r
certificat_lire(der)
```

## Arguments

- der:

  Vecteur `raw` : le certificat encode en DER.

## Value

Un objet `sommier_certificat` : `der`, `tbs` (les octets signes),
`signature`, `condensat`, `serie`, `emetteur`, `sujet`, `debut`, `fin`,
`cle_publique`, `extensions`.

## Details

`emetteur` et `sujet` sont rendus **en octets**, non en texte :
rattacher un certificat a son emetteur se fait par egalite binaire des
noms encodes. Comparer des chaines rendues par un formateur ferait
dependre la confiance de la facon dont on imprime un nom.

## See also

[`certificat_horodateur()`](https://pobsteta.github.io/sommieR/reference/certificat_horodateur.md),
[`certificat_valide_a()`](https://pobsteta.github.io/sommieR/reference/certificat_valide_a.md)
