# Elements du plan cadastral dans la foret et a ses abords

Rassemble tous les elements physiques du PCI vecteur - bornes, signes de
limite, details topographiques, cours d'eau, voies, batiments - qui
touchent la foret elargie de `tampon_m` metres, les situe, cite le texte
que le plan leur attache, et les numerote.

## Usage

``` r
sommier_elements_pci(fond, emprise, tampon_m = 20, symboles = NULL)
```

## Arguments

- fond:

  Objet `sommier_fond_pci`
  ([`sommier_fond_pci()`](https://pobsteta.github.io/sommieR/reference/sommier_fond_pci.md)).

- emprise:

  Couche des unites de gestion
  ([`sommier_couche_ug()`](https://pobsteta.github.io/sommieR/reference/sommier_couche_ug.md)),
  ou `data.frame` a colonne `wkt` en Lambert-93. Obligatoire : sans
  contour, ni le tampon ni la situation n'ont de sens.

- tampon_m:

  Largeur du tampon autour de la foret, en metres.

- symboles:

  Vecteur nomme donnant la nature d'un code `SYM` des details, par
  exemple `c("21" = "mur")`. Il vous appartient : le paquet n'en
  embarque aucun tant qu'une source n'est pas citable.

## Value

Un `data.frame` : `id`, `numero`, `categorie`, `couche`, `feuille`,
`objet`, `sym`, `texte`, `texte_morcele`, `nature`, `nature_source`,
`situation`, `distance_limite_m`, `orientation`, `cree_le`,
`modifie_le`, `millesime`, `echelle` (echelle d'origine du plan de la
feuille, lue dans `EOR`), `x`, `y` (point d'ancrage en Lambert-93) et
`wkt`. Attributs `tampon_m` et `source`.

## Details

**La selection se fait au tampon, sans autre filtre.** Est retenu tout
element qui touche l'union des contours des unites, elargie de
`tampon_m`. Le tampon capte les bornes et les murs de la limite, que
deux dessins superposent rarement au metre, et les elements du riverain
immediat.

**La situation se calcule, elle ne s'enregistre pas.** `situation` vaut
`"foret"` si l'element touche l'union des unites, `"tampon"` sinon, et
`distance_limite_m` donne sa distance au contour de cette union. C'est
une lecture du plan, comme les tenements du rapport. La distance compte
plus que la situation : une borne posee sur la limite cadastrale tombe
souvent a quelques metres hors d'unites dessinees a une autre main.

**La nature vient de la couche ou d'une table fournie, jamais du
texte.** Pour une borne, un cours d'eau, une voie ou un batiment, la
couche suffit a dire ce qu'est l'objet (`nature_source = "couche"`).
Pour un detail ponctuel, lineaire ou surfacique, seul le code `SYM` le
distingue, et sa nomenclature n'est pas dans l'archive : la table
`symboles` fournie par l'appelant le nomme (`"appelant"`), sinon
`nature` reste `NA`.

**Le texte du plan est cite, pas interprete.** `TEX` sur l'objet, ou une
etiquette des couches `*_LABEL` rattachee par `OGR_OBJ_LNK`, rend
`texte`. Il nomme parfois l'objet (« pylone telecom » sur un detail
ponctuel de Loury), et parfois seulement ce qui l'entoure : sur Couchey,
les lignes de code 19 portent « COMMUNE DE FLAVIGNEROT », le nom de la
commune voisine le long de la limite. En faire une nature ferait dire au
document qu'une ligne est une commune. Le texte reste donc a cote de la
nature, cite tel quel.

**Un nom morcele n'est pas recompose.** Le plan pose le nom d'une voie
mot par mot le long du trace, et l'ordre de ses attributs `TEX`,
`TEX2`... n'est pas celui de la lecture. `texte` reste alors `NA` et
`texte_morcele` vaut `TRUE` : recomposer serait inventer l'ordre.

**Chaque element a un identifiant stable** : `feuille:OBJECT_RID`. Le
numero court (`B-001`, `P-001`...) suit l'ordre du cadastre - feuille,
puis position d'ouest en est et du sud au nord - et ne vaut que pour un
millesime ; l'identifiant vaut au-dela.

Le PCI reste un decor : rien de ce qui est rendu ici n'entre dans un
registre, une empreinte ou un manifeste.

## See also

[`sommier_exporter_elements_pci()`](https://pobsteta.github.io/sommieR/reference/sommier_exporter_elements_pci.md),
[`sommier_rapport_quarto()`](https://pobsteta.github.io/sommieR/reference/sommier_rapport_quarto.md)

## Examples

``` r
# Necessite `sf`, un acces reseau et une connexion :
# ug <- sommier_couche_ug(con, foret)
# feuilles <- sommier_feuilles_pci("45188", emprise = ug)
# fond <- sommier_fond_pci("45188", feuilles$feuille)
# elements <- sommier_elements_pci(fond, ug)
```
