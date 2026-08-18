# Types d'entree du registre 8

Le registre 8 recouvre trois imprimes et un flux entrant :

- `phenomene` : journal chronologique des phenomenes interessant la vie
  de la foret (imprime A50K) - tempetes, incendies, crises sanitaires,
  gel.

- `tableau_chasse` : prelevement cynegetique par saison et par espece
  (imprime A50L).

- `equilibre_gibier` : constat d'equilibre foret-gibier, obligatoire en
  PSG depuis la LAAAF de 2014.

- `detection` : phenomene propose par teledetection, en attente de
  validation terrain (voir
  [`sommier_importer_detections()`](https://pobsteta.github.io/sommieR/reference/sommier_importer_detections.md)).

## Usage

``` r
SOMMIER_TYPES_EVENEMENT
```

## Format

An object of class `character` of length 4.
