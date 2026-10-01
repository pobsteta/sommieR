# Suite donnee a une detection apres passage sur le terrain

Inscrit le constat de terrain qui confirme ou ecarte une detection. La
nouvelle entree porte NDP 0 et rectifie la detection : celle-ci sort des
vues de consultation sans sortir de la chaine.

## Usage

``` r
sommier_valider_detection(
  con,
  detection_id,
  auteur,
  statut,
  description,
  date_evenement = Sys.Date(),
  nature = NULL,
  surface_ha = NULL,
  volume_impacte_m3 = NULL,
  observations = NULL,
  id = uuid_v4(),
  ...
)
```

## Arguments

- con:

  Connexion DBI.

- detection_id:

  UUID de l'entree de detection.

- auteur:

  Identifiant de l'agent ayant constate.

- statut:

  `"confirme"` ou `"ecarte"`.

- description:

  Constat de terrain.

- date_evenement:

  Date du constat. Par defaut, aujourd'hui.

- nature:

  Nature retenue. Par defaut, celle de la detection.

- surface_ha:

  Surface constatee (facultatif).

- volume_impacte_m3:

  Volume affecte (facultatif).

- observations:

  Observations libres (facultatif).

- id:

  UUID de l'entree a ecrire (facultatif) : celui du releve de terrain,
  pour qu'un import se rejoue sans ecrire deux fois.

- ...:

  Champs du constat de terrain : `geometrie`, `precision_m`,
  `source_gnss`, `operateur`, `visite_le`, `releve_uuid`, `photos` (voir
  [`registre8_suite_detection()`](https://pobsteta.github.io/sommieR/reference/registre8_suite_detection.md)).

## Value

Invisiblement, l'entree chainee.

## Details

Un constat qui ecarte la detection la rectifie tout autant qu'un constat
qui la confirme : dans les deux cas la proposition ne doit plus etre lue
comme un fait etabli. La difference tient au champ `statut_detection` du
payload, que les vues exposent.

Une detection ne se suit qu'une fois : une seconde suite est refusee.
Pour revenir sur un constat, on corrige la suite elle-meme. Les constats
d'une tournee QField s'importent par
[`sommier_importer_qfield_detections()`](https://pobsteta.github.io/sommieR/reference/sommier_importer_qfield_detections.md).
