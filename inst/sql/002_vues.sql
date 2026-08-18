-- =====================================================================
-- sommieR — vues de consultation (v0.1.0)
--
-- « La balance A50E est une vue calculee, pas une saisie » (brief, s.4).
-- Rien de ce qui suit n'est stocke : tout se deduit du registre, ce qui
-- garantit que le constate affiche est bien celui que la chaine couvre.
-- =====================================================================

-- Entrees en vigueur : une entree rectifiee par une entree ulterieure sort
-- des vues de consultation, mais reste dans la chaine. C'est la mention
-- rectificative du classeur papier, pas une rature.
CREATE OR REPLACE VIEW v_entree_courante AS
SELECT e.*
FROM entree_sommier e
WHERE NOT EXISTS (
  SELECT 1 FROM entree_sommier c WHERE c.corrige_id = e.id
);

COMMENT ON VIEW v_entree_courante IS
  'Entrees non rectifiees. Toutes les vues metier s''y adossent.';

-- ---------------------------------------------------------------------
-- Registre 5 — coupes et recoltes
-- ---------------------------------------------------------------------

CREATE OR REPLACE VIEW v_coupe AS
SELECT
  e.id,
  e.foret_id,
  e.ug_uuid,
  e.seq,
  e.date_evenement,
  e.auteur,
  e.ndp,
  (e.payload ->> 'type_entree')::TEXT             AS type_entree,
  (e.payload ->> 'exercice')::INTEGER             AS exercice,
  (e.payload ->> 'nature_coupe')::TEXT            AS nature_coupe,
  (e.payload ->> 'volume_m3')::NUMERIC            AS volume_m3,
  (e.payload ->> 'surface_ha')::NUMERIC           AS surface_ha,
  (e.payload ->> 'essence')::TEXT                 AS essence,
  (e.payload ->> 'coupon')::TEXT                  AS coupon,
  (e.payload ->> 'observations')::TEXT            AS observations
FROM v_entree_courante e
WHERE e.registre = 5;

-- Balance A50E : SUM(volumes marteles de l'exercice) - possibilite, cumulee.
--
-- `coupe_realisee` est exclu du martele : la meme coupe est d'abord martelee
-- (A50E) puis exploitee (A50F), l'imputer deux fois doublerait le
-- prelevement constate.
--
-- La jointure part de `exercice` et non des coupes : un exercice sans aucune
-- coupe pese pour un deficit egal a toute sa possibilite, il ne doit pas
-- disparaitre de la balance cumulee.
CREATE OR REPLACE VIEW v_balance_possibilite AS
WITH martele AS (
  SELECT
    c.foret_id,
    c.exercice,
    SUM(c.volume_m3) FILTER (
      WHERE c.type_entree IN ('martelage', 'produit_accidentel', 'bois_delivre')
    ) AS volume_martele_m3,
    SUM(c.volume_m3) FILTER (
      WHERE c.type_entree = 'coupe_realisee'
    ) AS volume_realise_m3
  FROM v_coupe c
  GROUP BY c.foret_id, c.exercice
),
socle AS (
  SELECT
    x.foret_id,
    x.annee                                   AS exercice,
    x.possibilite_m3_an,
    COALESCE(m.volume_martele_m3, 0)          AS volume_martele_m3,
    COALESCE(m.volume_realise_m3, 0)          AS volume_realise_m3
  FROM exercice x
  LEFT JOIN martele m
    ON m.foret_id = x.foret_id AND m.exercice = x.annee
)
SELECT
  s.foret_id,
  s.exercice,
  s.possibilite_m3_an,
  s.volume_martele_m3,
  s.volume_realise_m3,
  s.volume_martele_m3 - COALESCE(s.possibilite_m3_an, 0) AS balance_exercice_m3,
  SUM(s.volume_martele_m3 - COALESCE(s.possibilite_m3_an, 0))
    OVER (PARTITION BY s.foret_id ORDER BY s.exercice
          ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS balance_cumulee_m3
FROM socle s
ORDER BY s.foret_id, s.exercice;

COMMENT ON VIEW v_balance_possibilite IS
  'Imprime A50E. Balance positive = exces de prelevement sur la possibilite, '
  'negative = deficit. En foret privee, la possibilite tient lieu de '
  'programme PSG et la tolerance de conformite est de +/- 4 ans.';

-- ---------------------------------------------------------------------
-- Registre 6 — travaux
-- ---------------------------------------------------------------------

CREATE OR REPLACE VIEW v_travaux AS
SELECT
  e.id,
  e.foret_id,
  e.ug_uuid,
  e.seq,
  e.date_evenement,
  e.auteur,
  e.ndp,
  (e.payload ->> 'annee')::INTEGER            AS annee,
  (e.payload ->> 'nature_travaux')::TEXT      AS nature_travaux,
  (e.payload ->> 'localisation')::TEXT        AS localisation,
  (e.payload ->> 'repere_plan')::TEXT         AS repere_plan,
  (e.payload ->> 'quantite')::NUMERIC         AS quantite,
  (e.payload ->> 'unite')::TEXT               AS unite,
  (e.payload ->> 'nb_plants')::INTEGER        AS nb_plants,
  (e.payload ->> 'provenance_plants')::TEXT   AS provenance_plants,
  (e.payload ->> 'montant_eur')::NUMERIC      AS montant_eur,
  (e.payload ->> 'taux_reprise_pct')::NUMERIC AS taux_reprise_pct,
  (e.payload ->> 'observations')::TEXT        AS observations,
  (e.ug_uuid IS NULL)                         AS hors_unite_gestion
FROM v_entree_courante e
WHERE e.registre = 6;

COMMENT ON VIEW v_travaux IS
  'Imprimes A50J et A50J bis (par unite de gestion) et A50H '
  '(hors unite de gestion, ug_uuid NULL).';

-- ---------------------------------------------------------------------
-- Etat de la chaine
-- ---------------------------------------------------------------------

-- Tete de chaine par foret : ce que signe un visa et ce qu'horodate un
-- ancrage.
CREATE OR REPLACE VIEW v_tete_chaine AS
SELECT DISTINCT ON (e.foret_id)
  e.foret_id,
  e.seq  AS seq_tete,
  e.hash AS hash_tete,
  e.date_saisie
FROM entree_sommier e
ORDER BY e.foret_id, e.seq DESC;

-- ---------------------------------------------------------------------
-- Registre 1 - validations (imprime A10)
-- ---------------------------------------------------------------------

CREATE OR REPLACE VIEW v_validation AS
SELECT
  e.id,
  e.foret_id,
  e.seq,
  e.date_evenement,
  e.auteur,
  (e.payload ->> 'type_validation')::TEXT AS type_validation,
  (e.payload ->> 'autorite')::TEXT        AS autorite,
  (e.payload ->> 'nom_qualite')::TEXT     AS nom_qualite,
  (e.payload ->> 'exercice')::INTEGER     AS exercice,
  (e.payload ->> 'reference')::TEXT       AS reference,
  (e.payload ->> 'date_effet')::DATE      AS date_effet,
  (e.payload ->> 'portee')::TEXT          AS portee,
  (e.payload ->> 'observations')::TEXT    AS observations
FROM v_entree_courante e
WHERE e.registre = 1;

COMMENT ON VIEW v_validation IS
  'Imprime A10. Trace l''acte de validation ; la preuve cryptographique '
  'correspondante vit dans la table visa, qui couvre la tete de chaine.';

-- Exercices vises, avec l''etat de la preuve cryptographique. Un exercice
-- porte au registre 1 sans visa signe correspondant n''est pas une fraude,
-- mais il n''est pas opposable de la meme facon : la vue le montre.
CREATE OR REPLACE VIEW v_tenue_sommier AS
SELECT
  v.foret_id,
  v.exercice,
  v.autorite,
  v.nom_qualite,
  v.date_evenement                       AS date_acte,
  (s.id IS NOT NULL)                     AS signe,
  (s.tst_rfc3161 IS NOT NULL)            AS horodate,
  s.seq_tete
FROM v_validation v
LEFT JOIN visa s
  ON s.foret_id = v.foret_id
 AND s.exercice = v.exercice
 AND s.autorite = v.autorite
WHERE v.type_validation IN ('visa_annuel', 'visa_direction')
ORDER BY v.foret_id, v.exercice;

-- ---------------------------------------------------------------------
-- Registre 8 - evenements et faune (imprimes A50K et A50L)
-- ---------------------------------------------------------------------

CREATE OR REPLACE VIEW v_evenement AS
SELECT
  e.id,
  e.foret_id,
  e.ug_uuid,
  e.seq,
  e.date_evenement,
  e.auteur,
  e.ndp,
  (e.payload ->> 'type_entree')::TEXT       AS type_entree,
  (e.payload ->> 'nature')::TEXT            AS nature,
  (e.payload ->> 'description')::TEXT       AS description,
  (e.payload ->> 'surface_ha')::NUMERIC     AS surface_ha,
  (e.payload ->> 'volume_impacte_m3')::NUMERIC AS volume_impacte_m3,
  (e.payload ->> 'source')::TEXT            AS source,
  (e.payload ->> 'indice')::NUMERIC         AS indice,
  (e.payload ->> 'statut_detection')::TEXT  AS statut_detection,
  (e.payload ->> 'observations')::TEXT      AS observations
FROM v_entree_courante e
WHERE e.registre = 8
  AND (e.payload ->> 'type_entree') IN ('phenomene', 'detection');

COMMENT ON VIEW v_evenement IS
  'Imprime A50K. Les detections encore en attente de validation y figurent '
  'avec leur NDP d''origine ; une fois le terrain passe, elles sont '
  'rectifiees et sortent de la vue au profit du constat NDP 0.';

-- Detections proposees par teledetection et non encore tranchees. La liste
-- de travail du gestionnaire : ce qui reste a aller voir.
CREATE OR REPLACE VIEW v_detection_en_attente AS
SELECT
  e.id, e.foret_id, e.ug_uuid, e.seq, e.date_evenement, e.ndp,
  (e.payload ->> 'nature')::TEXT        AS nature,
  (e.payload ->> 'source')::TEXT        AS source,
  (e.payload ->> 'description')::TEXT   AS description,
  (e.payload ->> 'surface_ha')::NUMERIC AS surface_ha,
  (e.payload ->> 'indice')::NUMERIC     AS indice
FROM v_entree_courante e
WHERE e.registre = 8
  AND (e.payload ->> 'type_entree') = 'detection';

CREATE OR REPLACE VIEW v_tableau_chasse AS
SELECT
  e.id,
  e.foret_id,
  e.seq,
  e.date_evenement,
  (e.payload ->> 'saison')::TEXT      AS saison,
  (e.payload ->> 'espece')::TEXT      AS espece,
  (e.payload ->> 'classe_age')::TEXT  AS classe_age,
  (e.payload ->> 'sexe')::TEXT        AS sexe,
  (e.payload ->> 'nombre')::INTEGER   AS nombre,
  (e.payload ->> 'attribue')::INTEGER AS attribue
FROM v_entree_courante e
WHERE e.registre = 8
  AND (e.payload ->> 'type_entree') = 'tableau_chasse';

COMMENT ON VIEW v_tableau_chasse IS
  'Imprime A50L. La matrice especes x saisons se reconstitue par requete : '
  'le registre s''ecrit ligne a ligne, comme tout registre append-only.';

CREATE OR REPLACE VIEW v_equilibre_gibier AS
SELECT
  e.id,
  e.foret_id,
  e.ug_uuid,
  e.seq,
  e.date_evenement,
  (e.payload ->> 'saison')::TEXT                  AS saison,
  (e.payload ->> 'surface_sensible_ha')::NUMERIC  AS surface_sensible_ha,
  (e.payload ->> 'taux_abroutissement_pct')::NUMERIC AS taux_abroutissement_pct,
  (e.payload ->> 'methode')::TEXT                 AS methode,
  (e.payload ->> 'diagnostic')::TEXT              AS diagnostic
FROM v_entree_courante e
WHERE e.registre = 8
  AND (e.payload ->> 'type_entree') = 'equilibre_gibier';

COMMENT ON VIEW v_equilibre_gibier IS
  'Equilibre foret-gibier, obligatoire en PSG depuis la LAAAF de 2014. '
  'Alimente la famille R (r4_abroutissement) de nemeton.';
