# Brief — Patrimoine, lot 1 : les espèces observées dans la forêt et à ses abords, rapportées à TAXREF

*Établi le 2 octobre 2026, à partir du sommier de la forêt domaniale d'Orléans
et d'un jeu fictif dans sa base de test.*

## Pourquoi ce lot existe

Le registre 9 n'inventorie que le remarquable, et seulement ce que le
gestionnaire a relevé lui-même : un arbre, un peuplement, un vestige, une
espèce qu'il a vue. Il ne dit rien de ce que d'autres ont observé dans la
forêt — ornithologues, botanistes, inventaires nationaux, naturalistes de la
DREAL. Ces observations existent, publiées en données ouvertes, et elles
intéressent la gestion : une espèce protégée nichant dans une unité change la
façon d'y marteler ou d'y conduire des travaux.

Ce lot rapporte ces observations au rapport, comme un contexte, et les nomme
dans **TAXREF, le référentiel taxonomique national, qui fait référence** : une
espèce s'y identifie par son `CD_NOM`, et son nom valide par son `CD_REF`.

## Ce que la vérification a établi

- **Les observations existent, en nombre.** Dans un rectangle d'environ
  3 × 3 km autour de la forêt d'Orléans (2,12–2,16° E, 48,00–48,03° N), GBIF
  compte, le 2 octobre 2026, **1 287 observations de 178 espèces**, toutes des
  observations humaines. Elles viennent surtout du STOC-EPS (1 023), des
  relevés floristiques de l'inventaire forestier national de l'IGN (143) et de
  la base faune de la DREAL Centre-Val de Loire (34).
- **OpenObs, le portail national du SINP, est hors service.** Le Muséum
  national d'Histoire naturelle a subi une cyberattaque à l'été 2025 : l'INPN
  affiche « Services temporairement interrompus », l'API d'OpenObs
  (`/api/docs`, `/developer`) et son portail de recherche (`openobs-hub`)
  répondent 404. L'API TAXREF (`taxref.mnhn.fr/api`) redirige vers la page de
  l'INPN. Les téléchargements officiels de TAXREF et de la BDC Statuts, que
  data.gouv.fr renvoie vers l'INPN, sont donc inaccessibles.
- **TAXREF reste disponible, par GBIF France.** PatriNat publie TAXREF sur
  l'IPT de GBIF France (`ipt.gbif.fr`, ressource `taxref`, jeu GBIF
  `0e61f8fe-7d25-4f81-ada7-d970bbb2c6d6`, CC BY 4.0). L'archive Darwin Core
  du 10 mars 2025 porte **TAXREF v18.0** : `taxon.txt` (188 Mo) et
  `vernacularname.txt`, 32 Mo compressée. Le `taxonID` y est le `CD_NOM` :
  *Dendrocopos medius* y porte 3619, son synonyme *Dendrocoptes medius*
  1046450.
- **Cette archive ne porte pas les statuts.** Ni protection, ni liste rouge,
  ni directive : la BDC Statuts est une base distincte, publiée par l'INPN.
- **GBIF ne nomme pas en TAXREF.** Une occurrence GBIF est rattachée à la
  taxonomie de GBIF (`speciesKey`) ; le rapprochement avec TAXREF est à faire.
  OpenObs, lui, nomme nativement en TAXREF.
- **Les paquets R existent.** `rgbif` (CRAN) interroge GBIF. `galah` (CRAN,
  2.3.0) interroge les Living Atlases, dont OpenObs pour la France depuis la
  1.5.1. `rtaxref` (GitHub) interroge l'API TAXREF, aujourd'hui coupée. Aucun
  n'est installé, ni utilisé par sommieR ou nemeton.

## Décisions de conception

1. **TAXREF fait référence.** Toute espèce que le rapport nomme porte son
   `CD_NOM` et son `CD_REF`, son nom valide et son nom vernaculaire TAXREF, et
   la version de TAXREF utilisée est citée. Les observations se comptent par
   `CD_REF` : deux synonymes sont une espèce. Un nom de la source qu'on ne
   rapproche pas de TAXREF sans ambiguïté est montré comme tel, « non
   rapproché », et n'est pas deviné.

2. **TAXREF se lit dans un fichier, pas dans une API.** `sommier_taxref()`
   télécharge une fois l'archive Darwin Core et la garde en cache, avec sa
   version, comme le PCI ou la couche des SER. Le rapport ne déclenche aucun
   appel réseau : il reçoit ce qu'on lui fournit. Le rapport ne dépend donc
   pas de l'état des serveurs du Muséum. La source de l'archive (GBIF France
   aujourd'hui, l'INPN quand il reviendra) est un paramètre, et la version lue
   dans l'archive, pas dans l'adresse.

3. **Les observations sont un contexte, hors de la chaîne.** Une observation
   d'un tiers n'est pas un constat : elle n'entre pas au registre 9, ni comme
   fiche, ni comme détection en attente. Elle est présentée comme la référence
   IFN ou les indices de nemeton : sourcée, datée, dite estimation de
   contexte. Ce que le registre 9 inventorie, et ce que l'IBP en tire, ne
   change pas.

4. **La source des observations est interchangeable.** GBIF d'abord, par
   `rgbif`, parce qu'il répond et qu'il agrège déjà une partie du SINP.
   OpenObs ensuite, par `galah`, quand le Muséum l'aura rétabli : il nomme en
   TAXREF et porte des données que GBIF n'a pas. La fonction et son résultat
   ne changent pas d'une source à l'autre ; le résultat dit d'où il vient.

5. **L'extraction est explicite, datée et citée.** `sommier_especes_observees()`
   interroge la source sur l'emprise de la forêt élargie d'un tampon, filtre,
   rapproche de TAXREF et rend une table par espèce. Elle garde la date
   d'extraction, les jeux de données sources et leur licence, que le rapport
   cite. Les données GBIF sont sous CC0, CC BY ou CC BY-NC selon le jeu : la
   citation n'est pas facultative.

6. **Les filtres sont des paramètres, avec des défauts prudents.** Tampon
   autour de la forêt, date minimale d'observation, incertitude maximale de la
   position, observations présentes seulement (pas les absences). Une
   occurrence dont la position est floutée au-delà du seuil — c'est le cas des
   espèces sensibles dans le SINP — n'est pas placée dans une unité.

7. **Une position d'espèce sensible ne se publie pas.** Le rapport liste les
   espèces, il ne cartographie pas leurs observations. À `public = TRUE`, les
   observations d'une espèce dont le statut le demande restent comptées, sans
   unité de gestion.

8. **Les statuts viennent de la BDC Statuts, rapportée par `CD_REF`.**
   Protection nationale et régionale, listes rouges, annexes des directives
   Habitats et Oiseaux. Comme TAXREF, elle se lit dans un fichier en cache, sa
   version citée. Tant qu'aucune source ne la fournit, le rapport le dit et
   liste les espèces sans statut, plutôt que d'en inventer un.

## Livrables

**Lot 1 : TAXREF et les espèces observées**

- `sommier_taxref(cache = NULL, source = <archive GBIF France>, force = FALSE)`
  télécharge l'archive TAXREF, la garde en cache, et rend la table des taxons
  (`cd_nom`, `cd_ref`, rang, nom scientifique, auteur, nom valide, nom
  vernaculaire, règne, groupe) avec `attr(, "version")`.
- `sommier_especes_observees(emprise, taxref, source = "gbif",
  tampon_m = 500, depuis = 2000, incertitude_max_m = 100, cache = NULL)`
  rend une ligne par `CD_REF` : nom valide, nom vernaculaire, groupe, nombre
  d'observations, première et dernière année, unités de gestion où elles
  tombent, jeux de données sources. Attributs : source, date d'extraction,
  paramètres, citation des jeux, nombre d'observations non rapprochées de
  TAXREF.
- Rapprochement GBIF → TAXREF : par le nom scientifique canonique et le rang,
  contre le nom valide puis les synonymes de TAXREF ; un nom à plusieurs
  correspondances reste non rapproché.
- `sommier_rapport_quarto(especes_observees = NULL)` : une sous-section
  « Espèces observées dans la forêt et à ses abords (hors registre) » sous le
  patrimoine remarquable. Un encadré dit la source, la date, les filtres et la
  version de TAXREF ; un tableau par groupe (oiseaux, plantes, mammifères…) ;
  la liste des espèces observées qui ont aussi une fiche au registre 9.
- `rgbif` en Suggests, comme `nemeton` ou `arrow`.

**Lot 2 : les statuts**

- `sommier_statuts_taxref()` : la BDC Statuts en cache, filtrée sur la région
  de la forêt (Centre-Val de Loire pour Orléans), rapportée par `CD_REF`.
- Le tableau des espèces observées gagne leurs statuts ; le rapport met en
  tête les espèces protégées observées dans une unité de gestion, et celles
  qui n'ont pas de fiche au registre 9 : ce sont celles que le gestionnaire
  pourrait vouloir aller voir.
- `registre9_espece()` gagne un `cd_nom` facultatif, contrôlé contre TAXREF :
  le registre nomme lui aussi en TAXREF, et une fiche se rapproche des
  observations sans passer par le nom. Le schéma du registre 9 change de
  version ; les fiches antérieures, sans `cd_nom`, restent valides.

**Lot 3 : OpenObs**

- `source = "openobs"` dans `sommier_especes_observees()`, par `galah`, dès
  que le portail répond. Les observations y portent leur `CD_NOM` : pas de
  rapprochement à faire.

## Critères d'acceptation

- Sur la forêt d'Orléans, `sommier_especes_observees()` rend une table dont
  chaque ligne porte un `CD_REF` de TAXREF v18.0, et dit combien
  d'observations n'ont pas été rapprochées.
- Deux observations d'une espèce sous deux synonymes comptent pour une seule
  espèce.
- Le rapport rendu sans réseau, avec la table fournie, montre la section, sa
  source, sa date d'extraction et la version de TAXREF ; rendu sans la table,
  il n'en dit rien.
- Aucune observation n'entre dans la chaîne : `sommier_verifier()` rend la
  même tête avant et après.
- À `public = TRUE`, aucune observation d'une espèce sensible n'est rattachée
  à une unité de gestion.
- Les tests tournent sans réseau, sur une archive TAXREF et une réponse GBIF
  réduites, enregistrées dans `tests/testthat/fixtures`.

## Questions ouvertes

- **Où trouver la BDC Statuts tant que l'INPN est coupé ?** data.gouv.fr ne
  renvoie que vers l'INPN. À chercher : une copie publiée par PatriNat
  ailleurs, ou attendre le rétablissement. Le lot 2 en dépend.
- **`occ_search()` ou `occ_download()` ?** La recherche simple est immédiate
  mais plafonnée et sans DOI ; le téléchargement donne un DOI citable, mais
  demande un compte GBIF. À trancher selon l'usage : un rapport diffusé
  devrait citer un DOI.
- **Les défauts des filtres.** 500 m de tampon, observations depuis 2000,
  100 m d'incertitude : à confirmer avec le gestionnaire.
- **sommieR ou nemeton ?** nemeton gère déjà les couches écologiques et leur
  cache. L'acquisition pourrait y vivre, sommieR ne faisant que lire, comme
  pour les indices. Ce brief la place dans sommieR, à côté de
  `sommier_reference_ifn()`, faute d'avoir vu nemeton s'en charger.
