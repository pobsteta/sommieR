# Brief — Détections, lot 1 : vérifier sur le terrain, avec QField, ce que la télédétection propose

*Établi le 1er octobre 2026, à partir du sommier de la forêt domaniale d'Orléans.*

## Pourquoi ce lot existe

Une chaîne de télédétection ne constate rien : elle propose. Ses détections
entrent au registre 8 avec le niveau de précision de leur source (NDP ≥ 1), et
y restent **en attente** jusqu'à ce qu'un passage sur le terrain les confirme
ou les écarte. `sommier_valider_detection()` inscrit cette suite.

À Orléans, rien n'a encore été vérifié :

- **14 détections RECONFORT** (dépérissement du chêne) sont en attente au
  registre 8, sur 129,8 ha ;
- **16 coupes rases SUFOSAT** (47,9 ha, 2018-2022) ne s'expliquent par aucun
  martelage inscrit. Le rapport les signale, mais elles ne sont pas au
  registre.

Le lot « Limites » a monté la mécanique qui manque : un projet QField
engendré par le sommier, un constat par objet avec position GNSS et photos,
et un import au retour, tout ou rien et rejouable. Ce lot l'applique aux
détections.

## Ce que la vérification a établi

- **Les détections n'ont pas de géométrie.** Celles d'Orléans portent une
  unité de gestion et une surface (24,93 ha sur l'unité 1123, par exemple),
  mais aucun contour. Sur le terrain, l'agent ne saurait pas où chercher dans
  une unité de 30 ha. Les contours existent pourtant : les rasters RECONFORT
  (`reconfort_score`, `reconfort_mask`) et SUFOSAT du projet nemeton disent
  quels pixels ont déclenché la détection.
- **La suite d'une détection ne porte ni photo ni position.**
  `registre8_suite_detection()` connaît le statut (confirmé ou écarté), la
  nature retenue, la surface et le volume constatés, et des observations.
  C'est tout.
- **`sommier_valider_detection()` ne se rejoue pas.** Elle ne prend pas
  d'identifiant : réimporter une tournée écrirait la suite deux fois.
- **Les coupes SUFOSAT ne sont des détections qu'au rapport.**
  `sommier_coupes_sufosat()` les calcule, `sommier_importer_detections()`
  saurait les inscrire, mais rien ne fait le lien entre les deux.

## Décisions de conception

1. **La suite d'une détection devient un constat complet.** Le schéma
   `r8-1.3.0` donne à la suite les mêmes champs que la reconnaissance de
   limite : la position relevée (`geometrie`, en WGS84), `precision_m`,
   `source_gnss`, `releve_uuid`, `operateur`, `visite_le`, et `photos` par
   leur empreinte. Les suites écrites avant restent valides.

2. **Le contour d'une détection est un décor, recalculé à la génération.**
   Les détections déjà inscrites n'ont pas de géométrie, et on ne la leur
   ajoute pas : une entrée chaînée ne se complète pas après coup. Le projet de
   terrain dessine, pour chaque détection, les pixels qui l'ont produite, lus
   dans les rasters fournis (RECONFORT, SUFOSAT) et vectorisés sur l'unité.
   C'est un décor, hors de la chaîne, comme le PCI : il aide à trouver, il
   ne prouve rien. Sans raster fourni, la détection s'affiche par son unité.

3. **Une coupe SUFOSAT s'inscrit avant d'aller la voir.** Pour être
   confirmée ou écartée, elle doit d'abord exister au registre 8. Un pas
   explicite, `sommier_inscrire_coupes_sufosat()`, inscrit comme détections
   (source `sufosat`, NDP 1) les coupes qu'aucun martelage n'explique. Il
   recopie dans les observations la date médiane et la probabilité, et
   n'inscrit pas deux fois la même coupe (même unité, même année). Dans une
   vraie base, c'est une décision du gestionnaire, et le pas reste séparé.

4. **Le constat dit ce que la chaîne de télédétection ne pouvait pas dire.**
   Les états possibles :
   - `confirme`, avec la **nature retenue**, à choisir parmi
     `SOMMIER_NATURES_PHENOMENE`. Pour une coupe rase : coupe sanitaire
     (`crise_sanitaire`), chablis (`tempete`), sécheresse ou `autre`
     (exploitation programmée). C'est ce que SUFOSAT ignore ;
   - `ecarte` : rien de tel sur le terrain ;
   - `non_vu` : l'agent n'a pas pu aller voir. La détection reste en attente,
     et rien n'est écrit au registre.

   La surface constatée peut différer de la surface détectée ; les deux
   restent lisibles.

5. **Le projet QField reprend celui des limites.** Il a un modèle propre
   (`inst/qgis/detections.qgs`), produit par le même script PyQGIS, avec les
   mêmes règles : identifiants de couche préfixés, chemins relatifs, ortho
   hors ligne facultative, QField 4.3 au minimum. Le formulaire propose la
   détection la plus proche et exige un état. La nature n'est demandée que
   pour une détection confirmée. On peut joindre plusieurs photos.

6. **Le retour est tout ou rien, et rejouable.** `sommier_valider_detection()`
   gagne un argument `id` : l'UUID du constat saisi dans QField devient celui
   de l'entrée, si bien que réimporter n'écrit rien de plus. Une détection
   déjà suivie n'est pas suivie une seconde fois, et l'import le dit.

## Livrables

**Lot 1 : constat, projet, retour**

- `registre8_suite_detection()` gagne `geometrie`, `precision_m`,
  `source_gnss`, `releve_uuid`, `operateur`, `visite_le` et `photos`. Le
  schéma passe en `r8-1.3.0`.
- `sommier_valider_detection()` gagne `id` et les mêmes champs, et refuse
  une seconde suite pour une même détection (la base ne l'interdit pas :
  `corrige_id` n'est pas unique).
- `sommier_inscrire_coupes_sufosat(con, foret_id, coupes, auteur)` inscrit
  les coupes qu'aucun martelage n'explique.
- `sommier_contours_detections(con, foret_id, reconfort = NULL,
  sufosat = NULL, classe_min = 2, seuil_proba = 90)` vectorise, par unité,
  les pixels qui ont déclenché chaque détection en attente.
- `sommier_projet_qfield_detections(con, foret_id, dossier, operateur,
  reconfort = NULL, sufosat = NULL, fond = NULL, ortho = NULL)` écrit le
  projet de tournée.
- `sommier_importer_qfield_detections(con, foret_id, dossier, depot,
  auteur)` relit les constats et écrit les suites, avec leurs photos déposées
  sous leur empreinte. `non_vu` n'écrit rien.

**Lot 2 : le rapport**

- La section « Détections à vérifier » distingue les détections en attente,
  confirmées et écartées. Elle montre, pour chaque suite, la nature retenue,
  la surface constatée, la date et l'opérateur, et une planche de photos
  (celle des limites, généralisée). La version publique la retire.
- La balance signale toujours une coupe SUFOSAT sans martelage. Une fois
  confirmée en coupe sanitaire ou en chablis, elle le dit : ce n'était pas un
  oubli de martelage, mais un produit accidentel à inscrire au registre 5.

**Lot 3 : du constat au registre 5** *(ajouté le 2 octobre 2026)*

- `sommier_produit_accidentel(con, constat_id, volume_m3, auteur, ...)`
  inscrit le produit accidentel d'une détection confirmée en crise sanitaire,
  chablis, sécheresse, incendie, neige ou gel. Il reprend l'unité, la nature
  et la surface du constat, et y renvoie par `constat_id` (registre 5 en
  `r5-1.3.0`). Le volume reste saisi par le gestionnaire.
- Le rapport sépare les produits inscrits de ceux qui restent à inscrire. Une
  coupe SUFOSAT dont le produit est inscrit n'est plus comptée sans
  martelage.

## Critères d'acceptation

- Sur une copie d'Orléans, le projet contient les 14 détections RECONFORT, et
  les 16 coupes SUFOSAT une fois inscrites. Chacune a son contour quand les
  rasters sont fournis. Le projet s'ouvre dans QGIS et dans QField 4.3.
- Un constat `confirme` sans nature est refusé à l'import. Un constat
  `non_vu` n'écrit rien.
- Réimporter la même tournée n'écrit rien. Une détection déjà suivie n'est pas
  suivie deux fois.
- Les photos sont déposées sous leur empreinte, et `sommier_verifier_photos()`
  les retrouve.
- Inscrire deux fois les mêmes coupes SUFOSAT n'en inscrit qu'une fois.
- Rien de ce qui vient d'un raster n'entre dans la chaîne. Seul le constat de
  l'agent y entre, en NDP 0.

## Questions ouvertes

- **Inscrire les 16 coupes SUFOSAT dans la vraie base d'Orléans ?** C'est une
  écriture dans la chaîne réelle, à décider avant la tournée. Sinon, la
  tournée ne porte que les 14 détections RECONFORT.
- ~~Un seul projet pour tout ?~~ **Tranché le 1er octobre 2026 : deux
  projets QField**, l'un pour les limites, l'autre pour les détections.
- ~~Une coupe confirmée appelle-t-elle un martelage ?~~ **Tranché au lot 3 :**
  une coupe sanitaire ou un chablis constatés appellent un produit accidentel,
  que `sommier_produit_accidentel()` inscrit depuis le constat, avec le volume
  saisi par le gestionnaire. Une exploitation ordinaire appelle un
  martelage.
