# Sommier des forêts unifié — Synthèse pour sommieR

*Analyse de la série A50 ONF (imprimés officiels, éditions 1974–2018) et généralisation aux trois régimes : forêt domaniale, forêt communale (régime forestier), forêt privée (PSG).*

---

## 1. Ce qu'est le sommier, d'après les imprimés eux-mêmes

L'imprimé A10 le définit en une phrase : *« Le sommier de la forêt constitue avec l'aménagement un instrument essentiel de la gestion forestière. Sa mise à jour régulière est donc obligatoire et il fait l'objet d'un visa annuel du responsable du niveau de gestion. »*

Le sommier n'est donc pas un document mais un **système de registres permanents**, complémentaire du document de gestion (aménagement ou PSG) : l'aménagement dit ce qui est prévu, le sommier enregistre ce qui advient. Trois propriétés en découlent, qui sont les invariants de conception de sommieR :

1. **Append-only** : chaque imprimé est un tableau à lignes datées que l'on remplit sans jamais réécrire l'existant. La correction se fait par nouvelle ligne, pas par rature.
2. **Trois échelles d'ancrage** : la forêt (ou série), l'unité de gestion, et l'objet remarquable ponctuel. Chaque enregistrement se rattache à exactement une de ces échelles.
3. **Contrôle par visa** : le registre A10 trace la validation annuelle. C'est ce qui rend le sommier opposable (contentieux foncier, certification PEFC, transmission entre gestionnaires).

## 2. Cartographie de la série A50 (référentiel ONF)

### Registres à l'échelle de la forêt ou de la série

| Imprimé | Registre | Champs relevés |
|---|---|---|
| **A10** | Tenue du sommier — fiche de contrôle | Date, visa annuel du responsable du niveau de gestion (nom/qualité, signature), observations, visas du niveau de direction |
| **A40** | Frais de délimitation et de bornage | Éléments de calcul (heures ingénieur/technicien, arpentage, fourniture et pose des bornes), répartition à la charge du propriétaire / des riverains |
| **A50C** | Concessions — chasse — pêche | N°, unités de gestion/séries, nature, nom du titulaire, date de départ, date d'expiration, observations |
| **A50D** | Inventaire routier | Voirie privée forestière (routes revêtues / empierrées / en terrain naturel, pistes, largeur de chaussée, longueurs et cumuls) ; voirie publique ; densités en km/100 ha |
| **A50D bis** | Fiche par route forestière | Carte schématisée, points de repère et longueurs cumulées, usage (exploitation / DFCI / tourisme, ouverte / fermée au public), profil en travers type, structure de chaussée datée |
| **A50E** | Volume annuel des produits martelés | Par exercice : possibilité (m³/an), nature des coupes, UG parcourues, volumes martelés (coupes + produits accidentels), **balance de l'exercice** (excès/déficit vs possibilité) et balance cumulée |
| **A50G** | Recettes et dépenses | Par exercice : recettes (bois sur pied, façonnés, délivrés, chasse-pêche, concessions) ; dépenses travaux d'entretien (peuplements, infrastructure, tourisme, chasse-pêche, exploitation en régie) ; travaux neufs (reboisement, équipement, tourisme) ; autres frais (impôts fonciers, frais de garderie, honoraires) |
| **A50H** | Travaux hors unité de gestion | Année, nature des travaux et localisation, quantités, montant, observations |
| **A50K** | Phénomènes intéressant la vie de la forêt | Journal chronologique libre : tempêtes, incendies, crises sanitaires, gel, événements marquants |
| **A50L** | Tableaux de chasse par saison | Matrice espèces × saisons cynégétiques (du 1er avril au 31 mars) : cervidés détaillés par classe d'âge et sexe, sanglier, petit gibier, prédateurs |

### Registres à l'échelle de l'unité de gestion

| Imprimé | Registre | Champs relevés |
|---|---|---|
| **A50F** | Relevé des coupes martelées | Exercice, UG ou coupon, surface, volume (m³), observations |
| **A50I** | Volumes marqués dans l'UG | (Au catalogue ; détail par UG des martelages) |
| **A50J** | Croquis + travaux de l'UG | Croquis à l'échelle avec légende ; relevé des travaux : années, nature, repère plan, nb de plants et provenance, quantités, montant, observations dont **% de reprise** |
| **A50J bis** | Idem + suivi des jeunes peuplements | Groupe d'aménagement, région IFN, surface totale / forestière utile / initiale à travailler ; grille norme × classe × année |

### Fiches du patrimoine remarquable (série A50 r/)

| Imprimé | Objet | Structure commune |
|---|---|---|
| **r/a** | Arbre(s) remarquable(s) | Appellation, essence, intérêt (âge, dimensions, port, histoire) + plan de situation + **mesures datées** (âge, circonférence, hauteur totale, état sanitaire) |
| **r/p** | Peuplement(s) remarquable(s) | Idem + composition en essences (1/10e) + mesures datées (âge, surface, H.dom, surface terrière) + relevé des volumes martelés au verso |
| **r/c** | Vestiges et éléments culturels | Nature, remarques, plan, observations datées, travaux effectués, références bibliographiques |
| **r/e** | Espèces protégées (liste) | Date, nom français, nom latin, localisation |
| **r/s** | Espèce protégée (fiche) | Nom, statut de protection, plan, observations datées, bibliographie |
| **r/h** | Milieux et habitats remarquables | Type d'habitat naturel, surface, localisation, observations |

### Pièces sources (hors sommier, mais l'alimentant)

D01 (proposition d'assiette de coupes non réglées), D11 (fiche de martelage), D1.12 (procès-verbal de dénombrement / titre de recette), CD7 (relevé de travaux du personnel). Le sommier est la **destination consolidée** de ces flux : sommieR doit prévoir des importateurs, pas reproduire ces formulaires.

---

## 3. Le sommier unifié : socle commun aux trois régimes

Les dix registres se généralisent en **8 registres + 1 inventaire**, tous rattachés à une UG stable ou à la forêt :

| # | Registre sommieR | Source A50 | Domanial | Communal | Privé (PSG) |
|---|---|---|---|---|---|
| 1 | **Validations** (visas, agréments) | A10 | Visa ONF | Visa ONF + délibérations du conseil municipal | Agrément CRPF, avenants, engagement fiscal |
| 2 | **Foncier & limites** | A40 | Bornage, délimitation | Idem + application/distraction du régime forestier | Idem + actes d'acquisition, servitudes, références cadastrales |
| 3 | **Droits & concessions** | A50C | Concessions, chasse, pêche | Idem + **affouage** (rôle, garants, taxe) | Baux de chasse, droits d'usage, conventions |
| 4 | **Infrastructures** | A50D/Dbis | Voirie, équipements | Idem | Desserte, équipements DFCI (obligatoire depuis la loi de 2023) |
| 5 | **Coupes & récoltes** | A50E/F/I | Martelages, balance vs possibilité | Idem + bois délivrés (affouage) | Coupes réalisées vs programme PSG (flexibilité ±4 ans), coupes extraordinaires autorisées |
| 6 | **Travaux** | A50J/Jbis/H | Par UG + hors UG, % de reprise | Idem | Idem, conformité SRGS de l'itinéraire |
| 7 | **Comptabilité** | A50G | Recettes/dépenses par exercice | Idem + frais de garderie | Idem + dispositifs fiscaux (DEFI, IFI, Monichon) |
| 8 | **Événements & faune** | A50K/L | Journal des phénomènes + tableaux de chasse | Idem | Idem + **équilibre forêt-gibier** (surfaces sensibles, plan de chasse — obligatoire LAAAF 2014) |
| 9 | **Patrimoine remarquable** | A50 r/* | 6 types de fiches | Idem | Idem, alimente l'IBP et les annexes Natura 2000 |

### Ce qui change réellement entre régimes

Le socle est identique à ~85 %. Les différences tiennent en quatre points :

1. **L'autorité de validation** (registre 1) : arrêté ministériel/préfectoral + visa ONF en domanial, + délibérations communales en forêt communale, agrément CRPF en privé. C'est un simple champ `autorite` + type de pièce jointe.
2. **L'affouage** n'existe qu'en communal : sous-registre du registre 3 (bénéficiaires, garants) et lignes « bois délivrés » dans les registres 5 et 7. L'imprimé A50G le prévoit déjà (colonne « bois délivrés »).
3. **La balance de possibilité** (A50E) est stricte en forêt publique (aménagement réglé) ; en privé elle devient une **balance de conformité au programme PSG** avec tolérance ±4 ans — même mécanisme, paramètres différents.
4. **Les obligations récentes du PSG** (analyse DFCI 2023, équilibre forêt-gibier 2014) sont déjà couvertes par les registres 4 et 8 du socle : il suffit de les rendre obligatoires selon le régime.

---

## 4. Modèle de données sommieR

### Entités

```
foret            (id, nom, regime {domanial|communal|privee}, proprietaire,
                  date_application_regime_forestier, surface_ha)
serie            (id, foret_id, nom)                      -- optionnel
ug               (uuid STABLE, foret_id, serie_id, numero_affichage,
                  geometrie_versionnee[], date_debut, date_fin, parent_uuid)
exercice         (foret_id, annee, possibilite_m3_an)

-- Un seul patron d'enregistrement pour les 8 registres :
entree_sommier   (id, foret_id, ug_uuid NULLABLE, registre {1..8},
                  date_evenement, date_saisie, auteur, ndp,
                  payload JSONB versionné par type, piece_jointe[])

objet_remarquable (id, foret_id, ug_uuid, type {arbre|peuplement|vestige|
                   espece|habitat}, geometrie_ponctuelle, fiche JSONB,
                   observations_datees[])
visa             (id, foret_id, annee, autorite, nom_qualite, date, document)
```

### Règles héritées des imprimés

- **Append-only strict** : pas d'UPDATE sur `entree_sommier` ; correction = nouvelle entrée avec `corrige_id`. C'est ce que le classeur papier garantit physiquement.
- **UG à identifiant stable** : les imprimés A50J survivent aux redécoupages parce que la fiche papier suit la parcelle. En numérique, cela impose un `uuid` jamais réattribué et une table de filiation `parent_uuid` lors des scissions/fusions — indépendant du `numero_affichage`.
- **Le champ `ndp`** raccorde le sommier au système nemeton : une entrée saisie sur le terrain (martelage, % de reprise, observation d'espèce) est NDP 0 par définition ; une entrée déduite de télédétection (événement A50K détecté par FORDEAD/FAST) porte son NDP d'origine. Le sommier devient ainsi le **réceptacle NDP 0** de la plateforme.
- **La balance A50E est une vue calculée**, pas une saisie : `SUM(volumes martelés de l'exercice) − possibilité`, cumulée. Idem densités routières A50D (km/100 ha) et totaux A50G.

### Ce que sommieR ne doit PAS faire

- Reproduire les pièces sources (D11, D01, CD7) : ce sont des flux entrants à importer.
- Écraser ou renuméroter : le mécanisme `ug_init_default()` → `save_ug_data()` identifié dans l'audit v1.0.0 de nemetonshiny est incompatible avec un sommier — l'identifiant stable est un prérequis (lot D de l'audit).
- Mélanger sommier et document de gestion : le programme prévisionnel appartient à l'aménagement/PSG ; le sommier n'enregistre que le réalisé et le constaté.

---

## 5. Correspondance avec les familles nemeton

| Registre sommieR | Familles NMT alimentées | Sens du flux |
|---|---|---|
| Coupes & récoltes (5) | P (p1_volume, p3_qualite_bois), E | Sommier → indicateurs (historique de prélèvement) |
| Travaux (6) | T (t2_changement), C | Sommier → indicateurs |
| Événements (8) | R (r1_feu, r2_tempete, r3_secheresse) | Bidirectionnel : détection télédétection → proposition d'entrée A50K, validation terrain → NDP 0 |
| Faune (8) | R (r4_abroutissement) | Sommier → équilibre forêt-gibier du PSG |
| Patrimoine remarquable (9) | B (b1, b2), N | Sommier → IBP (facteurs bois mort, arbres habitats, milieux ouverts) |
| Comptabilité (7) | P + budget prévisionnel | Comble l'écart « budget prévisionnel absent » du comparatif |
| Foncier (2) | — | Comble l'écart « module historique incomplet » |

Le sommier résout structurellement deux écarts importants du comparatif Nemeton : le **module de gestion antérieure** (le sommier EST l'historique des coupes, travaux et événements fortuits exigé par les trois référentiels) et le **bilan réglementaire** du précédent aménagement/PSG, qui devient une simple requête sur les registres 5, 6 et 7.

---

## 6. Intégrité vérifiable : chaîne de hash et visa signé

Le sommier étant un registre partagé et opposable, son append-only doit être une **propriété vérifiable cryptographiquement**, pas une convention applicative (le scénario `save_ug_data()` de l'audit v1.0.0 montre qu'un UPDATE silencieux est toujours possible côté application). La solution retenue : un **journal à chaînage de hash** dans PostGIS, signé par visa via AgentConnect, horodaté par une autorité RFC 3161. Aucune blockchain : les acteurs sont identifiés, l'autorité de validation est désignée par le droit, et la valeur probante en France passe par le cadre eIDAS (signature qualifiée, horodatage qualifié, NF Z42-013) — pas par un consensus décentralisé. IPFS est par ailleurs exclu pour cause de RGPD (données personnelles des registres 3 et 7 : titulaires de baux, affouagistes, montants).

### 6.1 Principe

```
entrée n-1                entrée n                  entrée n+1
┌──────────────┐          ┌──────────────┐          ┌──────────────┐
│ payload      │          │ payload      │          │ payload      │
│ hash_prev ───┼─┐        │ hash_prev ───┼─┐        │ hash_prev    │
│ hash    ◄────┼─┼───┐    │ hash    ◄────┼─┼───┐    │ hash         │
└──────────────┘ │   │    └──────────────┘ │   │    └──────────────┘
                 │   └──────────►──────────┘   └─────────►
                 │
   hash_n = SHA-256( JCS(payload_n) ‖ hash_{n-1} )

Clôture d'exercice :
   hash de tête ──► signature JWS (AgentConnect/Keycloak) ──► visa A10
                └─► jeton d'horodatage RFC 3161 ──► ancrage
```

Toute modification, suppression ou insertion a posteriori d'une entrée invalide tous les hash suivants ; le visa signé et l'horodatage externe prouvent que la chaîne existait dans cet état à une date donnée. Chaque acteur (commune, CRPF, expert) peut revérifier la chaîne localement à partir d'un export, sans faire confiance au serveur.

### 6.2 Schéma SQL (PostGIS)

```sql
CREATE TABLE entree_sommier (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  foret_id      UUID NOT NULL REFERENCES foret(id),
  ug_uuid       UUID REFERENCES ug(uuid),          -- NULL = échelle forêt
  registre      SMALLINT NOT NULL CHECK (registre BETWEEN 1 AND 9),
  seq           BIGINT NOT NULL,                   -- monotone PAR forêt
  date_evenement DATE NOT NULL,
  date_saisie   TIMESTAMPTZ NOT NULL DEFAULT now(),
  auteur        TEXT NOT NULL,                     -- sub OIDC Keycloak
  ndp           SMALLINT NOT NULL DEFAULT 0,
  corrige_id    UUID REFERENCES entree_sommier(id),-- correction = nouvelle entrée
  payload       JSONB NOT NULL,                    -- versionné par type de registre
  schema_version TEXT NOT NULL,                    -- patron ACTION_PLAN_SCHEMA_VERSION
  hash_prev     BYTEA NOT NULL,                    -- 32 octets ; genèse = SHA256(foret_id)
  hash          BYTEA NOT NULL,                    -- SHA256(JCS(payload) || hash_prev)
  UNIQUE (foret_id, seq),
  UNIQUE (foret_id, hash)
);

-- L'append-only est imposé PAR LA BASE, pas par l'application :
REVOKE UPDATE, DELETE ON entree_sommier FROM nemeton_app;

CREATE FUNCTION interdire_mutation() RETURNS trigger AS $$
BEGIN RAISE EXCEPTION 'entree_sommier est append-only (sommier)'; END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER sommier_immutable
  BEFORE UPDATE OR DELETE ON entree_sommier
  FOR EACH ROW EXECUTE FUNCTION interdire_mutation();

CREATE TABLE visa (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  foret_id      UUID NOT NULL REFERENCES foret(id),
  exercice      INTEGER NOT NULL,
  seq_tete      BIGINT NOT NULL,                   -- dernière entrée couverte
  hash_tete     BYTEA NOT NULL,                    -- ce qui est signé
  autorite      TEXT NOT NULL,        -- 'onf' | 'commune' | 'crpf' | 'proprietaire'
  signataire    JSONB NOT NULL,       -- claims OIDC : sub, given_name, usual_name, siret
  signature_jws TEXT NOT NULL,        -- JWS detached sur hash_tete
  tst_rfc3161   BYTEA,                -- jeton d'horodatage qualifié
  date_visa     TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (foret_id, exercice, autorite)
);

CREATE TABLE ancrage (                -- horodatage périodique hors visa
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  foret_id    UUID NOT NULL REFERENCES foret(id),
  seq_tete    BIGINT NOT NULL,
  hash_tete   BYTEA NOT NULL,
  tst_rfc3161 BYTEA NOT NULL,
  ots_proof   BYTEA,                  -- optionnel : preuve OpenTimestamps
  date_ancrage TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

### 6.3 Règles d'implémentation

- **Sérialisation canonique obligatoire** : le hash porte sur `payload` en **JSON Canonical Scheme (RFC 8785)**, jamais sur le JSONB tel que restitué par PostgreSQL (qui réordonne les clés et normalise les nombres — deux représentations d'un même payload donneraient deux hash). Le calcul se fait côté R (`jsonlite` en sortie canonique + `openssl::sha256()`), la base ne fait que stocker et contraindre.
- **Concurrence** : l'insertion prend un `pg_advisory_xact_lock(hashtext(foret_id::text))` pour sérialiser les écritures par forêt — deux INSERT concurrents avec le même `hash_prev` créeraient une fourche. Le couple `UNIQUE(foret_id, seq)` est le filet de sécurité.
- **Correction sans réécriture** : une erreur se corrige par une nouvelle entrée portant `corrige_id` ; les vues de consultation (balance A50E, totaux A50G) excluent les entrées corrigées. La chaîne, elle, garde tout — c'est le comportement du classeur papier (rature interdite, mention rectificative).
- **Vérification** : `sommier_verifier(foret_id)` recalcule la chaîne de la genèse à la tête et confronte chaque visa/ancrage à son `hash_tete`. Exposée dans le package (utilisable par un auditeur tiers sur un export) et exécutée à chaque ouverture de projet dans nemetonShiny.
- **Flux du visa A10 numérique** : (1) clôture de l'exercice → lecture de `hash_tete` ; (2) authentification du signataire via AgentConnect (agents publics, ONF) ou Keycloak (propriétaires privés, experts) ; (3) signature JWS détachée de `hash_tete` — clé du signataire ou service de signature eIDAS selon le niveau visé ; (4) requête d'horodatage RFC 3161 sur le même hash ; (5) INSERT du visa. Le certificat/les claims OIDC sont archivés dans `signataire` pour la vérification à long terme.
- **Ancrage périodique** (mensuel, tâche cron) : horodatage RFC 3161 du hash de tête, indépendamment des visas — garantit qu'même un exercice non visé ne peut être réécrit discrètement. `ots_proof` (OpenTimestamps, gratuit) en ceinture-bretelles optionnelle.
- **Export partagé** : GeoPackage + manifeste JSON contenant la chaîne des hash, les visas et les jetons d'horodatage. Le destinataire vérifie l'intégrité hors ligne avec `sommier_verifier()` — c'est le « partage sans confiance » recherché, sans infrastructure distribuée.

### 6.4 Ce que cette couche apporte commercialement

L'argument « registre à valeur probante (chaînage cryptographique, signature AgentConnect, horodatage qualifié eIDAS) » est directement audible par une DREAL, un CRPF ou une commune — contrairement à « blockchain » qui déclenche la méfiance des acheteurs publics. Il répond aussi à l'exigence PEFC de traçabilité documentée, et transforme le point faible identifié par l'audit (écrasement silencieux du layout UGF) en garantie structurelle.

---

## 7. Priorités de développement suggérées

1. **v0.1 — le noyau append-only vérifiable** : `foret`, `ug` (uuid stable + filiation), `entree_sommier` **avec chaîne de hash dès la première ligne** (le chaînage ne se rétrofitte pas sur un registre existant sans en réécrire la genèse), triggers d'immutabilité, `sommier_verifier()`, registres 5 et 6 (coupes, travaux) — ce sont eux qu'exigent PEFC et le bilan PSG/aménagement.
2. **v0.2 — événements et visas signés** : registres 8 et 1, flux de visa JWS via AgentConnect/Keycloak, ancrage RFC 3161 périodique, import des détections FORDEAD/FAST comme entrées proposées à valider (NDP monte à 0 après validation terrain).
3. **v0.3 — comptabilité et balance** : registre 7 + vues calculées A50E/A50G → génère le budget prévisionnel et le bilan financier du document de gestion.
4. **v0.4 — foncier, concessions, remarquables** : registres 2, 3, 4, 9 + export IBP.
5. **Exports** : section « gestion antérieure » du PSG (bloc 3 de l'arrêté 2012), bilan de l'aménagement précédent (partie 2 du DA ONF), évaluation de fin de plan (étape 5 CT88) — les trois se génèrent depuis les mêmes registres — et **export partagé vérifiable** (GeoPackage + manifeste chaîne/visas/horodatages, vérifiable hors ligne).

---

*Synthèse établie à partir de la série A50 ONF (26 imprimés, éditions 01/74 à 09/09, mises en page 2018, catalogue DT BFC 2019) — août 2026.*
