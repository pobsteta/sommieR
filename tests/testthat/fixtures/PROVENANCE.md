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

`edigeo-45188000ZK01.tar.bz2` — feuille cadastrale ZK01 de Loury (45188),
téléchargée le 30 septembre 2026 depuis :

    https://cadastre.data.gouv.fr/data/dgfip-pci-vecteur/latest/edigeo/feuilles/45/45188/edigeo-45188000ZK01.tar.bz2

Plan Cadastral Informatisé, DGFiP, sous Licence Ouverte. 48 Ko. Lot daté du
17 février 2026 (`TDASD08` de son `.THF`).

**Pourquoi une seconde feuille.** La feuille de Couchey ne porte que des
bornes, des détails linéaires et des voies. Celle de Loury porte tout ce que
les éléments du plan doivent savoir lire : un détail ponctuel nommé
(« pylone télécom »), un signe de limite orienté, une surface, des cours
d'eau, des bâtiments, et des noms de voies posés mot par mot. Mêmes règles
que ci-dessus : fixture, jamais donnée du sommier.

---

# Photos de test

`photo-exif-ii.jpg`, `photo-exif-mm.jpg`, `photo-sans-exif.jpg` — trois
images de 16 × 16 pixels **engendrées localement** le 30 septembre 2026 par
Pillow 10.2. Les deux premières portent un en-tête EXIF, l'une en ordre
d'octets Intel (`II`), l'autre Motorola (`MM`) : date de modification
2026:10:12 10:00:00, date de prise de vue 2026:10:12 10:31:05, position
47° 58' 37,2" N, 2° 1' 50,4" E. La troisième n'en porte aucun.

**Pourquoi Pillow.** Le lecteur EXIF de `sommier_deposer_photo()` est écrit
dans le paquet ; l'éprouver sur des en-têtes qu'il aurait lui-même fabriqués
ne prouverait rien. Pillow est un autre producteur, et le plus répandu.

    from PIL import Image
    from PIL.TiffImagePlugin import IFDRational as R
    ex = Image.Exif(); ex.endian = "<"   # ">" pour MM
    ex[0x0132] = "2026:10:12 10:00:00"
    ex[0x8769] = {0x9003: "2026:10:12 10:31:05"}
    ex[0x8825] = {1: "N", 2: (R(47,1), R(58,1), R(372,10)),
                  3: "E", 4: (R(2,1), R(1,1), R(504,10))}
    Image.new("RGB", (16, 16), (90, 120, 60)).save(
        "photo-exif-ii.jpg", "JPEG", exif=ex.tobytes(), quality=80)

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

---

# Statuts des espèces (BDC Statuts, API TAXREF)

`statuts-taxref-orleans.json` — réponses réelles de l'API TAXREF
(`https://taxref.mnhn.fr/api`), obtenues le 17 octobre 2026 avec l'en-tête
`Accept: application/hal+json;version=1`, réunies en un seul objet JSON :

- `taxrefVersions/current` : la version courante de TAXREF (18.0) ;
- pour chacun des taxons 3619 (Pic mar), 4272 (Pouillot siffleur),
  88766 (Laîche pendante), 851674 (Couleuvre helvétique) et 2660 (Balbuzard
  pêcheur), la réponse de
  `status/search/lines?taxrefId=<CD_REF>&latitude=47.95&longitude=2.15&page=1&size=1000`,
  soit les statuts de la BDC Statuts qui s'appliquent en forêt d'Orléans
  (commune INSEE 45142, Loiret, Centre-Val de Loire).

BDC Statuts, PatriNat (OFB, MNHN, CNRS, IRD). 44 Ko.

**Pourquoi des réponses figées.** Les tests de `sommier_statuts_taxref()`
tournent sans réseau : ils remplacent l'appel à l'API par ces réponses. Le
balbuzard y est parce qu'il est sensible (`SENSREG`) en Centre-Val de Loire :
c'est lui qui montre qu'un document public ne place pas une espèce sensible
dans une unité. Mêmes règles que ci-dessus : fixture, jamais donnée du
sommier.
