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
