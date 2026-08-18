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
  (e.payload ->> 'observations')::TEXT         AS observations
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
  (e.payload ->> 'beneficiaire')::TEXT             AS beneficiaire
FROM v_entree_courante e
WHERE e.registre = 2;

COMMENT ON VIEW v_foncier IS 'Imprime A40 et actes fonciers.';

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
  (e.payload ->> 'mode_partage')::TEXT    AS mode_partage
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
  (e.payload ->> 'etat')::TEXT               AS etat
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
  (e.payload ->> 'etat_conservation')::TEXT AS etat_conservation
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
