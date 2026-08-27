# Verification d'un manifeste exporte

Verifie hors ligne la chaine d'un manifeste produit par
[`sommier_exporter_manifeste()`](https://pobsteta.github.io/sommieR/reference/sommier_exporter_manifeste.md),
et confronte chaque visa et chaque ancrage a l'empreinte qu'il pretend
attester.

## Usage

``` r
sommier_verifier_manifeste(chemin, ancres = list())
```

## Arguments

- chemin:

  Fichier JSON produit par
  [`sommier_exporter_manifeste()`](https://pobsteta.github.io/sommieR/reference/sommier_exporter_manifeste.md).

- ancres:

  Ancres de confiance, lues par
  [`certificat_lire()`](https://pobsteta.github.io/sommieR/reference/certificat_lire.md).
  Aucune n'est embarquee : ce serait faire dependre du rythme de
  publication de sommieR la question de savoir qui est digne de
  confiance.

## Value

Un objet `sommier_rapport`, dont les anomalies incluent les types
`visa_orphelin`, `ancrage_orphelin`, `visa_horodatage`,
`ancrage_horodatage` et `visa_signature`.

## Details

Deux confrontations sont faites, sans reseau ni magasin de confiance.

1.  Le `hash_tete` que l'attestation declare correspond a l'etat de la
    chaine a la sequence annoncee. Un visa dont l'empreinte ne
    correspond a aucune entree est signale : c'est ce qui detecte une
    attestation rapportee d'une autre chaine.

2.  **Le jeton d'horodatage atteste bien cette empreinte-la.** Le point
    1 porte sur ce que la base declare ; celui-ci sur ce que l'autorite
    a reellement signe. Sans lui, un jeton obtenu pour une autre tete de
    chaine accompagnerait le manifeste sans que rien ne le distingue du
    bon.

3.  **La signature JWS du visa se verifie**, quand le visa porte le
    certificat de son signataire (format `sommier-manifeste-2`). C'est
    ce qui rend l'export verifiable par un tiers sans qu'il ait a se
    procurer la cle par un canal que le manifeste n'organise pas.

**Anomalies et reserves ne se confondent pas.** Une anomalie dit que
quelque chose est faux ; une reserve, que quelque chose n'a pas pu etre
verifie sans que rien n'indique pour autant que ce soit faux - un jeton
intact dont aucune ancre fournie ne couvre l'autorite, un visa sans
certificat. Compter les secondes comme les premieres declarerait
invalide un manifeste parfait verifie sans ancres.

La revocation n'est jamais verifiee : CRL et OCSP demandent le reseau,
ce que la verification hors ligne exclut par construction. Le rapport le
dit en reserve plutot que de laisser croire le contraire.
