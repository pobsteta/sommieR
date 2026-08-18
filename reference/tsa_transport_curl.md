# Transport HTTP pour l'horodatage

Rend la fonction qui poste une requete DER a l'autorite. Le transport
est un parametre et non un appel en dur : les tests injectent une
autorite simulee, et un deploiement ferme peut brancher son propre
client.

## Usage

``` r
tsa_transport_curl(timeout = 30)
```

## Arguments

- timeout:

  Delai maximal, en secondes.

## Value

Une fonction `(url, corps) -> raw`.
