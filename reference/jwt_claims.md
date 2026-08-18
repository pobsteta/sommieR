# Claims d'un jeton JWT

Decode la charge utile d'un JWT compact. **Ne verifie pas la signature**
: la validation du jeton releve du client OIDC qui l'a obtenu.

## Usage

``` r
jwt_claims(jeton)
```

## Arguments

- jeton:

  JWT compact (`en-tete.charge.signature`).

## Value

Une liste nommee.
