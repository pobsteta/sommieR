# Brief — Lot 2 : la géométrie dans les payloads

*Établi le 19 août 2026. Suppose le lot 1 livré.*

## Pourquoi

Après le lot 1, la carte s'arrête à l'unité de gestion. Une borne posée en
2017, un fossé, un chêne remarquable, un tronçon de piste : rien de tout cela
n'a de coordonnées. Le registre 2 stocke des références cadastrales
(`R/registre2.R:108`), le registre 9 une localisation en clair
(`R/registre9.R:195`) — des chaînes de caractères, que personne ne peut
placer sur un plan.

C'est la carte forestière proprement dite qui manque, et c'est ce lot qui la
rend possible.

## L'idée directrice

L'empreinte couvre le champ `payload` (`R/empreinte.R:35`). Une géométrie mise
**dans le payload**, sérialisée comme le reste selon la RFC 8785, entre donc
dans la chaîne de hachage : **le contour d'une coupe devient aussi opposable
que son volume**, la position d'une borne aussi opposable que la date de son
implantation.

C'est le cœur du lot, et ce qui le distingue d'un simple ajout de colonne
PostGIS : la géométrie n'est pas une commodité d'affichage, c'est un constat
daté et signé au même titre que les autres.

## Décisions de conception

1. **La géométrie est du GeoJSON dans le payload**, pas une colonne. Le format
   est textuel, canonisable par JCS, et se relit sans PostGIS — un
   destinataire vérifie le manifeste hors ligne, géométries comprises.

2. **EPSG:4326, sans exception.** La RFC 7946 l'impose et le payload doit
   être interprétable sans contexte externe. C'est la règle déjà retenue à
   l'export GeoJSON, pour la même raison.

3. **Une colonne PostGIS dérivée**, alimentée par déclencheur à l'écriture,
   sert l'index spatial et les jointures. Elle est **hors empreinte** et
   entièrement reconstructible depuis le payload : si les deux divergent, le
   payload fait foi.

4. **Une version de schéma par registre touché** (`R/registres.R:93`) :
   `r4-1.1.0`, `r8-1.1.0`, `r9-1.1.0`. Les entrées antérieures restent
   valides et ne sont pas réécrites — l'append-only n'admet pas de migration
   de contenu.

5. **La géométrie reste facultative.** Un gestionnaire qui n'a pas de GPS
   continue de saisir sans coordonnées, et son sommier reste conforme. Rendre
   le champ obligatoire fermerait le registre à ceux qu'il doit servir.

6. **Le type géométrique est contraint par nature d'objet** : une borne est un
   point, un fossé une ligne, un habitat un polygone. Accepter n'importe quoi
   ferait de la vérification une politesse.

## Périmètre

Par ordre de valeur :

| Registre | Objets | Géométrie |
|---|---|---|
| 9 — patrimoine | arbres, vestiges, espèces | point |
| 9 — patrimoine | peuplements, habitats | polygone |
| 4 — infrastructures | voirie, fossés | ligne |
| 4 — infrastructures | équipements, ouvrages DFCI | point |
| 8 — évènements | phénomènes (tempête, sécheresse) | polygone |
| 2 — foncier | bornes, limites | point, ligne |
| 5 — coupes | emprise de coupe | polygone |

Les registres 1, 3, 6 et 7 restent sans géométrie : un visa, un bail, une
écriture comptable ne se localisent pas.

## Livrables

* Champ `geometrie` sur les constructeurs des registres retenus, validé quant
  au type et aux coordonnées.
* Validation JCS de la géométrie : mêmes octets pour deux écritures d'un même
  contour, sans quoi le chaînage perdrait sa reproductibilité.
* Colonne PostGIS dérivée, déclencheur d'alimentation, index GIST.
* Extension de `sommier_exporter_sig()` aux objets, et non plus aux seules
  unités.
* Cartes correspondantes dans les chapitres 4, 7 et 8 du rapport.
* Migration de schéma versionnée — le premier changement de schéma du projet.

## Risques

* **La migration.** Le schéma n'a jamais changé depuis la v0.1.0 ; ce lot
  impose d'en écrire une, et de la tester sur une base peuplée.
* **Le volume du payload.** Un polygone détaillé pèse plus qu'une écriture
  ordinaire. À surveiller : simplifier à l'écriture serait falsifier un
  constat, il faudra donc plutôt borner la précision demandée à la saisie.

## Critères d'acceptation

* Une entrée avec géométrie se vérifie hors ligne, manifeste seul, sans base.
* Les entrées sans géométrie conservent exactement leurs empreintes.
* Une géométrie mal formée est refusée à l'écriture, pas à la lecture.
