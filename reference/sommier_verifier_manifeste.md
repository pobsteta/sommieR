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
`visa_orphelin` et `ancrage_orphelin`.

## Details

La verification des signatures JWS et des jetons d'horodatage RFC 3161
releve du flux de visa (priorite 2 du brief) et n'est pas faite ici : ce
qui est verifie, c'est que le `hash_tete` atteste correspond bien a
l'etat de la chaine a la sequence annoncee. Un visa dont l'empreinte ne
correspond a aucune entree est signale - c'est deja suffisant pour
detecter une attestation rapportee d'une autre chaine.
