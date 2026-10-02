# Produit accidentel issu d'un constat de terrain

Inscrit au registre 5 le produit accidentel - bois sanitaires, chablis -
qu'une detection confirmee sur le terrain a laisse. L'entree reprend du
constat l'unite, la nature et la surface, et renvoie a lui par
`constat_id` ; seul le volume est a saisir.

## Usage

``` r
sommier_produit_accidentel(
  con,
  constat_id,
  volume_m3,
  auteur,
  date_evenement = Sys.Date(),
  exercice = NULL,
  surface_ha = NULL,
  nature_coupe = NULL,
  essence = NULL,
  observations = NULL
)
```

## Arguments

- con:

  Connexion DBI.

- constat_id:

  UUID du constat : la suite de la detection, au registre 8.

- volume_m3:

  Volume du produit, en metres cubes.

- auteur:

  Compte qui inscrit.

- date_evenement:

  Date de l'entree. Par defaut, aujourd'hui.

- exercice:

  Exercice d'imputation. Par defaut, l'annee de `date_evenement`.

- surface_ha:

  Surface parcourue. Par defaut, la surface constatee sur le terrain, si
  elle a ete saisie.

- nature_coupe:

  Nature de la coupe. Par defaut, deduite du constat.

- essence:

  Essence ou groupe d'essences (facultatif).

- observations:

  Observations (facultatif). Par defaut, le renvoi au constat en clair.

## Value

Invisiblement, l'entree chainee.

## Details

**Le volume ne se devine pas.** Ni la teledetection ni une photo ne le
donnent : il vient du cubage, une fois les bois designes ou exploites.
C'est pourquoi le rapport signale les produits a inscrire sans les
ecrire.

**Ce qui est refuse.** Un constat qui n'est pas la suite d'une
detection, une detection ecartee, une nature qui ne laisse pas de
produit accidentel (voir
[SOMMIER_NATURES_ACCIDENTELLES](https://pobsteta.github.io/sommieR/reference/SOMMIER_NATURES_ACCIDENTELLES.md)
: une exploitation ordinaire appelle un martelage), et un second produit
pour le meme constat - on corrige alors le premier.

**Nature de coupe.** Par defaut, deduite de la nature retenue sur le
terrain : « coupe sanitaire » pour une crise sanitaire ou une
secheresse, « chablis » pour une tempete, etc.

## See also

[`sommier_importer_qfield_detections()`](https://pobsteta.github.io/sommieR/reference/sommier_importer_qfield_detections.md),
[`registre5_coupe()`](https://pobsteta.github.io/sommieR/reference/registre5_coupe.md)
