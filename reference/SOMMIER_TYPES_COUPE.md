# Types d'entree du registre 5 (coupes et recoltes)

- `martelage` : volume martele en coupe reglee ou non reglee (imprime
  A50E).

- `produit_accidentel` : chablis, bois sanitaires, volumes marteles hors
  coupe prevue (imprime A50E, colonne "produits accidentels").

- `bois_delivre` : delivrance, principalement l'affouage en foret
  communale (imprime A50G, colonne "bois delivres") - bois martele, donc
  imputable.

- `coupe_realisee` : releve de la coupe effectivement exploitee (imprime
  A50F).

## Usage

``` r
SOMMIER_TYPES_COUPE
```

## Format

An object of class `character` of length 4.
