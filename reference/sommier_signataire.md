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

  Fonction prenant un vecteur `raw` et rendant la signature, en `raw`.

- alg:

  Algorithme JOSE, parmi
  [SOMMIER_ALGOS_JWS](https://pobsteta.github.io/sommieR/reference/SOMMIER_ALGOS_JWS.md).

- kid:

  Identifiant de cle, porte dans l'en-tete JWS (facultatif).

## Value

Un objet de classe `sommier_signataire`.

## See also

[`signataire_cle()`](https://pobsteta.github.io/sommieR/reference/signataire_cle.md),
[`signataire_keycloak()`](https://pobsteta.github.io/sommieR/reference/signataire_keycloak.md)
