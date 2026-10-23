# Reprise d'un sommier de travaux tenu sous tableur

Transcrit au registre 6 les interventions d'un tableur (CSV ou XLSX) au
format de
[SOMMIER_COLONNES_TABLEUR_TRAVAUX](https://pobsteta.github.io/sommieR/reference/SOMMIER_COLONNES_TABLEUR_TRAVAUX.md)
: une ligne, une entree `travaux`, construite par
[`sommier_reprise()`](https://pobsteta.github.io/sommieR/reference/sommier_reprise.md)
et ecrite par
[`sommier_reprendre()`](https://pobsteta.github.io/sommieR/reference/sommier_reprendre.md).
Code et geometrie entrent quand le tableur les porte ; une intervention
sans code reste une intervention, rangee "non codee" au bilan.

## Usage

``` r
sommier_reprendre_travaux(
  con,
  foret_id,
  fichier,
  auteur,
  source,
  ndp = NULL,
  crs = 4326,
  feuille = 1L
)
```

## Arguments

- con:

  Connexion DBI.

- foret_id:

  UUID de la foret.

- fichier:

  Chemin du tableur : `.csv` (separateur `;`, `,` ou tabulation, UTF-8)
  ou `.xlsx` (paquet `readxl`).

- auteur:

  Compte qui transcrit.

- source:

  Piece dont la reprise est tiree
  ([`reprise_source()`](https://pobsteta.github.io/sommieR/reference/reprise_source.md)),
  obligatoire : d'ordinaire `tableur`, ou `base_gestionnaire` pour un
  extrait date d'une base tenue.

- ndp:

  NDP des entrees (\>= 1) ; par defaut, celui de la source.

- crs:

  CRS des WKT de la colonne `geometrie` (EPSG) ; WGS84 par defaut.

- feuille:

  Feuille a lire d'un `.xlsx` (numero ou nom).

## Value

Invisiblement, le compte rendu de
[`sommier_reprendre()`](https://pobsteta.github.io/sommieR/reference/sommier_reprendre.md),
qui compte aussi `deja_presents`, les lignes deja transcrites.

## Details

**Une transcription, pas un constat.** Chaque entree porte la piece dont
elle sort, sans valeur par defaut : un nom de fichier ne dit ni qui
tenait le tableur ni sur quelle periode. Elle porte aussi un NDP d'au
moins 1 (3 pour un `tableur`), et pour `date_saisie` l'instant de
l'import. La date de l'evenement est `date`, a defaut `date_reception`,
a defaut le 1er janvier de l'annee : un A50J ne donne souvent que
l'annee.

**L'unite de gestion** est celle dont le numero est en colonne `ug`, et
qui existait a la date de l'evenement. Sans numero, c'est celle qui
contient la geometrie ; sans l'une ni l'autre, l'intervention s'inscrit
a l'echelle de la foret (A50H), et `localisation` devrait le dire.

**La geometrie** est un WKT simple : `POINT`, `LINESTRING` ou `POLYGON`
sans trou, de la forme que le code admet. Les multi-geometries sont
refusees, faute d'etre admises au registre : une plantation en trois
placeaux s'ecrit en trois lignes. Lire une geometrie demande `sf`.

**Tout ou rien.** Chaque ligne est controlee avant toute ecriture :
colonnes connues, nombres et dates lisibles, code connu, unite du code,
motif d'un ecart au prevu, forme de la geometrie, unite de gestion
connue. Une faute fait refuser le fichier entier, avec la liste de
toutes, ligne par ligne (la ligne d'en-tete est la ligne 1).

**Rejouable.** L'identifiant d'une entree se deduit de son contenu
(foret, unite, date, payload) : reimporter le meme tableur n'ecrit rien
de plus, et un tableur complete n'ecrit que ses lignes nouvelles. Deux
lignes identiques sont refusees comme un doublon. Une ligne corrigee
dans le tableur entre comme une ligne nouvelle : la rectification d'une
entree deja transcrite se fait par `corrige_id`, pas par reimport.

Les nombres admettent la virgule decimale et les espaces de milliers ;
les valeurs fermees (`execution`, `prevu`) se lisent sans casse ni
accents (`Non prevu`, `Regie`, accentues ou non).

## See also

[SOMMIER_COLONNES_TABLEUR_TRAVAUX](https://pobsteta.github.io/sommieR/reference/SOMMIER_COLONNES_TABLEUR_TRAVAUX.md),
[`sommier_reprise()`](https://pobsteta.github.io/sommieR/reference/sommier_reprise.md),
[`sommier_provenance()`](https://pobsteta.github.io/sommieR/reference/sommier_provenance.md)

## Examples

``` r
if (FALSE) { # \dontrun{
sommier_reprendre_travaux(
  con, foret, "suivi_travaux.csv", auteur = "agent-01",
  source = reprise_source("tableur", "Suivi des travaux 2015-2025, CRPF")
)
} # }
```
