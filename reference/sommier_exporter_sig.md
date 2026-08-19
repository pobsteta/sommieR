# Export cartographique des unites de gestion

Exporte les unites de gestion et leur geometrie courante, enrichies du
nombre d'entrees de sommier qui s'y rattachent.

## Usage

``` r
sommier_exporter_sig(
  con,
  foret_id,
  chemin,
  format = "geojson",
  a_la_date = Sys.Date()
)
```

## Arguments

- con:

  Connexion DBI.

- foret_id:

  UUID de la foret.

- chemin:

  Fichier de destination.

- format:

  L'un de
  [SOMMIER_FORMATS_SIG](https://pobsteta.github.io/sommieR/reference/SOMMIER_FORMATS_SIG.md).

- a_la_date:

  Date de reference pour la version de geometrie et l'activite des
  unites (defaut : aujourd'hui).

## Value

Invisiblement, une liste : `chemin`, `n_unites`, `unites_sans_geometrie`
(leurs numeros d'affichage).

## Details

Seule la version de geometrie en vigueur a la date demandee est
exportee. Une unite sans geometrie connue est **omise de la couche mais
signalee** : la faire figurer sans contour serait une entite fantome
dans le SIG, et l'omettre en silence laisserait croire que la foret est
entierement cartographiee.

Les deux formats ne portent pas le systeme de coordonnees de la meme
maniere, et l'export en tient compte. Un GeoJSON ne transporte aucune
declaration de projection : la RFC 7946 impose le WGS84, et tout lecteur
le suppose. La couche est donc reprojetee en EPSG:4326 a l'emission -
emettre du Lambert-93 tel quel produirait un fichier qui s'ouvre sans
erreur et place la foret a des milliers de kilometres, c'est-a-dire la
pire des sorties : fausse et silencieuse. Le GeoPackage, lui, ecrit son
systeme dans le fichier ; il reste en EPSG:2154, ou les longueurs et les
surfaces se mesurent en metres.

L'export cartographique ne remplace pas le manifeste : la valeur
probante est dans la chaine, que
[`sommier_exporter_manifeste()`](https://pobsteta.github.io/sommieR/reference/sommier_exporter_manifeste.md)
transporte. Les deux se completent, et le destinataire verifie l'un
avant de lire l'autre.
