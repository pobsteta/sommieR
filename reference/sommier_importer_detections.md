# Import de detections par teledetection

Inscrit au registre 8 des phenomenes proposes par une chaine de
teledetection (FORDEAD, FAST). Chaque detection est ecrite avec le NDP
de sa source, jamais NDP 0 : c'est une proposition, pas un constat.

## Usage

``` r
sommier_importer_detections(con, foret_id, detections, source, ndp, auteur)
```

## Arguments

- con:

  Connexion DBI.

- foret_id:

  UUID de la foret.

- detections:

  `data.frame` ou liste de listes. Colonnes attendues : `nature`,
  `description`, `date_evenement` ; facultatives : `ug_uuid`,
  `surface_ha`, `indice`, `date_detection`, `observations`.

- source:

  Chaine de detection : `"fordead"`, `"fast"`, autre.

- ndp:

  Niveau de precision de la source (entier \>= 1). Une detection ne peut
  pas etre NDP 0 : ce niveau est reserve au constat de terrain.

- auteur:

  Identifiant du compte ayant lance l'import.

## Value

Invisiblement, la liste des entrees chainees.

## Details

Le sommier reste le receptacle NDP 0 de la plateforme sans pour autant
se fermer aux observations moins precises. La distinction est portee par
le champ `ndp` de l'entree : une detection FORDEAD arrive avec le NDP de
la chaine, et seule
[`sommier_valider_detection()`](https://pobsteta.github.io/sommieR/reference/sommier_valider_detection.md)
inscrit l'entree NDP 0 qui la confirme ou l'ecarte apres passage sur le
terrain.

Ecrire les propositions dans la chaine plutot que dans une table
d'attente est deliberé : une detection est un fait date - la chaine a
bien produit ce signal ce jour-la - et le sommier enregistre ce qui
advient. La suite donnee, elle, se lit au registre.

## See also

[`sommier_valider_detection()`](https://pobsteta.github.io/sommieR/reference/sommier_valider_detection.md),
[`registre8_detection()`](https://pobsteta.github.io/sommieR/reference/registre8_detection.md)
