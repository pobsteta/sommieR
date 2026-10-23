# Colonnes d'un sommier de travaux tenu sous tableur

Le format que lit
[`sommier_reprendre_travaux()`](https://pobsteta.github.io/sommieR/reference/sommier_reprendre_travaux.md)
: une ligne par intervention, une colonne par champ du payload `travaux`
du registre 6 (voir
[`registre6_travaux()`](https://pobsteta.github.io/sommieR/reference/registre6_travaux.md)),
plus l'unite de gestion, la date et la geometrie. C'est le tableau
metier du suivi sylvicole, tel qu'un gestionnaire le tient avant
d'entrer dans le sommier.

## Usage

``` r
SOMMIER_COLONNES_TABLEUR_TRAVAUX
```

## Format

Un `data.frame` : `colonne`, `alias` (synonymes admis, separes par une
virgule), `description`.

## Details

Les en-tetes se lisent sans egard a la casse, aux accents, aux espaces
ni a la ponctuation : `Annee` (accentue ou non), `annee` et `ANNEE`
designent la meme colonne, `Montant (EUR)` vaut `montant_eur`. Quelques
synonymes usuels sont admis (colonne `alias`). Une colonne qui n'est pas
dans ce tableau fait refuser le fichier : une donnee ecartee sans le
dire serait perdue sans trace.

Seule `annee` est obligatoire, et encore : elle se deduit de `date`
quand celle-ci est remplie. `nature_travaux` prend, a defaut, le libelle
du code.

## See also

[`sommier_reprendre_travaux()`](https://pobsteta.github.io/sommieR/reference/sommier_reprendre_travaux.md)
