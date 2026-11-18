# Jeu de demonstration : foret communale de Marsannay-la-Cote

Peuple une base vierge avec un petit sommier de demonstration, ancre sur
les trois parcelles de
[SOMMIER_PARCELLES_MARSANNAY](https://pobsteta.github.io/sommieR/reference/SOMMIER_PARCELLES_MARSANNAY.md)
: une plantation, un degagement, trois placettes de suivi controlees
deux fois (six controles) et un entretien de la desserte, soit la meme
taille que
[`sommier_demo_couchey()`](https://pobsteta.github.io/sommieR/reference/sommier_demo_couchey.md)
pour ce que lit la tournee de
[`sommier_projet_qfield_travaux()`](https://pobsteta.github.io/sommieR/reference/sommier_projet_qfield_travaux.md).
Sert a montrer le paquet, et la tournee des travaux, sans donnees de
client.

## Usage

``` r
sommier_demo_marsannay(
  con,
  auteur = "demo-sommieR",
  geometries = TRUE,
  suffixe = NULL
)
```

## Arguments

- con:

  Connexion DBI vers une base ou le schema est deploye.

- auteur:

  Identifiant porte comme auteur des entrees.

- geometries:

  Inserer les contours des parcelles (defaut `TRUE`). Necessite PostGIS,
  qui assure la reprojection depuis le WGS84.

- suffixe:

  Discriminant ajoute au nom, pour poser plusieurs jeux dans une meme
  base. Il s'ajoute a
  [NOM_FORET_DEMO](https://pobsteta.github.io/sommieR/reference/NOM_FORET_DEMO.md)
  au lieu de le remplacer : la mention « jeu de demonstration » survit
  ainsi a toute personnalisation, et c'est elle que le rapport lit pour
  afficher son avertissement.

## Value

Invisiblement, une liste : `foret_id`, `ug` (UUID par numero de
parcelle), `n_entrees`.

## Details

**Les ecritures sont fictives, le terrain ne l'est pas.** Aucune donnee
de plantation n'existe pour Marsannay : chantiers, quantites, montants,
dates et releves sont inventes. Le nom de la foret porte la mention «
jeu de demonstration »
([NOM_FORET_DEMO_MARSANNAY](https://pobsteta.github.io/sommieR/reference/NOM_FORET_DEMO_MARSANNAY.md)),
et la fonction refuse de s'executer sur une base ou le jeu existe deja.
Les `code_travaux` employes (`PL`, `DG`) sont de
[SOMMIER_CODES_TRAVAUX](https://pobsteta.github.io/sommieR/reference/SOMMIER_CODES_TRAVAUX.md).

## Examples

``` r
# Necessite une connexion :
# sommier_init_schema(con)
# demo <- sommier_demo_marsannay(con)
# sommier_projet_qfield_travaux(con, demo$foret_id, tempdir(), "operateur")
```
