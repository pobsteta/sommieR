# Depot d'une photo, sous son empreinte

Hache une photo (SHA-256), la copie dans le depot sous le nom
`<sha256>.<extension>`, et rend sa description prete pour le payload
d'une reconnaissance de limite.

## Usage

``` r
sommier_deposer_photo(fichier, depot)
```

## Arguments

- fichier:

  Chemin de la photo.

- depot:

  Repertoire du depot. Cree s'il n'existe pas.

## Value

Une liste : `sha256`, `octets`, `type`, `fichier` (nom d'origine), et,
lorsque l'EXIF les porte, `exif_date`, `exif_decalage`, `exif_date_utc`,
`exif_position`, `exif_datum`, `exif_erreur_m`.

## Details

**La photo n'entre pas dans la base, son empreinte oui.** Le payload
porte le SHA-256 du fichier ; les octets vivent dans le depot, sous ce
nom. La chaine atteste donc les octets : un recadrage, une retouche ou
un remplacement changent l'empreinte, et
[`sommier_verifier_photos()`](https://pobsteta.github.io/sommieR/reference/sommier_verifier_photos.md)
le voit.

**Le fichier n'est jamais modifie**, pas meme pour en retirer des
metadonnees. Un fichier retouche par l'outil qui pretend en garantir
l'integrite, ce serait la preuve fabriquee par son propre gardien.

**Ce que l'EXIF dit est une declaration de l'appareil.** La date de
prise de vue et la position, lues dans l'en-tete EXIF d'un JPEG, sont
recopiees comme telles (`exif_date`, `exif_position`) et jamais
presentees comme des faits : la chaine atteste que la photo existait,
avec ces octets, au moment de l'ecriture - pas quand ni ou elle a ete
prise. `exif_date` est l'heure locale de l'appareil, sans fuseau :
l'EXIF n'en porte pas.

**Trois balises disent comment lire la date et la position** :
`OffsetTimeOriginal` (`exif_decalage`, ex. `+01:00`) donne le fuseau de
`exif_date` et permet d'en tirer `exif_date_utc` ; `GPSMapDatum`
(`exif_datum`, ex. `ETRS89` en RTK Centipede, `WGS-84` en GNSS autonome)
dit dans quel repere est `exif_position` ; `GPSHPositioningError`
(`exif_erreur_m`) en donne la precision horizontale, en metres. **Une
position n'est jamais tenue pour du WGS 84 sans que le fichier le dise**
: sans `exif_datum`, le repere est inconnu, et `exif_position` reste une
declaration de l'appareil.

Deposer deux fois la meme photo ne la copie qu'une fois. Un fichier deja
present sous ce nom mais d'un autre contenu est une alteration du depot
: elle est signalee, et rien n'est ecrase.

## See also

[`sommier_verifier_photos()`](https://pobsteta.github.io/sommieR/reference/sommier_verifier_photos.md),
[`sommier_importer_qfield()`](https://pobsteta.github.io/sommieR/reference/sommier_importer_qfield.md)

## Examples

``` r
# p <- sommier_deposer_photo("DCIM/borne-12.jpg", "photos")
```
