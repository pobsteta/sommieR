# Payload du registre 8 - tableau de chasse (imprime A50L)

Un prelevement cynegetique, pour une saison, une espece et une
categorie. L'imprime A50L est une matrice especes x saisons ; on
l'enregistre ligne a ligne, la matrice se reconstituant par requete.

## Usage

``` r
registre8_tableau_chasse(
  saison,
  espece,
  nombre,
  classe_age = NULL,
  sexe = NULL,
  attribue = NULL,
  observations = NULL
)
```

## Arguments

- saison:

  Saison cynegetique, au format `"AAAA-AAAA"`.

- espece:

  Espece prelevee.

- nombre:

  Nombre d'individus preleves (entier positif ou nul).

- classe_age:

  Classe d'age (facultatif) : `"jeune"`, `"subadulte"`, `"adulte"`, ou
  notation propre au plan de chasse.

- sexe:

  Sexe (facultatif) : `"male"`, `"femelle"`, `"indetermine"`.

- attribue:

  Nombre attribue au plan de chasse (facultatif), pour confronter
  realise et attribue.

- observations:

  Observations libres (facultatif).

## Value

Une liste nommee, prete a etre passee a
[`sommier_entree()`](https://pobsteta.github.io/sommieR/reference/sommier_entree.md).

## Details

La saison cynegetique court du 1er avril au 31 mars et se note
`"AAAA-AAAA"` (par exemple `"2025-2026"`). Les deux annees doivent se
suivre : `"2025-2027"` est refuse, une saison ne durant pas deux ans.

## Examples

``` r
registre8_tableau_chasse(
  saison = "2025-2026", espece = "chevreuil",
  classe_age = "adulte", sexe = "male", nombre = 12, attribue = 15
)
#> $type_entree
#> [1] "tableau_chasse"
#> 
#> $saison
#> [1] "2025-2026"
#> 
#> $espece
#> [1] "chevreuil"
#> 
#> $nombre
#> [1] 12
#> 
#> $classe_age
#> [1] "adulte"
#> 
#> $sexe
#> [1] "male"
#> 
#> $attribue
#> [1] 15
#> 
```
