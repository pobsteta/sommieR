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
