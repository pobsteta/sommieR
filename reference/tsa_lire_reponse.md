# Lecture d'une reponse d'horodatage RFC 3161

Verifie le `PKIStatus` et extrait le jeton d'horodatage.

## Usage

``` r
tsa_lire_reponse(reponse)
```

## Arguments

- reponse:

  Vecteur `raw` : la reponse DER de l'autorite.

## Value

Une liste : `statut` (entier), `libelle`, `jeton` (`raw` ou `NULL`).

## Details

Le jeton est rendu tel quel, sans verification cryptographique de la
chaine de certification de l'autorite : celle-ci exige un magasin de
confiance et une validation CMS complete, hors de portee de ce paquet.
Ce qui est garanti ici, c'est que l'autorite a accorde l'horodatage et
que le jeton est syntaxiquement exploitable. La verification complete se
fait avec `openssl ts -verify`, en s'appuyant sur le certificat inclus
quand `demander_certificat` valait `TRUE`.
