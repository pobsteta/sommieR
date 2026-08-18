# Construction d'une entree de sommier

Prepare une entree valide mais **non encore chainee** : `seq`,
`hash_prev` et `hash` sont affectes au moment de l'insertion, par
[`sommier_chainer()`](https://pobsteta.github.io/sommieR/reference/sommier_chainer.md)
hors base ou par
[`sommier_ajouter()`](https://pobsteta.github.io/sommieR/reference/sommier_ajouter.md)
en base. Cette separation est volontaire - la position dans la chaine
n'est pas une propriete de l'entree, c'est une propriete du registre au
moment ou on l'y ecrit.

## Usage

``` r
sommier_entree(
  foret_id,
  registre,
  date_evenement,
  auteur,
  payload,
  ug_uuid = NULL,
  ndp = 0L,
  corrige_id = NULL,
  date_saisie = Sys.time(),
  id = uuid_v4()
)
```

## Arguments

- foret_id:

  UUID de la foret.

- registre:

  Numero de registre, parmi
  [SOMMIER_REGISTRES_OUVERTS](https://pobsteta.github.io/sommieR/reference/SOMMIER_REGISTRES_OUVERTS.md).

- date_evenement:

  Date de l'evenement enregistre (`Date` ou `"AAAA-MM-JJ"`) - celle du
  fait, pas celle de la saisie.

- auteur:

  Identifiant de l'auteur (`sub` OIDC Keycloak).

- payload:

  Liste nommee produite par
  [`registre5_coupe()`](https://pobsteta.github.io/sommieR/reference/registre5_coupe.md)
  ou
  [`registre6_travaux()`](https://pobsteta.github.io/sommieR/reference/registre6_travaux.md).

- ug_uuid:

  UUID de l'unite de gestion, ou `NULL` pour une entree a l'echelle de
  la foret.

- ndp:

  Niveau de precision nemeton (entier \>= 0, defaut 0).

- corrige_id:

  UUID de l'entree que celle-ci rectifie, le cas echeant.

- date_saisie:

  Instant de saisie (`POSIXct` ou `"AAAA-MM-JJTHH:MM:SSZ"`). Par defaut
  l'instant courant en UTC. Il est couvert par l'empreinte, il doit donc
  etre fixe par l'ecrivain, pas par l'horloge du serveur.

- id:

  UUID de l'entree ; genere si absent.

## Value

Un objet de classe `sommier_entree`.

## Details

Le champ `ndp` raccorde le sommier au systeme nemeton (brief, section 4)
: une entree saisie sur le terrain est NDP 0 par definition, une entree
deduite de teledetection porte le NDP de sa source. La valeur par defaut
est donc 0, le sommier etant le receptacle NDP 0 de la plateforme.

Une correction ne modifie jamais l'entree fautive : elle prend la forme
d'une nouvelle entree portant `corrige_id`. C'est le comportement du
classeur papier, ou la rature est interdite et la rectification se fait
par mention nouvelle.

## Examples

``` r
sommier_entree(
  foret_id = "3f2b1c4d-5e6f-4a7b-8c9d-0e1f2a3b4c5d",
  registre = 6L,
  date_evenement = "2026-04-15",
  auteur = "agent-01",
  payload = registre6_travaux(annee = 2026, nature_travaux = "degagement")
)
#> <entree de sommier>
#>   registre  : 6 - Travaux
#>   foret     : 3f2b1c4d-5e6f-4a7b-8c9d-0e1f2a3b4c5d
#>   ug        : (echelle foret)
#>   evenement : 2026-04-15
#>   auteur    : agent-01 (NDP 0)
#>   chainage  : non chainee
#>   payload   : {"annee":2026,"nature_travaux":"degagement"}
```
