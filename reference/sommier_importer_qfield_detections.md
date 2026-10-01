# Import des constats d'une tournee de verification des detections

Relit le projet rapporte du terrain et inscrit au registre 8 la suite de
chaque detection visitee : confirmee ou ecartee, avec la position, la
nature retenue et les photos deposees sous leur empreinte.

## Usage

``` r
sommier_importer_qfield_detections(con, foret_id, dossier, depot, auteur)
```

## Arguments

- con:

  Connexion DBI.

- foret_id:

  UUID de la foret.

- dossier:

  Dossier du projet, rapporte du terrain.

- depot:

  Repertoire du depot de photos.

- auteur:

  Compte qui importe. L'agent qui a constate est l'operateur de chaque
  constat.

## Value

Invisiblement, un bilan : `ecrits`, `deja_presents`, `non_vus`,
`deja_suivies` (les numeros des detections deja suivies), `photos` et
`entrees` (les entrees chainees).

## Details

**Tout ou rien.** Chaque constat est controle avant toute ecriture :
etat connu, detection presente dans le projet et appartenant a la foret,
nature connue - et exigee pour une detection confirmee -, date de
visite, photos presentes, une seule suite par detection. Une faute fait
echouer l'import, qui les liste toutes. Les suites s'ecrivent en une
transaction.

**Rejouable.** L'UUID que QField a donne au constat devient celui de
l'entree : reimporter le meme dossier n'ecrit rien de plus.

**« Non vu » n'ecrit rien** : la detection reste en attente. Une
detection deja suivie - par une autre tournee, ou a la main - ne l'est
pas une seconde fois ; le bilan la signale.

L'entree porte NDP 0 : c'est un constat de terrain. Elle rectifie la
detection, qui sort des vues de consultation sans sortir de la chaine
(voir
[`sommier_valider_detection()`](https://pobsteta.github.io/sommieR/reference/sommier_valider_detection.md)).

## See also

[`sommier_projet_qfield_detections()`](https://pobsteta.github.io/sommieR/reference/sommier_projet_qfield_detections.md),
[`sommier_verifier_photos()`](https://pobsteta.github.io/sommieR/reference/sommier_verifier_photos.md)
