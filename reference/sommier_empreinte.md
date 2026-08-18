# Empreinte d'une entree de sommier

`hash_n = SHA-256( JCS(enregistrement_n) || hash_{n-1} )`, ou
`enregistrement_n` est produit par
[`sommier_enregistrement_canonique()`](https://pobsteta.github.io/sommieR/reference/sommier_enregistrement_canonique.md)
et `||` designe la concatenation des octets.

## Usage

``` r
sommier_empreinte(entree, hash_prev)
```

## Arguments

- entree:

  Liste nommee decrivant l'entree.

- hash_prev:

  Vecteur `raw` de 32 octets : l'empreinte de l'entree precedente, ou
  [`sommier_empreinte_genese()`](https://pobsteta.github.io/sommieR/reference/sommier_empreinte_genese.md)
  pour la premiere.

## Value

Un vecteur `raw` de 32 octets.

## See also

[`sommier_verifier_chaine()`](https://pobsteta.github.io/sommieR/reference/sommier_verifier_chaine.md)
