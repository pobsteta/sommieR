# Controler une placette de suivi

Inscrit au registre 6 un passage sur une placette : plants comptes,
vivants, hauteur, abroutis, concurrence, et le travail qui s'impose
ensuite. L'entree prend l'unite de gestion de la placette.

## Usage

``` r
sommier_controler_placette(
  con,
  placette_id,
  nb_total = NULL,
  nb_vivants = NULL,
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

  Plants comptes, et vivants parmi eux. Avec `plants`, ils se deduisent
  des etats (voir
  [`registre6_controle()`](https://pobsteta.github.io/sommieR/reference/registre6_controle.md)).

- auteur:

  Compte qui ecrit.

- visite_le:

  Instant du controle ; sa date civile, en Europe/Paris, est la date de
  l'entree.

- id:

  UUID de l'entree.

- ...:

  Champs de
  [`registre6_controle()`](https://pobsteta.github.io/sommieR/reference/registre6_controle.md)
  : `h_moy_cm`, `nb_abroutis`, `concurrence`, `besoin`, `operateur`,
  `releve_uuid`, `photos`, `observations`, et la position mesuree
  (`geometrie`, `precision_m`, `rattache_par_identite`,
  `sans_position_mesuree`), et `plants`, l'etat de chaque plant a ce
  passage.

## Value

Invisiblement, l'entree chainee (liste d'une entree).

## Details

Une placette inconnue, ou qui n'en est pas une, est refusee, de meme
qu'un second controle de la meme placette le meme jour : une erreur de
comptage se rectifie, elle ne se double pas.

**Avec `plants`**, les totaux en decoulent et doivent concorder (un
total contradictoire est refuse avant toute ecriture), et le controle
est confronte aux plants de la placette : un plant inconnu de la
placette, un plant vivant (ou pas encore vu) au passage precedent sans
etat, ou un plant mort ou absent redit vivant sont refuses. Un plant
remplace par un regarni d'un passage anterieur n'a plus d'etat a donner
: s'il en a un, il ne compte pas. Un controle sans `plants` s'ecrit
comme avant.

## See also

[`sommier_installer_placette()`](https://pobsteta.github.io/sommieR/reference/sommier_installer_placette.md),
[`registre6_controle()`](https://pobsteta.github.io/sommieR/reference/registre6_controle.md),
[`sommier_pointer_plant()`](https://pobsteta.github.io/sommieR/reference/sommier_pointer_plant.md)
