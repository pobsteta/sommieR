# Payload du registre 3 - droits et concessions (imprime A50C)

Une concession, un bail, un droit d'usage ou une convention. L'imprime
A50C releve le numero, la nature, le titulaire, les dates de depart et
d'expiration.

## Usage

``` r
registre3_droit(
  type_entree,
  nature,
  date_debut,
  numero = NULL,
  titulaire = NULL,
  date_expiration = NULL,
  redevance_eur = NULL,
  surface_ha = NULL,
  observations = NULL
)
```

## Arguments

- type_entree:

  L'un de
  [SOMMIER_TYPES_DROIT](https://pobsteta.github.io/sommieR/reference/SOMMIER_TYPES_DROIT.md).

- nature:

  Nature du droit ou de la concession.

- date_debut:

  Date de prise d'effet.

- numero:

  Numero d'ordre porte sur l'imprime (facultatif).

- titulaire:

  Titulaire (facultatif). Voir la note sur les donnees personnelles.

- date_expiration:

  Date d'expiration (facultatif : un droit d'usage peut etre perpetuel).

- redevance_eur:

  Redevance annuelle (facultatif).

- surface_ha:

  Surface concernee (facultatif).

- observations:

  Observations libres (facultatif).

## Value

Une liste nommee, prete a etre passee a
[`sommier_entree()`](https://pobsteta.github.io/sommieR/reference/sommier_entree.md).

## Details

**Donnees personnelles.** `titulaire` designe souvent une personne
physique. Comme au registre 7, le champ est facultatif et ne doit etre
renseigne que lorsqu'il est necessaire : une entree de sommier ne
s'efface pas. `v_droit` ne l'expose pas.

L'affouage, propre a la foret communale, se saisit avec
[`registre3_affouage()`](https://pobsteta.github.io/sommieR/reference/registre3_affouage.md),
qui porte les champs qui lui sont propres.

## Examples

``` r
registre3_droit(
  type_entree = "bail_chasse", nature = "Location de chasse",
  numero = "12", date_debut = "2024-04-01", date_expiration = "2033-03-31",
  redevance_eur = 3200
)
#> $type_entree
#> [1] "bail_chasse"
#> 
#> $nature
#> [1] "Location de chasse"
#> 
#> $numero
#> [1] "12"
#> 
#> $date_debut
#> [1] "2024-04-01"
#> 
#> $date_expiration
#> [1] "2033-03-31"
#> 
#> $redevance_eur
#> [1] 3200
#> 
```
