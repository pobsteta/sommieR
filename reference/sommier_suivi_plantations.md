# Suivi des plantations

Rend, par unite de gestion, par plantation suivie et par age, ce que les
placettes ont mesure : taux de reprise, densite a l'hectare, hauteur et
part d'abroutis, en moyenne des placettes controlees a cet age, et les
besoins qu'elles ont signales.

## Usage

``` r
sommier_suivi_plantations(con, foret_id)
```

## Arguments

- con:

  Connexion DBI.

- foret_id:

  UUID de la foret.

## Value

Un `data.frame` : `ug`, `travaux_id`, `annee_travaux`, `code_travaux`,
`age_ans`, `annee_controle`, `n_placettes`, `taux_reprise_pct`,
`densite_ha`, `h_moy_cm`, `abroutis_pct`, `besoins` (codes signales,
hors `aucun`, separes par une virgule ; `NA` s'il n'y en a pas).

## Details

Un etat courant, comme les limites : il n'est pas borne par une periode.
Les valeurs viennent de `v_controle_plantation`, qui les calcule depuis
les comptages ; rien n'y est saisi. Une plantation controlee deux fois
la meme annee (deux placettes a des jours differents) donne une ligne :
l'age est en annees.

## See also

[`sommier_controler_placette()`](https://pobsteta.github.io/sommieR/reference/sommier_controler_placette.md),
[`sommier_bilan_travaux()`](https://pobsteta.github.io/sommieR/reference/sommier_bilan_travaux.md)
