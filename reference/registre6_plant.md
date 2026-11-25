# Payload du registre 6 - plant pointe

Un plant pointe dans une placette de suivi, par son observation brute
relative au piquet (distance horizontale et azimut magnetique, comme
Surculus les releve) ; sa position (`geometrie`) en est derivee. Il
porte son identifiant (l'`id` de l'entree), qu'il garde d'un passage a
l'autre, et son numero dans la placette, donne au premier pointage et
jamais recalcule : sommieR le recoit tel quel. L'etat du plant a chaque
passage est porte par le controle
([`registre6_controle()`](https://pobsteta.github.io/sommieR/reference/registre6_controle.md)),
pas par le plant.

Un plant s'inscrit une fois, au passage ou il est pointe. Un regarni est
un nouveau plant (`regarni = TRUE`), lie au plant mort ou absent qu'il
remplace (`remplace_uuid`) : le plant remplace compte encore au controle
ou le regarni est pose, puis sort des totaux des controles suivants.

## Usage

``` r
registre6_plant(
  placette_id,
  numero,
  geometrie,
  essence = NULL,
  regarni = NULL,
  remplace_uuid = NULL,
  distance_m = NULL,
  azimut_mag = NULL,
  unite_azimut = NULL,
  declinaison_deg = NULL,
  convergence_deg = NULL,
  azimut_geo_deg = NULL,
  modele_geomagnetique = NULL,
  pointe_le = NULL,
  observations = NULL,
  methode_pointage = NULL
)
```

## Arguments

- placette_id:

  UUID de la placette
  ([`registre6_placette()`](https://pobsteta.github.io/sommieR/reference/registre6_placette.md)).

- numero:

  Numero du plant dans la placette (entier, au moins 1).

- geometrie:

  La position du plant, un point en WGS84
  ([`geom_point()`](https://pobsteta.github.io/sommieR/reference/geometries.md)).

- essence:

  Essence du plant (code ONF, texte libre pour sommieR) ;
  [`sommier_pointer_plant()`](https://pobsteta.github.io/sommieR/reference/sommier_pointer_plant.md)
  la prerempli avec l'essence objectif des travaux suivis.

- regarni, remplace_uuid:

  `regarni = TRUE` exige `remplace_uuid`, l'UUID du plant mort ou absent
  que ce plant remplace ; `remplace_uuid` exige `regarni` vrai ou omis.

- distance_m:

  Distance horizontale du piquet au plant, en metres.

- azimut_mag, unite_azimut:

  Azimut magnetique tel que lu, et son unite (`deg` : \[0, 360\[ ; `gr`
  : \[0, 400\[). L'un exige l'autre.

- declinaison_deg, convergence_deg, azimut_geo_deg:

  Termes derives : declinaison magnetique, convergence des meridiens,
  azimut geographique dans \[0, 360\[ (nord geographique, sens horaire).

- modele_geomagnetique:

  Modele de la declinaison (`WMM2025`).

- methode_pointage:

  Comment la position a ete obtenue : l'une de
  [SOMMIER_METHODES_POINTAGE](https://pobsteta.github.io/sommieR/reference/SOMMIER_METHODES_POINTAGE.md)
  (facultatif ; omise, elle n'est pas inscrite).

- pointe_le:

  Instant du pointage (UTC) ; sa date civile, en Europe/Paris, est celle
  du plant.

- observations:

  Observations libres.

## Value

Une liste nommee, prete a etre passee a
[`sommier_entree()`](https://pobsteta.github.io/sommieR/reference/sommier_entree.md).

## See also

[`sommier_pointer_plant()`](https://pobsteta.github.io/sommieR/reference/sommier_pointer_plant.md)
