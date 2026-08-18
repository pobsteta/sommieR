# Payload du registre 9 - vestige ou element culturel (imprime A50 r/c)

Payload du registre 9 - vestige ou element culturel (imprime A50 r/c)

## Usage

``` r
registre9_vestige(
  appellation,
  nature,
  remarques,
  travaux_effectues = NULL,
  bibliographie = NULL,
  observations = NULL
)
```

## Arguments

- appellation:

  Nom du vestige.

- nature:

  Nature : charbonniere, muret, borne armoriee, vestige archeologique.

- remarques:

  Description et interet.

- travaux_effectues:

  Travaux de degagement ou de conservation (facultatif).

- bibliographie:

  References bibliographiques (facultatif).

- observations:

  Observations libres (facultatif).

## Value

Une liste nommee, prete a etre passee a
[`sommier_entree()`](https://pobsteta.github.io/sommieR/reference/sommier_entree.md).
