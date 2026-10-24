# Imprimés A50 et sommieR : confrontation

*24 octobre 2026. Lecture seule, sur le code de la 0.37.0 : les numéros de ligne datent de ce jour. L'écart b2 (l'A50F) est corrigé en 0.37.1.*

**Sources.** Les imprimés sont dans `/home/pascal/dev/sommieR/specs/A50/` (ils étaient auparavant dans `docs/A50/`). Ils ne sont pas versionnés : leurs droits de diffusion ne sont pas connus. Ils ont été rendus en PNG à 80 dpi puis lus à l'image, page par page, et recoupés avec `pdftotext -layout`. Le code confronté est `R/registres.R`, `R/registre1..9.R`, `inst/sql/002_vues.sql`, `inst/quarto/sommier.qmd` et `R/registre_imprime.R`.

**Il n'existe pas de schéma JSON.** Aucun `*.schema.json` dans le dépôt. Les constructeurs `registreN_*()` sont le schéma, revalidés par `valider_payload()` (`R/registres.R:359-394`), et versionnés par `SOMMIER_SCHEMA_VERSIONS` (`R/registres.R:121-125`).

**Conventions.**
- **[lu]** : vu sur l'image de l'imprimé.
- **[déduit]** : mon interprétation, absente de l'imprimé.
- Les citations d'imprimé reprennent la casse et l'orthographe imprimées, coquilles comprises (« SITUTATION », « procès-verval »).

---

## 1. Imprimé par imprimé

Le pied de page de chaque imprimé donne son code et son édition (par exemple « A50 K Recto (02/74) »). Toutes les pages portent en tête une mise en page datée du 23/05/2018 [lu].

### A10 — « TENUE DU SOMMIER DE LA FORET / FICHE DE CONTROLE » (10/93), recto et verso → registre 1

[lu]
- **En-tête** : « (1) FORET … de … », sur trois lignes. Renvoi (1) : « Mentionner ici, éventuellement, les noms des diverses forêts dont les sommiers sont regroupés dans le même classeur. »
- **Texte imprimé** : « Le sommier de la forêt constitue avec l'aménagement un instrument essentiel de la gestion forestière. Sa mise à jour régulière est donc obligatoire et il fait l'objet d'un visa annuel du responsable du niveau de gestion. »
- **Colonnes** :
  - « DATE (JJ/MM/AA) » ;
  - « VISA ANNUEL DU RESPONSABLE DU NIVEAU DE GESTION », en deux sous-colonnes « Nom/Qualité » et « Signature » ;
  - une seule colonne « • OBSERVATIONS • VISAS DU NIVEAU DE DIRECTION ».
- Le verso est identique, sans le texte.

### A40 — « ÉTAT GÉNÉRAL ET DE RÉPARTITION DES FRAIS DE DÉLIMITATION ET DE BORNAGE » (08/05) → registre 2

[lu]
- **Cartouche** : Niveau de Direction, Niveau de Gestion, FORÊT, DÉPARTEMENT, ARRONDISSEMENT.
- **Recto, « ÉTAT GÉNÉRAL »** : trois colonnes, « ELEMENTS DE CALCUL » (1), « A la charge du propriétaire de la forêt » (2), « A la charge des riverains » (3). Cinq rubriques :
  1. « Rémunération de l'ingénieur expert et des autres personnels de l'ONF (1) » : « … heures d'ingénieur à … l'heure », « … heures … à … l'heure », TOTAL. Renvoi (1) : « Uniquement en forêt non domaniale ». La colonne riverains est grisée.
  2. « Rémunération du technicien privé ou du cabinet spécialisé appelé à prêter son concours ». C'est un montant, pas des heures. La colonne riverains est grisée.
  3. « Rémunération des personnels employés aux opérations d'arpentage (à répartir par moitié) ».
  4. « Frais de fourniture et de mise en place des … bornes (nb) » : Fourniture … € soit … € par borne ; Transport et mise en place … ; « TOTAL x = … soit … € par borne », répartis « x/2 » et « x/2 » ; « ou éventuellement, tarif en usage : y = … », répartis « x-y/2 » et « y/2 ».
  5. « Frais de constitution et d'envoi des actes » : « Coût des significations (DT/DR, niveau de gestion, propriétaires) », « Coût global des extraits », « Frais d'envoi des extraits ».
  - Puis un TOTAL.
- **Verso, « ÉTAT DE RÉPARTITION »**, en paysage :
  1. « N° de l'article du procès-verval » ;
  2. « Noms des propriétaires riverains » ;
  3. « Adresse » ;
  4. « Développement de la limite concernant chaque riverain (en m) » ;
  - sous « FRAIS DUS PAR CHAQUE RIVERAIN » : 5. « Opérations d'arpentage », 6. « Opérations de bornage », 7. « Constitution et envoi des extraits » ;
  8. « TOTAL ».

### A50C — « CONCESSIONS - CHASSE - PECHE » (06/96) → registre 3

[lu] En-tête « FORET d ». Colonnes :
1. Numéro
2. Unités de gestion / Séries
3. Nature
4. Nom du titulaire
5. Date de départ
6. Date d'expiration
7. Observations

Le verso est identique.

### A50D — « INVENTAIRE ROUTIER » (01/74) → registre 4

[lu] En-tête « Forêt … de … Série ».
- **Colonnes sous « VOIRIE PRIVÉE FORESTIÈRE »** :
  1. « NOM SITUTATION » ;
  2. « Largeur de la chaussée (en m) » ;
  - sous « ROUTES » : 3. Revêtues, 4. Empierrées, 5. En terrain naturel, 6. Longueur cumulée ;
  - sous « PISTES » : 7. Longueur, 8. Longueur cumulée.
- **Colonnes sous « VOIRIE PUBLIQUE »** : 9. Désignation, 10. Longueur, 11. Longueur cumulée.
- **Pied** : « DENSITÉS Routes … Km/100 ha Pistes … Km/100 ha » et « NOTA : les colonnes 3 à 8 - 10 et 11 sont à remplir en km avec une décimale ».

### A50D bis — « FICHE SOMMIER DE LA FORET POUR ROUTE FORESTIERE » (03/94) → registre 4

[lu]
- **Recto** :
  - « Carte schématisée : » ;
  - « Indication des longueurs cumulées correspondant aux points de repère de la carte schématisée : 0___ ___ … » ;
  - « Route de … F.D. de … » ;
  - « CARACTERISTIQUES » : « USAGE : Exploitation ❑ DFCI ❑ Tourisme ❑ Ouverte ❑ Fermée ❑ au public » ;
  - « Profil en travers-type » ;
  - « Structure de chaussée au … (*) », avec le renvoi « (*) Date du 1er établissement de la fiche. »
- **Verso, « TRAVAUX EFFECTUES »** : Date, Emplacement, Nature, « Coût unitaire (m2, km, tonne ou unité) », « Dépense totale (F) ».

### A50E — « VOLUME ANNUEL DES PRODUITS MARTELES » (04/96) → registres 5 et 1

[lu]
- **En-tête** : « Forêt … de … Série ».
- **Cartouche** : « Groupe(s) concerné(s) », « Possibilité … /an », « Volumes comptabilisés », « Tarifs employés ».
- **Blocs par exercice**, cinq au recto et autant au verso [déduit du verso, partiellement lu]. Chaque bloc porte « Exercice : » et les colonnes :
  1. NATURE DES COUPES ;
  2. UNITES DE GESTION PARCOURUES EN COUPES ;
  - sous « Volumes martelés (m3) » : 3. Coupes, 4. Produits accidentels, 5. Total ;
  - sous « Balance de l'exercice (volumes martelés moins possibilité) » : 6. Excès (+), 7. Déficit (-).
- **Fin de bloc** : « Observations : », « TOTAL », « Balance finale ».

### A50F — « RELEVÉ DES COUPES MARTELÉES » (04/96) → registre 5

[lu] En-tête « Forêt … de … Série ». Colonnes :
1. Exercice
2. Unité de gestion ou coupon
3. Surface
4. Volume (m3)
5. Observations

### A50G — « RECETTES ET DEPENSES » (03/76) → registre 7

`pdftotext` n'en tire que 28 mots ; tout ce qui suit est lu à l'image.

- **En-tête** : « Forêt … de … Série ».
- **Huit colonnes, toutes en couples NATURE / MONTANT** :
  - **RECETTES** (1-2) : Bois vendus sur pied, Bois vendus façonnés, Bois délivrés, Chasse - Pêche, Concessions, puis deux lignes vierges ; « TOTAL Recettes ».
  - **DEPENSES TRAVAUX, « Entretien courant et renouvellement »** (3-4) : Peuplements, Infrastructure, Tourisme, Chasse - Pêche, « Frais d'exploitation en régie », une ligne vierge ; « Total dépenses Entretien ».
  - **DEPENSES TRAVAUX, « Travaux neufs »** (5-6) : Reboisement, Equipement, Tourisme, **Chasse - Pêche** ; « Total dépenses Travaux neufs ».
  - **DEPENSES AUTRES FRAIS** (7-8) : Impôts fonciers, deux lignes vierges, Frais de garderie, Honoraires ; « Total autres frais ».
- **Pied de bloc** : « TOTAL DEPENSES (Col. 4 + 6 + 8) … (Frais de personnel exclus) ».
- **Exercices** : quatre blocs « EXERCICE : » par page.

### A50H — « SOMMIER DES TRAVAUX NE S'INSCRIVANT PAS DANS UNE UNITÉ DE GESTION » (04/96) → registre 6

[lu] Colonnes :
1. Année
2. Nature des travaux et localisation
3. Quantités
4. Montant (Euros)
5. Observations

### A50J — titre catalogue « Croquis de la parcelle et travaux effectués dans l'unité de gestion » (10/95) → registre 6, et croquis

[lu]
- **Recto et verso identiques** :
  - en-tête « FORET … d … Série » ;
  - « CROQUIS DE L'UNITE DE GESTION N° … (Parcelle ou sous-parcelle) », « Echelle : », « LEGENDE » ;
  - un petit cadre vierge à droite, au-dessus du tableau, dont l'usage n'est pas imprimé [lu ; usage non déduit].
- **« TRAVAUX EFFECTUES DANS L'UNITE DE GESTION / RELEVE DES TRAVAUX EFFECTUES »** :
  1. Années ;
  2. NATURE ;
  3. Repère plan ;
  - sous « Plantation » : 4. Nbre plants, 5. Provenance ;
  6. QUANTITES ;
  7. MONTANT (facultatif) ;
  8. OBSERVATIONS % de reprise.

### A50J bis (09/95) → registre 6

[lu]
- **Recto** : identique à l'A50J.
- **Verso, « SUIVI DES JEUNES PEUPLEMENTS DE L'UNITE DE GESTION N° … »** :
  - « Groupe d'aménagement : … », « Région IFN : … » ;
  - « Surface totale de l'UG (parcelle ou sous-parcelle) », « Surface forestière utile », « Surface initiale à travailler » ;
  - une grille dont la case d'angle porte « Norme / Classe / Année », avec une quinzaine de colonnes vierges et une colonne « TOTAL » ;
  - puis le même relevé des travaux en huit colonnes qu'à l'A50J.
- La signification de « Norme » et de « Classe » n'est pas imprimée. Hypothèse [déduit] : des normes sylvicoles de dépressage ou de dégagement, et des classes de hauteur des jeunes peuplements.

### A50K — « PHENOMENES INTERESSANT LA VIE DE LA FORET » (02/74) → registre 8

[lu]
- En-tête « FORET d ».
- Ensuite, seulement des lignes réglées, sans aucune colonne, pas même une date ; le verso est identique.

### A50L — « TABLEAUX DE CHASSE PAR SAISON (du 1er avril au 31 mars) » (09/09) → registre 8

[lu]
- **Recto, « GIBIERS TUES EN FORET »** : en colonnes, dix « Années » sous « SAISON DE CHASSE ». En lignes :
  - CERF, BICHE, JEUNE CERF (1), TOTAL CERF ;
  - BROCARD, CHEVRETTE, CHEVRILLARD Mâle, CHEVRILLARD Femelle, TOTAL CHEVREUIL ;
  - DAIM, CERF SIKA, SANGLIER, CHAMOIS OU ISARD, MOUFLON ;
  - LIEVRE (2), LAPIN, PETIT TETRAS, GRAND TETRAS, FAISAN (3), PERDRIX (4), CANARD (5), BECASSE, PIGEON (6), GRIVE (7) ;
  - RENARD, BLAIREAU, MARTRE, FOUINE, PUTOIS, HERMINE, BELETTE ;
  - AUTRES GIBIERS (à préciser).
  - Renvois : (1) « Cerf mâle ou femelle de moins d'un an » ; (2) compris lièvre variable ; (3) compris faisan vénéré ; (4) toutes espèces ; (5) tous anatidés, compris sarcelles ; (6) toutes espèces, compris tourterelles ; (7) toutes espèces.
- **Verso, « TABLEAUX DE REPEUPLEMENT EN FORET DOMANIALE PAR SAISON »** :
  - « ANIMAUX VIVANTS LACHES EN FORET DOMANIALE », en deux blocs, « par l'Office » et « par le locataire » ;
  - lignes de chaque bloc : CERF, BICHE, BROCARD, CHEVRETTE, CHAMOIS OU ISARD, MOUFLON, LIEVRE, FAISAN, PERDRIX, CANARD, Autres (à préciser) ;
  - puis un cadre libre « RENSEIGNEMENTS CONCERNANT LE GIBIER ET LA CHASSE ».

### A50 r/a — « Arbre(s) remarquable(s) » (04/96) → registre 9

[lu]
- **Recto** :
  - « Forêt … de … », « Parcelle » ;
  - Appellation, Numéro(s), Essences(s), « Intérêt (âge, dimensions, port, histoire, curiosité, …) », Remarques ;
  - « Plan de situation », « Echelle : », « Légende » ;
  - tableau Date / Age / Circonf. / H.tot. / *deux colonnes à en-tête vierge* / Etat sanitaire.
- **Verso** :
  - Forêt, Parcelle, Appellation, Numéro(s) ;
  - « Travaux effectués » : Année / Nature / Montant / Observations ;
  - « Références, bibliographie ».

### A50 r/p — « Peuplement(s) remarquable(s) » (04/96) → registre 9

[lu]
- **Recto** :
  - Forêt, Parcelle, Numéro, Appellation, « Intérêt (âge, dimensions, port, histoire, curiosité, …) », Remarques ;
  - Plan de situation, Echelle, Légende ;
  - « Composition en essences » : Essence / 1/10ème ;
  - tableau Date / Age / Surface / H.dom. / s.terr. / Etat sanitaire.
- **Verso** :
  - Forêt, Parcelle, Numéro, Appellation ;
  - « Relevé du volume des produits martelés » : Année, puis six couples Nbre / Volume dont les en-têtes de groupe sont vierges, puis Observations. Ces groupes sont probablement des essences ou des catégories [déduit] ;
  - « Travaux effectués » : Année / Nature / deux colonnes vierges / Montant / Observations ;
  - « Références, bibliographie ».

### A50 r/c — « Vestige(s) et élément(s) culturel(s) remarquable(s) » (04/96), recto seul → registre 9

[lu]
- Forêt, Parcelle, Numéro, Appellation, Nature, « Remarques (intérêt, …) » ;
- Plan de situation, Echelle, Légende ;
- tableau Date / Observations ;
- « Travaux effectués » : Année / Nature / Montant / Observations ;
- « Références, bibliographie ».

### A50 r/e — « Espèce(s) protégée(s), rare(s), menacée(s) » (04/96), liste → registre 9

[lu] « Forêt … de … », sans parcelle. Colonnes : Date / Nom français / Nom latin / Localisation.

### A50 r/s — « Espèce(s) protégée(s), rare(s), menacée(s) » (04/96), fiche → registre 9

[lu]
- Forêt, Parcelle, Nom français, Nom latin, « Remarques (statut prot., intérêt, …) » ;
- Plan de situation, Echelle, Légende ;
- tableau Date / Observations ;
- « Références, bibliographie ».
- Pas de cadre de travaux.

### A50 r/h — « Milieux et habitats naturels remarquables » (04/96) → registre 9

[lu] « Forêt … de … », sans parcelle. Colonnes : Type d'habitat naturel / Surface / Localisation / Observations.

### Pièces secondaires (titres lus)

- **CD7 (01-04)** : « RELEVE DE TRAVAUX » du personnel (heures, tâches, salaire brut).
- **D01 (06/04)** : « PROPOSITION D'ASSIETTE DE COUPES NON REGLEES ».
- **D1.12 (01-14)** : « Titre de Recette » et procès-verbal de dénombrement, ventes à l'unité de produit.
- **D1.23 (01-11)** : « MESURES DE PROTECTION D'UNE COUPE », convocation ou ordre de suspension. Absente de la synthèse.
- **D11 (10/95)** : « Fiche de martelage ». Elle porte une rubrique « Proro. tarif », ce qui conforte la lecture de « Tarifs employés » de l'A50E comme des tarifs de cubage [déduit].
- **Catalogue xlsx** : il confirme l'A50I « Volumes marqués dans l'unité de gestion », sans PDF fourni. Il liste aussi une série A50-1 à A50-4 bis (bilans matière et argent des travaux) et un « A 50 g Recettes et dépenses RTM », absents de la synthèse.
- **Devis** : classeurs 23 anneaux, sans contenu de rubriques.

---

## 2. Écarts

### (a) Rubriques de l'imprimé absentes du payload ou du rendu

| # | Imprimé | Rubrique absente | Où dans le code |
|---|---|---|---|
| a1 | A50E | « Volumes comptabilisés » et « Tarifs employés ». Ni le payload de coupe ni l'aménagement ne disent quel volume est compté ni avec quel tarif. `nature_volume` dit autre chose : possibilité fixée ou récolte prévue. | `R/registres.R:165-187` ; `inst/sql/002_vues.sql:117-122` |
| a2 | A50E et autres | « Série », en tête de l'A50D, E, F, G, H et J. Les entrées n'en portent pas : la série vit sur l'UG (`R/db.R:113-133`) et en texte dans l'aménagement. La balance A50E est par série sur papier, par aménagement dans sommieR. | `inst/sql/002_vues.sql:117, 205-240` |
| a3 | A40 recto | Rubrique 5, « Frais de constitution et d'envoi des actes » (significations, extraits, envoi). Détail de la rubrique 4 : fourniture, transport et pose, prix par borne, « tarif en usage y ». Taux horaires de la rubrique 1. Seuls subsistent `heures_ingenieur`, `heures_technicien`, `arpentage_eur`, `nb_bornes`, `cout_total_eur` et les deux parts. | `R/registre2.R:148-160, 219-237` |
| a4 | A40 verso | Tout l'« État de répartition » par riverain : n° d'article du PV, nom, adresse, développement de limite (m), frais d'arpentage, de bornage et d'extraits, total. Le payload n'a qu'un `charge_riverains_eur` agrégé. | `R/registre2.R:155-156, 233-235` |
| a5 | A50D bis verso | « TRAVAUX EFFECTUES » de la route : date, emplacement, nature, coût unitaire, dépense totale. Rien ne relie une entrée de travaux, au registre 6 (code `DS`), à la route du registre 4 : pas d'identifiant d'infrastructure dans `registre6_travaux`. | `R/registre4.R:56-85` ; `R/registres.R:259-339` |
| a6 | A50D bis | « Profil en travers-type ». « Indication des longueurs cumulées correspondant aux points de repère ». « Route de … F.D. de … ». La géométrie remplace en partie la carte schématisée [déduit]. | `R/registre4.R:56-85` |
| a7 | A50J bis verso | « Groupe d'aménagement », « Région IFN », « Surface totale de l'UG », « Surface forestière utile », « Surface initiale à travailler », grille « Norme × Classe × Année ». Placettes et contrôles (`registre6_placette`, `registre6_controle`) la remplacent sans la transcrire : une fiche papier ne peut pas être reprise telle quelle. | `R/registre6.R:101-186` |
| a8 | A50L verso | Les « TABLEAUX DE REPEUPLEMENT » (lâchers par l'Office et par le locataire) et le cadre « RENSEIGNEMENTS CONCERNANT LE GIBIER ET LA CHASSE ». Aucun type d'entrée n'existe pour un lâcher. | `R/registre8.R:16-18, 106-124` |
| a9 | A50L | La liste d'espèces et de catégories est imprimée et fermée : CERF/BICHE/JEUNE CERF, BROCARD/CHEVRETTE/CHEVRILLARD M/F, etc. Dans sommieR, `espece` et `classe_age` sont du texte libre. La matrice ne se reconstitue pas de façon fiable entre saisisseurs. | `R/registre8.R:113-119` |
| a10 | r/a | Numéro(s), Remarques, verso « Travaux effectués » (Année/Nature/Montant/Observations), « Références, bibliographie », et les deux colonnes de mesure libres. | `R/registre9.R:49-72` |
| a11 | r/p | « Etat sanitaire » est une colonne des mesures datées, mais `registre9_peuplement` n'en a pas. Manquent aussi Numéro, Remarques, le verso « Relevé du volume des produits martelés » (Année × six couples Nbre/Volume), « Travaux effectués » et la bibliographie. | `R/registre9.R:102-140` |
| a12 | r/c | Numéro. « Travaux effectués » est un tableau à quatre colonnes sur l'imprimé, une simple chaîne `travaux_effectues` dans le payload. | `R/registre9.R:159-177` |
| a13 | r/s | « Remarques (statut prot., intérêt, …) » : seul `statut_protection` en est retenu, sans champ pour la remarque d'intérêt. Minime. | `R/registre9.R:214-244` |
| a14 | A50D | « SITUATION », dans la colonne 1 « NOM SITUTATION » : pas de champ de localisation en clair pour la voirie. Les « longueurs cumulées » sont calculables. | `R/registre4.R:56-85` |
| a15 | A10 | Le renvoi (1), « diverses forêts dont les sommiers sont regroupés dans le même classeur ». Une chaîne vaut une forêt, et rien ne dit le regroupement. Sans conséquence probante. | `R/registre_imprime.R:446-480` |
| a16 | A10, rendu | Le tableau « Visas par exercice » ne montre pas les observations du visa (colonne « OBSERVATIONS » de l'A10). Elles restent dans le tableau générique du registre 1. | `inst/quarto/sommier.qmd:258-279` |
| a17 | Rendu, toutes fiches | Le rendu du registre est un journal chronologique par registre : un tableau à colonnes fixes, avec tout le payload aplati dans « Écriture ». Il ne reprend la mise en page d'aucun imprimé : pas de bloc par exercice comme à l'A50E, pas de matrice comme à l'A50L, pas de totaux par colonne comme à l'A50G, pas de densités comme à l'A50D. Balance et cartes sont dans `gestion-anterieure.qmd:1087-1190`, pas dans `sommier.qmd`. | `inst/quarto/sommier.qmd:296-318` |
| a18 | Rendu | Champs imprimés sur la fiche sans libellé en français : `age_ans`, `hauteur_dominante_m`, `surface_terriere_m2ha`, `composition`, `remarques`, `bibliographie`, `travaux_effectues`, `usage`, `ouverte_public`, `largeur_chaussee_m`, `structure_chaussee`, `heures_*`, `charge_*`, `espece`, `nombre`, `classe_age`, `sexe`… Ils sortent sous leur nom de code. Le commentaire « dans l'ordre de l'imprimé » est inexact : l'ordre est celui d'un vecteur global. À l'A50J, par exemple, la quantité passe avant les plants, et le numéro de l'A50C vient après la nature. | `inst/quarto/sommier.qmd:42-73, 103-104` |

### (b) Ce que la synthèse affirme et que l'original contredit

Les citations renvoient à `specs/brief_sommier-unifie-synthese.md:<ligne>`.

| # | Synthèse | Original | Reprise dans le code |
|---|---|---|---|
| b1 | **:29**, A50G : « travaux neufs (reboisement, équipement, tourisme) » | [lu] Les travaux neufs comptent une 4e ligne, « Chasse - Pêche ». Le pied dit « (Frais de personnel exclus) ». Le bloc d'entretien s'intitule « Entretien courant et renouvellement ». | `SOMMIER_POSTES_COMPTABLES` n'a que trois postes de travaux neufs (`reboisement`, `equipement`, `tourisme_neuf`) et pas de poste « chasse-pêche neuf » (`R/registre7.R:36, 46-47`). Aucune règle n'exclut les frais de personnel (`R/registre7.R:114-151` ; `inst/sql/002_vues.sql:593+`). |
| b2 | **:38** dit juste : A50F « Relevé des coupes martelées ». | Le code, lui, fait de l'A50F le relevé de la coupe **exploitée**. Sur l'imprimé, A50E et A50F relèvent tous deux des martelages, l'un par exercice et l'autre par UG [lu : titres]. | `R/registres.R:69-70` (« `coupe_realisee` : relevé de la coupe effectivement exploitée (imprimé A50F) ») ; `R/registres.R:80-83` et `inst/sql/002_vues.sql:214-216` (« martelée (A50E) puis exploitée (A50F) ») ; `R/carte.R:74, 146`. Le type `coupe_realisee` n'a pas d'imprimé source. Un A50F repris de papier sous ce type sortirait de la balance alors que ce sont des volumes martelés. |
| b3 | **:24**, A40 : « heures ingénieur/technicien » | [lu] Seuls les personnels de l'ONF sont comptés en heures, et la rubrique 1 vaut « uniquement en forêt non domaniale ». Le technicien privé ou le cabinet est une rémunération en montant (rubrique 2). | `heures_technicien` (`R/registre2.R:98, 224-225`) n'a pas de colonne d'origine, et le montant du technicien privé n'a pas de champ. |
| b4 | **:27**, A50D bis : « structure de chaussée datée » | [lu] « Structure de chaussée au … (*) — Date du 1er établissement de la fiche ». La date est celle de l'état constaté à l'ouverture de la fiche, pas celle des travaux. | `date_structure` est documenté comme « Date de réalisation de la structure » (`R/registre4.R:39, 80-81`). |
| b5 | **:27**, A50D bis : « usage (exploitation / DFCI / tourisme …) » | [lu] Trois cases à cocher distinctes, cumulables [déduit de la mise en page]. | `usage` est un choix unique, avec un `mixte` qui perd la combinaison (`R/registre4.R:7, 74-75`). |
| b6 | **:13** : « chaque imprimé est un tableau à lignes datées » | [lu] L'A50K n'a ni colonne ni date. L'A40 n'a pas de date. L'A50L est une matrice par saison. L'A50D bis et les fiches r/* ont une partie d'identité non datée. | Sans conséquence sur le code, qui date chaque entrée (`date_evenement`). Le principe est juste, sa justification par les imprimés est inexacte. |
| b7 | **:31**, A50K : « Journal … : tempêtes, incendies, crises sanitaires, gel » | [lu] L'imprimé n'énumère rien : c'est une feuille réglée. | La nomenclature fermée `SOMMIER_NATURES_PHENOMENE` (`R/registre8.R:22-25`) est un ajout, pas une transposition. Voir c5. |
| b8 | **:47**, r/a : « Appellation, essence, intérêt … + plan + mesures datées » | [lu] S'y ajoutent Numéro(s), Remarques, Parcelle, deux colonnes de mesure libres, le verso « Travaux effectués » et la bibliographie. | Voir a10. |
| b9 | **:48**, r/p : « Idem + … mesures datées (âge, surface, H.dom, surface terrière) + relevé des volumes martelés au verso » | [lu] « Idem » est faux pour l'essence : le r/p n'a pas de champ Essence(s), il a la composition. Les mesures datées comptent aussi « Etat sanitaire ». Le verso porte aussi « Travaux effectués » et la bibliographie. | Voir a11. |
| b10 | **:51**, r/s : « Nom, statut de protection … » | [lu] Le statut n'est pas une rubrique : il est un exemple de « Remarques (statut prot., intérêt, …) ». Il y a Nom français et Nom latin, et une Parcelle. | Voir a13. |
| b11 | **:49**, r/c | [lu] Omet Numéro, Appellation et Parcelle. Le reste est juste. | — |
| b12 | **:32**, A50L | [lu] Omet tout le verso (repeuplement et renseignements). « Prédateurs » n'est pas une rubrique : l'imprimé liste renard, blaireau, martre, fouine, putois, hermine, belette. | Voir a8 et a9. |
| b13 | **:28**, A50E : « Par exercice : possibilité (m³/an) » | [lu] La possibilité est au cartouche de la feuille, une fois, pas par exercice. Le cartouche porte aussi « Groupe(s) concerné(s) », « Volumes comptabilisés » et « Tarifs employés », omis. | Voir a1. |
| b14 | **:81** : « L'imprimé A50G le prévoit déjà (colonne « bois délivrés ») » | [lu] C'est une ligne de la colonne NATURE des recettes, pas une colonne. Bénin. | Repris dans `R/registres.R:67-68` (« colonne "bois delivres" »). |
| b15 | **:14** : « Trois échelles d'ancrage : la forêt (ou série), l'UG, l'objet remarquable » | [lu] Les fiches r/a, r/p, r/c et r/s portent une case « Parcelle » : l'objet remarquable est lui-même rattaché à une parcelle. Les listes r/e et r/h sont à l'échelle de la forêt. | Conforme au `mixte` du registre 9 (`R/registres.R:45-48`). |
| b16 | **:56**, pièces sources | [lu] D1.23 (mesures de protection d'une coupe) est fournie mais non citée. Le catalogue liste aussi A50-1 à A50-4 bis (bilans matière et argent des travaux) et un A50g RTM. | — |

Points où la synthèse est **confirmée** par l'original : A10 (:23), A50C (:25), A50D (:26), A50H (:30), A50F (:38), A50J (:40), A50J bis (:41, grille « norme × classe × année »), r/e (:50), r/h (:52), et la datation de la série (:249 : éditions 01/74 à 09/09, mises en page 2018).

### (c) Ce que sommieR ajoute (normal, noté pour mémoire)

- **Registre 1** : les types `arrete`, `deliberation`, `agrement`, `avenant` et `engagement_fiscal`, et le bloc `amenagement` (`R/registre1.R:29-32, 103`). La signature de l'A10 devient un JWS dans la table `visa` (`R/registre1.R:42-46`). `visa_direction` est un acte distinct ; sur l'A10, il partage la colonne des observations.
- **Registre 2** : la reconnaissance de limite, avec ses états par forme, l'élément PCI, le GNSS et les photos (`R/registre2.R:15-77, 162-170`). Les mouvements de propriété, la servitude et l'application du régime forestier (`R/registre2.R:15-18`).
- **Registre 3** : `redevance_eur`, `surface_ha`, et le sous-registre de l'affouage (`R/registre3.R:117-136`). L'A50C n'a pas de colonne de redevance.
- **Registre 4** : `equipement` et `ouvrage_dfci` (`R/registre4.R:123-151`) ; `voirie_publique` est un booléen sur le tronçon.
- **Registre 5** : `essence`, la géométrie, `constat_id`, `bois_delivre` comme type, et `coupe_realisee` (voir b2) (`R/registres.R:165-187`).
- **Registre 6** : le code fermé `SOMMIER_CODES_TRAVAUX` ; `prevu` et `motif_ecart`, `execution`, `intervenant`, `date_reception` ; placettes et contrôles (`R/registre6.R:16-186` ; `R/registres.R:259-339`).
- **Registre 7** : les postes `subventions`, `autres_produits` et `autres_frais` ; `tiers`, `reference`, `dispositif_fiscal` (`R/registre7.R:30-69`).
- **Registre 8** : la nomenclature des phénomènes, `equilibre_gibier`, `detection`, et `attribue` (plan de chasse) (`R/registre8.R:16-25, 121, 152-172`).
- **Registre 9** : `effectif`, `cd_nom` (TAXREF), `code_natura2000` et `etat_conservation` (`R/registre9.R:222-244, 262-282`).
- **Transversal** : NDP, `reprise`, la chaîne de hash, les géométries en WGS84, et les croquis avec barre d'échelle et légende de provenance (`inst/quarto/sommier.qmd:336-395`). Ces croquis transposent fidèlement le « Echelle / Légende » de l'A50J et des fiches r/*.

---

## 3. Écarts qui comptent, par priorité

Ce sont les écarts qui touchent la valeur probante, ou ce qu'un successeur peut reprendre et relire.

1. **A50F mal identifié (b2).** Le code et la vue de balance attribuent à l'A50F des volumes exploités, alors que l'imprimé relève des coupes **martelées** par UG. Il y a risque d'erreur de reprise : un A50F papier saisi en `coupe_realisee` sortirait de la balance ; saisi aussi en `martelage` à côté de l'A50E, il doublerait le prélèvement. C'est à corriger d'abord dans la documentation (`R/registres.R:69-70, 80-83` ; `inst/sql/002_vues.sql:214-216`). Il faut aussi décider ce qu'est `coupe_realisee`.
2. **Volumes comptabilisés et tarifs (a1, b13).** Une balance de possibilité n'est comparable d'un aménagement ou d'un gestionnaire à l'autre que si l'on sait quel volume et quel tarif sont comptés. L'imprimé l'exige en cartouche ; sommieR ne le chaîne nulle part.
3. **Série (a2).** L'A50E tient sa balance par série. sommieR la tient par aménagement, et les entrées ne portent pas la série. Une forêt à plusieurs séries ne se relit pas comme son classeur.
4. **A50G, travaux neufs chasse-pêche et frais de personnel exclus (b1).** Il manque un poste, et la règle d'exclusion des frais de personnel n'est pas posée. Les totaux du registre 7 ne sont donc pas ceux de l'A50G : la comparaison avec un classeur repris est faussée.
5. **A40 verso, répartition par riverain (a4), et rubrique 5 (a3).** C'est la pièce opposable aux riverains, qui fonde ce que chacun doit. Un total agrégé ne la remplace pas en contentieux.
6. **Lien entre une route et ses travaux (a5)**, et **date de la structure de chaussée mal définie (b4)** : un successeur ne retrouve pas l'historique d'une route.
7. **Repeuplements A50L (a8)** et **espèces et catégories en texte libre (a9)** : la matrice de chasse n'est ni complète ni reconstituable sans ambiguïté.
8. **Fiches r/a et r/p incomplètes (a10, a11)** : l'état sanitaire du peuplement, le numéro, les travaux, la bibliographie et les martelages au verso du r/p manquent. Une fiche papier existante ne se reprend pas entière.
9. **Suivi des jeunes peuplements de l'A50J bis (a7)** : il est remplacé par un dispositif différent, les placettes, sans voie de reprise de la grille papier.

**Cosmétique, sans enjeu probant** :
- les libellés manquants et l'ordre des champs au rendu (a18) ;
- le rendu en journal plutôt qu'à la mise en page des imprimés (a17) ;
- les observations du visa absentes du tableau A10 (a16) ;
- `usage` en choix unique (b5) ;
- « colonne bois délivrés » (b14) ;
- le regroupement de forêts dans un classeur (a15) ;
- l'unité des longueurs : en km à une décimale sur l'A50D, en mètres dans sommieR ;
- « Remarques » du r/s (a13) ;
- les pièces secondaires non citées (b16).
