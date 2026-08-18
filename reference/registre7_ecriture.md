# Payload du registre 7 - comptabilite

Une ecriture de recette ou de depense (imprime A50G). Le sens est deduit
du poste, et le montant est toujours **positif** : c'est le poste qui
dit s'il s'ajoute ou se retranche.

## Usage

``` r
registre7_ecriture(
  poste,
  exercice,
  montant_eur,
  libelle = NULL,
  quantite = NULL,
  unite = NULL,
  tiers = NULL,
  reference = NULL,
  dispositif_fiscal = NULL,
  observations = NULL
)
```

## Arguments

- poste:

  L'un des postes de
  [SOMMIER_POSTES_COMPTABLES](https://pobsteta.github.io/sommieR/reference/SOMMIER_POSTES_COMPTABLES.md).

- exercice:

  Exercice budgetaire (entier).

- montant_eur:

  Montant en euros, positif ou nul.

- libelle:

  Libelle de l'ecriture (facultatif).

- quantite, unite:

  Quantite et unite associees - par exemple le volume vendu en metres
  cubes (facultatif).

- tiers:

  Contrepartie (facultatif). Voir la note sur les donnees personnelles.

- reference:

  Reference de la piece : numero de titre de recette, de facture, de
  mandat (facultatif).

- dispositif_fiscal:

  L'un de
  [SOMMIER_DISPOSITIFS_FISCAUX](https://pobsteta.github.io/sommieR/reference/SOMMIER_DISPOSITIFS_FISCAUX.md)
  (facultatif, foret privee).

- observations:

  Observations libres (facultatif).

## Value

Une liste nommee, prete a etre passee a
[`sommier_entree()`](https://pobsteta.github.io/sommieR/reference/sommier_entree.md).

## Details

Porter le sens dans le signe du montant est la source classique de
doubles negations - une depense saisie a `-500` sur un poste deja
debiteur devient une recette sans que rien ne le signale. Ici
`montant_eur` est contraint positif ou nul, et `sens` est calcule : les
deux ne peuvent pas diverger.

**Donnees personnelles.** `tiers` (acheteur, titulaire de bail,
affouagiste, entreprise) est une donnee a caractere personnel des lors
qu'il designe une personne physique. Le champ est facultatif, et il doit
etre omis lorsqu'il n'est pas necessaire : une entree de sommier ne
s'efface pas, l'append-only s'appliquant aussi aux donnees personnelles
qu'on y aurait mises sans besoin.

## Examples

``` r
registre7_ecriture(
  poste = "bois_sur_pied", exercice = 2026, montant_eur = 18400,
  quantite = 320, unite = "m3", reference = "TR-2026-014"
)
#> $poste
#> [1] "bois_sur_pied"
#> 
#> $sens
#> [1] "recette"
#> 
#> $rubrique
#> [1] "produits"
#> 
#> $exercice
#> [1] 2026
#> 
#> $montant_eur
#> [1] 18400
#> 
#> $quantite
#> [1] 320
#> 
#> $unite
#> [1] "m3"
#> 
#> $reference
#> [1] "TR-2026-014"
#> 
```
