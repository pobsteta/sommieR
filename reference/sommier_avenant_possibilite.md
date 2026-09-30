# Avenant a un amenagement : la possibilite, la surface ou la fin changent

Ecrit l'avenant qui change, a partir d'un exercice, la possibilite a
l'hectare d'un amenagement, la surface a laquelle elle s'applique, sa
fin, ou plusieurs de ces elements.

## Usage

``` r
sommier_avenant_possibilite(
  con,
  foret_id,
  amenagement_id,
  a_partir_de,
  autorite,
  nom_qualite,
  date_acte,
  auteur,
  reference = NULL,
  possibilite_m3_ha_an = NULL,
  surface_ha = NULL,
  annee_fin = NULL,
  ventilation = NULL,
  source = NULL
)
```

## Arguments

- con:

  Connexion DBI.

- foret_id:

  UUID de la foret.

- amenagement_id:

  Identifiant de l'amenagement modifie.

- a_partir_de:

  Premier exercice auquel l'avenant s'applique.

- autorite, nom_qualite, date_acte, auteur, reference:

  Comme pour
  [`sommier_amenagement()`](https://pobsteta.github.io/sommieR/reference/sommier_amenagement.md).

- possibilite_m3_ha_an:

  Nouvelle possibilite a l'hectare (facultatif).

- surface_ha:

  Nouvelle surface (facultatif).

- annee_fin:

  Nouvelle fin de l'amenagement (facultatif).

- ventilation:

  Nouvelle ventilation, en m3/ha/an (facultatif).

- source:

  Page ou tableau de l'avenant (facultatif).

## Value

Invisiblement, l'entree chainee.

## Details

Les exercices anterieurs a `a_partir_de` gardent la possibilite qu'ils
avaient : un avenant ne recrit pas le passe, il dit ce qui vaut
desormais. La balance cite, pour chaque exercice, l'acte dont vient sa
possibilite. Changer la surface - une distraction, une acquisition -
change le volume annuel sans changer le taux.

Avancer la fin clot l'amenagement - c'est ce qui permet une revision
anticipee. La reculer n'est admis que si aucun autre amenagement ne
couvre deja les exercices gagnes.

## See also

[`sommier_amenagement()`](https://pobsteta.github.io/sommieR/reference/sommier_amenagement.md)
