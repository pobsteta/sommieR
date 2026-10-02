# Import des constats d'un projet QField

Relit le projet rapporte du terrain et inscrit au registre 2 une
reconnaissance de limite par constat, avec ses photos deposees sous leur
empreinte.

## Usage

``` r
sommier_importer_qfield(con, foret_id, dossier, depot, auteur)
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

Invisiblement, un bilan : `ecrits`, `deja_presents`, `photos` (nombre de
photos deposees) et `entrees` (les entrees chainees).

## Details

**Tout ou rien.** Chaque constat est controle avant toute ecriture :
etat connu et de la liste du type choisi, type egal a la forme de
l'element, element present dans le projet (sauf `hors_plan`), date de
visite, photos presentes. Un projet engendre avant la v0.26.0 n'a pas de
type : ses constats gardent les etats d'une borne. Une seule faute fait
echouer l'import, qui les liste toutes a la fois : on corrige dans
QField, puis on reimporte. Les entrees s'ecrivent ensuite en une
transaction.

**Rejouable.** Chaque constat porte l'UUID que QField lui a donne a la
saisie ; il devient l'identifiant de l'entree. Reimporter le meme
dossier n'ecrit rien de plus, et le bilan le dit.

**Le constat recopie l'element tel que l'agent l'a vu** : identifiant,
numero, categorie, nature, texte, millesime et coordonnees du plan, lus
dans le projet emporte. Au millesime suivant, le constat restera
lisible.

La position relevee entre au payload en WGS84, comme toute geometrie du
sommier. Les photos sont deposees par
[`sommier_deposer_photo()`](https://pobsteta.github.io/sommieR/reference/sommier_deposer_photo.md),
qui ne les modifie jamais ; la date et la position EXIF y sont des
declarations de l'appareil. L'entree porte NDP 0 : c'est un constat de
terrain.

## See also

[`sommier_projet_qfield()`](https://pobsteta.github.io/sommieR/reference/sommier_projet_qfield.md),
[`sommier_verifier_photos()`](https://pobsteta.github.io/sommieR/reference/sommier_verifier_photos.md)
