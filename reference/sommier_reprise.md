# Construction d'une entree transcrite depuis l'existant

Prepare une entree qui **transcrit** un fait anterieur au sommier - une
coupe de 1998 lue dans le registre papier, un arrete retrouve aux
archives de la commune - au lieu de le constater. Comme
[`sommier_entree()`](https://pobsteta.github.io/sommieR/reference/sommier_entree.md),
elle rend une entree non encore chainee ; elle s'ecrit par
[`sommier_reprendre()`](https://pobsteta.github.io/sommieR/reference/sommier_reprendre.md).

## Usage

``` r
sommier_reprise(
  foret_id,
  registre,
  date_evenement,
  auteur,
  payload,
  source,
  ug_uuid = NULL,
  ndp = NULL,
  corrige_id = NULL,
  id = uuid_v4(),
  ...
)
```

## Arguments

- foret_id:

  UUID de la foret.

- registre:

  Numero de registre, parmi
  [SOMMIER_REGISTRES_OUVERTS](https://pobsteta.github.io/sommieR/reference/SOMMIER_REGISTRES_OUVERTS.md).

- date_evenement:

  Date du fait transcrit (`Date` ou `"AAAA-MM-JJ"`).

- auteur:

  Identifiant de qui transcrit - pas de qui a constate a l'epoque :
  c'est bien une ecriture d'aujourd'hui.

- payload:

  Liste nommee produite par un constructeur de registre.

- source:

  Bloc de provenance produit par
  [`reprise_source()`](https://pobsteta.github.io/sommieR/reference/reprise_source.md).

- ug_uuid:

  UUID de l'unite de gestion, ou `NULL`.

- ndp:

  Niveau de precision (entier \>= 1). Par defaut, celui que
  [SOMMIER_SOURCES_REPRISE](https://pobsteta.github.io/sommieR/reference/SOMMIER_SOURCES_REPRISE.md)
  attache a la provenance.

- corrige_id:

  UUID de l'entree que celle-ci rectifie, le cas echeant - une
  transcription fautive se rectifie comme le reste, par une entree de
  plus.

- id:

  UUID de l'entree ; genere si absent.

- ...:

  Aucun autre argument n'est admis. `date_saisie` en particulier est
  refuse, avec un message qui dit pourquoi.

## Value

Un objet de classe `sommier_reprise`, qui herite de `sommier_entree`.

## Details

Une reprise se distingue d'un constat sur trois points, et ces trois
points sont imposes ici plutot que laisses a la discipline de l'appelant
:

- **`date_saisie` est l'instant reel de la transcription.** Le champ est
  pose par la fonction et ne peut pas lui etre dicte : le lui permettre
  laisserait antidater une reprise, et une chaine qui peut etre
  convaincue d'avoir su plus tot qu'elle n'a su ne vaut rien. La date du
  fait, elle, se porte par `date_evenement`, qui remonte aussi loin
  qu'il le faut.

- **Le NDP est strictement superieur a 0.** NDP 0 designe le constat de
  terrain ; une recopie n'en est pas un. C'est la regle deja appliquee
  aux detections par
  [`sommier_importer_detections()`](https://pobsteta.github.io/sommieR/reference/sommier_importer_detections.md),
  transposee a une autre provenance.

- **La source est citee.** Sans reference de piece, une reprise ne se
  distingue pas d'une invention. Il n'y a donc pas de defaut a `source`.

La sequence, elle, n'est pas rejouee : les entrees reprises s'ajoutent a
la suite de ce qui est deja ecrit. Le sommier date l'histoire, il ne la
reordonne pas - une reprise de trente ans forme un bloc d'entrees
contigues dont les dates d'evenement remontent le temps.

## See also

[`sommier_reprendre()`](https://pobsteta.github.io/sommieR/reference/sommier_reprendre.md),
[`reprise_source()`](https://pobsteta.github.io/sommieR/reference/reprise_source.md),
[`sommier_entree()`](https://pobsteta.github.io/sommieR/reference/sommier_entree.md)

## Examples

``` r
sommier_reprise(
  foret_id = "3f2b1c4d-5e6f-4a7b-8c9d-0e1f2a3b4c5d",
  registre = 5L,
  date_evenement = "1998-03-12",
  auteur = "agent-01",
  payload = registre5_coupe(
    type_entree = "martelage", exercice = 1998,
    nature_coupe = "amelioration", volume_m3 = 210
  ),
  source = reprise_source(
    "registre_signe",
    "Sommier papier, imprime A50E, exercice 1998, folio 12"
  )
)
#> <entree de sommier>
#>   registre  : 5 - Coupes & recoltes
#>   foret     : 3f2b1c4d-5e6f-4a7b-8c9d-0e1f2a3b4c5d
#>   ug        : (echelle foret)
#>   evenement : 1998-03-12
#>   auteur    : agent-01 (NDP 1)
#>   chainage  : non chainee
#>   payload   : {"exercice":1998,"nature_coupe":"amelioration","reprise":{"reference":"Sommier papier, imprime A50E, exercice 1998, folio 12","source":"registre_signe"},"type_entree":"martelage","volume_m3":210}
#>   transcrit : registre_signe (NDP 1) - Sommier papier, imprime A50E, exercice 1998, folio 12
```
