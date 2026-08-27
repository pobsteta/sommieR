# Validite d'un certificat a une date donnee

`quand`, non « maintenant ». Un jeton de 2019 reste bon apres
l'expiration du certificat qui l'a produit - c'est meme tout l'interet
de l'horodatage : il atteste qu'une empreinte existait a une date ou le
certificat, lui, etait valide.

## Usage

``` r
certificat_valide_a(certificat, quand)
```

## Arguments

- certificat:

  Objet
  [`certificat_lire()`](https://pobsteta.github.io/sommieR/reference/certificat_lire.md).

- quand:

  Date d'appreciation (`POSIXct`).

## Value

`TRUE` ou `FALSE`.
