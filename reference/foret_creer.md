# Creation d'une foret

Creation d'une foret

## Usage

``` r
foret_creer(
  con,
  nom,
  regime,
  proprietaire = NULL,
  date_application_regime_forestier = NULL,
  surface_ha = NULL,
  id = uuid_v4()
)
```

## Arguments

- con:

  Connexion DBI.

- nom:

  Nom de la foret.

- regime:

  L'un de
  [SOMMIER_REGIMES](https://pobsteta.github.io/sommieR/reference/SOMMIER_REGIMES.md).

- proprietaire:

  Proprietaire (facultatif).

- date_application_regime_forestier:

  Date d'application du regime forestier - sans objet en foret privee.

- surface_ha:

  Surface en hectares (facultatif).

- id:

  UUID a affecter ; genere si absent.

## Value

L'UUID de la foret creee.
