# Pose d'un visa signe sur la tete de chaine

Cloture un exercice : enregistre l'acte de visa au registre 1, signe la
tete de chaine, l'horodate si une autorite est configuree, et inscrit le
visa. C'est le flux de la section 6.3 du brief.

## Usage

``` r
sommier_viser(
  con,
  foret_id,
  exercice,
  autorite,
  signataire,
  nom_qualite = NULL,
  tsa_url = NULL,
  transport = tsa_transport_curl(),
  enregistrer_acte = TRUE
)
```

## Arguments

- con:

  Connexion DBI.

- foret_id:

  UUID de la foret.

- exercice:

  Exercice vise (entier).

- autorite:

  Autorite de validation : `"onf"`, `"commune"`, `"crpf"` ou
  `"proprietaire"`.

- signataire:

  Objet
  [`sommier_signataire()`](https://pobsteta.github.io/sommieR/reference/sommier_signataire.md).

- nom_qualite:

  Nom et qualite portes au registre 1. Par defaut, le claim `name` du
  signataire, a defaut son `sub`.

- tsa_url:

  URL de l'autorite d'horodatage (facultatif).

- transport:

  Transport HTTP, voir
  [`tsa_transport_curl()`](https://pobsteta.github.io/sommieR/reference/tsa_transport_curl.md).

- enregistrer_acte:

  Ecrire l'entree de registre 1 (defaut `TRUE`).

## Value

Invisiblement, une liste : `id`, `seq_tete`, `hash_tete` (hexadecimal),
`horodate` (booleen) et `date_attestee` - la date que l'autorite a
certifiee, `NA` sans horodatage.

## Details

L'ordre des operations n'est pas indifferent.

1.  L'entree de registre 1 est ecrite **d'abord**, de sorte que la tete
    signee la couvre : le visa atteste un sommier qui contient la trace
    de sa propre delivrance.

2.  La tete est lue **ensuite**, dans la meme transaction.

3.  La signature et l'horodatage portent sur cette tete.

Signer avant d'ecrire l'acte laisserait au contraire une entree hors
couverture du visa.

Si `tsa_url` est laisse a `NULL`, le visa est pose sans jeton
d'horodatage : c'est un visa valide, mais dont la date ne repose que sur
l'horloge du serveur.
[`sommier_verifier_visas()`](https://pobsteta.github.io/sommieR/reference/sommier_verifier_visas.md)
le signale.

## See also

[`sommier_verifier_visas()`](https://pobsteta.github.io/sommieR/reference/sommier_verifier_visas.md)
