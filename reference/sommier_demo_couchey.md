# Jeu de demonstration : foret communale de Couchey

Peuple une base vierge avec un sommier complet et coherent couvrant les
neuf registres sur dix exercices, ancre sur les trois parcelles de
[SOMMIER_PARCELLES_COUCHEY](https://pobsteta.github.io/sommieR/reference/SOMMIER_PARCELLES_COUCHEY.md).
Sert a faire tourner les exemples, les rapports et la prise en main sans
rien saisir.

## Usage

``` r
sommier_demo_couchey(
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

**Les ecritures sont fictives.** Couchey est une commune reelle, et la
geometrie vient d'une fixture qui se declare elle-meme « mock » ; mais
aucun des volumes, montants, dates, coupes ou visas qui suivent ne
provient de ses registres. Ils sont construits pour la demonstration, a
une echelle coherente avec les 7,5 hectares des trois parcelles.

Trois precautions le rendent visible plutot que de compter sur la
memoire du lecteur : le nom de la foret porte la mention, le rapport
engendre l'affiche en tete, et la fonction refuse de s'executer sur une
base ou le jeu existe deja. Un paquet dont l'objet est la valeur
probante ne peut pas produire de fausses ecritures qui passeraient pour
authentiques.

## Examples

``` r
# Necessite une connexion :
# sommier_init_schema(con)
# demo <- sommier_demo_couchey(con)
# sommier_verifier(con, demo$foret_id)
```
