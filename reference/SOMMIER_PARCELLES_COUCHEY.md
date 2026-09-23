# Parcelles du jeu de demonstration

Trois parcelles de la foret communale de Couchey, avec leurs references,
leurs contenances et leurs contours **reels** : ceux que publie la
DGFiP, repris par le projet Couchey de nemeton qui porte le meme
parcellaire. Un sommier se rapproche ainsi des indicateurs nemeton
calcules sur le meme terrain, sans qu'il faille croire deux dessins sur
parole.

## Usage

``` r
SOMMIER_PARCELLES_COUCHEY
```

## Format

`data.frame` de 3 lignes : `numero`, `geo_parcelle`, `section`,
`contenance_m2`, `surface_ha`, `wkt_4326`.

## Source

Cadastre DGFiP, livraison etalab du 1er juin 2026, par le projet Couchey
de nemeton (`20260828_140251_hwuy`).

## Details

**Les contours sont authentiques, les ecritures ne le sont pas.** La
geometrie et les references cadastrales sont celles de la DGFiP ; tout
ce que
[`sommier_demo_couchey()`](https://pobsteta.github.io/sommieR/reference/sommier_demo_couchey.md)
inscrit dessus est invente. La distinction porte : un contour faux se
voit a la premiere superposition, une ecriture fausse ne se voit jamais.
C'est donc elle, et elle seule, que le nom de la foret et le rapport
engendre signalent.

Jusqu'a la v0.11.1, le paquet reprenait la fixture « mock » de
`nemetonshiny` : trois carres de 0,002 degre portant les references
`21200000A0054` a `56`. Ces parcelles n'existent pas - la section A de
Couchey passe de 38 a 61 - et la reference etait meme mal formee, le
cadastre ecrivant `212000000A0054` sur quatorze caracteres. Une
geometrie plausible mais fausse est exactement ce qu'un sommier existe
pour interdire ; la garder en exemple revenait a demontrer le contraire
de ce que le paquet affirme.

**Trois blocs, et non un tenant.** A 102 est a 485 metres de A 35, et A
15 a 1,7 kilometre a l'est. Une foret communale en plusieurs blocs est
la regle plutot que l'exception, et le jeu y gagne : la « piste de
desserte est » dessert reellement le bloc est.

Les contours sont simplifies a 1 metre par
`ST_SimplifyPreserveTopology`, ce qui coute 55 m2 sur 16,4 hectares -
0,03 %. La tolerance de 5 metres en coutait 866, dont 1 % sur la seule A
15 : pour trois parcelles, la simplification n'economise pas assez de
code pour qu'on abime une surface.

`contenance_m2` est la contenance cadastrale et `surface_ha` la meme
valeur en hectares. Ni l'une ni l'autre n'est l'aire du contour, qui en
differe de quelques dizaines de metres carres : le cadastre fait foi sur
la contenance, le dessin ne fait foi sur rien.

Les contours sont en WGS84 (EPSG:4326) ; ils sont reprojetes en
Lambert-93 a l'insertion, le schema du sommier stockant en EPSG:2154.

## Examples

``` r
SOMMIER_PARCELLES_COUCHEY[, c("geo_parcelle", "surface_ha")]
#>     geo_parcelle surface_ha
#> 1 212000000A0015     4.8750
#> 2 212000000A0035     7.1900
#> 3 212000000A0102     4.3095
```
