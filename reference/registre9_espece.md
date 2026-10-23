# Payload du registre 9 - espece protegee (imprimes A50 r/e et r/s)

Payload du registre 9 - espece protegee (imprimes A50 r/e et r/s)

## Usage

``` r
registre9_espece(
  nom_francais,
  nom_latin,
  statut_protection = NULL,
  effectif = NULL,
  localisation = NULL,
  bibliographie = NULL,
  observations = NULL,
  geometrie = NULL,
  cd_nom = NULL,
  taxref = NULL
)
```

## Arguments

- nom_francais:

  Nom francais.

- nom_latin:

  Nom scientifique.

- statut_protection:

  Statut : protection nationale, regionale, directive Habitats, liste
  rouge (facultatif).

- effectif:

  Effectif ou nombre de stations observees (facultatif).

- localisation:

  Localisation en clair (facultatif).

- bibliographie:

  References bibliographiques (facultatif).

- observations:

  Observations libres (facultatif).

- geometrie:

  Position de l'objet, en WGS84 : voir
  [`geom_point()`](https://pobsteta.github.io/sommieR/reference/geometries.md).
  Facultative — un gestionnaire sans releve continue de saisir sans, et
  son sommier reste conforme.

- cd_nom:

  `CD_NOM` de l'espece dans TAXREF (facultatif) : le registre nomme lui
  aussi dans le referentiel national, et la fiche se rapproche des
  especes observees sans passer par le nom.

- taxref:

  TAXREF, tel que le rend
  [`sommier_taxref()`](https://pobsteta.github.io/sommieR/reference/sommier_taxref.md)
  (facultatif) : s'il est fourni, `cd_nom` doit y figurer parmi les
  especes, et `nom_latin` y etre son nom ou son nom valide. Il sert au
  controle et n'est pas ecrit.

## Value

Une liste nommee, prete a etre passee a
[`sommier_entree()`](https://pobsteta.github.io/sommieR/reference/sommier_entree.md).

## Details

Le `cd_nom` est entre au registre 9 avec le schema `r9-1.3.0`. Une fiche
anterieure, sans `cd_nom`, reste valide et se relit a l'identique.

## Examples

``` r
registre9_espece(
  nom_francais = "Sabot de Venus", nom_latin = "Cypripedium calceolus",
  statut_protection = "Directive Habitats, annexe II", effectif = 34
)
#> $type_fiche
#> [1] "espece"
#> 
#> $nom_francais
#> [1] "Sabot de Venus"
#> 
#> $nom_latin
#> [1] "Cypripedium calceolus"
#> 
#> $statut_protection
#> [1] "Directive Habitats, annexe II"
#> 
#> $effectif
#> [1] 34
#> 
```
