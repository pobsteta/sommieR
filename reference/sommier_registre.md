# Sommier : le registre, ecriture par ecriture

Extrait le sommier tel qu'il est chaine : une ligne par ecriture,
registre par registre, dans l'ordre de la chaine, rectifiees comprises.
C'est l'inverse du bilan de gestion : ni somme, ni carte, ni estimation,
rien qui ne soit dans la chaine.

## Usage

``` r
sommier_registre(
  con,
  foret_id,
  registres = 1:9,
  jusqu_au_visa = NULL,
  cles_publiques = list(),
  ancres = list()
)
```

## Arguments

- con:

  Connexion DBI.

- foret_id:

  UUID de la foret.

- registres:

  Registres a extraire (1 a 9).

- jusqu_au_visa:

  Exercice dont le visa arrete l'edition ; `NULL` pour tout le sommier.

- cles_publiques, ancres:

  Transmises a
  [`sommier_verifier_visas()`](https://pobsteta.github.io/sommieR/reference/sommier_verifier_visas.md)
  pour verifier le visa qui arrete l'edition : cles publiques des
  signataires (inutiles quand le visa porte son certificat), ancres de
  confiance des autorites d'horodatage. Sans effet sans `jusqu_au_visa`.

## Value

Un objet de classe `sommier_registre` : `foret` (nom, regime),
`ecritures` (`data.frame`, une ligne par ecriture : `seq`, `registre`,
`type_entree`, `date_evenement`, `date_saisie`, `auteur`, `ndp`, `ug`,
`provenance`, `piece`, `rectifie`, `rectifiee_par`, `contenu`,
`payload`, `schema_version`, `hash`), `tenue` (fiche A10, par exercice),
`ancrages`, `verification` (etat de la chaine extraite), `visa` (le visa
qui arrete l'edition, s'il y en a un : `exercice`, `autorite`,
`seq_tete`, `hash_tete`, `date_visa`, `horodate`, `concorde`, et son
attestation - `signataire`, `signature_jws`, `certificat`, `jeton`,
`verifie`), `registres`, et `croquis` : `objets` (une ligne par ecriture
localisee, rectifiees comprises : `seq`, `registre`, `type_entree`,
`designation`, `date_evenement`, `provenance`, `ndp`, `rectifie`,
`rectifiee_par`, `ug`, `ug_uuid`, `localisation` - `propre`, `ug` ou
`foret` -, `type_geometrie`, `wkt` en Lambert-93, `precision_m`,
`x_l93`, `y_l93`, `floutage`, `contour_version`, `contour_en_vigueur`),
`contours` (toutes les versions de contour des unites, avec leur
source), `filiations`, `date_situation` et `non_localisees`.

## Details

**Les rectifiees restent.** Le classeur papier interdisait la rature et
imposait la mention rectificative : une ecriture rectifiee figure a sa
place, avec le numero de celle qui la rectifie (`rectifiee_par`), et la
rectification porte le numero de sa cible (`rectifie`).

**Chaque ligne dit d'ou elle vient.** Une transcription porte sa piece
(`payload$reprise`, voir
[`sommier_reprise()`](https://pobsteta.github.io/sommieR/reference/sommier_reprise.md))
; un constat n'en porte pas.

**La fiche A10 ouvre le sommier.** Pour chaque exercice depuis
l'ouverture, les actes de visa du registre 1, signes et horodates ou non
; un exercice sans acte est dit non vise. Les ancrages suivent.

**Les croquis sont hors chaine.** L'extraction porte aussi, pour
l'annexe de lecture, chaque ecriture localisee : par sa geometrie
propre, ou a defaut par son unite, prise dans le contour en vigueur a la
date de l'evenement (le plus proche, dit non en vigueur, quand aucun ne
l'etait). Une ecriture sans geometrie ni unite se rattache a la foret
entiere, sauf aux registres 1 et 7 : un visa ou une ligne de comptes
n'est pas un objet sur le terrain. Les contours ne sont pas des
ecritures ; ils sont rendus avec leur source.

**Une edition peut s'arreter a un visa.** `jusqu_au_visa` imprime le
sommier tel qu'il etait quand l'exercice a ete vise : les ecritures
jusqu'a la tete signee, pas au-dela. La chaine est alors verifiee
jusqu'a cette tete, et l'extraction dit si elle concorde avec
l'empreinte visee.

**Le visa se lit avec ses pieces.** Une edition arretee a un visa porte
aussi l'attestation de ce visa, verifiee par
[`sommier_verifier_visas()`](https://pobsteta.github.io/sommieR/reference/sommier_verifier_visas.md)
: qui l'a signe (les claims du signataire, et son certificat quand le
visa en porte un), si la signature se verifie et sous quelle cle, et ce
que vaut le jeton d'horodatage - la date que l'autorite a certifiee, et
qui est cette autorite. La signature, le certificat et le jeton
eux-memes sont rendus tels quels, pour etre recopies et verifies
ailleurs.

## See also

[`sommier_registre_quarto()`](https://pobsteta.github.io/sommieR/reference/sommier_registre_quarto.md),
[`sommier_exporter_manifeste()`](https://pobsteta.github.io/sommieR/reference/sommier_exporter_manifeste.md)
