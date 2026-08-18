# Postes comptables du registre 7 (imprime A50G)

Nomenclature des postes de recettes et de depenses, reprise de la
structure de l'imprime A50G. Chaque poste porte son sens (recette ou
depense) et sa rubrique, de sorte que le sens n'a pas a etre saisi : il
decoule du poste, et ne peut donc pas le contredire.

## Usage

``` r
SOMMIER_POSTES_COMPTABLES
```

## Format

`data.frame` de 4 colonnes : `poste`, `sens`, `rubrique`, `libelle`.

## Details

Les rubriques suivent les quatre blocs de l'imprime :

- `produits` : recettes (bois sur pied, faconnes, delivres, chasse et
  peche, concessions).

- `travaux_entretien` : entretien des peuplements, des infrastructures,
  du tourisme, de la chasse et de la peche, exploitation en regie.

- `travaux_neufs` : reboisement, equipement, tourisme.

- `autres_frais` : impots fonciers, frais de garderie, honoraires.

`frais_garderie` ne concerne en pratique que la foret communale, et
`bois_delivres` que l'affouage ; ils ne sont pas pour autant interdits
ailleurs. Le sommier enregistre ce qui advient : refuser a priori une
ecriture parce qu'elle est inhabituelle rendrait le registre infidele.

## Examples

``` r
SOMMIER_POSTES_COMPTABLES
#>                       poste    sens          rubrique
#> 1             bois_sur_pied recette          produits
#> 2             bois_faconnes recette          produits
#> 3             bois_delivres recette          produits
#> 4              chasse_peche recette          produits
#> 5               concessions recette          produits
#> 6               subventions recette          produits
#> 7           autres_produits recette          produits
#> 8     entretien_peuplements depense travaux_entretien
#> 9  entretien_infrastructure depense travaux_entretien
#> 10       entretien_tourisme depense travaux_entretien
#> 11   entretien_chasse_peche depense travaux_entretien
#> 12       exploitation_regie depense travaux_entretien
#> 13              reboisement depense     travaux_neufs
#> 14               equipement depense     travaux_neufs
#> 15            tourisme_neuf depense     travaux_neufs
#> 16          impots_fonciers depense      autres_frais
#> 17           frais_garderie depense      autres_frais
#> 18               honoraires depense      autres_frais
#> 19             autres_frais depense      autres_frais
#>                                   libelle
#> 1                    Bois vendus sur pied
#> 2                           Bois faconnes
#> 3                Bois delivres (affouage)
#> 4         Locations de chasse et de peche
#> 5                    Concessions diverses
#> 6                     Subventions percues
#> 7                         Autres produits
#> 8               Entretien des peuplements
#> 9           Entretien des infrastructures
#> 10 Entretien des equipements touristiques
#> 11              Entretien chasse et peche
#> 12                  Exploitation en regie
#> 13                            Reboisement
#> 14                     Equipement nouveau
#> 15         Equipement touristique nouveau
#> 16                        Impots fonciers
#> 17                      Frais de garderie
#> 18                             Honoraires
#> 19                           Autres frais
```
