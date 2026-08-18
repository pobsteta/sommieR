# Densite de la voirie forestiere (imprime A50D)

Longueur et densite par nature de revetement, en kilometres pour cent
hectares. Vue calculee : rien n'est saisi.

## Usage

``` r
sommier_densite_voirie(con, foret_id)
```

## Arguments

- con:

  Connexion DBI.

- foret_id:

  UUID de la foret.

## Value

Un `data.frame` : `revetement`, `longueur_km`, `densite_km_100ha`, plus
une ligne `total`.

## Details

Seule la voirie **privee** forestiere entre au numerateur. L'imprime
A50D distingue voirie privee et voirie publique, et une route
departementale qui traverse la foret ne dit rien de sa desserte : l'y
compter gonflerait la densite sans qu'un metre de plus soit utilisable
pour l'exploitation.

La densite vaut `NA` lorsque la surface de la foret est inconnue : sans
denominateur, elle serait inventee.
