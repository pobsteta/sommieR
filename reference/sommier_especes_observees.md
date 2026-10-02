# Especes observees dans la foret et a ses abords

Rend les especes que d'autres ont observees dans la foret et autour -
des ornithologues, des botanistes, les inventaires nationaux -, nommees
dans TAXREF : une ligne par `CD_REF`, deux synonymes etant une espece.

## Usage

``` r
sommier_especes_observees(
  emprise,
  taxref,
  source = "gbif",
  tampon_m = 500,
  depuis = 2000,
  incertitude_max_m = 100,
  limite = 20000,
  occurrences = NULL
)
```

## Arguments

- emprise:

  Couche des unites de gestion
  ([`sommier_couche_ug()`](https://pobsteta.github.io/sommieR/reference/sommier_couche_ug.md)).

- taxref:

  TAXREF, tel que le rend
  [`sommier_taxref()`](https://pobsteta.github.io/sommieR/reference/sommier_taxref.md).

- source:

  Source des observations : `"gbif"`.

- tampon_m:

  Elargissement de la foret, en metres.

- depuis:

  Premiere annee d'observation retenue.

- incertitude_max_m:

  Incertitude de position au-dela de laquelle une observation n'est pas
  placee dans une unite, en metres.

- limite:

  Nombre maximal d'observations lues a la source.

- occurrences:

  Observations deja extraites (colonnes GBIF : `key`, `species`,
  `kingdom`, `decimalLongitude`, `decimalLatitude`,
  `coordinateUncertaintyInMeters`, `year`, `datasetKey`, `license`) ;
  `NULL` pour interroger la source.

## Value

Un `data.frame` : `cd_ref`, `nom_valide`, `nom_vernaculaire`, `groupe`,
`n_observations`, `premiere_annee`, `derniere_annee`, `ug` (unites ou
des observations sont placees, separees par des virgules), `n_jeux`.
Attributs : `source`, `extrait_le`, `parametres`, `taxref` (version),
`jeux` (cle, titre, licence et nombre d'observations de chaque jeu de
donnees, a citer), `non_rapprochees` (noms et nombres d'observations),
`tronque` (la source avait plus que `limite`).

## Details

**Un contexte, hors de la chaine.** Une observation d'un tiers n'est pas
un constat : rien n'entre au registre 9, et ce que le registre
inventorie ne change pas. Le rapport presente ces especes comme la
reference IFN : sourcees, datees, hors registre.

**La source.** GBIF, par `rgbif`, sur la boite de la foret elargie de
`tampon_m` ; les observations sont ensuite retenues si elles tombent
dans la foret tamponnee. Seules les observations presentes,
georeferencees, sans defaut geographique signale par GBIF et depuis
`depuis` sont lues. OpenObs, qui nomme nativement en TAXREF, s'ajoutera
quand le Museum l'aura retabli.

**Le rapprochement avec TAXREF.** GBIF nomme dans sa propre taxonomie.
Le nom d'espece de chaque observation est cherche parmi les noms
d'espece de TAXREF, du meme regne, hors emplois errones (`auct.`,
`sensu`). Un homonyme se departage par l'auteur, a l'annee pres ; un nom
qui ne mene a rien est retente sous le nom d'origine de l'observation
(`originalNameUsage`), s'il a la forme d'un binome latin. Ce qui mene
encore a plusieurs noms valides, ou a aucun, reste non rapproche :
compte a part, pas devine.

**Les unites de gestion.** Une observation n'est placee dans une unite
que si l'incertitude de sa position est connue et ne depasse pas
`incertitude_max_m` : une position floutee - c'est le sort des especes
sensibles - ne designe pas une unite.

## See also

[`sommier_taxref()`](https://pobsteta.github.io/sommieR/reference/sommier_taxref.md),
[`sommier_rapport_quarto()`](https://pobsteta.github.io/sommieR/reference/sommier_rapport_quarto.md)
et son argument `especes_observees`.

## Examples

``` r
# Necessite un acces reseau :
# taxref <- sommier_taxref()
# sommier_especes_observees(sommier_couche_ug(con, foret), taxref)
```
