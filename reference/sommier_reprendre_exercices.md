# Reprise de la table `exercice` en amenagement(s)

Transcrit la possibilite rangee dans la table `exercice` - hors de la
chaine, et reecrivable sans trace - en un ou plusieurs amenagements
repris. Les annees consecutives de meme possibilite forment un
amenagement.

## Usage

``` r
sommier_reprendre_exercices(
  con,
  foret_id,
  auteur,
  surface_ha = NULL,
  autorite = "onf",
  nom_qualite = "Non renseigne",
  reference = NULL
)
```

## Arguments

- con:

  Connexion DBI.

- foret_id:

  UUID de la foret.

- auteur:

  Compte qui transcrit.

- surface_ha:

  Surface sur laquelle ramener le volume a l'hectare. Par defaut, celle
  de la foret.

- autorite, nom_qualite:

  Autorite et signataire de l'acte d'origine, s'ils sont connus.

- reference:

  Reference de l'acte d'origine, si elle est connue.

## Value

Invisiblement, le compte rendu de
[`sommier_reprendre()`](https://pobsteta.github.io/sommieR/reference/sommier_reprendre.md).

## Details

La table porte un volume annuel, en m3 ; l'amenagement, une possibilite
a l'hectare. La conversion se fait sur `surface_ha`, par defaut la
surface de la foret : sans surface, il n'y a pas de taux, et la reprise
le dit.

La transcription dit qu'elle en est une : chaque amenagement porte un
bloc `reprise` (source `base_gestionnaire`, NDP 2), et rien n'est efface
de la table. Apres reprise,
[`exercice_definir()`](https://pobsteta.github.io/sommieR/reference/exercice_definir.md)
refuse d'ecrire : une possibilite ne se modifie plus que par avenant.
