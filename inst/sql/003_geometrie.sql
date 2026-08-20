-- =====================================================================
-- sommieR — geometrie des entrees (v0.7.0)
--
-- Premier changement de schema du projet. Il n'en est pas moins
-- append-only : rien n'est reecrit, rien n'est efface. On ajoute une
-- colonne DERIVEE du payload, et le payload, lui, est deja chaine.
--
-- La verite est dans `payload -> 'geometrie'`, en WGS84, hachee avec le
-- reste de l'entree. `geom` n'en est qu'une projection en Lambert-93,
-- posee pour l'index spatial et les jointures. Si les deux divergent,
-- c'est le payload qui fait foi — la colonne se reconstruit, l'empreinte
-- non.
-- =====================================================================

ALTER TABLE entree_sommier
  ADD COLUMN IF NOT EXISTS geom geometry(Geometry, 2154);

COMMENT ON COLUMN entree_sommier.geom IS
  'Projection Lambert-93 de payload->''geometrie'' (WGS84), posee par '
  'declencheur. Derivee et hors empreinte : le payload fait foi.';

-- Le calcul est fait par la base et non par l''application : une entree
-- ecrite par un autre client — psql, un ETL, un futur portage — doit
-- porter la meme geometrie derivee, sans quoi l''index mentirait sur une
-- partie du registre.
CREATE OR REPLACE FUNCTION deriver_geometrie() RETURNS trigger AS $$
BEGIN
  IF NEW.payload ? 'geometrie' THEN
    NEW.geom := ST_Transform(
      ST_SetSRID(ST_GeomFromGeoJSON(NEW.payload -> 'geometrie'), 4326),
      2154
    );
  ELSE
    NEW.geom := NULL;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- BEFORE INSERT seulement : il n''y a pas d''UPDATE sur ce registre, le
-- declencheur d''immutabilite s''en charge.
DROP TRIGGER IF EXISTS sommier_geometrie_derivee ON entree_sommier;
CREATE TRIGGER sommier_geometrie_derivee
  BEFORE INSERT ON entree_sommier
  FOR EACH ROW EXECUTE FUNCTION deriver_geometrie();

CREATE INDEX IF NOT EXISTS entree_sommier_geom_idx
  ON entree_sommier USING GIST (geom)
  WHERE geom IS NOT NULL;
