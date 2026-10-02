# Brief — Sommier, lot 1 : le registre imprimé

*Établi le 2 octobre 2026, à la demande de distinguer le document « Sommier »
du « Bilan de gestion ».*

## Pourquoi ce lot existe

sommieR édite un seul document, le rapport Quarto de
`sommier_rapport_quarto()`. C'est une **synthèse** : sur une période, il
additionne les coupes par exercice, ventile les travaux, dessine des cartes,
calcule la balance, et y joint ce qui vient d'ailleurs — référence IFN,
indices nemeton, coupes SUFOSAT, espèces observées — en le disant hors chaîne.
Il sert à réviser un plan : bilan de l'aménagement précédent, gestion
antérieure du PSG, évaluation de fin de plan CT88. Il s'intitulera désormais
« Bilan de gestion ».

Le **sommier**, lui, n'a pas de document. C'est le registre : les neuf
registres de la base, chaque écriture chaînée à la précédente. On peut le
vérifier (`sommier_verifier()`) et l'exporter pour un tiers
(`sommier_exporter_manifeste()`), mais pas le lire comme on lisait le classeur
A50 : registre par registre, ligne après ligne, avec la fiche A10 de tenue en
tête. C'est pourtant ce qu'on consulte pour le visa annuel, ce qu'on transmet
à un successeur, ce qu'on ouvre devant un contentieux de limite.

Ce lot édite ce document : **le sommier imprimé**, l'inverse du bilan.

| | Bilan de gestion | Sommier imprimé |
|---|---|---|
| Ce qu'il montre | Une synthèse : sommes, cartes, balance | Chaque écriture, telle qu'elle est chaînée |
| Période | Bornée, celle d'un plan | Tout, depuis la genèse, ou jusqu'à un visa |
| Ce qui vient d'ailleurs | Oui, dit hors chaîne | Rien |
| Usage | Réviser un plan | Consulter, viser, transmettre |

## Ce que la vérification a établi

- **Tout ce qu'il faut imprimer est déjà dans la base.** Chaque écriture
  porte son numéro d'ordre (`seq`), sa date d'événement et sa date de saisie,
  son auteur, son NDP, l'unité de gestion, la version de son schéma, la
  rectification qu'elle opère (`corrige_id`), son empreinte et celle de la
  précédente. La reprise de l'existant porte sa pièce (`payload$reprise`).
- **Les vues de consultation cachent les écritures rectifiées**
  (`v_entree_courante`) : c'est voulu pour une synthèse, pas pour un registre.
  Le classeur papier interdisait la rature et imposait la mention
  rectificative ; le registre imprimé doit montrer les deux lignes.
- **La fiche A10 existe en base.** `v_tenue_sommier` donne, par exercice, l'acte
  de visa du registre 1, s'il est signé, s'il est horodaté, et la tête de
  chaîne visée ; les ancrages sont dans `ancrage`. `sommier_verifier_visas()`
  confronte chaque visa à la chaîne.
- **Orléans n'a encore ni visa ni ancrage.** La base de référence compte
  40 écritures : 8 au registre 2 (les reconnaissances de limite du
  2 octobre 2026), 2 au registre 5, 30 au registre 8 ; aucune rectification,
  aucune transcription. Un sommier imprimé d'Orléans aurait donc une fiche
  A10 vide, et le dirait.
- **Les registres 3 et 7 portent des données personnelles** : titulaires de
  baux, affouagistes, tiers des écritures comptables. Le bilan les écarte déjà
  du PSG ; un sommier transmis hors du gestionnaire doit pouvoir les masquer.

## Décisions de conception

1. **Le sommier imprimé est le registre, pas une synthèse.** Une ligne par
   écriture, sans somme, sans carte, sans estimation. Rien de ce qui n'est pas
   dans la chaîne n'y figure.

2. **Registre par registre, dans l'ordre de la chaîne.** Les registres 1 à 9
   se suivent, chacun avec son imprimé A50 de référence (A10, A40, A50C…).
   Dans un registre, les écritures se lisent dans l'ordre de leur numéro,
   c'est-à-dire de leur inscription, comme les lignes d'un classeur ; la date
   d'événement est une colonne. Une transcription, inscrite après coup, se lit
   donc là où elle a été inscrite, avec sa pièce.

3. **La rectification se montre, elle ne s'efface pas.** Une écriture
   rectifiée reste à sa place, marquée « rectifiée par le n° X » ; celle qui la
   rectifie porte « rectifie le n° Y ». C'est la mention rectificative du
   classeur.

4. **Chaque ligne dit d'où elle vient.** Numéro, date d'événement, date de
   saisie, auteur, NDP, unité de gestion, provenance (constatée, ou transcrite
   avec la nature et la référence de sa pièce), puis le contenu de l'écriture
   et le début de son empreinte (douze caractères). Les empreintes complètes
   sont en annexe, dans l'ordre de la chaîne : c'est ce qu'un auditeur
   recopie pour vérifier.

5. **Le contenu suit l'imprimé, avec un repli générique.** Chaque type
   d'écriture a ses colonnes, reprises de l'imprimé A50 qu'il remplace (un
   martelage : exercice, nature, volume, surface, essence, coupon). Un type
   sans gabarit s'imprime en « clé : valeur », lisible, jamais omis : un
   registre imprimé ne perd pas de ligne parce que sa mise en page n'est pas
   prévue.

6. **La fiche A10 ouvre le document.** Par exercice : l'acte de visa, son
   autorité, la tête visée, signé ou non, horodaté ou non. Puis les ancrages.
   Un exercice sans visa figure, marqué « non visé ». En tête, l'état de la
   chaîne au moment de l'édition : intègre ou non, numéro et empreinte de
   tête.

7. **Une édition peut s'arrêter à un visa.** `jusqu_au_visa = 2025` imprime le
   sommier tel qu'il était quand l'exercice 2025 a été visé : les écritures
   jusqu'à la tête signée, pas au-delà. Le document correspond alors exactement
   à ce que le signataire a attesté.

8. **Le document n'est pas la preuve.** Comme le bilan, il le dit : la valeur
   probante reste dans la chaîne, et `sommier_exporter_manifeste()` la
   transporte. Le sommier imprimé permet de lire et de recopier les empreintes,
   pas de s'en dispenser.

9. **Un sommier à transmettre masque les personnes.** À `public = TRUE`, les
   noms de tiers des registres 3 et 7 (titulaires, affouagistes, tiers d'une
   écriture) sont remplacés par « (masqué) ». La ligne, son montant et son
   empreinte restent : on voit qu'une écriture existe, on ne voit pas qui elle
   nomme. Les photos des constats ne sont pas reproduites, seulement leurs
   empreintes.

10. **Même mécanique que le bilan.** Extraction dans un RDS, puis rendu Quarto
    en HTML autoportant ou en PDF A4. Le rendu ne touche pas la base et se
    rejoue à l'identique. Le PDF passe les registres larges en paysage.

## Livrables

**Lot 1 : le registre imprimé**

- `sommier_registre(con, foret_id, registres = 1:9, jusqu_au_visa = NULL)` :
  l'extraction, rectifiées comprises, avec la fiche A10, les ancrages, l'état
  de la chaîne et les empreintes. Un `data.frame` par registre, et un objet
  de classe `sommier_registre`.
- `sommier_registre_quarto(con, foret_id, chemin, format = "html",
  registres = 1:9, jusqu_au_visa = NULL, public = FALSE)` : le document
  « Sommier de la forêt », sur un gabarit `inst/quarto/sommier.qmd`.
- Les colonnes par type d'écriture, d'après les imprimés A50 ; le repli
  « clé : valeur » pour les autres.
- Dans le bilan, un renvoi d'une ligne : « Le détail de chaque écriture est
  dans le sommier imprimé (`sommier_registre_quarto()`). »

**Lot 2 : le visa sur le document**

- Le sommier imprimé arrêté à un visa porte, en tête, la signature et le
  jeton d'horodatage vérifiés (`sommier_verifier_visas()`), avec le
  certificat du signataire. Le lecteur sait qui a visé quoi, et quand.

## Critères d'acceptation

- Le sommier imprimé de la démo de Couchey montre chaque écriture de la
  chaîne, dans l'ordre, et le nombre de lignes imprimées est égal au nombre
  d'écritures (`count(*)` de `entree_sommier`), rectifiées comprises.
- Une écriture rectifiée et sa rectification apparaissent toutes deux, avec
  leurs mentions croisées.
- Une transcription montre sa pièce ; un constat ne montre pas de pièce.
- L'annexe des empreintes reproduit, dans l'ordre, les empreintes que
  `sommier_verifier()` recalcule.
- `jusqu_au_visa` s'arrête à la tête signée de l'exercice ; un exercice non
  visé est refusé.
- À `public = TRUE`, aucun nom de tiers des registres 3 et 7 n'apparaît, et
  le nombre de lignes ne change pas.
- Le rendu ne modifie pas la chaîne : même tête avant et après.

## Questions ouvertes

- **L'ordre dans un registre : inscription ou événement ?** Ce brief retient
  l'ordre d'inscription, celui de la chaîne et du classeur. Un gestionnaire
  peut préférer lire ses martelages dans l'ordre des exercices ; un tri par
  date d'événement serait alors une option, pas le défaut.
- **Les géométries.** Le registre imprimé dit qu'une écriture est localisée
  (point, ligne, surface) mais ne dessine rien. Faut-il une carte par
  registre, en annexe, ou laisser les cartes au bilan ?
- **Le nom de la fonction du bilan.** `sommier_rapport_quarto()` deviendrait
  `sommier_bilan_quarto()`, l'ancien nom restant un alias, pour que les deux
  documents se nomment l'un par rapport à l'autre.
