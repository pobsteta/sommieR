# Lecture d'un fond cadastral

Lit un fond telecharge par
[`sommier_fond_cadastral()`](https://pobsteta.github.io/sommieR/reference/sommier_fond_cadastral.md)
et le restreint a l'emprise de la foret.

## Usage

``` r
sommier_fond_lire(fond, emprise = NULL, marge_m = 100)
```

## Arguments

- fond:

  Objet `sommier_fond`.

- emprise:

  Couche des unites de gestion
  ([`sommier_couche_ug()`](https://pobsteta.github.io/sommieR/reference/sommier_couche_ug.md)),
  ou tout `data.frame` portant une colonne `wkt` en Lambert-93. `NULL` :
  toute la commune.

- marge_m:

  Marge autour de l'emprise, en metres. Une foret collee au bord de sa
  carte se lit mal.

## Value

Un `data.frame` : `reference`, `section`, `numero`, `contenance_m2`,
`wkt` (Lambert-93), portant les attributs `source` et `millesime`.

## Details

On ne retient que ce qui intersecte l'emprise tamponnee, et non tout le
territoire communal : Couchey compte pres de trois mille parcelles, une
foret n'en couvre qu'une poignee, et un fond illisible ne renseigne
personne.

La sortie est en Lambert-93, comme les couches du sommier : une carte se
mesure en metres, et melanger deux systemes sur le meme dessin les
decalerait.

## Examples

``` r
# Necessite `sf` et un fond telecharge :
# sommier_fond_lire(fond, emprise = couche)
```
