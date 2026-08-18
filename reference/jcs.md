# Serialisation JSON canonique (RFC 8785, JCS)

`jcs()` produit la representation canonique JCS d'une valeur R. C'est la
brique de base du chainage de hachages du sommier : deux representations
d'un meme payload doivent produire des octets strictement identiques,
sinon la chaine n'est pas verifiable par un tiers.

Le JSONB restitue par PostgreSQL ne convient pas (il reordonne les cles
et normalise les nombres) : conformement au brief, le hachage est
calcule cote R et la base ne fait que stocker et contraindre.

## Usage

``` r
jcs(x)
```

## Arguments

- x:

  Valeur R a serialiser.

## Value

Une chaine de caracteres de longueur 1, en UTF-8.

## Details

Regles appliquees (RFC 8785 sections 3.2.2 a 3.2.4) :

- **Objets** : cles triees par ordre des unites de code UTF-16, aucun
  espace, `"cle":valeur`.

- **Tableaux** : ordre d'origine preserve.

- **Chaines** : echappement minimal RFC 8259 (`\"`, `\\`, `\b`, `\f`,
  `\n`, `\r`, `\t`), autres caracteres de controle en `\u00xx`
  minuscule, tout le reste litteral en UTF-8.

- **Nombres** : algorithme ECMAScript `Number::toString` (voir
  [`jcs_nombre()`](https://pobsteta.github.io/sommieR/reference/jcs_nombre.md)).
  `NaN` et les infinis sont refuses, JSON ne les representant pas.

- **Litteraux** : `true`, `false`, `null`.

Correspondance R -\> JSON :

|  |  |
|----|----|
| Valeur R | JSON |
| `NULL` | `null` |
| liste nommee | objet |
| liste non nommee | tableau |
| `structure(list(), names = character(0))` | [`{}`](https://rdrr.io/r/base/Paren.html) |
| [`list()`](https://rdrr.io/r/base/list.html) | `[]` |
| atomique de longueur 1 | scalaire |
| atomique de longueur != 1 | tableau |
| atomique de longueur 1 dans [`I()`](https://rdrr.io/r/base/AsIs.html) | tableau a 1 element |
| `NA` | erreur (ambigu) |

Ces conventions sont celles de `jsonlite::toJSON(auto_unbox = TRUE)`, a
ceci pres que `NA` est refuse : `null` et "valeur manquante" ne sont pas
interchangeables dans un registre a valeur probante, il faut ecrire
`NULL` explicitement.

## See also

[`jcs_nombre()`](https://pobsteta.github.io/sommieR/reference/jcs_nombre.md),
[`sommier_empreinte()`](https://pobsteta.github.io/sommieR/reference/sommier_empreinte.md)

## Examples

``` r
jcs(list(b = 1, a = "x"))
#> [1] "{\"a\":\"x\",\"b\":1}"
#> {"a":"x","b":1}
jcs(list(volume_m3 = 12.5, essence = "HET"))
#> [1] "{\"essence\":\"HET\",\"volume_m3\":12.5}"
```
