-- Unicite du numero de plant dans la placette (mission 057), garantie par la
-- base : la verification applicative (sommier_pointer_plant) lit puis ecrit
-- sans verrou, deux ecritures concurrentes pouvaient donc toutes deux la
-- passer. Ajout seul : rien n'est reecrit, aucune entree n'est touchee.
--
-- Les entrees qui en corrigent une autre (corrige_id) restent hors de l'index :
-- une correction porte le meme numero que l'entree qu'elle remplace.

-- Une base qui porte deja un doublon refuse l'installation, sans rien
-- modifier, avec un message qui nomme la placette et le numero.
DO $$
DECLARE
  doublon TEXT;
BEGIN
  SELECT 'placette ' || (payload ->> 'placette_id') || ', numero '
         || (payload ->> 'numero') || ' (' || count(*) || ' plants)'
    INTO doublon
    FROM entree_sommier
   WHERE registre = 6 AND payload ->> 'type_entree' = 'plant'
     AND corrige_id IS NULL
   GROUP BY payload ->> 'placette_id', payload ->> 'numero'
  HAVING count(*) > 1
   LIMIT 1;
  IF doublon IS NOT NULL THEN
    RAISE EXCEPTION
      'Installation refusee : deux plants portent le meme numero dans la '
      'meme placette (%). Rien n''a ete modifie ; corriger l''un des deux '
      'par une entree portant corrige_id, puis relancer l''installation.',
      doublon
      USING ERRCODE = 'unique_violation';
  END IF;
END;
$$ LANGUAGE plpgsql;

CREATE UNIQUE INDEX IF NOT EXISTS plant_numero_par_placette_unique
  ON entree_sommier (((payload ->> 'placette_id')::UUID),
                     ((payload ->> 'numero')::INTEGER))
  WHERE registre = 6 AND payload ->> 'type_entree' = 'plant'
    AND corrige_id IS NULL;
