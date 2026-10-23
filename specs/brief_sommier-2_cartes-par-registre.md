# Brief — Sommier, lot 3 : les cartes par registre

*Ouvert le 22 octobre 2026, suite du brief `sommier-1_registre-imprime`
(question ouverte « Les géométries »).*

*Cadrage donné par Pascal : les cartes par registre ; pour le successeur ;
éprouvé sur la démo de Couchey.*

## Ma réponse d'abord

*22 octobre 2026, Pascal :*

> J'attends des cartes representatives de chaque chapitre
>
> Parce que c'est la mémoire de la forêt

## Pourquoi ce lot existe

*Arbitrage de Pascal, 22 octobre 2026, à la question « qu'est-ce qui manque
au successeur que les cartes du bilan ne lui donnent pas ? » :*

> Le sommier montre tous les bilans. Le bilan est un instantané du sommier.

## Ce que la vérification a établi

*Établi par la lecture du code (contradicteur, 22 octobre 2026) ; la base
n'a pas été interrogée.*

- **Le lot 2 de `sommier-1`, le visa sur le document, est fait** (PR #54) :
  ce lot-ci est le lot 3 du sommier.
- **Une carte lisible s'appuie sur ce qui est hors chaîne** : les contours
  d'UG (`ug_geometrie`, versionnée, non chaînée,
  `inst/sql/001_schema.sql:86-95`), le fond cadastral (« décor, jamais une
  écriture »), la colonne `geom` en Lambert-93 dérivée du GeoJSON chaîné
  (`R/carte.R:221-224`). Les martelages (registre 5) et les travaux
  (registre 6) de Couchey ne se localisent que par leur UG
  (`R/demo.R:331-361`).
- **Les fonctions de carte actuelles cachent les rectifiées** :
  `v_objet_localise` repose sur `v_entree_courante`
  (`inst/sql/002_vues.sql:881`, `R/carte.R:226-228`) ; le bilan ne garde que
  le dernier relevé d'un sujet (`gestion-anterieure.qmd:285-290`) ;
  `sommier_geometrie_ug()` ne rend que les UG actives à une date
  (`R/carte.R:41-58`). Rien n'est réutilisable tel quel.
- **Les cartes du bilan n'ont ni échelle ni nord** (recherche dans
  `gestion-anterieure.qmd`, non vérifiée sur un rendu).
- **Couchey** : registres 1, 3 et 7 sans géométrie, 2 écritures localisées
  sur 10 au registre 8, aucune rectification, des visas écrits comme
  `registre1_validation` et non par `sommier_viser()` (à vérifier en base) ;
  trois blocs jusqu'à 1,7 km d'écart (`R/demo.R:35-38`).
- **`public = TRUE` ne masque que les noms des registres 3 et 7**
  (`R/registre_imprime.R:229`) ; le Sabot de Vénus du registre 9 est localisé
  au point (`R/demo.R:499-504`).

## Décisions de conception

*Arbitrages de Pascal, 22 octobre 2026, après la critique du contradicteur.*

1. **Les cartes sont une annexe de lecture, déclarée hors chaîne.** Comme
   l'IFN dans le bilan. Les objets localisés par leur UG (martelages,
   travaux) peuvent y figurer. Le principe du lot 1, « rien de ce qui n'est
   pas dans la chaîne n'y figure », vaut pour le registre ; il est levé
   pour cette annexe, et le document le dit.

2. **Un croquis par fiche, comme les imprimés A50.** Pas une carte par
   registre : un croquis par objet ou par UG (A50J « croquis à l'échelle
   avec légende » par UG, « plan de situation » par arbre…).

3. **À `public = TRUE`, les localisations sensibles sont floutées selon le
   SINP** (à la commune ou à la maille 10 × 10 km, selon le code de
   sensibilité ; art. D411-21-3 du Code de l'environnement). **Ce qui est
   sensible est dit par une liste de référence** (sensibilité SINP des
   espèces, statuts), pas par le type d'écriture.

   *Arbitrage de Pascal, 23 octobre 2026, après acquisition :* **la liste de
   référence est le référentiel national de sensibilité de l'INPN**
   (`SENSIBILITE.zip`, version 18 du 7 août 2025,
   `assets.patrinat.fr/files/referentiel/SENSIBILITE.zip`), daté et
   empreint. Il porte, par `CD_REF` et par département (`CD_DEPT`), le code
   de sensibilité (1 à 3), sa durée depuis l'observation, ses conditions
   (statut biologique, comportement, autre) et la liste régionale dont il
   vient. L'API TAXREF n'est pas retenue comme source. La licence n'est pas
   demandée à PatriNat.

4. **Toutes les positions, chacune avec son numéro.** Une écriture rectifiée
   reste dessinée, marquée « rectifiée par le n° X », d'un trait distinct ;
   un objet relevé plusieurs fois montre chaque relevé. C'est la mention
   rectificative, portée sur le croquis.

5. **La provenance se lit sur le croquis, par le trait.** Une variable
   visuelle distingue le constaté du transcrit et le NDP (plein, tireté…),
   avec sa légende ; chaque objet porte son numéro d'écriture et sa date.

6. **Chaque écriture dans la forêt de son époque.** Le croquis prend les
   contours d'UG en vigueur à la date d'événement de l'écriture, UG fermées,
   scindées ou fusionnées comprises (`ug_filiation`), et dit de quelle date
   sont ses contours.

7. **Le minimum de chaque croquis :** barre d'échelle et flèche du nord ;
   système de coordonnées (Lambert-93) et précision du relevé quand elle
   est connue ; source et millésime du fond et des contours, date
   d'édition. La mention « ce croquis n'est pas un plan de bornage » n'est
   pas retenue.

8. **Un plan de situation ouvre l'annexe.** Une vue d'ensemble de la forêt,
   tous blocs, puis chaque croquis à l'échelle de son UG ou de son objet.

9. **Le PDF est produit en PDF/A** (ISO 19005), polices et croquis
   embarqués, rejouable sans réseau : l'ONF archive l'ancien aménagement
   cent ans (instruction 88G16, citée par la note ONF Savoie du 17/12/2020).

## Livrables

**Lot 3 : les croquis du sommier**

- **L'extraction.** `sommier_registre()` porte, en plus, les croquis : une
  ligne par écriture localisée, rectifiées comprises (lue dans
  `entree_sommier`, pas dans `v_entree_courante`), avec son numéro, son
  registre, sa date d'événement, sa provenance et son NDP, et sa géométrie :
  celle du payload, à défaut celle de son UG **à la date d'événement**
  (`ug_geometrie` versionnée, `ug_filiation` pour les UG disparues). Arrêtée
  à un visa, l'extraction s'arrête à la tête visée.
- **Le rendu.** Dans `inst/quarto/sommier.qmd`, une annexe « Croquis »,
  déclarée hors chaîne : le plan de situation de la forêt, puis un croquis
  par fiche (par objet ou par UG), chacun avec ses numéros d'écriture, ses
  dates, la provenance au trait et sa légende, l'échelle, le nord, le
  système de coordonnées, la précision quand elle est connue, la source et
  le millésime du fond et des contours, la date d'édition.
- **Le public.** À `public = TRUE`, les localisations sensibles sont
  floutées selon les codes de sensibilité du SINP, d'après une liste de
  référence citée et versionnée, à acquérir (question ouverte).
- **L'archivage.** Le PDF est produit en PDF/A, sans réseau.

## Critères d'acceptation

*Arbitrages de Pascal, 22 octobre 2026 ; à compléter.*

- **Comptage :** le nombre d'objets dessinés est égal au nombre d'écritures
  localisées (par leur géométrie propre ou leur UG), rectifiées comprises.
- **Terrain d'épreuve :** la démo de Couchey, enrichie dans les tests d'une
  rectification, d'un relevé répété et d'un visa ; et un rendu sur
  `sommier_reconfort_orleans_test`, jamais sur la base réelle.

## Questions ouvertes

- **La liste de référence des espèces sensibles** : tranchée (décision 3,
  référentiel INPN v18). Restent :
  - *l'écart entre les sources* : à Orléans (Loiret), le fichier n'a pas de
    ligne pour le Sabot de Vénus (le Centre-Val de Loire a sa liste flore,
    la liste socle nationale ne s'applique pas), alors que l'API TAXREF rend
    un code national 1 ; à confirmer auprès du pôle SINP Centre-Val de
    Loire ;
  - *la traduction des codes en floutage* : le fichier donne des codes 1
    à 3, le guide v2.0 (2022) raisonne en surfaces ; la correspondance est
    à établir, pas à inventer ;
  - *les habitats, vestiges et arbres remarquables* : aucune liste citable
    trouvée ; leur sort à `public = TRUE` est un choix du gestionnaire, que
    le document dira tel ;
  - *la licence du référentiel* n'est pas connue et ne sera pas demandée :
    à décider si le fichier est inclus dans le paquet ou téléchargé et mis
    en cache à l'usage.
- **PDF/A avec Quarto et LaTeX : faisable, essai du 23 octobre 2026.**
  Quarto 1.8.27, TeX Live 2026, classe `scrartcl` en A4 paysage, validation
  par veraPDF (image Docker `verapdf/cli`) :
  - KOMA-Script refuse `\DocumentMetadata` (erreur fatale) ; il faut, avant
    `\documentclass`, `\RequirePackage{pdfmanagement}` puis
    `\SetKeys[document/metadata]{pdfstandard=a-2b, lang=fr-FR}`, par un
    gabarit partiel `doc-class.tex` (`template-partials`). Paquets TinyTeX
    requis : `pdfmanagement`, `latex-lab`, `colorprofiles`.
  - **Croquis par `cairo_pdf` : PASS** PDF/A-2B. **Par `pdf()` : FAIL**
    (clause 6.2.11.4.1, Helvetica non embarquée). `cairo_pdf` lève aussi
    la limite Latin-1 de `pdf()` (`gestion-anterieure.qmd:150-151`).
  - Reste à éprouver sur le vrai gabarit, avec ses tableaux longs et ses
    croquis `sf`.
- **Les objets hors UG** ou rattachés à la forêt (travaux A50H, sécheresse
  qui déborde A 35, affouage) : quel croquis ?
- **`jusqu_au_visa`** : les croquis s'arrêtent à la tête visée ; les contours
  restent ceux de l'époque de chaque écriture (décision 6).
- **Le contenu exact des imprimés A50** (A50D bis, A50J, r/a, r/c, r/s) n'est
  connu que par `specs/brief_sommier-unifie-synthese.md` : à confronter aux
  originaux.
