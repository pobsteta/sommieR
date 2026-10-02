# Sommier imprime en Quarto

Rend le sommier ecriture par ecriture - le document "Sommier de la
foret" - en HTML autoportant ou en PDF : la fiche A10 de tenue, puis
chaque registre dans l'ordre de la chaine, et en annexe les empreintes
completes.

## Usage

``` r
sommier_registre_quarto(
  con,
  foret_id,
  chemin,
  format = "html",
  registres = 1:9,
  jusqu_au_visa = NULL,
  public = FALSE,
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

- registres:

  Registres a extraire (1 a 9).

- jusqu_au_visa:

  Exercice dont le visa arrete l'edition ; `NULL` pour tout le sommier.

- public:

  `TRUE` pour un sommier a transmettre : les tiers des registres 3 et 7
  sont masques.

- quarto:

  Chemin de l'executable Quarto.

## Value

Invisiblement, le chemin du document produit.

## Details

Meme mecanique que
[`sommier_rapport_quarto()`](https://pobsteta.github.io/sommieR/reference/sommier_rapport_quarto.md)
: l'extraction
([`sommier_registre()`](https://pobsteta.github.io/sommieR/reference/sommier_registre.md))
est deposee dans un RDS que le gabarit lit, et le rendu ne touche pas la
base. Le document n'est pas la preuve : la valeur probante reste dans la
chaine, que
[`sommier_exporter_manifeste()`](https://pobsteta.github.io/sommieR/reference/sommier_exporter_manifeste.md)
transporte, et le document le dit.

Un sommier a transmettre hors du gestionnaire se rend avec
`public = TRUE` : les noms de tiers des registres 3 et 7 (titulaires,
garants, tiers d'une ecriture) sont remplaces par "(masque)". La ligne,
son montant et son empreinte restent : on voit qu'une ecriture existe,
pas qui elle nomme. Les photos des constats ne sont jamais reproduites,
seulement comptees.

## See also

[`sommier_registre()`](https://pobsteta.github.io/sommieR/reference/sommier_registre.md),
[`sommier_rapport_quarto()`](https://pobsteta.github.io/sommieR/reference/sommier_rapport_quarto.md)
