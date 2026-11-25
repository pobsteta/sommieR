<!-- Origine : copie recopiee telle quelle du brief de Surculus
     `surculus/pilotage/briefs/vers-sommier/2026-10-15-travaux-2-plants.md`.
     Deposee dans `specs/` le 2026-11-25 (mission 054 de nemetonplateforme, sous la delegation de Pascal).
     Trois choix de l'orchestrateur sur les questions ouvertes (delegation) : (1) essence AU PLANT, prerempli par
     l'essence objectif des travaux suivis ; (2) numerotation par azimut depuis le nord, sens horaire, fixee au premier
     pointage et jamais recalculee : sommieR la recoit de Surculus et ne la calcule pas ; (3) registre imprime : un
     decompte des plants sous leur placette, pas une ligne par plant.
     Realise en 2026.11.2.9000 : voir NEWS.md. Non realise dans cette mission : modele QField (`qfield_modele.py`,
     PyQGIS absent), plants vivants verses a l'aller, SOMMIER_METHODES_POINTAGE, demo Couchey, demandes
     complementaires.      ECART A LA DECISION 5 (reprise 1 de la mission 054, decision de l'orchestrateur sous delegation) : un plant
     mort ou absent NE PEUT PAS etre omis des controles suivants. Chaque plant pointe de la placette (hors remplaces
     par un regarni anterieur) a un etat a chaque controle qui porte des plants, comme « Terminer » dans Surculus
     (spec § 4.3). Raison : un mort omis sort de nb_total et fait passer taux_reprise_pct de 50 a 100 sans qu'aucun
     plant ait repris. Un etat date avant le pointage du plant est aussi refuse. -->

# Brief — Travaux, lot 2 : les plants, pointés et suivis d'un passage à l'autre

*Établi le 15 octobre 2026 depuis le dépôt `surculus`, à partir de sommieR
0.31.1 (`main`, `fd92078`). À déposer dans `specs/` de sommieR sous le nom
`brief_travaux-2_plants.md`. **Réaligné le même jour** sur la spec validée de
Surculus (`docs/spec.md`), ses référentiels (`docs/referentiels/`) et les ADR
0002, 0003 et 0007 : sommieR possède le schéma de ces couches, Surculus les écrit
à l'identique par anticipation (ADR 0007, décision de Pascal).*

## Pourquoi ce lot existe

Surculus, l'application Android de la tournée travaux, contrôle les
placettes en **pointant chaque plant** : un point, un UUID, un numéro dans
la placette, et à chaque passage son état selon le DSF (sain, atteint, mort,
absent), la cause d'une atteinte ou d'une mort, la hauteur ; un plant non retrouvé
est « non observé » (absence de mesure, hors totaux). C'est une décision de Pascal du 15 octobre 2026 : retrouver les
mêmes plants d'un passage à l'autre, et non seulement des totaux.

Le registre 6 ne connaît aujourd'hui que des totaux par contrôle
(`nb_total`, `nb_vivants`, `nb_abroutis`, `h_moy_cm`). Ce lot lui apprend
les plants, sans rien changer pour les contrôles par totaux déjà inscrits
ou saisis dans QField.

## Ce que la vérification a établi

- **Le registre 6 est en `r6-1.2.0`**, avec trois types d'entrée
  (`SOMMIER_TYPES_TRAVAUX` : `travaux`, `placette`, `controle`) et un
  `registre6_depuis_payload()` qui route la relecture.
- **`registre6_controle()` refuse déjà** plus de vivants que de plants et
  plus d'abroutis que de vivants. Rien ne relie un contrôle à des plants.
- **`sommier_importer_qfield_travaux()` lit des couches nommées**
  (`travaux_surf`, `travaux_lin`, `travaux_pt`, `placettes`, `controles`,
  `photos`) et ignore les autres : une tournée de Surculus portant des
  couches en plus s'importe donc déjà, plants exclus.
- **L'import se fait en une transaction, dans l'ordre** travaux, placettes,
  contrôles, rejouable par l'UUID de chaque saisie. Les plants s'y insèrent
  entre placettes et contrôles.
- **Une placette de 3,99 m de rayon (50 m²) porte une dizaine de plants**
  à 1 600–2 000 plants/ha : une entrée par plant reste modeste à l'échelle
  d'une forêt.

## Décisions de conception

1. **Un quatrième type d'entrée, `plant`.** Il porte `placette_id`,
   `numero` (dans la placette), `essence` (code ONF, `essences.csv` de
   Surculus), et l'**observation brute relative au piquet** : `distance_m`
   (horizontale), `azimut_mag` et `unite_azimut` (deg, gr), `declinaison_deg`,
   `convergence_deg`, `azimut_geo_deg`, `modele_geomagnetique` ; la
   `geometrie` (point, même repère que la tournée) en est dérivée. Un plant
   s'inscrit une fois, au passage où il est pointé ; un regarni est un
   nouveau plant (`regarni`), lié au plant mort ou absent qu'il remplace
   (`remplace_uuid`) : le plant remplacé sort des totaux suivants.
2. **Le contrôle peut porter l'état de ses plants.** `registre6_controle()`
   gagne `plants`, une liste de `{plant_id, etat, cause_groupe, cause_detail,
   hauteur_cm}`, `etat` dans `SOMMIER_ETATS_PLANT` (`sain`, `atteint`, `mort`,
   `absent`, ou `non_observe`), `cause_groupe` parmi les quatre groupes du DSF
   (`entomologique`, `pathologique`, `animaux`,
   `abiotique_complexe_indetermine`). Abrouti = sain ou atteint dont le détail
   porte l'abroutissement.
3. **Avec des plants, les totaux en découlent et doivent concorder.**
   `nb_total` = plants de la liste hors non observés et plants remplacés,
   `nb_vivants` = sains + atteints, `nb_abroutis` = vivants abroutis, `h_moy_cm` = moyenne des hauteurs données. Un contrôle
   dont les totaux ne concordent pas avec ses plants est refusé : la vue
   `v_controle_plantation` continue de lire les totaux, et ne change pas.
4. **Un contrôle sans plants reste valide** : c'est le cas de tous les
   contrôles inscrits avant ce lot, et de ceux saisis dans QField.
5. **Un plant mort ou absent le reste.** Un plant déjà mort ou absent à un
   passage antérieur peut être omis des passages suivants ; un plant vivant
   au passage précédent doit avoir un état.
6. **Registre 6 en `r6-1.3.0`.** Les payloads `r6-1.2.0` se relisent sans
   changement.

## Livrables

- `SOMMIER_TYPES_TRAVAUX` gagne `plant` ; `SOMMIER_ETATS_PLANT`,
  `SOMMIER_METHODES_POINTAGE` ; `registre6_plant()` ;
  `registre6_controle(plants = NULL)` et la concordance des totaux ;
  `registre6_depuis_payload()` route `plant`.
- `sommier_pointer_plant(con, placette_id, geometrie, numero, auteur, ...)`
  refuse une placette inconnue et un numéro déjà pris dans la placette.
- Vues : `v_plant` (plants courants, placette, UG, numéro, essence) et
  `v_etat_plant` (un état par plant et par contrôle, avec la date du
  contrôle) ; `v_controle_plantation` inchangée.
- **Projet QField `travaux`** (`data-raw/qfield_modele.py travaux`) : les
  couches de Surculus, **sans préfixe**, avec les champs de `docs/spec.md` § 5
  de Surculus : `plants` (POINT), `etats_plants`, `constats_reprise`
  (POLYGON), `vides` (POLYGON), `positions_controles` (POINT, position GNSS
  mesurée et drapeau « rattaché par identité »), et une table `projet` dont
  les champs écrits par sommieR (`nom`, `foret`, `prepare_le`,
  `version_sommier`, version du schéma) sont séparés de ceux écrits par
  Surculus (`operateur`, `version_surculus`). Tables sans géométrie déclarées
  `attributes` dans `gpkg_contents` (OGC 12-128, Req. 118-119) ; contraintes
  de valeurs par l'extension Schema (`gpkg_data_column_constraints`).
  `sommier_projet_qfield_travaux()` y verse les plants vivants des
  placettes, avec leur dernier état.
- **Import** : `sommier_importer_qfield_travaux()` lit `plants` et
  `etats_plants`, inscrit dans l'ordre travaux, placettes, **plants**,
  contrôles, et accepte un dossier ou un `.zip`. Fautes ajoutées à la liste
  rendue : plant sans placette, état d'un plant inconnu, deux états du même
  plant dans un contrôle, totaux qui ne concordent pas avec les états,
  plant vivant au passage précédent sans état.
- Suivi : `sommier_suivi_plantations()` gagne, quand des plants existent, la
  mortalité entre deux passages et le nombre de regarnis.
- Démo Couchey : les 3 placettes de l'UG 35 reçoivent leurs plants pointés,
  contrôlés en 2023 et 2025.
- Tests : rejouer les cas `fixtures/regles/plants/*.json` du dépôt
  `surculus` (résultats attendus écrits à la main), pour que R et Kotlin
  appliquent les mêmes règles.

## Ce que Surculus écrit déjà, à reprendre tel quel (mission 006, 2026-10-17)

Surculus écrit ces couches dans son export dès maintenant, par anticipation (ADR 0007) ; la
définition de sommieR fait foi dès qu'elle existe, mais autant partir de celle-ci. Décisions de
Pascal du 2026-10-17, vérifiées contre `sommier_importer_qfield_travaux()` 0.31.1 (l'import
ignore ces couches, l'export est relu sans écart avec et sans elles) :

- **Types** : `TEXT`, `INTEGER`, `REAL`, `BOOLEAN` (0 ou 1), `DATETIME` (ISO 8601 UTC,
  millisecondes, « Z », comme GDAL) ; clé `fid INTEGER PRIMARY KEY AUTOINCREMENT`, géométrie
  dans `geom`. Les UUID sont en minuscules (l'import de sommieR n'accepte que `[0-9a-f]`).
- **`constats_reprise.departs`** : un tableau JSON dans un `TEXT`.
- **`plants.modele_geomagnetique`** : `WMM2025`.
- **`projet`** : une ligne, qui porte la **version unique** du fichier. Les champs qui reviennent
  à sommieR (`nom`, `foret`, `prepare_le`, `version_sommier`) sont **laissés vides** par
  Surculus, et jamais écrasés : sommieR les remplira à l'aller (`sommier_projet_qfield_travaux()`)
  quand il aura le schéma ; Surculus écrit `operateur` et `version_surculus`.
- **Valeurs permises** par l'extension Schema de GeoPackage (`gpkg_data_column_constraints`,
  type `enum`) : `etat_plant`, `cause_groupe`, `unite_azimut`, `methode_constat`,
  `origine_vide` ; GDAL (≥ 3.3) les lit comme domaines de champ (vérifié avec `ogrinfo` 3.11.4) ;
  QGIS et QField reposent sur GDAL, mais ne sont pas essayés ici (voir « Terrain »).
- **Un contrôle par placette et par jour UTC** : l'import refuse la tournée entière si deux
  contrôles d'une même placette tombent le même jour UTC (`visite_le` est lu en `POSIXct`), alors
  que Surculus compte en jour civil Europe/Paris. Les deux diffèrent entre minuit et 2 h du matin
  à Paris : Surculus refuse l'export dans ce cas (double règle, décision de Pascal du 2026-10-17).
  **Demande à sommieR : aligner l'import sur le jour civil** (Europe/Paris) ; la règle UTC de
  Surculus tombera quand sommieR suivra.
- **`visite_le`** : l'instant du journal de Surculus, c'est-à-dire l'heure GNSS si le fix a au plus
  5 s, sinon l'heure du téléphone ; toujours écrit en UTC.

## Demandes complémentaires (porte n° 1 de Surculus)

À trancher par sommieR, dans ce lot ou un suivant :

- **Plantations à constater, à l'aller** : contour, nombre de plants,
  écartement et orientation des lignes, essence, date de réception,
  cloisonnements (constat de reprise en cheminement, ADR 0002 de Surculus).
- **Décision « hors entreprise »** (fascicule 34, art. 3-1.1) prise au bureau,
  dans sommieR, sur les pertes rendues par Surculus.
- **Table de correspondance des codes travaux** (`operations-plantation.csv`,
  `codes-taches-onf.csv`, `codes-teck-onf.csv` de Surculus) ; `montant_eur`
  facultatif.
- **Codes d'essences ONF** (`essences.csv` de Surculus) ; attention, `SAP` =
  sapin autre que pectiné, le sapin pectiné est `S.P`.
- **Passage de toute la tournée à EPSG:9794** (RGF93 v2b / Lambert-93) par une
  version du modèle : modèle QGIS, base, import et ortho ensemble (ADR 0003 de
  Surculus). Surculus lit le repère dans `gpkg_spatial_ref_sys` et refuse un
  fichier qui mêle 2154 et 9794.

## Critères d'acceptation

- Une tournée écrite par Surculus avant ce lot s'importe comme aujourd'hui
  (plants ignorés) ; après ce lot, la même tournée inscrit aussi ses plants.
- Réimporter la même tournée n'écrit rien. Une tournée dont un état est
  fautif n'écrit rien du tout.
- Les plants d'une placette contrôlée deux fois gardent leur UUID et leur
  numéro ; `v_etat_plant` rend deux états pour chacun.
- Un contrôle par totaux (QField, avant ce lot) reste valide et lisible.
- `sommier_verifier()` reste vert sur une base 0.31.1 mise à jour.

## Questions ouvertes

- **Essence au plant ou à la placette ?** Une plantation mélangée demande
  l'essence au plant ; une plantation pure la répète. Proposition : au plant,
  préremplie par l'essence objectif des travaux suivis.
- **Numérotation** : par azimut depuis le nord, sens horaire (règle de
  Groma), fixée au premier pointage et jamais recalculée ?
- **Registre imprimé** : les plants y ont-ils une ligne chacun, ou un
  décompte sous leur placette ?
