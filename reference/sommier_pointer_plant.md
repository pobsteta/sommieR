# Pointer un plant

Inscrit au registre 6 un plant d'une placette de suivi, pointe a la
position donnee. Il garde son UUID (l'`id` de l'entree) et son numero
d'un passage a l'autre ; son etat a chaque passage est porte par le
controle
([`sommier_controler_placette()`](https://pobsteta.github.io/sommieR/reference/sommier_controler_placette.md),
argument `plants`).

## Usage

``` r
sommier_pointer_plant(
  con,
  placette_id,
  geometrie,
  numero,
  auteur,
  date_evenement = NULL,
  id = uuid_v4(),
  ...
)
```

## Arguments

- con:

  Connexion DBI.

- placette_id:

  UUID de la placette.

- geometrie:

  La position du plant, un point en WGS84
  ([`geom_point()`](https://pobsteta.github.io/sommieR/reference/geometries.md)).

- numero:

  Numero du plant dans la placette (entier, au moins 1).

- auteur:

  Compte qui ecrit.

- date_evenement:

  Date du pointage (par defaut, celle de `pointe_le` si elle est donnee,
  sinon le jour).

- id:

  UUID de l'entree, donc du plant ; un import de terrain y met celui du
  releve.

- ...:

  Champs de
  [`registre6_plant()`](https://pobsteta.github.io/sommieR/reference/registre6_plant.md)
  : `essence`, `regarni`, `remplace_uuid`, `distance_m`, `azimut_mag`,
  `unite_azimut`, `declinaison_deg`, `convergence_deg`,
  `azimut_geo_deg`, `modele_geomagnetique`, `methode_pointage`,
  `pointe_le`, `observations`.

## Value

Invisiblement, l'entree chainee (liste d'une entree).

## Details

Une placette inconnue, ou qui n'en est pas une, est refusee, de meme
qu'un numero deja pris dans la placette : le numero se donne au premier
pointage et ne se recalcule jamais (sommieR le recoit de Surculus,
numerotation par azimut depuis le nord, sens horaire ; il ne le calcule
pas).

L'essence, si elle n'est pas donnee, est celle des travaux suivis par la
placette (`essence_objectif`) : une plantation melangee se tient en
donnant l'essence de chaque plant.

Un regarni (`regarni = TRUE`) remplace exactement un plant **mort ou
absent de la meme placette**, deja connu de la base (`remplace_uuid`) :
un plant sain ou atteint, d'une autre placette, inconnu, ou deja
remplace, est refuse. Le plant remplace compte encore au controle ou le
regarni est pose, puis sort des totaux des controles suivants.

## See also

[`registre6_plant()`](https://pobsteta.github.io/sommieR/reference/registre6_plant.md),
[`sommier_controler_placette()`](https://pobsteta.github.io/sommieR/reference/sommier_controler_placette.md)
