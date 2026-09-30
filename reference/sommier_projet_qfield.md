# Projet QGIS/QField pour verifier les limites sur le terrain

Ecrit un dossier autonome - un projet QGIS, un GeoPackage et un dossier
`DCIM/` vide - que l'on copie sur le telephone ou la tablette et que
l'on ouvre avec QField. On y trouve les elements du plan cadastral a
verifier, colores selon leur derniere visite, et une couche ou saisir un
constat par element visite, avec ses photos.

## Usage

``` r
sommier_projet_qfield(
  con,
  foret_id,
  elements,
  dossier,
  operateur,
  fond = NULL,
  anciennete_ans = 10,
  ortho = NULL
)
```

## Arguments

- con:

  Connexion DBI.

- foret_id:

  UUID de la foret.

- elements:

  Elements du plan, tels que les rend
  [`sommier_elements_pci()`](https://pobsteta.github.io/sommieR/reference/sommier_elements_pci.md).

- dossier:

  Dossier a creer. Il ne doit pas exister : une tournee non rapatriee ne
  doit jamais etre ecrasee.

- operateur:

  Nom de l'operateur, propose par defaut dans chaque constat.

- fond:

  Parcellaire cadastral pour se reperer, tel que le rend
  [`sommier_fond_lire()`](https://pobsteta.github.io/sommieR/reference/sommier_fond_lire.md)
  (facultatif).

- anciennete_ans:

  Au-dela de ce nombre d'annees, une visite est dite ancienne.

- ortho:

  GeoTIFF d'orthophotographie a joindre au projet, tel que l'ecrit
  [`sommier_ortho_ign()`](https://pobsteta.github.io/sommieR/reference/sommier_ortho_ign.md)
  (facultatif). Il est copie, jamais telecharge ici. Sans lui, la couche
  d'ortho hors ligne est retiree du projet plutot que laissee pointer
  vers un fichier absent.

## Value

Invisiblement, le chemin du projet `.qgs`.

## Details

**Le projet est engendre sans QGIS.** Le modele - styles, formulaires,
relation entre constats et photos - a ete produit une fois par QGIS
lui-meme (`data-raw/qfield_modele.py`) et se trouve dans `inst/qgis/`.
Cette fonction le copie, remplit les couches de donnees et pose quelques
valeurs : titre, operateur, emprise d'ouverture.

**Aucun service en ligne n'est requis.** Le dossier se copie par cable
ou par un partage de fichiers, et revient de la meme facon ; QFieldCloud
reste possible, le dossier etant un projet QGIS ordinaire. En foret, le
reseau manque souvent : `ortho` joint au projet une orthophotographie
que QField affiche hors ligne (voir
[`sommier_ortho_ign()`](https://pobsteta.github.io/sommieR/reference/sommier_ortho_ign.md)).
La couche de l'IGN en ligne reste dessous, pour qui a du reseau.

**Le formulaire en fait le plus possible.** Un nouveau constat propose
l'element du plan le plus proche a moins de 30 m, et remplit la date,
l'operateur, la precision et la source GNSS. L'etat, lui, doit etre
choisi : c'est le constat.

Les elements sont colores selon leur derniere reconnaissance au sommier
: a voir (jamais vu, ou reste inaccessible), vu il y a plus de
`anciennete_ans` ans, vu en place, vu endommage, non retrouve ou
detruit.

Le projet vise QField 4.x ; il le declare dans ses metadonnees.

## See also

[`sommier_importer_qfield()`](https://pobsteta.github.io/sommieR/reference/sommier_importer_qfield.md),
[`sommier_elements_pci()`](https://pobsteta.github.io/sommieR/reference/sommier_elements_pci.md)

## Examples

``` r
# sommier_projet_qfield(con, foret, elements, "limites-loury",
#                       operateur = "P. Obstetar")
```
