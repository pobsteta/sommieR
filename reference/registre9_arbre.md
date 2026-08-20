# Payload du registre 9 - arbre remarquable (imprime A50 r/a)

Une fiche d'arbre remarquable et, le cas echeant, une mesure datee.

## Usage

``` r
registre9_arbre(
  appellation,
  essence,
  interet,
  age_ans = NULL,
  circonference_cm = NULL,
  hauteur_m = NULL,
  etat_sanitaire = NULL,
  observations = NULL,
  geometrie = NULL
)
```

## Arguments

- appellation:

  Nom sous lequel l'arbre est connu.

- essence:

  Essence.

- interet:

  Ce qui fonde le caractere remarquable : age, dimensions, port,
  histoire.

- age_ans, circonference_cm, hauteur_m:

  Mesures du releve (facultatif).

- etat_sanitaire:

  `"bon"`, `"moyen"`, `"degrade"`, `"deperissant"`, `"mort"`
  (facultatif). Un arbre mort sur pied reste remarquable : c'est meme un
  facteur de l'IBP.

- observations:

  Observations libres (facultatif).

- geometrie:

  Position de l'objet, en WGS84 : voir
  [`geom_point()`](https://pobsteta.github.io/sommieR/reference/geometries.md).
  Facultative — un gestionnaire sans releve continue de saisir sans, et
  son sommier reste conforme.

## Value

Une liste nommee, prete a etre passee a
[`sommier_entree()`](https://pobsteta.github.io/sommieR/reference/sommier_entree.md).

## Details

L'imprime r/a est fait de deux parties : une identite qui ne bouge pas
(appellation, essence, interet) et des mesures datees qui s'ajoutent au
fil des visites. En append-only, chaque visite est une entree de plus
portant la meme `appellation` : la serie de mesures se reconstitue par
requete, comme la matrice du tableau de chasse. Rien n'est ecrase, et
l'evolution du sujet reste lisible.

## Examples

``` r
registre9_arbre(
  appellation = "Chene des Trois Bornes", essence = "CHS",
  interet = "Age estime a 350 ans, port en candelabre",
  circonference_cm = 540, hauteur_m = 28, etat_sanitaire = "moyen"
)
#> $type_fiche
#> [1] "arbre"
#> 
#> $appellation
#> [1] "Chene des Trois Bornes"
#> 
#> $essence
#> [1] "CHS"
#> 
#> $interet
#> [1] "Age estime a 350 ans, port en candelabre"
#> 
#> $circonference_cm
#> [1] 540
#> 
#> $hauteur_m
#> [1] 28
#> 
#> $etat_sanitaire
#> [1] "moyen"
#> 
```
