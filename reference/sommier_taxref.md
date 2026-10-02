# Referentiel taxonomique TAXREF

Rend TAXREF, le referentiel taxonomique national, qui fait reference
pour nommer une espece en France : un taxon s'y identifie par son
`CD_NOM`, et son nom valide par son `CD_REF`.

## Usage

``` r
sommier_taxref(cache = NULL, source = SOMMIER_SOURCE_TAXREF, force = FALSE)
```

## Arguments

- cache:

  Repertoire de cache.

- source:

  Adresse de l'archive Darwin Core de TAXREF, ou chemin d'une archive
  deja telechargee.

- force:

  Relire la source meme si TAXREF est en cache.

## Value

Un `data.frame` : `cd_nom`, `cd_ref`, `nom` (sans auteur), `auteur`,
`rang`, `regne`, `embranchement`, `classe`, `ordre`, `famille`,
`nom_vernaculaire`. Attributs `version` (par exemple `"TAXREF v18.0"`)
et `source`.

## Details

TAXREF se lit dans un fichier, pas dans une API : l'archive Darwin Core
que PatriNat publie sur l'IPT de GBIF France se telecharge une fois,
explicitement, et se garde en cache, reduite aux especes et a leurs noms
valides. Ni le rapport ni
[`sommier_especes_observees()`](https://pobsteta.github.io/sommieR/reference/sommier_especes_observees.md)
ne la redemandent au reseau, et ils ne dependent donc pas de l'etat des
serveurs du Museum. La version est lue dans l'archive (`eml.xml`), pas
dans son adresse : une archive qui ne la dit pas est refusee.

## See also

[`sommier_especes_observees()`](https://pobsteta.github.io/sommieR/reference/sommier_especes_observees.md)

## Examples

``` r
# Necessite un acces reseau au premier appel (32 Mo) :
# taxref <- sommier_taxref()
```
