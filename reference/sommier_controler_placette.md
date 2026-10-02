# Controler une placette de suivi

Inscrit au registre 6 un passage sur une placette : plants comptes,
vivants, hauteur, abroutis, concurrence, et le travail qui s'impose
ensuite. L'entree prend l'unite de gestion de la placette.

## Usage

``` r
sommier_controler_placette(
  con,
  placette_id,
  nb_total,
  nb_vivants,
  auteur,
  visite_le = Sys.time(),
  id = uuid_v4(),
  ...
)
```

## Arguments

- con:

  Connexion DBI.

- placette_id:

  UUID de la placette.

- nb_total, nb_vivants:

  Plants comptes, et vivants parmi eux.

- auteur:

  Compte qui ecrit.

- visite_le:

  Instant du controle ; sa date est la date de l'entree.

- id:

  UUID de l'entree.

- ...:

  Champs de
  [`registre6_controle()`](https://pobsteta.github.io/sommieR/reference/registre6_controle.md)
  : `h_moy_cm`, `nb_abroutis`, `concurrence`, `besoin`, `operateur`,
  `releve_uuid`, `photos`, `observations`.

## Value

Invisiblement, l'entree chainee (liste d'une entree).

## Details

Une placette inconnue, ou qui n'en est pas une, est refusee, de meme
qu'un second controle de la meme placette le meme jour : une erreur de
comptage se rectifie, elle ne se double pas.

## See also

[`sommier_installer_placette()`](https://pobsteta.github.io/sommieR/reference/sommier_installer_placette.md),
[`registre6_controle()`](https://pobsteta.github.io/sommieR/reference/registre6_controle.md)
