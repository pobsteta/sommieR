# Scission d'une unite de gestion

Clot l'unite d'origine et cree les unites issues du decoupage, en
enregistrant la filiation. L'unite d'origine n'est jamais supprimee :
les entrees de sommier qui la referencent restent lisibles, ce qui est
tout l'interet d'un identifiant stable.

## Usage

``` r
ug_scinder(con, ug_uuid, enfants, date_effet)
```

## Arguments

- con:

  Connexion DBI.

- ug_uuid:

  UUID de l'unite a scinder.

- enfants:

  `data.frame` ou liste de listes a colonnes `numero_affichage` et,
  facultativement, `serie_id`.

- date_effet:

  Date d'effet de la scission.

## Value

Le vecteur des UUID crees.
