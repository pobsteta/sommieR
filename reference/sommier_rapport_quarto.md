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
