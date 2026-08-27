# Construction d'un signataire

Contrat generique attendu par
[`sommier_viser()`](https://pobsteta.github.io/sommieR/reference/sommier_viser.md)
: des claims d'identite, et de quoi signer. Les deux sont volontairement
separes, parce qu'ils viennent de sources differentes - le fournisseur
d'identite (Keycloak, AgentConnect) atteste **qui** signe, une cle ou un
service de signature eIDAS produit **la** signature. Keycloak ne signe
pas de contenu arbitraire.

## Usage

``` r
sommier_signataire(claims, signer, alg = "RS256", kid = NULL)
```

## Arguments

- claims:

  Liste nommee des claims d'identite (au minimum `sub`).

- signer:

  Fonction prenant un vecteur `raw` et rendant la signature, en `raw`,
  au format JOSE de `alg`.

- alg:

  Algorithme JOSE, parmi
  [SOMMIER_ALGOS_JWS](https://pobsteta.github.io/sommieR/reference/SOMMIER_ALGOS_JWS.md).

- kid:

  Identifiant de cle, porte dans l'en-tete JWS (facultatif).

## Value

Un objet de classe `sommier_signataire`.

## Details

`signer` doit rendre la signature **au format que JOSE attend pour
`alg`** : pour `ES256`, les 64 octets `R||S`, et non le DER que produit
OpenSSL.
[`signataire_cle()`](https://pobsteta.github.io/sommieR/reference/signataire_cle.md)
s'en charge, puisqu'elle tient la cle ; un service de signature externe
branche ici doit le faire de son cote. Le paquet ne devine pas le format
rendu : une signature ECDSA en DER peut, tres rarement, faire exactement
64 octets, et un reniflage se tromperait alors sans que rien ne le
signale.

## See also

[`signataire_cle()`](https://pobsteta.github.io/sommieR/reference/signataire_cle.md),
[`signataire_keycloak()`](https://pobsteta.github.io/sommieR/reference/signataire_keycloak.md)
