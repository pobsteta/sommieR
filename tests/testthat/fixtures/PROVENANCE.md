# Lot EDIGÉO de démonstration

`edigeo-212000000A01.tar.bz2` — feuille cadastrale A01 de Couchey (21200),
téléchargée le 20 août 2026 depuis :

    https://cadastre.data.gouv.fr/data/dgfip-pci-vecteur/latest/edigeo/feuilles/21/21200/edigeo-212000000A01.tar.bz2

Plan Cadastral Informatisé, DGFiP, sous Licence Ouverte. 39 Ko.

**Pourquoi cette archive est dans le dépôt.** La lecture EDIGÉO ne se teste
pas autrement : le format est multi-fichiers et auto-descripteur, et le
reconstituer à la main produirait une imitation dont la conformité ne
prouverait rien. Sans elle, `sommier_fond_pci_lire()` ne serait exercé que par
un test dépendant du réseau, donc sauté en intégration continue — une
couverture qui tient à une connexion n'en est pas une.

Elle sert de **fixture**, jamais de donnée du sommier : rien de son contenu
n'entre dans un registre, une empreinte ou un manifeste.

---

# Autorité d'horodatage de test

`tsa-test-racine.crt`, `tsa-test-requete.tsq`, `tsa-test-reponse.tsr` — une
racine, une requête et une réponse RFC 3161 **engendrées localement** le
27 août 2026, sans réseau. Aucune autorité réelle n'est sollicitée.

    # Racine
    openssl req -x509 -newkey rsa:2048 -nodes -keyout ca.key -out ca.crt \
      -days 3650 -subj "/CN=Racine de test sommieR"

    # Certificat d'autorité, portant l'EKU timeStamping critique
    # (exigé par la RFC 3161 section 2.3)
    openssl req -newkey rsa:2048 -nodes -keyout tsa.key -out tsa.csr \
      -subj "/CN=Autorite d horodatage de test"
    openssl x509 -req -in tsa.csr -CA ca.crt -CAkey ca.key -CAcreateserial \
      -out tsa.crt -days 3650 -extfile ext.cnf -extensions tsa_ext
    # [ tsa_ext ] : basicConstraints=CA:FALSE
    #              keyUsage=critical,digitalSignature,nonRepudiation
    #              extendedKeyUsage=critical,timeStamping

La requête vient de **sommieR lui-même**, non d'`openssl ts -query` :

    empreinte <- openssl::sha256(charToRaw("sommieR : tete de chaine de test"))
    writeBin(tsa_requete(as.raw(empreinte), nonce = 1234567890123),
             "tsa-test-requete.tsq")

    openssl ts -reply -config tsa.cnf -section tsa_config \
      -queryfile tsa-test-requete.tsq -out tsa-test-reponse.tsr

Deux raisons. La requête engendrée par `tsa_requete()` est ainsi **soumise à
une vraie implémentation d'autorité**, qui l'accepte — l'encodeur DER du
paquet est donc éprouvé contre autre chose que lui-même. Et le nonce est
choisi : celui qu'`openssl ts -query` tire fait 64 bits, ce qu'un nombre de R
ne représente pas exactement, si bien qu'aucun test ne pourrait le redonner
à `tsa_horodater()`.

Les valeurs attestées, que les tests asservissent :

| Champ | Valeur |
|---|---|
| empreinte | `38f5282a5c6e0b415f02b0ad7ae7f2d5413e4313fe893c61f484b2c950e4205c` |
| nonce | `11f71fb04cb` (1 234 567 890 123) |
| numéro de série | `11` |
| date attestée | 2026-08-27T06:04:56Z |
| politique | 1.2.3.4.1 |

La vérification de référence passe :

    openssl ts -verify -digest 38f5282a... -in tsa-test-reponse.tsr -CAfile ca.crt
    # Verification: OK

**Pourquoi un vrai jeton.** Un `TSTInfo` reconstitué à la main serait une
imitation de ce que le paquet doit savoir lire : champs facultatifs présents
(`accuracy`, `ordering`, `nonce`, `tsa`), `GeneralizedTime` réel, certificat de
l'autorité encapsulé dans le CMS. Les tests d'analyse ne prouveraient rien
contre un jeton d'autorité réelle. L'engendrer localement plutôt que
d'interroger une autorité publique garde la suite exécutable **sans réseau**.

**Aucune clé privée n'est versée au dépôt.** Ce jeton-ci est figé parce que
les tests d'analyse ont besoin de valeurs stables à asservir. Les tests de
flux, eux, ont besoin d'une autorité qui réponde vraiment — depuis que
`tsa_horodater()` confronte l'empreinte et le nonce, un jeton bricolé ne passe
plus. Ils montent donc leur propre autorité à la volée, dans un répertoire
temporaire (`helper-tsa.R`, `autorite_tsa_de_test()`), et se sautent d'eux-mêmes
là où `openssl` en ligne de commande manque.

Les certificats du jeton figé expirent en 2036 ; le régénérer suit les
commandes ci-dessus.
