# Chainage d'une suite d'entrees hors base

Affecte `seq`, `hash_prev` et `hash` a une suite d'entrees, dans l'ordre
fourni. C'est la meme arithmetique que celle appliquee par
[`sommier_ajouter()`](https://pobsteta.github.io/sommieR/reference/sommier_ajouter.md)
cote base, isolee ici pour pouvoir etre testee, rejouee et verifiee sans
serveur.

## Usage

``` r
sommier_chainer(entrees, seq_depart = 1, hash_prev = NULL)
```

## Arguments

- entrees:

  Liste d'objets `sommier_entree`, ou un objet seul.

- seq_depart:

  Sequence de la premiere entree (defaut 1).

- hash_prev:

  Empreinte precedant la premiere entree. Par defaut la genese de la
  foret ; a renseigner pour prolonger une chaine existante.

## Value

Une liste d'objets `sommier_entree` chainees.

## Examples

``` r
foret <- "3f2b1c4d-5e6f-4a7b-8c9d-0e1f2a3b4c5d"
e <- sommier_entree(
  foret_id = foret, registre = 6L, date_evenement = "2026-04-15",
  auteur = "agent-01",
  payload = registre6_travaux(annee = 2026, nature_travaux = "degagement")
)
chainees <- sommier_chainer(list(e))
sommier_verifier_chaine(chainees)$valide
#> [1] TRUE
```
