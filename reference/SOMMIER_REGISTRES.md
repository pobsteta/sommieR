# Les neuf registres du sommier unifie

Table de correspondance entre les registres de `sommieR`, les imprimes
de la serie A50 de l'ONF dont ils derivent, et l'echelle a laquelle ils
s'ancrent. Elle materialise la section 3 du brief.

## Usage

``` r
SOMMIER_REGISTRES
```

## Format

`data.frame` de 9 lignes et 5 colonnes : `registre`, `nom`,
`source_a50`, `echelle`, `implemente`.

## Details

`echelle` vaut `"foret"` (l'entree porte `ug_uuid = NULL`), `"ug"`
(`ug_uuid` obligatoire) ou `"mixte"` (les deux sont admis - le registre
6 couvre a la fois les travaux par unite de gestion, imprime A50J, et
les travaux hors unite de gestion, imprime A50H).

Seuls les registres 5 et 6 sont ouverts a l'ecriture en v0.1.0,
conformement a la priorite 1 du brief : ce sont eux qu'exigent la
certification PEFC et le bilan du document de gestion precedent.

## Examples

``` r
SOMMIER_REGISTRES
#>   registre                    nom  source_a50 echelle implemente
#> 1        1            Validations         A10   foret       TRUE
#> 2        2      Foncier & limites         A40   mixte       TRUE
#> 3        3   Droits & concessions        A50C   mixte       TRUE
#> 4        4        Infrastructures   A50D/Dbis   foret       TRUE
#> 5        5      Coupes & recoltes    A50E/F/I   mixte       TRUE
#> 6        6                Travaux A50J/Jbis/H   mixte       TRUE
#> 7        7           Comptabilite        A50G   foret       TRUE
#> 8        8     Evenements & faune      A50K/L   mixte       TRUE
#> 9        9 Patrimoine remarquable     A50 r/*   mixte       TRUE
```
