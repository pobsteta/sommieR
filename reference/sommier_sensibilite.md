# Referentiel de sensibilite des especes (SINP)

Lit le referentiel national de sensibilite de l'INPN - le fichier
`RefSensibilite_<version>.csv` de l'archive `SENSIBILITE.zip` - pour
flouter, dans un sommier a transmettre, la localisation des especes
sensibles (voir
[`sommier_registre_quarto()`](https://pobsteta.github.io/sommieR/reference/sommier_registre_quarto.md)).

## Usage

``` r
sommier_sensibilite(chemin)
```

## Arguments

- chemin:

  Le fichier `RefSensibilite_<version>.csv`, ou l'archive
  `SENSIBILITE.zip` qui le contient.

## Value

Un `data.frame` aux colonnes en minuscules, portant les attributs
`version`, `empreinte` (SHA-256 du CSV) et `fichier`.

## Details

**Le fichier n'est pas dans le paquet.** Sa licence n'est pas connue :
on le telecharge soi-meme depuis l'INPN
(`https://assets.patrinat.fr/files/referentiel/SENSIBILITE.zip`) et on
passe ici le CSV, ou l'archive entiere. Ce qui en est lu est date et
empreint : la version (tiree du nom du fichier) et le SHA-256 du CSV
sont portes en attributs, et le document qui en use les cite.

Chaque ligne donne, pour un taxon (`cd_nom`, `cd_ref`) et un departement
(`cd_dept`), un code de sensibilite de 1 a 3, sa duree en annees depuis
l'observation (`duree`), les conditions qui la restreignent
(`statut_biologique`, `comportement`, `autre`) et la liste regionale
dont elle vient (`cd_sens_mtd`).

## See also

[`sommier_registre_quarto()`](https://pobsteta.github.io/sommieR/reference/sommier_registre_quarto.md)

## Examples

``` r
# Le fichier se telecharge depuis l'INPN :
# ref <- sommier_sensibilite("SENSIBILITE.zip")
# attr(ref, "version")
```
