# Changelog

## sommieR 0.2.0

Priorité 2 du brief : évènements, visas signés et ancrage.

### Visa signé et ancrage

- [`sommier_viser()`](https://pobsteta.github.io/sommieR/reference/sommier_viser.md)
  clôture un exercice : il inscrit l’acte au registre 1, signe la tête
  de chaîne en JWS détaché, l’horodate si une autorité est configurée,
  puis pose le visa. L’acte est écrit **avant** la lecture de la tête,
  de sorte que le visa atteste un sommier contenant la trace de sa
  propre délivrance.
- [`sommier_signataire()`](https://pobsteta.github.io/sommieR/reference/sommier_signataire.md)
  sépare l’identité de la signature, parce qu’elles viennent de sources
  différentes : un fournisseur OIDC atteste qui signe, une clé ou un
  service eIDAS produit la signature.
  [`signataire_keycloak()`](https://pobsteta.github.io/sommieR/reference/signataire_keycloak.md)
  et
  [`signataire_cle()`](https://pobsteta.github.io/sommieR/reference/signataire_cle.md)
  couvrent les deux cas d’usage courants.
- [`jws_signer_detache()`](https://pobsteta.github.io/sommieR/reference/jws_signer_detache.md)
  /
  [`jws_verifier_detache()`](https://pobsteta.github.io/sommieR/reference/jws_verifier_detache.md)
  implémentent la signature détachée sur charge non encodée (RFC 7515 et
  7797, `b64: false`). La tête de chaîne n’est pas recopiée dans le
  jeton : le vérificateur la relit du registre, ce qui lie la signature
  à la chaîne et non à une copie.
- [`sommier_ancrer()`](https://pobsteta.github.io/sommieR/reference/sommier_ancrer.md)
  horodate la tête indépendamment de tout visa, pour qu’un exercice non
  visé ne puisse pas non plus être réécrit discrètement.
- [`sommier_verifier_visas()`](https://pobsteta.github.io/sommieR/reference/sommier_verifier_visas.md)
  confronte chaque visa à la chaîne et à la clé publique fournie. Les
  clés sont passées par l’appelant et non cherchées au JWKS : un visa
  doit rester vérifiable des années plus tard, hors ligne.
- Client RFC 3161 complet
  ([`tsa_requete()`](https://pobsteta.github.io/sommieR/reference/tsa_requete.md),
  [`tsa_lire_reponse()`](https://pobsteta.github.io/sommieR/reference/tsa_lire_reponse.md),
  [`tsa_horodater()`](https://pobsteta.github.io/sommieR/reference/tsa_horodater.md)),
  transport injectable. Sans autorité configurée, le visa est posé sans
  jeton et le rapport le signale plutôt que d’échouer.

### Registres 1 et 8

- Registre 1 — validations
  ([`registre1_validation()`](https://pobsteta.github.io/sommieR/reference/registre1_validation.md),
  imprimé A10) : visas annuels, arrêtés, délibérations, agréments CRPF,
  engagements fiscaux.
- Registre 8 — évènements et faune :
  [`registre8_phenomene()`](https://pobsteta.github.io/sommieR/reference/registre8_phenomene.md)
  (A50K),
  [`registre8_tableau_chasse()`](https://pobsteta.github.io/sommieR/reference/registre8_tableau_chasse.md)
  (A50L),
  [`registre8_equilibre_gibier()`](https://pobsteta.github.io/sommieR/reference/registre8_equilibre_gibier.md)
  (équilibre forêt-gibier, LAAAF 2014) et
  [`registre8_detection()`](https://pobsteta.github.io/sommieR/reference/registre8_detection.md).
- Le registre 8 est d’échelle mixte : une tempête frappe des unités
  identifiées, un tableau de chasse est à l’échelle de la forêt.
- Nouvelles vues : `v_validation`, `v_tenue_sommier`, `v_evenement`,
  `v_detection_en_attente`, `v_tableau_chasse`, `v_equilibre_gibier`.

### Détections de télédétection

- [`sommier_importer_detections()`](https://pobsteta.github.io/sommieR/reference/sommier_importer_detections.md)
  inscrit les propositions FORDEAD/FAST avec le NDP de leur source,
  jamais NDP 0 : une détection est une proposition, pas un constat.
- [`sommier_valider_detection()`](https://pobsteta.github.io/sommieR/reference/sommier_valider_detection.md)
  inscrit le constat de terrain en NDP 0, qui rectifie la détection —
  qu’il la confirme ou l’écarte. La proposition sort des vues de
  consultation sans sortir de la chaîne.

### Corrections

- [`sommier_init_schema()`](https://pobsteta.github.io/sommieR/reference/sommier_init_schema.md)
  exécute le script instruction par instruction
  ([`decouper_sql()`](https://pobsteta.github.io/sommieR/reference/decouper_sql.md)).
  L’envoyer d’un bloc échouait sur les pilotes passant par le protocole
  étendu de PostgreSQL — « cannot insert multiple commands into a
  prepared statement » — ce que le pilote employé en développement
  masquait. Le découpage respecte les chaînes, les commentaires
  imbriqués et les corps de fonction délimités par `$$`.
- Les transactions sont réentrantes, par points de reprise.
  `dbWithTransaction` ne s’imbrique pas : le `COMMIT` interne validait
  la transaction externe avant l’heure, si bien qu’un visa refusé
  laissait derrière lui l’acte de registre 1 déjà écrit.
- [`entrees_en_data_frame()`](https://pobsteta.github.io/sommieR/reference/entrees_en_data_frame.md)
  n’utilise plus [`methods::as()`](https://rdrr.io/r/methods/as.html),
  qui n’était pas importé.
- Les listes de paramètres envoyées au pilote ne sont plus nommées.
  [`vapply()`](https://rdrr.io/r/base/lapply.html) sur un vecteur de
  caractères nomme son résultat par ses propres valeurs :
  [`ug_lire()`](https://pobsteta.github.io/sommieR/reference/ug_lire.md)
  et
  [`ug_fusionner()`](https://pobsteta.github.io/sommieR/reference/ug_fusionner.md)
  transmettaient donc des paramètres nommés, que RPostgres refuse («
  `params` must not be named ») là où RPostgreSQL les tolère. Les noms
  sont désormais retirés au point d’appel, pour qu’aucun site ne puisse
  régresser là-dessus.

## sommieR 0.1.0

Première version : le noyau append-only vérifiable (priorité 1 du
brief).

### Registre et chaîne

- [`sommier_entree()`](https://pobsteta.github.io/sommieR/reference/sommier_entree.md)
  construit une entrée validée ;
  [`sommier_ajouter()`](https://pobsteta.github.io/sommieR/reference/sommier_ajouter.md)
  la chaîne et l’écrit,
  [`sommier_lire()`](https://pobsteta.github.io/sommieR/reference/sommier_lire.md)
  la relit,
  [`sommier_verifier()`](https://pobsteta.github.io/sommieR/reference/sommier_verifier.md)
  recalcule la chaîne de la genèse à la tête.
- [`sommier_chainer()`](https://pobsteta.github.io/sommieR/reference/sommier_chainer.md)
  et
  [`sommier_verifier_chaine()`](https://pobsteta.github.io/sommieR/reference/sommier_verifier_chaine.md)
  opèrent hors base : un auditeur tiers peut vérifier un export sans
  serveur.
- [`jcs()`](https://pobsteta.github.io/sommieR/reference/jcs.md)
  implémente la sérialisation JSON canonique de la RFC 8785 — tri des
  clés par unités de code UTF-16, échappement minimal, nombres selon
  ECMAScript `Number::toString`.
- L’empreinte couvre l’enregistrement complet, pas seulement le payload
  : voir `SOMMIER_CHAMPS_EMPREINTE` pour la liste des champs et la
  justification de cet écart au brief.

### Registres ouverts

- Registre 5 — coupes et récoltes
  ([`registre5_coupe()`](https://pobsteta.github.io/sommieR/reference/registre5_coupe.md),
  imprimés A50E/F/I).
- Registre 6 — travaux
  ([`registre6_travaux()`](https://pobsteta.github.io/sommieR/reference/registre6_travaux.md),
  imprimés A50J/J bis/H).
- Les sept autres registres sont déclarés dans `SOMMIER_REGISTRES` et
  refusés à l’écriture avec un message explicite.

### Base de données

- [`sommier_init_schema()`](https://pobsteta.github.io/sommieR/reference/sommier_init_schema.md)
  déploie le schéma PostGIS et les vues ; les deux fichiers SQL sont
  idempotents.
- L’append-only est imposé par des déclencheurs, y compris sur
  `TRUNCATE`, que les déclencheurs `FOR EACH ROW` ne couvrent pas ;
  `visa` et `ancrage` sont immuables au même titre.
- [`sommier_revoquer_mutations()`](https://pobsteta.github.io/sommieR/reference/sommier_revoquer_mutations.md)
  retire `UPDATE`, `DELETE` et `TRUNCATE` au rôle applicatif.
- Les écritures concurrentes sont sérialisées par forêt via
  `pg_advisory_xact_lock()`, pris avant la lecture de la tête de chaîne.

### Unités de gestion

- Identifiant stable à vie, distinct du numéro d’affichage ; un numéro
  n’est unique que parmi les unités actives, ce qui autorise sa reprise
  après clôture sans jamais réattribuer l’identifiant.
- [`ug_scinder()`](https://pobsteta.github.io/sommieR/reference/ug_scinder.md)
  et
  [`ug_fusionner()`](https://pobsteta.github.io/sommieR/reference/ug_fusionner.md)
  clôturent les unités d’origine et enregistrent la filiation. La table
  `ug_filiation` porte le cas à plusieurs parents, que la colonne
  `parent_uuid` seule ne sait pas représenter.

### Vues calculées

- `v_balance_possibilite` (imprimé A50E) : volumes martelés moins
  possibilité, cumulés. `coupe_realisee` en est exclu, la même coupe
  étant d’abord martelée puis exploitée.
- `v_entree_courante` écarte les entrées rectifiées ; la chaîne les
  conserve.
- `v_coupe`, `v_travaux`, `v_tete_chaine`.

### Export

- [`sommier_exporter_manifeste()`](https://pobsteta.github.io/sommieR/reference/sommier_exporter_manifeste.md)
  et
  [`sommier_verifier_manifeste()`](https://pobsteta.github.io/sommieR/reference/sommier_verifier_manifeste.md)
  : partage vérifiable hors ligne, visas et ancrages compris. L’export
  GeoPackage est prévu pour la 0.5.0.
