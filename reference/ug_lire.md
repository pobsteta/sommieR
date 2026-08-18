# Lecture d'unites de gestion

Lecture d'unites de gestion

## Usage

``` r
ug_lire(con, ug_uuid = NULL, foret_id = NULL, actives_seulement = FALSE)
```

## Arguments

- con:

  Connexion DBI.

- ug_uuid:

  UUID a lire ; toutes les unites de `foret_id` si absent.

- foret_id:

  UUID de la foret.

- actives_seulement:

  Ne rendre que les unites non cloturees.

## Value

Un `data.frame`.
