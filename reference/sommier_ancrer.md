# Ancrage periodique de la tete de chaine

Horodate la tete de chaine independamment de tout visa. Le brief
(section 6.3) en fait une tache periodique : elle garantit qu'un
exercice non vise ne peut pas non plus etre reecrit discretement.

## Usage

``` r
sommier_ancrer(con, foret_id, tsa_url, transport = tsa_transport_curl())
```

## Arguments

- con:

  Connexion DBI.

- foret_id:

  UUID de la foret.

- tsa_url:

  URL de l'autorite d'horodatage.

- transport:

  Transport HTTP, voir
  [`tsa_transport_curl()`](https://pobsteta.github.io/sommieR/reference/tsa_transport_curl.md).

## Value

Invisiblement, une liste : `id`, `seq_tete`, `hash_tete`.
