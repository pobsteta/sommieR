# Verification des visas d'une foret

Confronte chaque visa a la chaine : l'empreinte attestee correspond-elle
bien a l'entree de la sequence visee, et la signature est-elle valide
sous la cle fournie ?

## Usage

``` r
sommier_verifier_visas(con, foret_id, cles_publiques = list())
```

## Arguments

- con:

  Connexion DBI.

- foret_id:

  UUID de la foret.

- cles_publiques:

  Liste nommee de cles publiques, indexee par `kid` ou par `sub` du
  signataire.

## Value

Un `data.frame` : `exercice`, `autorite`, `seq_tete`, `concorde`,
`signature_valide`, `horodate`, `date_attestee`, `remarque`.

## Details

Les cles publiques sont passees par l'appelant, indexees par `kid` ou
par `sub`. Le paquet ne va pas les chercher au JWKS du fournisseur :
cela ferait dependre une verification a valeur probante de la
disponibilite d'un service tiers au moment du controle, alors qu'un visa
doit rester verifiable des annees plus tard, hors ligne.

Un visa sans jeton d'horodatage est signale mais n'invalide rien : sa
date repose sur l'horloge du serveur, ce que l'appelant doit savoir sans
que cela constitue une fraude.

`date_attestee` est lue **dans le jeton**, non dans la base : c'est la
date que l'autorite a certifiee. La colonne `date_visa`, elle, est celle
que le registre s'est donnee a lui-meme, et ne prouve rien contre celui
qui tient la base. Le jeton est aussi confronte a la tete visee : un
jeton valide mais obtenu pour une autre empreinte est signale, la ou
`horodate` seul le comptait comme bon.

La signature de l'autorite d'horodatage n'est pas verifiee ici : elle
demande un magasin de confiance, et fait l'objet du lot suivant.
