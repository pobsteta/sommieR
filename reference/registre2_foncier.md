# Payload du registre 2 - foncier et limites (imprime A40)

Une operation foncière : limite, mouvement de propriete, servitude, ou
application du regime forestier.

## Usage

``` r
registre2_foncier(
  type_entree,
  description,
  heures_ingenieur = NULL,
  heures_technicien = NULL,
  arpentage_eur = NULL,
  nb_bornes = NULL,
  cout_total_eur = NULL,
  charge_proprietaire_eur = NULL,
  charge_riverains_eur = NULL,
  surface_ha = NULL,
  reference_acte = NULL,
  references_cadastrales = NULL,
  beneficiaire = NULL,
  observations = NULL
)
```

## Arguments

- type_entree:

  L'un de
  [SOMMIER_TYPES_FONCIER](https://pobsteta.github.io/sommieR/reference/SOMMIER_TYPES_FONCIER.md).

- description:

  Description de l'operation.

- heures_ingenieur, heures_technicien:

  Temps passe (facultatif).

- arpentage_eur:

  Frais d'arpentage (facultatif).

- nb_bornes:

  Nombre de bornes fournies et posees (facultatif).

- cout_total_eur:

  Cout total de l'operation (facultatif).

- charge_proprietaire_eur, charge_riverains_eur:

  Repartition du cout (facultatif).

- surface_ha:

  Surface concernee (facultatif).

- reference_acte:

  Reference de l'acte, de l'arrete ou du proces-verbal (facultatif).

- references_cadastrales:

  References cadastrales, en un ou plusieurs elements (facultatif).

- beneficiaire:

  Beneficiaire d'une servitude (facultatif).

- observations:

  Observations libres (facultatif).

## Value

Une liste nommee, prete a etre passee a
[`sommier_entree()`](https://pobsteta.github.io/sommieR/reference/sommier_entree.md).

## Details

L'imprime A40 detaille les elements de calcul des frais de delimitation
(heures d'ingenieur et de technicien, arpentage, fourniture et pose des
bornes) et leur repartition entre le proprietaire et les riverains. Ces
champs ne sont exiges que pour les operations de limite : une
acquisition n'a pas d'heures d'arpentage.

La coherence de la repartition est verifiee lorsque les deux parts et le
cout total sont renseignes : une repartition qui ne totalise pas le cout
est une erreur de saisie, pas une subtilite comptable.

## Examples

``` r
registre2_foncier(
  type_entree = "bornage", description = "Limite nord, canton des Vernes",
  heures_technicien = 14, nb_bornes = 8, cout_total_eur = 1200,
  charge_proprietaire_eur = 600, charge_riverains_eur = 600
)
#> $type_entree
#> [1] "bornage"
#> 
#> $description
#> [1] "Limite nord, canton des Vernes"
#> 
#> $heures_technicien
#> [1] 14
#> 
#> $nb_bornes
#> [1] 8
#> 
#> $cout_total_eur
#> [1] 1200
#> 
#> $charge_proprietaire_eur
#> [1] 600
#> 
#> $charge_riverains_eur
#> [1] 600
#> 
```
