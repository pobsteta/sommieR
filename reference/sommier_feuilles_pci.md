# Feuilles cadastrales d'une commune

Rend les feuilles du plan cadastral, avec leur emprise, et permet de
retenir celles qui intersectent la foret.

## Usage

``` r
sommier_feuilles_pci(code_insee, emprise = NULL, marge_m = 100, cache = NULL)
```

## Arguments

- code_insee:

  Code INSEE de la commune.

- emprise:

  Couche des unites de gestion
  ([`sommier_couche_ug()`](https://pobsteta.github.io/sommieR/reference/sommier_couche_ug.md)),
  ou tout `data.frame` portant une colonne `wkt` en Lambert-93. `NULL` :
  toutes les feuilles.

- marge_m:

  Marge autour de l'emprise, en metres.

- cache:

  Repertoire de cache.

## Value

Un `data.frame` : `feuille`, `section`, `echelle`, `wkt`.

## Details

Les feuilles se lisent sur la couche legere d'Etalab, dont les
identifiants correspondent exactement aux noms des archives EDIGEO.
C'est ce qui rend le lot praticable : Couchey compte dix-sept feuilles
et une foret en touche une ou deux, alors que rien dans l'archive EDIGEO
ne dit ou elle se trouve avant de l'avoir telechargee.

## See also

[`sommier_fond_pci()`](https://pobsteta.github.io/sommieR/reference/sommier_fond_pci.md)

## Examples

``` r
# Necessite un acces reseau :
# sommier_feuilles_pci("21200")
```
