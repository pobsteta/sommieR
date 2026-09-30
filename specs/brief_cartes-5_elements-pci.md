# Brief — Cartes, lot 5 : les éléments du plan cadastral, dans la forêt et à 20 m

*Établi le 30 septembre 2026, après inventaire des feuilles EDIGÉO de Loury.*

## Pourquoi ce lot existe

Le lot 4 est allé chercher le PCI vecteur, mais n'en montre que les bornes, en
croix brunes sur la carte de la desserte. Pour le suivi des limites, c'est à la
fois trop peu et mal placé :

* **trop peu** : le plan porte aussi des murs, des fossés, des chemins, des cours
  d'eau, des bâtiments et des points remarquables. Le lot 4 lit `TLINE_id` sans
  l'afficher, et il ignore les autres couches ;
* **mal placé** : une borne n'est pas un élément de desserte, et le lecteur qui
  cherche ses limites ne sait pas où regarder.

Ce lot prend **tous les éléments physiques du plan situés dans la forêt ou à
moins de 20 m de son contour**, les numérote, et leur donne une carte et un
inventaire dans le rapport. C'est la liste que le lot 1 de la série « Limites »
emportera sur le terrain, dans QField.

## Ce que la vérification a établi

La forêt de Loury (sommier `sommier_reconfort`, 30 unités) touche cinq feuilles :
`451880000A02`, `A04`, `B01` au 1/5000, `45188000ZK01` et `ZL01` au 1/2000.
Toutes les couches ont été lues avec `sf::st_layers()` sur le `.THF`. Le compte
ci-dessous porte sur les objets qui touchent l'union des unités élargie de 20 m :

| Couche | Géométrie | Ce que c'est | Retenus | Sur les 5 feuilles |
|---|---|---|---|---|
| `BORNE_id` | point | borne | **68** | 578 |
| `ZONCOMMUNI_id` | ligne | voie (nom en `TEX`) | 30 | 51 |
| `BATIMENT_id` | polygone | bâtiment | 7 | 110 |
| `TSURF_id` | polygone | détail surfacique (`SYM` 34) | 6 | 30 |
| `TRONFLUV_id` | polygone | cours d'eau | 5 | 7 |
| `TLINE_id` | ligne | détail linéaire (`SYM` 21, « chemin ») | 1 | 50 |
| `TPOINT_id` | point | détail ponctuel (`SYM` 50, « pylone télécom ») | 1 | 2 |
| `SYMBLIM_id` | point | signe de limite, orienté (`ORI`) | 0 | 6 |
| `TRONROUTE_id` | polygone | tronçon de route | 0 | 5 |

Soit **118 éléments** pour Loury, dont 68 bornes.

Quatre constats commandent la conception :

1. **Le plan nomme une partie de ses éléments.** Le lot 4 croyait que la
   nature d'un détail ne se trouvait nulle part dans l'archive. C'est vrai du
   code `SYM`, mais pas de l'objet : `TPOINT_id` porte un attribut `TEX`
   (« pylone télécom »), `ZONCOMMUNI_id` porte le nom de la voie, et les
   couches `*_LABEL` rattachent un texte à leur objet par `OGR_OBJ_LNK` (les
   lignes `TLINE` sont étiquetées « chemin »). Ce texte a été écrit par le
   service du cadastre : c'est une source citable, et il suffit de le lire.
2. **Le code seul ne dit toujours rien.** Sans texte, `SYM` = 34 sur six
   surfaces reste muet, et rien dans l'archive ne dit ce qu'il désigne.
3. **Les couches restantes ne sont pas des éléments de terrain.**
   `ID_S_OBJ_Z_1_2_2` (277 points) contient les positions des étiquettes des
   numéros de parcelle. `PARCELLE`, `SECTION`, `SUBDSECT`, `SUBDFISC`,
   `COMMUNE`, `LIEUDIT` et `NUMVOIE` découpent ou nomment le territoire, sans
   rien matérialiser. On les écarte.
4. **Chaque objet porte ses dates.** `CREAT_DATE` et `UPDATE_DATE` disent quand
   le cadastre a dessiné ou retouché l'élément, par exemple 2021 pour les signes
   de limite de Loury. C'est une donnée précieuse pour une vérification : une
   borne dessinée en 2021 et introuvable en 2026 n'a pas la même histoire
   qu'une borne de 1960.

## Décisions de conception

1. **La sélection se fait à 20 m, sans autre filtre.** Est retenu tout élément
   physique qui touche l'union des contours des unités élargie de 20 m. Le
   tampon capte les bornes et les murs de la limite, que deux dessins
   superposent rarement au mètre près. Il capte aussi les éléments du
   riverain immédiat, qu'on veut voir. Les 20 m sont un paramètre, et le rapport
   imprime la valeur retenue.

2. **La situation se calcule, elle ne s'enregistre pas.** Chaque élément reçoit
   `situation = "foret"` s'il touche l'union des unités, `"tampon"` sinon. Même
   logique que les ténements : c'est une lecture du plan au rendu, pas un fait
   advenu.

3. **La nature se lit dans le plan, puis se cite, puis se tait.** Dans l'ordre :
   * le texte que le plan attache à l'objet (`TEX`, ou `*_LABEL` joint par
     `OGR_OBJ_LNK`), marqué `nature_source = "plan"` ;
   * le nom de la couche, quand il suffit : borne, bâtiment, cours d'eau, voie ;
   * une table `SYM` **fournie par l'appelant**, marquée
     `nature_source = "appelant"` ;
   * sinon, rien : le document écrit « détail surfacique, code 34 ».

   La règle du lot 4 tient : aucune correspondance plausible n'est embarquée
   sans source. Si la documentation DGFiP du format EDIGÉO PCI donne la table,
   elle entre dans le paquet avec sa référence, comme les projections.

4. **Chaque élément a un identifiant stable.** Il se compose de la feuille et de
   l'`OBJECT_RID` (`451880000A02:Objet_849915`). C'est la clé que le projet
   QField porte sur le terrain, et que le constat recopiera. Le rapport affiche
   en plus un numéro court par nature (B-001 pour les bornes, P-001 pour les
   points, L-001 pour les lignes…), attribué dans l'ordre du cadastre (feuille,
   puis position d'ouest en est). Le numéro court ne vaut que pour un millésime,
   l'identifiant vaut au-delà.

5. **Le PCI reste un décor.** Rien n'entre dans la chaîne, et le rendu ne fait
   aucun appel réseau. La couche se passe à `sommier_rapport_quarto()` comme
   `fond`. Le millésime de chaque feuille est imprimé sous la carte.

## Livrables

* `SOMMIER_COUCHES_PCI` étendu à `TPOINT_id`, `TSURF_id`, `TRONFLUV_id`,
  `SYMBLIM_id`, `BATIMENT_id`, `TRONROUTE_id`, avec les couches `*_LABEL`
  correspondantes.
* `sommier_elements_pci(fond_pci, emprise, tampon_m = 20, sym = NULL)` : lit
  toutes les couches utiles, joint les étiquettes, sélectionne dans le tampon,
  calcule la situation, déduit la nature, numérote. Il renvoie un tableau WKT en
  Lambert-93 avec les colonnes `id`, `numero`, `feuille`, `objet`, `couche`,
  `sym`, `texte`, `nature`, `nature_source`, `situation`, `orientation`
  (`SYMBLIM`), `cree_le`, `modifie_le`, `millesime`.
* `sommier_exporter_elements_pci(elements, chemin)` : le même tableau en
  GeoPackage, pour le projet QField du lot « Limites ».
* Le paramètre `fond_pci` de `sommier_rapport_quarto()` accepte ce tableau.
  L'ancien format (bornes seules) reste accepté.
* Une section « Éléments du plan cadastral », après le récapitulatif du
  parcellaire :
  * **une carte** : le contour de la forêt en trait fort, le tampon de 20 m en
    tireté, les bornes numérotées, les autres éléments figurés selon leur nature,
    et ceux du tampon en teinte atténuée ;
  * **un en-tête** : « 118 éléments dans la forêt ou à moins de 20 m, dont
    68 bornes ; *n* dans la forêt, *m* dans le tampon » ;
  * **un tableau par nature** : numéro, nature (avec sa source), situation,
    feuille, identifiant, coordonnées Lambert-93 (le centroïde pour une ligne ou
    une surface), date de dernière modification au cadastre ;
  * **une note de source** : feuilles, millésimes, tampon, et la mention que
    le plan est la donnée d'un tiers.
* Les croix brunes disparaissent de la carte de la desserte, qui retrouve son
  objet.

## Critères d'acceptation

* Sur Loury, avec un tampon de 20 m, la section compte 118 éléments, dont
  68 bornes. Ce compte figure dans la NEWS.
* Le point `SYM` 50 s'affiche « pylone télécom (d'après le plan) », et les
  surfaces `SYM` 34 s'affichent « détail surfacique, code 34 ».
* Avec une table fournie par l'appelant, les libellés viennent de la table et
  sont marqués comme tels. Le texte du plan, quand il existe, prime sur elle.
* Aucun élément de `ID_S_OBJ_Z_1_2_2`, `PARCELLE` ou `LIEUDIT` n'apparaît.
* Un élément garde son identifiant d'un rendu à l'autre, et son numéro court
  sur un même millésime.
* Aucune donnée PCI n'entre dans la chaîne de hachage, et le rendu ne fait
  aucun appel réseau.
* La carte reste lisible en A4 avec 70 bornes : les numéros ne se chevauchent
  pas, et la carte se découpe en planches si l'emprise l'exige. Le seuil de
  découpage est à fixer sur Orléans.

## Question ouverte

* **La table `SYM`.** Il n'y a plus urgence, puisque le plan nomme une partie
  de ses éléments et que le reste s'affiche en code. On la cherche quand même
  dans la documentation DGFiP : les six surfaces `SYM` 34 de Loury méritent un
  nom.
