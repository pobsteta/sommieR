# sommieR

> Le sommier des forêts unifié, à valeur probante.

Le sommier n’est pas un document, c’est un **système de registres
permanents**, complémentaire du document de gestion : l’aménagement dit
ce qui est prévu, le sommier enregistre ce qui advient.

`sommieR` implémente le sommier unifié décrit dans
[`specs/brief_sommier-unifie-synthese.md`](https://pobsteta.github.io/sommieR/specs/brief_sommier-unifie-synthese.md),
couvrant les trois régimes — forêt domaniale, forêt communale, forêt
privée sous PSG — à partir de la série A50 de l’ONF.

## Les trois invariants

1.  **Append-only.** On n’écrase jamais, on ajoute. Une correction est
    une nouvelle entrée portant `corrige_id`, comme la mention
    rectificative du classeur papier où la rature est interdite.
2.  **Trois échelles d’ancrage.** La forêt, l’unité de gestion, l’objet
    remarquable. Chaque entrée se rattache à exactement une échelle.
3.  **Contrôle par visa.** La validation annuelle est ce qui rend le
    sommier opposable — contentieux foncier, certification PEFC,
    transmission entre gestionnaires.

## Ce que le package garantit

L’append-only y est une propriété **vérifiable**, pas une convention
applicative. Les entrées forment un journal à chaînage de hachages :

    hash_n = SHA-256( JCS(enregistrement_n) ‖ hash_{n-1} )

où `JCS` est la sérialisation JSON canonique de la RFC 8785 et `‖` la
concaténation des octets. La genèse est `SHA-256(foret_id)`.

Trois lignes de défense se superposent, et elles ne protègent pas des
mêmes choses :

| Défense | Protège de | Contournable par |
|----|----|----|
| Déclencheur PostgreSQL | Le bogue applicatif — un `UPDATE` involontaire | Le propriétaire des tables |
| `REVOKE UPDATE, DELETE` | Le rôle applicatif compromis | Un superutilisateur |
| Chaîne de hachages | Tout le reste, y compris le serveur lui-même | Rien, sans casser la vérification |

C’est la troisième qui compte pour un tiers : elle ne demande de faire
confiance à personne. Un destinataire vérifie un export hors ligne avec
[`sommier_verifier_manifeste()`](https://pobsteta.github.io/sommieR/reference/sommier_verifier_manifeste.md).

> Aucune blockchain. Les acteurs sont identifiés, l’autorité de
> validation est désignée par le droit, et la valeur probante en France
> passe par le cadre eIDAS — pas par un consensus décentralisé.

## Installation

``` r

# install.packages("remotes")
remotes::install_github("pobsteta/sommieR")
```

Il faut par ailleurs une base PostgreSQL 13+ avec PostGIS et l’extension
`pgcrypto`, et un pilote DBI (`RPostgres` de préférence, `RPostgreSQL`
fonctionne aussi).

## Prise en main

``` r

library(DBI)
library(sommieR)

con <- dbConnect(RPostgres::Postgres(), dbname = "sommier")
sommier_init_schema(con)

foret <- foret_creer(con, "Forêt communale de Chaux", "communal", surface_ha = 500)
ug    <- ug_creer(con, foret, numero_affichage = "12", date_debut = "2010-01-01")
exercice_definir(con, foret, annee = 2026, possibilite_m3_an = 100)

# Registre 5 — un martelage (imprimé A50E)
sommier_ajouter(con, sommier_entree(
  foret_id       = foret,
  ug_uuid        = ug,
  registre       = 5L,
  date_evenement = "2026-03-01",
  auteur         = "agent-01",
  payload        = registre5_coupe(
    type_entree = "martelage", exercice = 2026,
    nature_coupe = "amélioration", volume_m3 = 120, surface_ha = 12.4
  )
))

# Registre 6 — une plantation avec son taux de reprise (imprimé A50J)
sommier_ajouter(con, sommier_entree(
  foret_id = foret, ug_uuid = ug, registre = 6L,
  date_evenement = "2026-04-15", auteur = "agent-01",
  payload = registre6_travaux(
    annee = 2026, nature_travaux = "plantation",
    nb_plants = 1200, provenance_plants = "CHS — Bourgogne",
    montant_eur = 4800, taux_reprise_pct = 87.5
  )
))

sommier_verifier(con, foret)
#> Verification de chaine — sommier
#>   foret     : …
#>   entrees   : 2
#>   seq tete  : 2
#>   hash tete : a6503cc7adc21c04…
#>   etat      : chaine intacte

sommier_balance_possibilite(con, foret)   # imprimé A50E, vue calculée
```

### Corriger sans réécrire

``` r

entree <- sommier_ajouter(con, sommier_entree(...))[[1]]

# La correction est une entrée de plus, pas une modification
sommier_ajouter(con, sommier_entree(
  ..., corrige_id = entree$id,
  payload = registre5_coupe("martelage", 2026, "amélioration", volume_m3 = 95)
))
```

Les vues de consultation ne retiennent que la valeur corrigée ; la
chaîne, elle, garde les deux entrées.

### Partager un export vérifiable

``` r

sommier_exporter_manifeste(con, foret, "sommier-chaux-2026.json")

# Chez le destinataire — commune, CRPF, expert — sans accès à la base :
sommier_verifier_manifeste("sommier-chaux-2026.json")
```

## Les neuf registres

Le socle est commun aux trois régimes à environ 85 % ; ce qui varie
tient à l’autorité de validation, à l’affouage (communal seulement) et
aux paramètres de la balance.

| \#  | Registre                           | Imprimé A50  | Échelle | v0.5.0 |
|-----|------------------------------------|--------------|---------|:------:|
| 1   | **Validations (visas, agréments)** | A10          | forêt   |   ✅   |
| 2   | **Foncier & limites**              | A40          | mixte   |   ✅   |
| 3   | **Droits & concessions**           | A50C         | mixte   |   ✅   |
| 4   | **Infrastructures**                | A50D/D bis   | forêt   |   ✅   |
| 5   | **Coupes & récoltes**              | A50E/F/I     | mixte   |   ✅   |
| 6   | **Travaux**                        | A50J/J bis/H | mixte   |   ✅   |
| 7   | **Comptabilité**                   | A50G         | forêt   |   ✅   |
| 8   | **Événements & faune**             | A50K/L       | mixte   |   ✅   |
| 9   | **Patrimoine remarquable**         | A50 r/\*     | mixte   |   ✅   |

**Les neuf registres sont ouverts.** Les échelles marquées `mixte` le
sont d’après les imprimés eux-mêmes : l’A50C porte une colonne « unités
de gestion / séries », une servitude vise des parcelles identifiées, une
liste d’espèces protégées peut couvrir la forêt entière. Le registre 4
reste à l’échelle de la forêt — une route traverse plusieurs unités, l’y
rattacher serait arbitraire.

## Générer les documents de gestion

Le brief note que la section « gestion antérieure » du PSG, le bilan de
l’aménagement précédent et l’évaluation CT88 *« se génèrent depuis les
mêmes registres »*. Il y a donc un seul assemblage et trois
présentations.

``` r

ga <- sommier_gestion_anterieure(
  con, foret, debut = "2016-01-01", fin = "2025-12-31",
  referentiel = "psg"        # ou "amenagement", ou "ct88"
)

sommier_rapport_markdown(ga, "gestion-anterieure-chaux.md")
```

Chaque référentiel ne reçoit que ce qu’il demande : le PSG n’emporte pas
le détail financier, que le propriétaire n’a pas à produire au CRPF ; le
CT88, tourné vers l’évaluation d’un contrat, n’emporte pas l’inventaire
du patrimoine. Restreindre la sortie évite de diffuser plus que
nécessaire — les registres 3 et 7 portent des données personnelles.

Le patrimoine remarquable n’est délibérément **pas** borné par la
période : c’est un état courant, et le borner écarterait un arbre
inventorié plus tôt alors que le document veut l’inventaire tel qu’il
est aujourd’hui.

## Partager la cartographie

``` r

sommier_exporter_sig(con, foret, "ug-chaux.geojson")            # sans dépendance
sommier_exporter_sig(con, foret, "ug-chaux.gpkg", format = "gpkg")   # via sf
```

Une unité sans géométrie connue est **omise de la couche mais signalée**
dans le retour : la faire figurer sans contour créerait une entité
fantôme dans le SIG, l’omettre en silence laisserait croire la forêt
entièrement cartographiée.

L’export cartographique ne remplace pas le manifeste : la valeur
probante est dans la chaîne, et c’est
[`sommier_exporter_manifeste()`](https://pobsteta.github.io/sommieR/reference/sommier_exporter_manifeste.md)
qui la transporte.

## Comptabilité et bilan financier

Le registre 7 enregistre le réalisé ; le budget prévisionnel vit à côté,
parce que le brief l’exige — *le programme prévisionnel appartient à
l’aménagement, le sommier n’enregistre que le réalisé et le constaté*.
Le prévisionnel est donc mutable, le registre ne l’est pas.

``` r

budget_definir(con, foret, annee = 2026, poste = "reboisement", montant_eur = 5000)

sommier_ajouter(con, sommier_entree(
  foret_id = foret, registre = 7L,
  date_evenement = "2026-06-30", auteur = "compta-01",
  payload = registre7_ecriture(
    poste = "bois_sur_pied", exercice = 2026, montant_eur = 18400,
    quantite = 320, unite = "m3", reference = "TR-2026-014"
  )
))

sommier_bilan_financier(con, foret)        # imprimé A50G
sommier_execution_budgetaire(con, foret)   # réalisé contre prévisionnel
```

Le **sens de l’écriture se déduit du poste** — il ne se saisit pas — et
`montant_eur` est toujours positif. Porter le sens dans le signe est la
source classique des doubles négations, où une dépense saisie à `-500`
sur un poste débiteur redevient silencieusement une recette.

Dans `v_execution_budgetaire`, un poste budgété mais jamais exécuté
reste visible avec un réalisé nul, et un poste exécuté hors budget avec
un prévu nul : les deux sont des faits de gestion, aucun ne doit
disparaître du tableau.

## Le visa : ce qui rend le sommier opposable

Clôturer un exercice signe la tête de chaîne. L’acte est d’abord inscrit
au registre 1, *puis* la tête est lue et signée — de sorte que le visa
atteste un sommier qui contient déjà la trace de sa propre délivrance.

``` r

# L'identité vient du fournisseur OIDC, la signature d'une clé (ou d'un
# service eIDAS) : Keycloak atteste qui signe, il ne signe pas un contenu
# qu'on lui soumet.
signataire <- signataire_keycloak(jeton_id, cle = ma_cle, kid = "cle-2026")

sommier_viser(
  con, foret, exercice = 2026, autorite = "commune",
  signataire = signataire,
  tsa_url = "https://freetsa.org/tsr"   # facultatif
)

sommier_verifier_visas(con, foret, cles_publiques = list(`cle-2026` = ma_cle$pubkey))
#>   exercice autorite seq_tete concorde signature_valide horodate remarque
#> 1     2026  commune       12     TRUE             TRUE     TRUE       NA
```

La signature est détachée sur charge non encodée (RFC 7515 et 7797,
`b64: false`) : la tête de chaîne n’est **pas** recopiée dans le jeton.
Le vérificateur la relit du registre, ce qui lie la signature à la
chaîne plutôt qu’à une copie.

Sans `tsa_url`, le visa est posé sans jeton d’horodatage — valide, mais
sa date ne repose que sur l’horloge du serveur, et
[`sommier_verifier_visas()`](https://pobsteta.github.io/sommieR/reference/sommier_verifier_visas.md)
le dit.
[`sommier_ancrer()`](https://pobsteta.github.io/sommieR/reference/sommier_ancrer.md)
horodate la tête indépendamment de tout visa, pour qu’un exercice non
visé ne puisse pas non plus être réécrit discrètement.

Les clés publiques sont fournies par l’appelant, jamais cherchées au
JWKS du fournisseur : un visa doit rester vérifiable des années plus
tard, hors ligne, sans dépendre de la disponibilité d’un service tiers.

## Détections de télédétection

Une détection FORDEAD ou FAST est une **proposition**, pas un constat :
elle entre au registre 8 avec le NDP de sa source, jamais NDP 0.

``` r

sommier_importer_detections(
  con, foret, detections, source = "fordead", ndp = 3L, auteur = "chaine-fordead"
)

# Après passage sur le terrain — NDP 0, et la proposition est rectifiée
sommier_valider_detection(
  con, detection_id, auteur = "agent-01", statut = "confirme",
  description = "Dépérissement confirmé", surface_ha = 2.8
)
```

`v_detection_en_attente` est la liste de travail : ce qui reste à aller
voir. Une détection tranchée en sort — qu’elle soit confirmée ou écartée
— sans sortir de la chaîne.

## Deux points de conception à connaître

### L’empreinte couvre plus que le payload

Le brief pose `hash_n = SHA-256( JCS(payload_n) ‖ hash_{n-1} )`. Cette
formule laisse hors chaîne `registre`, `ug_uuid`, `date_evenement`,
`auteur`, `ndp`, `seq` et `corrige_id` : on pourrait réaffecter une
coupe à une autre unité de gestion, ou en changer la date, sans
qu’aucune empreinte ne bouge.

Le déclencheur PostgreSQL l’interdit côté serveur, mais l’objectif
annoncé est que chaque acteur puisse revérifier la chaîne **à partir
d’un export, sans faire confiance au serveur**. Un export dont les
métadonnées ne sont pas couvertes ne remplit pas cette promesse.

La forme de la formule est conservée ; elle porte sur l’enregistrement
complet plutôt que sur le seul payload. Les champs couverts sont
énumérés par `SOMMIER_CHAMPS_EMPREINTE`, et l’objet effectivement haché
est reproductible par un tiers via
[`sommier_enregistrement_canonique()`](https://pobsteta.github.io/sommieR/reference/sommier_enregistrement_canonique.md).

### La canonisation ne peut pas être déléguée à PostgreSQL

Le hachage porte sur la forme RFC 8785 du payload, calculée en R. Le
JSONB restitué par PostgreSQL réordonne les clés et normalise les
nombres : deux représentations du même payload y donneraient deux
empreintes. La base stocke et contraint, elle ne calcule pas.

C’est pourquoi
[`jcs()`](https://pobsteta.github.io/sommieR/reference/jcs.md)
implémente l’algorithme complet — tri des clés par unités de code
**UTF-16** (qui diffère de l’ordre des points de code dès qu’un
caractère hors du plan multilingue de base apparaît), échappement
minimal, et sérialisation des nombres selon ECMAScript
`Number::toString`.

## Développement

``` sh
R CMD INSTALL .

# Tests hors base (le noyau se teste entièrement sans serveur)
Rscript -e 'testthat::test_local()'

# Tests complets, base comprise
createdb sommier_test
SOMMIER_TEST_DB=sommier_test Rscript -e 'testthat::test_local()'
```

Sans `SOMMIER_TEST_DB`, les tests de la couche d’accès sont ignorés
plutôt qu’échoués.

## Feuille de route

| Version | Contenu |
|----|----|
| 0.1.0 | Noyau append-only vérifiable, registres 5 et 6, balance A50E |
| 0.2.0 | Registres 1 et 8 ; visa signé JWS, ancrage RFC 3161 ; import FORDEAD/FAST comme propositions à valider |
| 0.3.0 | Registre 7 et vues A50G ; budget prévisionnel et bilan financier |
| 0.4.0 | Registres 2, 3, 4, 9 ; densité de voirie et éléments d’IBP |
| **0.5.0** | Exports réglementaires (PSG, aménagement, CT88) et export cartographique |

La feuille de route du brief est couverte. Restent hors périmètre, et
signalés comme tels : la validation cryptographique de la chaîne de
certification des jetons d’horodatage (elle demande un magasin de
confiance et une validation CMS), et `ES256` pour les signatures — JOSE
veut l’ECDSA en `R||S` brut, OpenSSL la produit en DER, et signer sans
convertir produirait des jetons invérifiables ailleurs.

`ES256` n’est pas encore accepté pour les signatures, et ce n’est pas un
oubli : JOSE exige la signature ECDSA au format brut `R||S` alors
qu’OpenSSL la produit en DER. L’accepter sans faire la conversion
produirait des signatures que rien d’autre ne saurait vérifier.

## Licence

GPL-3.
