# Definition de terrain des niveaux de concurrence

Ce qui distingue `faible`, `moyenne` et `forte` au controle d'une
plantation (brief `surculus` 2026-11-04, issue \#69). Colonnes :
`niveau` (un de
[SOMMIER_CONCURRENCES](https://pobsteta.github.io/sommieR/reference/SOMMIER_CONCURRENCES.md)),
`libelle` (ecran), `part_plants_min_pct` et `part_plants_max_pct` (part
des plants vivants au contact de la vegetation concurrente, bornes
`[min, max[`), `critere_hauteur` (position de la vegetation par rapport
au plant) et `travail` (suite usuelle).

**Un seul critere decide : la part de plants vivants au contact de la
vegetation.** `critere_hauteur` et `travail` sont une aide descriptive
pour le controleur : ils ne decident jamais du niveau (60 % des plants
au contact avec une vegetation au pied seulement : `forte`).

Aucune des cinq sources publiees lues par l'acquereur de Surculus (guide
"Reussir la plantation forestiere" 2014 p. 52 ; DSF bilan 2024 p. 13 et
16 ; RENFOR/INRAE ; CNPF CONQueTh ; MRNF Quebec 2024 p. 12) ne definit
trois niveaux : leurs criteres sont binaires et portent sur le plant
("aucune touffe de vegetation concurrente au pied des plants", guide
2014 p. 52). Les seuils ci-dessous sont donc une **convention de
sommieR**, derivee de ce critere par plant, a confirmer sur le terrain ;
elle n'est pas une norme.

## Usage

``` r
SOMMIER_DEFINITIONS_CONCURRENCE
```

## Format

Un `data.frame` de trois lignes.

## See also

[`sommier_niveau_concurrence()`](https://pobsteta.github.io/sommieR/reference/sommier_niveau_concurrence.md),
[SOMMIER_CONCURRENCES](https://pobsteta.github.io/sommieR/reference/SOMMIER_CONCURRENCES.md)
