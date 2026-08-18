# Payload du registre 4 - voirie forestiere (imprimes A50D et A50D bis)

Un troncon de voirie forestiere, avec son revetement, sa longueur, sa
largeur de chaussee et son usage.

## Usage

``` r
registre4_voirie(
  nom,
  revetement,
  longueur_m,
  largeur_chaussee_m = NULL,
  usage = NULL,
  ouverte_public = NULL,
  voirie_publique = FALSE,
  structure_chaussee = NULL,
  date_structure = NULL,
  observations = NULL
)
```

## Arguments

- nom:

  Nom ou numero du troncon.

- revetement:

  L'un de
  [SOMMIER_REVETEMENTS](https://pobsteta.github.io/sommieR/reference/SOMMIER_REVETEMENTS.md).

- longueur_m:

  Longueur en metres.

- largeur_chaussee_m:

  Largeur de chaussee (facultatif).

- usage:

  L'un de
  [SOMMIER_USAGES_VOIRIE](https://pobsteta.github.io/sommieR/reference/SOMMIER_USAGES_VOIRIE.md)
  (facultatif).

- ouverte_public:

  Ouverture a la circulation publique (facultatif).

- voirie_publique:

  Le troncon releve de la voirie publique et non de la voirie privee
  forestiere (defaut `FALSE`). L'imprime A50D les distingue, et seule la
  voirie privee entre dans la densite.

- structure_chaussee:

  Description de la structure (facultatif).

- date_structure:

  Date de realisation de la structure (facultatif).

- observations:

  Observations libres (facultatif).

## Value

Une liste nommee, prete a etre passee a
[`sommier_entree()`](https://pobsteta.github.io/sommieR/reference/sommier_entree.md).

## Details

L'imprime A50D inventorie la voirie et en tire des densites en km pour
100 hectares ; ces densites sont une vue calculee
([`sommier_densite_voirie()`](https://pobsteta.github.io/sommieR/reference/sommier_densite_voirie.md)),
pas une saisie. L'imprime A50D bis y ajoute, route par route, l'usage et
l'ouverture au public.

`ouverte_public` est distinct de l'usage : une route peut servir au
tourisme tout en etant fermee a la circulation motorisee, et c'est
precisement ce que l'imprime demande de tracer.

## Examples

``` r
registre4_voirie(
  nom = "Route du Haut-Bois", revetement = "empierree",
  longueur_m = 2400, largeur_chaussee_m = 4, usage = "exploitation",
  ouverte_public = FALSE
)
#> $type_entree
#> [1] "voirie"
#> 
#> $nom
#> [1] "Route du Haut-Bois"
#> 
#> $revetement
#> [1] "empierree"
#> 
#> $longueur_m
#> [1] 2400
#> 
#> $largeur_chaussee_m
#> [1] 4
#> 
#> $usage
#> [1] "exploitation"
#> 
#> $ouverte_public
#> [1] FALSE
#> 
#> $voirie_publique
#> [1] FALSE
#> 
```
