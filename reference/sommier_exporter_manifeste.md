# Export d'un manifeste verifiable

Ecrit la chaine d'une foret dans un fichier JSON autoportant : les
entrees, leurs empreintes, les visas et les ancrages. Le destinataire
verifie l'integrite hors ligne avec
[`sommier_verifier_manifeste()`](https://pobsteta.github.io/sommieR/reference/sommier_verifier_manifeste.md),
sans acces a la base et sans avoir a faire confiance a l'expediteur -
c'est le "partage sans confiance" du brief (section 6.3).

## Usage

``` r
sommier_exporter_manifeste(con, foret_id, chemin)
```

## Arguments

- con:

  Connexion DBI.

- foret_id:

  UUID de la foret.

- chemin:

  Fichier de destination.

## Value

Invisiblement, `chemin`.

## Details

Le brief prevoit a terme un GeoPackage accompagne de ce manifeste
(priorite 5). La v0.1.0 n'exporte que le manifeste : la chaine y est
complete et verifiable, la couche geographique viendra avec l'export
cartographique.

Le manifeste porte les payloads en JSON tel que stocke, pas en forme
canonique : c'est la verification qui recanonise. Un manifeste dont les
payloads seraient deja canoniques masquerait un bogue de canonisation
chez l'expediteur.
