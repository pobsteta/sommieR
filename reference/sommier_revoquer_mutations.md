# Revocation des droits de mutation sur le registre

Complement indispensable aux declencheurs d'immutabilite : le brief
(section 6.2) revoque `UPDATE` et `DELETE` a l'utilisateur applicatif.
Le declencheur protege du bogue, la revocation protege du role.

Le proprietaire de la table et les superutilisateurs ne sont pas
concernes par une revocation - ils restent bloques par le declencheur,
mais peuvent le desactiver. Faire tourner l'application sous un role
distinct du proprietaire des tables n'est donc pas un detail de
deploiement.

## Usage

``` r
sommier_revoquer_mutations(con, role = "nemeton_app")
```

## Arguments

- con:

  Connexion DBI.

- role:

  Nom du role applicatif (defaut `"nemeton_app"`).

## Value

Invisiblement `TRUE`.
