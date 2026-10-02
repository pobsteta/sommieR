-- =====================================================================
-- sommieR — vues de consultation (v0.1.0)
--
-- « La balance A50E est une vue calculee, pas une saisie » (brief, s.4).
-- Rien de ce qui suit n'est stocke : tout se deduit du registre, ce qui
-- garantit que le constate affiche est bien celui que la chaine couvre.
-- =====================================================================

-- Chaque vue metier porte trois colonnes de provenance : `repris`,
-- `reprise_source` et `reprise_reference`. Elles disent si la ligne a ete
-- CONSTATEE ou TRANSCRITE d'une piece anterieure au sommier, et de laquelle.
-- Sans elles, un tableau melerait la recopie et la mesure sans le dire ; le
-- bloc lui-meme vit dans le payload, donc dans l'empreinte (voir
-- sommier_reprise() cote R). A ne pas confondre avec `taux_reprise_pct` du
-- registre 6, qui mesure la reprise des plants apres une plantation : meme
-- mot, deux choses.

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

-- La surface d'un martelage est, par defaut, celle de son unite de gestion :
-- un martelage parcourt l'unite. Elle se deduit a la lecture - du contour en
-- vigueur a la date du martelage, a defaut du dernier connu - et n'entre pas
-- dans la chaine : une surface deduite n'a pas a passer pour une surface
-- saisie. `surface_source` dit laquelle s'applique. Une coupe realisee ou un
-- produit accidentel ne parcourt pas forcement toute l'unite : ils gardent la
-- surface saisie, ou aucune.
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
  COALESCE(
    (e.payload ->> 'surface_ha')::NUMERIC,
    CASE WHEN e.payload ->> 'type_entree' = 'martelage'
         THEN unite.surface_ha END
  )::NUMERIC                                      AS surface_ha,
  (e.payload ->> 'essence')::TEXT                 AS essence,
  (e.payload ->> 'coupon')::TEXT                  AS coupon,
  (e.payload ->> 'observations')::TEXT            AS observations,
  jsonb_exists(e.payload, 'reprise')          AS repris,
  (e.payload -> 'reprise' ->> 'source')       AS reprise_source,
  (e.payload -> 'reprise' ->> 'reference')    AS reprise_reference,
  CASE
    WHEN e.payload ? 'surface_ha' THEN 'saisie'
    WHEN e.payload ->> 'type_entree' = 'martelage'
         AND unite.surface_ha IS NOT NULL THEN 'unite'
  END                                          AS surface_source,
  -- v0.25.0 : le constat de terrain dont la coupe procede (un produit
  -- accidentel apres une detection confirmee). En fin de liste : CREATE OR
  -- REPLACE n'accepte une colonne nouvelle qu'apres les autres.
  (e.payload ->> 'constat_id')::UUID           AS constat_id
FROM v_entree_courante e
LEFT JOIN LATERAL (
  SELECT (ST_Area(g.geom) / 10000)::NUMERIC AS surface_ha
    FROM ug_geometrie g
   WHERE g.ug_uuid = e.ug_uuid
   ORDER BY (g.date_debut <= e.date_evenement
             AND (g.date_fin IS NULL OR g.date_fin >= e.date_evenement)) DESC,
            g.version DESC
   LIMIT 1
) unite ON TRUE
WHERE e.registre = 5;

-- Amenagements (v0.19.0) : la periode et la possibilite entrent dans la
-- chaine avec l'acte qui les fixe (registre 1). Un avenant change la
-- possibilite a partir d'un exercice, ou la fin de l'amenagement ; il ne
-- recrit pas le passe.
--
-- Les vues de ce bloc sont supprimees puis recreees, des dependantes aux
-- sources : `v_balance_possibilite` change de colonnes avec la v0.19.0, et
-- `CREATE OR REPLACE` ne permet pas de changer les colonnes d'une vue
-- existante. Aucune autre vue n'en depend.
DROP VIEW IF EXISTS v_martelage_hors_amenagement;
DROP VIEW IF EXISTS v_balance_possibilite;
DROP VIEW IF EXISTS v_possibilite_exercice;
DROP VIEW IF EXISTS v_amenagement;
DROP VIEW IF EXISTS v_amenagement_acte;

CREATE VIEW v_amenagement_acte AS
SELECT
  e.id                                                   AS acte_id,
  e.foret_id, e.seq, e.date_evenement,
  (e.payload ->> 'type_validation')::TEXT                AS type_validation,
  (e.payload ->> 'reference')::TEXT                      AS reference,
  (e.payload -> 'amenagement' ->> 'id')::TEXT            AS amenagement_id,
  (e.payload -> 'amenagement' ->> 'libelle')::TEXT       AS libelle,
  (e.payload -> 'amenagement' ->> 'annee_debut')::INTEGER AS annee_debut,
  (e.payload -> 'amenagement' ->> 'annee_fin')::INTEGER   AS annee_fin,
  (e.payload -> 'amenagement' ->> 'a_partir_de')::INTEGER AS a_partir_de,
  (e.payload -> 'amenagement' ->> 'possibilite_m3_ha_an')::NUMERIC
                                                         AS possibilite_m3_ha_an,
  (e.payload -> 'amenagement' -> 'ventilation')          AS ventilation,
  (e.payload -> 'amenagement' ->> 'surface_ha')::NUMERIC AS surface_ha,
  (e.payload -> 'amenagement' ->> 'serie')::TEXT         AS serie,
  (e.payload -> 'amenagement' ->> 'tolerance_ans')::INTEGER AS tolerance_ans,
  (e.payload -> 'amenagement' ->> 'source')::TEXT        AS source,
  COALESCE(e.payload -> 'amenagement' ->> 'nature_volume', 'possibilite')
                                                         AS nature_volume,
  (e.payload -> 'amenagement' -> 'groupes')              AS groupes,
  (e.payload -> 'amenagement' ->> 'surface_regeneration_ha')::NUMERIC
                                                         AS surface_regeneration_ha,
  jsonb_exists(e.payload, 'reprise')                     AS repris
FROM v_entree_courante e
WHERE e.registre = 1 AND e.payload ? 'amenagement';

COMMENT ON VIEW v_amenagement_acte IS
  'Actes du registre 1 qui portent un amenagement : arretes, agrements, avenants.';

-- Un amenagement, et sa fin telle que le dernier avenant l'a fixee.
CREATE VIEW v_amenagement AS
SELECT
  a.foret_id, a.amenagement_id, a.libelle, a.annee_debut,
  COALESCE((
    SELECT v.annee_fin FROM v_amenagement_acte v
     WHERE v.foret_id = a.foret_id AND v.amenagement_id = a.amenagement_id
       AND v.type_validation = 'avenant' AND v.annee_fin IS NOT NULL
     ORDER BY v.seq DESC LIMIT 1
  ), a.annee_fin)                                        AS annee_fin,
  a.annee_fin                                            AS annee_fin_initiale,
  a.possibilite_m3_ha_an                                 AS possibilite_initiale_m3_ha_an,
  a.surface_ha                                           AS surface_initiale_ha,
  a.possibilite_m3_ha_an * a.surface_ha                  AS possibilite_initiale_m3_an,
  a.ventilation, a.serie, a.tolerance_ans, a.source,
  a.nature_volume, a.groupes,
  COALESCE((
    SELECT v.surface_regeneration_ha FROM v_amenagement_acte v
     WHERE v.foret_id = a.foret_id AND v.amenagement_id = a.amenagement_id
       AND v.type_validation = 'avenant'
       AND v.surface_regeneration_ha IS NOT NULL
     ORDER BY v.seq DESC LIMIT 1
  ), a.surface_regeneration_ha)                          AS surface_regeneration_ha,
  a.reference, a.type_validation, a.acte_id, a.seq,
  a.date_evenement                                       AS date_acte,
  a.repris
FROM v_amenagement_acte a
WHERE a.type_validation IN ('arrete', 'agrement');

COMMENT ON VIEW v_amenagement IS
  'Amenagements et PSG, avec la fin fixee par le dernier avenant.';

-- La possibilite de chaque exercice, et l'acte dont elle vient : le dernier
-- avenant applicable a cet exercice, sinon l'acte d'amenagement. Le taux a
-- l'hectare et la surface se suivent separement - un avenant peut changer
-- l'un sans l'autre -, et le volume annuel s'en deduit.
CREATE VIEW v_possibilite_exercice AS
SELECT
  m.foret_id, m.amenagement_id, m.libelle, g.exercice,
  COALESCE(taux.possibilite_m3_ha_an, m.possibilite_initiale_m3_ha_an)
                                                         AS possibilite_m3_ha_an,
  COALESCE(surf.surface_ha, m.surface_initiale_ha)       AS surface_ha,
  COALESCE(taux.possibilite_m3_ha_an, m.possibilite_initiale_m3_ha_an)
    * COALESCE(surf.surface_ha, m.surface_initiale_ha)   AS possibilite_m3_an,
  COALESCE(taux.acte_id, surf.acte_id, m.acte_id)        AS acte_id,
  COALESCE(taux.reference, surf.reference, m.reference)  AS reference_acte,
  (taux.acte_id IS NOT NULL OR surf.acte_id IS NOT NULL) AS par_avenant,
  m.tolerance_ans,
  m.nature_volume
FROM v_amenagement m
CROSS JOIN LATERAL generate_series(m.annee_debut, m.annee_fin) AS g(exercice)
LEFT JOIN LATERAL (
  SELECT v.possibilite_m3_ha_an, v.acte_id, v.reference
    FROM v_amenagement_acte v
   WHERE v.foret_id = m.foret_id AND v.amenagement_id = m.amenagement_id
     AND v.type_validation = 'avenant' AND v.possibilite_m3_ha_an IS NOT NULL
     AND v.a_partir_de <= g.exercice
   ORDER BY v.a_partir_de DESC, v.seq DESC
   LIMIT 1
) taux ON TRUE
LEFT JOIN LATERAL (
  SELECT v.surface_ha, v.acte_id, v.reference
    FROM v_amenagement_acte v
   WHERE v.foret_id = m.foret_id AND v.amenagement_id = m.amenagement_id
     AND v.type_validation = 'avenant' AND v.surface_ha IS NOT NULL
     AND v.a_partir_de <= g.exercice
   ORDER BY v.a_partir_de DESC, v.seq DESC
   LIMIT 1
) surf ON TRUE;

COMMENT ON VIEW v_possibilite_exercice IS
  'Possibilite en vigueur pour chaque exercice d''un amenagement, et l''acte qui la fixe.';

-- La balance se calcule par amenagement : le cumul repart de zero avec
-- chaque nouvel amenagement. Elle court jusqu'a l'exercice courant - un
-- exercice futur de l'amenagement ne pese pas encore - sauf si un martelage
-- y est deja impute.
--
-- Le socle part des exercices de l'amenagement et non des coupes : un
-- exercice sans aucune coupe pese pour un deficit egal a toute sa
-- possibilite, il ne doit pas disparaitre de la balance cumulee.
--
-- `coupe_realisee` est exclu du martele : la meme coupe est d'abord martelee
-- (A50E) puis exploitee (A50F), l'imputer deux fois doublerait le
-- prelevement constate.
CREATE VIEW v_balance_possibilite AS
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
    p.foret_id, p.amenagement_id, p.libelle, p.exercice,
    p.possibilite_m3_ha_an, p.surface_ha, p.possibilite_m3_an,
    p.reference_acte, p.acte_id, p.par_avenant,
    p.tolerance_ans, p.nature_volume,
    COALESCE(m.volume_martele_m3, 0)          AS volume_martele_m3,
    COALESCE(m.volume_realise_m3, 0)          AS volume_realise_m3
  FROM v_possibilite_exercice p
  LEFT JOIN martele m
    ON m.foret_id = p.foret_id AND m.exercice = p.exercice
  WHERE p.exercice <= EXTRACT(YEAR FROM CURRENT_DATE)
     OR m.volume_martele_m3 IS NOT NULL
)
SELECT
  s.foret_id,
  s.amenagement_id,
  s.libelle                                            AS amenagement,
  s.exercice,
  s.possibilite_m3_ha_an,
  s.surface_ha,
  s.possibilite_m3_an,
  s.volume_martele_m3,
  s.volume_martele_m3 / NULLIF(s.surface_ha, 0)        AS prelevement_m3_ha,
  s.volume_realise_m3,
  s.volume_martele_m3 - COALESCE(s.possibilite_m3_an, 0) AS balance_exercice_m3,
  SUM(s.volume_martele_m3 - COALESCE(s.possibilite_m3_an, 0))
    OVER (PARTITION BY s.foret_id, s.amenagement_id ORDER BY s.exercice
          ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS balance_cumulee_m3,
  s.reference_acte,
  s.acte_id,
  s.par_avenant,
  s.tolerance_ans,
  s.nature_volume
FROM socle s
ORDER BY s.foret_id, s.exercice;

COMMENT ON VIEW v_balance_possibilite IS
  'Imprime A50E, par amenagement. Possibilite en m3/ha/an sur une surface, '
  'volume annuel deduit. Balance positive = exces de prelevement '
  'sur la possibilite, negative = deficit. Le cumul repart de zero avec '
  'chaque amenagement. En foret privee, la possibilite tient lieu de '
  'programme PSG et la tolerance de conformite est de +/- 4 ans.';

-- Ce qui ne se compare a rien : un prelevement impute a un exercice
-- qu'aucun amenagement ne couvre. Il n'est pas perdu, il est montre a part.
CREATE VIEW v_martelage_hors_amenagement AS
SELECT c.*
FROM v_coupe c
WHERE c.type_entree IN ('martelage', 'produit_accidentel', 'bois_delivre')
  AND NOT EXISTS (
    SELECT 1 FROM v_possibilite_exercice p
     WHERE p.foret_id = c.foret_id AND p.exercice = c.exercice
  );

COMMENT ON VIEW v_martelage_hors_amenagement IS
  'Martelages imputes a un exercice qu''aucun amenagement ne couvre.';

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
  (e.ug_uuid IS NULL)                         AS hors_unite_gestion,
  jsonb_exists(e.payload, 'reprise')          AS repris,
  (e.payload -> 'reprise' ->> 'source')       AS reprise_source,
  (e.payload -> 'reprise' ->> 'reference')    AS reprise_reference
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
  (e.payload ->> 'observations')::TEXT    AS observations,
  jsonb_exists(e.payload, 'reprise')          AS repris,
  (e.payload -> 'reprise' ->> 'source')       AS reprise_source,
  (e.payload -> 'reprise' ->> 'reference')    AS reprise_reference
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
  (e.payload ->> 'observations')::TEXT      AS observations,
  jsonb_exists(e.payload, 'reprise')          AS repris,
  (e.payload -> 'reprise' ->> 'source')       AS reprise_source,
  (e.payload -> 'reprise' ->> 'reference')    AS reprise_reference
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

-- ---------------------------------------------------------------------
-- Registre 7 - comptabilite (imprime A50G)
-- ---------------------------------------------------------------------

CREATE OR REPLACE VIEW v_comptabilite AS
SELECT
  e.id,
  e.foret_id,
  e.seq,
  e.date_evenement,
  e.auteur,
  (e.payload ->> 'exercice')::INTEGER          AS exercice,
  (e.payload ->> 'poste')::TEXT                AS poste,
  (e.payload ->> 'sens')::TEXT                 AS sens,
  (e.payload ->> 'rubrique')::TEXT             AS rubrique,
  (e.payload ->> 'montant_eur')::NUMERIC       AS montant_eur,
  (e.payload ->> 'libelle')::TEXT              AS libelle,
  (e.payload ->> 'quantite')::NUMERIC          AS quantite,
  (e.payload ->> 'unite')::TEXT                AS unite,
  (e.payload ->> 'reference')::TEXT            AS reference,
  (e.payload ->> 'dispositif_fiscal')::TEXT    AS dispositif_fiscal,
  (e.payload ->> 'observations')::TEXT         AS observations,
  jsonb_exists(e.payload, 'reprise')          AS repris,
  (e.payload -> 'reprise' ->> 'source')       AS reprise_source,
  (e.payload -> 'reprise' ->> 'reference')    AS reprise_reference
FROM v_entree_courante e
WHERE e.registre = 7;

COMMENT ON VIEW v_comptabilite IS
  'Imprime A50G. `tiers` n''est volontairement pas expose ici : c''est une '
  'donnee a caractere personnel, qui reste lisible dans le payload pour qui '
  'en a besoin mais ne se diffuse pas par la vue de consultation courante.';

-- Bilan financier par exercice : recettes, depenses, solde, et cumul.
-- Meme mecanique que la balance A50E, sur les euros plutot que sur les m3.
CREATE OR REPLACE VIEW v_bilan_financier AS
WITH par_exercice AS (
  SELECT
    c.foret_id,
    c.exercice,
    COALESCE(SUM(c.montant_eur) FILTER (WHERE c.sens = 'recette'), 0) AS recettes_eur,
    COALESCE(SUM(c.montant_eur) FILTER (WHERE c.sens = 'depense'), 0) AS depenses_eur,
    COALESCE(SUM(c.montant_eur) FILTER (WHERE c.rubrique = 'travaux_entretien'), 0) AS travaux_entretien_eur,
    COALESCE(SUM(c.montant_eur) FILTER (WHERE c.rubrique = 'travaux_neufs'), 0) AS travaux_neufs_eur,
    COALESCE(SUM(c.montant_eur) FILTER (WHERE c.rubrique = 'autres_frais'), 0) AS autres_frais_eur,
    COALESCE(SUM(c.montant_eur) FILTER (WHERE c.poste = 'bois_delivres'), 0) AS bois_delivres_eur
  FROM v_comptabilite c
  GROUP BY c.foret_id, c.exercice
)
SELECT
  p.foret_id,
  p.exercice,
  p.recettes_eur,
  p.depenses_eur,
  p.travaux_entretien_eur,
  p.travaux_neufs_eur,
  p.autres_frais_eur,
  p.bois_delivres_eur,
  p.recettes_eur - p.depenses_eur AS solde_eur,
  SUM(p.recettes_eur - p.depenses_eur)
    OVER (PARTITION BY p.foret_id ORDER BY p.exercice
          ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS solde_cumule_eur
FROM par_exercice p
ORDER BY p.foret_id, p.exercice;

COMMENT ON VIEW v_bilan_financier IS
  'Bilan financier de l''imprime A50G. Solde positif = excedent. '
  'bois_delivres_eur isole l''affouage, propre a la foret communale.';

-- Execution budgetaire : realise (registre 7) confronte au previsionnel
-- (budget_previsionnel), poste par poste.
--
-- FULL JOIN et non LEFT JOIN : un poste budgete mais jamais execute est une
-- information de gestion au moins aussi utile qu'un depassement, et un poste
-- execute hors budget doit apparaitre plutot que disparaitre.
CREATE OR REPLACE VIEW v_execution_budgetaire AS
WITH realise AS (
  SELECT c.foret_id, c.exercice, c.poste, SUM(c.montant_eur) AS realise_eur
  FROM v_comptabilite c
  GROUP BY c.foret_id, c.exercice, c.poste
)
SELECT
  COALESCE(r.foret_id, b.foret_id)   AS foret_id,
  COALESCE(r.exercice, b.annee)      AS exercice,
  COALESCE(r.poste, b.poste)         AS poste,
  COALESCE(b.montant_eur, 0)         AS prevu_eur,
  COALESCE(r.realise_eur, 0)         AS realise_eur,
  COALESCE(r.realise_eur, 0) - COALESCE(b.montant_eur, 0) AS ecart_eur,
  CASE
    WHEN COALESCE(b.montant_eur, 0) = 0 THEN NULL
    ELSE ROUND(100 * COALESCE(r.realise_eur, 0) / b.montant_eur, 1)
  END                                AS execution_pct
FROM realise r
FULL JOIN budget_previsionnel b
  ON b.foret_id = r.foret_id AND b.annee = r.exercice AND b.poste = r.poste
ORDER BY 1, 2, 3;

COMMENT ON VIEW v_execution_budgetaire IS
  'Realise confronte au previsionnel. execution_pct vaut NULL lorsque rien '
  'n''etait budgete : un taux d''execution sur une base nulle n''a pas de sens, '
  'et l''ecart en euros le dit deja.';

-- ---------------------------------------------------------------------
-- Registres 2, 3, 4 et 9 (v0.4.0)
-- ---------------------------------------------------------------------

CREATE OR REPLACE VIEW v_foncier AS
SELECT
  e.id, e.foret_id, e.ug_uuid, e.seq, e.date_evenement, e.auteur,
  (e.payload ->> 'type_entree')::TEXT              AS type_entree,
  (e.payload ->> 'description')::TEXT              AS description,
  (e.payload ->> 'cout_total_eur')::NUMERIC        AS cout_total_eur,
  (e.payload ->> 'charge_proprietaire_eur')::NUMERIC AS charge_proprietaire_eur,
  (e.payload ->> 'charge_riverains_eur')::NUMERIC  AS charge_riverains_eur,
  (e.payload ->> 'nb_bornes')::INTEGER             AS nb_bornes,
  (e.payload ->> 'surface_ha')::NUMERIC            AS surface_ha,
  (e.payload ->> 'reference_acte')::TEXT           AS reference_acte,
  (e.payload ->> 'beneficiaire')::TEXT             AS beneficiaire,
  jsonb_exists(e.payload, 'reprise')          AS repris,
  (e.payload -> 'reprise' ->> 'source')       AS reprise_source,
  (e.payload -> 'reprise' ->> 'reference')    AS reprise_reference
FROM v_entree_courante e
WHERE e.registre = 2;

COMMENT ON VIEW v_foncier IS 'Imprime A40 et actes fonciers.';

-- Reconnaissances de limite (v0.16.0) : un constat de terrain par element du
-- plan cadastral, photo a l'appui. L'element est recopie dans le payload tel
-- que l'agent l'a vu ; les photos n'y sont que par leur empreinte.
CREATE OR REPLACE VIEW v_reconnaissance_limite AS
SELECT
  e.id, e.foret_id, e.ug_uuid, e.seq, e.date_evenement, e.date_saisie,
  e.auteur,
  (e.payload ->> 'etat')::TEXT                       AS etat,
  (e.payload -> 'element_pci' ->> 'id')::TEXT        AS element_id,
  (e.payload -> 'element_pci' ->> 'numero')::TEXT    AS element_numero,
  (e.payload -> 'element_pci' ->> 'categorie')::TEXT AS element_categorie,
  (e.payload -> 'element_pci' ->> 'x')::NUMERIC      AS element_x,
  (e.payload -> 'element_pci' ->> 'y')::NUMERIC      AS element_y,
  (e.payload ->> 'visite_le')::TIMESTAMPTZ           AS visite_le,
  (e.payload ->> 'operateur')::TEXT                  AS operateur,
  (e.payload ->> 'precision_m')::NUMERIC             AS precision_m,
  (e.payload ->> 'source_gnss')::TEXT                AS source_gnss,
  (e.payload ->> 'releve_uuid')::TEXT                AS releve_uuid,
  coalesce(jsonb_array_length(e.payload -> 'photos'), 0) AS nb_photos,
  (e.payload ->> 'observations')::TEXT               AS observations,
  e.geom
FROM v_entree_courante e
WHERE e.registre = 2
  AND e.payload ->> 'type_entree' = 'reconnaissance_limite';

COMMENT ON VIEW v_reconnaissance_limite IS
  'Constats de terrain sur les elements de limite du plan cadastral.';

-- La derniere visite de chaque element : c'est la question que pose le
-- suivi des limites - quand cette borne a-t-elle ete vue pour la derniere
-- fois, et dans quel etat. Les elements hors plan n'ont pas d'identifiant
-- et ne s'y agregent pas.
CREATE OR REPLACE VIEW v_reconnaissance_derniere AS
SELECT DISTINCT ON (r.foret_id, r.element_id) r.*
FROM v_reconnaissance_limite r
WHERE r.element_id IS NOT NULL
ORDER BY r.foret_id, r.element_id, r.date_evenement DESC, r.seq DESC;

COMMENT ON VIEW v_reconnaissance_derniere IS
  'Derniere reconnaissance de chaque element du plan cadastral.';

-- `titulaire` et `garants` ne sont pas exposes : donnees a caractere
-- personnel, comme `tiers` au registre 7.
CREATE OR REPLACE VIEW v_droit AS
SELECT
  e.id, e.foret_id, e.ug_uuid, e.seq, e.date_evenement, e.auteur,
  (e.payload ->> 'type_entree')::TEXT     AS type_entree,
  (e.payload ->> 'numero')::TEXT          AS numero,
  (e.payload ->> 'nature')::TEXT          AS nature,
  (e.payload ->> 'date_debut')::DATE      AS date_debut,
  (e.payload ->> 'date_expiration')::DATE AS date_expiration,
  (e.payload ->> 'redevance_eur')::NUMERIC AS redevance_eur,
  (e.payload ->> 'surface_ha')::NUMERIC   AS surface_ha,
  (e.payload ->> 'campagne')::TEXT        AS campagne,
  (e.payload ->> 'nb_affouagistes')::INTEGER AS nb_affouagistes,
  (e.payload ->> 'volume_m3')::NUMERIC    AS volume_m3,
  (e.payload ->> 'taxe_eur')::NUMERIC     AS taxe_eur,
  (e.payload ->> 'mode_partage')::TEXT    AS mode_partage,
  jsonb_exists(e.payload, 'reprise')          AS repris,
  (e.payload -> 'reprise' ->> 'source')       AS reprise_source,
  (e.payload -> 'reprise' ->> 'reference')    AS reprise_reference
FROM v_entree_courante e
WHERE e.registre = 3;

COMMENT ON VIEW v_droit IS
  'Imprime A50C, affouage compris. `titulaire` et `garants` sont volontairement '
  'absents : donnees a caractere personnel, lisibles dans le payload pour qui '
  'en a besoin mais non diffusees par la vue courante.';

-- Droits en vigueur a une date donnee. Une concession expiree sort de la
-- liste sans sortir du registre : c'est bien la meme logique que la
-- rectification, appliquee au temps plutot qu'a l'erreur.
CREATE OR REPLACE VIEW v_droit_en_vigueur AS
SELECT d.*
FROM v_droit d
WHERE d.date_debut <= CURRENT_DATE
  AND (d.date_expiration IS NULL OR d.date_expiration >= CURRENT_DATE);

CREATE OR REPLACE VIEW v_infrastructure AS
SELECT
  e.id, e.foret_id, e.seq, e.date_evenement, e.auteur,
  (e.payload ->> 'type_entree')::TEXT        AS type_entree,
  (e.payload ->> 'nom')::TEXT                AS nom,
  (e.payload ->> 'nature')::TEXT             AS nature,
  (e.payload ->> 'revetement')::TEXT         AS revetement,
  (e.payload ->> 'longueur_m')::NUMERIC      AS longueur_m,
  (e.payload ->> 'largeur_chaussee_m')::NUMERIC AS largeur_chaussee_m,
  (e.payload ->> 'usage')::TEXT              AS usage,
  (e.payload ->> 'ouverte_public')::BOOLEAN  AS ouverte_public,
  (e.payload ->> 'voirie_publique')::BOOLEAN AS voirie_publique,
  (e.payload ->> 'capacite')::NUMERIC        AS capacite,
  (e.payload ->> 'unite')::TEXT              AS unite,
  (e.payload ->> 'etat')::TEXT               AS etat,
  jsonb_exists(e.payload, 'reprise')          AS repris,
  (e.payload -> 'reprise' ->> 'source')       AS reprise_source,
  (e.payload -> 'reprise' ->> 'reference')    AS reprise_reference
FROM v_entree_courante e
WHERE e.registre = 4;

-- Densites de l'imprime A50D, en km pour 100 hectares. Seule la voirie
-- PRIVEE forestiere entre au numerateur : l'imprime distingue les deux, et
-- une route departementale traversant la foret ne dit rien de sa desserte.
CREATE OR REPLACE VIEW v_densite_voirie AS
SELECT
  f.id                                    AS foret_id,
  f.surface_ha,
  i.revetement,
  SUM(i.longueur_m) / 1000.0              AS longueur_km,
  CASE
    WHEN f.surface_ha IS NULL OR f.surface_ha = 0 THEN NULL
    ELSE ROUND((SUM(i.longueur_m) / 1000.0) / (f.surface_ha / 100.0), 2)
  END                                     AS densite_km_100ha
FROM foret f
JOIN v_infrastructure i ON i.foret_id = f.id
WHERE i.type_entree = 'voirie'
  AND COALESCE(i.voirie_publique, FALSE) = FALSE
GROUP BY f.id, f.surface_ha, i.revetement
ORDER BY f.id, i.revetement;

COMMENT ON VIEW v_densite_voirie IS
  'Imprime A50D. densite_km_100ha vaut NULL si la surface de la foret est '
  'inconnue : une densite sans denominateur serait inventee.';

CREATE OR REPLACE VIEW v_remarquable AS
SELECT
  e.id, e.foret_id, e.ug_uuid, e.seq, e.date_evenement, e.auteur,
  (e.payload ->> 'type_fiche')::TEXT        AS type_fiche,
  (e.payload ->> 'appellation')::TEXT       AS appellation,
  (e.payload ->> 'essence')::TEXT           AS essence,
  (e.payload ->> 'interet')::TEXT           AS interet,
  (e.payload ->> 'age_ans')::INTEGER        AS age_ans,
  (e.payload ->> 'circonference_cm')::NUMERIC AS circonference_cm,
  (e.payload ->> 'hauteur_m')::NUMERIC      AS hauteur_m,
  (e.payload ->> 'etat_sanitaire')::TEXT    AS etat_sanitaire,
  (e.payload ->> 'surface_ha')::NUMERIC     AS surface_ha,
  (e.payload ->> 'nom_francais')::TEXT      AS nom_francais,
  (e.payload ->> 'nom_latin')::TEXT         AS nom_latin,
  (e.payload ->> 'statut_protection')::TEXT AS statut_protection,
  (e.payload ->> 'effectif')::INTEGER       AS effectif,
  (e.payload ->> 'type_habitat')::TEXT      AS type_habitat,
  (e.payload ->> 'code_natura2000')::TEXT   AS code_natura2000,
  (e.payload ->> 'etat_conservation')::TEXT AS etat_conservation,
  jsonb_exists(e.payload, 'reprise')          AS repris,
  (e.payload -> 'reprise' ->> 'source')       AS reprise_source,
  (e.payload -> 'reprise' ->> 'reference')    AS reprise_reference
FROM v_entree_courante e
WHERE e.registre = 9;

COMMENT ON VIEW v_remarquable IS
  'Serie A50 r/*. Un sujet revisite donne une entree de plus portant la meme '
  'appellation : la serie de mesures se reconstitue par requete, rien n''est '
  'ecrase.';

-- Dernier releve connu de chaque sujet remarquable nomme.
CREATE OR REPLACE VIEW v_remarquable_dernier_releve AS
SELECT DISTINCT ON (r.foret_id, r.type_fiche, COALESCE(r.appellation, r.nom_latin, r.type_habitat))
  r.*
FROM v_remarquable r
ORDER BY r.foret_id, r.type_fiche,
         COALESCE(r.appellation, r.nom_latin, r.type_habitat),
         r.date_evenement DESC, r.seq DESC;

-- ---------------------------------------------------------------------
-- Objets localises (colonne `geom`, posee par 003_geometrie.sql)
-- ---------------------------------------------------------------------

-- Les objets localises, tous registres confondus : ce que le sommier sait
-- placer sur une carte.
CREATE OR REPLACE VIEW v_objet_localise AS
SELECT
  e.id,
  e.foret_id,
  e.ug_uuid,
  e.registre,
  e.seq,
  e.date_evenement,
  e.auteur,
  e.ndp,
  coalesce(
    e.payload ->> 'appellation',
    e.payload ->> 'nom',
    e.payload ->> 'nom_francais',
    e.payload ->> 'type_habitat',
    e.payload ->> 'nature',
    e.payload ->> 'nature_coupe',
    e.payload ->> 'description',
    e.payload ->> 'type_entree'
  )                                        AS designation,
  coalesce(
    e.payload ->> 'type_fiche',
    e.payload ->> 'type_entree'
  )                                        AS type_objet,
  ST_GeometryType(e.geom)                  AS type_geometrie,
  e.geom,
  jsonb_exists(e.payload, 'reprise')          AS repris,
  (e.payload -> 'reprise' ->> 'source')       AS reprise_source,
  (e.payload -> 'reprise' ->> 'reference')    AS reprise_reference
FROM v_entree_courante e
WHERE e.geom IS NOT NULL;

COMMENT ON VIEW v_objet_localise IS
  'Entrees portant une geometrie, tous registres confondus. `designation` '
  'prend le premier libelle disponible : les registres ne nomment pas '
  'leurs objets de la meme facon, une carte les nomme toutes pareil. Le '
  'repli final sur type_entree evite l''objet sans nom : un trait sans '
  'etiquette sur une carte est pire qu''un nom approximatif.';
