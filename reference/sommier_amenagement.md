# Amenagement : la periode et la possibilite, dans la chaine

Ecrit l'acte d'un amenagement - l'arrete, en foret publique, ou
l'agrement du PSG, en foret privee - avec la periode qu'il couvre et la
possibilite qu'il fixe. La balance de possibilite (imprime A50E) se
calcule ensuite contre lui : voir
[`sommier_balance_possibilite()`](https://pobsteta.github.io/sommieR/reference/sommier_balance_possibilite.md).

## Usage

``` r
sommier_amenagement(
  con,
  foret_id,
  id,
  annee_debut,
  annee_fin,
  possibilite_m3_ha_an,
  surface_ha,
  autorite,
  nom_qualite,
  date_acte,
  auteur,
  type_validation = "arrete",
  reference = NULL,
  libelle = NULL,
  ventilation = NULL,
  serie = NULL,
  tolerance_ans = NULL,
  source = NULL,
  nature_volume = "possibilite",
  groupes = NULL,
  surface_regeneration_ha = NULL,
  reference_m3_ha_an = NULL,
  facteur_vraisemblance = 3
)
```

## Arguments

- con:

  Connexion DBI.

- foret_id:

  UUID de la foret.

- id:

  Identifiant de l'amenagement, stable, repris par ses avenants (par
  exemple `"FD-ORLEANS-2026"`).

- annee_debut, annee_fin:

  Premier et dernier exercice couverts.

- possibilite_m3_ha_an:

  Possibilite a l'hectare, en m3/ha/an : fixee par l'acte, ou recolte
  prevue au document (voir `nature_volume`).

- surface_ha:

  Surface a laquelle la possibilite s'applique, en ha.

- autorite:

  L'un de
  [SOMMIER_AUTORITES](https://pobsteta.github.io/sommieR/reference/SOMMIER_AUTORITES.md).

- nom_qualite:

  Nom et qualite du signataire de l'acte.

- date_acte:

  Date de l'acte.

- auteur:

  Compte qui ecrit.

- type_validation:

  `"arrete"` (foret publique) ou `"agrement"` (PSG).

- reference:

  Reference de l'arrete ou de l'agrement.

- libelle:

  Libelle lisible (facultatif).

- ventilation:

  Possibilite ventilee par nature de coupe, en m3/ha/an, vecteur nomme -
  par exemple `c(regeneration = 3, amelioration = 1.4)`. Sa somme doit
  egaler `possibilite_m3_ha_an` (facultatif).

- serie:

  Serie concernee, si la foret en compte plusieurs (facultatif).

- tolerance_ans:

  Ecart admis a la balance cumulee, en annees de possibilite
  (facultatif) : quatre ans pour un PSG.

- source:

  Page ou tableau du document ou la possibilite est fixee (facultatif).

- nature_volume:

  `"possibilite"` (fixee par l'acte) ou `"recolte_prevue"` (recolte
  previsible du document d'amenagement).

- groupes:

  Surfaces par groupe d'amenagement, en ha, vecteur nomme - par exemple
  `c(regeneration = 2648.31, amelioration = 3016.81)` (facultatif).

- surface_regeneration_ha:

  Surface a ouvrir en regeneration sur la periode, en ha (facultatif).

- reference_m3_ha_an:

  Prelevement de reference a l'hectare, pour le controle de
  vraisemblance (facultatif).

- facteur_vraisemblance:

  Ecart, en facteur, au-dela duquel le controle avertit.

## Value

Invisiblement, l'entree chainee.

## Details

**La possibilite s'exprime a l'hectare.** Elle se saisit en m3/ha/an,
sur une surface ; le volume annuel en m3, que la balance confronte aux
martelages, s'en deduit. C'est l'unite dans laquelle se comparent les
forets entre elles et avec l'IFN, dont nemeton tire le prelevement
observe par sylvoecoregion.

**La possibilite est une ecriture.** Elle entre au registre 1 avec
l'acte qui la fixe, et elle est couverte par l'empreinte au meme titre
qu'un volume martele. La changer suppose un avenant
([`sommier_avenant_possibilite()`](https://pobsteta.github.io/sommieR/reference/sommier_avenant_possibilite.md)),
qui s'ajoute a la chaine : l'ancienne valeur reste lisible pour les
exercices qu'elle a couverts.

**Deux amenagements ne se chevauchent pas.** Un exercice appartient a un
seul amenagement, sans quoi il aurait deux possibilites. Une revision
anticipee clot d'abord l'ancien par avenant, en avancant sa fin.

**Possibilite ou recolte prevue.** Un PSG, ou un amenagement ancien,
fixe une possibilite. Les amenagements recents de l'ONF ne le font plus
: l'arrete fixe des surfaces par groupe (a regenerer, a ameliorer), et
le volume n'apparait qu'au document, comme recolte previsible pilotee en
surface terriere - l'arrete du 9 aout 2019 du massif de Lorris-Les
Bordes (foret domaniale d'Orleans) n'en porte aucun, son document en
prevoit 4,4 m3/ha/an. `nature_volume` le dit, et le rapport ne presente
pas une prevision comme une possibilite. Les surfaces que l'arrete fixe
se gardent dans `groupes` et `surface_regeneration_ha`.

**Le controle de vraisemblance avertit, il ne refuse pas.** La
possibilite peut etre confrontee a un prelevement de reference a
l'hectare - celui que l'IFN observe dans la sylvoecoregion. Au-dela d'un
facteur `facteur_vraisemblance`, un avertissement signale une possible
faute de frappe (un zero de trop). L'acte s'ecrit quand meme : la
possibilite est un acte d'autorite, pas une estimation, et un
amenagement de conversion ou de rattrapage s'ecarte legitimement de la
moyenne regionale.

## See also

[`sommier_avenant_possibilite()`](https://pobsteta.github.io/sommieR/reference/sommier_avenant_possibilite.md),
[`sommier_balance_possibilite()`](https://pobsteta.github.io/sommieR/reference/sommier_balance_possibilite.md),
[`sommier_reprendre_exercices()`](https://pobsteta.github.io/sommieR/reference/sommier_reprendre_exercices.md)

## Examples

``` r
# sommier_amenagement(con, foret, "FD-ORLEANS-2026", 2026, 2045,
#   possibilite_m3_ha_an = 4.4, surface_ha = 535.2, autorite = "ministre",
#   nom_qualite = "Ministre de l'agriculture", date_acte = "2026-02-01",
#   auteur = "gestionnaire", reference = "Arrete du 1er fevrier 2026")
```
