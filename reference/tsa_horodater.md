# Obtention d'un jeton d'horodatage

Obtention d'un jeton d'horodatage

## Usage

``` r
tsa_horodater(empreinte, url, transport = tsa_transport_curl(), nonce = NULL)
```

## Arguments

- empreinte:

  Vecteur `raw` de 32 octets a horodater.

- url:

  URL de l'autorite d'horodatage.

- transport:

  Fonction de transport, voir
  [`tsa_transport_curl()`](https://pobsteta.github.io/sommieR/reference/tsa_transport_curl.md).

- nonce:

  Nonce a employer (facultatif).

## Value

Un vecteur `raw` : le jeton d'horodatage.
