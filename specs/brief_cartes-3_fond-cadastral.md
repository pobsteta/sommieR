# Brief — Lot 3 : le fond cadastral

*Établi le 19 août 2026. Indépendant des lots 1 et 2, mais sans intérêt avant
le lot 1.*

## Pourquoi

Une carte de la forêt seule flotte : le lecteur ne sait pas où elle se situe,
ni comment ses unités de gestion se rapportent au parcellaire. Le fond
cadastral donne ce repère, et il est le seul référentiel que le propriétaire,
le notaire, la commune et le CRPF lisent tous.

## La règle qui commande tout le reste

**Le cadastre n'est pas une écriture du sommier.** L'y verser ferait passer la
donnée d'un tiers pour un constat du gestionnaire — exactement ce que le
registre existe pour empêcher. Sa place est celle d'un fond de plan : affiché,
daté, sourcé, et jamais chaîné.

En pratique : aucune entrée de registre, aucune empreinte, aucun stockage dans
`entree_sommier`. Une table de cache, éventuellement, dont la perte n'affecte
rien.

## À vérifier avant de bâtir

L'énoncé initial supposait que le cadastre porte les bornes et les fossés.
C'est vrai de sa forme vectorielle riche (EDIGEO/PCI, qui contient des objets
topographiques ponctuels et linéaires), **mais il reste à établir** ce que les
exports publics couramment disponibles exposent réellement — les livraisons
GeoJSON d'Etalab paraissent se limiter aux parcelles, sections, bâtiments et
lieux-dits.

C'est la première tâche du lot, et son résultat peut en changer le périmètre :
si les objets topographiques ne sont pas disponibles publiquement, les bornes
et les fossés relèvent du lot 2 — c'est-à-dire du constat du gestionnaire — et
non d'un fond tiers.

## Périmètre envisagé

* Parcelles cadastrales intersectant l'emprise de la forêt, avec leur
  référence.
* Sections, en étiquetage.
* Bâtiments, s'ils intersectent.
* Le cas échéant, objets topographiques — sous réserve de la vérification
  ci-dessus.

## Décisions de conception

1. **Téléchargement explicite, jamais implicite.** Une fonction dédiée va
   chercher les données ; ni le rapport ni un export ne déclenchent d'appel
   réseau à l'insu de l'utilisateur. Un document de gestion doit pouvoir
   s'engendrer sur un poste sans internet.

2. **Cache local daté.** Ce qui est téléchargé est conservé avec sa date de
   millésime et sa source ; le rapport affiche l'une et l'autre sous la carte.
   Un fond sans millésime induit en erreur dès l'année suivante.

3. **Emprise, pas commune entière.** On récupère ce qui intersecte la forêt
   tamponnée, non tout le territoire communal : le volume et la lisibilité y
   gagnent.

4. **Dégradation propre.** Fond absent, réseau coupé, cache vide : la carte se
   dessine sans fond, avec la mention correspondante.

## Livrables

* Vérification documentée des sources publiques et de leur contenu réel.
* Fonction de récupération et de mise en cache, à emprise donnée.
* Intégration au chapitre 1 du rapport, en fond des unités de gestion.
* Mention de source et de millésime sous chaque carte qui en porte un.

## Critères d'acceptation

* Le rapport s'engendre à l'identique sans réseau.
* Le fond affiché porte toujours sa source et son millésime.
* Aucune donnée cadastrale n'entre dans la chaîne de hachage.
