# Rapport de gestion anterieure en Quarto

Rend la gestion anterieure sous forme de document Quarto — HTML
autoportant ou PDF — en y joignant l'etat de la chaine, la balance de
possibilite, les elements d'IBP et la desserte.

## Usage

``` r
sommier_rapport_quarto(
  con,
  foret_id,
  chemin,
  format = "html",
  debut = NULL,
  fin = NULL,
  referentiel = "psg",
  fond = NULL,
  fond_pci = NULL,
  photos = NULL,
  public = FALSE,
  indices = NULL,
  reference_ifn = NULL,
  coupes_detectees = NULL,
  quarto = Sys.which("quarto")
)
```

## Arguments

- con:

  Connexion DBI.

- foret_id:

  UUID de la foret.

- chemin:

  Fichier de destination. Son extension doit s'accorder avec `format`.

- format:

  `"html"` ou `"pdf"`.

- debut, fin:

  Bornes de la periode (voir
  [`sommier_gestion_anterieure()`](https://pobsteta.github.io/sommieR/reference/sommier_gestion_anterieure.md)).

- referentiel:

  L'un de
  [SOMMIER_REFERENTIELS](https://pobsteta.github.io/sommieR/reference/SOMMIER_REFERENTIELS.md).

- fond:

  Fond cadastral a poser sous les cartes, tel que le rend
  [`sommier_fond_lire()`](https://pobsteta.github.io/sommieR/reference/sommier_fond_lire.md)
  ; `NULL` pour s'en passer. Il se fournit et ne se telecharge pas : le
  rendu ne doit declencher aucun appel reseau, sans quoi un rapport
  cesserait d'etre editable hors ligne - et le meme rapport rejoue plus
  tard changerait de fond sans le dire. C'est aussi lui qui donne les
  tenements du recapitulatif du parcellaire - la part de chaque parcelle
  cadastrale comprise dans une unite : sans fond, le recapitulatif ne
  liste que les unites.

- fond_pci:

  Le PCI vecteur, sous l'une de deux formes. Les elements du plan que
  rend
  [`sommier_elements_pci()`](https://pobsteta.github.io/sommieR/reference/sommier_elements_pci.md) -
  bornes, details, cours d'eau, voies, dans la foret et a ses abords -
  recoivent leur propre section, avec une carte et un tableau par
  categorie. Les bornes seules, telles que les rend
  [`sommier_fond_pci_lire()`](https://pobsteta.github.io/sommieR/reference/sommier_fond_pci_lire.md),
  se posent en croix sur la carte de la desserte. `NULL` pour s'en
  passer. Meme regle que `fond` : fourni, jamais telecharge au rendu.

- photos:

  Depot des photos des constats de terrain - reconnaissances de limite
  et suites des detections (voir
  [`sommier_deposer_photo()`](https://pobsteta.github.io/sommieR/reference/sommier_deposer_photo.md))
  ; `NULL` pour s'en passer. Fourni, jamais telecharge. Les vignettes de
  la planche photographique sont reduites au rendu ; une photo dont
  l'empreinte ne tient plus n'est pas montree.

- public:

  `TRUE` pour un document a diffuser : la planche photographique est
  retiree, le tableau garde le nombre de photos, et le document dit
  qu'elles existent. Une photo peut montrer un riverain ou une plaque
  d'immatriculation.

- indices:

  Indices de nemeton par unite, tels que les rend
  [`sommier_lire_indices_nemeton()`](https://pobsteta.github.io/sommieR/reference/sommier_lire_indices_nemeton.md)
  (facultatif) : un encadre « Ce que la foret porte » donne le volume
  sur pied et la possibilite rapportee au capital. Des estimations, hors
  chaine, presentees comme telles.

- reference_ifn:

  Prelevement de reference de l'IFN, pour situer la possibilite et le
  preleve (facultatif) : liste nommee portant `taux_m3_ha_an`, et
  facultativement `ser`, `nom`, `millesime`, `source`.
  [`sommier_reference_ifn()`](https://pobsteta.github.io/sommieR/reference/sommier_reference_ifn.md)
  la rend toute faite, depuis la sylvoecoregion de la foret et les
  tables IFN de nemeton.

- coupes_detectees:

  Coupes rases detectees, telles que les rend
  [`sommier_coupes_sufosat()`](https://pobsteta.github.io/sommieR/reference/sommier_coupes_sufosat.md)
  (facultatif) : celles qu'aucun martelage de la meme unite n'explique,
  l'exercice de la detection ou le precedent, sont signalees sous la
  balance.

- quarto:

  Chemin de l'executable Quarto.

## Value

Invisiblement, le chemin du document produit.

## Details

Les cartes sont portees par la meme extraction : les contours des unites
de gestion et leurs indicateurs voyagent en WKT dans le RDS, et le
document les convertit en `sf` au rendu. Le RDS n'exige donc pas `sf`
pour etre relu.

Les donnees sont extraites de la base **avant** le rendu et deposees
dans un fichier RDS que le document lit. Deux consequences voulues :
aucun identifiant de connexion ne circule dans le document ou ses
parametres, et le rendu est reproductible a l'identique sans acces a la
base — on peut rejouer un rapport des mois plus tard sur le meme
instantane.

Le document porte l'empreinte de tete et l'etat de la chaine au moment
de l'edition. C'est une mise en forme, pas la preuve : la valeur
probante reste dans le registre, et
[`sommier_exporter_manifeste()`](https://pobsteta.github.io/sommieR/reference/sommier_exporter_manifeste.md)
est ce qui la transporte. Le rapport le dit explicitement a son lecteur
plutot que de laisser croire qu'un PDF vaut attestation.

Quarto doit etre installe et joignable dans le `PATH` ; le rendu PDF
exige en outre une distribution LaTeX (`quarto install tinytex` suffit).

## See also

[`sommier_gestion_anterieure()`](https://pobsteta.github.io/sommieR/reference/sommier_gestion_anterieure.md),
[`sommier_rapport_markdown()`](https://pobsteta.github.io/sommieR/reference/sommier_rapport_markdown.md)

## Examples

``` r
# Necessite une connexion et Quarto :
# sommier_rapport_quarto(con, foret, "gestion-anterieure.html")
```
