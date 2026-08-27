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

Ce qui est garanti ici, c'est que l'autorite a accorde l'horodatage et
que le jeton est syntaxiquement exploitable. Son contenu se lit avec
[`tsa_lire_jeton()`](https://pobsteta.github.io/sommieR/reference/tsa_lire_jeton.md)
: empreinte attestee, date, nonce.

La signature de l'autorite et la chaine de certification qui la rattache
a une racine ne sont pas verifiees : cela demande un magasin de
confiance, et fait l'objet du lot suivant. En attendant,
`openssl ts -verify` s'en charge, en s'appuyant sur le certificat inclus
quand `demander_certificat` valait `TRUE`.
