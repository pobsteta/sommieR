# Serialisation d'un nombre selon ECMAScript `Number::toString`

RFC 8785 renvoie a l'algorithme ECMAScript : la representation decimale
la plus courte qui se relit exactement en IEEE 754 double precision,
avec bascule en notation exponentielle en dehors de la plage `1e-7` ..
`1e21`.

## Usage

``` r
jcs_nombre(m)
```

## Arguments

- m:

  Nombre fini de longueur 1.

## Value

Une chaine de caracteres.

## Details

Soient `n`, `k` et `s` les entiers tels que `k >= 1`,
`10^(k-1) <= s < 10^k`, `s * 10^(n-k) == m`, et `k` minimal. Alors :

- `k <= n <= 21` : chiffres de `s` suivis de `n - k` zeros ;

- `0 < n <= 21` : chiffres de `s` avec un point apres `n` chiffres ;

- `-6 < n <= 0` : `"0."`, `-n` zeros, puis les chiffres de `s` ;

- sinon : notation exponentielle sur `n - 1`.

`k` minimal est obtenu en augmentant le nombre de chiffres significatifs
jusqu'a ce que la relecture redonne la valeur d'origine au bit pres.

## Examples

``` r
jcs_nombre(1)       # "1"
#> [1] "1"
jcs_nombre(1e21)    # "1e+21"
#> [1] "1e+21"
jcs_nombre(1e-7)    # "1e-7"
#> [1] "1e-7"
jcs_nombre(0.1)     # "0.1"
#> [1] "0.1"
```
