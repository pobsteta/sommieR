# Brief — Lot 4 : le PCI vecteur, bornes et détails topographiques

*Établi le 20 août 2026, après vérification sur une feuille réelle de Couchey.*

## Pourquoi ce lot existe

Le lot 3 concluait que les bornes et les fossés n'étaient pas dans le
cadastre. La conclusion était juste pour les **livraisons GeoJSON d'Etalab**,
qui sont une version simplifiée du PCI : le retraitement ne conserve que
parcelles, bâtiments, sections, feuilles, lieux-dits et subdivisions fiscales,
et écarte tous les détails topographiques.

Ils existent pourtant, dans le **PCI vecteur brut au format EDIGÉO** publié
feuille par feuille par la DGFiP sur le même site. Ce lot va les y chercher.

## Ce que la vérification a établi

Feuille `212000000A01` de Couchey, décompressée et ouverte par le pilote
EDIGÉO de GDAL :

| Couche | Géométrie | Objets |
|---|---|---|
| `BORNE_id` | point | 12 |
| `TLINE_id` | ligne | 50 |
| `ZONCOMMUNI_id` | ligne | 11 |
| `PARCELLE_id` | polygone | 38 |
| `SECTION_id`, `SUBDSECT_id`, `LIEUDIT_id`, `COMMUNE_id` | polygone | 1 à 12 |

`sf::st_layers()` sur le `.THF` suffit — aucun `ogr2ogr` intermédiaire.

Deux constats qui commandent la conception :

1. **Le `SYM` est là, sa nomenclature ne l'est pas.** `TLINE_id` porte un
   attribut `SYM` (valeurs 19, 21, 22, 23, 31 sur cette feuille), qui distingue
   mur, fossé, haie, clôture. Mais ni le `.DIC` ni le `.SCD` de l'archive ne
   contiennent la table de correspondance : elle appartient à la symbolisation
   du plan, publiée ailleurs.
2. **Le système de coordonnées arrive sans code EPSG.** Le pilote rend un
   proj4 Lambert-93 mais `st_crs()$epsg` vaut `NA`. Le lot, lui, **déclare son
   référentiel** : EDIGÉO est auto-descripteur, et le fichier `.GEO` porte
   `RELSA06:LAMB93` — `CC42` à `CC50` pour les livraisons `edigeo-cc`. On lit
   donc la déclaration plutôt que de reconnaître une chaîne.

## Décisions de conception

1. **On ne devine pas la nature d'un détail.** EDIGÉO décrit sa *structure* —
   noms d'objets, d'attributs et de relations — et GDAL s'en sert pour bâtir
   les couches et leurs champs ; c'est ainsi qu'on obtient `SYM` sans lire le
   `.DIC` soi-même. Mais la structure n'est pas la sémantique : sur la feuille
   examinée, toutes les définitions du `.DIC` sont vides (`DEFST00:`) et aucune
   section n'énumère les valeurs. Le code `SYM` est donc exposé tel quel, et
   une table de correspondance peut être **fournie par l'appelant**.
   Aucune table n'est embarquée tant qu'une source n'est pas citable : une
   correspondance plausible mais fausse ferait dire au document « fossé » là où
   le terrain montre un mur. Un paquet dont l'objet est la valeur probante ne
   peut pas se permettre une nomenclature approximative.

2. **On ne télécharge que les feuilles utiles.** Couchey compte dix-sept
   feuilles ; une forêt en touche une ou deux. Les feuilles à charger sont
   choisies sur la couche `feuilles` d'Etalab — légère, déjà en cache — dont
   les identifiants correspondent exactement aux noms des archives EDIGÉO.
   Charger toute la commune serait payer cinquante fois le nécessaire.

3. **Le PCI reste un décor.** Même règle qu'au lot 3 : rien n'entre dans un
   registre, une empreinte ou un manifeste. Une borne relevée par la DGFiP est
   la donnée d'un tiers ; le constat qui fait foi est celui du gestionnaire,
   au registre 2, avec sa géométrie.

4. **Le CRS vient de ce que le lot déclare**, non de ce qu'on croit
   reconnaître : le `.GEO` est lu, son code traduit en EPSG, et la sortie
   ramenée en Lambert-93 quelle que soit la livraison. Un référentiel absent ou
   inconnu se signale plutôt que de se laisser deviner — c'est le même défaut
   que le GeoJSON en 2154 corrigé en v0.6.0, et il se paie au même prix.

5. **Le téléchargement reste explicite**, comme au lot 3 : ni le rapport ni un
   export ne déclenchent d'appel réseau.

## Livrables

* `sommier_feuilles_pci()` — les feuilles cadastrales de la commune, avec
  leur emprise, et le choix de celles qui intersectent la forêt.
* `sommier_fond_pci()` — téléchargement et mise en cache des archives EDIGÉO
  des feuilles retenues.
* `sommier_fond_pci_lire()` — lecture d'une couche, restreinte à l'emprise,
  en Lambert-93, avec `SYM` brut et table de correspondance facultative.
* Bornes et détails en surimpression sur la carte de la desserte.

## Critères d'acceptation

* Une forêt de trois parcelles ne fait télécharger qu'une ou deux feuilles.
* Le `SYM` remonte brut ; sans table fournie, la nature reste `NA` et le
  document ne l'affiche pas.
* Une feuille en conique conforme est reprojetée d'après ce qu'elle déclare ;
  un référentiel absent ou inconnu est refusé, pas deviné.
* Aucune donnée PCI n'entre dans la chaîne de hachage.
