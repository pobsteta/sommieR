# Verification des visas d'une foret

Confronte chaque visa a la chaine : l'empreinte attestee correspond-elle
bien a l'entree de la sequence visee, et la signature est-elle valide
sous la cle fournie ?

## Usage

``` r
sommier_verifier_visas(con, foret_id, cles_publiques = list(), ancres = list())
```

## Arguments

- con:

  Connexion DBI.

- foret_id:

  UUID de la foret.

- cles_publiques:

  Liste nommee de cles publiques, indexee par `kid` ou par `sub` du
  signataire. Inutile pour les visas portant leur certificat.

- ancres:

  Ancres de confiance pour les jetons d'horodatage, lues par
  [`certificat_lire()`](https://pobsteta.github.io/sommieR/reference/certificat_lire.md).
  Sans elles, un jeton intact est dit `"non_rattache"` plutot que
  valide.

## Value

Un `data.frame` : `exercice`, `autorite`, `seq_tete`, `concorde`,
`signature_valide`, `horodatage`, `date_attestee`, `remarque`.

## Details

Les cles publiques sont passees par l'appelant, indexees par `kid` ou
par `sub`. Le paquet ne va pas les chercher au JWKS du fournisseur :
cela ferait dependre une verification a valeur probante de la
disponibilite d'un service tiers au moment du controle, alors qu'un visa
doit rester verifiable des annees plus tard, hors ligne.

Un visa sans jeton d'horodatage est signale mais n'invalide rien : sa
date repose sur l'horloge du serveur, ce que l'appelant doit savoir sans
que cela constitue une fraude.

Depuis la v0.10.0, un visa peut porter le certificat de son signataire.
Quand il en porte un, la cle en est tiree et `cles_publiques` devient
inutile : le visa se verifie seul. Les visas anterieurs gardent le
comportement precedent.

`date_attestee` est lue **dans le jeton**, non dans la base : c'est la
date que l'autorite a certifiee. La colonne `date_visa`, elle, est celle
que le registre s'est donnee a lui-meme, et ne prouve rien contre celui
qui tient la base.

`horodatage` porte quatre etats plutot qu'un booleen, parce qu'un jeton
se juge sur plus que sa presence : `"absent"`, `"valide"` (signature de
l'autorite verifiee et chaine rattachee a une ancre), `"non_rattache"`
(le jeton est intact, mais aucune ancre ne le couvre) et `"invalide"`.

La revocation des certificats n'est jamais verifiee : CRL et OCSP
demandent le reseau. Voir
[`tsa_verifier_jeton()`](https://pobsteta.github.io/sommieR/reference/tsa_verifier_jeton.md).
