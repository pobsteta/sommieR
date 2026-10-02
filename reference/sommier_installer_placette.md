# Installer une placette de suivi

Inscrit au registre 6 une placette permanente qui suivra une plantation
ou une regeneration : son centre, son rayon, et les travaux qu'elle
suit.

## Usage

``` r
sommier_installer_placette(
  con,
  travaux_id,
  code_placette,
  geometrie,
  auteur,
  date_evenement = Sys.Date(),
  id = uuid_v4(),
  ...
)
```

## Arguments

- con:

  Connexion DBI.

- travaux_id:

  UUID de l'intervention suivie.

- code_placette:

  Code lisible ("P35-03").

- geometrie:

  Le centre, un point en WGS84
  ([`geom_point()`](https://pobsteta.github.io/sommieR/reference/geometries.md)).

- auteur:

  Compte qui ecrit.

- date_evenement:

  Date d'installation.

- id:

  UUID de l'entree ; un import de terrain y met celui du releve.

- ...:

  Champs de
  [`registre6_placette()`](https://pobsteta.github.io/sommieR/reference/registre6_placette.md)
  : `rayon_m`, `materialisation`, `precision_m`, `source_gnss`,
  `observations`.

## Value

Invisiblement, l'entree chainee (liste d'une entree).

## Details

Les travaux suivis doivent etre une intervention du registre 6 de la
meme foret, dans la meme unite de gestion : une placette de l'UG 35 ne
suit pas une plantation de l'UG 12. Le code d'une placette est unique
dans son unite ; une placette deplacee se rectifie, elle ne se
reinstalle pas sous le meme code.

## See also

[`sommier_controler_placette()`](https://pobsteta.github.io/sommieR/reference/sommier_controler_placette.md),
[`registre6_placette()`](https://pobsteta.github.io/sommieR/reference/registre6_placette.md)
