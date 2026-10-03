# Import d'une tournee de travaux et de suivi des plantations

Relit le projet rapporte du terrain et inscrit au registre 6 les travaux
releves, les placettes installees et les controles saisis, avec leurs
photos deposees sous leur empreinte.

## Usage

``` r
sommier_importer_qfield_travaux(con, foret_id, dossier, depot, auteur)
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

  Compte qui importe. L'agent qui a releve est l'operateur.

## Value

Invisiblement, un bilan : `travaux`, `placettes`, `controles` (nombres
d'entrees ecrites), `deja_presents`, `photos` et `entrees`.

## Details

**Tout ou rien.** Chaque saisie est controlee avant toute ecriture :
code connu et forme de la couche admise par le code, unite du code,
motif d'un ecart au prevu, placette rattachee a des travaux connus,
controle sur une placette connue, vivants et abroutis coherents, photos
presentes. Une faute fait echouer l'import, qui les liste toutes. Un
controle ajoute depuis sa couche, sans placette choisie, se rattache a
la placette la plus proche de sa position, a 15 m pres. L'ecriture se
fait en une transaction, dans cet ordre : travaux, placettes,
controles - une placette peut suivre des travaux releves dans la meme
tournee, un controle porter sur une placette qui vient d'etre installee.

**Rejouable.** L'UUID que QField a donne a chaque saisie devient celui
de l'entree : reimporter le meme dossier n'ecrit rien de plus. Les
placettes deja inscrites, versees dans le projet, ne se reinscrivent
pas.

**L'unite de gestion** d'une intervention est celle qui contient sa
geometrie (le point interieur d'une surface, le milieu d'une ligne) ;
hors de toute unite, l'intervention est inscrite a l'echelle de la
foret.

Toutes les entrees portent NDP 0 : ce sont des constats de terrain.

## See also

[`sommier_projet_qfield_travaux()`](https://pobsteta.github.io/sommieR/reference/sommier_projet_qfield_travaux.md),
[`sommier_verifier_photos()`](https://pobsteta.github.io/sommieR/reference/sommier_verifier_photos.md)
