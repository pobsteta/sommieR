<!-- Origine : copie recopiée telle quelle du brief de Surculus
     `surculus/pilotage/briefs/vers-sommier/2026-10-22-position-mesuree-du-controle.md`.
     Déposé dans `specs/` le 2026-11-25 (mission 052 de nemetonplateforme, sous la délégation de Pascal),
     sous le nom demandé par le brief. Réalisé en 2026.11.2.9000 : voir NEWS.md. -->

# Brief — La position mesurée du contrôle de placette, jusqu'au registre

*Établi le 22 octobre 2026 depuis le dépôt `surculus`, à partir de sommieR
0.31.1 (`fd92078`). Complète le brief `2026-10-15-travaux-2-plants.md` (lot 2),
qui demandait déjà la couche `positions_controles`. Décision de Pascal du
2026-10-22 (mission 028, `pilotage/journal.md`). À déposer dans `specs/` de
sommieR sous le nom `brief_travaux-2b_position_controle.md`.*

## Le constat

Surculus mesure la position de chaque contrôle : la position GNSS moyennée,
sa précision, et le drapeau « rattaché par identité » quand l'agent a confirmé
le piquet hors des 15 m (`docs/spec.md` § 4.3 et l. 259, ADR 0003). Il l'écrit
dans la couche `positions_controles` de la tournée.

L'import de sommieR 0.31.1 ne la lit pas, et le registre ne peut pas la garder :

- `R/registre6.R:150-180` : `registre6_controle` n'a aucun champ de géométrie ;
- `R/travaux_qfield.R:262-277` : l'import appelle `sommier_controler_placette`
  sans position ;
- `inst/sql/003_geometrie.sql:26-31` : `entree_sommier.geom` ne vient que de
  `payload->'geometrie'`, donc reste nulle pour un contrôle ;
- `inst/sql/002_vues.sql:366-398` : `v_controle_plantation` n'expose aucune
  position ; `v_placette.geom` est le centre de la placette, pas la position
  mesurée.

## Ce que ça coûte

Le registre ne sait pas où le contrôle a réellement été fait. Un piquet
déplacé, un contrôle rattaché par identité à 20 m, ou une position perdue à
l'import ne se voient pas dans sommieR.

## Ce qui est demandé

1. Que `registre6_controle` accepte une `geometrie` (POINT, WGS 84 dans le
   payload, comme les autres entrées), avec l'équivalent de `precision_m` et de
   `rattache_par_identite` (noms de Surculus).
2. Que l'import de la tournée lise `positions_controles` (clé
   `controle_uuid`) et passe la position au contrôle.
3. Que `v_controle_plantation` expose cette position.

Le nom des champs et leur place dans le modèle relèvent de sommieR.

## Ce que Surculus fait en attendant

La CI d'import de Surculus (mission 028, critère F4) compare les totaux du
contrôle au registre, et la position mesurée à la couche
`positions_controles` de l'export, à 0,5 m près. Le résumé du job dit que la
position n'arrive pas au registre. Quand sommieR la gardera, F4 la comparera
au registre.

## Complément du 2 novembre 2026 : des contrôles sans position mesurée

*Décisions de Pascal du 2026-11-02 (ADR 0003 de Surculus, « Amendement du
2026-11-02 : ouvrir un contrôle sans position » ; mission 085). Ce complément
s'ajoute au brief ci-dessus, qui reste valable.*

**Ce qui change dans Surculus.** Sous couvert dense, le téléphone peut ne
recevoir aucune position au pied du piquet. Après 30 s sans aucun fix (valeur
provisoire), Surculus permet d'ouvrir le contrôle sur le **code lu** du piquet,
connu de la tournée, après confirmation de la placette par l'agent. Le
contrôle prend alors la **position de la placette créée par sommieR** ; il n'a
**pas de position mesurée**. Un fix reçu, même unique ou médiocre, reste une
position et suit la règle des 15 m.

**Ce que l'export écrit pour un tel contrôle.**

- `controles` : la ligne porte la position du piquet et son `placette_uuid`,
  comme aujourd'hui. L'import 0.31.1 n'est pas touché : il lit
  `placette_uuid` et jette la géométrie (`R/travaux_qfield.R` l. 296-305 ; les
  15 m n'y servent qu'aux contrôles sans `placette_uuid`).
- `positions_controles` : **une ligne par contrôle**, avec une géométrie
  **NULL** (pas un POINT EMPTY), `precision_m` NULL, une nouvelle colonne
  booléenne `sans_position_mesuree` à vrai, et `rattache_par_identite` à vrai
  (sens élargi : le code lu a désigné la placette, la position mesurée ne l'a
  pas fait).

**Ce que ça ajoute à la demande ci-dessus.**

4. Que la `geometrie` du contrôle demandée au point 1 puisse être **absente**,
   et que le registre garde l'équivalent de `sans_position_mesuree`, pour
   distinguer « mesuré ici » de « pas de mesure, position reprise de la
   placette ».
5. Que l'import lise une ligne de `positions_controles` à géométrie NULL sans
   la refuser ni la confondre avec une position (0, 0).
6. Que `v_controle_plantation` dise, pour chaque contrôle, s'il a une position
   mesurée.

Le nom des champs et leur place dans le modèle relèvent toujours de sommieR.

**Sources de la géométrie NULL** (vérifiées le 2026-11-02) : Darwin Core,
`coordinateUncertaintyInMeters` (vide quand il n'y a pas de coordonnées, zéro
n'est pas une valeur valide) ; QField, `@position_horizontal_accuracy` (NULL
quand la position n'est pas celle du capteur) ; GeoPackage 1.3, exigence 152
(le point vide s'encode en NaN, mal défini avant la 1.3). Détail et liens :
ADR 0003 de Surculus.

**Ce que Surculus fera en attendant** (mission 086, à venir). La CI d'import
(F4) ne comparera la position qu'aux contrôles qui ont une position mesurée ;
pour les autres, elle vérifiera la ligne à géométrie NULL et
`sans_position_mesuree`.
