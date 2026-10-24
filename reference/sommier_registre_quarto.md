# Sommier imprime en Quarto

Rend le sommier ecriture par ecriture - le document "Sommier de la
foret" - en HTML autoportant ou en PDF : la fiche A10 de tenue, puis
chaque registre dans l'ordre de la chaine, et en annexe les empreintes
completes.

## Usage

``` r
sommier_registre_quarto(
  con,
  foret_id,
  chemin,
  format = "html",
  registres = 1:9,
  jusqu_au_visa = NULL,
  public = FALSE,
  cles_publiques = list(),
  ancres = list(),
  sensibilite = NULL,
  departement = NULL,
  fond = NULL,
  quarto = Sys.which("quarto")
)
```

## Arguments

- con:

  Connexion DBI.

- foret_id:

  UUID de la foret.

- chemin:

  Fichier de destination. Son extension doit s'accorder avec `format`.

- format:

  `"html"` ou `"pdf"`.

- registres:

  Registres a extraire (1 a 9).

- jusqu_au_visa:

  Exercice dont le visa arrete l'edition ; `NULL` pour tout le sommier.

- public:

  `TRUE` pour un sommier a transmettre : les tiers des registres 3 et 7
  sont masques, les localisations sensibles floutees.

- cles_publiques, ancres:

  Transmises a
  [`sommier_verifier_visas()`](https://pobsteta.github.io/sommieR/reference/sommier_verifier_visas.md)
  pour verifier le visa qui arrete l'edition : cles publiques des
  signataires (inutiles quand le visa porte son certificat), ancres de
  confiance des autorites d'horodatage. Sans effet sans `jusqu_au_visa`.

- sensibilite:

  Le referentiel de sensibilite de l'INPN, lu par
  [`sommier_sensibilite()`](https://pobsteta.github.io/sommieR/reference/sommier_sensibilite.md).
  Sans lui, a `public = TRUE`, aucune espece localisee n'est diffusee.
  Sans effet sans `public`.

- departement:

  Code du departement de la foret (`"21"`, `"2A"`...), pour ne retenir
  que les listes qui s'y appliquent. Sans lui, la plus forte
  sensibilite, tous departements confondus.

- fond:

  Parcellaire cadastral a poser sous les croquis, tel que le rend
  [`sommier_fond_lire()`](https://pobsteta.github.io/sommieR/reference/sommier_fond_lire.md)
  ; `NULL` pour s'en passer. Il se fournit et ne se telecharge pas au
  rendu, comme pour
  [`sommier_rapport_quarto()`](https://pobsteta.github.io/sommieR/reference/sommier_rapport_quarto.md)
  ; sa source et son millesime sont dits sous chaque croquis.

- quarto:

  Chemin de l'executable Quarto.

## Value

Invisiblement, le chemin du document produit.

## Details

Meme mecanique que
[`sommier_rapport_quarto()`](https://pobsteta.github.io/sommieR/reference/sommier_rapport_quarto.md)
: l'extraction
([`sommier_registre()`](https://pobsteta.github.io/sommieR/reference/sommier_registre.md))
est deposee dans un RDS que le gabarit lit, et le rendu ne touche pas la
base. Le document n'est pas la preuve : la valeur probante reste dans la
chaine, que
[`sommier_exporter_manifeste()`](https://pobsteta.github.io/sommieR/reference/sommier_exporter_manifeste.md)
transporte, et le document le dit.

Un sommier a transmettre hors du gestionnaire se rend avec
`public = TRUE` : les noms de tiers des registres 3 et 7 (titulaires,
garants, tiers d'une ecriture) sont remplaces par "(masque)". La ligne,
son montant et son empreinte restent : on voit qu'une ecriture existe,
pas qui elle nomme. Les photos des constats ne sont jamais reproduites,
seulement comptees.

**Les croquis sont une annexe de lecture, hors chaine.** Un croquis par
fiche - par unite de gestion et version de son contour, puis par objet
hors unite - precede d'un plan de situation. Chaque ecriture localisee y
figure, rectifiees comprises, a sa position propre ou, a defaut, dans
son unite, prise dans le contour qu'elle avait a la date de l'evenement.
Le trait dit la provenance (constat, source indirecte, transcription) ;
chaque croquis porte son echelle, le nord, le systeme de coordonnees et
la source de ses contours, et du parcellaire cadastral quand `fond` le
fournit. Il faut le paquet `sf` la ou le document se rend.

A `public = TRUE`, **les especes sensibles sont floutees selon le SINP**
: le croquis les tait, et leur fiche dit l'echelle de diffusion - la
commune, la maille 10 km ou le departement, selon le code de sensibilite
du referentiel de l'INPN (`sensibilite`). L'unite de gestion et le
libelle de localisation de ces ecritures sont tus aussi. Sans
referentiel, aucune espece localisee n'est diffusee.

Le PDF est un PDF/A-2B (ISO 19005-2) : polices et croquis embarques,
rejouable sans reseau.

Arrete a un visa (`jusqu_au_visa`), le document porte en tete ce visa
tel que
[`sommier_verifier_visas()`](https://pobsteta.github.io/sommieR/reference/sommier_verifier_visas.md)
le juge : le signataire et son certificat, la signature, le jeton
d'horodatage et l'autorite qui l'a emis. Les pieces elles-memes
(signature JWS, certificat PEM, jeton en base64) sont en annexe. Le nom
du signataire n'est pas masque a `public = TRUE` : il vise en qualite,
ce n'est pas un tiers.

## See also

[`sommier_registre()`](https://pobsteta.github.io/sommieR/reference/sommier_registre.md),
[`sommier_rapport_quarto()`](https://pobsteta.github.io/sommieR/reference/sommier_rapport_quarto.md)
