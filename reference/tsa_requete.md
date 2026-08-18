# Requete d'horodatage RFC 3161

Encode une `TimeStampReq` (RFC 3161 section 2.4.1) portant l'empreinte
SHA-256 a horodater.

## Usage

``` r
tsa_requete(empreinte, nonce = NULL, demander_certificat = TRUE)
```

## Arguments

- empreinte:

  Vecteur `raw` de 32 octets.

- nonce:

  Entier aleatoire liant la reponse a la requete. Un nonce permet de
  detecter le rejeu d'une reponse anterieure.

- demander_certificat:

  Demander a l'autorite d'inclure son certificat dans le jeton, ce qui
  rend celui-ci verifiable de facon autonome.

## Value

Un vecteur `raw` : la requete encodee en DER.
