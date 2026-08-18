-- =====================================================================
-- sommieR — schema du sommier forestier unifie (v0.1.0)
--
-- Traduction de la section 4 (modele de donnees) et de la section 6.2
-- (chaine de hachages) du brief. Deux principes gouvernent ce fichier :
--
--   1. L'append-only est impose PAR LA BASE, pas par l'application.
--      Un UPDATE silencieux cote applicatif reste toujours possible ; le
--      declencheur, lui, ne se contourne pas.
--   2. La base stocke et contraint, elle ne calcule pas les empreintes.
--      Le hachage porte sur la forme canonique RFC 8785 du payload, que
--      PostgreSQL ne peut pas reproduire (JSONB reordonne les cles et
--      normalise les nombres). Le calcul se fait donc cote R.
-- =====================================================================

CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS pgcrypto;   -- gen_random_uuid()

-- ---------------------------------------------------------------------
-- Perimetre de gestion
-- ---------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS foret (
  id        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nom       TEXT NOT NULL,
  regime    TEXT NOT NULL CHECK (regime IN ('domanial', 'communal', 'privee')),
  proprietaire TEXT,
  date_application_regime_forestier DATE,
  surface_ha    NUMERIC CHECK (surface_ha IS NULL OR surface_ha >= 0),
  cree_le       TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON COLUMN foret.date_application_regime_forestier IS
  'Sans objet en foret privee ; renseignee en domanial et en communal.';

CREATE TABLE IF NOT EXISTS serie (
  id       UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  foret_id UUID NOT NULL REFERENCES foret(id) ON DELETE RESTRICT,
  nom      TEXT NOT NULL,
  UNIQUE (foret_id, nom)
);

-- Unite de gestion. L'identifiant est stable A VIE : les fiches A50J
-- survivent aux redecoupages parce que la fiche papier suit la parcelle.
-- `numero_affichage` peut changer, `uuid` jamais.
CREATE TABLE IF NOT EXISTS ug (
  uuid             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  foret_id         UUID NOT NULL REFERENCES foret(id) ON DELETE RESTRICT,
  serie_id         UUID REFERENCES serie(id),
  numero_affichage TEXT NOT NULL,
  date_debut       DATE NOT NULL,
  date_fin         DATE,                       -- NULL = unite active
  parent_uuid      UUID REFERENCES ug(uuid),   -- filiation a parent unique
  CHECK (date_fin IS NULL OR date_fin >= date_debut)
);

COMMENT ON COLUMN ug.parent_uuid IS
  'Commodite pour le cas a parent unique (scission). La filiation faisant '
  'autorite est ug_filiation, qui seule sait representer une fusion.';

-- Un identifiant retire de la circulation ne doit jamais etre reattribue :
-- l''index partiel garantit qu''un numero d''affichage n''est porte que par
-- une seule unite active a la fois, sans empecher sa reprise apres cloture.
CREATE UNIQUE INDEX IF NOT EXISTS ug_numero_actif_unique
  ON ug (foret_id, numero_affichage) WHERE date_fin IS NULL;

CREATE INDEX IF NOT EXISTS ug_foret_idx ON ug (foret_id);

-- Filiation generale : une scission a un parent et n enfants, une fusion a
-- n parents et un enfant. Une seule colonne `parent_uuid` ne sait pas
-- representer le second cas.
CREATE TABLE IF NOT EXISTS ug_filiation (
  enfant_uuid UUID NOT NULL REFERENCES ug(uuid),
  parent_uuid UUID NOT NULL REFERENCES ug(uuid),
  type_filiation TEXT NOT NULL CHECK (type_filiation IN ('scission', 'fusion')),
  date_effet  DATE NOT NULL,
  PRIMARY KEY (enfant_uuid, parent_uuid),
  CHECK (enfant_uuid <> parent_uuid)
);

CREATE INDEX IF NOT EXISTS ug_filiation_parent_idx
  ON ug_filiation (parent_uuid);

-- Geometrie versionnee : le contour d''une unite de gestion change (revision
-- d''amenagement, releve GNSS plus precis) sans que son identite change.
CREATE TABLE IF NOT EXISTS ug_geometrie (
  ug_uuid    UUID NOT NULL REFERENCES ug(uuid),
  version    INTEGER NOT NULL,
  geom       GEOMETRY(MultiPolygon, 2154) NOT NULL,
  source     TEXT,
  date_debut DATE NOT NULL,
  date_fin   DATE,
  PRIMARY KEY (ug_uuid, version),
  CHECK (date_fin IS NULL OR date_fin >= date_debut)
);

CREATE INDEX IF NOT EXISTS ug_geometrie_geom_idx
  ON ug_geometrie USING GIST (geom);

-- Possibilite annuelle : le terme de comparaison de la balance A50E.
CREATE TABLE IF NOT EXISTS exercice (
  foret_id          UUID NOT NULL REFERENCES foret(id) ON DELETE RESTRICT,
  annee             INTEGER NOT NULL,
  possibilite_m3_an NUMERIC CHECK (possibilite_m3_an IS NULL OR possibilite_m3_an >= 0),
  PRIMARY KEY (foret_id, annee)
);

-- ---------------------------------------------------------------------
-- Le registre lui-meme
-- ---------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS entree_sommier (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  foret_id       UUID NOT NULL REFERENCES foret(id) ON DELETE RESTRICT,
  ug_uuid        UUID REFERENCES ug(uuid),          -- NULL = echelle foret
  registre       SMALLINT NOT NULL CHECK (registre BETWEEN 1 AND 9),
  seq            BIGINT NOT NULL,                   -- monotone PAR foret
  date_evenement DATE NOT NULL,
  date_saisie    TIMESTAMPTZ NOT NULL DEFAULT now(),
  auteur         TEXT NOT NULL,                     -- sub OIDC Keycloak
  ndp            SMALLINT NOT NULL DEFAULT 0 CHECK (ndp >= 0),
  corrige_id     UUID REFERENCES entree_sommier(id),
  payload        JSONB NOT NULL,
  schema_version TEXT NOT NULL,
  hash_prev      BYTEA NOT NULL CHECK (octet_length(hash_prev) = 32),
  hash           BYTEA NOT NULL CHECK (octet_length(hash) = 32),
  UNIQUE (foret_id, seq),
  UNIQUE (foret_id, hash),
  CHECK (seq >= 1),
  CHECK (corrige_id <> id)
);

COMMENT ON COLUMN entree_sommier.hash IS
  'SHA-256( JCS(enregistrement) || hash_prev ). L''enregistrement couvre le '
  'payload ET les metadonnees attestables (registre, ug_uuid, dates, auteur, '
  'ndp, seq, corrige_id, schema_version) : un export dont les metadonnees '
  'seraient hors chaine ne serait pas verifiable par un tiers.';

COMMENT ON COLUMN entree_sommier.corrige_id IS
  'Correction = nouvelle entree, jamais reecriture. Les vues de consultation '
  'excluent les entrees corrigees ; la chaine, elle, garde tout.';

CREATE INDEX IF NOT EXISTS entree_sommier_foret_seq_idx
  ON entree_sommier (foret_id, seq);
CREATE INDEX IF NOT EXISTS entree_sommier_registre_idx
  ON entree_sommier (foret_id, registre);
CREATE INDEX IF NOT EXISTS entree_sommier_ug_idx
  ON entree_sommier (ug_uuid) WHERE ug_uuid IS NOT NULL;
CREATE INDEX IF NOT EXISTS entree_sommier_corrige_idx
  ON entree_sommier (corrige_id) WHERE corrige_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS entree_sommier_payload_idx
  ON entree_sommier USING GIN (payload);

-- L''append-only est impose par la base, pas par l''application.
CREATE OR REPLACE FUNCTION interdire_mutation() RETURNS trigger AS $$
BEGIN
  -- TG_TABLE_NAME plutot que le nom en dur : la fonction sert aussi a visa
  -- et ancrage, un message errone y enverrait l''exploitant sur une fausse
  -- piste.
  RAISE EXCEPTION
    '% est append-only (sommier) : une correction s''ecrit comme une '
    'nouvelle entree portant corrige_id, jamais comme un %.',
    TG_TABLE_NAME, TG_OP
    USING ERRCODE = 'restrict_violation';
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS sommier_immutable ON entree_sommier;
CREATE TRIGGER sommier_immutable
  BEFORE UPDATE OR DELETE ON entree_sommier
  FOR EACH ROW EXECUTE FUNCTION interdire_mutation();

-- TRUNCATE ne declenche pas un trigger FOR EACH ROW : sans ce second
-- declencheur, le registre entier reste effacable d''une seule commande.
DROP TRIGGER IF EXISTS sommier_immutable_truncate ON entree_sommier;
CREATE TRIGGER sommier_immutable_truncate
  BEFORE TRUNCATE ON entree_sommier
  FOR EACH STATEMENT EXECUTE FUNCTION interdire_mutation();

-- Une entree ne peut corriger qu''une entree de la meme foret : une
-- correction inter-forets briserait la lecture par registre.
CREATE OR REPLACE FUNCTION verifier_correction() RETURNS trigger AS $$
DECLARE
  foret_cible UUID;
BEGIN
  IF NEW.corrige_id IS NULL THEN
    RETURN NEW;
  END IF;
  SELECT foret_id INTO foret_cible FROM entree_sommier WHERE id = NEW.corrige_id;
  IF foret_cible IS DISTINCT FROM NEW.foret_id THEN
    RAISE EXCEPTION
      'corrige_id % appartient a une autre foret que %',
      NEW.corrige_id, NEW.foret_id
      USING ERRCODE = 'foreign_key_violation';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS sommier_correction_coherente ON entree_sommier;
CREATE TRIGGER sommier_correction_coherente
  BEFORE INSERT ON entree_sommier
  FOR EACH ROW EXECUTE FUNCTION verifier_correction();

-- ---------------------------------------------------------------------
-- Visa et ancrage (schema pose en v0.1.0, flux de signature en v0.2.0)
-- ---------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS visa (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  foret_id      UUID NOT NULL REFERENCES foret(id) ON DELETE RESTRICT,
  exercice      INTEGER NOT NULL,
  seq_tete      BIGINT NOT NULL,
  hash_tete     BYTEA NOT NULL CHECK (octet_length(hash_tete) = 32),
  autorite      TEXT NOT NULL
                CHECK (autorite IN ('onf', 'commune', 'crpf', 'proprietaire')),
  signataire    JSONB NOT NULL,
  signature_jws TEXT NOT NULL,
  tst_rfc3161   BYTEA,
  date_visa     TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (foret_id, exercice, autorite)
);

CREATE TABLE IF NOT EXISTS ancrage (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  foret_id     UUID NOT NULL REFERENCES foret(id) ON DELETE RESTRICT,
  seq_tete     BIGINT NOT NULL,
  hash_tete    BYTEA NOT NULL CHECK (octet_length(hash_tete) = 32),
  tst_rfc3161  BYTEA NOT NULL,
  ots_proof    BYTEA,
  date_ancrage TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Un visa et un ancrage attestent d''un etat de la chaine : ils sont eux
-- aussi immuables, sans quoi on pourrait antidater une attestation.
DROP TRIGGER IF EXISTS visa_immutable ON visa;
CREATE TRIGGER visa_immutable
  BEFORE UPDATE OR DELETE ON visa
  FOR EACH ROW EXECUTE FUNCTION interdire_mutation();

DROP TRIGGER IF EXISTS ancrage_immutable ON ancrage;
CREATE TRIGGER ancrage_immutable
  BEFORE UPDATE OR DELETE ON ancrage
  FOR EACH ROW EXECUTE FUNCTION interdire_mutation();

-- ---------------------------------------------------------------------
-- Budget previsionnel (v0.3.0)
--
-- Le previsionnel N'EST PAS une entree de sommier. Le brief est explicite :
-- « le programme previsionnel appartient a l'amenagement/PSG ; le sommier
-- n'enregistre que le realise et le constate ». Il vit donc a cote du
-- registre, exactement comme `exercice.possibilite_m3_an` porte la
-- possibilite sans etre une coupe.
--
-- Consequence assumee : cette table est mutable, contrairement au registre.
-- Un budget se revise, et cette revision n'a pas a etre opposable ; ce qui
-- doit l'etre, c'est le realise, qui lui est dans la chaine.
-- ---------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS budget_previsionnel (
  foret_id    UUID NOT NULL REFERENCES foret(id) ON DELETE RESTRICT,
  annee       INTEGER NOT NULL,
  poste       TEXT NOT NULL,
  montant_eur NUMERIC NOT NULL CHECK (montant_eur >= 0),
  revise_le   TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (foret_id, annee, poste)
);

COMMENT ON TABLE budget_previsionnel IS
  'Budget previsionnel du document de gestion. Hors chaine, et mutable : '
  'un budget se revise. Le realise correspondant est au registre 7.';

COMMENT ON COLUMN budget_previsionnel.montant_eur IS
  'Toujours positif : le sens vient du poste, via la nomenclature '
  'SOMMIER_POSTES_COMPTABLES.';
