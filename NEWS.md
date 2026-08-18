# sommieR 0.1.0

Première version : le noyau append-only vérifiable (priorité 1 du brief).

## Registre et chaîne

* `sommier_entree()` construit une entrée validée ; `sommier_ajouter()` la
  chaîne et l'écrit, `sommier_lire()` la relit, `sommier_verifier()` recalcule
  la chaîne de la genèse à la tête.
* `sommier_chainer()` et `sommier_verifier_chaine()` opèrent hors base : un
  auditeur tiers peut vérifier un export sans serveur.
* `jcs()` implémente la sérialisation JSON canonique de la RFC 8785 — tri des
  clés par unités de code UTF-16, échappement minimal, nombres selon
  ECMAScript `Number::toString`.
* L'empreinte couvre l'enregistrement complet, pas seulement le payload : voir
  `SOMMIER_CHAMPS_EMPREINTE` pour la liste des champs et la justification de
  cet écart au brief.

## Registres ouverts

* Registre 5 — coupes et récoltes (`registre5_coupe()`, imprimés A50E/F/I).
* Registre 6 — travaux (`registre6_travaux()`, imprimés A50J/J bis/H).
* Les sept autres registres sont déclarés dans `SOMMIER_REGISTRES` et refusés
  à l'écriture avec un message explicite.

## Base de données

* `sommier_init_schema()` déploie le schéma PostGIS et les vues ; les deux
  fichiers SQL sont idempotents.
* L'append-only est imposé par des déclencheurs, y compris sur `TRUNCATE`, que
  les déclencheurs `FOR EACH ROW` ne couvrent pas ; `visa` et `ancrage` sont
  immuables au même titre.
* `sommier_revoquer_mutations()` retire `UPDATE`, `DELETE` et `TRUNCATE` au
  rôle applicatif.
* Les écritures concurrentes sont sérialisées par forêt via
  `pg_advisory_xact_lock()`, pris avant la lecture de la tête de chaîne.

## Unités de gestion

* Identifiant stable à vie, distinct du numéro d'affichage ; un numéro n'est
  unique que parmi les unités actives, ce qui autorise sa reprise après
  clôture sans jamais réattribuer l'identifiant.
* `ug_scinder()` et `ug_fusionner()` clôturent les unités d'origine et
  enregistrent la filiation. La table `ug_filiation` porte le cas à plusieurs
  parents, que la colonne `parent_uuid` seule ne sait pas représenter.

## Vues calculées

* `v_balance_possibilite` (imprimé A50E) : volumes martelés moins possibilité,
  cumulés. `coupe_realisee` en est exclu, la même coupe étant d'abord martelée
  puis exploitée.
* `v_entree_courante` écarte les entrées rectifiées ; la chaîne les conserve.
* `v_coupe`, `v_travaux`, `v_tete_chaine`.

## Export

* `sommier_exporter_manifeste()` et `sommier_verifier_manifeste()` : partage
  vérifiable hors ligne, visas et ancrages compris. L'export GeoPackage est
  prévu pour la 0.5.0.
