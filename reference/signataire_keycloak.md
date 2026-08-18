# Signataire dont l'identite vient de Keycloak ou d'AgentConnect

Les claims sont extraits du jeton d'identite OIDC ; la signature reste
produite par la cle fournie.

## Usage

``` r
signataire_keycloak(
  jeton_id,
  cle,
  kid = NULL,
  claims_retenus = c("sub", "given_name", "usual_name", "family_name", "email", "siret",
    "iss")
)
```

## Arguments

- jeton_id:

  Jeton d'identite OIDC (JWT compact).

- cle:

  Cle privee servant a signer.

- kid:

  Identifiant de cle (facultatif).

- claims_retenus:

  Claims a archiver dans le visa. Par defaut ceux que le brief nomme,
  plus `siret`.

## Value

Un objet `sommier_signataire`.

## Details

Cette separation n'est pas un contournement, c'est le fonctionnement du
protocole : un fournisseur OIDC delivre des jetons attestant une
identite, il ne signe pas un contenu qu'on lui soumet. Le jeton prouve
**qui** est la personne, la cle produit la signature detachee sur la
tete de chaine. Pour un niveau eIDAS qualifie, `cle` doit etre remplacee
par un appel au service de signature du prestataire - c'est exactement
ce que permet le parametre `signer` de
[`sommier_signataire()`](https://pobsteta.github.io/sommieR/reference/sommier_signataire.md).

Le jeton n'est pas verifie ici : sa validite releve du client OIDC qui
l'a obtenu. Ce qui est archive dans le visa, ce sont ses claims.
