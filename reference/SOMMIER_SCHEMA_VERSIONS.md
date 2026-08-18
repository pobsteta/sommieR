# Versions de schema des payloads

Le payload est du JSONB versionne par type de registre (brief, section
4). La version est hachee avec l'entree : une evolution de schema ne
peut donc pas se faire passer pour l'ancienne.

## Usage

``` r
SOMMIER_SCHEMA_VERSIONS
```

## Format

An object of class `character` of length 9.
