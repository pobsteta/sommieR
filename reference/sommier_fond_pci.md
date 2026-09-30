# Fond PCI vecteur d'une ou plusieurs feuilles

Telecharge et decompresse les archives EDIGEO des feuilles demandees.

## Usage

``` r
sommier_fond_pci(code_insee, feuilles, cache = NULL, force = FALSE)
```

## Arguments

- code_insee:

  Code INSEE de la commune.

- feuilles:

  Identifiants de feuilles, tels que les rend
  [`sommier_feuilles_pci()`](https://pobsteta.github.io/sommieR/reference/sommier_feuilles_pci.md).

- cache:

  Repertoire de cache.

- force:

  Retelecharger meme si l'archive est deja decompressee.

## Value

Invisiblement, un objet `sommier_fond_pci` : `feuilles` (table des
feuilles, de leurs fichiers `.THF` et de leur millesime), `code_insee`,
`source`.

## Details

**Le PCI est un decor, jamais une ecriture.** Rien de ce qui est
telecharge ici n'entre dans un registre, une empreinte ou un manifeste :
une borne relevee par la DGFiP est la donnee d'un tiers, et le constat
qui fait foi est celui du gestionnaire, porte au registre 2 avec sa
geometrie (voir
[geometries](https://pobsteta.github.io/sommieR/reference/geometries.md)).

Le telechargement est explicite, comme pour le fond parcellaire : ni le
rapport ni un export ne declenchent d'appel reseau.

Le millesime de chaque feuille est la date d'echange que le lot declare
dans son `.THF` (`TDASD`). Le telechargement vise la derniere livraison
: sans cette date, un plan de 2026 relu en 2031 ne dirait pas son age.

## Examples

``` r
# Necessite un acces reseau :
# sommier_fond_pci("21200", "212000000A01")
```
