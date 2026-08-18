# Creation d'une unite de gestion

L'UUID produit est stable a vie : il ne doit jamais etre reattribue,
meme apres cloture de l'unite. Le `numero_affichage`, lui, peut changer
a chaque revision d'amenagement.

## Usage

``` r
ug_creer(
  con,
  foret_id,
  numero_affichage,
  date_debut,
  serie_id = NULL,
  parent_uuid = NULL,
  uuid = uuid_v4()
)
```

## Arguments

- con:

  Connexion DBI.

- foret_id:

  UUID de la foret.

- numero_affichage:

  Numero de parcelle affiche.

- date_debut:

  Date d'entree en vigueur.

- serie_id:

  UUID de la serie (facultatif).

- parent_uuid:

  UUID de l'unite dont celle-ci procede (facultatif).

- uuid:

  UUID a affecter ; genere si absent.

## Value

L'UUID de l'unite creee.
