# Verification d'un manifeste exporte

Verifie hors ligne la chaine d'un manifeste produit par
[`sommier_exporter_manifeste()`](https://pobsteta.github.io/sommieR/reference/sommier_exporter_manifeste.md),
et confronte chaque visa et chaque ancrage a l'empreinte qu'il pretend
attester.

## Usage

``` r
sommier_verifier_manifeste(chemin)
```

## Arguments

- chemin:

  Fichier JSON produit par
  [`sommier_exporter_manifeste()`](https://pobsteta.github.io/sommieR/reference/sommier_exporter_manifeste.md).

## Value

Un objet `sommier_rapport`, dont les anomalies incluent les types
`visa_orphelin`, `ancrage_orphelin`, `visa_horodatage` et
`ancrage_horodatage`.

## Details

Deux confrontations sont faites, sans reseau ni magasin de confiance.

1.  Le `hash_tete` que l'attestation declare correspond a l'etat de la
    chaine a la sequence annoncee. Un visa dont l'empreinte ne
    correspond a aucune entree est signale : c'est ce qui detecte une
    attestation rapportee d'une autre chaine.

2.  **Le jeton d'horodatage atteste bien cette empreinte-la.** Le point
    1 porte sur ce que la base declare ; celui-ci sur ce que l'autorite
    a reellement signe. Sans lui, un jeton obtenu pour une autre tete de
    chaine accompagnerait le manifeste sans que rien ne le distingue du
    bon.

Ce qui n'est pas verifie : la signature JWS du visa, faute de clé
publique dans le manifeste, et la chaine de certification de l'autorite
d'horodatage, qui demande une ancre de confiance. Les deux relevent du
lot suivant.
