# Brief — Travaux, lot 1 : du relevé A50J au suivi sylvicole, sur le terrain avec QField

*Établi le 2 octobre 2026, à partir de sommieR 0.27.1 (`main`, commit `1c6c4c2`)
et d'un brief métier sur le suivi des travaux sylvicoles.*

## Pourquoi ce lot existe

Le registre 6 dit qu'une plantation a été faite, pas si elle a réussi. Ce lot
« Travaux » le fait passer du relevé A50J à un suivi sylvicole : chaque
intervention localisée et codée, et le résultat mesuré sur des placettes
permanentes, relevées avec QField comme les limites et les détections.

À la fin du lot, sommieR doit pouvoir répondre, unité par unité :

- quels travaux ont été faits, où exactement, à quel coût cumulé à l'hectare ;
- s'ils étaient prévus par l'aménagement ou le PSG, ou non (et pourquoi) ;
- si la plantation tient : reprise, densité, hauteur et abroutissement à n+1,
  n+3, n+5 ;
- quelle intervention s'impose ensuite.

**Hors périmètre** : la programmation des travaux et le suivi de chantier
(fiche de chantier, déclaration, facturation). Le registre est append-only :
il inscrit ce qui a été fait et réceptionné, pas ce qui est projeté. La saisie
d'un programme prévisionnel est une question ouverte (dernière section).

## Ce que la vérification a établi

- **Le registre 6 existe, en `r6-1.1.0`, mais il est plat.**
  `registre6_travaux()` porte `annee`, `nature_travaux` (texte libre),
  `localisation`, `repere_plan`, `quantite` + `unite`, `nb_plants`,
  `provenance_plants`, `montant_eur`, `taux_reprise_pct` et `observations`. Il
  n'a ni type d'entrée, ni code de travaux, ni géométrie, ni photos.
- **Le taux de reprise est rangé sur l'intervention.** C'est la colonne « % de
  reprise » de l'A50J. Une seule valeur par plantation, sans date ni méthode :
  on ne peut pas suivre son évolution. La démo l'inscrit même sur un
  dégagement (UG 35, 2024, 84 %).
- **La géométrie est prête à servir.** Toute entrée peut porter
  `payload$geometrie` en WGS84, projetée en Lambert-93 dans
  `entree_sommier.geom` par déclencheur (`003_geometrie.sql`). Mais
  `SOMMIER_TYPES_GEOMETRIE` n'admet que `Point`, `LineString` et `Polygon`,
  pas les multi-géométries.
- **Le motif « terrain » est rodé.** Limites (`R/qfield.R`) et détections
  (`R/detections_terrain.R`) suivent le même schéma : un modèle GeoPackage +
  `.qgs` produit par `data-raw/qfield_modele.py`, une fonction
  `sommier_projet_qfield_*()` qui le remplit, un import tout ou rien et
  rejouable (l'UUID QField devient l'`id` de l'entrée), et des photos déposées
  sous leur empreinte.
- **Le discriminant `type_entree` est l'usage.** Les registres 5, 8 et 9 en
  ont un, avec un `registre*_depuis_payload()` pour la relecture. Le 6 n'en a
  pas encore.
- **L'abroutissement existe à l'échelle de la forêt**
  (`registre8_equilibre_gibier()`, par saison), pas par placette.
- **Le rapport, devenu « Bilan de gestion » en 0.27.1, a une section Travaux**
  (`gestion-anterieure.qmd`, `#sec-travaux`) : un tableau par année et nature
  qui nomme ses unités depuis la 0.26.3, et une carte du montant par UG
  (`sommier_indicateurs_ug()`). Aucun graphique de suivi.
- **L'aménagement ne porte pas de programme de travaux.**
  `sommier_amenagement()` connaît la possibilité, les groupes et la surface à
  régénérer, pas les travaux prévus.

Le GeoPackage maquette du brief métier (`suivi_travaux_sylvicoles.gpkg`) sert
de cahier des charges des champs. Il ne s'intègre pas tel quel : le dépôt
produit ses modèles par PyQGIS, et son champ `statut` (Programmé, En cours…)
supposerait des mises à jour, interdites ici.

## Architecture

Le lot ne crée pas de nouveau stockage : tout s'inscrit au registre 6, dans
`entree_sommier`, et le reste se lit dans des vues.

```
Registre 6 ──► Vues SQL ──────────► Indicateurs R ──────► Rapport Quarto
travaux        v_travaux            suivi_plantations()   #sec-travaux
placette       v_placette           bilan_travaux()       3 graphiques + à faire
controle       v_controle_plantation
   ▲              │ verse UG, travaux, placettes
   │              ▼
 Import  ◄── Tournée terrain ◄── Projet QField
 importer_    QField 4.3, GNSS     projet_qfield_travaux()
 qfield_      contours, placettes  travaux.gpkg + .qgs
 travaux()
 (tout ou rien, rejouable)
```

La boucle terrain reprend celle des détections : le projet est un décor tiré
des vues, et seul l'import écrit, en NDP 0. Les photos sont déposées sous leur
empreinte ; seul le constat de l'agent entre dans la chaîne.

## Décisions de conception

Le registre 6 passe en `r6-1.2.0` avec trois types d'entrée. Tous les ajouts
sont facultatifs : les entrées déjà chaînées restent valides et se lisent
comme des `travaux`.

1. **Un discriminant `type_entree`**, comme aux registres 5, 8 et 9 :
   `travaux`, `placette`, `controle`. Un payload sans `type_entree` est un
   `travaux` (compatibilité). `registre6_depuis_payload()` route la relecture,
   et `valider_payload()` l'appelle au lieu de `registre6_travaux()`.
2. **Un code fermé à côté du libellé.** `SOMMIER_CODES_TRAVAUX` (data.frame :
   `code`, `famille`, `libelle`, `unite`, `forme`) reprend la nomenclature
   métier : PS, PL, RG, PG, PI, DG, CL, NT, TF, EL, DE, RN, BI, DS, PA.
   `nature_travaux` reste le libellé libre de l'A50J, `code_travaux` devient
   le champ qu'on agrège.
3. **Le résultat quitte l'intervention.** Le taux de reprise se mesure sur des
   placettes, à des dates. `taux_reprise_pct` reste admis sur `travaux`
   (reprise de l'existant, A50J papier), mais le rapport lui préfère les
   contrôles quand il y en a.
4. **Une placette est une entrée, ses passages en sont d'autres.** Installer
   une placette inscrit un `placette` (point, rayon) ; chaque relevé inscrit
   un `controle` qui y renvoie par `placette_id`. C'est le couple détection /
   suite du registre 8.
5. **« Prévu » est un fait constaté à la réception.** `prevu` vaut `prevu`,
   `reporte` ou `non_prevu`, et `motif_ecart` est obligatoire hors `prevu`.
   Aucun statut « programmé » n'entre au registre ; une intervention annulée
   ou erronée se rectifie par `corrige_id`.
6. **Une géométrie par entrée, en WGS84.** Polygone pour une surface, ligne
   pour une clôture ou un cloisonnement, point pour un regarni localisé. La
   forme attendue découle du code (`forme` dans `SOMMIER_CODES_TRAVAUX`).

### Payload `travaux` (champs ajoutés)

| Champ | Type | Règle |
| --- | --- | --- |
| `type_entree` | texte | `"travaux"`, défaut |
| `code_travaux` | texte | dans `SOMMIER_CODES_TRAVAUX$code` |
| `modalite` | texte | libre, court (« mécanique en ligne ») |
| `essence_objectif` | texte | code essence |
| `execution` | texte | `regie`, `entreprise`, `autre` |
| `intervenant` | texte | nom de l'entreprise ou de l'équipe |
| `prevu` | texte | `prevu`, `reporte`, `non_prevu` |
| `motif_ecart` | texte | obligatoire si `prevu` ≠ `prevu` |
| `date_reception` | date | ISO 8601 |
| `geometrie`, `precision_m`, `source_gnss` | GeoJSON, nombre, texte | comme au registre 2 |
| `photos` | liste d'empreintes | comme au registre 2 |

### Payload `placette`

| Champ | Type | Règle |
| --- | --- | --- |
| `type_entree` | texte | `"placette"` |
| `code_placette` | texte | lisible, unique dans l'UG (« P35-03 ») |
| `rayon_m` | nombre | 3,99 (50 m²) par défaut |
| `travaux_id` | UUID | la plantation ou la régénération suivie |
| `materialisation` | texte | piquet, peinture… |
| `geometrie` | GeoJSON Point | obligatoire |

### Payload `controle`

| Champ | Type | Règle |
| --- | --- | --- |
| `type_entree` | texte | `"controle"` |
| `placette_id` | UUID | une entrée `placette` de la même UG |
| `nb_total`, `nb_vivants` | entiers | `nb_vivants` ≤ `nb_total` |
| `h_moy_cm` | entier | tiges objectif |
| `nb_abroutis` | entier | ≤ `nb_vivants` |
| `concurrence` | texte | `faible`, `moyenne`, `forte` |
| `besoin` | texte | un code de travaux, ou `aucun` |
| `operateur`, `visite_le`, `photos` | | comme au registre 2 |

Taux de reprise, densité/ha et part d'abroutis ne s'inscrivent pas : la vue
les calcule. `date_evenement` est la date de visite ; l'âge de la plantation
se déduit de l'`annee` du `travaux_id`.

### Vues SQL (`002_vues.sql`)

- `v_travaux` : nouvelles colonnes **ajoutées en fin** (`CREATE OR REPLACE
  VIEW` n'accepte que cela), filtrée sur `type_entree` absent ou `travaux`. La
  famille de travaux est rattachée côté R depuis `SOMMIER_CODES_TRAVAUX`.
- `v_placette` : les placettes courantes, leur UG et leurs travaux suivis.
- `v_controle_plantation` : un contrôle par ligne, avec `age_ans`,
  `taux_reprise_pct`, `densite_ha` (nb_vivants × 10 000 / πr²) et
  `abroutis_pct` calculés.

## Livrables

**Payloads et constantes** (`R/registres.R`, nouveau `R/registre6.R`)

- `SOMMIER_CODES_TRAVAUX`, `SOMMIER_EXECUTIONS_TRAVAUX`,
  `SOMMIER_PREVUS_TRAVAUX`, `SOMMIER_CONCURRENCES`, documentés et exportés.
- `registre6_travaux()` gagne les champs du tableau `travaux`. Cohérences
  refusées : `motif_ecart` absent hors `prevu`, unité différente de celle du
  code, forme de géométrie différente de celle du code.
- `registre6_placette()`, `registre6_controle()` et
  `registre6_depuis_payload()`. `SOMMIER_SCHEMA_VERSIONS["6"]` passe à
  `r6-1.2.0`.

**Écriture en base** (nouveau `R/travaux_terrain.R`)

- `sommier_installer_placette(con, foret_id, ug_uuid, travaux_id, geometrie,
  auteur, ...)` refuse un `code_placette` déjà pris dans l'UG et un
  `travaux_id` d'une autre UG.
- `sommier_controler_placette(con, placette_id, ..., auteur, id = uuid_v4())`
  refuse une placette inconnue et un second contrôle de la même placette le
  même jour.

**Terrain** (modèle PyQGIS + R)

- `data-raw/qfield_modele.py travaux` produit `inst/qgis/travaux.gpkg`,
  `travaux.qgs` et, s'il y a lieu, `travaux_attachments.zip`. Les couches
  reprennent la maquette : `ug` et `parcelles` en lecture, `travaux_surf`,
  `travaux_lin`, `travaux_pt`, `placettes`, `controles` (relation vers
  `placettes`) en saisie. Listes déroulantes depuis les constantes, forme du
  formulaire selon le code, comme les limites selon le type.
- `sommier_projet_qfield_travaux(con, foret_id, dossier, operateur, fond =
  NULL, ortho = NULL)` copie le modèle et y verse les UG, les travaux déjà
  inscrits (décor) et les placettes actives, avec leur dernier contrôle et la
  couleur du besoin.
- `sommier_importer_qfield_travaux(con, foret_id, dossier, depot, auteur)`
  relit travaux, placettes et contrôles. Tout ou rien, rejouable par l'UUID
  QField, photos déposées sous leur empreinte. Ordre imposé dans la
  transaction : travaux, puis placettes, puis contrôles.

**Lecture et indicateurs** (`R/carte.R`, `R/export.R`)

- `sommier_suivi_plantations(con, foret_id)` : par UG et par âge, reprise,
  densité, hauteur et abroutis moyens des placettes, et le dernier besoin
  signalé.
- `sommier_bilan_travaux(con, foret_id, debut = NULL, fin = NULL)` : coût
  cumulé et coût à l'hectare par UG et par famille, et la part prévue,
  reportée ou non prévue.
- `sommier_indicateurs_ug()` gagne `cout_travaux_ha` et
  `dernier_taux_reprise_pct` en fin de colonnes.

**Rapport** (`inst/quarto/gestion-anterieure.qmd`, `#sec-travaux`)

- Reprise par âge de plantation, une ligne par UG et le seuil en trait (le
  graphique type du brief métier).
- Coût cumulé €/ha par UG, barres empilées par famille.
- Prévu, reporté, non prévu, par année, en hectares.
- Une liste « à programmer » : les placettes dont le dernier contrôle signale
  un besoin.
- La version publique garde les graphiques et retire photos, opérateurs et
  intervenants. Si le registre imprimé (brief sommier-1) est livré avant,
  `placette` et `controle` y ont leurs propres colonnes.

**Démo et doc** : `sommier_demo_couchey()` installe 3 placettes sur l'UG 35
(plantation 2022) et les contrôle en 2023 et 2025 ; le dégagement 2024 perd
son taux de reprise. README, NEWS en 0.28.0 et ce brief.

## Critères d'acceptation

- Toutes les entrées 6 déjà chaînées (démo, fixtures, reprise) se relisent
  sans erreur par `valider_payload(6, …)`, et `sommier_verifier()` reste vert
  sur une base créée en 0.27.1 puis mise à jour.
- Un `travaux` `non_prevu` sans `motif_ecart`, un code inconnu, une clôture
  saisie en polygone ou un `controle` avec plus de vivants que de plants sont
  refusés, à la construction comme à l'import.
- Un `controle` sur une placette d'une autre forêt ou inexistante est refusé.
- Sur la démo Couchey, `sommier_suivi_plantations()` rend l'UG 35 à n+1 et
  n+3, avec une densité calculée et non saisie.
- Le projet `travaux` s'ouvre dans QGIS 3.40 et QField 4.3 ; ses listes
  viennent des constantes R.
- Réimporter la même tournée n'écrit rien. Une tournée dont un contrôle est
  invalide n'écrit rien du tout.
- Les photos sont déposées sous leur empreinte et `sommier_verifier_photos()`
  les retrouve.
- Le rapport de démo montre les trois graphiques ; la version publique ne
  montre ni photo, ni opérateur, ni intervenant.

**Tests à écrire** : `test-registre6.R` (constructeurs, compatibilité
`r6-1.1.0`, cohérences), `test-travaux-db.R` (placettes, contrôles, vues,
indicateurs), `test-travaux-qfield-db.R` (modèle, import, rejeu, transaction),
sur le modèle de `test-detections-db.R` et `helper-qgis.R`. Le CI
(`.github/workflows/r.yml`) doit rester vert.

## Lots et ordre de réalisation

Quatre lots, chacun une PR et une version mineure ; chaque lot laisse `main`
publiable.

1. **Lot 1, le registre (0.28.0).** `type_entree`, `SOMMIER_CODES_TRAVAUX`,
   les trois constructeurs, `registre6_depuis_payload()`, `r6-1.2.0`, les
   vues, `sommier_installer_placette()` et `sommier_controler_placette()`.
   Démo mise à jour. C'est le seul lot qui touche au schéma des payloads : il
   passe en premier.
2. **Lot 2, le terrain (0.29.0).** Modèle PyQGIS `travaux`,
   `sommier_projet_qfield_travaux()`, `sommier_importer_qfield_travaux()`.
   Recette sur le terrain avant fusion, comme pour les limites.
3. **Lot 3, les indicateurs et le rapport (0.30.0).**
   `sommier_suivi_plantations()`, `sommier_bilan_travaux()`, colonnes ajoutées
   à `sommier_indicateurs_ug()`, les trois graphiques et la liste à
   programmer.
4. **Lot 4, la reprise (0.31.0, facultatif).** Importer un sommier de travaux
   tenu sous tableur (le format du tableau métier) par `sommier_reprise()`, en
   NDP ≥ 1, avec code et géométrie quand ils existent.

## Questions ouvertes

- **Multi-géométries.** Une plantation en trois placeaux : trois entrées liées
  par un `repere_plan` commun, ou ouvrir `MultiPolygon` et `MultiLineString`
  dans `SOMMIER_TYPES_GEOMETRIE` ? La seconde touche à `R/geometrie.R` et à
  tous les registres.
- **Programme prévisionnel.** Le champ `prevu` suffit-il, ou faut-il porter le
  programme de travaux de l'aménagement (au registre 1, comme la possibilité)
  pour calculer le réalisé contre le prévu en hectares ?
- **Seuils.** Où vivent le seuil de reprise et la densité minimale : une
  constante par essence, ou un paramètre du rapport ?
- **Abroutissement.** Agréger les contrôles par saison pour alimenter
  `registre8_equilibre_gibier()`, ou laisser les deux sources séparées ?
- **Modèle QField.** Un troisième projet, ou un onglet dans celui des limites
  ? Les détections ont tranché pour deux projets distincts ; ce brief propose
  un troisième.
