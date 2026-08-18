# Rendu Markdown de la gestion anterieure

Met en forme le resultat de
[`sommier_gestion_anterieure()`](https://pobsteta.github.io/sommieR/reference/sommier_gestion_anterieure.md)
en Markdown, pret a etre colle dans un document de gestion ou converti.

## Usage

``` r
sommier_rapport_markdown(x, chemin = NULL)
```

## Arguments

- x:

  Objet `sommier_gestion_anterieure`.

- chemin:

  Fichier de destination (facultatif : la chaine est rendue si absent).

## Value

Invisiblement, le Markdown produit.

## Details

Le rendu est du Markdown et non un formulaire officiel : la mise en page
reglementaire appartient a l'outil de redaction du document de gestion,
et la reproduire ici la figerait sur une version des textes. Ce qui est
fourni, c'est le contenu exige, structure et etiquete.
