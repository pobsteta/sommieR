# Types d'entree du registre 6

- `travaux` : une intervention (A50J, A50H) ; le type est implicite, une
  entree sans `type_entree` en est une.

- `placette` : une placette permanente de suivi d'une plantation ou
  d'une regeneration.

- `controle` : un passage sur une placette.

- `plant` : un plant pointe dans une placette, qu'on retrouve d'un
  passage a l'autre (voir
  [`registre6_plant()`](https://pobsteta.github.io/sommieR/reference/registre6_plant.md)).

## Usage

``` r
SOMMIER_TYPES_TRAVAUX
```

## Format

An object of class `character` of length 4.
