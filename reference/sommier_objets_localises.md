# Objets localises du sommier

Rend les entrees qui portent une geometrie, tous registres confondus, en
WKT et en Lambert-93.

## Usage

``` r
sommier_objets_localises(
  con,
  foret_id,
  registres = NULL,
  debut = NULL,
  fin = NULL
)
```

## Arguments

- con:

  Connexion DBI.

- foret_id:

  UUID de la foret.

- registres:

  Registres a retenir (defaut : tous).

- debut, fin:

  Bornes de la periode (`NULL` : sans borne). Le patrimoine remarquable
  se consulte sans bornes - c'est un etat courant.

## Value

Un `data.frame` : `id`, `registre`, `date_evenement`, `designation`,
`type_objet`, `type_geometrie`, `wkt`.

## Details

La geometrie qui fait foi est celle du payload, en WGS84 et chainee avec
l'entree ; celle rendue ici est sa projection Lambert-93, posee par
declencheur a l'ecriture. C'est elle qu'on cartographie, parce qu'une
carte se mesure en metres — mais c'est le payload qu'on verifie.

Les entrees rectifiees ne remontent pas : la vue s'adosse a
`v_entree_courante`. Une borne deplacee apres coup montre sa position
actuelle, l'ancienne restant dans la chaine sans encombrer la carte.

## Examples

``` r
# Necessite une connexion :
# sommier_objets_localises(con, foret, registres = 9L)
```
