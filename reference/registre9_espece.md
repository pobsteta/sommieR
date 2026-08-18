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
  observations = NULL
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

## Value

Une liste nommee, prete a etre passee a
[`sommier_entree()`](https://pobsteta.github.io/sommieR/reference/sommier_entree.md).

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
