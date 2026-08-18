# Fusion d'unites de gestion

Clot les unites d'origine et cree l'unite resultante. La filiation a
plusieurs parents n'etant pas representable par la colonne
`parent_uuid`, elle est portee par la table `ug_filiation`.

## Usage

``` r
ug_fusionner(con, ug_uuids, numero_affichage, date_effet, serie_id = NULL)
```

## Arguments

- con:

  Connexion DBI.

- ug_uuids:

  UUID des unites a fusionner (au moins deux).

- numero_affichage:

  Numero de l'unite resultante.

- date_effet:

  Date d'effet de la fusion.

- serie_id:

  Serie de l'unite resultante (facultatif : celle de la premiere unite
  fusionnee par defaut).

## Value

L'UUID de l'unite creee.
