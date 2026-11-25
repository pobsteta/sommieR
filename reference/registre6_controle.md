# Payload du registre 6 - controle d'une placette

Un passage sur une placette : ce qu'on y compte. Le taux de reprise, la
densite a l'hectare et la part d'abroutis ne s'inscrivent pas : la vue
`v_controle_plantation` les calcule, et l'age de la plantation se deduit
de l'annee des travaux suivis.

## Usage

``` r
registre6_controle(
  placette_id,
  nb_total = NULL,
  nb_vivants = NULL,
  h_moy_cm = NULL,
  nb_abroutis = NULL,
  concurrence = NULL,
  besoin = NULL,
  operateur = NULL,
  visite_le = NULL,
  releve_uuid = NULL,
  photos = NULL,
  observations = NULL,
  nb_plants_vivants = NULL,
  nb_plants_concurrences = NULL,
  concurrence_calculee = NULL,
  geometrie = NULL,
  precision_m = NULL,
  rattache_par_identite = NULL,
  sans_position_mesuree = NULL,
  plants = NULL,
  plants_remplaces = NULL
)
```

## Arguments

- placette_id:

  UUID de la placette controlee.

- nb_total, nb_vivants:

  Plants comptes, et vivants parmi eux. Obligatoires sans `plants` ;
  avec `plants`, ils se deduisent des etats et, s'ils sont donnes,
  doivent concorder (voir `plants`).

- h_moy_cm:

  Hauteur moyenne des tiges objectif, en cm.

- nb_abroutis:

  Plants vivants abroutis.

- concurrence:

  L'un de
  [SOMMIER_CONCURRENCES](https://pobsteta.github.io/sommieR/reference/SOMMIER_CONCURRENCES.md),
  defini dans
  [SOMMIER_DEFINITIONS_CONCURRENCE](https://pobsteta.github.io/sommieR/reference/SOMMIER_DEFINITIONS_CONCURRENCE.md).

- besoin:

  Le travail qui s'impose ensuite : un code de
  [SOMMIER_CODES_TRAVAUX](https://pobsteta.github.io/sommieR/reference/SOMMIER_CODES_TRAVAUX.md),
  ou `"aucun"`.

- operateur:

  Agent qui a controle.

- visite_le:

  Instant du controle.

- releve_uuid:

  Identifiant du releve de terrain.

- photos:

  Photos, par leur empreinte.

- observations:

  Observations libres.

- nb_plants_vivants, nb_plants_concurrences:

  Facultatifs : le comptage dont `concurrence` est tiree, pour qu'on
  puisse la verifier. Plants vivants sur lesquels le contact avec la
  vegetation a ete note (au plus `nb_vivants`), et parmi eux ceux au
  contact de la vegetation concurrente. `nb_plants_concurrences` peut
  arriver **sans** `nb_plants_vivants` : il est alors garde tel quel,
  sans niveau deduit ni compare, et un avertissement le dit (rien ne se
  perd, rien n'est muet ; pas d'avertissement au rejeu). Ajout seul :
  `NULL` est accepte, et un controle sans ces champs se relit a
  l'identique. Lis avec
  [`sommier_niveau_concurrence()`](https://pobsteta.github.io/sommieR/reference/sommier_niveau_concurrence.md).
  Quand les deux sont fournis : si `concurrence` est absent, il est
  **deduit** par
  [`sommier_niveau_concurrence()`](https://pobsteta.github.io/sommieR/reference/sommier_niveau_concurrence.md)
  ; s'il est saisi et contredit les comptages, il est **conserve tel que
  saisi**, un avertissement le dit et le niveau calcule est inscrit au
  payload sous `concurrence_calculee`.

- concurrence_calculee:

  Ne se saisit pas : c'est la trace que la fonction inscrit quand le
  niveau saisi contredit les comptages. Accepte pour que la relecture
  d'un payload ecrit se rejoue (il est recalcule).

- geometrie, precision_m, rattache_par_identite, sans_position_mesuree:

  Facultatifs : la position **mesuree** du controle (noms de Surculus).
  Ajout seul : un controle sans ces champs se relit a l'identique.
  `geometrie` est un point WGS 84 (voir
  [`geom_point()`](https://pobsteta.github.io/sommieR/reference/geometries.md))
  ; `entree_sommier.geom` la projette comme pour toute entree, et la vue
  `v_controle_plantation` la rend. `precision_m` est la precision de
  cette position, en metres (strictement positive ; elle ne s'inscrit
  qu'avec une `geometrie`). `rattache_par_identite` (`TRUE`/`FALSE`) dit
  que le code lu du piquet a designe la placette, et non la position
  mesuree (piquet a plus de 15 m, ou controle sans position mesuree).
  `sans_position_mesuree = TRUE` dit que le controle a ete ouvert sans
  aucun fix : il n'a alors **ni** `geometrie` **ni** `precision_m`
  (jamais un point (0, 0), jamais un point vide), et sa position est
  celle de la placette. Un point hors des bornes WGS 84 (par exemple des
  metres Lambert-93), ou une position donnee avec
  `sans_position_mesuree = TRUE`, est refuse.

- plants:

  Facultatif : l'etat de chaque plant a ce passage, une liste d'elements
  `list(plant_id, etat, cause_groupe, cause_detail, hauteur_cm)` (ou un
  `data.frame` a ces colonnes). `etat` : l'un de
  [SOMMIER_ETATS_PLANT](https://pobsteta.github.io/sommieR/reference/SOMMIER_ETATS_PLANT.md)
  ; `cause_groupe` : l'un de
  [SOMMIER_GROUPES_CAUSE_PLANT](https://pobsteta.github.io/sommieR/reference/SOMMIER_GROUPES_CAUSE_PLANT.md),
  admis pour un plant `atteint` ou `mort` seulement ; `cause_detail` :
  texte libre, admis pour un `atteint` ou un `mort`, et pour un `sain`
  seulement s'il vaut `"abroutissement"` (jamais pour un `absent` ni un
  `non_observe`) ; `hauteur_cm` : entier strictement positif, refuse
  pour un `absent` et un `non_observe`. Un meme plant ne porte qu'un
  etat par controle.

  **Les totaux en decoulent** : `nb_total` = plants dont l'etat est
  sain, atteint, mort ou absent (hors `non_observe` et hors plants
  remplaces), `nb_vivants` = sains + atteints, `nb_abroutis` = vivants
  dont le detail est `"abroutissement"` (un plant mort d'abroutissement
  n'y compte pas), `h_moy_cm` = moyenne des hauteurs des vivants
  mesures, arrondie a l'entier le plus proche, demi vers le haut (42,5
  donne 43 ; [`round()`](https://rdrr.io/r/base/Round.html) de R
  donnerait 42). Totaux omis : ils sont deduits et inscrits. Totaux
  donnes qui contredisent les etats : refus, avant toute ecriture. Un
  controle sans `plants` s'ecrit comme avant.

- plants_remplaces:

  Facultatif : ceux des `plants` qu'un regarni pose a un passage
  anterieur a remplaces ; ils sortent des totaux. Doit etre inclus dans
  `plants`.
  [`sommier_controler_placette()`](https://pobsteta.github.io/sommieR/reference/sommier_controler_placette.md)
  le calcule.

## Value

Une liste nommee, prete a etre passee a
[`sommier_entree()`](https://pobsteta.github.io/sommieR/reference/sommier_entree.md).

## See also

[`sommier_controler_placette()`](https://pobsteta.github.io/sommieR/reference/sommier_controler_placette.md)
