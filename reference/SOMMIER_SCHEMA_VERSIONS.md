# Versions de schema des payloads

Le payload est du JSONB versionne par type de registre (brief, section
4). La version est hachee avec l'entree : une evolution de schema ne
peut donc pas se faire passer pour l'ancienne.

## Usage

``` r
SOMMIER_SCHEMA_VERSIONS
```

## Details

Les registres 2, 4, 5, 8 et 9 sont passes en `1.1.0` lorsque la
geometrie est entree dans leurs payloads. Les neuf sont passes a la
version suivante lorsque le bloc `reprise` est devenu admissible dans
tous les payloads (voir
[`sommier_reprise()`](https://pobsteta.github.io/sommieR/reference/sommier_reprise.md))
: la provenance concerne chaque registre, la version le dit pour chacun.
Les entrees anterieures gardent la version sous laquelle elles ont ete
ecrites, et restent valides : le registre est append-only, un changement
de schema ne se retrofitte pas sur ce qui est deja chaine. C'est
precisement ce que la version hachee permet de dire - cette entree a ete
ecrite sous ce schema-la.
