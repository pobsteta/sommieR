# Champs couverts par l'empreinte d'une entree

Les champs de
[entree_sommier](https://pobsteta.github.io/sommieR/reference/sommier_entree.md)
qui entrent dans le calcul de l'empreinte, dans l'ordre ou ils sont
documentes. `payload` en fait partie, mais il n'est pas le seul.

## Usage

``` r
SOMMIER_CHAMPS_EMPREINTE
```

## Format

An object of class `character` of length 11.

## Details

**Ecart assume par rapport au brief.** La section 6.1 du brief pose
`hash_n = SHA-256( JCS(payload_n) || hash_{n-1} )`, ou seul le payload
est hache. Cette formule laisse hors chaine `registre`, `ug_uuid`,
`date_evenement`, `auteur`, `ndp`, `seq` et `corrige_id` : on pourrait
reaffecter une coupe a une autre unite de gestion, en changer la date ou
l'auteur, sans qu'aucune empreinte ne bouge. Le declencheur PostgreSQL
l'interdit cote serveur, mais l'objectif annonce est justement que
"chaque acteur peut reverifier la chaine localement a partir d'un
export, sans faire confiance au serveur" : un export dont les
metadonnees ne sont pas couvertes n'est pas verifiable.

La forme de la formule est conservee - SHA-256 d'une serialisation
canonique concatenee a l'empreinte precedente - mais elle porte sur
l'enregistrement complet plutot que sur le seul payload.
