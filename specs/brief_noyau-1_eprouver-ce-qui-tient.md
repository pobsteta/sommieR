# Brief — Noyau, lot 1 : éprouver ce qui tient la chaîne

*Établi le 28 août 2026, après le premier passage de la suite complète contre
une base PostgreSQL réelle.*

## Pourquoi ce lot existe

La feuille de route du brief de synthèse est couverte. Les cinq priorités, les
quatre lots cartographiques, les deux lots probants, le premier lot de reprise :
tout est écrit, tout est documenté, tout passe. Ce lot n'ajoute donc aucune
fonction. Il porte sur autre chose — **ce que la suite de tests démontre
vraiment**, par opposition à ce que la documentation affirme.

Trois affirmations du paquet portent la chaîne à elles seules, et aucune des
trois n'est éprouvée aujourd'hui.

## Ce que la lecture a établi

| Constat | Où |
|---|---|
| Le verrou consultatif est la seule chose qui empêche deux écritures concurrentes de forker la chaîne | `R/ajouter.R:52-58` |
| `UNIQUE (foret_id, seq)` est annoncé comme « le filet de sécurité si le verrou venait à manquer » | `R/ajouter.R:20-21` |
| Le tri des clés par unités de code UTF-16 est ce qui rend l'empreinte reproductible chez un tiers | `R/jcs.R:16-17` |
| **Aucun test ne fait écrire deux connexions à la fois** | `grep -rn "concurrent\|advisory" tests/` ne rend rien |
| **Aucun test ne fait échouer le filet** | idem |
| Les treize tests de `test-jcs.R` sont des cas choisis à la main | `tests/testthat/test-jcs.R` |

Autrement dit : le paquet documente longuement *pourquoi* il prend un verrou, et
n'a jamais vérifié qu'il le prend. La chose la plus critique du noyau est celle
qui n'a jamais été mise en défaut.

## Ce que la première exécution contre une vraie base a fait apparaître

Faire tourner la suite avec `SOMMIER_TEST_DB` fait passer 912 assertions à
1220 — et sort quatre avertissements du pilote, tous de la même forme :

```
Closing open result set, cancelling previous query
```

Ils viennent du chemin de retour arrière de `transaction()` (`R/db.R:365`). Un
ordre SQL qui échoue laisse son résultat ouvert côté RPostgres ; le coup
suivant sur la connexion — ici le `ROLLBACK` — annonce qu'il l'annule. Le
message est donc **attendu et correct**. Il n'en est pas moins nuisible : il
apparaît à chaque transaction avortée, c'est-à-dire précisément aux moments
qu'un exploitant lit avec attention, et il n'apprend rien. Un avertissement
qu'on prend l'habitude d'ignorer est un avertissement qui masquera le suivant.

## Décisions de conception

### 1. Le verrou s'éprouve par le blocage qu'il produit, pas par un fork de processus

Un test de concurrence « réaliste » lancerait N processus qui écrivent
ensemble. C'est le réflexe, et c'est le mauvais choix ici : forker un processus
R qui détient une connexion libpq est notoirement instable, cela demanderait une
dépendance de plus, et un tel test est intermittent par construction — il
passerait le plus souvent sans rien prouver, et échouerait un jour sans qu'on
sache si le verrou ou l'ordonnanceur est en cause. **Un test de concurrence qui
n'échoue pas de façon reproductible ne démontre rien.**

La propriété à démontrer n'est pas « N processus écrivent » mais **« le verrou
est exclusif, et il est tenu pendant toute la transaction »**. Elle s'observe
depuis une seconde connexion, sans parallélisme :

1. La connexion B ouvre une transaction et prend le verrou de la forêt.
2. La connexion A borne son attente (`SET lock_timeout`) et écrit.
3. A doit **échouer sur expiration du verrou** — ce qui prouve que le verrou est
   pris, qu'il est exclusif, et que A l'attend au lieu de lire la tête.
4. B relâche. A réécrit et réussit, la chaîne restant valide.

Déterministe, sans dépendance nouvelle, et qui échoue franchement le jour où le
verrou disparaît du code. Vérifié avant rédaction : A attend puis rend
`canceling statement due to lock timeout`, et réussit après relâchement.

### 2. Le filet de sécurité se teste en le faisant travailler

`UNIQUE (foret_id, seq)` est présenté comme le rattrapage d'un verrou manquant.
Cette phrase n'engage à rien tant qu'on ne l'a pas provoquée. Le test chaîne
**deux branches depuis la même tête** — exactement ce qu'un verrou absent
produirait — et exige que la seconde insertion soit refusée par la contrainte,
la chaîne restant vérifiable. Vérifié avant rédaction : la seconde branche est
rejetée sur `entree_sommier_foret_id_seq_key`.

### 3. Les propriétés se testent sur des valeurs engendrées, pas seulement choisies

Treize cas choisis à la main disent que l'auteur a pensé à treize choses. Ce qui
porte la chaîne est une propriété universelle : **l'empreinte ne doit pas
dépendre de l'ordre dans lequel les clés du payload ont été écrites.** Un
destinataire qui reconstruit un payload champ par champ, dans un autre ordre,
doit retrouver la même empreinte, sinon la vérification par un tiers est une
promesse creuse.

Les propriétés retenues, sur valeurs engendrées à graine fixe — un test qui
change de verdict d'une exécution à l'autre ne se corrige pas :

* la canonisation est **invariante par permutation des clés**, à toute
  profondeur ;
* recanoniser une forme canonique ne la change pas ;
* tout nombre engendré se relit exactement à travers `jcs_nombre()` ;
* **l'empreinte d'une entrée est invariante par permutation des clés du
  payload**, et change dès qu'un octet couvert change.

### 4. Et sous le bruit, un vrai défaut

Taire le message du retour arrière n'a pas fait taire tous les autres : deux en
sont restés, sur `budget_definir()`, dont les deux arguments refusés n'atteignent
jamais la base. La trace remonte à ceci :

```r
DBI::dbExecute(con, "INSERT INTO budget_previsionnel …",
  params = parametres(list(
    valider_choix(poste, "poste", SOMMIER_POSTES_COMPTABLES$poste),  # <- ici
    …
  )))
```

R évalue les arguments paresseusement. La validation écrite **dans** la liste
`params` ne s'exécute donc pas avant l'appel, mais **pendant** — c'est-à-dire
après que le pilote a ouvert son objet de résultat. Un argument refusé laissait
ainsi une requête morte sur la connexion, et l'ordre suivant, *n'importe où
ailleurs dans le programme*, en héritait : une requête silencieusement annulée
et un avertissement à un endroit sans rapport avec la faute.

Ce n'est pas du bruit, c'est une connexion laissée sale par un chemin d'erreur.
Quatre appels partagent le défaut : `budget_definir()`,
`sommier_bilan_financier()`, `exercice_definir()` et `ug_creer()`. Les
validations remontent avant l'appel, où elles auraient toujours dû être.

C'est la trouvaille du lot, et elle illustre son intérêt : le bruit qu'on
s'habitue à ignorer cachait exactement ce qu'on redoutait qu'il cache.

### 5. Le silence ne se gagne pas en se bouchant les oreilles

Le retour arrière tait **ce seul message de ménage du pilote**, reconnu sur son
texte, et laisse passer tout le reste. Éteindre l'ensemble des avertissements du
bloc reviendrait à supprimer le symptôme et le signal ensemble.

## Livrables

* Un test de concurrence qui met le verrou consultatif en défaut de façon
  reproductible, et un test qui fait travailler `UNIQUE (foret_id, seq)`.
* Des tests de propriété à graine fixe sur la canonisation et sur l'empreinte,
  centrés sur l'invariance par permutation des clés.
* Le retour arrière de `transaction()` débarrassé du seul message de ménage du
  pilote.
* Les validations des quatre appels concernés remontées avant l'ouverture d'un
  résultat, et un test qui garde ce chemin d'erreur fermé.

## Critères d'acceptation

* Retirer le `pg_advisory_xact_lock` de `R/ajouter.R` fait **échouer** un test.
* Retirer `UNIQUE (foret_id, seq)` du schéma fait **échouer** un test.
* Une transaction avortée n'émet plus d'avertissement de pilote, et un
  avertissement d'une autre nature émis au même endroit passe toujours.
* Un argument refusé par l'un des quatre appels laisse la connexion propre :
  l'ordre suivant s'exécute sans un mot. Remettre une validation dans la liste
  `params` fait échouer un test.
* Aucune fonction exportée nouvelle, aucune dépendance nouvelle, aucun
  changement de comportement observable en dehors du silence gagné.

## Ce que ce lot ne fait pas

Il ne teste pas la concurrence à N écrivains réels, et ne prétend pas le faire.
Il démontre la propriété dont la correction dépend — l'exclusion mutuelle — et
laisse la montée en charge à une campagne de tenue, qui relève de
l'exploitation et non de la suite unitaire.
