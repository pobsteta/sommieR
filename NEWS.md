# sommieR 0.8.0

Lot 4 : le PCI vecteur. Les bornes et les détails topographiques que les
livraisons GeoJSON écartent, cherchés là où ils se trouvent.

## Ce que le lot 3 avait conclu trop vite

Le lot 3 concluait que bornes et fossés n'étaient pas dans le cadastre. Vrai
des livraisons d'Etalab, qui sont une **version simplifiée** du plan : le
retraitement ne conserve que parcelles, bâtiments, sections, feuilles,
lieux-dits et subdivisions fiscales. Les détails topographiques existent
pourtant, dans le PCI vecteur brut au format EDIGÉO publié feuille par feuille
par la DGFiP sur le même site.

Vérifié sur la feuille `212000000A01` de Couchey : `BORNE_id` (12 points),
`TLINE_id` (50 lignes, attribut `SYM`), `ZONCOMMUNI_id`, `PARCELLE_id`,
`SECTION_id`, `SUBDSECT_id`, `LIEUDIT_id`, `COMMUNE_id`.

## Ce que le paquet apporte

* `sommier_feuilles_pci()` rend les feuilles de la commune avec leur emprise et
  retient celles qui touchent la forêt. **Couchey en compte dix-sept, une forêt
  en touche deux** : charger toute la commune serait payer huit fois le
  nécessaire. Les feuilles se choisissent sur la couche légère d'Etalab, dont
  les identifiants correspondent exactement aux noms des archives EDIGÉO.
* `sommier_fond_pci()` télécharge et décompresse les archives retenues ;
  `sommier_fond_pci_lire()` en lit une couche, restreinte à l'emprise.

## Deux refus

* **La nature d'un détail n'est pas devinée.** EDIGÉO décrit sa structure, et
  GDAL s'en sert pour bâtir les couches et leurs champs — c'est ainsi qu'on
  obtient `SYM` sans lire le `.DIC` soi-même. Mais la structure n'est pas la
  sémantique : sur la feuille examinée, toutes les définitions du `.DIC` sont
  vides et aucune section n'énumère les valeurs. `SYM` distingue mur, fossé,
  haie et clôture ; sa nomenclature appartient à la symbolisation du plan,
  publiée ailleurs. Le code est
  donc rendu brut, et une table de correspondance peut être **fournie par
  l'appelant**. Aucune n'est embarquée tant qu'une source n'est pas citable :
  une correspondance plausible mais fausse ferait dire au document « fossé » là
  où le terrain montre un mur.
* **La projection vient de ce que le lot déclare.** EDIGÉO est
  auto-descripteur : son fichier `.GEO` porte le référentiel employé
  (`LAMB93`, ou `CC42` à `CC50` pour les livraisons `edigeo-cc`). Le pilote,
  lui, rend un proj4 sans code EPSG. On lit donc la déclaration à la source, et
  la sortie est ramenée en Lambert-93 quelle que soit la livraison — les lots
  en conique conforme sont donc lisibles, non refusés. Un référentiel absent ou
  inconnu est signalé plutôt que deviné : reprojeter au hasard poserait la
  feuille à côté de la forêt, exactement le défaut corrigé en v0.6.0.

## Et toujours : un décor

Rien du PCI n'entre dans un registre, une empreinte ou un manifeste. Une borne
relevée par la DGFiP est la donnée d'un tiers ; le bornage qui fait foi est
celui du gestionnaire, porté au registre 2 avec sa géométrie depuis la v0.7.0.
Les bornes s'affichent en surimpression sur la carte de la desserte, en croix
brunes, avec la mention qui le dit.

# sommieR 0.7.0

Les lots 2 et 3 des briefs de cartographie. La géométrie entre dans les
payloads — donc dans l'empreinte — et le cadastre prend sa place de décor.

## La géométrie est un constat, pas un attribut d'affichage

* Dix constructeurs de payload acceptent une `geometrie` : registres 2
  (bornes, limites), 4 (voirie, équipements), 5 (emprises de coupe), 8
  (phénomènes) et 9 (patrimoine remarquable). Elle se construit avec
  `geom_point()`, `geom_ligne()` ou `geom_polygone()`.
* **Elle est dans le payload, donc dans la chaîne.** Le contour d'une coupe
  devient aussi opposable que son volume, la position d'une borne aussi
  opposable que la date de son implantation. C'est tout l'objet du lot : la
  géométrie n'est pas rangée à côté du registre, elle est dedans.
* **WGS84 sans exception**, comme l'exige la RFC 7946 : un payload doit
  s'interpréter sans contexte extérieur. Des coordonnées projetées passées
  telles quelles sont refusées à la saisie, avec la mention du cas le plus
  probable — du Lambert-93 pris pour des degrés.
* **Arrondi à sept décimales**, soit le centimètre. Aucun instrument de
  terrain ne fait mieux, et deux saisies du même point doivent produire les
  mêmes octets sans quoi le chaînage cesse d'être reproductible. Arrondir
  n'est pas simplifier : aucun sommet n'est retiré.
* La géométrie reste **facultative**. Un gestionnaire sans relevé continue de
  saisir sans, et son sommier reste conforme ; la rendre obligatoire fermerait
  le registre à ceux qu'il doit servir.
* Le type est contraint par la nature de l'objet : un arbre est un point, une
  voirie une ligne, un habitat un polygone. Accepter n'importe quoi ferait de
  la vérification une politesse.

## Premier changement de schéma du projet

* `003_geometrie.sql` ajoute à `entree_sommier` une colonne `geom` **dérivée**
  du payload, posée par déclencheur et reprojetée en Lambert-93, avec son
  index GIST. Le calcul appartient à la base et non à l'application : une
  entrée écrite par un autre client doit porter la même géométrie dérivée.
* La colonne est **hors empreinte** et entièrement reconstructible. Si elle
  diverge du payload, c'est le payload qui fait foi — la colonne se
  reconstruit, l'empreinte non.
* Les registres 2, 4, 5, 8 et 9 passent en version de schéma `1.1.0`. Les
  entrées antérieures gardent la leur et restent valides : le registre est
  append-only, un changement de schéma ne se rétrofitte pas.
* `v_objet_localise` rassemble les entrées localisées, tous registres
  confondus. `sommier_objets_localises()` les lit ; `sommier_exporter_sig()`
  gagne une couche `objets`.

## Le cadastre est un décor, jamais une écriture

* `sommier_fond_cadastral()` télécharge et met en cache une couche communale ;
  `sommier_fond_lire()` la restreint à l'emprise de la forêt.
* **Rien n'entre dans le registre** : ni entrée, ni empreinte, ni manifeste.
  Verser le cadastre dans le sommier ferait passer la donnée d'un tiers pour
  un constat du gestionnaire.
* **Rien ne se télécharge tout seul** : `sommier_rapport_quarto()` reçoit le
  fond en argument. Un document de gestion doit pouvoir s'engendrer hors
  ligne, et le même rapport rejoué plus tard ne doit pas changer de fond sans
  le dire. Le millésime est conservé avec le fichier et affiché sous la carte.
* **Ce que ces livraisons ne portent pas.** Vérification faite avant d'écrire
  une ligne : le GeoJSON communal expose parcelles, sections, bâtiments et
  lieux-dits — ni bornes ni fossés. Ceux-là sont dans la forme EDIGEO du Plan
  Cadastral Informatisé, publiée sur le même site sous `dgfip-pci-vecteur`,
  par feuille et dans un format demandant le pilote EDIGEO de GDAL : hors de
  portée de ce paquet aujourd'hui, non hors d'atteinte. Et de toute façon, une
  borne relevée par la DGFiP reste la donnée d'un tiers — ce qui fait foi,
  c'est le constat du gestionnaire, registres 2 et 4, chaîné avec le reste.

## Cartes et démonstration

* Le rapport gagne trois cartes d'objets : emprises des phénomènes (chapitre
  4), patrimoine remarquable localisé (7), voirie et limites (8). Les emprises
  sont translucides — une sécheresse englobe le chablis qu'elle a précédé, et
  un aplat opaque en cacherait une.
* Un sujet revisité n'est dessiné qu'une fois, à son dernier relevé : la
  chaîne garde tout, la carte montre l'état.
* Le jeu de démonstration porte treize écritures localisées. Les coordonnées
  sont inventées comme le reste des écritures.

# sommieR 0.6.0

Le rapport de gestion antérieure était entièrement tabulaire, alors que le
sommier sait déjà **où** les choses se passent : chaque entrée porte un
`ug_uuid`, chaque unité de gestion un contour daté. Cette version le porte sur
une carte, sans rien changer au modèle de données ni à la chaîne.

Trois briefs déposés dans `specs/` cadrent la suite : ce lot, la géométrie
dans les payloads — qui la ferait entrer dans l'empreinte, et rendrait le
contour d'une coupe aussi opposable que son volume — et le fond cadastral.

## Ce que le sommier sait porter sur une carte

* `sommier_geometrie_ug()` rend le contour **en vigueur à une date**, en WKT et
  en Lambert-93. La date n'est pas un ornement : `ug_geometrie` est versionnée,
  et une carte qui accompagne un bilan de période doit montrer le parcellaire
  de l'époque, non celui du jour de l'édition. `sommier_couche_ug()` prend donc
  par défaut la borne de fin de la période, et non aujourd'hui.
* `sommier_indicateurs_ug()` agrège par unité ce qui se cartographie : entrées,
  volume martelé, surface coupée, montant de travaux. Le volume martelé exclut
  `coupe_realisee`, comme la balance de possibilité — la même coupe martelée
  puis exploitée doublerait le prélèvement.
* `sommier_couche_ug()` joint les deux et porte en attribut les unités sans
  contour connu.

## Trois cartes dans le rapport, pas une de plus

* Chapitre 1 le parcellaire, chapitre 2 les volumes martelés, chapitre 3 les
  montants de travaux. Les chapitres 1.1, 2.1, 5 et 9 n'ont rien de spatial :
  une carte décorative dans un document réglementaire coûte la confiance
  qu'elle prétend gagner.
* Une **unité sans contour** est nommée sous la première carte plutôt
  qu'escamotée — sinon le document laisserait croire la forêt entièrement
  cartographiée.
* Une **unité sans écriture** se teinte à zéro plutôt que de disparaître : là
  où rien n'a été fait n'est pas là où l'on ne sait pas.
* Les **travaux hors unité de gestion** (imprimé A50H) ne figurent sur aucune
  carte, faute de se localiser.
* La géométrie voyage en WKT dans le RDS du rapport : le document n'exige donc
  pas `sf` pour être relu. Sans `sf` ou sans contour, il s'engendre quand même,
  avec la mention correspondante.

## Site

* Deux articles : « Gestion antérieure : du registre au document », qui déroule
  les données, et « Le document engendré », qui encadre la sortie même de
  `sommier_rapport_quarto()`.

## Correction

* `sommier_exporter_sig(format = "geojson")` écrivait des coordonnées en
  Lambert-93 sans déclaration de projection, là où la RFC 7946 impose le WGS84
  et où tout lecteur le suppose : le fichier s'ouvrait sans erreur et posait la
  forêt à des milliers de kilomètres. L'export reprojette désormais à
  l'émission ; le GeoPackage, qui porte son système, reste en EPSG:2154.

# sommieR 0.5.0

Priorité 5 du brief : les exports. Le sommier devient la source des documents
réglementaires plutôt qu'un registre à recopier.

## Gestion antérieure, trois référentiels, un seul assemblage

* `sommier_gestion_anterieure()` rassemble sur une période les coupes, la
  balance de possibilité, les travaux, les évènements, et selon le référentiel
  le bilan financier, l'équilibre forêt-gibier et le patrimoine remarquable.
* Le brief le pose : *« les trois se génèrent depuis les mêmes registres »*.
  Il y a donc **un assemblage et trois présentations** — `psg` (bloc 3 de
  l'arrêté de 2012), `amenagement` (partie 2 du document ONF) et `ct88`
  (étape 5) — plutôt que trois extractions parallèles qui divergeraient à la
  première évolution.
* Chaque référentiel ne reçoit que ce qu'il demande. Le PSG n'emporte pas le
  détail financier, que le propriétaire n'a pas à produire au CRPF ; le CT88,
  tourné vers l'évaluation d'un contrat, n'emporte pas l'inventaire du
  patrimoine. Restreindre la sortie évite de diffuser plus que nécessaire —
  les registres 3 et 7 portent des données personnelles.
* Le patrimoine remarquable n'est **pas** borné par la période : c'est un état
  courant, et le borner écarterait un arbre inventorié plus tôt alors que le
  document veut l'inventaire tel qu'il est.
* `sommier_rapport_markdown()` met le tout en forme. Du Markdown, pas un
  formulaire officiel : la mise en page réglementaire appartient à l'outil de
  rédaction, et la reproduire ici la figerait sur une version des textes.

## Export cartographique

* `sommier_exporter_sig()` exporte les unités de gestion et leur géométrie en
  vigueur à une date, enrichies du nombre d'entrées qui s'y rattachent.
* Deux formats : `geojson`, qui n'exige rien de plus que PostGIS et que le
  destinataire ouvre sans rien installer, et `gpkg` via `sf`.
* Une unité sans géométrie connue est **omise de la couche mais signalée** :
  la faire figurer sans contour créerait une entité fantôme, l'omettre en
  silence laisserait croire la forêt entièrement cartographiée. Un GeoPackage
  qui ne contiendrait aucune unité est refusé plutôt qu'écrit vide — un
  fichier SIG sans couche est plus difficile à diagnostiquer qu'une erreur.
* La conversion vers `sf` passe par le WKT et non par le GeoJSON :
  `st_as_sfc()` a une méthode caractère pour le WKT, là où lire une géométrie
  GeoJSON nue dépendrait du pilote GDAL et de sa tolérance aux fragments sans
  enveloppe `Feature`.

# sommieR 0.4.0

Priorité 4 du brief : les quatre registres restants. **Les neuf registres du
sommier unifié sont désormais ouverts à l'écriture.**

## Registres 2, 3, 4 et 9

* Registre 2 — foncier et limites (`registre2_foncier()`, imprimé A40) :
  délimitation, bornage, application ou distraction du régime forestier,
  acquisitions, servitudes. La répartition du coût entre propriétaire et
  riverains est vérifiée quand les trois montants sont donnés — une
  répartition qui ne totalise pas le coût est une erreur de saisie.
* Registre 3 — droits et concessions (`registre3_droit()`, imprimé A50C) et
  l'affouage, propre à la forêt communale (`registre3_affouage()` : rôle,
  garants, taxe, mode de partage). Une expiration antérieure au départ est
  refusée : le droit n'aurait jamais existé.
* Registre 4 — infrastructures (`registre4_voirie()`, `registre4_equipement()`,
  imprimés A50D et A50D bis), ouvrages DFCI compris.
* Registre 9 — patrimoine remarquable, les cinq types de fiche de la série
  A50 r/* : arbre, peuplement, vestige, espèce protégée, habitat. La
  composition d'un peuplement doit sommer à 10, l'imprimé l'exprimant en
  dixièmes.
* Un sujet revisité donne une entrée de plus portant la même appellation : la
  série de mesures se reconstitue par requête, rien n'est écrasé.

## Échelles d'ancrage révisées

Les registres 2, 3 et 9 passent de `foret` ou `ug` à `mixte`, d'après les
imprimés eux-mêmes : l'A50C porte une colonne « unités de gestion / séries »,
une servitude vise des parcelles identifiées, et une liste d'espèces protégées
peut couvrir la forêt entière. Le registre 4 reste à l'échelle de la forêt —
une route traverse plusieurs unités, l'y rattacher serait arbitraire.

## Vues et analyses

* `sommier_densite_voirie()` / `v_densite_voirie` : longueurs et densités en
  km pour 100 ha (imprimé A50D). Seule la voirie **privée** compte — une
  départementale traversant la forêt ne dit rien de sa desserte. La densité
  vaut `NA` sans surface connue plutôt que d'être inventée.
* `sommier_elements_ibp()` rassemble ce que le registre 9 fournit à l'Indice
  de Biodiversité Potentielle : arbres à microhabitats, bois mort sur pied,
  très gros bois, milieux ouverts, espèces protégées. **La fonction ne cote pas
  l'IBP et ne le prétend pas** — un facteur se cote sur placette selon un
  protocole de terrain, pas par comptage d'un registre qui n'inventorie que le
  remarquable. Rendre une note serait plus vendeur et faux.
* `v_droit_en_vigueur` écarte les droits expirés sans les sortir du registre.
* `v_droit` n'expose ni `titulaire` ni `garants`, `v_foncier` ni `v_remarquable`
  aucune donnée nominative superflue : même règle qu'au registre 7.

# sommieR 0.3.0

Priorité 3 du brief : comptabilité et bilan financier.

## Registre 7 — comptabilité (imprimé A50G)

* `registre7_ecriture()` enregistre une recette ou une dépense.
  `SOMMIER_POSTES_COMPTABLES` porte la nomenclature des 19 postes, répartis
  dans les quatre blocs de l'imprimé : produits, travaux d'entretien, travaux
  neufs, autres frais.
* **Le sens et la rubrique se déduisent du poste**, ils ne se saisissent pas :
  ils ne peuvent donc pas le contredire. Et `montant_eur` est toujours positif
  — porter le sens dans le signe est la source classique des doubles
  négations, où une dépense saisie à `-500` sur un poste débiteur redevient
  silencieusement une recette.
* `dispositif_fiscal` rattache une écriture à un dispositif de la forêt privée
  (DEFI, Monichon, IFI).

## Budget prévisionnel

* `budget_definir()` fixe ou révise le montant prévu d'un poste.
* **Le prévisionnel n'est pas une entrée de sommier.** Le brief l'interdit :
  « le programme prévisionnel appartient à l'aménagement ou au PSG ; le
  sommier n'enregistre que le réalisé et le constaté ». Il vit donc dans sa
  propre table, à côté de la possibilité annuelle, et il est **mutable** — un
  budget se révise, et cette révision n'a pas à être opposable. Ce qui doit
  l'être, c'est le réalisé, qui lui est dans la chaîne.

## Vues calculées

* `sommier_bilan_financier()` / `v_bilan_financier` : recettes, dépenses,
  solde et cumul par exercice, avec les trois rubriques de dépense détaillées.
  `bois_delivres_eur` isole l'affouage, auquel l'imprimé A50G réserve sa
  colonne.
* `sommier_execution_budgetaire()` / `v_execution_budgetaire` : réalisé
  confronté au prévisionnel, poste par poste. La jointure est complète et non
  gauche — un poste budgété mais jamais exécuté est une information de gestion
  au moins aussi utile qu'un dépassement, et un poste exécuté hors budget doit
  apparaître plutôt que disparaître. `execution_pct` vaut `NA` sur une base
  budgétaire nulle, un taux n'ayant alors pas de sens ; l'écart en euros le dit
  déjà.
* `v_comptabilite` n'expose pas `tiers` : c'est une donnée à caractère
  personnel, qui reste lisible dans le payload pour qui en a besoin mais ne se
  diffuse pas par la vue de consultation courante.

# sommieR 0.2.0

Priorité 2 du brief : évènements, visas signés et ancrage.

## Visa signé et ancrage

* `sommier_viser()` clôture un exercice : il inscrit l'acte au registre 1,
  signe la tête de chaîne en JWS détaché, l'horodate si une autorité est
  configurée, puis pose le visa. L'acte est écrit **avant** la lecture de la
  tête, de sorte que le visa atteste un sommier contenant la trace de sa
  propre délivrance.
* `sommier_signataire()` sépare l'identité de la signature, parce qu'elles
  viennent de sources différentes : un fournisseur OIDC atteste qui signe, une
  clé ou un service eIDAS produit la signature. `signataire_keycloak()` et
  `signataire_cle()` couvrent les deux cas d'usage courants.
* `jws_signer_detache()` / `jws_verifier_detache()` implémentent la signature
  détachée sur charge non encodée (RFC 7515 et 7797, `b64: false`). La tête de
  chaîne n'est pas recopiée dans le jeton : le vérificateur la relit du
  registre, ce qui lie la signature à la chaîne et non à une copie.
* `sommier_ancrer()` horodate la tête indépendamment de tout visa, pour qu'un
  exercice non visé ne puisse pas non plus être réécrit discrètement.
* `sommier_verifier_visas()` confronte chaque visa à la chaîne et à la clé
  publique fournie. Les clés sont passées par l'appelant et non cherchées au
  JWKS : un visa doit rester vérifiable des années plus tard, hors ligne.
* Client RFC 3161 complet (`tsa_requete()`, `tsa_lire_reponse()`,
  `tsa_horodater()`), transport injectable. Sans autorité configurée, le visa
  est posé sans jeton et le rapport le signale plutôt que d'échouer.

## Registres 1 et 8

* Registre 1 — validations (`registre1_validation()`, imprimé A10) : visas
  annuels, arrêtés, délibérations, agréments CRPF, engagements fiscaux.
* Registre 8 — évènements et faune : `registre8_phenomene()` (A50K),
  `registre8_tableau_chasse()` (A50L), `registre8_equilibre_gibier()`
  (équilibre forêt-gibier, LAAAF 2014) et `registre8_detection()`.
* Le registre 8 est d'échelle mixte : une tempête frappe des unités
  identifiées, un tableau de chasse est à l'échelle de la forêt.
* Nouvelles vues : `v_validation`, `v_tenue_sommier`, `v_evenement`,
  `v_detection_en_attente`, `v_tableau_chasse`, `v_equilibre_gibier`.

## Détections de télédétection

* `sommier_importer_detections()` inscrit les propositions FORDEAD/FAST avec
  le NDP de leur source, jamais NDP 0 : une détection est une proposition, pas
  un constat.
* `sommier_valider_detection()` inscrit le constat de terrain en NDP 0, qui
  rectifie la détection — qu'il la confirme ou l'écarte. La proposition sort
  des vues de consultation sans sortir de la chaîne.

## Corrections

* `sommier_init_schema()` exécute le script instruction par instruction
  (`decouper_sql()`). L'envoyer d'un bloc échouait sur les pilotes passant par
  le protocole étendu de PostgreSQL — « cannot insert multiple commands into a
  prepared statement » — ce que le pilote employé en développement masquait.
  Le découpage respecte les chaînes, les commentaires imbriqués et les corps
  de fonction délimités par `$$`.
* Les transactions sont réentrantes, par points de reprise. `dbWithTransaction`
  ne s'imbrique pas : le `COMMIT` interne validait la transaction externe avant
  l'heure, si bien qu'un visa refusé laissait derrière lui l'acte de registre 1
  déjà écrit.
* `entrees_en_data_frame()` n'utilise plus `methods::as()`, qui n'était pas
  importé.
* Les listes de paramètres envoyées au pilote ne sont plus nommées. `vapply()`
  sur un vecteur de caractères nomme son résultat par ses propres valeurs :
  `ug_lire()` et `ug_fusionner()` transmettaient donc des paramètres nommés,
  que RPostgres refuse (« `params` must not be named ») là où RPostgreSQL les
  tolère. Les noms sont désormais retirés au point d'appel, pour qu'aucun site
  ne puisse régresser là-dessus.

# sommieR 0.1.0

Première version : le noyau append-only vérifiable (priorité 1 du brief).

## Registre et chaîne

* `sommier_entree()` construit une entrée validée ; `sommier_ajouter()` la
  chaîne et l'écrit, `sommier_lire()` la relit, `sommier_verifier()` recalcule
  la chaîne de la genèse à la tête.
* `sommier_chainer()` et `sommier_verifier_chaine()` opèrent hors base : un
  auditeur tiers peut vérifier un export sans serveur.
* `jcs()` implémente la sérialisation JSON canonique de la RFC 8785 — tri des
  clés par unités de code UTF-16, échappement minimal, nombres selon
  ECMAScript `Number::toString`.
* L'empreinte couvre l'enregistrement complet, pas seulement le payload : voir
  `SOMMIER_CHAMPS_EMPREINTE` pour la liste des champs et la justification de
  cet écart au brief.

## Registres ouverts

* Registre 5 — coupes et récoltes (`registre5_coupe()`, imprimés A50E/F/I).
* Registre 6 — travaux (`registre6_travaux()`, imprimés A50J/J bis/H).
* Les sept autres registres sont déclarés dans `SOMMIER_REGISTRES` et refusés
  à l'écriture avec un message explicite.

## Base de données

* `sommier_init_schema()` déploie le schéma PostGIS et les vues ; les deux
  fichiers SQL sont idempotents.
* L'append-only est imposé par des déclencheurs, y compris sur `TRUNCATE`, que
  les déclencheurs `FOR EACH ROW` ne couvrent pas ; `visa` et `ancrage` sont
  immuables au même titre.
* `sommier_revoquer_mutations()` retire `UPDATE`, `DELETE` et `TRUNCATE` au
  rôle applicatif.
* Les écritures concurrentes sont sérialisées par forêt via
  `pg_advisory_xact_lock()`, pris avant la lecture de la tête de chaîne.

## Unités de gestion

* Identifiant stable à vie, distinct du numéro d'affichage ; un numéro n'est
  unique que parmi les unités actives, ce qui autorise sa reprise après
  clôture sans jamais réattribuer l'identifiant.
* `ug_scinder()` et `ug_fusionner()` clôturent les unités d'origine et
  enregistrent la filiation. La table `ug_filiation` porte le cas à plusieurs
  parents, que la colonne `parent_uuid` seule ne sait pas représenter.

## Vues calculées

* `v_balance_possibilite` (imprimé A50E) : volumes martelés moins possibilité,
  cumulés. `coupe_realisee` en est exclu, la même coupe étant d'abord martelée
  puis exploitée.
* `v_entree_courante` écarte les entrées rectifiées ; la chaîne les conserve.
* `v_coupe`, `v_travaux`, `v_tete_chaine`.

## Export

* `sommier_exporter_manifeste()` et `sommier_verifier_manifeste()` : partage
  vérifiable hors ligne, visas et ancrages compris. L'export GeoPackage est
  prévu pour la 0.5.0.
