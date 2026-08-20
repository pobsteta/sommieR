# Package index

## Écrire et lire le sommier

Le cycle de vie d’une entrée : construction, chaînage, écriture,
relecture.

- [`sommier_entree()`](https://pobsteta.github.io/sommieR/reference/sommier_entree.md)
  : Construction d'une entree de sommier
- [`sommier_ajouter()`](https://pobsteta.github.io/sommieR/reference/sommier_ajouter.md)
  : Ecriture d'entrees dans le sommier
- [`sommier_lire()`](https://pobsteta.github.io/sommieR/reference/sommier_lire.md)
  : Lecture des entrees d'un sommier
- [`sommier_chainer()`](https://pobsteta.github.io/sommieR/reference/sommier_chainer.md)
  : Chainage d'une suite d'entrees hors base
- [`entrees_en_data_frame()`](https://pobsteta.github.io/sommieR/reference/entrees_en_data_frame.md)
  : Conversion d'entrees en data.frame

## Registres

Les neuf registres du sommier unifié et les constructeurs de payload des
registres ouverts à l’écriture.

- [`SOMMIER_REGISTRES`](https://pobsteta.github.io/sommieR/reference/SOMMIER_REGISTRES.md)
  : Les neuf registres du sommier unifie
- [`SOMMIER_REGISTRES_OUVERTS`](https://pobsteta.github.io/sommieR/reference/SOMMIER_REGISTRES_OUVERTS.md)
  : Registres ouverts a l'ecriture dans cette version
- [`SOMMIER_SCHEMA_VERSIONS`](https://pobsteta.github.io/sommieR/reference/SOMMIER_SCHEMA_VERSIONS.md)
  : Versions de schema des payloads
- [`valider_payload()`](https://pobsteta.github.io/sommieR/reference/valider_payload.md)
  : Validation d'un payload selon son registre

## Registre 1 — validations

Imprimé A10 : visas annuels, arrêtés, délibérations, agréments.

- [`registre1_validation()`](https://pobsteta.github.io/sommieR/reference/registre1_validation.md)
  : Payload du registre 1 - validations
- [`SOMMIER_TYPES_VALIDATION`](https://pobsteta.github.io/sommieR/reference/SOMMIER_TYPES_VALIDATION.md)
  : Types d'acte du registre 1
- [`SOMMIER_AUTORITES`](https://pobsteta.github.io/sommieR/reference/SOMMIER_AUTORITES.md)
  : Autorites de validation

## Registre 2 — foncier et limites

Imprimé A40 : délimitation, bornage, acquisitions, servitudes.

- [`registre2_foncier()`](https://pobsteta.github.io/sommieR/reference/registre2_foncier.md)
  : Payload du registre 2 - foncier et limites (imprime A40)
- [`SOMMIER_TYPES_FONCIER`](https://pobsteta.github.io/sommieR/reference/SOMMIER_TYPES_FONCIER.md)
  : Types d'entree du registre 2 (foncier et limites)

## Registre 3 — droits et concessions

Imprimé A50C, et l’affouage propre à la forêt communale.

- [`registre3_droit()`](https://pobsteta.github.io/sommieR/reference/registre3_droit.md)
  : Payload du registre 3 - droits et concessions (imprime A50C)
- [`registre3_affouage()`](https://pobsteta.github.io/sommieR/reference/registre3_affouage.md)
  : Payload du registre 3 - affouage
- [`SOMMIER_TYPES_DROIT`](https://pobsteta.github.io/sommieR/reference/SOMMIER_TYPES_DROIT.md)
  : Types d'entree du registre 3 (droits et concessions)

## Registre 4 — infrastructures

Imprimés A50D et A50D bis, ouvrages DFCI compris.

- [`registre4_voirie()`](https://pobsteta.github.io/sommieR/reference/registre4_voirie.md)
  : Payload du registre 4 - voirie forestiere (imprimes A50D et A50D
  bis)
- [`registre4_equipement()`](https://pobsteta.github.io/sommieR/reference/registre4_equipement.md)
  : Payload du registre 4 - equipement ou ouvrage DFCI
- [`sommier_densite_voirie()`](https://pobsteta.github.io/sommieR/reference/sommier_densite_voirie.md)
  : Densite de la voirie forestiere (imprime A50D)
- [`SOMMIER_TYPES_INFRASTRUCTURE`](https://pobsteta.github.io/sommieR/reference/SOMMIER_TYPES_INFRASTRUCTURE.md)
  : Types d'entree du registre 4 (infrastructures)
- [`SOMMIER_REVETEMENTS`](https://pobsteta.github.io/sommieR/reference/SOMMIER_REVETEMENTS.md)
  : Natures de revetement de la voirie forestiere (imprime A50D)
- [`SOMMIER_USAGES_VOIRIE`](https://pobsteta.github.io/sommieR/reference/SOMMIER_USAGES_VOIRIE.md)
  : Usages de la voirie forestiere (imprime A50D bis)

## Registre 5 — coupes et récoltes

Imprimés A50E, A50F et A50I.

- [`registre5_coupe()`](https://pobsteta.github.io/sommieR/reference/registre5_coupe.md)
  : Payload du registre 5 - coupes et recoltes
- [`SOMMIER_TYPES_COUPE`](https://pobsteta.github.io/sommieR/reference/SOMMIER_TYPES_COUPE.md)
  : Types d'entree du registre 5 (coupes et recoltes)
- [`SOMMIER_TYPES_MARTELES`](https://pobsteta.github.io/sommieR/reference/SOMMIER_TYPES_MARTELES.md)
  : Types d'entree imputables a la balance de possibilite

## Registre 6 — travaux

Imprimés A50J, A50J bis et A50H.

- [`registre6_travaux()`](https://pobsteta.github.io/sommieR/reference/registre6_travaux.md)
  : Payload du registre 6 - travaux

## Registre 7 — comptabilité

Imprimé A50G, budget prévisionnel et bilan financier.

- [`registre7_ecriture()`](https://pobsteta.github.io/sommieR/reference/registre7_ecriture.md)
  : Payload du registre 7 - comptabilite
- [`SOMMIER_POSTES_COMPTABLES`](https://pobsteta.github.io/sommieR/reference/SOMMIER_POSTES_COMPTABLES.md)
  : Postes comptables du registre 7 (imprime A50G)
- [`SOMMIER_DISPOSITIFS_FISCAUX`](https://pobsteta.github.io/sommieR/reference/SOMMIER_DISPOSITIFS_FISCAUX.md)
  : Dispositifs fiscaux de la foret privee
- [`budget_definir()`](https://pobsteta.github.io/sommieR/reference/budget_definir.md)
  : Fixation du budget previsionnel
- [`sommier_bilan_financier()`](https://pobsteta.github.io/sommieR/reference/sommier_bilan_financier.md)
  : Bilan financier (imprime A50G)
- [`sommier_execution_budgetaire()`](https://pobsteta.github.io/sommieR/reference/sommier_execution_budgetaire.md)
  : Execution budgetaire

## Registre 8 — évènements et faune

Imprimés A50K et A50L, équilibre forêt-gibier, et détections issues de
la télédétection.

- [`registre8_phenomene()`](https://pobsteta.github.io/sommieR/reference/registre8_phenomene.md)
  : Payload du registre 8 - phenomene (imprime A50K)
- [`registre8_tableau_chasse()`](https://pobsteta.github.io/sommieR/reference/registre8_tableau_chasse.md)
  : Payload du registre 8 - tableau de chasse (imprime A50L)
- [`registre8_equilibre_gibier()`](https://pobsteta.github.io/sommieR/reference/registre8_equilibre_gibier.md)
  : Payload du registre 8 - equilibre foret-gibier
- [`registre8_detection()`](https://pobsteta.github.io/sommieR/reference/registre8_detection.md)
  : Payload du registre 8 - detection par teledetection
- [`registre8_suite_detection()`](https://pobsteta.github.io/sommieR/reference/registre8_suite_detection.md)
  : Payload du registre 8 - suite donnee a une detection
- [`SOMMIER_TYPES_EVENEMENT`](https://pobsteta.github.io/sommieR/reference/SOMMIER_TYPES_EVENEMENT.md)
  : Types d'entree du registre 8
- [`SOMMIER_NATURES_PHENOMENE`](https://pobsteta.github.io/sommieR/reference/SOMMIER_NATURES_PHENOMENE.md)
  : Natures de phenomene (imprime A50K)
- [`sommier_importer_detections()`](https://pobsteta.github.io/sommieR/reference/sommier_importer_detections.md)
  : Import de detections par teledetection
- [`sommier_valider_detection()`](https://pobsteta.github.io/sommieR/reference/sommier_valider_detection.md)
  : Suite donnee a une detection apres passage sur le terrain

## Registre 9 — patrimoine remarquable

Série A50 r/\* : arbres, peuplements, vestiges, espèces protégées,
habitats — et ce qu’ils apportent à l’IBP.

- [`registre9_arbre()`](https://pobsteta.github.io/sommieR/reference/registre9_arbre.md)
  : Payload du registre 9 - arbre remarquable (imprime A50 r/a)
- [`registre9_peuplement()`](https://pobsteta.github.io/sommieR/reference/registre9_peuplement.md)
  : Payload du registre 9 - peuplement remarquable (imprime A50 r/p)
- [`registre9_vestige()`](https://pobsteta.github.io/sommieR/reference/registre9_vestige.md)
  : Payload du registre 9 - vestige ou element culturel (imprime A50
  r/c)
- [`registre9_espece()`](https://pobsteta.github.io/sommieR/reference/registre9_espece.md)
  : Payload du registre 9 - espece protegee (imprimes A50 r/e et r/s)
- [`registre9_habitat()`](https://pobsteta.github.io/sommieR/reference/registre9_habitat.md)
  : Payload du registre 9 - habitat remarquable (imprime A50 r/h)
- [`sommier_elements_ibp()`](https://pobsteta.github.io/sommieR/reference/sommier_elements_ibp.md)
  : Elements du sommier utiles a l'IBP
- [`SOMMIER_TYPES_REMARQUABLE`](https://pobsteta.github.io/sommieR/reference/SOMMIER_TYPES_REMARQUABLE.md)
  : Types de fiche du patrimoine remarquable (serie A50 r/\*)
- [`SOMMIER_ETATS_SANITAIRES`](https://pobsteta.github.io/sommieR/reference/SOMMIER_ETATS_SANITAIRES.md)
  : Etats sanitaires releves sur un sujet remarquable
- [`SOMMIER_SEUIL_TGB_CM`](https://pobsteta.github.io/sommieR/reference/SOMMIER_SEUIL_TGB_CM.md)
  : Seuil de circonference des tres gros bois

## Jeu de démonstration

Un sommier complet et cohérent sur les neuf registres, pour la prise en
main. Les écritures sont fictives, la géométrie vient de la fixture
Couchey de nemetonshiny.

- [`sommier_demo_couchey()`](https://pobsteta.github.io/sommieR/reference/sommier_demo_couchey.md)
  : Jeu de demonstration : foret communale de Couchey
- [`SOMMIER_PARCELLES_COUCHEY`](https://pobsteta.github.io/sommieR/reference/SOMMIER_PARCELLES_COUCHEY.md)
  : Parcelles du jeu de demonstration
- [`NOM_FORET_DEMO`](https://pobsteta.github.io/sommieR/reference/NOM_FORET_DEMO.md)
  : Nom de la foret du jeu de demonstration

## Exports réglementaires et cartographiques

Le sommier comme source des documents de gestion, et le partage
vérifiable.

- [`sommier_gestion_anterieure()`](https://pobsteta.github.io/sommieR/reference/sommier_gestion_anterieure.md)
  : Gestion anterieure : coupes, travaux, evenements et comptes
- [`sommier_rapport_markdown()`](https://pobsteta.github.io/sommieR/reference/sommier_rapport_markdown.md)
  : Rendu Markdown de la gestion anterieure
- [`SOMMIER_REFERENTIELS`](https://pobsteta.github.io/sommieR/reference/SOMMIER_REFERENTIELS.md)
  : Referentiels d'export de la gestion anterieure
- [`sommier_exporter_sig()`](https://pobsteta.github.io/sommieR/reference/sommier_exporter_sig.md)
  : Export cartographique des unites de gestion
- [`SOMMIER_FORMATS_SIG`](https://pobsteta.github.io/sommieR/reference/SOMMIER_FORMATS_SIG.md)
  : Formats d'export cartographique
- [`SOMMIER_COUCHES_SIG`](https://pobsteta.github.io/sommieR/reference/SOMMIER_COUCHES_SIG.md)
  : Couches d'export cartographique
- [`sommier_rapport_quarto()`](https://pobsteta.github.io/sommieR/reference/sommier_rapport_quarto.md)
  : Rapport de gestion anterieure en Quarto
- [`SOMMIER_FORMATS_QUARTO`](https://pobsteta.github.io/sommieR/reference/SOMMIER_FORMATS_QUARTO.md)
  : Formats de rendu Quarto

## Cartographie

Ce que le sommier sait porter sur une carte : les contours des unités de
gestion, en vigueur à une date, et les indicateurs qui s’y rattachent.

- [`sommier_couche_ug()`](https://pobsteta.github.io/sommieR/reference/sommier_couche_ug.md)
  : Couche cartographique des unites de gestion
- [`sommier_geometrie_ug()`](https://pobsteta.github.io/sommieR/reference/sommier_geometrie_ug.md)
  : Contours des unites de gestion
- [`sommier_indicateurs_ug()`](https://pobsteta.github.io/sommieR/reference/sommier_indicateurs_ug.md)
  : Indicateurs par unite de gestion
- [`sommier_objets_localises()`](https://pobsteta.github.io/sommieR/reference/sommier_objets_localises.md)
  : Objets localises du sommier

## Fond cadastral

Le décor des cartes, et rien de plus : donnée tierce, datée et sourcée,
qui n’entre ni dans un registre ni dans une empreinte.

- [`sommier_fond_cadastral()`](https://pobsteta.github.io/sommieR/reference/sommier_fond_cadastral.md)
  : Fond cadastral d'une commune
- [`sommier_fond_lire()`](https://pobsteta.github.io/sommieR/reference/sommier_fond_lire.md)
  : Lecture d'un fond cadastral
- [`SOMMIER_COUCHES_CADASTRE`](https://pobsteta.github.io/sommieR/reference/SOMMIER_COUCHES_CADASTRE.md)
  : Couches du fond cadastral

## Géométrie des payloads

La géométrie est dans le payload, donc dans l’empreinte : le contour
d’une coupe est aussi opposable que son volume. En WGS84, comme l’exige
la RFC 7946.

- [`geom_point()`](https://pobsteta.github.io/sommieR/reference/geometries.md)
  [`geom_ligne()`](https://pobsteta.github.io/sommieR/reference/geometries.md)
  [`geom_polygone()`](https://pobsteta.github.io/sommieR/reference/geometries.md)
  : Geometries d'un payload
- [`SOMMIER_TYPES_GEOMETRIE`](https://pobsteta.github.io/sommieR/reference/SOMMIER_TYPES_GEOMETRIE.md)
  : Types de geometrie admis dans un payload
- [`SOMMIER_DECIMALES_COORD`](https://pobsteta.github.io/sommieR/reference/SOMMIER_DECIMALES_COORD.md)
  : Nombre de decimales conservees sur une coordonnee
- [`valider_geometrie()`](https://pobsteta.github.io/sommieR/reference/valider_geometrie.md)
  : Valide une geometrie de payload

## Visa signé et horodatage

Ce qui rend le sommier opposable : la signature détachée de la tête de
chaîne, son horodatage qualifié, et leur vérification.

- [`sommier_viser()`](https://pobsteta.github.io/sommieR/reference/sommier_viser.md)
  : Pose d'un visa signe sur la tete de chaine
- [`sommier_ancrer()`](https://pobsteta.github.io/sommieR/reference/sommier_ancrer.md)
  : Ancrage periodique de la tete de chaine
- [`sommier_verifier_visas()`](https://pobsteta.github.io/sommieR/reference/sommier_verifier_visas.md)
  : Verification des visas d'une foret
- [`sommier_signataire()`](https://pobsteta.github.io/sommieR/reference/sommier_signataire.md)
  : Construction d'un signataire
- [`signataire_cle()`](https://pobsteta.github.io/sommieR/reference/signataire_cle.md)
  : Signataire adosse a une cle privee
- [`signataire_keycloak()`](https://pobsteta.github.io/sommieR/reference/signataire_keycloak.md)
  : Signataire dont l'identite vient de Keycloak ou d'AgentConnect
- [`jws_signer_detache()`](https://pobsteta.github.io/sommieR/reference/jws_signer_detache.md)
  : Signature JWS detachee sur charge non encodee
- [`jws_verifier_detache()`](https://pobsteta.github.io/sommieR/reference/jws_verifier_detache.md)
  : Verification d'une signature JWS detachee
- [`jwt_claims()`](https://pobsteta.github.io/sommieR/reference/jwt_claims.md)
  : Claims d'un jeton JWT
- [`base64url_encoder()`](https://pobsteta.github.io/sommieR/reference/base64url_encoder.md)
  : Encodage base64url (RFC 4648 section 5)
- [`base64url_decoder()`](https://pobsteta.github.io/sommieR/reference/base64url_decoder.md)
  : Decodage base64url
- [`SOMMIER_ALGOS_JWS`](https://pobsteta.github.io/sommieR/reference/SOMMIER_ALGOS_JWS.md)
  : Algorithmes de signature reconnus
- [`tsa_requete()`](https://pobsteta.github.io/sommieR/reference/tsa_requete.md)
  : Requete d'horodatage RFC 3161
- [`tsa_lire_reponse()`](https://pobsteta.github.io/sommieR/reference/tsa_lire_reponse.md)
  : Lecture d'une reponse d'horodatage RFC 3161
- [`tsa_horodater()`](https://pobsteta.github.io/sommieR/reference/tsa_horodater.md)
  : Obtention d'un jeton d'horodatage
- [`tsa_transport_curl()`](https://pobsteta.github.io/sommieR/reference/tsa_transport_curl.md)
  : Transport HTTP pour l'horodatage
- [`SOMMIER_STATUTS_TSA`](https://pobsteta.github.io/sommieR/reference/SOMMIER_STATUTS_TSA.md)
  : Statuts PKIStatus (RFC 3161 section 2.4.2)

## Intégrité vérifiable

Le chaînage de hachages et sa vérification, reproductibles par un tiers
à partir d’un export.

- [`sommier_verifier()`](https://pobsteta.github.io/sommieR/reference/sommier_verifier.md)
  : Verification du sommier d'une foret en base
- [`sommier_verifier_chaine()`](https://pobsteta.github.io/sommieR/reference/sommier_verifier_chaine.md)
  : Verification d'une chaine d'entrees de sommier
- [`sommier_empreinte()`](https://pobsteta.github.io/sommieR/reference/sommier_empreinte.md)
  : Empreinte d'une entree de sommier
- [`sommier_empreinte_genese()`](https://pobsteta.github.io/sommieR/reference/sommier_empreinte_genese.md)
  : Empreinte de genese d'une foret
- [`sommier_enregistrement_canonique()`](https://pobsteta.github.io/sommieR/reference/sommier_enregistrement_canonique.md)
  : Enregistrement canonique d'une entree
- [`SOMMIER_CHAMPS_EMPREINTE`](https://pobsteta.github.io/sommieR/reference/SOMMIER_CHAMPS_EMPREINTE.md)
  : Champs couverts par l'empreinte d'une entree
- [`SOMMIER_VERSION_CHAINE`](https://pobsteta.github.io/sommieR/reference/SOMMIER_VERSION_CHAINE.md)
  : Version de l'algorithme de chainage
- [`empreinte_hex()`](https://pobsteta.github.io/sommieR/reference/empreinte_hex.md)
  : Empreinte en hexadecimal
- [`empreinte_depuis_hex()`](https://pobsteta.github.io/sommieR/reference/empreinte_depuis_hex.md)
  : Empreinte depuis une chaine hexadecimale

## Sérialisation canonique (RFC 8785)

La brique sur laquelle porte le hachage : deux représentations d’un même
payload doivent produire les mêmes octets.

- [`jcs()`](https://pobsteta.github.io/sommieR/reference/jcs.md) :
  Serialisation JSON canonique (RFC 8785, JCS)

- [`jcs_nombre()`](https://pobsteta.github.io/sommieR/reference/jcs_nombre.md)
  :

  Serialisation d'un nombre selon ECMAScript `Number::toString`

- [`jcs_depuis_json()`](https://pobsteta.github.io/sommieR/reference/jcs_depuis_json.md)
  : Recanonisation d'un document JSON existant

## Périmètre de gestion

Forêts, unités de gestion à identifiant stable, filiation et exercices.

- [`foret_creer()`](https://pobsteta.github.io/sommieR/reference/foret_creer.md)
  : Creation d'une foret
- [`ug_creer()`](https://pobsteta.github.io/sommieR/reference/ug_creer.md)
  : Creation d'une unite de gestion
- [`ug_lire()`](https://pobsteta.github.io/sommieR/reference/ug_lire.md)
  : Lecture d'unites de gestion
- [`ug_scinder()`](https://pobsteta.github.io/sommieR/reference/ug_scinder.md)
  : Scission d'une unite de gestion
- [`ug_fusionner()`](https://pobsteta.github.io/sommieR/reference/ug_fusionner.md)
  : Fusion d'unites de gestion
- [`exercice_definir()`](https://pobsteta.github.io/sommieR/reference/exercice_definir.md)
  : Fixation de la possibilite d'un exercice
- [`SOMMIER_REGIMES`](https://pobsteta.github.io/sommieR/reference/SOMMIER_REGIMES.md)
  : Regimes de propriete forestiere

## Base de données

- [`sommier_init_schema()`](https://pobsteta.github.io/sommieR/reference/sommier_init_schema.md)
  : Deploiement du schema du sommier
- [`sommier_revoquer_mutations()`](https://pobsteta.github.io/sommieR/reference/sommier_revoquer_mutations.md)
  : Revocation des droits de mutation sur le registre
- [`decouper_sql()`](https://pobsteta.github.io/sommieR/reference/decouper_sql.md)
  : Decoupage d'un script SQL en instructions

## Consultation et export

- [`sommier_balance_possibilite()`](https://pobsteta.github.io/sommieR/reference/sommier_balance_possibilite.md)
  : Balance de possibilite (imprime A50E)
- [`sommier_exporter_manifeste()`](https://pobsteta.github.io/sommieR/reference/sommier_exporter_manifeste.md)
  : Export d'un manifeste verifiable
- [`sommier_verifier_manifeste()`](https://pobsteta.github.io/sommieR/reference/sommier_verifier_manifeste.md)
  : Verification d'un manifeste exporte
- [`SOMMIER_VERSION_MANIFESTE`](https://pobsteta.github.io/sommieR/reference/SOMMIER_VERSION_MANIFESTE.md)
  : Version du format de manifeste

## Utilitaires

- [`uuid_v4()`](https://pobsteta.github.io/sommieR/reference/uuid_v4.md)
  : Generation d'un UUID version 4
- [`sommieR`](https://pobsteta.github.io/sommieR/reference/sommieR-package.md)
  [`sommieR-package`](https://pobsteta.github.io/sommieR/reference/sommieR-package.md)
  : sommieR : le sommier forestier unifie, a valeur probante
