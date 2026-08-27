# Formats de manifeste que la verification accepte

Le format ecrit est
[SOMMIER_VERSION_MANIFESTE](https://pobsteta.github.io/sommieR/reference/SOMMIER_VERSION_MANIFESTE.md)
; ceux qui se **lisent** sont plus nombreux.

## Usage

``` r
SOMMIER_FORMATS_MANIFESTE_LUS
```

## Format

An object of class `character` of length 2.

## Details

Un manifeste est un export destine a etre verifie par un tiers, des
annees plus tard. Refuser de verifier un manifeste ancien sous pretexte
qu'une version posterieure du paquet ecrit autrement reviendrait a
annuler cela meme qu'il promet. Les evolutions du format sont additives
: la v2 ajoute le certificat du signataire, elle ne retire rien.
