# Deploiement du schema du sommier

Execute `001_schema.sql` puis `002_vues.sql`. Les deux fichiers sont
idempotents : les rejouer sur une base deja initialisee ne detruit ni
n'altere de donnee.

## Usage

``` r
sommier_init_schema(con, vues = TRUE)
```

## Arguments

- con:

  Connexion DBI vers une base PostgreSQL/PostGIS.

- vues:

  Deployer aussi les vues de consultation (defaut `TRUE`).

## Value

Invisiblement, le vecteur des fichiers executes.
