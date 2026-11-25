# Import d'une tournee de travaux et de suivi des plantations

Relit le projet rapporte du terrain et inscrit au registre 6 les travaux
releves, les placettes installees et les controles saisis, avec leurs
photos deposees sous leur empreinte.

## Usage

``` r
sommier_importer_qfield_travaux(con, foret_id, dossier, depot, auteur)
```

## Arguments

- con:

  Connexion DBI.

- foret_id:

  UUID de la foret.

- dossier:

  Dossier du projet, rapporte du terrain.

- depot:

  Repertoire du depot de photos.

- auteur:

  Compte qui importe. L'agent qui a releve est l'operateur.

## Value

Invisiblement, un bilan : `travaux`, `placettes`, `plants`, `controles`
(nombres d'entrees ecrites), `deja_presents`, `photos`, `entrees` et
`avertissements` (ecarts de forme acceptes : colonnes en trop de
`photos_terrain`, empreinte vide, photo en double, niveau de concurrence
contredit par les comptages de plants ; chacun est aussi rendu par
[`warning()`](https://rdrr.io/r/base/warning.html)).

## Details

**Tout ou rien.** Chaque saisie est controlee avant toute ecriture :
code connu et forme de la couche admise par le code, unite du code,
motif d'un ecart au prevu, placette rattachee a des travaux connus,
controle sur une placette connue, vivants et abroutis coherents, photos
presentes. Une faute fait echouer l'import, qui les liste toutes. Un
controle ajoute depuis sa couche, sans placette choisie, se rattache a
la placette la plus proche de sa position, a 15 m pres. L'ecriture se
fait en une transaction, dans cet ordre : travaux, placettes,
controles - une placette peut suivre des travaux releves dans la meme
tournee, un controle porter sur une placette qui vient d'etre installee.

**La position mesuree des controles.** Si la tournee porte la couche
`positions_controles` de Surculus (cle `controle_uuid`, un point par
controle), chaque position est inscrite au controle : `geometrie` (WGS
84, reprojetee depuis le SCR de la couche), `precision_m`,
`rattache_par_identite`, `sans_position_mesuree`. Une ligne a geometrie
NULL (ou POINT EMPTY) donne un controle **sans** geometrie et
`sans_position_mesuree = TRUE` : jamais un point (0, 0). Une couche sans
SCR, une position hors des bornes WGS 84, une position qui contredit son
drapeau ou deux lignes pour un meme controle sont des fautes (rien n'est
ecrit) ; une ligne pour un controle absent de la tournee est ignoree et
dite aux avertissements. Sans la couche, la tournee s'importe comme
avant.

**Les plants.** Si la tournee porte les couches `plants` (POINT) et
`etats_plants` de Surculus, les plants s'inscrivent entre les placettes
et les controles (type `plant`, UUID de la couche), et les etats de
chaque controle entrent dans son payload (`plants`), les totaux devant
en decouler. Fautes (rien n'est ecrit) : plant sans placette ou sans
position, numero deja pris dans la placette, plant deja inscrit sous un
autre numero ou une autre placette, regarni qui ne remplace pas un plant
mort ou absent de sa placette (le mort peut l'etre dans un controle de
la meme tournee), etat d'un plant inconnu ou d'un controle absent de la
tournee, deux etats du meme plant dans un controle, totaux qui ne
concordent pas avec les etats, plant vivant (ou jamais vu) au passage
precedent sans etat, plant mort ou absent redit vivant. Un plant
remplace par un regarni d'un passage anterieur n'a plus d'etat a donner.
Sans les couches, la tournee s'importe comme avant.

**Rejouable.** L'UUID que QField a donne a chaque saisie devient celui
de l'entree : reimporter le meme dossier n'ecrit rien de plus. Les
placettes deja inscrites, versees dans le projet, ne se reinscrivent
pas.

**L'unite de gestion** d'une intervention est celle qui contient sa
geometrie (le point interieur d'une surface, le milieu d'une ligne) ;
hors de toute unite, l'intervention est inscrite a l'echelle de la
foret.

Toutes les entrees portent NDP 0 : ce sont des constats de terrain.

## See also

[`sommier_projet_qfield_travaux()`](https://pobsteta.github.io/sommieR/reference/sommier_projet_qfield_travaux.md),
[`sommier_verifier_photos()`](https://pobsteta.github.io/sommieR/reference/sommier_verifier_photos.md)
