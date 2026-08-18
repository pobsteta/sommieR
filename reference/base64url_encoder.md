# Encodage base64url (RFC 4648 section 5)

Variante du base64 sans remplissage, ou `+` et `/` deviennent `-` et
`_`. C'est l'encodage impose par JOSE pour les en-tetes et les
signatures.

## Usage

``` r
base64url_encoder(x)
```

## Arguments

- x:

  Vecteur `raw` ou chaine de caracteres.

## Value

Une chaine de caracteres.
