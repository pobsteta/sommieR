# Brief — Lot 1 : ES256, et ce qu'un jeton d'horodatage atteste

*Établi le 27 août 2026, après vérification sur une autorité d'horodatage
montée localement et sur 4 000 signatures ECDSA.*

## Pourquoi ce lot existe

Le paquet sait poser un visa et obtenir un jeton d'horodatage. Il ne sait lire
ni l'un ni l'autre jusqu'au bout, et deux formulations du dépôt le disent
elles-mêmes :

* `R/jws.R:45` — `SOMMIER_ALGOS_JWS <- c("RS256")`, `ES256` refusé faute de la
  conversion DER → `R||S`.
* `R/horodatage.R:134` — le jeton est rendu « sans vérification cryptographique
  de la chaîne de certification […] La vérification complète se fait avec
  `openssl ts -verify` ».

Le second point cache le plus sérieux, qui n'est pas la chaîne de
certification. **Le contenu du jeton n'est jamais lu.** `sommier_verifier_visas()`
rend `horodate`, un booléen qui signifie « il y a un jeton dans la colonne »
(`R/visa.R:187`). Ni la date attestée par l'autorité, ni l'empreinte que le
jeton couvre ne sont regardées. Un jeton parfaitement valide, obtenu pour une
autre tête de chaîne — une autre forêt, un autre exercice — passe exactement
comme le bon.

C'est le contraire de ce que le paquet vend. `sommier_verifier_manifeste()`
prend soin de signaler le `visa_orphelin` « rapporté d'une autre chaîne »
(`R/manifeste.R:95`) en confrontant le `hash_tete` déclaré aux entrées — mais
ce `hash_tete` vient de la colonne, pas du jeton. Le jeton, lui, n'est confronté
à rien.

## Ce que la vérification a établi

### La conversion ECDSA existe déjà

`openssl` 2.4.2 expose `ecdsa_parse()` et `ecdsa_write()`. Le refus d'`ES256`
était juste au moment où il a été écrit ; sa raison a une réponse. L'aller-retour
DER → (r, s) → DER redonne l'octet près la signature d'origine, et elle se
vérifie.

Un piège demeure, et c'est lui qui commande la conception. `ecdsa_parse()` rend
deux `bignum` ; un `bignum` ne porte pas ses zéros de tête. Concaténer
naïvement `as.raw(r)` et `as.raw(s)` produit alors une signature de moins de
64 octets, qu'aucune autre implémentation JOSE n'accepte.

| Mesure | Résultat |
|---|---|
| Signatures P-256 tirées | 4 000 |
| Dont `r` ou `s` sur moins de 32 octets | 29 — **0,72 %** |

Une sur cent quarante environ. Assez rare pour qu'une suite de tests qui
compte sur le hasard passe au vert, assez fréquent pour qu'un service qui pose
un visa par exercice et par forêt en produise une invalide dans l'année.

### Le jeton dit tout ce qu'on lui reproche de taire

Autorité montée localement (racine, certificat portant l'EKU `timeStamping`
critique, `openssl ts -reply`), sans réseau. `tsa_lire_reponse()` lit la
réponse produite : statut 0 « accordé », jeton de 2 503 octets. Le `TSTInfo`
qu'il encapsule porte :

| Champ | Valeur observée |
|---|---|
| `messageImprint` | `05733e95…17b59745` — l'empreinte SHA-256 horodatée |
| `genTime` | `2026-08-27 05:02:29 GMT` |
| `serialNumber` | `0x02` |
| `nonce` | `0xB79CF020DACA5EED` |
| `policy` | l'OID de politique de l'autorité |

Rien de tout cela n'exige un magasin de confiance : c'est du DER, et
`R/horodatage.R` en contient déjà la moitié du lecteur (`der_lire()`,
`der_entier_valeur()`).

Confrontation faite avec l'outil de référence : le même jeton opposé à une
autre donnée échoue sur `message imprint mismatch`. C'est exactement le test
que le paquet ne fait pas.

## Décisions de conception

1. **`ES256` s'accepte, et chaque composante est rembourrée à 32 octets.**
   La conversion se fait dans les deux sens : `R||S` à la signature, DER à la
   vérification, puisque `openssl::signature_verify()` attend du DER. Le
   rembourrage n'est pas une précaution de style, c'est la correction d'un
   défaut mesuré à 0,72 %. Les tests l'exercent sur une signature à composante
   courte **construite ou cherchée exprès** : espérer en rencontrer une est ce
   qui laisserait passer le défaut.

2. **La clé décide de l'algorithme, pas l'appelant.** `signataire_cle()` fixe
   aujourd'hui `alg = "RS256"` en dur (`R/jws.R:109`). Avec deux algorithmes,
   laisser l'appelant déclarer `alg` tout en passant une clé EC produirait un
   en-tête annonçant `RS256` au-dessus d'une signature ECDSA — invérifiable
   partout, y compris ici. L'algorithme se déduit donc du type de clé, et une
   contradiction entre les deux est refusée.

3. **Un jeton doit dire ce qu'il atteste.** `tsa_lire_jeton()` rend le
   `TSTInfo` : empreinte, date, numéro de série, nonce, politique. La
   vérification confronte l'empreinte du jeton à la tête de chaîne qu'il
   prétend couvrir, et un écart est une anomalie, du même rang qu'un
   `visa_orphelin`. Le booléen `horodate` cède la place à la **date attestée**.
   Une date qui ne vient pas du jeton n'est qu'une date de base de données :
   celle que le registre s'est donnée à lui-même, et qui ne prouve rien contre
   celui qui tient la base.

4. **Ce lot ne réclame aucune configuration.** Tout ce qui précède se fait sans
   magasin de confiance, sans réseau, sans ancre à fournir. C'est délibéré :
   la valeur est immédiate, elle ne se paie pas d'un déploiement, et elle
   n'attend pas le lot 2. La validation de la chaîne de certification, qui
   exige une ancre, y est renvoyée entière.

5. **Le nonce est lu et confronté.** `tsa_requete()` en pose un déjà, pour
   « détecter le rejeu d'une réponse antérieure » (`R/horodatage.R:57`) — mais
   personne ne le relit, si bien que la détection annoncée n'a jamais eu lieu.
   `tsa_horodater()` compare celui du jeton à celui qu'il a envoyé.

## Livrables

* `SOMMIER_ALGOS_JWS <- c("RS256", "ES256")`, avec la conversion DER ↔ `R||S`
  dans les deux sens et le rembourrage à 32 octets.
* `signataire_cle()` déduit l'algorithme de la clé ; une contradiction est
  refusée.
* `tsa_lire_jeton()` — le `TSTInfo` d'un jeton : empreinte, date, série,
  nonce, politique.
* `tsa_horodater()` confronte le nonce rendu à celui envoyé.
* `sommier_verifier_visas()` et `sommier_verifier_manifeste()` rendent la date
  attestée, et signalent le jeton dont l'empreinte ne couvre pas la tête
  annoncée.
* Fixture de test : chaîne d'autorité et jeton réels, engendrés hors ligne,
  avec leur `PROVENANCE.md` — la suite reste exécutable sans réseau.

## Critères d'acceptation

* Une signature `ES256` posée par sommieR se vérifie par une implémentation
  JOSE tierce, y compris lorsque `r` ou `s` porte un zéro de tête.
* Un visa signé avec une clé EC ne peut pas porter un en-tête `RS256`.
* Un jeton obtenu pour une autre tête de chaîne est signalé comme anomalie,
  et non compté comme horodaté.
* La date rendue par le rapport est celle du `genTime` de l'autorité, pas
  celle de la colonne `date_visa`.
* Un jeton syntaxiquement valide mais dont le nonce diffère de celui envoyé
  est refusé à l'obtention.
* La suite de tests passe sans réseau et sans magasin de confiance.
