# Signature JWS detachee sur charge non encodee

Produit une signature JWS detachee au sens des RFC 7515 et 7797 :
l'en-tete declare `"b64": false`, la charge utile ne transite pas dans
le jeton, et l'entree de signature est
`BASE64URL(en-tete) || "." || charge`.

## Usage

``` r
jws_signer_detache(charge, signataire)
```

## Arguments

- charge:

  Vecteur `raw` a signer.

- signataire:

  Objet
  [`sommier_signataire()`](https://pobsteta.github.io/sommieR/reference/sommier_signataire.md).

## Value

Une chaine `en-tete..signature` (charge omise, d'ou le double point).

## Details

La charge est ici les 32 octets bruts de la tete de chaine. La signer
detachee plutot qu'encodee evite de recopier dans le jeton une valeur
qui vit deja dans la base : le verificateur la relit du registre, ce qui
lie la signature a la chaine et non a une copie.
