# Lecture du contenu d'un jeton d'horodatage

Rend le `TSTInfo` que le jeton encapsule (RFC 3161 section 2.4.2) : ce
que l'autorite a horodate, et quand.

## Usage

``` r
tsa_lire_jeton(jeton)
```

## Arguments

- jeton:

  Vecteur `raw` : le `TimeStampToken` rendu par
  [`tsa_horodater()`](https://pobsteta.github.io/sommieR/reference/tsa_horodater.md).

## Value

Un objet `sommier_jeton_tsa` : `empreinte` (`raw`), `algorithme`, `date`
(`POSIXct` UTC), `serie` et `nonce` (hexadecimal), `politique` (OID
pointe), `version`.

## Details

Sans cette lecture, un jeton n'est qu'une colonne non vide. Le paquet
saurait dire qu'un visa « est horodate » sans savoir ni a quelle date,
ni sur quelle empreinte : un jeton parfaitement valide, obtenu pour une
autre tete de chaine - une autre foret, un autre exercice - passerait
exactement comme le bon.

Ce que cette fonction ne fait pas : verifier la signature de l'autorite
et la chaine de certification qui la rattache a une racine. Un `TSTInfo`
lu n'est pas un `TSTInfo` authentifie ; c'est l'objet du lot suivant,
cadre dans `specs/brief_probant-2`. La lecture n'exige, elle, aucun
magasin de confiance et aucun reseau.

## See also

[`tsa_horodater()`](https://pobsteta.github.io/sommieR/reference/tsa_horodater.md),
[`tsa_lire_reponse()`](https://pobsteta.github.io/sommieR/reference/tsa_lire_reponse.md)
