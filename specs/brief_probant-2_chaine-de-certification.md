# Brief — Lot 2 : la chaîne de certification, et ce qui manque au destinataire

*Établi le 27 août 2026, dans le prolongement du lot 1.*

## Pourquoi ce lot existe

Le lot 1 fait dire au jeton ce qu'il atteste : une empreinte, une date. Il ne
dit toujours pas **qui** l'atteste. Lire le `TSTInfo` d'un jeton forgé de toutes
pièces donnerait une empreinte et une date tout aussi bien formées ; ce qui
sépare l'attestation de la fabrication, c'est la signature de l'autorité et la
chaîne qui la rattache à une racine que le vérificateur reconnaît.

Et il y a plus gênant, que l'export met à nu. `sommier_exporter_manifeste()`
emporte `signature_jws` et `tst_rfc3161` (`R/manifeste.R:47`), et la promesse
tenue au destinataire — une commune, un CRPF, une DREAL — est une vérification
hors ligne. Les deux pièces ne sont pourtant pas dans le même état :

| Pièce | Ce qui voyage | Ce qui manque au destinataire |
|---|---|---|
| Jeton RFC 3161 | le jeton **et le certificat de l'autorité**, inclus à la demande (`demander_certificat = TRUE`) | une ancre de confiance |
| Visa JWS | la signature et les claims, `kid` compris | **la clé publique elle-même** |

Le jeton est autoporteur. Le visa ne l'est pas. Les clés sont passées par
l'appelant et délibérément pas cherchées au JWKS, pour qu'« un visa reste
vérifiable des années plus tard, hors ligne » (NEWS 0.2.0) — la décision est
juste, mais elle laisse le destinataire sans rien : il reçoit une signature
qu'il ne peut confronter à aucune clé, à moins de se la faire remettre par un
canal que le manifeste n'organise pas. La vérification hors ligne par un tiers
n'est aujourd'hui vraie qu'à moitié.

## Décisions de conception

1. **L'ancre de confiance est fournie, jamais embarquée.** C'est la règle du
   lot 4 de la série cartographique, appliquée ici : aucune table de
   correspondance n'y était embarquée faute de source citable. Un magasin de
   racines embarqué dans le paquet serait pire encore — il ferait dépendre du
   rythme de publication de sommieR la question de savoir qui est digne de
   confiance, et une racine retirée resterait attestée par toute version
   installée. L'appelant fournit ses ancres (`openssl::read_cert_bundle()`) ;
   à charge pour lui de savoir ce qu'il reconnaît.

2. **Trois états, pas deux.** Sans ancre fournie, un jeton n'est ni valide ni
   invalide : il est **lu et non rattaché**. Le confondre avec l'un ou l'autre
   serait mentir dans les deux sens — annoncer une garantie absente, ou
   condamner un jeton correct. Le rapport porte donc trois états distincts, et
   le document engendré dit lequel.

3. **Le certificat du signataire entre dans le visa.** Non pas cherché au
   moment de vérifier, mais enregistré au moment de signer : il fait partie de
   ce qui est attesté. Le visa devient alors autoporteur comme le jeton, et les
   deux pièces se vérifient dans les mêmes conditions — signature confrontée au
   certificat, certificat confronté à une ancre fournie. La colonne est
   facultative : un visa antérieur, sans certificat, garde le comportement
   actuel, clé fournie par l'appelant. Le prix est une évolution du schéma et
   un incrément de `SOMMIER_VERSION_MANIFESTE` ; il est à payer ici plutôt
   qu'après la 1.0.

4. **La vérification se fait en R.** `openssl ts -verify` fait le travail, et
   c'est ce que la documentation recommande aujourd'hui. Mais demander à une
   commune d'avoir la ligne de commande OpenSSL et de connaître l'invocation
   juste, c'est déplacer la charge de la preuve sur celui qui reçoit. Ce que
   `sommier_verifier_manifeste()` promet, c'est de vérifier ; il doit donc
   vérifier.

5. **La révocation est hors périmètre, et déclarée.** CRL et OCSP exigent le
   réseau, ce que la vérification hors ligne exclut par construction. Un
   certificat révoqué mais non expiré passera. C'est une limite réelle : elle
   est écrite dans la documentation et rendue dans le rapport, plutôt que
   passée sous silence.

## Ce qu'il faut valider

La validation CMS d'un jeton RFC 3161, dans l'ordre :

* la signature du `SignerInfo` porte sur les `signedAttrs` réencodés en `SET OF`
  — non sur le `TSTInfo` directement ;
* l'attribut `messageDigest` des `signedAttrs` correspond à l'empreinte du
  `TSTInfo` ;
* l'`ESSCertID` (attribut `signingCertificateV2`) désigne bien le certificat
  employé — sans quoi un certificat substitué dans le champ `certificates`
  passerait ;
* le certificat porte l'EKU `id-kp-timeStamping`, critique, exigé par la
  RFC 3161 ;
* le certificat est valide **à la date attestée**, non à la date du jour : un
  jeton de 2019 reste bon après l'expiration du certificat qui l'a produit,
  c'est même tout l'intérêt de l'horodatage ;
* la chaîne remonte à une ancre fournie (`openssl::cert_verify()`).

## Livrables

* `tsa_verifier_jeton(jeton, empreinte, ancres = NULL)` — verdict structuré à
  trois états, avec le motif du refus quand il y en a un.
* Enregistrement du certificat du signataire au visa, et sa reprise dans le
  manifeste ; incrément de `SOMMIER_VERSION_MANIFESTE`.
* `sommier_verifier_manifeste()` vérifie signatures JWS et jetons, et lève la
  réserve inscrite à `R/manifeste.R:91`.
* Fixtures : la chaîne du lot 1, plus les cas de refus — certificat sans EKU,
  certificat substitué, jeton dont le `messageDigest` ne correspond pas, chaîne
  ne remontant à aucune ancre.

## Critères d'acceptation

* Un jeton vérifié avec l'ancre qui convient est déclaré valide ; le même sans
  ancre est déclaré lu et non rattaché ; aucun des deux n'est déclaré invalide.
* Un certificat d'autorité dépourvu de l'EKU `timeStamping` fait échouer la
  vérification.
* Un jeton dont le certificat a expiré **après** la date attestée reste valide.
* Un destinataire disposant du seul manifeste et de ses ancres vérifie visas et
  jetons sans accès au réseau ni à la base.
* Le rapport dit que la révocation n'est pas vérifiée, plutôt que de laisser
  croire qu'elle l'est.
