# Payload du registre 1 - validations

Construit et valide le payload d'une entree du registre 1 (imprime A10
et actes de validation du document de gestion). C'est ce registre qui
rend le sommier opposable : il trace qui a valide quoi, et quand.

## Usage

``` r
registre1_validation(
  type_validation,
  autorite,
  nom_qualite,
  exercice = NULL,
  reference = NULL,
  date_effet = NULL,
  portee = NULL,
  observations = NULL
)
```

## Arguments

- type_validation:

  L'un de
  [SOMMIER_TYPES_VALIDATION](https://pobsteta.github.io/sommieR/reference/SOMMIER_TYPES_VALIDATION.md).

- autorite:

  L'un de
  [SOMMIER_AUTORITES](https://pobsteta.github.io/sommieR/reference/SOMMIER_AUTORITES.md).

- nom_qualite:

  Nom et qualite du signataire, tels que portes sur l'imprime.

- exercice:

  Exercice couvert (entier), pour un visa annuel.

- reference:

  Reference de l'acte : numero d'arrete, de deliberation, d'agrement
  (facultatif).

- date_effet:

  Date d'effet si elle differe de la date de l'acte (facultatif).

- portee:

  Portee de l'acte : `"sommier"`, `"amenagement"`, `"psg"` (facultatif).

- observations:

  Observations libres (facultatif).

## Value

Une liste nommee, prete a etre passee a
[`sommier_entree()`](https://pobsteta.github.io/sommieR/reference/sommier_entree.md).

## Details

Ce registre enregistre l'**acte** de validation. Il ne porte pas la
signature cryptographique, qui vit dans la table `visa` et couvre la
tete de chaine : voir
[`sommier_viser()`](https://pobsteta.github.io/sommieR/reference/sommier_viser.md).
Les deux sont complementaires - le registre dit qu'un visa a ete donne,
la table `visa` prouve sur quel etat du sommier il portait.

## Examples

``` r
registre1_validation(
  type_validation = "visa_annuel", autorite = "commune",
  nom_qualite = "Maire de Chaux", exercice = 2026
)
#> $type_validation
#> [1] "visa_annuel"
#> 
#> $autorite
#> [1] "commune"
#> 
#> $nom_qualite
#> [1] "Maire de Chaux"
#> 
#> $exercice
#> [1] 2026
#> 
```
