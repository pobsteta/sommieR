# Le certificat est-il celui d'une autorite d'horodatage ?

La RFC 3161 (section 2.3) exige que le certificat de l'autorite porte
l'extension d'usage `id-kp-timeStamping`, **et elle seule**, marquee
critique.

## Usage

``` r
certificat_horodateur(certificat)
```

## Arguments

- certificat:

  Objet
  [`certificat_lire()`](https://pobsteta.github.io/sommieR/reference/certificat_lire.md).

## Value

`TRUE` ou `FALSE`.

## Details

L'exigence n'est pas formelle. Un certificat de serveur web signant des
jetons d'horodatage ferait d'une cle prevue pour l'authentification une
cle d'attestation dans le temps : c'est exactement ce que l'extension
sert a empecher.
