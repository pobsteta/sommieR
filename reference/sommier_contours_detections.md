# Contours des detections en attente

Dessine, pour chaque detection en attente au registre 8, les pixels qui
l'ont produite : ceux que RECONFORT classe en deperissement, ceux que
SUFOSAT date de l'annee de la coupe. A defaut, le contour est celui de
l'unite de gestion.

## Usage

``` r
sommier_contours_detections(
  con,
  foret_id,
  reconfort = NULL,
  sufosat = NULL,
  classe_min = 2L,
  seuil_proba = 90
)
```

## Arguments

- con:

  Connexion DBI.

- foret_id:

  UUID de la foret.

- reconfort:

  Raster des classes RECONFORT (facultatif).

- sufosat:

  Liste `dates`, `proba` : rasters SUFOSAT (facultatif).

- classe_min:

  Classe RECONFORT minimale retenue.

- seuil_proba:

  Probabilite SUFOSAT minimale, en %.

## Value

Un `data.frame` : `detection_id`, `ug`, `source`, `nature`,
`surface_ha`, `date_evenement`, `description`, `contour_source`
(`"pixels"` ou `"unite"`), `contour_ha`, `wkt` (Lambert-93).

## Details

**Un decor, pas une ecriture.** Les detections inscrites n'ont pas de
geometrie, et on ne la leur ajoute pas : une entree chainee ne se
complete pas apres coup. Le contour se recalcule depuis les rasters
fournis ; il aide l'agent a trouver ou regarder dans une unite de trente
hectares, il ne prouve rien.

- **RECONFORT** : le raster des classes (1 sain, 2 deperissant, 3 tres
  deperissant) ; sont retenus les pixels de l'unite de classe au moins
  `classe_min`.

- **SUFOSAT** : les rasters des dates (`AAJJJ`) et des probabilites ;
  sont retenus les pixels de l'unite dates de l'annee de la detection, a
  probabilite au moins `seuil_proba`.
