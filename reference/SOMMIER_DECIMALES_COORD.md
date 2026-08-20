# Nombre de decimales conservees sur une coordonnee

Sept decimales de degre valent environ un centimetre. Aucun instrument
de terrain forestier ne fait mieux, et deux saisies du meme point
doivent produire les memes octets pour que le chainage reste
reproductible.

## Usage

``` r
SOMMIER_DECIMALES_COORD
```

## Details

Arrondir n'est pas simplifier : on ne retire pas de sommets, on cesse
d'afficher une precision que la mesure n'a pas. Simplifier un contour,
lui, falsifierait un constat et n'est fait nulle part.
