# Changelog

## sommieR 0.28.0

Travaux, lot 1 : le registre du suivi sylvicole (brief `travaux-1`).

- **L’intervention se code et se localise.**
  [`registre6_travaux()`](https://pobsteta.github.io/sommieR/reference/registre6_travaux.md)
  gagne `code_travaux`, dans la nomenclature fermée
  `SOMMIER_CODES_TRAVAUX`, celle du brief métier : 15 codes en 8
  familles (préparation, plantation, protection, éducation,
  régénération, biodiversité, desserte, parcellaire). Le code fixe les
  unités et les formes de géométrie admises : une clôture se trace en
  ligne, en mètres ; un cloisonnement se mesure en mètres ou en hectares
  ; un regarni se place en surface ou en point. S’y ajoutent la
  modalité, l’essence objectif, l’exécution (régie, entreprise),
  l’intervenant, la date de réception, la géométrie, la précision GNSS
  et les photos.
- **Prévu, reporté ou non prévu.** `prevu` est un fait constaté à la
  réception ; hors `prevu`, `motif_ecart` est obligatoire. Aucun statut
  « programmé » n’entre au registre.
- **Le résultat quitte l’intervention.** Une placette permanente
  ([`registre6_placette()`](https://pobsteta.github.io/sommieR/reference/registre6_placette.md),
  [`sommier_installer_placette()`](https://pobsteta.github.io/sommieR/reference/sommier_installer_placette.md))
  suit une plantation ou une régénération de son unité ; chaque passage
  s’inscrit en contrôle
  ([`registre6_controle()`](https://pobsteta.github.io/sommieR/reference/registre6_controle.md),
  [`sommier_controler_placette()`](https://pobsteta.github.io/sommieR/reference/sommier_controler_placette.md))
  : plants comptés, vivants, hauteur, abroutis, concurrence, et le
  travail qui s’impose ensuite. Une placette inconnue, un code de
  placette déjà pris dans l’unité, un second contrôle le même jour, plus
  de vivants que de plants sont refusés.
- **Les vues calculent, rien ne s’inscrit deux fois.**
  `v_controle_plantation` donne l’âge, le taux de reprise, la densité à
  l’hectare et la part d’abroutis ; `v_placette` liste les placettes
  avec les travaux suivis. `v_travaux` gagne ses colonnes nouvelles en
  fin, et ne compte plus que les interventions.
- **Registre 6 en `r6-1.2.0`.** Les interventions déjà chaînées, sans
  type d’entrée, restent des travaux et se relisent à l’identique :
  [`registre6_depuis_payload()`](https://pobsteta.github.io/sommieR/reference/registre6_depuis_payload.md)
  route la relecture.
- **La démo de Couchey** code sa plantation de 2022 (UG 35) et l’y suit
  sur trois placettes, contrôlées en 2023 et en 2025 ; le dégagement de
  2024 perd son taux de reprise et devient « non prévu », avec son
  motif.

## sommieR 0.27.1

- **Le rapport s’intitule « Bilan de gestion ».** « Gestion antérieure »
  ne disait plus ce que le document contient. Un sous-titre dit la
  forêt, la période et l’objet du bilan selon le référentiel : bilan de
  l’aménagement précédent, gestion antérieure du plan simple de gestion,
  ou évaluation de fin de plan (CT88).

## sommieR 0.27.0

Les espèces observées dans la forêt et à ses abords, nommées dans TAXREF
(lot 1 du brief « Patrimoine »).

- **TAXREF fait référence.**
  [`sommier_taxref()`](https://pobsteta.github.io/sommieR/reference/sommier_taxref.md)
  lit TAXREF, le référentiel taxonomique national, dans l’archive Darwin
  Core que PatriNat publie sur l’IPT de GBIF France, et la garde en
  cache, réduite aux espèces et à leurs noms valides. La version est lue
  dans l’archive (TAXREF v18.0 aujourd’hui) ; une archive qui ne la dit
  pas est refusée. Ni le rapport ni les fonctions qui s’en servent ne
  dépendent des serveurs du Muséum, coupés depuis l’été 2025.
- **[`sommier_especes_observees()`](https://pobsteta.github.io/sommieR/reference/sommier_especes_observees.md)**
  rend les espèces que d’autres ont observées dans la forêt élargie d’un
  tampon (GBIF, par `rgbif`), une ligne par `CD_REF` : deux synonymes
  sont une espèce. Le nom de GBIF est rapproché de TAXREF dans le même
  règne, hors emplois erronés ; un homonyme se départage par l’auteur,
  et un nom que GBIF écrit autrement se retente sous le nom d’origine de
  l’observation. Ce qui reste ambigu est compté à part, pas deviné. Une
  observation n’est placée dans une unité que si sa position est connue
  à `incertitude_max_m` près.
- **Hors registre.** Rien n’entre dans la chaîne : le registre 9 et
  l’IBP ne changent pas.
- **Le rapport** gagne `especes_observees` : une sous-section du
  patrimoine liste ces espèces par groupe, avec leur `CD_REF`, dit la
  source, la date, les filtres, la version de TAXREF et les noms non
  rapprochés, signale celles qui ont aussi une fiche au registre 9 et
  cite les jeux de données avec leur licence. Un document public ne les
  rattache à aucune unité.
- `rgbif` rejoint les Suggests.

## sommieR 0.26.4

- **Les registres portent leurs accents.** `SOMMIER_REGISTRES$nom` dit «
  Coupes & récoltes », « Comptabilité » et « Évènements & faune », dans
  le rapport comme dans les messages.

## sommieR 0.26.3

- **Les travaux nomment leurs unités.** Comme les coupes, le tableau des
  travaux du rapport garde une ligne par année, nature et provenance, et
  liste les unités de gestion concernées. Des travaux à l’échelle de la
  forêt, une desserte par exemple, n’en nomment aucune.

## sommieR 0.26.2

- **Patrimoine remarquable.** Une espèce n’a pas d’appellation : le
  tableau du rapport la nomme par son nom français, au lieu d’un tiret.
- **Éléments utiles à l’IBP.** Le tableau a des en-têtes lisibles
  (Facteur IBP, Élément, Valeur, Unité, Entrées) au lieu des noms de
  colonnes.
- **Les cartes sous leur titre.** La carte du patrimoine remarquable se
  plaçait avant le titre de sa section, sous l’équilibre forêt-gibier ;
  elle suit maintenant le tableau du patrimoine. La carte des détections
  en attente suit leur liste, avant les suites données sur le terrain,
  sous lesquelles elle tombait dès qu’un constat existait.

## sommieR 0.26.1

- **Les coupes nomment leurs unités.** Dans le rapport, le tableau «
  Coupes et récoltes » garde une ligne par exercice, nature et
  provenance, et liste les unités de gestion parcourues (« 1110, 1123,
  1124 »). « Entrées » compte les martelages de la ligne.
- **La surface d’une unité compte une fois.** Plusieurs coupons d’une
  même unité ne multiplient plus sa surface : elle vaut la surface de
  l’unité, ou la plus grande saisie. Les écritures sans unité gardent
  leurs surfaces additionnées.

## sommieR 0.26.0

Le formulaire de constat des limites selon le type d’élément.

- **Le type d’abord.** Dans le projet QField des limites, un constat
  commence par le type d’élément : point (borne, signe, détail
  ponctuel), ligne, surface ou hors plan.
  - Le type proposé est celui de l’élément le plus proche, toutes formes
    confondues. Une surface se mesure à son contour, et une borne à
    moins de 2 m l’emporte.
  - La liste des éléments ne montre que ceux du type choisi, et propose
    le plus proche à 30 m. Près d’une borne, choisir « ligne » vise la
    voie d’à côté. Avant, la borne était toujours retenue.
- **L’état suit le type, et il est obligatoire.** Il est lu dans une
  table des états du GeoPackage, filtrée par le type. Changer de type
  vide l’état, et un formulaire sans état ou avec un état d’un autre
  type ne s’enregistre pas.
  - Point : en place, endommagé, non retrouvé, détruit.
  - Ligne, par sa visibilité : visible, partiellement visible, peu
    visible, non visible.
  - Surface : conforme au plan, modifiée, dégradée, disparue.
  - Tous : inaccessible. Hors plan : hors plan.
- `SOMMIER_ETATS_PAR_FORME` donne ces listes. `SOMMIER_ETATS_LIMITE` les
  réunit.
- **Registre 2 en `r2-1.4.0`.** Le constat recopie la forme de l’élément
  (`element_pci$forme`), et un état hors de la liste de sa forme est
  refusé, à la validation comme à l’import. L’import refuse aussi un
  type qui n’est pas la forme de l’élément. Les constats et les projets
  antérieurs, sans forme, restent valides avec les états d’une borne.
- **La couleur de la dernière visite**, sur le terrain et dans le
  rapport, range les nouveaux états : vu, vu en défaut, perdu (non
  retrouvé, détruit, non visible, disparue), à voir.

## sommieR 0.25.0

Du constat de terrain au registre 5 : le produit accidentel d’une
détection confirmée.

- [`sommier_produit_accidentel()`](https://pobsteta.github.io/sommieR/reference/sommier_produit_accidentel.md)
  inscrit au registre 5 le produit accidentel (bois sanitaires, chablis)
  qu’une détection confirmée a laissé. L’entrée reprend du constat
  l’unité, la nature et la surface, et y renvoie par `constat_id`. Seul
  le volume est à saisir : il vient du cubage, ni la télédétection ni
  une photo ne le donnent.
- Sont refusés :
  - un constat qui n’est pas la suite d’une détection ;
  - une détection écartée ;
  - une nature qui ne laisse pas de produit accidentel : une
    exploitation ordinaire s’inscrit comme martelage ;
  - un second produit pour le même constat : on corrige alors le
    premier.
- `SOMMIER_NATURES_ACCIDENTELLES` liste ces natures : crise sanitaire,
  tempête, sécheresse, incendie, neige, gel.
- Registre 5 en `r5-1.3.0` : le payload porte `constat_id`, que
  `v_coupe` expose en dernière colonne.
- Le rapport sépare les produits déjà inscrits, avec leur volume, de
  ceux qui restent à inscrire. Une coupe SUFOSAT confirmée dont le
  produit est inscrit depuis le constat est expliquée, quel que soit
  l’exercice d’inscription : elle sort du compte des coupes sans
  martelage.

## sommieR 0.24.1

- **Couleurs du projet QField des limites.** QGIS lit une couleur
  `#RRGGBBAA` comme `#AARRGGBB` : un élément surfacique « à voir »
  s’affichait bleu marine au lieu de rouge, et un « vu en place » brun
  presque invisible au lieu de vert. Le voile se donne désormais en
  `r,g,b,a`, et le modèle est régénéré. Les identifiants de couche ne
  changent pas.
- **Un rapport rendu sans plan cadastral (EDIGEO) le dit** sous «
  Éléments du plan cadastral », au lieu d’omettre la section : un
  lecteur qui cherche les bornes doit savoir qu’elles n’ont pas été
  montrées, non qu’il n’y en a pas.

## sommieR 0.24.0

Le rapport montre ce que le terrain a dit des détections.

- **Une sous-section « Suites données sur le terrain »** sous les
  détections en attente. Pour chaque détection tranchée, elle donne
  l’unité, la source, la surface détectée, le constat (confirmée ou
  écartée), la nature retenue, la surface constatée, la date de visite
  et le nombre de photos. Elle nomme les opérateurs et reprend les
  observations de terrain. Elle n’est pas bornée par la période : le
  sort d’une détection est un état courant.
- **Un rappel du registre 5.** Une détection confirmée en crise
  sanitaire, chablis, sécheresse, incendie, neige ou gel laisse
  peut-être des produits accidentels à y inscrire. Le rapport le signale
  sans l’écrire.
- **La planche photographique des limites sert aussi aux détections**,
  avec les mêmes contrôles : empreinte vérifiée, EXIF déclaré, aucune
  photo dans la version publique. Le paramètre `photos` de
  [`sommier_rapport_quarto()`](https://pobsteta.github.io/sommieR/reference/sommier_rapport_quarto.md)
  désigne le dépôt de tous les constats de terrain.
- **Le sort de chaque coupe SUFOSAT sans martelage.** Le rapport dit si
  elle n’est pas inscrite, si elle attend un constat ou si elle a été
  confirmée, et avec quelle nature. Une coupe écartée sur le terrain
  sort du compte des coupes sans martelage.
- [`sommier_ortho_ign()`](https://pobsteta.github.io/sommieR/reference/sommier_ortho_ign.md)
  : un bloc que le service WMS de l’IGN refuse deux fois est une panne
  du service, et l’erreur le dit par sa classe
  (`sommier_reseau_indisponible`). Le test qui interroge le vrai service
  se saute alors, au lieu d’échouer.

## sommieR 0.23.0

Vérifier sur le terrain ce que la télédétection propose : un projet
QField propre aux détections, à côté de celui des limites.

- [`sommier_projet_qfield_detections()`](https://pobsteta.github.io/sommieR/reference/sommier_projet_qfield_detections.md)
  écrit le projet de tournée : les détections en attente au registre 8,
  numérotées D01, D02… et dessinées par les pixels qui les ont
  produites. Le formulaire propose la détection sous les pieds de
  l’agent et exige un état : confirmé, écarté ou non vu. Une détection
  confirmée exige sa nature (crise sanitaire, chablis, sécheresse, coupe
  programmée…), ce que la télédétection ne sait pas dire.
- [`sommier_importer_qfield_detections()`](https://pobsteta.github.io/sommieR/reference/sommier_importer_qfield_detections.md)
  inscrit la suite de chaque détection visitée, avec position, précision
  GNSS, opérateur et photos attestées par leur empreinte. L’import est
  tout ou rien et rejouable. « Non vu » n’écrit rien. Une détection déjà
  suivie ne l’est pas une seconde fois, et le bilan la signale.
- [`sommier_contours_detections()`](https://pobsteta.github.io/sommieR/reference/sommier_contours_detections.md)
  recalcule, depuis les rasters RECONFORT (classes) et SUFOSAT (dates,
  probabilités), le contour de chaque détection en attente. Ce contour
  sert à trouver la zone, il ne prouve rien et n’entre pas dans la
  chaîne : à défaut de pixels, la détection se montre par son unité.
- [`sommier_inscrire_coupes_sufosat()`](https://pobsteta.github.io/sommieR/reference/sommier_inscrire_coupes_sufosat.md)
  inscrit au registre 8, comme détections à vérifier, les coupes SUFOSAT
  qu’aucun martelage n’explique, sans doublon.
- Registre 8 en `r8-1.3.0` : la suite d’une détection porte la position
  relevée, la précision et la source GNSS, l’opérateur, l’instant de la
  visite et les photos.
  [`sommier_valider_detection()`](https://pobsteta.github.io/sommieR/reference/sommier_valider_detection.md)
  gagne `id` et refuse une seconde suite pour une même détection.
- La lecture des rasters SUFOSAT se limite à l’emprise de la forêt :
  [`sommier_coupes_sufosat()`](https://pobsteta.github.io/sommieR/reference/sommier_coupes_sufosat.md)
  et les contours lisent environ cinq fois plus vite sur un raster de
  zone.

## sommieR 0.22.1

- Un article, « Suivre la balance de possibilité », déroule toute la
  chaîne sur la démo de Couchey et une forêt d’exemple : l’aménagement
  transcrit, la balance en volume, l’avenant qui change la possibilité à
  partir d’un exercice, le martelage hors aménagement, la balance en
  surface et la référence IFN (SER C20 pour Couchey, 2,55 m³/ha/an).
- Le rapport montre la référence de l’IFN même sans aménagement : elle
  dit ce que prélèvent les forêts voisines, et donc à quoi une future
  possibilité se mesurera. Le rapport réel de la forêt domaniale
  d’Orléans, qui n’a pas encore d’aménagement au registre, l’affichait
  vide.

## sommieR 0.22.0

La balance se tient aussi en surface. C’est ce que fixent les arrêtés
récents de l’ONF : celui de 2019 du massif de Lorris-Les Bordes ne fixe
aucun volume, mais 2 026,57 ha à ouvrir en régénération sur vingt ans.

### Balance en surface

[`sommier_balance_surface()`](https://pobsteta.github.io/sommieR/reference/sommier_balance_surface.md)
confronte, exercice par exercice, la surface ouverte en régénération à
la surface prévue, et en cumule l’écart par aménagement :

- **prévue** : la surface à régénérer de la période
  (`surface_regeneration_ha` de l’aménagement), répartie également sur
  ses exercices. L’arrêté fixe un total, pas un calendrier : ce rythme
  régulier n’est qu’un repère ;
- **ouverte** : la surface des martelages dont la nature relève de
  `SOMMIER_NATURES_REGENERATION` (régénération, ensemencement,
  secondaire, définitive, coupe rase ; la nature, texte libre, est lue
  sans accents ni majuscules). **Une unité ne s’ouvre qu’une fois** :
  une coupe secondaire puis définitive sur la même parcelle n’ouvrent
  pas deux fois la même surface. Des surfaces partielles saisies
  s’additionnent, sans dépasser la surface de l’unité.

Un écart cumulé négatif est un retard de régénération. Un avenant peut
désormais réviser la surface à régénérer
(`sommier_avenant_possibilite(surface_regeneration_ha = )`).

Le rapport ajoute une section « Balance en surface : la régénération »
sous la balance en volume. Sur la copie d’essai d’Orléans, avec un
avenant fictif de 60 ha sur 2009-2028, 47,89 ha sont ouverts, presque
tous en 2017-2019 sur les coupes rases que SUFOSAT a vues, et l’écart
cumulé est de −6,11 ha en 2026.

## sommieR 0.21.0

La référence de l’IFN s’obtient en un appel.

`sommier_reference_ifn(emprise)` situe la forêt dans sa sylvoécorégion
([`sommier_ser()`](https://pobsteta.github.io/sommieR/reference/sommier_ser.md))
et rend le prélèvement que l’IFN y observe, en m³/ha/an, prêt pour
`sommier_rapport_quarto(reference_ifn = )` et pour le contrôle de
vraisemblance de
[`sommier_amenagement()`](https://pobsteta.github.io/sommieR/reference/sommier_amenagement.md).
Pour la forêt domaniale d’Orléans : SER B70 « Sologne-Orléanais », 2,28
m³/ha/an sur 2005-2024.

Le taux vient de nemeton. Le paquet entre en Suggests, et s’installe
depuis GitHub (`Remotes: pobsteta/nemeton`), ce que la CI sait faire.
Ses tables IFN sont livrées avec lui, si bien que l’appel ne demande pas
le réseau. Sans nemeton, la fonction le dit ; le rapport accepte
toujours une référence fournie à la main.

## sommieR 0.20.0

La balance se lit désormais en regard de ce que la forêt porte et de ce
que l’IFN observe autour d’elle. Tout est en m³/ha/an, et rien de ces
repères n’entre dans la chaîne.

### Situer la possibilité

[`sommier_ser()`](https://pobsteta.github.io/sommieR/reference/sommier_ser.md)
rend la sylvoécorégion de l’IGN qui contient la forêt. La couche est
téléchargée une fois, explicitement, puis gardée en cache. La forêt
domaniale d’Orléans est dans la SER B70 « Sologne-Orléanais ».

Le rapport accepte une `reference_ifn` : le prélèvement que l’IFN
observe dans cette SER. Un tableau de repères à l’hectare réunit alors
la possibilité, le prélevé moyen des exercices échus et ce prélèvement
de référence. Pour Orléans, la référence est de 2,28 m³/ha/an sur
2005-2024 : c’est la somme des taux `maille` de toutes les essences,
tirée de
[`nemeton::ifn_prelevement_essence_ser()`](https://pobsteta.github.io/nemeton/reference/ifn_prelevement_essence_ser.html).
sommieR n’appelle pas nemeton, qui n’est pas sur le CRAN ; la
documentation montre comment obtenir le taux. Le rapport rappelle que ce
chiffre est ce qui a été coupé, toutes propriétés confondues, et non ce
qui devait l’être.

### Ce que la forêt porte

[`sommier_lire_indices_nemeton()`](https://pobsteta.github.io/sommieR/reference/sommier_lire_indices_nemeton.md)
lit les indicateurs d’un projet nemeton (`data/indicators.parquet`, avec
`arrow` en Suggests). Les unités sont rapprochées par le numéro de
parcelle lu à la fin du libellé. Le rapport en tire un encadré : volume
sur pied estimé, possibilité rapportée au capital (1,6 % par an sur la
copie d’essai d’Orléans), unités à volume nul, et unités sans indice. Il
donne la source et la date, et dit que nemeton ne déclare pas sa
précision.

### Les coupes que la balance ne voit pas

[`sommier_coupes_sufosat()`](https://pobsteta.github.io/sommieR/reference/sommier_coupes_sufosat.md)
agrège les rasters SUFOSAT par unité et par année (surface, date
médiane, probabilité moyenne), et écarte les détections sous 0,5 ha.
Passées au rapport par `coupes_detectees`, les coupes qu’aucun martelage
de la même unité n’explique, ni l’exercice de la détection ni le
précédent, sont signalées sous la balance. Une détection n’est pas un
constat : la balance n’est pas corrigée d’office.

## sommieR 0.19.0

La balance de possibilité se calcule contre un aménagement inscrit dans
la chaîne. Jusqu’ici, elle se comparait à un chiffre qu’on pouvait
réécrire sans laisser de trace.

### L’aménagement est une écriture

La possibilité vivait dans une table `exercice`, hors de la chaîne, que
[`exercice_definir()`](https://pobsteta.github.io/sommieR/reference/exercice_definir.md)
remplaçait en silence. Un paquet dont l’objet est la valeur probante
comparait ainsi des prélèvements attestés à un chiffre modifiable après
coup.

[`sommier_amenagement()`](https://pobsteta.github.io/sommieR/reference/sommier_amenagement.md)
écrit désormais l’acte du registre 1 (arrêté ou agrément du PSG, schéma
`r1-1.2.0`). L’acte porte la période, la **possibilité à l’hectare
(m³/ha/an)** et la surface à laquelle elle s’applique, la ventilation
par nature de coupe (elle aussi à l’hectare), la série, la tolérance et
la source. Le volume annuel se déduit du taux et de la surface.
[`sommier_avenant_possibilite()`](https://pobsteta.github.io/sommieR/reference/sommier_avenant_possibilite.md)
change le taux, la surface ou la fin à partir d’un exercice, sans
réécrire le passé : une distraction de 20 ha change le volume, pas le
taux. Deux aménagements ne peuvent pas se chevaucher : une révision
anticipée clôt d’abord l’ancien par avenant.

### Une balance par aménagement

`v_balance_possibilite` se calcule à partir des exercices de chaque
aménagement. Elle donne la possibilité à l’hectare et en volume, et
ramène le martelé à l’hectare (`prelevement_m3_ha`). On lit ainsi le
prélèvement contre la possibilité, et contre les références de l’IFN,
dans la même unité. Son cumul **repart de zéro** avec chaque nouvel
aménagement, et court jusqu’à l’exercice courant. Chaque ligne cite
l’acte dont vient sa possibilité, et dit s’il s’agit d’un avenant. Un
martelage imputé à un exercice qu’aucun aménagement ne couvre n’est pas
compté, mais il n’est pas perdu :
[`sommier_martelages_hors_amenagement()`](https://pobsteta.github.io/sommieR/reference/sommier_martelages_hors_amenagement.md)
et le rapport le montrent à part.

### Possibilité ou récolte prévue

La recherche des aménagements de la forêt domaniale d’Orléans a montré
qu’un arrêté récent de l’ONF ne fixe plus de possibilité en m³. Celui du
9 août 2019 (massif de Lorris-Les Bordes, 2019-2038) fixe des surfaces
par groupe. Le volume, 37 215 m³/an, n’apparaît qu’au document, comme
récolte prévisible pilotée en surface terrière.

L’aménagement porte donc `nature_volume` : `possibilite` (fixée par
l’acte) ou `recolte_prevue` (récolte prévisible du document). Il garde
aussi les surfaces par groupe et la surface à ouvrir en régénération. Le
rapport ne présente jamais une prévision comme une possibilité.

### La table `exercice` se reprend

[`sommier_reprendre_exercices()`](https://pobsteta.github.io/sommieR/reference/sommier_reprendre_exercices.md)
transcrit la table en un ou plusieurs aménagements repris, en regroupant
les années consécutives de même possibilité (source `base_gestionnaire`,
NDP 2). Le volume de la table est ramené à l’hectare sur la surface de
la forêt. La balance ne lit plus la table.
[`exercice_definir()`](https://pobsteta.github.io/sommieR/reference/exercice_definir.md)
avertit qu’il est obsolète, puis refuse d’écrire une fois la table
reprise. Le jeu de démonstration de Couchey porte désormais un
aménagement transcrit, 2016-2035 à 5 m³/ha/an sur 16,37 ha.

### Un martelage parcourt son unité

Par défaut, la surface d’un martelage est celle de son unité de gestion.
`v_coupe` la déduit à la lecture, à partir du contour en vigueur à la
date du martelage, et une nouvelle colonne `surface_source` dit si la
surface a été `saisie` ou vient de l’`unite`. La surface déduite n’entre
pas dans la chaîne : elle n’a pas à passer pour une surface saisie, et
elle suit le contour si celui-ci est révisé. Une coupe réalisée ou un
produit accidentel ne parcourt pas forcément toute l’unité : ils gardent
la surface saisie, ou aucune.

### Un contrôle de vraisemblance

`sommier_amenagement(reference_m3_ha_an = )` confronte la possibilité à
un prélèvement de référence à l’hectare, par exemple celui que l’IFN
observe dans la sylvoécorégion. Au-delà d’un facteur 3, un avertissement
signale une faute de frappe possible. L’acte s’écrit quand même : la
possibilité est un acte d’autorité, pas une estimation.

### Dans le rapport

La section « Balance de possibilité » nomme chaque aménagement : sa
période, sa possibilité (« 4,40 m³/ha/an sur 535,20 ha, soit 2 355 m³/an
») et sa nature, l’acte, les surfaces par groupe. Le tableau donne le
prélèvement à l’hectare de chaque exercice. Elle trace le cumul par
aménagement, et prévient que l’exercice en cours pèse déjà pour toute sa
possibilité. Sans aménagement, elle dit pourquoi elle est vide.

Les apports de nemeton, prévus au brief (volume sur pied, coupes SUFOSAT
sans martelage, plan d’actions), viendront dans un lot suivant.

## sommieR 0.18.0

Trois retouches au suivi des limites, tirées de la recette sur le
terrain.

### Une ortho qui s’affiche sans réseau

En forêt, le réseau manque souvent, et l’orthophotographie en ligne de
l’IGN restait alors blanche dans QField.
[`sommier_ortho_ign()`](https://pobsteta.github.io/sommieR/reference/sommier_ortho_ign.md)
télécharge, sur demande explicite, un extrait de l’ortho de la
Géoplateforme sur l’emprise de la forêt, en GeoTIFF Lambert-93. À 0,5 m,
une forêt de trois kilomètres tient en une dizaine de mégaoctets.
`sommier_projet_qfield(ortho = )` le joint au projet : QField l’affiche
hors ligne, sous la couche en ligne. Sans ortho fournie, la couche est
retirée du projet, pour que QField ne signale pas un fichier absent.

Le service a des ratés : un bloc refusé (« layer unknown ») passe au
suivant. Or GDAL n’en fait qu’un avertissement, et écrivait un fichier
troué que la fonction rendait comme un succès. Tout avertissement de
téléchargement fait désormais échouer l’essai. L’essai est retenté une
fois, et un refus qui se répète échoue avec la réponse du service, sans
laisser de fichier. `couche = "ORTHOIMAGERY.ORTHOPHOTOS.IRC"` donne
l’infrarouge, qui distingue mieux feuillus et résineux.

### « Hors plan » vide l’élément proposé

La valeur par défaut de l’élément est réévaluée à chaque changement.
Choisir « Hors plan » la vide, alors qu’elle proposait jusque-là la
borne voisine. Le choix manuel de l’agent est gardé.

### La tolérance à l’échelle de la feuille

[`sommier_elements_pci()`](https://pobsteta.github.io/sommieR/reference/sommier_elements_pci.md)
lit l’échelle d’origine du plan de chaque feuille (attribut `EOR` de la
subdivision de section) : 2000 pour ZK01 à Loury, 5000 pour A01 à
Couchey. Dans le rapport, un écart au plan est dans la tolérance sous la
précision du relevé augmentée de 0,2 mm à cette échelle, soit 0,4 m au
1/2000 et 1 m au 1/5000. Faute d’éléments du plan, la tolérance reste de
1 m, et le rapport le dit.

## sommieR 0.17.0

Le rapport montre ce que le terrain a vu. Les reconnaissances de limite
rapportées de QField ont désormais leur section, avec une carte, un
tableau et une planche de photos. Une version publique la rend sans les
photos.

### Ce que le terrain a vu

[`sommier_rapport_quarto()`](https://pobsteta.github.io/sommieR/reference/sommier_rapport_quarto.md)
ajoute, après les éléments du plan, une section « Vérification des
limites sur le terrain » :

- **un bilan par catégorie** : « Borne : 2 vu(s) sur 68, dont 1
  endommagé(s) ; 0 non retrouvé(s) ou détruit(s) ; 66 à voir », puis les
  éléments trouvés hors plan ;
- **un encadré sur ce que la photo atteste**, et sur ce qu’elle
  n’atteste pas ;
- **une carte du dernier état de chaque élément**. Ce qui reste à voir y
  est allégé, pour qu’une voie de trois kilomètres n’écrase pas les
  bornes, et les éléments visités sont dessinés en dernier ;
- **un tableau des constats** : élément, état, date, opérateur, écart au
  plan, délai entre la visite et l’import, nombre de photos ;
- **une planche photographique**, quatre vignettes par ligne, sous
  chacune le numéro, la date, l’état et le début de l’empreinte.

Les vignettes sont réduites au rendu par GDAL, déjà là par `sf` : aucune
dépendance nouvelle. Une photo de QField passe de 1,6 Mo à environ 130
Ko. Seul l’original est attesté. Une photo dont l’empreinte ne tient
plus n’est pas montrée, et le rapport dit pourquoi. La planche est
écrite directement en HTML et en LaTeX, parce que la grille de figures
de Quarto numérotait chaque vignette « (a) ».

### Un pointé n’est pas une mesure

Le premier retour de terrain l’a montré. Avec le positionnement coupé,
QField laisse la précision vide, et la position du constat est l’endroit
où l’agent a touché la carte. L’écart au plan n’est donc calculé que
pour une position mesurée. Il est dit dans la tolérance sous la
précision déclarée du relevé augmentée d’un mètre, la précision
graphique d’un plan au 1/5000 (le brief prévoyait l’échelle de chaque
feuille, que les éléments ne portent pas encore). Au-delà, le tableau
écrit « hors tolérance », jamais « déplacé ». Sans mesure, il écrit «
pointé ».

### Une version publique

`sommier_rapport_quarto(public = TRUE)` retire la planche. Le tableau
garde le nombre de photos, et un encadré dit qu’elles existent et où les
demander. Une photo peut montrer un riverain ou une plaque
d’immatriculation. `photos =` désigne le dépôt, qui est fourni et jamais
téléchargé, comme le fond.

## sommieR 0.16.0

Le suivi des limites va sur le terrain. Le sommier prépare un projet
QGIS que l’agent ouvre avec QField, et il relit ce que l’agent en
rapporte : un constat par élément visité, avec sa position et ses
photos, au registre 2.

### Un projet QField engendré par le sommier

[`sommier_projet_qfield()`](https://pobsteta.github.io/sommieR/reference/sommier_projet_qfield.md)
écrit un dossier autonome, sans avoir besoin de QGIS ni d’un service en
ligne : un projet `limites.qgs`, un `terrain.gpkg` et un dossier `DCIM/`
vide. On le copie sur le téléphone ou la tablette, et on le rapporte de
la même façon. On y trouve les éléments du plan (lot 5 de la
cartographie), colorés selon leur dernière visite : à voir, vu il y a
plus de dix ans, vu en place, vu endommagé, non retrouvé ou détruit.

Le formulaire du constat fait le plus possible à la place de l’agent. Il
propose l’élément du plan le plus proche à moins de 30 m (les bornes
d’abord) et remplit la date, l’opérateur, la précision et la source
GNSS. Il exige un état, et un élément sauf pour un constat « hors plan
». On joint à un constat autant de photos qu’on veut, sous une consigne
de prise de vue : cadrer l’élément, éviter les personnes et les
véhicules.

Le modèle du projet (styles, formulaires, relation entre constats et
photos) a été produit par QGIS lui-même, avec
`data-raw/qfield_modele.py`. Un `.qgs` écrit à la main n’aurait eu
aucune garantie d’être relu. Le script a d’ailleurs révélé ce qu’aucune
documentation ne dit : à la relecture, QGIS remplace par un UUID un
identifiant de couche sans tiret bas, ou trop court (`limites_ug`). La
relation et la proposition de l’élément le plus proche se perdaient
alors. Les couches s’appellent donc `limites_constats`,
`limites_unites`… Un test ouvre le projet engendré avec PyQGIS, quand
QGIS est installé.

Le projet a été recetté sous QField 4.3.4 (Android), et il demande
désormais cette version au minimum, ce qu’il déclare dans ses
métadonnées. Le premier retour de terrain, deux constats sur Loury avec
leur photo, s’est importé tel quel. Il a aussi montré deux choses.
QField écrit un en-tête EXIF, mais sans date de prise de vue ni position
quand le positionnement est coupé. Et un constat pointé sur la carte,
sans GNSS, a une précision vide : sa géométrie est un pointé, pas une
mesure.

### Le constat au registre 2

[`registre2_foncier()`](https://pobsteta.github.io/sommieR/reference/registre2_foncier.md)
gagne le type `reconnaissance_limite` (schéma `r2-1.3.0`). Un constat
porte un état parmi `SOMMIER_ETATS_LIMITE` : en place, endommagé, non
retrouvé, détruit, inaccessible, hors plan. Il n’y a pas d’état «
déplacé » : un écart de quelques mètres entre un GNSS et un plan au
1/5000 ne prouve rien, et c’est au géomètre de juger. Le constat recopie
l’élément du plan tel que l’agent l’a vu (identifiant, numéro,
catégorie, millésime, coordonnées), pour rester lisible quand le plan
changera.

[`sommier_importer_qfield()`](https://pobsteta.github.io/sommieR/reference/sommier_importer_qfield.md)
relit le projet rapporté. **Tout ou rien** : une seule faute fait
échouer l’import, qui les liste toutes à la fois. **Rejouable** : l’UUID
que QField donne au constat devient l’identifiant de l’entrée, si bien
que réimporter n’écrit rien de plus. L’entrée porte NDP 0, puisque c’est
un constat de terrain. Les vues `v_reconnaissance_limite` et
`v_reconnaissance_derniere` donnent, pour chaque élément, sa dernière
visite.

### Les photos, attestées par leur empreinte

[`sommier_deposer_photo()`](https://pobsteta.github.io/sommieR/reference/sommier_deposer_photo.md)
range chaque photo dans un dépôt local, sous son SHA-256. Le payload ne
porte que l’empreinte, si bien que la chaîne atteste les octets. Le
fichier n’est jamais modifié, pas même pour en retirer des métadonnées.
La date et la position lues dans l’EXIF sont recopiées comme
déclarations de l’appareil, jamais comme des faits. Le lecteur EXIF est
écrit dans le paquet, sans nouvelle dépendance, et éprouvé sur des
photos produites par Pillow dans les deux ordres d’octets.

[`sommier_verifier_photos()`](https://pobsteta.github.io/sommieR/reference/sommier_verifier_photos.md)
classe chaque photo : conforme, altérée ou manquante. Une photo effacée
est perdue pour la lecture, mais pas pour la chaîne, et
[`sommier_verifier()`](https://pobsteta.github.io/sommieR/reference/sommier_verifier.md)
reste valide.
[`sommier_exporter_manifeste()`](https://pobsteta.github.io/sommieR/reference/sommier_exporter_manifeste.md)
joint les photos au manifeste (`depot =`), et
[`sommier_verifier_manifeste()`](https://pobsteta.github.io/sommieR/reference/sommier_verifier_manifeste.md)
les confronte aux empreintes (`photos =`). Une altération y est une
anomalie, une absence une réserve.

### Ce qui reste à faire

- La section du rapport sur la vérification des limites, avec sa carte
  par état, sa planche de photos et la variante publique sans photos. Ce
  sera le lot 2.
- Un fond d’orthophotographie hors ligne. Le projet porte celle de
  l’IGN, qui ne s’affiche qu’avec du réseau.
- Pour un constat hors plan, QField propose quand même l’élément le plus
  proche. L’agent doit vider le champ, et la contrainte du formulaire
  l’y oblige.

## sommieR 0.15.0

Le rapport montre désormais tout ce que le plan cadastral pose dans la
forêt et à ses abords : bornes, signes de limite, détails, cours d’eau,
voies, bâtiments. C’est la liste que le suivi des limites emportera sur
le terrain.

### Tout ce qui touche la forêt élargie de 20 mètres

[`sommier_elements_pci()`](https://pobsteta.github.io/sommieR/reference/sommier_elements_pci.md)
lit toutes les couches physiques du PCI vecteur — `BORNE`, `SYMBLIM`,
`TPOINT`, `TLINE`, `TSURF`, `TRONFLUV`, `ZONCOMMUNI`, `TRONROUTE`,
`BATIMENT` — et retient ce qui touche l’union des unités élargie de
`tampon_m` mètres (20 par défaut). Sur la forêt de Loury, cinq feuilles
en donnent **118** : 68 bornes, 30 voies, 7 bâtiments, 6 détails
surfaciques, 5 cours d’eau, un détail linéaire et un détail ponctuel.

Les couches qui ne posent rien au sol sont écartées : parcelles,
sections, lieux-dits, numéros de voirie, et `ID_S_OBJ_Z_1_2_2`, qui ne
porte que la position des étiquettes des numéros de parcelle.

Chaque élément reçoit un identifiant stable, `feuille:OBJECT_RID`, et un
numéro court par catégorie (`B-001`, `P-001`…) dans l’ordre du cadastre.
Le millésime de chaque feuille, date d’échange que le lot déclare dans
son `.THF`, est désormais lu par
[`sommier_fond_pci()`](https://pobsteta.github.io/sommieR/reference/sommier_fond_pci.md)
et imprimé sous la carte.

### Une distance, parce que la situation seule tromperait

Chaque élément est dit « forêt » s’il touche les unités, « tampon »
sinon. Sur Loury, 64 des 68 bornes tombent dans le tampon, à 8 m du
contour en médiane et 18 m au plus : elles sont sur la limite
cadastrale, ce sont les unités, dessinées à une autre main, qui ne la
suivent pas au mètre. La distance au contour (`distance_limite_m`) est
donc rendue à côté. Elle mesure, là où la situation classe, et elle
justifie le tampon de 20 m.

### Le texte du plan est cité, pas interprété

Le brief prévoyait de lire la nature d’un détail dans le texte que le
plan lui attache. La feuille de Couchey l’a démenti : ses lignes de code
19 portent « COMMUNE DE FLAVIGNEROT », le nom de la commune voisine posé
le long de la limite. Le texte nomme parfois l’objet (« pylone télécom »
sur Loury), parfois seulement ses abords. Il est donc cité entre
guillemets, à côté de la nature, qui ne vient que de la couche ou d’une
table `symboles` fournie.

Les noms de voies et de cours d’eau posés mot par mot — un mot par
attribut `TEX`, `TEX2`… dans un ordre qui n’est pas celui de la lecture
— ne sont pas recomposés : « Route de la Vallée Jaune » arrive en
`Jaune`, `de`, `la`, `Vallée`, `Route`. Le rapport écrit « nom morcelé
sur le plan ».

### Dans le rapport

Passé à `sommier_rapport_quarto(fond_pci = )`, le tableau des éléments
ouvre une section « Éléments du plan cadastral » après le récapitulatif
du parcellaire : une carte d’ensemble avec le tampon, une carte des
bornes au plus près — sur une forêt de plusieurs kilomètres, les bornes
se groupent et leurs numéros se chevauchaient —, et un tableau par
catégorie. En PDF, ces tableaux passent en LaTeX direct : pandoc faisait
revenir les coordonnées à la ligne. Les bornes seules
([`sommier_fond_pci_lire()`](https://pobsteta.github.io/sommieR/reference/sommier_fond_pci_lire.md))
restent acceptées et gardent leurs croix sur la carte de la desserte.

[`sommier_exporter_elements_pci()`](https://pobsteta.github.io/sommieR/reference/sommier_exporter_elements_pci.md)
écrit les mêmes éléments en GeoPackage, une couche par type de
géométrie, pour QGIS et QField.

Le PCI reste un décor : rien n’entre dans la chaîne, et le rendu ne fait
aucun appel réseau.

## sommieR 0.14.1

Les contours lus depuis le cadastre gardent leur précision.

### Un arrondi au mètre que rien ne signalait

[`sommier_fond_lire()`](https://pobsteta.github.io/sommieR/reference/sommier_fond_lire.md),
[`sommier_fond_pci_lire()`](https://pobsteta.github.io/sommieR/reference/sommier_fond_pci_lire.md)
et la lecture des objets EDIGEO passaient leurs géométries en WKT par
[`sf::st_as_text()`](https://r-spatial.github.io/sf/reference/st_as_text.html)
sans lui dire combien de chiffres garder. La fonction suit alors
`getOption("digits")`, soit sept chiffres significatifs : en Lambert-93,
une ordonnée comme 6 768 263,2 perd ses décimales, et le contour est
ramené au mètre. Sur la fixture du paquet, l’écart atteint 0,29 m.

Le défaut s’est vu sur la forêt domaniale d’Orléans, où l’union des
ténements d’une unité, valide avant l’écriture, en ressortait
auto-intersectée. Les trois lectures passent désormais par un même
utilitaire à quinze chiffres, qui rend le double tel qu’il a été lu. Les
surfaces de ténements du récapitulatif du parcellaire, calculées sur ce
fond, en gagnent autant.

## sommieR 0.14.0

Le rapport récapitule désormais le parcellaire : les unités de gestion,
les parcelles cadastrales qu’elles recouvrent, et les ténements qui les
relient.

### Un ténement se calcule, il ne s’enregistre pas

Un ténement est la part d’une parcelle cadastrale comprise dans une
unité de gestion. Le sommier n’en garde pas trace, et n’a pas à le faire
: c’est une lecture du parcellaire, pas un fait advenu. Le rapport les
calcule au rendu, en croisant les contours des unités avec le fond
cadastral déjà passé à
[`sommier_rapport_quarto()`](https://pobsteta.github.io/sommieR/reference/sommier_rapport_quarto.md)
par `fond`. Aucun appel réseau de plus, aucune écriture dans la chaîne.

Le tableau suit la carte du parcellaire. Une ligne par ténement :
l’unité, la parcelle telle que le cadastre l’affiche, sa référence, sa
contenance cadastrale, la surface du ténement mesurée sur le dessin, et
la part de la parcelle qu’il représente. L’en-tête compte les unités,
les parcelles et les ténements, et confronte la surface SIG des unités à
la contenance des parcelles. Sans fond, le récapitulatif ne liste que
les unités et dit pourquoi.

### Un seuil, parce que deux traits ne se superposent jamais

Le fond déborde de la forêt, et une limite commune tracée par deux mains
laisse un liseré de quelques mètres carrés. Sur Loury, le premier essai,
à 1 % de la parcelle, annonçait 33 ténements pour 30 unités : trois
liserés de 0,01 à 0,02 ha, dont deux sur une parcelle de 0,67 ha
enclavée entre deux unités. Le seuil est de 100 m² **et** 5 % de la
parcelle. Loury retombe à 30 unités, 30 parcelles, 30 ténements — et la
contenance des parcelles concernées, 554,93 ha, est exactement la
surface déclarée de la forêt.

Le tableau suit l’ordre du cadastre et non celui de l’alphabet : B 2
avant B 11.

### Des tableaux qui se lisent

Le premier martelage réel porté au sommier de la forêt domaniale
d’Orléans a rendu la section des coupes pour la première fois ailleurs
que sur la démonstration, et deux défauts avec elle. Le compte d’entrées
sortait « 4.940656e-324 » : c’est le `count(*)` de PostgreSQL, un
bigint, relu par le document sans `bit64` — le même piège que la
séquence de tête, que la 0.13.0 n’avait refermé que pour elle. Les
colonnes `integer64` de toutes les sections passent désormais en
numérique avant le RDS. Et les tableaux parlaient SQL : `type_entree`,
`volume_m3`, `151.4036`, `NA`. Ils portent maintenant des libellés, des
nombres à la française, et « — » pour une valeur absente.

## sommieR 0.13.0

Le rapport de gestion antérieure ne voyait pas les détections. Ce lot
les lui montre, et corrige ce qu’un premier rendu sur une forêt réelle a
mis au jour.

### Seize détections, et un rapport qui disait « aucun enregistrement »

Le sommier de la forêt de Loury, versé depuis le projet RECONFORT de
nemeton, porte seize détections de dépérissement du chêne au registre 8
— NDP 1, toutes en attente de constat. Son rapport PDF n’en montrait
aucune :
[`sommier_gestion_anterieure()`](https://pobsteta.github.io/sommieR/reference/sommier_gestion_anterieure.md)
ne lisait que les phénomènes, et la section « Évènements marquants »
concluait « Aucun enregistrement sur la période » sur un sommier dont
c’étaient les seules écritures.

Ne pas les mêler aux évènements était juste : une détection n’est pas un
constat. Ne les montrer nulle part ne l’était pas. Deux sections
s’ajoutent :

- `detections` : les détections en attente, avec le numéro de l’unité,
  la source, le NDP, la surface, l’indice et les observations de la
  chaîne. **Sans borne de période**, comme le patrimoine remarquable :
  une détection en attente l’est aujourd’hui, et un bilan borné qui la
  ferait disparaître cacherait justement ce que personne n’est encore
  allé voir ;
- `suites_detection` : sur la période, le nombre de détections
  confirmées et écartées par
  [`sommier_valider_detection()`](https://pobsteta.github.io/sommieR/reference/sommier_valider_detection.md).
  Celles-là sont des constats datés, elles se bornent.

Le rapport Quarto leur consacre une section « Détections à vérifier sur
le terrain » : un encadré qui dit ce qu’est une proposition, le tableau,
une carte des surfaces proposées par unité, et les libellés du registre.
Les réserves de méthode que la chaîne répète sur chaque détection —
domaine de calibration, masque feuillus — sont données une fois ; chaque
détection garde ce qui lui est propre. Rien n’est reformulé : le texte
est celui du registre, découpé à ses points.

### Ce que le premier rendu réel a montré

Le jeu de démonstration masquait six défauts, qu’une forêt réelle rend
visibles d’un coup :

- **la séquence de tête s’imprimait `8 × 10⁻³²³`**. Elle arrive de
  PostgreSQL en `integer64` ; relue par le document sans `bit64`, elle
  s’affichait comme le double qui partage ses octets. Elle voyage
  désormais en texte dans le RDS ;
- **le titre « Données de démonstration » s’affichait sur toute forêt**
  : seul le corps de l’encadré était conditionnel. Le bandeau entier
  l’est devenu ;
- **la période s’écrivait « 0001-01-01 au 9999-12-31 »** faute de
  bornes. Ces dates sont des sentinelles : le rapport écrit « depuis
  l’ouverture du sommier » et « à ce jour » ;
- **l’empreinte de tête sortait de la page** en PDF. Elle y est coupée
  en quatre blocs de seize caractères ; en HTML elle reste d’un tenant,
  pour qu’on puisse la copier ;
- **les cartes des coupes et des travaux se dessinaient toutes à zéro**
  quand le registre était vide, et le symbole « € » sortait en point
  sous le périphérique [`pdf()`](https://rdrr.io/r/grDevices/pdf.html),
  qui ne connaît que le Latin-1. Une carte sans valeur ne se dessine
  plus — le « Aucun enregistrement » de la section reste, une absence
  d’écriture est une information — et le PDF écrit « EUR » ;
- les surfaces sont arrondies et écrites à la française (554,93 ha).

### Le rapport ne renvoie plus aux imprimés A50

Les sections du rapport Quarto s’ouvraient sur l’imprimé de la série A50
qu’elles transposent — « Imprimés A50E, A50F et A50I », « Imprimé A50K
», « Série A50 r/\* ». Ces renvois sont retirés, légendes comprises :
ils parlent au gestionnaire qui tient le classeur, pas au lecteur du
rapport, et une forêt privée sous PSG n’a jamais connu ces imprimés. Les
registres, eux, restent calqués sur la série.

### Un rendu qui échoue le dit

[`sommier_rapport_quarto()`](https://pobsteta.github.io/sommieR/reference/sommier_rapport_quarto.md)
copiait le document produit vers sa destination sans regarder le
résultat : [`file.copy()`](https://rdrr.io/r/base/files.html) ne signale
un échec que par un avertissement, et la fonction rendait le chemin d’un
fichier qui n’existait pas. Elle échoue désormais, en nommant la
destination.

## sommieR 0.12.0

Le jeu de démonstration reposait sur un parcellaire qui n’existe pas. Ce
lot lui rend le vrai.

### Un contour faux dans un paquet qui vend la valeur probante

`SOMMIER_PARCELLES_COUCHEY` reprenait la fixture « mock » de
`nemetonshiny` : trois carrés de 0,002 degré, portant les références
`21200000A0054` à `56`. Trois choses n’allaient pas, et la troisième est
celle qui gêne.

Les parcelles **n’existent pas** — la section A de Couchey passe de 38 à
61. La référence était **mal formée** : le cadastre écrit
`212000000A0054`, sur quatorze caractères et non treize. Et surtout, un
paquet dont l’objet est d’empêcher qu’une écriture plausible passe pour
une écriture vraie livrait en exemple une géométrie plausible et fausse.
L’argument ne survit pas à sa propre démonstration.

### Ce que le jeu porte désormais

Trois parcelles réelles de la forêt communale de Couchey, prises au
cadastre de la DGFiP par le projet Couchey de nemeton
(`20260828_140251_hwuy`), qui porte le même parcellaire :

| Parcelle | Référence        | Contenance |
|----------|------------------|-----------:|
| A 15     | `212000000A0015` |   4,875 ha |
| A 35     | `212000000A0035` |    7,19 ha |
| A 102    | `212000000A0102` |  4,3095 ha |

Le recoupement avec la livraison etalab du 1er juin 2026 donne un
recouvrement de 1,0000 : la géométrie de nemeton **est** celle de la
DGFiP.

Les contours sont simplifiés à 1 mètre, ce qui coûte 55 m² sur 16,4
hectares — 0,03 %. La tolérance de 5 mètres, essayée, en coûtait 866,
dont 1 % sur la seule A 15. Pour trois parcelles et 54 sommets, la
simplification n’économise pas assez de code pour qu’on abîme une
surface.

### Trois blocs, et ce que ça change

Les parcelles ne se touchent pas : A 102 est à 485 mètres de A 35, A 15
à 1,7 kilomètre à l’est. Une forêt communale en plusieurs blocs est la
règle plutôt que l’exception, et les treize géométries du jeu s’y logent
au lieu de flotter dans un carré : chaque arbre tombe dans la parcelle
qui le porte, l’emprise du chablis tient **entièrement** dans A 35 — une
emprise rattachée à une unité ne peut pas déborder de l’unité — le
chemin relie les deux blocs de l’ouest, la piste « est » dessert
réellement le bloc est, et la limite bornée suit le côté nord-est de A
102.

Les longueurs suivent le dessin au lieu d’être posées à côté : le chemin
déclare 1 040 mètres parce que son tracé en mesure 1 040. Une desserte
dont l’attribut et la géométrie se contredisent ne renseigne ni la carte
ni l’imprimé A50D.

### Les écritures recalibrées

La surface passe de 7,5 à 16,37 hectares : les écritures suivent, à ~5
m³/ha/an de possibilité. Possibilité 38 → 82 m³/an, martelages 34–46 →
74–98 m³, chablis 22 → 48 m³ sur 1,75 ha, plantation 480 → 1 050 plants,
recettes et budgets à l’avenant. Les grandeurs qui ne dépendent pas de
la surface ne bougent pas : circonférences des arbres remarquables, taux
de reprise, taxe d’affouage à la corde.

**Les écritures restent fictives, et c’est maintenant la seule chose qui
le soit.** La distinction porte : un contour faux se voit à la première
superposition, une écriture fausse ne se voit jamais. C’est donc elle,
et elle seule, que le nom de la forêt et le rapport engendré signalent.

### Le fond de carte, rattrapé par les trois blocs

Le passage aux contours réels a mis au jour un défaut que le tenant
unique masquait. `boite_emprise()` prenait la **boîte englobante** des
contours avant de la tamponner : sur une forêt d’un seul tenant, c’est
sans conséquence ; sur trois blocs distants de 485 mètres et de 1,7
kilomètre, la boîte couvre 396 hectares — le village compris — pour 16
hectares de forêt. Le fond cadastral des cartes passait de 20 à 65
parcelles, c’est-à-dire exactement le « fond illisible » que
[`sommier_fond_lire()`](https://pobsteta.github.io/sommieR/reference/sommier_fond_lire.md)
documente vouloir éviter.

La fonction, renommée `emprise_tamponnee()`, tamponne désormais
l’**union** des contours. Une forêt en plusieurs blocs est la règle
plutôt que l’exception, et la boîte ne se trompait que sur le cas
général. Le changement porte sur les trois découpes qui partagent la
règle : parcellaire, feuilles du PCI et objets EDIGEO.

Au passage, une emprise dont tous les contours sont inconnus le dit au
lieu d’échouer sur une « OGR error » muette —
[`sommier_couche_ug()`](https://pobsteta.github.io/sommieR/reference/sommier_couche_ug.md)
rend une unité sans géométrie avec un `wkt` à `NA`, et rien ne
l’écartait avant l’union. Une unité sans contour parmi d’autres
n’empêche plus les autres de servir.

## sommieR 0.11.1

Éprouver ce qui tient la chaîne. Aucune fonction nouvelle : ce lot porte
sur l’écart entre ce que la documentation affirme et ce que la suite
démontrait.

### Ce que le paquet affirmait sans l’avoir montré

Trois phrases portent le noyau, et aucune des trois n’était éprouvée.

Le verrou consultatif de
[`sommier_ajouter()`](https://pobsteta.github.io/sommieR/reference/sommier_ajouter.md)
est la seule chose qui empêche deux écritures concurrentes de forker la
chaîne — et **aucun test ne faisait écrire deux connexions à la fois**.
Le paquet documentait longuement pourquoi il prend un verrou, sans avoir
jamais vérifié qu’il le prend.

`UNIQUE (foret_id, seq)` est annoncé comme « le filet de sécurité si le
verrou venait à manquer ». Une phrase pareille n’engage à rien tant
qu’on ne l’a pas provoquée.

Le tri des clés par unités de code UTF-16 est ce qui rend l’empreinte
reproductible chez un tiers. Il était couvert par treize cas choisis à
la main — c’est-à-dire par ce à quoi l’auteur avait pensé.

### Le verrou s’éprouve par le blocage qu’il produit

Le réflexe serait de lancer N processus qui écrivent ensemble. C’est le
mauvais choix : forker un processus R qui détient une connexion libpq
est instable, cela demanderait une dépendance de plus, et un tel test
échouerait un jour sans qu’on sache si le verrou ou l’ordonnanceur est
en cause. **Un test de concurrence qui n’échoue pas de façon
reproductible ne démontre rien.**

La propriété qui porte la correction n’est pas « N processus écrivent »
mais « le verrou est exclusif, et tenu pendant toute la transaction ».
Elle s’observe depuis une seconde connexion, sans parallélisme : B prend
le verrou et le garde, A borne son attente et doit expirer dessus — donc
l’attendre au lieu de lire la tête —, puis réussir dès que B relâche.
S’y ajoutent le relâchement en fin de transaction, et le fait que deux
forêts distinctes ne s’attendent pas.

Le filet, lui, se teste en le faisant travailler : deux branches
chaînées depuis la même tête, exactement ce qu’un verrou absent
produirait, et la seconde insertion doit être refusée par la contrainte,
la chaîne restant vérifiable.

Ces tests mordent, et c’est vérifié plutôt que supposé : retirer le
`pg_advisory_xact_lock` du code en fait échouer deux, retirer la
contrainte du schéma en fait échouer cinq.

### Ce qu’une valeur engendrée démontre qu’un cas choisi ne démontre pas

La propriété dont dépend la vérification par un tiers est universelle :
**l’empreinte ne doit pas dépendre de l’ordre dans lequel les clés du
payload ont été écrites.** Un destinataire qui reconstruit un payload
champ par champ, dans son ordre à lui, doit retrouver la même empreinte.

Les propriétés sont désormais éprouvées sur des valeurs engendrées à
graine fixe — un test qui change de verdict d’une exécution à l’autre ne
se corrige pas, il se subit. L’alphabet de tirage est choisi pour ce
qu’il casse : caractères de contrôle, accentués à deux octets,
idéogrammes à trois, et un emoji hors du plan multilingue de base, qui
compte donc pour deux unités de code UTF-16 — ce dont dépend précisément
l’ordre des clés.

- La canonisation est invariante par permutation des clés, à toute
  profondeur.
- Recanoniser une forme canonique ne la change pas, et cette forme est
  du JSON qu’un analyseur quelconque relit — sans quoi la chaîne se
  refermerait sur elle-même.
- Le rendu ne dépend pas de la locale de collation de la session.
- Tout nombre engendré se relit exactement à travers
  [`jcs_nombre()`](https://pobsteta.github.io/sommieR/reference/jcs_nombre.md)
  : un arrondi silencieux ferait diverger deux vérificateurs sur un
  volume de bois.
- L’empreinte est invariante par permutation des clés du payload **et**
  des champs de l’entrée, et elle change dès qu’un seul des onze champs
  annoncés comme couverts change — l’écart assumé par rapport au brief,
  hacher l’enregistrement complet plutôt que le seul payload, n’a de
  valeur que si chaque champ pèse vraiment.

### Le silence ne se gagne pas en se bouchant les oreilles

Faire tourner la suite contre une vraie base sortait quatre
avertissements du pilote, tous de la même forme :
`Closing open result set, cancelling previous query`. Un ordre SQL qui
échoue laisse son résultat ouvert côté RPostgres, et le coup suivant sur
la connexion annonce qu’il l’annule. Dans un retour arrière, ce coup
suivant est le `ROLLBACK` — c’est-à-dire exactement le moment où ce
résultat n’a plus à vivre.

Le message était donc attendu et correct, et nuisible malgré cela : il
apparaissait à chaque transaction avortée, aux moments qu’un exploitant
lit avec attention, et il n’apprenait rien. Un avertissement qu’on prend
l’habitude d’ignorer est un avertissement qui masquera le suivant.

Le retour arrière de `transaction()` tait désormais **ce seul message**,
reconnu sur son texte. Éteindre le bloc entier supprimerait le symptôme
et le signal ensemble : un test veille donc à ce qu’un avertissement
d’une autre nature, émis au même endroit, passe toujours.

### Et sous le bruit, un vrai défaut

Deux avertissements ont survécu à ce nettoyage, sur
[`budget_definir()`](https://pobsteta.github.io/sommieR/reference/budget_definir.md)
— dont les deux arguments refusés n’atteignent jamais la base. La trace
remonte à une validation écrite **dans** la liste `params` de
[`dbExecute()`](https://dbi.r-dbi.org/reference/dbExecute.html) :

``` r
DBI::dbExecute(con, "INSERT INTO budget_previsionnel …",
  params = parametres(list(
    valider_choix(poste, "poste", SOMMIER_POSTES_COMPTABLES$poste),  # <- ici
    …
  )))
```

R évalue les arguments paresseusement : cette validation ne s’exécute
pas avant l’appel mais **pendant**, c’est-à-dire après que le pilote a
ouvert son objet de résultat. Un argument refusé laissait donc une
requête morte sur la connexion, et l’ordre suivant — *n’importe où
ailleurs dans le programme* — en héritait : une requête silencieusement
annulée, et un avertissement à un endroit sans rapport avec la faute.

Ce n’était pas du bruit, mais une connexion laissée sale par un chemin
d’erreur. Quatre appels partageaient le défaut :
[`budget_definir()`](https://pobsteta.github.io/sommieR/reference/budget_definir.md),
[`sommier_bilan_financier()`](https://pobsteta.github.io/sommieR/reference/sommier_bilan_financier.md),
[`exercice_definir()`](https://pobsteta.github.io/sommieR/reference/exercice_definir.md)
et
[`ug_creer()`](https://pobsteta.github.io/sommieR/reference/ug_creer.md).
Les validations remontent avant l’appel, où elles auraient toujours dû
être.

C’est la trouvaille du lot, et elle en dit l’intérêt : le bruit qu’on
s’habituait à ignorer cachait exactement ce qu’on redoutait qu’il cache.

### Ce que ce lot ne fait pas

Il ne teste pas la concurrence à N écrivains réels, et ne prétend pas le
faire. Il démontre la propriété dont la correction dépend — l’exclusion
mutuelle — et laisse la montée en charge à une campagne de tenue, qui
relève de l’exploitation et non de la suite unitaire.

## sommieR 0.11.0

Lot 1 de la reprise. Le sommier ne savait démarrer qu’à vide ; il sait
désormais accueillir trente ans d’histoire sans prétendre les avoir
connus.

### Le problème, tel qu’il se posait

Une forêt qui entre dans le dispositif arrive avec son passé : registres
A50 sur papier, base d’un gestionnaire, tableurs d’un CRPF,
délibérations de la commune. Deux issues, mauvaises toutes les deux.

**La laisser dehors.** Mais l’un des trois exports du paquet est le
*bilan de l’aménagement précédent*, qui porte sur la période écoulée. Un
sommier ouvert en 2027 n’en dirait rien avant 2047.

**La saisir comme si elle arrivait aujourd’hui.** Une coupe de 1998
entrerait avec sa date d’évènement, mais serait pour tout le reste
indiscernable d’un constat de terrain. Le sommier dirait qu’il sait,
alors qu’il a recopié.

### Ce que le modèle savait déjà — et ce qu’il pouvait faire dire de faux

Rien n’a été ajouté au schéma. `date_evenement` et `date_saisie` étaient
déjà deux champs distincts, tous deux couverts par l’empreinte ; `ndp`
portait déjà la bonne sémantique, appliquée dès la v0.2.0 aux détections
FORDEAD. Le modèle savait donc distinguer *quand la chose est arrivée*
de *quand on l’a écrite*.

Il savait aussi mentir. `date_saisie` était librement fixable : une
reprise pressée l’aurait antidatée « pour faire propre », et la chaîne
aurait alors attesté qu’elle savait depuis 1998. C’était le seul endroit
du paquet où l’on pouvait faire dire au registre une chose fausse sans
rien casser.

### Une transcription, et ce qui l’empêche de passer pour un constat

[`sommier_reprise()`](https://pobsteta.github.io/sommieR/reference/sommier_reprise.md)
construit une entrée transcrite. Trois propriétés y sont **imposées**
plutôt que recommandées — une discipline qui repose sur la vigilance de
l’appelant n’en est pas une :

| Ce qui est imposé | Pourquoi |
|----|----|
| `date_saisie` est posée par le constructeur, et le lui dicter est refusé | une chaîne qu’on peut convaincre d’avoir su plus tôt qu’elle n’a su ne vaut rien |
| le NDP est strictement supérieur à 0 | NDP 0 désigne le constat de terrain ; recopier n’est pas constater |
| la source est citée, sans valeur par défaut | sans référence de pièce, une reprise ne se distingue pas d’une invention |

La date du fait, elle, reste libre de remonter aussi loin qu’il le faut
— seule une date d’évènement dans l’avenir est refusée : une reprise
transcrit ce qui a eu lieu, elle ne l’annonce pas.

[`sommier_reprendre()`](https://pobsteta.github.io/sommieR/reference/sommier_reprendre.md)
écrit le lot en une transaction et rend le compte-rendu de ce qui est
entré : combien d’entrées, par registre, sur quelle période, depuis
quelles pièces. Il n’accepte que des entrées construites par
[`sommier_reprise()`](https://pobsteta.github.io/sommieR/reference/sommier_reprise.md)
— une transcription qui entrerait par
[`sommier_entree()`](https://pobsteta.github.io/sommieR/reference/sommier_entree.md)
pourrait être antidatée, et c’est exactement ce que ce lot interdit.

### Une échelle, pas un entier laissé au jugement

`SOMMIER_SOURCES_REPRISE` attache un NDP à chaque provenance usuelle. Le
niveau croît avec la distance entre l’écriture et un fait attestable.

| Provenance | NDP | Ce qui la distingue |
|----|:--:|----|
| `registre_signe` | 1 | une pièce datée et signée, opposable telle quelle |
| `base_gestionnaire` | 2 | une base tenue, mais sans visa pièce à pièce |
| `tableur` | 3 | un fichier sans tenue vérifiable ni signature |
| `temoignage` | 4 | une déclaration recueillie, sans pièce qui la porte |

Deux communes qui transcrivent le même genre de pièce portent ainsi le
même niveau. Un appelant peut juger une pièce moins bonne que son type
ne le suggère ; il ne peut pas la juger meilleure qu’un constat.

### La chaîne ne rejoue pas l’histoire, elle la date

Les entrées reprises ne s’insèrent pas « à leur place » : la séquence
est celle de l’écriture, et elle le reste. Une reprise de trente ans
forme un bloc d’entrées contiguës dont les dates d’évènement remontent
le temps. La genèse reste la genèse — aucune réécriture, aucun recalcul.

### La marque du repris

Le bloc de provenance voyage dans le payload, sous la clé `reprise` : il
est donc couvert par l’empreinte au même titre que le volume d’une
coupe. C’est le seul champ commun aux neuf registres, parce que la
question à laquelle il répond — d’où vient cette écriture — se pose
partout de la même façon. Les neuf versions de schéma passent en
conséquence à la version suivante ; les entrées antérieures gardent la
leur, et restent valides.

Chaque vue métier porte désormais `repris`, `reprise_source` et
`reprise_reference`. Le rapport de gestion antérieure gagne une section
`provenance`, qui compte registre par registre ce qui a été constaté et
ce qui a été transcrit, et les tableaux de coupes et de travaux portent
une colonne `provenance`. Un tableau qui les additionnerait sans le dire
ferait passer la recopie pour de la mesure.

### Le jeu de démonstration raconte enfin sa propre histoire

La tenue du sommier de Couchey commence en 2021 — c’est la date de son
premier visa annuel. Les faits antérieurs ont eu lieu, mais la commune
ne les a pas enregistrés là : quatorze écritures sont donc transcrites,
depuis quatre pièces, dont le souvenir de l’agent patrimonial pour la
sécheresse de 2020. Le rapport engendré montre le mélange, et le dit.

### Ce que ce lot ne fait pas

Il ne lit aucun format en particulier. Transformer un tableur communal
ou un export ONF en entrées de sommier est un travail propre à chaque
source, et l’y enfermer maintenant figerait une supposition sur des
données qu’on n’a pas vues. Ce lot pose la discipline de la reprise et
le contrat qu’elle doit tenir ; les convertisseurs viendront ensuite, un
par source réelle et documentée.

## sommieR 0.10.1

Un hôte injoignable n’est pas un fichier absent.

### Ce qui s’est passé

Le 27 août 2026, la CI de `main` a échoué sur `test-pci.R` : l’endpoint
OVH qui sert les livraisons d’Etalab n’a pas répondu. Le test avait
pourtant son `skip_if_offline()`. Ce garde-fou demande **s’il y a un
internet**, pas **si cet hôte-là répond** : il est passé, et le
téléchargement a échoué en erreur.

### Ce qui change

`telecharger()` distingue désormais deux échecs, parce qu’ils ne veulent
pas dire la même chose :

| Condition | Ce qu’elle signifie |
|----|----|
| `sommier_reseau_indisponible` | hôte injoignable, délai dépassé, 5xx — une panne d’infrastructure |
| `sommier_ressource_absente` | 404, fichier vide — le fichier n’est pas là où on le cherche |

La distinction demande le statut HTTP, donc `curl` ; sans lui, la
condition reste `sommier_transfert_echoue` et le comportement est
inchangé — on ne prétend pas distinguer ce qu’on ne peut pas voir.

Côté tests, `sauter_si_source_indisponible()` saute sur la première et
laisse passer la seconde. Sauter les deux rendrait un vert trompeur le
jour où la source déplacerait ses fichiers ; échouer sur les deux rend
la CI otage d’un serveur tiers.

Deux tests seulement sont concernés : ceux qui vérifient le chemin de
téléchargement contre la vraie source, ce qu’aucun cache pré-rempli ne
peut faire. Tout le reste passait déjà par des fixtures.

## sommieR 0.10.0

Lot 2 de la couche probante. Le lot 1 faisait dire au jeton **ce** qu’il
atteste ; celui-ci établit **qui** l’atteste — et rend le visa aussi
autoporteur que le jeton.

### La chaîne de certification

[`tsa_verifier_jeton()`](https://pobsteta.github.io/sommieR/reference/tsa_verifier_jeton.md)
valide le CMS complet, dans l’ordre : l’attribut `contentType`, le
`messageDigest` confronté au contenu lu, l’`ESSCertID` qui désigne le
certificat employé, la signature portant sur les attributs signés
réencodés en `SET OF` (RFC 5652 §5.4), l’usage `timeStamping`, la
validité du certificat, et la chaîne jusqu’à une ancre.

**Trois états, pas deux.**

| État           | Ce qu’il dit                                               |
|----------------|------------------------------------------------------------|
| `valide`       | tout est vérifié, et la chaîne remonte à une ancre fournie |
| `non_rattache` | le jeton est intact, mais aucune ancre ne le couvre        |
| `invalide`     | quelque chose cloche dans le jeton lui-même                |

La distinction n’est pas cosmétique. Dire « invalide » à une commune
dont le jeton est parfait mais émis par une autorité qu’on n’a pas
listée serait faux ; lui faire croire à une garantie non vérifiée le
serait tout autant.

### Trois décisions

- **La validité s’apprécie à la date attestée, pas aujourd’hui.** Un
  jeton de 2019 reste bon après l’expiration du certificat qui l’a
  produit — c’est même tout l’intérêt de l’horodatage. C’est pourquoi la
  chaîne est parcourue à la main plutôt que confiée à
  [`openssl::cert_verify()`](https://jeroen.r-universe.dev/openssl/reference/certificates.html),
  qui juge à l’heure courante et condamnerait tout jeton ancien.
- **Aucune ancre n’est embarquée.** Un magasin de racines livré avec le
  paquet ferait dépendre du rythme de publication de sommieR la question
  de savoir qui est digne de confiance, et une racine retirée resterait
  attestée par toute version installée. C’est la règle du lot 4
  cartographique, appliquée ici.
- **L’usage `timeStamping` doit être le seul, et critique** (RFC 3161
  §2.3). Un certificat servant aussi à authentifier un serveur web n’est
  plus dédié à l’horodatage, et c’est la dédicace qui fait la garantie.

### Le visa devient autoporteur

Le jeton RFC 3161 emporte le certificat de son autorité ; le visa, lui,
n’emportait que sa signature. Le manifeste laissait donc son
destinataire — une commune, un CRPF — avec une signature qu’il ne
pouvait confronter à aucune clé. La vérification hors ligne par un tiers
n’était vraie qu’à moitié.

- Le certificat du signataire s’enregistre **au moment de signer**, non
  se cherche au moment de vérifier : il fait partie de ce que le visa
  atteste. Nouvelle colonne facultative `visa.certificat`
  (`004_certificat_visa.sql`).
- [`sommier_verifier_visas()`](https://pobsteta.github.io/sommieR/reference/sommier_verifier_visas.md)
  en tire la clé : `cles_publiques` devient inutile pour les visas qui
  en portent un. Les visas antérieurs gardent le comportement précédent
  — leur inventer un certificat après coup serait écrire dans un
  registre append-only ce qui n’y a jamais été.
- [`sommier_verifier_manifeste()`](https://pobsteta.github.io/sommieR/reference/sommier_verifier_manifeste.md)
  vérifie les signatures JWS et les jetons, et lève la réserve inscrite
  depuis la v0.5.0.

### Anomalies et réserves ne se confondent plus

Une anomalie dit que quelque chose est faux ; une **réserve**, que
quelque chose n’a pas pu être vérifié sans que rien n’indique pour
autant que ce soit faux — un jeton intact qu’aucune ancre fournie ne
couvre, un visa sans certificat, la révocation. Les confondre
déclarerait invalide un manifeste parfait vérifié sans ancres.
`sommier_rapport` porte donc `reserves` à côté de `anomalies`, et
[`print()`](https://rdrr.io/r/base/print.html) les montre.

### Format de manifeste

`SOMMIER_VERSION_MANIFESTE` passe à `sommier-manifeste-2` — le
certificat du signataire s’y ajoute. Mais **la v1 reste vérifiable** :
`SOMMIER_FORMATS_MANIFESTE_LUS` liste les formats lus, plus nombreux que
celui qui s’écrit. Un manifeste est un export destiné à être vérifié des
années plus tard ; refuser l’ancien format annulerait cela même qu’il
promet.

### Changement dans le rapport de visas

[`sommier_verifier_visas()`](https://pobsteta.github.io/sommieR/reference/sommier_verifier_visas.md)
rend `horodatage` (quatre états : `absent`, `valide`, `non_rattache`,
`invalide`) à la place du booléen `horodate` : un jeton se juge sur plus
que sa présence. La fonction accepte un argument `ancres`.

### Ce qui reste hors périmètre, et le reste franchement

**La révocation n’est pas vérifiée.** CRL et OCSP demandent le réseau,
ce que la vérification hors ligne exclut par construction. Un certificat
révoqué mais non expiré passe donc. La limite est écrite dans la
documentation et rendue en réserve dans chaque rapport, plutôt que
passée sous silence.

### Tests

Les autorités de test se montent à la volée, avec l’usage et la
criticité voulus. Un constat consigné au passage : **`openssl ts` refuse
lui-même de signer avec un certificat non conforme** (« invalid signer
certificate purpose »), si bien qu’un jeton contrefait de cette façon
n’est pas fabricable — les règles d’usage s’éprouvent donc sur le
certificat, qui est exactement ce que consulte la vérification.

## sommieR 0.9.0

Lot 1 de la couche probante. Le paquet savait poser un visa et obtenir
un jeton d’horodatage ; il sait désormais les lire jusqu’au bout — sans
magasin de confiance, sans réseau, sans configuration.

### Ce qu’un jeton atteste, et non plus seulement qu’il existe

[`sommier_verifier_visas()`](https://pobsteta.github.io/sommieR/reference/sommier_verifier_visas.md)
rendait `horodate`, un booléen qui signifiait « il y a un jeton dans la
colonne ». Ni la date certifiée par l’autorité, ni l’empreinte que le
jeton couvre n’étaient regardées : **un jeton parfaitement valide,
obtenu pour une autre tête de chaîne — une autre forêt, un autre
exercice — passait exactement comme le bon.**

- [`tsa_lire_jeton()`](https://pobsteta.github.io/sommieR/reference/tsa_lire_jeton.md)
  rend le `TSTInfo` encapsulé dans le CMS : empreinte attestée, date,
  numéro de série, nonce, politique.
- [`sommier_verifier_visas()`](https://pobsteta.github.io/sommieR/reference/sommier_verifier_visas.md)
  gagne `date_attestee`, **lue dans le jeton** et non dans la base. La
  colonne `date_visa` est celle que le registre s’est donnée à lui-même
  ; elle ne prouve rien contre celui qui tient la base.
- Le jeton est confronté à la tête qu’il prétend couvrir, dans le
  rapport de visas comme dans
  [`sommier_verifier_manifeste()`](https://pobsteta.github.io/sommieR/reference/sommier_verifier_manifeste.md)
  — nouvelles anomalies `visa_horodatage` et `ancrage_horodatage`. Le
  point existant portait sur ce que la base déclare ; celui-ci sur ce
  que l’autorité a réellement signé.
- [`tsa_horodater()`](https://pobsteta.github.io/sommieR/reference/tsa_horodater.md)
  confronte aussi le nonce rendu à celui envoyé. Le nonce était posé
  depuis la v0.2.0 « pour détecter le rejeu d’une réponse antérieure »,
  mais personne ne le relisait : la détection annoncée n’avait jamais eu
  lieu.
- [`sommier_viser()`](https://pobsteta.github.io/sommieR/reference/sommier_viser.md)
  et
  [`sommier_ancrer()`](https://pobsteta.github.io/sommieR/reference/sommier_ancrer.md)
  rendent la date attestée.

### ES256, et les 32 octets qui le rendent interopérable

Le refus d’`ES256` datait d’une époque où la conversion DER → `R||S`
n’était pas à portée. `openssl` expose `ecdsa_parse()` et
`ecdsa_write()` : elle l’est.

- `SOMMIER_ALGOS_JWS` accepte `RS256` et `ES256`.
  [`ecdsa_der_vers_brut()`](https://pobsteta.github.io/sommieR/reference/ecdsa_der_vers_brut.md)
  et
  [`ecdsa_brut_vers_der()`](https://pobsteta.github.io/sommieR/reference/ecdsa_brut_vers_der.md)
  font la conversion dans les deux sens.
- **Chaque composante est rembourrée à 32 octets**, et ce n’est pas une
  précaution de style. `ecdsa_parse()` rend deux `bignum`, et un
  `bignum` ne porte pas ses zéros de tête : sur 4 000 signatures P-256,
  29 — soit 0,72 % — ont une composante courte. Les concaténer telles
  quelles produirait une signature de 63 octets que la RFC 7518 fait
  refuser, une fois sur cent quarante. Le test ne compte pas sur le
  hasard pour rencontrer le cas : il resigne jusqu’à l’obtenir.
- [`signataire_cle()`](https://pobsteta.github.io/sommieR/reference/signataire_cle.md)
  **déduit l’algorithme de la clé** au lieu de le demander. Laisser
  l’appelant déclarer `alg` en passant une clé d’un autre type
  produirait un en-tête annonçant `RS256` au-dessus d’une signature
  ECDSA : invalide partout, et découvert seulement le jour où quelqu’un
  cherche à vérifier le visa.
- Seule la courbe P-256 est acceptée. `ES384` et `ES512` supposent des
  composantes de 48 et 66 octets, et les rembourrer à 32 les tronquerait
  : une clé P-384 est refusée plutôt que mal signée.

### Ce qui reste hors périmètre, et le reste franchement

La signature de l’autorité d’horodatage et la chaîne de certification
qui la rattache à une racine ne sont toujours pas vérifiées : cela
demande une ancre de confiance, et fait l’objet du lot 2
(`specs/brief_probant-2`). Un `TSTInfo` lu n’est pas un `TSTInfo`
authentifié, et la documentation le dit à chaque endroit où la
distinction compte.

### Tests

- Un vrai jeton RFC 3161 entre au dépôt comme fixture, engendré hors
  ligne — un `TSTInfo` reconstitué à la main ne serait qu’une imitation
  de ce que le paquet doit savoir lire. Sa requête vient de
  [`tsa_requete()`](https://pobsteta.github.io/sommieR/reference/tsa_requete.md)
  : **l’encodeur DER du paquet est donc soumis à une vraie
  implémentation d’autorité**, qui l’accepte.
- Les tests de flux montent leur propre autorité à la volée plutôt que
  de verser une clé privée au dépôt, et se sautent là où `openssl` en
  ligne de commande manque.
- L’interopérabilité d’`ES256` a été vérifiée contre une implémentation
  tierce, cas à composante courte compris.

### Correction

`der_entier_valeur()` accumulait en entier : un `INTEGER` de plus de
quatre octets — un numéro de série, un nonce — débordait et se rendait
en `NA` sans que rien ne l’annonce. L’accumulation se fait en double.

## sommieR 0.8.0

Lot 4 : le PCI vecteur. Les bornes et les détails topographiques que les
livraisons GeoJSON écartent, cherchés là où ils se trouvent.

### Ce que le lot 3 avait conclu trop vite

Le lot 3 concluait que bornes et fossés n’étaient pas dans le cadastre.
Vrai des livraisons d’Etalab, qui sont une **version simplifiée** du
plan : le retraitement ne conserve que parcelles, bâtiments, sections,
feuilles, lieux-dits et subdivisions fiscales. Les détails
topographiques existent pourtant, dans le PCI vecteur brut au format
EDIGÉO publié feuille par feuille par la DGFiP sur le même site.

Vérifié sur la feuille `212000000A01` de Couchey : `BORNE_id` (12
points), `TLINE_id` (50 lignes, attribut `SYM`), `ZONCOMMUNI_id`,
`PARCELLE_id`, `SECTION_id`, `SUBDSECT_id`, `LIEUDIT_id`, `COMMUNE_id`.

### Ce que le paquet apporte

- [`sommier_feuilles_pci()`](https://pobsteta.github.io/sommieR/reference/sommier_feuilles_pci.md)
  rend les feuilles de la commune avec leur emprise et retient celles
  qui touchent la forêt. **Couchey en compte dix-sept, une forêt en
  touche deux** : charger toute la commune serait payer huit fois le
  nécessaire. Les feuilles se choisissent sur la couche légère d’Etalab,
  dont les identifiants correspondent exactement aux noms des archives
  EDIGÉO.
- [`sommier_fond_pci()`](https://pobsteta.github.io/sommieR/reference/sommier_fond_pci.md)
  télécharge et décompresse les archives retenues ;
  [`sommier_fond_pci_lire()`](https://pobsteta.github.io/sommieR/reference/sommier_fond_pci_lire.md)
  en lit une couche, restreinte à l’emprise.

### Deux refus

- **La nature d’un détail n’est pas devinée.** EDIGÉO décrit sa
  structure, et GDAL s’en sert pour bâtir les couches et leurs champs —
  c’est ainsi qu’on obtient `SYM` sans lire le `.DIC` soi-même. Mais la
  structure n’est pas la sémantique : sur la feuille examinée, toutes
  les définitions du `.DIC` sont vides et aucune section n’énumère les
  valeurs. `SYM` distingue mur, fossé, haie et clôture ; sa nomenclature
  appartient à la symbolisation du plan, publiée ailleurs. Le code est
  donc rendu brut, et une table de correspondance peut être **fournie
  par l’appelant**. Aucune n’est embarquée tant qu’une source n’est pas
  citable : une correspondance plausible mais fausse ferait dire au
  document « fossé » là où le terrain montre un mur.
- **La projection vient de ce que le lot déclare.** EDIGÉO est
  auto-descripteur : son fichier `.GEO` porte le référentiel employé
  (`LAMB93`, ou `CC42` à `CC50` pour les livraisons `edigeo-cc`). Le
  pilote, lui, rend un proj4 sans code EPSG. On lit donc la déclaration
  à la source, et la sortie est ramenée en Lambert-93 quelle que soit la
  livraison — les lots en conique conforme sont donc lisibles, non
  refusés. Un référentiel absent ou inconnu est signalé plutôt que
  deviné : reprojeter au hasard poserait la feuille à côté de la forêt,
  exactement le défaut corrigé en v0.6.0.

### Et toujours : un décor

Rien du PCI n’entre dans un registre, une empreinte ou un manifeste. Une
borne relevée par la DGFiP est la donnée d’un tiers ; le bornage qui
fait foi est celui du gestionnaire, porté au registre 2 avec sa
géométrie depuis la v0.7.0. Les bornes s’affichent en surimpression sur
la carte de la desserte, en croix brunes, avec la mention qui le dit.

## sommieR 0.7.0

Les lots 2 et 3 des briefs de cartographie. La géométrie entre dans les
payloads — donc dans l’empreinte — et le cadastre prend sa place de
décor.

### La géométrie est un constat, pas un attribut d’affichage

- Dix constructeurs de payload acceptent une `geometrie` : registres 2
  (bornes, limites), 4 (voirie, équipements), 5 (emprises de coupe), 8
  (phénomènes) et 9 (patrimoine remarquable). Elle se construit avec
  [`geom_point()`](https://pobsteta.github.io/sommieR/reference/geometries.md),
  [`geom_ligne()`](https://pobsteta.github.io/sommieR/reference/geometries.md)
  ou
  [`geom_polygone()`](https://pobsteta.github.io/sommieR/reference/geometries.md).
- **Elle est dans le payload, donc dans la chaîne.** Le contour d’une
  coupe devient aussi opposable que son volume, la position d’une borne
  aussi opposable que la date de son implantation. C’est tout l’objet du
  lot : la géométrie n’est pas rangée à côté du registre, elle est
  dedans.
- **WGS84 sans exception**, comme l’exige la RFC 7946 : un payload doit
  s’interpréter sans contexte extérieur. Des coordonnées projetées
  passées telles quelles sont refusées à la saisie, avec la mention du
  cas le plus probable — du Lambert-93 pris pour des degrés.
- **Arrondi à sept décimales**, soit le centimètre. Aucun instrument de
  terrain ne fait mieux, et deux saisies du même point doivent produire
  les mêmes octets sans quoi le chaînage cesse d’être reproductible.
  Arrondir n’est pas simplifier : aucun sommet n’est retiré.
- La géométrie reste **facultative**. Un gestionnaire sans relevé
  continue de saisir sans, et son sommier reste conforme ; la rendre
  obligatoire fermerait le registre à ceux qu’il doit servir.
- Le type est contraint par la nature de l’objet : un arbre est un
  point, une voirie une ligne, un habitat un polygone. Accepter
  n’importe quoi ferait de la vérification une politesse.

### Premier changement de schéma du projet

- `003_geometrie.sql` ajoute à `entree_sommier` une colonne `geom`
  **dérivée** du payload, posée par déclencheur et reprojetée en
  Lambert-93, avec son index GIST. Le calcul appartient à la base et non
  à l’application : une entrée écrite par un autre client doit porter la
  même géométrie dérivée.
- La colonne est **hors empreinte** et entièrement reconstructible. Si
  elle diverge du payload, c’est le payload qui fait foi — la colonne se
  reconstruit, l’empreinte non.
- Les registres 2, 4, 5, 8 et 9 passent en version de schéma `1.1.0`.
  Les entrées antérieures gardent la leur et restent valides : le
  registre est append-only, un changement de schéma ne se rétrofitte
  pas.
- `v_objet_localise` rassemble les entrées localisées, tous registres
  confondus.
  [`sommier_objets_localises()`](https://pobsteta.github.io/sommieR/reference/sommier_objets_localises.md)
  les lit ;
  [`sommier_exporter_sig()`](https://pobsteta.github.io/sommieR/reference/sommier_exporter_sig.md)
  gagne une couche `objets`.

### Le cadastre est un décor, jamais une écriture

- [`sommier_fond_cadastral()`](https://pobsteta.github.io/sommieR/reference/sommier_fond_cadastral.md)
  télécharge et met en cache une couche communale ;
  [`sommier_fond_lire()`](https://pobsteta.github.io/sommieR/reference/sommier_fond_lire.md)
  la restreint à l’emprise de la forêt.
- **Rien n’entre dans le registre** : ni entrée, ni empreinte, ni
  manifeste. Verser le cadastre dans le sommier ferait passer la donnée
  d’un tiers pour un constat du gestionnaire.
- **Rien ne se télécharge tout seul** :
  [`sommier_rapport_quarto()`](https://pobsteta.github.io/sommieR/reference/sommier_rapport_quarto.md)
  reçoit le fond en argument. Un document de gestion doit pouvoir
  s’engendrer hors ligne, et le même rapport rejoué plus tard ne doit
  pas changer de fond sans le dire. Le millésime est conservé avec le
  fichier et affiché sous la carte.
- **Ce que ces livraisons ne portent pas.** Vérification faite avant
  d’écrire une ligne : le GeoJSON communal expose parcelles, sections,
  bâtiments et lieux-dits — ni bornes ni fossés. Ceux-là sont dans la
  forme EDIGEO du Plan Cadastral Informatisé, publiée sur le même site
  sous `dgfip-pci-vecteur`, par feuille et dans un format demandant le
  pilote EDIGEO de GDAL : hors de portée de ce paquet aujourd’hui, non
  hors d’atteinte. Et de toute façon, une borne relevée par la DGFiP
  reste la donnée d’un tiers — ce qui fait foi, c’est le constat du
  gestionnaire, registres 2 et 4, chaîné avec le reste.

### Cartes et démonstration

- Le rapport gagne trois cartes d’objets : emprises des phénomènes
  (chapitre 4), patrimoine remarquable localisé (7), voirie et limites
  (8). Les emprises sont translucides — une sécheresse englobe le
  chablis qu’elle a précédé, et un aplat opaque en cacherait une.
- Un sujet revisité n’est dessiné qu’une fois, à son dernier relevé : la
  chaîne garde tout, la carte montre l’état.
- Le jeu de démonstration porte treize écritures localisées. Les
  coordonnées sont inventées comme le reste des écritures.

## sommieR 0.6.0

Le rapport de gestion antérieure était entièrement tabulaire, alors que
le sommier sait déjà **où** les choses se passent : chaque entrée porte
un `ug_uuid`, chaque unité de gestion un contour daté. Cette version le
porte sur une carte, sans rien changer au modèle de données ni à la
chaîne.

Trois briefs déposés dans `specs/` cadrent la suite : ce lot, la
géométrie dans les payloads — qui la ferait entrer dans l’empreinte, et
rendrait le contour d’une coupe aussi opposable que son volume — et le
fond cadastral.

### Ce que le sommier sait porter sur une carte

- [`sommier_geometrie_ug()`](https://pobsteta.github.io/sommieR/reference/sommier_geometrie_ug.md)
  rend le contour **en vigueur à une date**, en WKT et en Lambert-93. La
  date n’est pas un ornement : `ug_geometrie` est versionnée, et une
  carte qui accompagne un bilan de période doit montrer le parcellaire
  de l’époque, non celui du jour de l’édition.
  [`sommier_couche_ug()`](https://pobsteta.github.io/sommieR/reference/sommier_couche_ug.md)
  prend donc par défaut la borne de fin de la période, et non
  aujourd’hui.
- [`sommier_indicateurs_ug()`](https://pobsteta.github.io/sommieR/reference/sommier_indicateurs_ug.md)
  agrège par unité ce qui se cartographie : entrées, volume martelé,
  surface coupée, montant de travaux. Le volume martelé exclut
  `coupe_realisee`, comme la balance de possibilité — la même coupe
  martelée puis exploitée doublerait le prélèvement.
- [`sommier_couche_ug()`](https://pobsteta.github.io/sommieR/reference/sommier_couche_ug.md)
  joint les deux et porte en attribut les unités sans contour connu.

### Trois cartes dans le rapport, pas une de plus

- Chapitre 1 le parcellaire, chapitre 2 les volumes martelés, chapitre 3
  les montants de travaux. Les chapitres 1.1, 2.1, 5 et 9 n’ont rien de
  spatial : une carte décorative dans un document réglementaire coûte la
  confiance qu’elle prétend gagner.
- Une **unité sans contour** est nommée sous la première carte plutôt
  qu’escamotée — sinon le document laisserait croire la forêt
  entièrement cartographiée.
- Une **unité sans écriture** se teinte à zéro plutôt que de disparaître
  : là où rien n’a été fait n’est pas là où l’on ne sait pas.
- Les **travaux hors unité de gestion** (imprimé A50H) ne figurent sur
  aucune carte, faute de se localiser.
- La géométrie voyage en WKT dans le RDS du rapport : le document
  n’exige donc pas `sf` pour être relu. Sans `sf` ou sans contour, il
  s’engendre quand même, avec la mention correspondante.

### Site

- Deux articles : « Gestion antérieure : du registre au document », qui
  déroule les données, et « Le document engendré », qui encadre la
  sortie même de
  [`sommier_rapport_quarto()`](https://pobsteta.github.io/sommieR/reference/sommier_rapport_quarto.md).

### Correction

- `sommier_exporter_sig(format = "geojson")` écrivait des coordonnées en
  Lambert-93 sans déclaration de projection, là où la RFC 7946 impose le
  WGS84 et où tout lecteur le suppose : le fichier s’ouvrait sans erreur
  et posait la forêt à des milliers de kilomètres. L’export reprojette
  désormais à l’émission ; le GeoPackage, qui porte son système, reste
  en EPSG:2154.

## sommieR 0.5.0

Priorité 5 du brief : les exports. Le sommier devient la source des
documents réglementaires plutôt qu’un registre à recopier.

### Gestion antérieure, trois référentiels, un seul assemblage

- [`sommier_gestion_anterieure()`](https://pobsteta.github.io/sommieR/reference/sommier_gestion_anterieure.md)
  rassemble sur une période les coupes, la balance de possibilité, les
  travaux, les évènements, et selon le référentiel le bilan financier,
  l’équilibre forêt-gibier et le patrimoine remarquable.
- Le brief le pose : *« les trois se génèrent depuis les mêmes registres
  »*. Il y a donc **un assemblage et trois présentations** — `psg` (bloc
  3 de l’arrêté de 2012), `amenagement` (partie 2 du document ONF) et
  `ct88` (étape 5) — plutôt que trois extractions parallèles qui
  divergeraient à la première évolution.
- Chaque référentiel ne reçoit que ce qu’il demande. Le PSG n’emporte
  pas le détail financier, que le propriétaire n’a pas à produire au
  CRPF ; le CT88, tourné vers l’évaluation d’un contrat, n’emporte pas
  l’inventaire du patrimoine. Restreindre la sortie évite de diffuser
  plus que nécessaire — les registres 3 et 7 portent des données
  personnelles.
- Le patrimoine remarquable n’est **pas** borné par la période : c’est
  un état courant, et le borner écarterait un arbre inventorié plus tôt
  alors que le document veut l’inventaire tel qu’il est.
- [`sommier_rapport_markdown()`](https://pobsteta.github.io/sommieR/reference/sommier_rapport_markdown.md)
  met le tout en forme. Du Markdown, pas un formulaire officiel : la
  mise en page réglementaire appartient à l’outil de rédaction, et la
  reproduire ici la figerait sur une version des textes.

### Export cartographique

- [`sommier_exporter_sig()`](https://pobsteta.github.io/sommieR/reference/sommier_exporter_sig.md)
  exporte les unités de gestion et leur géométrie en vigueur à une date,
  enrichies du nombre d’entrées qui s’y rattachent.
- Deux formats : `geojson`, qui n’exige rien de plus que PostGIS et que
  le destinataire ouvre sans rien installer, et `gpkg` via `sf`.
- Une unité sans géométrie connue est **omise de la couche mais
  signalée** : la faire figurer sans contour créerait une entité
  fantôme, l’omettre en silence laisserait croire la forêt entièrement
  cartographiée. Un GeoPackage qui ne contiendrait aucune unité est
  refusé plutôt qu’écrit vide — un fichier SIG sans couche est plus
  difficile à diagnostiquer qu’une erreur.
- La conversion vers `sf` passe par le WKT et non par le GeoJSON :
  `st_as_sfc()` a une méthode caractère pour le WKT, là où lire une
  géométrie GeoJSON nue dépendrait du pilote GDAL et de sa tolérance aux
  fragments sans enveloppe `Feature`.

## sommieR 0.4.0

Priorité 4 du brief : les quatre registres restants. **Les neuf
registres du sommier unifié sont désormais ouverts à l’écriture.**

### Registres 2, 3, 4 et 9

- Registre 2 — foncier et limites
  ([`registre2_foncier()`](https://pobsteta.github.io/sommieR/reference/registre2_foncier.md),
  imprimé A40) : délimitation, bornage, application ou distraction du
  régime forestier, acquisitions, servitudes. La répartition du coût
  entre propriétaire et riverains est vérifiée quand les trois montants
  sont donnés — une répartition qui ne totalise pas le coût est une
  erreur de saisie.
- Registre 3 — droits et concessions
  ([`registre3_droit()`](https://pobsteta.github.io/sommieR/reference/registre3_droit.md),
  imprimé A50C) et l’affouage, propre à la forêt communale
  ([`registre3_affouage()`](https://pobsteta.github.io/sommieR/reference/registre3_affouage.md)
  : rôle, garants, taxe, mode de partage). Une expiration antérieure au
  départ est refusée : le droit n’aurait jamais existé.
- Registre 4 — infrastructures
  ([`registre4_voirie()`](https://pobsteta.github.io/sommieR/reference/registre4_voirie.md),
  [`registre4_equipement()`](https://pobsteta.github.io/sommieR/reference/registre4_equipement.md),
  imprimés A50D et A50D bis), ouvrages DFCI compris.
- Registre 9 — patrimoine remarquable, les cinq types de fiche de la
  série A50 r/\* : arbre, peuplement, vestige, espèce protégée, habitat.
  La composition d’un peuplement doit sommer à 10, l’imprimé l’exprimant
  en dixièmes.
- Un sujet revisité donne une entrée de plus portant la même appellation
  : la série de mesures se reconstitue par requête, rien n’est écrasé.

### Échelles d’ancrage révisées

Les registres 2, 3 et 9 passent de `foret` ou `ug` à `mixte`, d’après
les imprimés eux-mêmes : l’A50C porte une colonne « unités de gestion /
séries », une servitude vise des parcelles identifiées, et une liste
d’espèces protégées peut couvrir la forêt entière. Le registre 4 reste à
l’échelle de la forêt — une route traverse plusieurs unités, l’y
rattacher serait arbitraire.

### Vues et analyses

- [`sommier_densite_voirie()`](https://pobsteta.github.io/sommieR/reference/sommier_densite_voirie.md)
  / `v_densite_voirie` : longueurs et densités en km pour 100 ha
  (imprimé A50D). Seule la voirie **privée** compte — une départementale
  traversant la forêt ne dit rien de sa desserte. La densité vaut `NA`
  sans surface connue plutôt que d’être inventée.
- [`sommier_elements_ibp()`](https://pobsteta.github.io/sommieR/reference/sommier_elements_ibp.md)
  rassemble ce que le registre 9 fournit à l’Indice de Biodiversité
  Potentielle : arbres à microhabitats, bois mort sur pied, très gros
  bois, milieux ouverts, espèces protégées. **La fonction ne cote pas
  l’IBP et ne le prétend pas** — un facteur se cote sur placette selon
  un protocole de terrain, pas par comptage d’un registre qui
  n’inventorie que le remarquable. Rendre une note serait plus vendeur
  et faux.
- `v_droit_en_vigueur` écarte les droits expirés sans les sortir du
  registre.
- `v_droit` n’expose ni `titulaire` ni `garants`, `v_foncier` ni
  `v_remarquable` aucune donnée nominative superflue : même règle qu’au
  registre 7.

## sommieR 0.3.0

Priorité 3 du brief : comptabilité et bilan financier.

### Registre 7 — comptabilité (imprimé A50G)

- [`registre7_ecriture()`](https://pobsteta.github.io/sommieR/reference/registre7_ecriture.md)
  enregistre une recette ou une dépense. `SOMMIER_POSTES_COMPTABLES`
  porte la nomenclature des 19 postes, répartis dans les quatre blocs de
  l’imprimé : produits, travaux d’entretien, travaux neufs, autres
  frais.
- **Le sens et la rubrique se déduisent du poste**, ils ne se saisissent
  pas : ils ne peuvent donc pas le contredire. Et `montant_eur` est
  toujours positif — porter le sens dans le signe est la source
  classique des doubles négations, où une dépense saisie à `-500` sur un
  poste débiteur redevient silencieusement une recette.
- `dispositif_fiscal` rattache une écriture à un dispositif de la forêt
  privée (DEFI, Monichon, IFI).

### Budget prévisionnel

- [`budget_definir()`](https://pobsteta.github.io/sommieR/reference/budget_definir.md)
  fixe ou révise le montant prévu d’un poste.
- **Le prévisionnel n’est pas une entrée de sommier.** Le brief
  l’interdit : « le programme prévisionnel appartient à l’aménagement ou
  au PSG ; le sommier n’enregistre que le réalisé et le constaté ». Il
  vit donc dans sa propre table, à côté de la possibilité annuelle, et
  il est **mutable** — un budget se révise, et cette révision n’a pas à
  être opposable. Ce qui doit l’être, c’est le réalisé, qui lui est dans
  la chaîne.

### Vues calculées

- [`sommier_bilan_financier()`](https://pobsteta.github.io/sommieR/reference/sommier_bilan_financier.md)
  / `v_bilan_financier` : recettes, dépenses, solde et cumul par
  exercice, avec les trois rubriques de dépense détaillées.
  `bois_delivres_eur` isole l’affouage, auquel l’imprimé A50G réserve sa
  colonne.
- [`sommier_execution_budgetaire()`](https://pobsteta.github.io/sommieR/reference/sommier_execution_budgetaire.md)
  / `v_execution_budgetaire` : réalisé confronté au prévisionnel, poste
  par poste. La jointure est complète et non gauche — un poste budgété
  mais jamais exécuté est une information de gestion au moins aussi
  utile qu’un dépassement, et un poste exécuté hors budget doit
  apparaître plutôt que disparaître. `execution_pct` vaut `NA` sur une
  base budgétaire nulle, un taux n’ayant alors pas de sens ; l’écart en
  euros le dit déjà.
- `v_comptabilite` n’expose pas `tiers` : c’est une donnée à caractère
  personnel, qui reste lisible dans le payload pour qui en a besoin mais
  ne se diffuse pas par la vue de consultation courante.

## sommieR 0.2.0

Priorité 2 du brief : évènements, visas signés et ancrage.

### Visa signé et ancrage

- [`sommier_viser()`](https://pobsteta.github.io/sommieR/reference/sommier_viser.md)
  clôture un exercice : il inscrit l’acte au registre 1, signe la tête
  de chaîne en JWS détaché, l’horodate si une autorité est configurée,
  puis pose le visa. L’acte est écrit **avant** la lecture de la tête,
  de sorte que le visa atteste un sommier contenant la trace de sa
  propre délivrance.
- [`sommier_signataire()`](https://pobsteta.github.io/sommieR/reference/sommier_signataire.md)
  sépare l’identité de la signature, parce qu’elles viennent de sources
  différentes : un fournisseur OIDC atteste qui signe, une clé ou un
  service eIDAS produit la signature.
  [`signataire_keycloak()`](https://pobsteta.github.io/sommieR/reference/signataire_keycloak.md)
  et
  [`signataire_cle()`](https://pobsteta.github.io/sommieR/reference/signataire_cle.md)
  couvrent les deux cas d’usage courants.
- [`jws_signer_detache()`](https://pobsteta.github.io/sommieR/reference/jws_signer_detache.md)
  /
  [`jws_verifier_detache()`](https://pobsteta.github.io/sommieR/reference/jws_verifier_detache.md)
  implémentent la signature détachée sur charge non encodée (RFC 7515 et
  7797, `b64: false`). La tête de chaîne n’est pas recopiée dans le
  jeton : le vérificateur la relit du registre, ce qui lie la signature
  à la chaîne et non à une copie.
- [`sommier_ancrer()`](https://pobsteta.github.io/sommieR/reference/sommier_ancrer.md)
  horodate la tête indépendamment de tout visa, pour qu’un exercice non
  visé ne puisse pas non plus être réécrit discrètement.
- [`sommier_verifier_visas()`](https://pobsteta.github.io/sommieR/reference/sommier_verifier_visas.md)
  confronte chaque visa à la chaîne et à la clé publique fournie. Les
  clés sont passées par l’appelant et non cherchées au JWKS : un visa
  doit rester vérifiable des années plus tard, hors ligne.
- Client RFC 3161 complet
  ([`tsa_requete()`](https://pobsteta.github.io/sommieR/reference/tsa_requete.md),
  [`tsa_lire_reponse()`](https://pobsteta.github.io/sommieR/reference/tsa_lire_reponse.md),
  [`tsa_horodater()`](https://pobsteta.github.io/sommieR/reference/tsa_horodater.md)),
  transport injectable. Sans autorité configurée, le visa est posé sans
  jeton et le rapport le signale plutôt que d’échouer.

### Registres 1 et 8

- Registre 1 — validations
  ([`registre1_validation()`](https://pobsteta.github.io/sommieR/reference/registre1_validation.md),
  imprimé A10) : visas annuels, arrêtés, délibérations, agréments CRPF,
  engagements fiscaux.
- Registre 8 — évènements et faune :
  [`registre8_phenomene()`](https://pobsteta.github.io/sommieR/reference/registre8_phenomene.md)
  (A50K),
  [`registre8_tableau_chasse()`](https://pobsteta.github.io/sommieR/reference/registre8_tableau_chasse.md)
  (A50L),
  [`registre8_equilibre_gibier()`](https://pobsteta.github.io/sommieR/reference/registre8_equilibre_gibier.md)
  (équilibre forêt-gibier, LAAAF 2014) et
  [`registre8_detection()`](https://pobsteta.github.io/sommieR/reference/registre8_detection.md).
- Le registre 8 est d’échelle mixte : une tempête frappe des unités
  identifiées, un tableau de chasse est à l’échelle de la forêt.
- Nouvelles vues : `v_validation`, `v_tenue_sommier`, `v_evenement`,
  `v_detection_en_attente`, `v_tableau_chasse`, `v_equilibre_gibier`.

### Détections de télédétection

- [`sommier_importer_detections()`](https://pobsteta.github.io/sommieR/reference/sommier_importer_detections.md)
  inscrit les propositions FORDEAD/FAST avec le NDP de leur source,
  jamais NDP 0 : une détection est une proposition, pas un constat.
- [`sommier_valider_detection()`](https://pobsteta.github.io/sommieR/reference/sommier_valider_detection.md)
  inscrit le constat de terrain en NDP 0, qui rectifie la détection —
  qu’il la confirme ou l’écarte. La proposition sort des vues de
  consultation sans sortir de la chaîne.

### Corrections

- [`sommier_init_schema()`](https://pobsteta.github.io/sommieR/reference/sommier_init_schema.md)
  exécute le script instruction par instruction
  ([`decouper_sql()`](https://pobsteta.github.io/sommieR/reference/decouper_sql.md)).
  L’envoyer d’un bloc échouait sur les pilotes passant par le protocole
  étendu de PostgreSQL — « cannot insert multiple commands into a
  prepared statement » — ce que le pilote employé en développement
  masquait. Le découpage respecte les chaînes, les commentaires
  imbriqués et les corps de fonction délimités par `$$`.
- Les transactions sont réentrantes, par points de reprise.
  `dbWithTransaction` ne s’imbrique pas : le `COMMIT` interne validait
  la transaction externe avant l’heure, si bien qu’un visa refusé
  laissait derrière lui l’acte de registre 1 déjà écrit.
- [`entrees_en_data_frame()`](https://pobsteta.github.io/sommieR/reference/entrees_en_data_frame.md)
  n’utilise plus [`methods::as()`](https://rdrr.io/r/methods/as.html),
  qui n’était pas importé.
- Les listes de paramètres envoyées au pilote ne sont plus nommées.
  [`vapply()`](https://rdrr.io/r/base/lapply.html) sur un vecteur de
  caractères nomme son résultat par ses propres valeurs :
  [`ug_lire()`](https://pobsteta.github.io/sommieR/reference/ug_lire.md)
  et
  [`ug_fusionner()`](https://pobsteta.github.io/sommieR/reference/ug_fusionner.md)
  transmettaient donc des paramètres nommés, que RPostgres refuse («
  `params` must not be named ») là où RPostgreSQL les tolère. Les noms
  sont désormais retirés au point d’appel, pour qu’aucun site ne puisse
  régresser là-dessus.

## sommieR 0.1.0

Première version : le noyau append-only vérifiable (priorité 1 du
brief).

### Registre et chaîne

- [`sommier_entree()`](https://pobsteta.github.io/sommieR/reference/sommier_entree.md)
  construit une entrée validée ;
  [`sommier_ajouter()`](https://pobsteta.github.io/sommieR/reference/sommier_ajouter.md)
  la chaîne et l’écrit,
  [`sommier_lire()`](https://pobsteta.github.io/sommieR/reference/sommier_lire.md)
  la relit,
  [`sommier_verifier()`](https://pobsteta.github.io/sommieR/reference/sommier_verifier.md)
  recalcule la chaîne de la genèse à la tête.
- [`sommier_chainer()`](https://pobsteta.github.io/sommieR/reference/sommier_chainer.md)
  et
  [`sommier_verifier_chaine()`](https://pobsteta.github.io/sommieR/reference/sommier_verifier_chaine.md)
  opèrent hors base : un auditeur tiers peut vérifier un export sans
  serveur.
- [`jcs()`](https://pobsteta.github.io/sommieR/reference/jcs.md)
  implémente la sérialisation JSON canonique de la RFC 8785 — tri des
  clés par unités de code UTF-16, échappement minimal, nombres selon
  ECMAScript `Number::toString`.
- L’empreinte couvre l’enregistrement complet, pas seulement le payload
  : voir `SOMMIER_CHAMPS_EMPREINTE` pour la liste des champs et la
  justification de cet écart au brief.

### Registres ouverts

- Registre 5 — coupes et récoltes
  ([`registre5_coupe()`](https://pobsteta.github.io/sommieR/reference/registre5_coupe.md),
  imprimés A50E/F/I).
- Registre 6 — travaux
  ([`registre6_travaux()`](https://pobsteta.github.io/sommieR/reference/registre6_travaux.md),
  imprimés A50J/J bis/H).
- Les sept autres registres sont déclarés dans `SOMMIER_REGISTRES` et
  refusés à l’écriture avec un message explicite.

### Base de données

- [`sommier_init_schema()`](https://pobsteta.github.io/sommieR/reference/sommier_init_schema.md)
  déploie le schéma PostGIS et les vues ; les deux fichiers SQL sont
  idempotents.
- L’append-only est imposé par des déclencheurs, y compris sur
  `TRUNCATE`, que les déclencheurs `FOR EACH ROW` ne couvrent pas ;
  `visa` et `ancrage` sont immuables au même titre.
- [`sommier_revoquer_mutations()`](https://pobsteta.github.io/sommieR/reference/sommier_revoquer_mutations.md)
  retire `UPDATE`, `DELETE` et `TRUNCATE` au rôle applicatif.
- Les écritures concurrentes sont sérialisées par forêt via
  `pg_advisory_xact_lock()`, pris avant la lecture de la tête de chaîne.

### Unités de gestion

- Identifiant stable à vie, distinct du numéro d’affichage ; un numéro
  n’est unique que parmi les unités actives, ce qui autorise sa reprise
  après clôture sans jamais réattribuer l’identifiant.
- [`ug_scinder()`](https://pobsteta.github.io/sommieR/reference/ug_scinder.md)
  et
  [`ug_fusionner()`](https://pobsteta.github.io/sommieR/reference/ug_fusionner.md)
  clôturent les unités d’origine et enregistrent la filiation. La table
  `ug_filiation` porte le cas à plusieurs parents, que la colonne
  `parent_uuid` seule ne sait pas représenter.

### Vues calculées

- `v_balance_possibilite` (imprimé A50E) : volumes martelés moins
  possibilité, cumulés. `coupe_realisee` en est exclu, la même coupe
  étant d’abord martelée puis exploitée.
- `v_entree_courante` écarte les entrées rectifiées ; la chaîne les
  conserve.
- `v_coupe`, `v_travaux`, `v_tete_chaine`.

### Export

- [`sommier_exporter_manifeste()`](https://pobsteta.github.io/sommieR/reference/sommier_exporter_manifeste.md)
  et
  [`sommier_verifier_manifeste()`](https://pobsteta.github.io/sommieR/reference/sommier_verifier_manifeste.md)
  : partage vérifiable hors ligne, visas et ancrages compris. L’export
  GeoPackage est prévu pour la 0.5.0.
