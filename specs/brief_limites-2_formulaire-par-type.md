# Brief — Limites, lot 2 : un formulaire de constat selon le type d'élément

*Établi le 2 octobre 2026, à partir du retour de terrain sur `limites-orleans`.*

## Pourquoi ce lot existe

Le formulaire du projet QField des limites propose l'élément du plan le plus
proche à moins de 30 m, mais par priorité : **une borne d'abord**, puis une
ligne, puis une surface. Près d'une borne, c'est donc toujours elle qui est
proposée, et l'agent ne peut pas constater la ligne (voie, détail linéaire) ou
la surface (bâtiment, cours d'eau) qui passe à côté.

Et la liste des états est la même pour tous les éléments : en place,
endommagé, non retrouvé, détruit, inaccessible, hors plan. Elle convient aux
bornes, mal aux lignes, pas aux surfaces.

## Ce que la vérification a établi

- **La priorité est écrite dans le modèle.** La valeur par défaut de
  `element_id` enchaîne trois `overlay_nearest()` (points, lignes, surfaces)
  dans un `coalesce()` : le premier trouvé gagne.
- **Une tolérance en pixels n'est pas fiable.** Dans un formulaire, QField
  calcule en mètres, et le niveau de zoom de la carte n'y est pas exposé de
  façon sûre. Une distance « à l'écran » se calculerait mal, ou pas du tout.
- **L'état est déjà exigé**, par une contrainte « non nul » forte. Mais la
  liste offrait une valeur vide, et rien ne liait l'état à l'élément choisi.
- **À Orléans**, 118 éléments : 69 points (68 bornes), 31 lignes (30 voies),
  18 surfaces (7 bâtiments, 6 détails surfaciques, 5 cours d'eau). Un cours
  d'eau peut être une ligne ou une surface selon la feuille : le type se
  déduit de la **forme** de l'objet, non de sa catégorie.

## Décisions

*Arrêtées le 2 octobre 2026 : le type d'abord, quatre niveaux de visibilité
pour les lignes, « conforme → disparue » pour les surfaces.*

1. **Le type d'élément d'abord.** Un champ « Type » ouvre le formulaire :
   point, ligne, surface, hors plan. Sa valeur par défaut est le type de
   l'élément **le plus proche, toutes formes confondues** ; l'agent la change
   d'un geste. Deux précisions, venues des tests sur le plan de Loury :
   - une surface se mesure à son **contour** : un point pris dedans serait
     sinon toujours à zéro mètre d'elle ;
   - **à 2 m d'une borne**, c'est la borne : une borne au bord d'un cours
     d'eau avait le contour de la surface à 38 cm, plus près qu'elle.
2. **La liste des éléments suit le type.** Elle ne montre que les éléments de
   ce type, et propose le plus proche d'entre eux à moins de 30 m. Près d'une
   borne, choisir « Ligne » propose la voie qui passe à côté.
3. **La liste des états suit le type**, lue dans une table des états du
   GeoPackage (une liste de valeurs filtrée par le type, que QField sait
   lire). Changer de type après avoir choisi un état rend l'état invalide : il
   faut le choisir de nouveau.
4. **L'état est obligatoire** : aucune valeur vide dans la liste, contrainte
   forte, et l'état doit appartenir à la liste du type.
5. **Les états**, arrêtés le 2 octobre 2026 :

   | Type | États | Couleur de la dernière visite |
   |---|---|---|
   | Point | en place · endommagé · non retrouvé · détruit · inaccessible *(inchangés)* | vu · défaut · perdu · perdu · à voir |
   | Ligne | visible · partiellement visible · peu visible · non visible · inaccessible | vu · défaut · défaut · perdu · à voir |
   | Surface | conforme au plan · modifiée · dégradée · disparue · inaccessible | vu · défaut · défaut · perdu · à voir |
   | Hors plan | hors plan *(aucun élément du plan)* | — |

   Une ligne se suit sans peine (visible), par endroits (partiellement), à
   quelques traces (peu visible), ou plus du tout (non visible). Une surface
   modifiée a une emprise ou une forme différente du plan ; dégradée, elle est
   en ruine, comblée ou envahie.

6. **Le registre 2 garde la forme de l'élément** : le constat recopie
   `forme` (point, ligne, surface) avec l'élément, et l'import refuse un état
   qui n'est pas de la liste de sa forme. Schéma `r2-1.4.0` ; les constats
   écrits avant restent valides.
7. **La couleur de la dernière visite**, sur le terrain et dans le rapport,
   range chaque état dans quatre classes : vu, vu en défaut, perdu, à voir.

## Livrables

- Modèle QField des limites régénéré : champ `type_element`, table `etats`,
  listes filtrées, contraintes.
- `R/qfield.R` : la table des états écrite dans le GeoPackage, la forme
  recopiée dans le constat, le contrôle à l'import.
- `R/registre2.R` : les états par forme, la validation, `r2-1.4.0`.
- Rapport : libellés et classes des nouveaux états.
- Tests : le projet relu par PyQGIS propose une ligne quand le type est
  « Ligne », même à 50 cm d'une borne ; un état de ligne sur une borne est
  refusé, dans le formulaire et à l'import.

## Critères d'acceptation

- Près d'une borne, un constat de type « Ligne » propose la ligne la plus
  proche, et la liste ne montre que des lignes.
- La liste des états ne montre que ceux du type choisi ; un formulaire sans
  état, ou avec un état d'un autre type, ne s'enregistre pas.
- Un import qui porte un état incohérent avec la forme de l'élément est
  refusé, sans rien écrire.
- Les constats déjà inscrits (états des bornes) se lisent comme avant.
- Le projet s'ouvre dans QGIS et dans QField 4.3.
