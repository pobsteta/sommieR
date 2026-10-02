# Payload du registre 6 - travaux

Construit et valide le payload d'une intervention du registre 6
(imprimes A50J, A50J bis pour les travaux par unite de gestion, A50H
pour les travaux hors unite de gestion).

## Usage

``` r
registre6_travaux(
  annee,
  nature_travaux,
  localisation = NULL,
  repere_plan = NULL,
  quantite = NULL,
  unite = NULL,
  nb_plants = NULL,
  provenance_plants = NULL,
  montant_eur = NULL,
  taux_reprise_pct = NULL,
  observations = NULL,
  type_entree = NULL,
  code_travaux = NULL,
  modalite = NULL,
  essence_objectif = NULL,
  execution = NULL,
  intervenant = NULL,
  prevu = NULL,
  motif_ecart = NULL,
  date_reception = NULL,
  geometrie = NULL,
  precision_m = NULL,
  source_gnss = NULL,
  photos = NULL
)
```

## Arguments

- annee:

  Annee de realisation (entier).

- nature_travaux:

  Nature des travaux, en clair.

- localisation:

  Localisation en clair - a renseigner pour les travaux hors unite de
  gestion (imprime A50H), ou l'entree n'est ancree sur aucune unite de
  gestion.

- repere_plan:

  Repere sur le plan (facultatif).

- quantite, unite:

  Quantite realisee et son unite (facultatif). Avec un `code_travaux`,
  l'unite est l'une de celles du code.

- nb_plants, provenance_plants:

  Nombre de plants et provenance, pour les travaux de reboisement
  (facultatif).

- montant_eur:

  Montant en euros (facultatif).

- taux_reprise_pct:

  Taux de reprise en pourcentage, 0 a 100 (facultatif) : la colonne de
  l'A50J, pour la reprise de l'existant.

- observations:

  Observations libres (facultatif).

- type_entree:

  `"travaux"`, ou `NULL` (le defaut, qui vaut travaux).

- code_travaux:

  L'un des codes de
  [SOMMIER_CODES_TRAVAUX](https://pobsteta.github.io/sommieR/reference/SOMMIER_CODES_TRAVAUX.md)
  (facultatif).

- modalite:

  Modalite d'execution, courte ("mecanique en ligne").

- essence_objectif:

  Code de l'essence objectif.

- execution:

  L'un de
  [SOMMIER_EXECUTIONS_TRAVAUX](https://pobsteta.github.io/sommieR/reference/SOMMIER_EXECUTIONS_TRAVAUX.md).

- intervenant:

  Entreprise ou equipe.

- prevu:

  L'un de
  [SOMMIER_PREVUS_TRAVAUX](https://pobsteta.github.io/sommieR/reference/SOMMIER_PREVUS_TRAVAUX.md).

- motif_ecart:

  Raison d'un ecart au prevu ; obligatoire hors `prevu`.

- date_reception:

  Date de reception des travaux.

- geometrie:

  Emprise, en WGS84 : surface, ligne ou point selon le code (voir
  [`geom_polygone()`](https://pobsteta.github.io/sommieR/reference/geometries.md)).

- precision_m, source_gnss:

  Precision et source de la position relevee.

- photos:

  Photos, par leur empreinte (voir
  [`sommier_deposer_photo()`](https://pobsteta.github.io/sommieR/reference/sommier_deposer_photo.md)).

## Value

Une liste nommee, prete a etre passee a
[`sommier_entree()`](https://pobsteta.github.io/sommieR/reference/sommier_entree.md).

## Details

**Le libelle et le code.** `nature_travaux` reste le libelle libre de
l'A50J ; `code_travaux`, dans
[SOMMIER_CODES_TRAVAUX](https://pobsteta.github.io/sommieR/reference/SOMMIER_CODES_TRAVAUX.md),
est ce qu'on agrege. Le code fixe les unites admises pour la quantite et
les formes admises pour la geometrie : une cloture se trace en ligne, en
metres ; une plantation en surface, en hectares.

**Prevu, ou non.** `prevu` est un fait constate a la reception :
l'amenagement ou le PSG prevoyait-il l'intervention ? Hors `prevu`,
`motif_ecart` est obligatoire. Aucun statut "programme" n'entre au
registre, qui n'inscrit que ce qui a ete fait.

**Le resultat quitte l'intervention.** La reprise se mesure sur des
placettes, a des dates
([`registre6_placette()`](https://pobsteta.github.io/sommieR/reference/registre6_placette.md),
[`registre6_controle()`](https://pobsteta.github.io/sommieR/reference/registre6_controle.md)).
`taux_reprise_pct` reste admis pour transcrire la colonne "% de reprise"
de l'A50J papier.

**Le type d'entree.** Une intervention n'ecrit `type_entree` que s'il
est passe : les interventions inscrites avant la v0.28.0 n'en portent
pas, et doivent se relire a l'identique.

## See also

[`registre6_placette()`](https://pobsteta.github.io/sommieR/reference/registre6_placette.md),
[`registre6_controle()`](https://pobsteta.github.io/sommieR/reference/registre6_controle.md),
[SOMMIER_CODES_TRAVAUX](https://pobsteta.github.io/sommieR/reference/SOMMIER_CODES_TRAVAUX.md)

## Examples

``` r
registre6_travaux(
  annee = 2026, nature_travaux = "plantation",
  nb_plants = 1200, provenance_plants = "CHS - Bourgogne",
  montant_eur = 4800, code_travaux = "PL", quantite = 1.2, unite = "ha",
  prevu = "prevu"
)
#> $annee
#> [1] 2026
#> 
#> $nature_travaux
#> [1] "plantation"
#> 
#> $quantite
#> [1] 1.2
#> 
#> $unite
#> [1] "ha"
#> 
#> $nb_plants
#> [1] 1200
#> 
#> $provenance_plants
#> [1] "CHS - Bourgogne"
#> 
#> $montant_eur
#> [1] 4800
#> 
#> $code_travaux
#> [1] "PL"
#> 
#> $prevu
#> [1] "prevu"
#> 
```
