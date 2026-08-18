# Payload du registre 6 - travaux

Construit et valide le payload d'une entree du registre 6 (imprimes
A50J, A50J bis pour les travaux par unite de gestion, A50H pour les
travaux hors unite de gestion). Le taux de reprise est le champ "% de
reprise" de l'imprime A50J, releve lors du controle des plantations.

## Usage

``` r
registre6_travaux(
  annee,
  nature_travaux,
  localisation = NULL,
  repere_plan = NULL,
  quantite = NULL,
  unite = NULL,
  nb_plants = NULL,
  provenance_plants = NULL,
  montant_eur = NULL,
  taux_reprise_pct = NULL,
  observations = NULL
)
```

## Arguments

- annee:

  Annee de realisation (entier).

- nature_travaux:

  Nature des travaux.

- localisation:

  Localisation en clair - a renseigner pour les travaux hors unite de
  gestion (imprime A50H), ou l'entree n'est ancree sur aucune unite de
  gestion.

- repere_plan:

  Repere sur le plan (facultatif).

- quantite, unite:

  Quantite realisee et son unite (facultatif).

- nb_plants, provenance_plants:

  Nombre de plants et provenance, pour les travaux de reboisement
  (facultatif).

- montant_eur:

  Montant en euros (facultatif).

- taux_reprise_pct:

  Taux de reprise en pourcentage, 0 a 100 (facultatif).

- observations:

  Observations libres (facultatif).

## Value

Une liste nommee, prete a etre passee a
[`sommier_entree()`](https://pobsteta.github.io/sommieR/reference/sommier_entree.md).

## Examples

``` r
registre6_travaux(
  annee = 2026, nature_travaux = "plantation",
  nb_plants = 1200, provenance_plants = "CHS - Bourgogne",
  montant_eur = 4800, taux_reprise_pct = 87.5
)
#> $annee
#> [1] 2026
#> 
#> $nature_travaux
#> [1] "plantation"
#> 
#> $nb_plants
#> [1] 1200
#> 
#> $provenance_plants
#> [1] "CHS - Bourgogne"
#> 
#> $montant_eur
#> [1] 4800
#> 
#> $taux_reprise_pct
#> [1] 87.5
#> 
```
