# Payload du registre 3 - affouage

Une campagne d'affouage, propre a la foret communale. Le brief en fait
un sous-registre du registre 3 : role des affouagistes, garants, taxe.

## Usage

``` r
registre3_affouage(
  campagne,
  nb_affouagistes,
  volume_m3 = NULL,
  taxe_eur = NULL,
  garants = NULL,
  mode_partage = NULL,
  observations = NULL
)
```

## Arguments

- campagne:

  Campagne d'affouage, au format `"AAAA-AAAA"`.

- nb_affouagistes:

  Nombre d'affouagistes inscrits au role.

- volume_m3:

  Volume delivre (facultatif).

- taxe_eur:

  Taxe d'affouage par part (facultatif).

- garants:

  Noms des garants (facultatif). Donnee personnelle.

- mode_partage:

  `"par_feu"`, `"par_habitant"` ou `"par_part"` (facultatif).

- observations:

  Observations libres (facultatif).

## Value

Une liste nommee, prete a etre passee a
[`sommier_entree()`](https://pobsteta.github.io/sommieR/reference/sommier_entree.md).

## Details

Les garants sont les trois habitants qui repondent de la bonne execution
de l'affouage devant la commune ; l'article L243-2 du code forestier en
prevoit trois, mais le champ n'en impose pas le nombre - un role
incomplet se constate, il ne se refuse pas.

## Examples

``` r
registre3_affouage(
  campagne = "2025-2026", nb_affouagistes = 42, volume_m3 = 310,
  taxe_eur = 45, mode_partage = "par_feu"
)
#> $type_entree
#> [1] "affouage"
#> 
#> $nature
#> [1] "Affouage"
#> 
#> $campagne
#> [1] "2025-2026"
#> 
#> $nb_affouagistes
#> [1] 42
#> 
#> $volume_m3
#> [1] 310
#> 
#> $taxe_eur
#> [1] 45
#> 
#> $mode_partage
#> [1] "par_feu"
#> 
```
