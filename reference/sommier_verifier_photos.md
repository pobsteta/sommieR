# Verification des photos d'un sommier

Confronte chaque photo que le registre 2 reference a son fichier dans le
depot : conforme, alteree ou manquante.

## Usage

``` r
sommier_verifier_photos(con, foret_id, depot)
```

## Arguments

- con:

  Connexion DBI.

- foret_id:

  UUID de la foret.

- depot:

  Repertoire du depot.

## Value

Un `data.frame` : `entree_id`, `seq`, `element`, `sha256`, `type`,
`fichier`, `statut`.

## Details

**Une photo absente n'est pas une chaine rompue.** Trois cas sont
distingues :

- `conforme` : le fichier est la, et son empreinte est celle du registre
  ;

- `alteree` : le fichier est la, mais son empreinte differe - c'est une
  modification apres depot, et elle est signalee comme telle ;

- `manquante` : le fichier n'est pas dans le depot. La photo est perdue
  pour la lecture, mais l'empreinte chainee n'en est pas moins intacte :
  [`sommier_verifier()`](https://pobsteta.github.io/sommieR/reference/sommier_verifier.md)
  reste valide.

## See also

[`sommier_deposer_photo()`](https://pobsteta.github.io/sommieR/reference/sommier_deposer_photo.md)
