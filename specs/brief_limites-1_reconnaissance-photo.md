# Brief — Limites, lot 1 : vérifier sur le terrain, avec QField, photo à l'appui

*Établi le 30 septembre 2026, à la suite du lot 5 de la cartographie.*

## Pourquoi ce lot existe

Le lot 5 de la cartographie dit **ce que le plan cadastral annonce** : 118
éléments dans la forêt de Loury ou à moins de 20 m, dont 68 bornes, un pylône,
des voies, des bâtiments et des cours d'eau. Il ne dit rien de **ce que le
terrain montre**. Une borne peut avoir été arrachée par un débardage, enfouie
ou déplacée. Un mur peut s'être effondré. Le suivi des limites consiste à aller
voir, élément par élément, et à le prouver.

Ce lot organise l'aller-retour complet :

1. le sommier **prépare un projet QGIS/QField** qui contient les éléments à
   vérifier et l'état de leur dernière visite ;
2. l'agent **vérifie sur le terrain avec QField** : il se rend à l'élément,
   saisit son état, relève sa position au GNSS et le photographie ;
3. le sommier **réimporte le projet** : chaque constat devient une écriture du
   registre 2, et chaque photo entre dans la chaîne par son empreinte ;
4. le rapport **montre ce qui a été vu**, ce qui ne l'a pas été, et les photos.

Pourquoi QField : c'est un outil libre, standard et déjà répandu chez les
gestionnaires. Il lit un projet QGIS tel quel, travaille hors ligne, gère les
formulaires, les photos et les récepteurs GNSS externes (RTK compris). Le
sommier n'a pas d'application à maintenir, seulement un projet à produire.

## Décisions de conception

1. **Le constat est une écriture, le PCI reste un décor.** Le plan est la
   donnée d'un tiers, qui change d'un millésime à l'autre. Le constat de l'agent
   est ce qui fait foi : il entre au registre 2, sous un nouveau type
   `reconnaissance_limite` (schéma `r2-1.3.0`). Une écriture par élément visité,
   et non une par tournée : un élément se suit dans le temps, et la question
   « quand cette borne a-t-elle été vue pour la dernière fois ? » doit avoir une
   réponse directe.

2. **Le constat recopie l'élément tel que l'agent l'a vu.** Le payload porte
   l'identifiant du lot 5 (`feuille:OBJECT_RID`), le numéro court, la nature, le
   millésime et les coordonnées du plan, tels qu'ils figuraient dans le
   projet emporté. Au millésime suivant, le constat restera lisible, et on saura
   à quoi il répondait. Un élément trouvé sur le terrain mais absent du plan
   (une borne récente, un mur non dessiné) s'enregistre aussi, avec l'état
   `hors_plan` et sans identifiant PCI.

3. **Le projet est engendré, et QGIS n'est pas nécessaire pour cela.** Un
   modèle `.qgs` (du XML) est livré dans `inst/qgis/`, avec ses styles, ses
   formulaires et ses relations. R le complète : chemins, emprise, variables
   du projet. Aucun appel à QGIS ni à PyQGIS n'a lieu à la génération. Le `.qgs`
   est préféré au `.qgz`, parce qu'il se lit et se compare dans une revue.
   QField ouvre les deux. La cible est QField 4.x.

4. **Le projet est un dossier autonome, sans service en ligne.** Il contient
   un `.qgs`, un `terrain.gpkg` et un dossier `DCIM/` vide. On le copie sur le
   téléphone ou la tablette (USB, partage de fichiers), et on le récupère de la
   même façon. QFieldCloud reste possible, puisque le dossier est un projet
   QGIS ordinaire, mais il n'est pas requis. Une forêt sans réseau reste une
   forêt où l'on travaille.

5. **La photo n'entre pas dans la base, son empreinte oui.** À l'import, chaque
   photo est hachée (SHA-256) et copiée dans un **dépôt adressé par contenu**
   (`photos/<sha256>.jpg`), à côté de la base. Le payload porte l'empreinte, la
   taille et le type. La chaîne atteste alors les octets : un recadrage, une
   retouche ou un remplacement changent l'empreinte, et la vérification le
   voit. Le paquet ne modifie jamais une photo, même pour retirer des
   métadonnées : un fichier retouché par l'outil qui prétend en garantir
   l'intégrité, ce serait la preuve fabriquée par son propre gardien.

6. **Ce que la photo atteste, et ce qu'elle n'atteste pas.** C'est la leçon du
   lot 1 de la couche probante. La chaîne atteste que la photo existait, avec
   ces octets, **au moment de l'import**, et le jeton d'horodatage l'atteste
   s'il y en a un. Entre la prise de vue et l'import, la photo a vécu sur le
   téléphone : rien ne l'y protège. La date et la position EXIF sont des
   **déclarations de l'appareil**. On les recopie comme telles (`exif_date`,
   `exif_position`) et on ne les présente jamais comme des faits. Le rapport dit
   tout cela. Plus l'import suit la tournée de près, moins l'intervalle compte :
   le rapport imprime ce délai pour chaque constat.

7. **Des états constatés, pas des verdicts.** Les états possibles sont
   `en_place`, `endommage`, `non_retrouve` (cherché sans succès), `detruit`
   (vestiges constatés), `inaccessible` et `hors_plan`. Le paquet ne conclut
   jamais « déplacé » à partir d'un écart de coordonnées. L'écart entre la
   position relevée et le plan se **calcule au rendu**, et se lit à la lumière
   de la précision déclarée par le récepteur : il est dit « compatible »
   lorsqu'il est inférieur à cette précision augmentée de la précision
   graphique du plan (échelle de la feuille × 0,2 mm, soit 1 m au 1/5000). Juger
   qu'une borne a bougé revient au géomètre, pas au rapport.

8. **Une photo absente n'est pas une chaîne rompue.** C'est la leçon de #16. À la
   vérification, trois cas sont distingués :
   * photo présente, empreinte conforme ;
   * photo présente, empreinte **différente** : c'est une altération, signalée
     comme telle ;
   * photo **absente** du dépôt : elle est déclarée manquante, mais la chaîne
     reste intègre.

   `sommier_exporter_manifeste()` joint les photos, ce qui garde le paquet
   exporté autoporteur.

9. **Le retour est tout ou rien, et rejouable.** Chaque constat porte un UUID créé
   par QField au moment de la saisie. Réimporter le même dossier n'écrit rien
   de plus. Un constat invalide (état inconnu, élément introuvable dans le
   projet, pas d'état) fait échouer tout l'import, qui liste alors toutes les
   fautes à la fois : on corrige dans QField, puis on réimporte.

## Le projet QField

`terrain.gpkg`, en Lambert-93 :

| Couche | Géométrie | Édition | Contenu |
|---|---|---|---|
| `elements` | selon l'élément | lecture seule | Les éléments du lot 5, avec `derniere_visite` et `dernier_etat`, lus au sommier au moment de la génération |
| `constats` | point | saisie | Un constat par élément visité |
| `photos` | aucune | saisie | Les photos d'un constat : une ligne par photo |
| `foret`, `tampon` | polygone | lecture seule | Le contour des unités et le tampon de 20 m |
| `ug`, `parcelles` | polygone | lecture seule | Les unités de gestion et le fond cadastral, pour se repérer |

Le formulaire `constats` est préparé pour que l'agent ait le moins possible à
taper :

| Champ | Widget | Valeur par défaut |
|---|---|---|
| `uuid` | masqué | `uuid()` |
| `element_id` | liste liée à `elements` | l'élément le plus proche à moins de 30 m (`overlay_nearest`) |
| `etat` | liste de valeurs | aucune : l'agent doit choisir |
| `date_visite` | date et heure | `now()` |
| `operateur` | texte | variable de projet `operateur`, posée à la génération |
| `precision_m` | nombre, lecture seule | `@position_horizontal_accuracy` |
| `source_gnss` | texte, lecture seule | `@position_source_name` |
| `observations` | texte multiligne | — |
| photos | éditeur de relation vers `photos` | — |

Dans `photos`, le champ `fichier` utilise le widget **pièce jointe**, en mode
appareil photo, avec un chemin relatif au projet (`DCIM/…`). On peut
ainsi joindre plusieurs photos à un même constat.

La symbologie de `elements` indique à l'agent où aller : jamais visité (rouge),
visité il y a plus de *n* ans (orange), vu en place (vert), non retrouvé ou
détruit (noir). Une étiquette affiche le numéro court.

Pour le fond de carte, une couche **Géoplateforme de l'IGN** (orthophotos,
WMTS) est incluse, mais elle ne s'affiche qu'avec du réseau. Pour travailler
hors ligne, `sommier_projet_qfield()` accepte un raster fourni
(`fond_image = "ortho.tif"`), qu'il copie dans le dossier et ne télécharge
jamais.

## Livrables

**Lot 1 : le constat, le projet, l'aller-retour**

* `registre2_foncier()` gagne le type `reconnaissance_limite` et ses champs :
  `element_pci` (liste), `etat`, `date_visite`, `operateur`, `precision_m`,
  `source_gnss`, `releve_uuid`, `photos` (liste de
  `{sha256, octets, type, exif_date, exif_position}`), et `geometrie` (le point
  relevé). Le schéma passe en `r2-1.3.0`, et les anciennes écritures restent
  valides.
* `sommier_projet_qfield(con, foret_id, elements, dossier, operateur,
  fond = NULL, fond_image = NULL, anciennete_ans = 10)` : écrit le dossier du
  projet. `elements` est le tableau de `sommier_elements_pci()`. Le dossier ne
  doit pas exister, pour ne jamais écraser une tournée non rapatriée.
* `sommier_importer_qfield(con, foret_id, dossier, depot, auteur)` : lit
  `constats` et `photos`, contrôle, hache, copie dans le dépôt, puis écrit une
  entrée par constat. Il renvoie un bilan : constats écrits, déjà présents,
  photos ajoutées, fautes.
* `sommier_verifier_photos(con, foret_id, depot)` classe chaque photo en
  conforme, altérée ou manquante.
* `sommier_exporter_manifeste()` joint les photos référencées.
* La vue `v_reconnaissance_limite` : chaque élément et sa dernière visite.
* Une recette de terrain dans la NEWS : générer le projet de Loury, l'ouvrir
  dans QField, saisir trois constats avec photos (dont un `hors_plan`),
  rapatrier, importer.

**Lot 2 : le rapport**

* `sommier_rapport_quarto(photos = depot)` : le dépôt est fourni, jamais
  téléchargé, selon la même règle que `fond`.
* Une section « Vérification des limites sur le terrain », après celle du
  lot 5 :
  * **une carte** des 118 éléments selon leur dernier état (vu en place, vu
    endommagé, non retrouvé ou détruit, jamais visité, visité il y a plus de
    *n* ans), et les éléments `hors_plan` relevés ;
  * **un en-tête par nature** : « Bornes : 42 vues sur 68, dont 3 non
    retrouvées ; 26 jamais visitées » ;
  * **un tableau** : numéro, nature, état, date de la dernière visite,
    opérateur, écart au plan avec la précision déclarée, délai entre la visite
    et l'import, nombre de photos ;
  * **une planche photographique** de quatre vignettes par ligne. Sous chaque
    vignette figurent le numéro, la date de visite, l'état et les 12 premiers
    caractères de l'empreinte. Les vignettes sont réduites au rendu et ne sont
    pas attestées : seul l'original l'est. Une photo altérée n'est pas
    affichée, et sa case le signale ;
  * **un encadré** qui reprend la décision 6.
* `public = TRUE` retire la planche photographique (voir « Décisions
  arrêtées »).
* Des vignettes de 600 px au plus sur le grand côté, avec `magick` en
  `Suggests`. Sans `magick`, la planche liste les photos sans les montrer, et
  le dit.

## Critères d'acceptation

* Le projet engendré pour Loury s'ouvre dans QGIS et dans QField sans couche
  cassée. Un test automatique vérifie que le `.qgs` est du XML valide, que ses
  chemins sont relatifs et résolus, et, si `qgis_process` est installé, que QGIS
  le charge.
* Dans QField, un nouveau constat propose l'élément le plus proche, remplit la
  date, l'opérateur et la précision, et exige un état.
* Réimporter le même dossier n'ajoute ni écriture ni photo.
* Un constat à l'état inconnu fait échouer tout l'import, et rien n'est écrit.
* Une photo modifiée d'un octet après l'import est signalée comme altérée, et
  sa vignette n'apparaît pas.
* Une photo supprimée du dépôt est signalée comme manquante, et
  `sommier_verifier()` reste vert sur la chaîne.
* Les dates et positions EXIF apparaissent avec la mention « déclarée par
  l'appareil ».
* Un rapport rendu avec `public = TRUE` ne contient aucune image de photo.
* Aucun écart de coordonnées ne produit à lui seul l'état « déplacé ».
* Un élément vérifié puis disparu du plan au millésime suivant reste affiché
  avec les coordonnées recopiées dans le constat.
* Le rendu du rapport ne fait aucun appel réseau.

## Décisions arrêtées

*Tranchées le 30 septembre 2026.*

* **Données personnelles : une consigne, et un rapport public.** Une photo peut
  montrer un riverain ou une plaque d'immatriculation, et l'EXIF porte le
  modèle de l'appareil. Le formulaire `photos` du projet QField porte un texte
  d'aide : cadrer l'élément, éviter les personnes et les véhicules.
  `sommier_rapport_quarto()` gagne `public = FALSE`. À `TRUE`, la planche
  photographique disparaît, le tableau garde le nombre de photos et leurs
  empreintes, et l'encadré dit que les photos existent et où les demander. Les
  photos elles-mêmes ne sont jamais modifiées (décision 5).
* **Le dépôt de photos est un dossier local**, passé en paramètre (`depot`),
  à côté de la base. Le rangement par empreinte permettra de passer plus tard à
  un stockage objet sans rien changer au registre, mais ce lot ne le prévoit pas.
* **La tournée n'entre pas au sommier.** Seuls les constats s'écrivent. Ce qui
  n'a jamais été vu se lit déjà par différence entre les éléments du plan et
  les constats. Une tournée ne serait qu'un regroupement de travail, pas un fait
  à attester.
* **QField 4.x est la version plancher.** Le projet est développé et recetté
  sous QField 4. Le `.qgs` le déclare dans ses métadonnées, et le texte d'aide
  du projet l'affiche. `overlay_nearest` et les variables de position y sont
  disponibles sans détour. On ne cherche pas la compatibilité avec QField 2 ou 3.
