-- =====================================================================
-- sommieR — le certificat du signataire, au visa (v0.10.0)
--
-- Le jeton d'horodatage est autoporteur : l'autorite y inclut son
-- certificat, si bien qu'un tiers n'a besoin que d'une ancre de
-- confiance pour le verifier. Le visa, lui, ne l'etait pas. Le manifeste
-- emportait la signature JWS et les claims, jamais la cle publique — et
-- les cles sont fournies par l'appelant, delibrement pas cherchees au
-- JWKS, pour qu'un visa reste verifiable des annees plus tard, hors
-- ligne. La decision est juste, mais elle laissait le destinataire d'un
-- export sans rien a quoi confronter la signature.
--
-- La colonne est donc posee ici, et remplie AU MOMENT DE SIGNER, non
-- cherchee au moment de verifier : le certificat fait partie de ce que
-- le visa atteste. Le visa devient autoporteur comme le jeton, et les
-- deux pieces se verifient dans les memes conditions.
--
-- Elle est FACULTATIVE a dessein. Un visa pose avant la v0.10.0 n'en a
-- pas, et le lui inventer apres coup serait ecrire dans un registre
-- append-only ce qui n'y a jamais ete. Ces visas-la gardent le
-- comportement anterieur : cle fournie par l'appelant.
-- =====================================================================

ALTER TABLE visa
  ADD COLUMN IF NOT EXISTS certificat BYTEA;

COMMENT ON COLUMN visa.certificat IS
  'Certificat X.509 du signataire, en DER, enregistre au moment de '
  'signer. Facultatif : les visas anterieurs a la v0.10.0 n''en portent '
  'pas et se verifient avec une cle fournie par l''appelant.';
