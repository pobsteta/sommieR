# Elements du sommier utiles a l'IBP

Rassemble ce que le registre 9 peut fournir a l'Indice de Biodiversite
Potentielle : arbres porteurs de microhabitats, bois mort sur pied, tres
gros bois vivants, milieux ouverts, especes protegees.

## Usage

``` r
sommier_elements_ibp(con, foret_id, seuil_tgb_cm = SOMMIER_SEUIL_TGB_CM)
```

## Arguments

- con:

  Connexion DBI.

- foret_id:

  UUID de la foret.

- seuil_tgb_cm:

  Seuil de circonference des tres gros bois, en centimetres (defaut
  [SOMMIER_SEUIL_TGB_CM](https://pobsteta.github.io/sommieR/reference/SOMMIER_SEUIL_TGB_CM.md)).

## Value

Un `data.frame` : `facteur_ibp`, `element`, `valeur`, `unite`,
`n_entrees`.

## Details

**Cette fonction ne cote pas l'IBP, et ne le pretend pas.** L'IBP se
releve sur le terrain selon son protocole, sur des placettes et avec des
classes de notation qui ne se deduisent pas d'un registre. Ce que le
sommier apporte, ce sont des elements deja constates et dates - des
arbres remarquables identifies, des habitats mesures - qui alimentent
les facteurs correspondants sans s'y substituer.

Rendre une note serait plus vendeur et faux : un facteur IBP se cote par
densite a l'hectare sur placette, pas par comptage d'un registre qui
n'inventorie que le remarquable.

## Examples

``` r
# Necessite une connexion :
# sommier_elements_ibp(con, foret)
```
