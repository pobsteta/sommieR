# Couche cartographique des unites de gestion

Rassemble
[`sommier_geometrie_ug()`](https://pobsteta.github.io/sommieR/reference/sommier_geometrie_ug.md)
et
[`sommier_indicateurs_ug()`](https://pobsteta.github.io/sommieR/reference/sommier_indicateurs_ug.md)
en une seule table, prete a etre portee sur une carte.

## Usage

``` r
sommier_couche_ug(con, foret_id, debut = NULL, fin = NULL, a_la_date = NULL)
```

## Arguments

- con:

  Connexion DBI.

- foret_id:

  UUID de la foret.

- debut, fin:

  Bornes de la periode (`NULL` : sans borne).

- a_la_date:

  Date de reference des contours (defaut : la borne `fin` si elle est
  donnee, sinon aujourd'hui). Ce defaut n'est pas cosmetique : une carte
  qui accompagne un bilan de periode doit montrer le parcellaire de la
  fin de cette periode, non celui du jour de l'edition.

## Value

Un `data.frame` des unites avec contour, joint de leurs indicateurs,
portant l'attribut `unites_sans_geometrie`.

## Details

Le resultat porte l'attribut `unites_sans_geometrie` : les numeros
d'affichage des unites actives dont le contour est inconnu. Les cartes
du rapport s'en servent pour le dire au lecteur — une foret
partiellement cartographiee doit se declarer telle, sans quoi la carte
laisse croire qu'elle montre tout.

## Examples

``` r
# Necessite une connexion :
# sommier_couche_ug(con, foret, "2016-01-01", "2025-12-31")
```
