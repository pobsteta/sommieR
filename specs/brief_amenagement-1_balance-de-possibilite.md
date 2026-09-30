# Brief — Aménagement, lot 1 : l'aménagement comme objet, et la balance de possibilité qui en découle

*Établi le 30 septembre 2026, à partir du sommier de la forêt domaniale d'Orléans (RECONFORT).*

## Pourquoi ce lot existe

La balance de possibilité (imprimé A50E) confronte les volumes martelés à la
possibilité de l'aménagement. Elle se lit **en cumul, sur la durée de
l'aménagement** : un excès une année se compense par un déficit une autre, et
un nouvel aménagement repart de zéro avec sa propre possibilité.

sommieR sait déjà additionner les martelages (`v_balance_possibilite`), mais
pas ce à quoi il faut les comparer. Trois défauts, par ordre de gravité :

1. **La possibilité vit hors de la chaîne.** Elle est rangée dans une table
   `exercice` à part, et `exercice_definir()` la **remplace en silence**
   (`ON CONFLICT DO UPDATE`). Un paquet dont l'objet est la valeur probante
   compare donc les prélèvements, qui sont attestés, à un chiffre qu'on peut
   modifier après coup sans laisser de trace. Diminuer la possibilité de 2031
   en 2033 pour effacer un excès ne se verrait nulle part.
2. **Il n'y a pas d'aménagement.** La possibilité se saisit année par année, et
   rien ne dit à quel document de gestion chaque année appartient. Le cumul
   court donc sur toute la vie de la forêt, et ne repart jamais de zéro.
3. **Un sommier réel ne peut pas la renseigner.** À Orléans, deux martelages
   de 2026 (244,7 et 151,4 m³, saisis sur Marculus) sont au registre 5, mais
   aucun exercice n'est défini : la section « Balance de possibilité » du
   rapport reste vide.

Ce lot fait de l'aménagement une **écriture** : un acte du registre 1 qui porte
sa période, sa possibilité et sa source. La balance s'en déduit.

## Ce que la vérification a établi

- **Le registre 1 a déjà la bonne case.** Il connaît l'arrêté d'aménagement
  (`type_validation = "arrete"`), l'agrément du PSG (`"agrement"`), l'avenant
  (`"avenant"`) et la portée `"amenagement"` ou `"psg"`. Il ne porte ni
  période, ni possibilité : l'acte est tracé, pas son contenu.
- **La table `exercice` ne sert qu'à la possibilité.** Aucune autre donnée n'y
  est rattachée. Seuls le jeu de démonstration (82 m³/an) et les tests
  l'alimentent.
- **Les martelages portent leur exercice**, dans le payload du registre 5
  (`exercice = 2026`), indépendamment de la date de l'évènement.
- **Le martelé n'est pas le réalisé.** La vue somme séparément martelage,
  produit accidentel et bois délivré d'un côté, coupe réalisée de l'autre,
  pour ne pas compter deux fois la même coupe. Ce choix reste.

### Ce que dit un aménagement réel de la forêt domaniale d'Orléans

*Ajout du 30 septembre 2026, après recherche des arrêtés en ligne.*

- La forêt domaniale d'Orléans (34 698,73 ha, identifiant ONF F09381U) compte
  **quatre massifs, chacun avec son aménagement** : Orléans, Ingrannes,
  Lorris-Châteauneuf et Lorris-Les Bordes.
- **Seul l'aménagement de Lorris-Les Bordes est publié en ligne.** Il a été
  approuvé par un arrêté ministériel du 9 août 2019 (BO agri, semaine 33), pour
  la période 2019-2038, sur 8 673,16 ha. **L'arrêté ne fixe aucune possibilité
  en m³.** Son article 4 fixe des **surfaces par groupe** : 2 648,31 ha en
  régénération, dont 2 026,57 ha à ouvrir ; 1 576,05 ha de jeunesse ;
  3 016,81 ha en amélioration ; 817,61 ha en futaie irrégulière. Le volume
  n'apparaît que dans le document d'aménagement, comme **récolte prévisible**
  pilotée en surface terrière : 37 215 m³/an, soit 4,4 m³/ha/an. Le document
  précise que « la notion de tarif aménagement est abandonnée ».
- **Le massif d'Orléans, dont dépend la zone RECONFORT, n'a aucun
  aménagement publié.** L'ancien couvrait 2005-2024, sur environ 6 260 ha, en
  série unique (DOCOB Natura 2000 de 2005). Un nouvel aménagement 2025-2044
  était en consultation en 2023 (contribution de Loiret Nature
  Environnement), mais nous n'avons trouvé ni son arrêté ni ses chiffres. Il
  faut les demander à l'agence ONF Val-de-Loire.

**Ce qui change dans la conception.** La possibilité en m³ fixée par l'acte
reste le cas du PSG et des aménagements anciens. Pour un aménagement récent,
le volume est une **prévision** du document, et l'acte fixe des surfaces.
L'aménagement porte donc aussi :
- `nature_volume` : `possibilite` (fixée par l'acte) ou `recolte_prevue`
  (récolte prévisible du document). Le rapport ne présente jamais une prévision
  comme une possibilité.
- `groupes` : les surfaces par groupe que l'arrêté fixe.
- `surface_regeneration_ha` : la surface à ouvrir en régénération sur la
  période. C'est le socle d'une future balance en surface (lot 2).

La question ouverte « surface ou volume ? » est ainsi tranchée : les deux sont
gardés, la balance en volume vient dans ce lot, celle en surface dans le
suivant.

## Décisions de conception

1. **L'aménagement est une écriture du registre 1.** L'arrêté (domanial,
   communal) ou l'agrément (PSG) gagne un bloc `amenagement` :
   - un **identifiant** et un **libellé** (« Aménagement 2026-2045 ») ;
   - une **période** : `annee_debut` et `annee_fin`, exercices compris ;
   - une **possibilité annuelle en volume** (m³/an), éventuellement **ventilée
     par nature de coupe** (régénération, amélioration) quand l'aménagement la
     ventile ;
   - la **surface** à laquelle elle s'applique (ha), et la **série** si la
     forêt en compte plusieurs ;
   - la **source** : référence de l'arrêté ou de l'agrément, page ou tableau
     du document où la possibilité est fixée.

   L'acte étant chaîné, la possibilité l'est aussi : la changer suppose une
   nouvelle écriture.
2. **Une possibilité change par avenant, jamais par réécriture.** Un avenant
   (`type_validation = "avenant"`) désigne l'aménagement qu'il modifie et
   l'exercice à partir duquel il s'applique. Les exercices antérieurs gardent
   l'ancienne valeur. La balance cite, pour chaque exercice, l'acte dont vient
   sa possibilité.
3. **Deux aménagements ne se chevauchent pas.** Écrire un aménagement dont la
   période recouvre celle d'un aménagement en vigueur est refusé. Une
   révision anticipée clôt d'abord l'ancien par avenant, en avançant son
   `annee_fin`.
4. **La balance se calcule par aménagement.** Le cumul court de
   `annee_debut` à l'exercice courant et **repart de zéro** avec chaque
   nouvel aménagement. Un exercice de la période sans aucune coupe pèse pour
   toute sa possibilité, comme aujourd'hui. Un martelage hors de toute période
   d'aménagement est montré à part : il ne se compare à rien, et le rapport le
   dit au lieu de l'ignorer.
5. **La table `exercice` devient une lecture, puis une reprise.** La balance
   ne la lit plus. Un sommier qui y a des lignes se voit proposer
   `sommier_reprendre_exercices()`, qui les transcrit en un aménagement repris
   (bloc `reprise`, source « table exercice »), en regroupant les années
   consécutives de même possibilité. Rien n'est effacé, et la transcription
   dit qu'elle en est une (voir le brief Reprise, lot 1). Après reprise,
   `exercice_definir()` refuse d'écrire.
6. **La tolérance se déclare avec l'aménagement.** En privé, le PSG admet un
   écart de ± 4 ans de programme. En public, l'écart admis dépend de
   l'aménagement. L'aménagement porte donc `tolerance_ans` (facultatif). Le
   rapport dit « dans la tolérance », « hors tolérance » ou « tolérance non
   déclarée », et **ne juge pas plus loin**.
7. **Les indices de nemeton éclairent la possibilité, ils ne la fixent pas.**
   La possibilité est un acte d'autorité : un arrêté, un agrément. Un volume
   estimé par télédétection ou par inventaire n'en est pas un. Les indices de
   nemeton servent à deux choses, et à deux choses seulement :
   - **proposer un ordre de grandeur** au moment de saisir un aménagement qui
     n'existe que sur papier, pour repérer une faute de frappe (un zéro de
     trop) ;
   - **mettre la balance en regard** de ce que la forêt porte et produit, dans
     le rapport, sans que rien de cela n'entre dans la chaîne.

   Voir « Ce que nemeton peut apporter ».

## Livrables

- `registre1_validation()` gagne `amenagement` (liste) pour les types
  `arrete`, `agrement` et `avenant`. Le schéma passe en `r1-1.2.0`, et les
  anciens actes restent valides.
- `sommier_amenagement()` : écrit l'acte d'un aménagement. C'est un
  raccourci au-dessus de `registre1_validation()` qui contrôle la période,
  le non-chevauchement et la ventilation (sa somme doit égaler le total).
- `sommier_avenant_possibilite()` : l'avenant qui change la possibilité ou la
  fin de période, à partir d'un exercice donné.
- Vues `v_amenagement` (les aménagements et leurs avenants, avec la
  possibilité en vigueur par exercice) et `v_balance_possibilite` réécrite
  (colonnes `amenagement_id`, `exercice`, `possibilite_m3_an`, `source_acte`,
  `volume_martele_m3`, `volume_realise_m3`, `balance_exercice_m3`,
  `balance_cumulee_m3` remise à zéro par aménagement). Une vue
  `v_martelage_hors_amenagement` recense ce qui ne se compare à rien.
- `sommier_balance_possibilite()` : même signature, résultat par aménagement ;
  `tolerance_ans` lu dans l'aménagement quand il n'est pas passé.
- `sommier_reprendre_exercices()` : transcrit la table `exercice`.
- Rapport : la section « Balance de possibilité » nomme l'aménagement, sa
  période, sa possibilité et l'acte qui la fixe. Elle trace le cumul par
  aménagement, avec la tolérance quand elle est déclarée, et liste les
  martelages hors aménagement. Un encadré « Ce que la forêt porte » reprend
  les indices de nemeton quand ils sont fournis (voir plus bas), hors
  chaîne.
- Le jeu de démonstration Couchey passe par un aménagement (2016-2035,
  82 m³/an) au lieu de `exercice_definir()`.

## Ce que nemeton peut apporter

*Inventaire du paquet nemeton (lecture seule) et du projet RECONFORT
`20260701_204501_ltcp`, forêt domaniale d'Orléans.*

**nemeton ne calcule aucune possibilité.** Aucun code ne fixe un volume
annuel exploitable, ni ne compare un prélèvement à une possibilité. La
décision 7 n'est donc pas une précaution de principe : il n'y a rien à
reprendre tel quel. Ce qui existe sert d'ordre de grandeur ou de contrôle.

### Ce qui peut orienter la saisie ou éclairer la balance

| Indice nemeton | Ce qu'il donne | Usage proposé | Réserve |
|---|---|---|---|
| `indicateur_p1_volume()` → `P1` | Volume sur pied, m³/ha, par unité : tarifs IFN 2016 (V = a·D^b·H^c) sur la hauteur LiDAR HD (90e centile du MNH) | Encadré « Ce que la forêt porte » : volume sur pied par unité et total ; possibilité rapportée au capital (% du volume par an) | Diamètre et densité synthétisés depuis la hauteur quand l'inventaire manque ; aucune précision déclarée. À Orléans : 0 à 424 m³/ha, médiane 334. |
| `completer_volume_ifn()` → `volume_source` | Provenance du volume : `mesure`, `ifn_ser`, `ifn_greco`, `ifn_national` | Afficher la provenance à côté de chaque volume, et ne jamais mêler une référence régionale à une mesure sans le dire | — |
| `ifn_taux_prelevement()` / `ifn_prelevement_essence_ser()` | **Prélèvement observé** par l'IFN, m³/ha/an, par sylvoécorégion (SER) et essence ; moyenne nationale 2,84 m³/ha/an | **Contrôle de vraisemblance à la saisie** : la possibilité ramenée à l'hectare (m³/ha/an) est comparée au prélèvement IFN de la SER. Un écart de plus d'un facteur 3 déclenche un avertissement, jamais un refus. | La documentation de nemeton le dit elle-même : c'est ce qui a été coupé, pas ce qui devrait l'être. Il repère un zéro de trop, il ne juge pas une possibilité. |
| `indicateur_t3_coupes_rases()` (SUFOSAT) | Part de l'unité en coupe rase détectée sur 5 ans (probabilité ≥ 0,9) | **Contrôle de complétude** : une unité avec une coupe détectée et aucun martelage au registre 5 sur la période est signalée sous la balance (« prélèvement possible non inscrit ») | Détection, pas constat, au même titre que les détections RECONFORT : elle ne corrige pas la balance, elle dit qu'elle est peut-être incomplète. |
| `action_plan.json` (nemetonshiny) | 46 actions sur 20 ans à Orléans (12 éclaircies, 3 coupes rases…), avec année cible et unité | **Programme prévisionnel** : volume planifié par exercice, mis en regard de la possibilité | C'est le plan de nemeton, pas l'aménagement de l'ONF. Il se présente comme tel, et jamais comme la possibilité. |
| `marculus_tiges.json` (nemetonshiny) | Tiges martelées : essence, classe, volume, surface terrière, **tarif de cubage** (`SCHAEFFER_RAPIDE:12`) | Déjà versé au registre 5 (deux martelages de 2026). Le versement devrait **recopier le tarif**, que l'observation dit aujourd'hui « non renseigné » alors que chaque tige le porte. | Hors de ce lot : c'est un correctif du versement, noté ici parce que la balance additionne ces volumes. |

### Ce qui n'est pas utilisable en l'état

- **L'accroissement.** `indicateur_p2_station()` ne donne un accroissement
  (m³/ha/an) qu'en mode ancien, depuis une table générique de 30 lignes. En
  mode LiDAR, celui du projet d'Orléans, `P2` est une **hauteur** (indice de
  station en mètres), calculée sur un âge fixé à 60 ans pour toutes les
  unités. La valeur 20,71 m s'y répète d'une unité à l'autre, ce qui est
  suspect. Aucun calcul du type « possibilité = accroissement × surface » n'est
  donc possible honnêtement.
- **`volume_mobilisable()`** a une **erreur d'unité** (`R/volume_mobilisable.R:239` :
  un volume multiplié par un taux annuel puis par une durée). L'exemple de sa
  documentation fait passer 300 m³/ha à 12 000 m³/ha. À corriger dans nemeton
  avant tout usage.
- **Les biomasses et le carbone** (`C1`, `E1`) répondent à une autre question.

### Ce que sommieR en prend

- **Rien n'entre dans la chaîne.** Les indices sont fournis au rapport,
  comme le fond cadastral : `sommier_rapport_quarto(indices = )` accepte un
  tableau par unité (volume sur pied, provenance, date du calcul), et
  `sommier_amenagement(controle = )` accepte le prélèvement IFN de la SER
  pour l'avertissement de saisie.
- **Un lecteur facultatif**, `sommier_lire_indices_nemeton(projet)`, lit
  `data/indicators.parquet` d'un projet nemeton (`arrow` en Suggests) et le
  rapproche des unités du sommier. La clé de rapprochement reste à fixer
  (voir les questions ouvertes).
- **Chaque indice est daté et sourcé dans le rapport**, avec sa provenance
  (`volume_source`) et son niveau de donnée (NDP 1 pour le LiDAR HD
  d'Orléans).

## Critères d'acceptation

- La possibilité d'un exercice ne peut changer que par un nouvel acte chaîné.
  Modifier la table `exercice` après reprise n'a aucun effet sur la balance.
- Deux aménagements qui se chevauchent sont refusés à l'écriture, et le
  message nomme celui qui est en vigueur.
- Le cumul repart de zéro au premier exercice d'un nouvel aménagement.
- Un avenant de 2031 change la possibilité de 2031 et des exercices
  suivants, pas celle de 2030. La balance cite l'avenant pour 2031.
- Un martelage de 2026 sans aménagement couvrant 2026 apparaît dans
  `v_martelage_hors_amenagement` et dans le rapport. Il n'est pas perdu.
- La somme d'une ventilation par nature égale la possibilité totale, sinon
  l'acte est refusé.
- La reprise de la table `exercice` de la démonstration donne un aménagement
  unique de 82 m³/an, marqué `reprise`, et une balance identique à
  l'ancienne.
- Aucun indice de nemeton n'entre dans la chaîne, et le rapport les présente
  comme des estimations, avec leur source et leur date.
- Saisir 820 m³/an au lieu de 82 déclenche l'avertissement de vraisemblance
  quand le prélèvement IFN de la SER est fourni. L'aménagement s'écrit quand
  même : c'est un avertissement, pas un refus.
- Une unité où SUFOSAT détecte une coupe rase sans martelage inscrit sur la
  période est signalée sous la balance, et la balance n'est pas modifiée.

## Questions ouvertes

- **Orléans : quel aménagement ?** Il faut l'arrêté du massif d'Orléans
  2025-2044, ou la prorogation de celui de 2005-2024 : ses groupes, sa surface
  à régénérer, et la récolte prévue au document. Il n'est pas publié en ligne
  (voir plus haut). L'aménagement est un document de l'ONF : on le transcrit,
  on ne l'invente pas.
- **PSG par unité.** Un PSG fixe souvent un programme de coupes par unité et
  par année, plutôt qu'un volume annuel global. Le suivre à l'unité serait un
  lot 2.
- **Rapprocher les unités de nemeton et du sommier.** nemeton identifie ses
  unités par `ug_id` et un libellé (« … parcelle 1039 »), le sommier par un
  UUID et un `numero_affichage`. La base d'Orléans ayant été versée depuis ce
  projet, la clé existe sans doute au versement : il faut la retrouver et la
  garder, plutôt que d'apparier par le libellé.
- **Seuil de l'avertissement de saisie.** Un facteur 3 entre la possibilité à
  l'hectare et le prélèvement IFN de la SER repère une faute de frappe sans
  gêner un aménagement de rattrapage ou de conversion. À valider par qui connaît
  les aménagements de la région.
