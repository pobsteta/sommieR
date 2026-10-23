# Statuts des especes : la BDC Statuts de TAXREF

Rend les statuts reglementaires et de conservation des especes -
protection nationale, regionale et departementale, listes rouges,
annexes des directives Habitats et Oiseaux, sensibilite - tels que la
base de connaissance "Statuts" (BDC Statuts) de PatriNat les donne au
lieu de la foret, rapportes par `CD_REF`.

## Usage

``` r
sommier_statuts_taxref(
  cd_ref,
  emprise,
  cache = NULL,
  source = SOMMIER_SOURCE_STATUTS,
  force = FALSE
)
```

## Arguments

- cd_ref:

  `CD_REF` des especes, ou la table que rend
  [`sommier_especes_observees()`](https://pobsteta.github.io/sommieR/reference/sommier_especes_observees.md).

- emprise:

  Couche des unites de gestion
  ([`sommier_couche_ug()`](https://pobsteta.github.io/sommieR/reference/sommier_couche_ug.md))
  : la foret, dont un point fixe le lieu des statuts.

- cache:

  Repertoire de cache.

- source:

  Adresse de l'API TAXREF.

- force:

  Relire tous les taxons, meme en cache.

## Value

Un `data.frame`, une ligne par statut : `cd_ref`, `cd_nom` (le nom sous
lequel le texte cite l'espece), `type` (`PN`, `PR`, `PD`, `LRN`, `LRR`,
`DH`, `DO`, `SENSNAT`...), `groupe`, `code`, `libelle`, `remarque`,
`lieu`, `niveau`. Attributs : `version` (par exemple
`"BDC Statuts, TAXREF v18.0"`), `source`, `lieu` (code INSEE du lieu des
statuts), `consulte_le`, `consultes` (les `CD_REF` interroges, avec ou
sans statut).

## Details

**D'ou vient la donnee.** Le fichier de la BDC Statuts que l'INPN
publiait
(`inpn.mnhn.fr/telechargement/referentielEspece/bdc-statuts-especes`,
vers lequel data.gouv.fr renvoie toujours) ne repond plus depuis la
cyberattaque de l'ete 2025. L'API de TAXREF, elle, sert de nouveau la
BDC Statuts (`taxref.mnhn.fr/api`, ressource `status/search/lines`), et
c'est elle que la fonction interroge. La version citee est celle de
TAXREF que l'API declare courante (`taxrefVersions/current`) : la BDC
Statuts suit les versions de TAXREF.

**Le lieu de la foret, et non une liste nationale.** L'API rend, pour un
point, les statuts qui s'y appliquent : nationaux, de la region, du
departement. Le point est pris dans la foret (un point de sa surface, en
WGS84) : une liste rouge regionale du Centre-Val de Loire vaut pour
Orleans, pas celle de Bourgogne. Une foret a cheval sur deux
departements ne recoit que les statuts departementaux de l'un d'eux.

**Un taxon a la fois.** Une requete portant plusieurs taxons, ou un type
de statut sur tout le lieu, dedoublonne les lignes d'un taxon a l'autre
: le Pic mar y perd sa protection nationale, que le Pouillot siffleur
garde. La fonction interroge donc l'API taxon par taxon, et garde en
cache, par lieu, ce qu'elle a lu : un second appel ne demande au reseau
que les taxons nouveaux, et le rapport ne le sollicite jamais. Une
nouvelle version de TAXREF invalide le cache du lieu.

## See also

[`sommier_especes_observees()`](https://pobsteta.github.io/sommieR/reference/sommier_especes_observees.md)
et son argument `statuts`.

## Examples

``` r
# Necessite un acces reseau (un appel par espece, puis le cache) :
# statuts <- sommier_statuts_taxref(c(3619L, 2660L), sommier_couche_ug(con, foret))
```
