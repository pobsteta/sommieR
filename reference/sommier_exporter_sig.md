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

L'export cartographique ne remplace pas le manifeste : la valeur
probante est dans la chaine, que
[`sommier_exporter_manifeste()`](https://pobsteta.github.io/sommieR/reference/sommier_exporter_manifeste.md)
transporte. Les deux se completent, et le destinataire verifie l'un
avant de lire l'autre.
