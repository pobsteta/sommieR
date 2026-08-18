# Payload du registre 4 - equipement ou ouvrage DFCI

Un equipement forestier (place de depot, barriere, aire d'accueil) ou un
ouvrage de defense de la foret contre l'incendie.

## Usage

``` r
registre4_equipement(
  type_entree,
  nature,
  nom = NULL,
  capacite = NULL,
  unite = NULL,
  etat = NULL,
  date_controle = NULL,
  observations = NULL
)
```

## Arguments

- type_entree:

  `"equipement"` ou `"ouvrage_dfci"`.

- nature:

  Nature de l'equipement ou de l'ouvrage.

- nom:

  Nom ou identifiant (facultatif).

- capacite:

  Capacite, par exemple le volume d'un point d'eau (facultatif).

- unite:

  Unite de la capacite (facultatif).

- etat:

  Etat constate : `"bon"`, `"moyen"`, `"degrade"`, `"hors_service"`
  (facultatif).

- date_controle:

  Date du dernier controle (facultatif).

- observations:

  Observations libres (facultatif).

## Value

Une liste nommee, prete a etre passee a
[`sommier_entree()`](https://pobsteta.github.io/sommieR/reference/sommier_entree.md).

## Details

L'analyse DFCI est obligatoire dans les PSG depuis la loi du 10 juillet
2023 ; le brief la range dans le socle commun du registre 4 plutot que
dans un registre propre a la foret privee, ce que suit cette
implementation : un point d'eau se decrit de la meme facon quel que soit
le regime.

## Examples

``` r
registre4_equipement(
  type_entree = "ouvrage_dfci", nature = "Point d'eau",
  nom = "PE-03", capacite = 120, unite = "m3", etat = "bon"
)
#> $type_entree
#> [1] "ouvrage_dfci"
#> 
#> $nature
#> [1] "Point d'eau"
#> 
#> $nom
#> [1] "PE-03"
#> 
#> $capacite
#> [1] 120
#> 
#> $unite
#> [1] "m3"
#> 
#> $etat
#> [1] "bon"
#> 
```
