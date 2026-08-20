# Valide une geometrie de payload

Verifie qu'une geometrie est d'un type admis, correctement formee, et en
coordonnees geographiques. Rend la forme canonique.

## Usage

``` r
valider_geometrie(
  geometrie,
  types = SOMMIER_TYPES_GEOMETRIE,
  nom = "geometrie"
)
```

## Arguments

- geometrie:

  Geometrie a valider.

- types:

  Types admis pour ce type d'objet.

- nom:

  Nom de l'argument, pour les messages.

## Value

La geometrie canonique.

## Details

La normalisation n'est pas cosmetique. Un payload relu depuis la base ou
depuis un manifeste revient avec ses coordonnees en matrice et non en
liste de couples, parce que c'est ainsi que `jsonlite` simplifie un
tableau de tableaux. Serialisees telles quelles, les deux formes ne
donneraient pas les memes octets, et l'empreinte recalculee ne
retomberait pas sur celle du registre. Toute geometrie repasse donc par
la meme mise en forme, a l'ecriture comme a la relecture.
