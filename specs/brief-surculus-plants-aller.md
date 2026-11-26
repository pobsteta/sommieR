# Brief vers Surculus — Les plants que sommieR écrit à l'aller : trois écarts avec ta spec

*Établi le 2026-11-26 depuis le dépôt `sommieR`, à partir de `a586121` (mission 065,
PR #91 : « plants à l'aller du projet QField »). Lu dans Surculus à `792cedd` (lecture
seule). Mission 079 de `nemetonplateforme`. Ce brief ne change aucun code : il pose trois
questions, sommieR n'en tranche aucune seule. Copie de référence ici ; Surculus reçoit une
issue qui renvoie à ce fichier.*

## Le constat

Depuis `a586121`, `sommier_projet_qfield_travaux()` verse à l'aller les couches `plants`
(POINT, Lambert-93) et `etats_plants` (table) : tous les plants non remplacés par un
regarni, chacun avec son dernier état s'il en a un (doc roxygen `R/travaux_qfield.R:65-77` ; appel à
`R/travaux_qfield.R:173` ; logique dans `verser_plants_aller`, `R/travaux_plants.R:551-606`).
Les couches sont celles de ta spec (`docs/spec.md:494` et `:496`). Trois choses écrites à
l'aller ne s'y retrouvent pas, ou pas telles.

## Écart 1 — la colonne `methode_pointage` de `plants`

**Ce que fait sommieR.** Si au moins un plant a une méthode de pointage, la couche `plants`
porte une colonne de plus, `methode_pointage` (`R/travaux_plants.R:565` pour la lecture,
`:586` pour l'ajout conditionnel). Valeurs fermées, `SOMMIER_METHODES_POINTAGE`
(`R/registre6.R:185-186`) : `relatif_boussole`, `relatif_saisie`, `gnss_plant`,
`construit`. Hors liste, sommieR refuse (`R/registre6.R:366-367` ; documenté en
`R/travaux_qfield.R:243-245`). La démo Couchey pose `construit` (`R/demo.R:395`, `:467`).
La colonne est lue au retour si elle existe (`COLONNES_PLANTS_TEXTE`, `R/travaux_plants.R:263`) ; sans elle, rien n'est inscrit.

**Ce que dit ta spec.** La couche `plants` n'a pas ce champ (`docs/spec.md:494` : `uuid`,
`placette_uuid`, `numero`, `essence`, `regarni`, `remplace_uuid`, `pointe_le`, `distance_m`,
`azimut_mag`, `unite_azimut`, `declinaison_deg`, `convergence_deg`, `azimut_geo_deg`,
`modele_geomagnetique`). `methode_pointage` ne figure nulle part dans ton dépôt (recherche
sur tout le dépôt, sans résultat). Les quatre valeurs étaient dites « reprises de Surculus »
dans `R/registre6.R:176-181` ; la doc est corrigée, elles sont propres à sommieR (définies le 2026-11-25, mission 065), et elles n'existent nulle part chez Surculus (recherche large, ADR 0003 compris) ; la seule trace
voisine est `source_azimut` (`boussole_telephone` ou `saisie`),
`docs/formats/journal-valeurs-v1.md:69`.

**Effet sur Surculus.** Aucun à la lecture : `LecteurTournee` fait `SELECT * FROM "plants"`
et ne copie que ses champs (`gpkg/.../LecteurTournee.kt:201-215`, `PlantLu` n'en a pas
d'autre). À l'écriture, l'export garde la colonne (`ajouterColonnesManquantes` n'ajoute que
les colonnes manquantes, `ExportTravaux.kt:340-350`) mais n'y écrit rien pour tes plants
(`ExportTravaux.kt:125-148`) : ils repartent avec `NULL`. La méthode d'un plant pointé par
Surculus n'arrive donc jamais au registre.

**Options.**
- Décision de Pascal (2026-11-26) : sommieR **garde** ces quatre valeurs. Il propose à Surculus de les adopter s'il veut la colonne (option A) ; il ne tranche pas pour Surculus.
- A. Surculus l'adopte (ce serait une création de vocabulaire côté Surculus, pas une reprise) : colonne ajoutée à `plants` (`docs/spec.md:494`), écrite par
  l'export (`relatif_boussole` ou `relatif_saisie` d'après `source_azimut`).
- B. Surculus ne la veut pas : sommieR cesse de l'écrire à l'aller (ligne `R/travaux_plants.R:586`)
  ou la garde pour sa seule démo ; il ne la lira plus au retour.
- C. Statu quo : colonne tolérée, ignorée, jamais renseignée par toi.

**Question.** Surculus veut-il porter `methode_pointage` dans `plants` et la renseigner
(A), ou sommieR doit-il la retirer de l'aller (B) ?

## Écart 2 — `controle_uuid` des états d'aller : un contrôle absent de la couche `controles`

**Ce que fait sommieR.** Chaque ligne de `etats_plants` écrite à l'aller porte pour
`controle_uuid` l'UUID du dernier contrôle qui a mesuré le plant (`d.controle_id`,
`R/travaux_plants.R:566`, `:601`), un contrôle déjà inscrit au registre, d'une tournée
passée. À l'aller, la couche `controles` n'est pas écrite par sommieR : elle vient du
gabarit `inst/qgis/travaux.gpkg`, où la table existe vide (vérifié, 0 ligne). La spec la
donne en « retour » seulement (`docs/spec.md:486`). Les états d'aller pointent donc vers
des contrôles que le projet ne contient pas.

**Ce que dit ta spec.** `etats_plants.controle_uuid` est un champ simple, sans dire où le
contrôle doit se trouver (`docs/spec.md:496`).

**Effet sur Surculus.** Ton code lit `controles` sans condition (`LecteurTournee.kt:176`,
pas de `existeTable`) puis cherche le dernier état d'un plant par `visite_le` du contrôle :
`visiteDe[it.controleUuid].orEmpty()` (`ContexteDeTournee.kt:48-49`). Avec `controles`
vide, tous les états valent `""` et `maxByOrNull` prend le premier : correct tant qu'un
plant n'a qu'un état, ce qui est le cas à l'aller (un seul état par plant,
`R/travaux_plants.R:594-604`). Mais l'état de l'aller n'a aucune date lisible, et rien ne
le départage d'un état saisi ensuite à un contrôle de la tournée. Côté sommieR, l'import ne
réinscrit pas ces lignes : il vérifie qu'elles reprennent l'état déjà au registre, sinon il
avertit (`etats_aller_ignores`, `R/travaux_plants.R:608-650` ; doc : `R/travaux_qfield.R:65-77`).

**Options.**
- A. sommieR écrit à l'aller, dans `controles`, une ligne par contrôle cité (`uuid`,
  `placette_uuid`, `visite_le`), pour que ta résolution par `visite_le` fonctionne.
  Coût : `controles` cesse d'être « retour » seulement (`docs/spec.md:486`) et les lignes
  d'aller ne doivent pas être réimportées comme des contrôles.
- B. Surculus accepte un `controle_uuid` sans ligne `controles`, et traite l'état d'aller
  comme antérieur à tout état de la tournée (à écrire dans ta spec).
- C. sommieR laisse `controle_uuid` vide à l'aller : à écarter, `controle_uuid` est la clé de rattachement de l'état (`R/travaux_plants.R:453`, `LecteurTournee.kt:218`).

**Question.** Surculus préfère-t-il A (lignes `controles` d'aller, avec `visite_le`) ou B
(état d'aller toujours le plus ancien, sans contrôle dans la couche) ?

## Écart 3 — l'`uuid` des états d'aller est dérivé (md5), pas tiré

**Ce que fait sommieR.** Pour ne pas inventer un identifiant que le registre ne connaît
pas, l'`uuid` de la ligne d'état est calculé : md5 de `"<controle_uuid> <plant_uuid>"`
(`R/travaux_plants.R:594-597`), découpé en 8-4-4-4-12 (`:598-600`). Même entrée, même
`uuid` : l'aller est rejouable à l'identique. Ce n'est pas un UUID v4 : sommieR en tire
ailleurs avec `uuid_v4()` (`R/valider.R:149-153`), qui force les bits de version et de
variante ; le calcul md5 ne les force pas (essai : `0cc9cd4d-d26c-5137-b675-a0d819cb9ab0`,
nibble de version `5`). Il a la forme 8-4-4-4-12, que `MOTIF_UUID` (`R/valider.R:10`)
accepte.

**Ce que dit ta spec.** Le journal de Surculus tire ses `uuid` en v7, ordonnés (`docs/adr/0005-stockage-et-sauvegarde.md:46`
et `:100`, RFC 9562) ; les états que Surculus écrit au retour reprennent l'`uuid`
de ses lignes (`ExportTravaux.kt:254`). Ta spec ne dit pas ce qui est exigé d'un
`uuid` d'`etats_plants` lu à l'aller.

**Effet sur Surculus.** À ma lecture, aucun : je n'ai trouvé aucun contrôle de version
d'UUID dans `core/src/main` (recherche de `v7`, `0x7`, `UuidV7`), et `EtatLu` prend le
texte tel quel (`LecteurTournee.kt:217-222`). Seul contrôle de forme : `ValidationExport.kt:35-41` (8-4-4-4-12 en minuscules), qui ne porte que sur les états écrits au retour. L'ordre « v7, croissant dans le temps » n'est
pas disponible pour les états d'aller : trier par `uuid` n'y a pas de sens.

**Options.**
- A. Garder le md5 : Surculus déclare dans sa spec qu'un `uuid` d'état d'aller est opaque,
  jamais ordonné.
- B. sommieR tire un v7 à l'aller et le stocke pour le rejeu : demande un lieu de
  stockage au registre, donc un changement côté sommieR (non estimé ici).
- C. sommieR passe en v4 aléatoire : l'aller n'est plus rejouable à l'identique.

**Question.** L'`uuid` d'un état d'aller peut-il être opaque et dérivé (A), ou Surculus
dépend-il d'un v7 (B) ?

## Ce que sommieR ne tranche pas, et ce qui n'est pas vérifié

- Aucun écart n'est tranché ici ; sommieR attend les trois réponses avant de toucher au code.
- Constat du relecteur : recherche faite dans tout le dépôt Surculus, `app/` compris : aucune
  lecture de `methode_pointage`, aucun contrôle de version d'UUID en lecture ; seule
  `gpkg/.../ValidationExport.kt:35-41` contrôle la forme 8-4-4-4-12 des états écrits au retour.
- Non vérifié : comportement de `LecteurTournee` sur une tournée réelle ; les lectures
  ci-dessus viennent du code, pas d'une exécution.
- Non vérifié : QField sur une couche `etats_plants` dont `controle_uuid` ne mène à rien.
