# Geometries d'un payload

Construisent la geometrie GeoJSON qu'une entree de sommier peut porter :
`geom_point()` pour une borne, un arbre ou un equipement, `geom_ligne()`
pour une voirie ou un fosse, `geom_polygone()` pour une emprise de
coupe, un habitat ou un phenomene.

## Usage

``` r
geom_point(lon, lat)

geom_ligne(coords)

geom_polygone(coords, fermer = TRUE)
```

## Arguments

- lon, lat:

  Longitude et latitude en degres decimaux (WGS84).

- coords:

  Sommets : matrice ou `data.frame` a deux colonnes (longitude,
  latitude), ou liste de couples.

- fermer:

  Fermer l'anneau si le dernier sommet ne repete pas le premier (defaut
  `TRUE`). Un anneau non ferme n'est pas un polygone ; le refermer est
  une convention de saisie, pas une correction de mesure.

## Value

Une liste nommee `type` / `coordinates`, prete a etre passee en
`geometrie` a un constructeur de payload.

## Details

**La geometrie est dans le payload, donc dans l'empreinte.** Elle n'est
pas une commodite d'affichage rangee a cote du registre : c'est un
constat date et chaine au meme titre qu'un volume ou un montant, et le
contour d'une coupe devient aussi opposable que son volume.

Deux consequences de ce choix. Les coordonnees sont en **WGS84
(EPSG:4326)**, comme l'exige la RFC 7946 : un payload doit s'interpreter
sans contexte exterieur, et une coordonnee Lambert-93 nue n'aurait de
sens que pour qui connait la convention du producteur. Elles sont
arrondies a
[SOMMIER_DECIMALES_COORD](https://pobsteta.github.io/sommieR/reference/SOMMIER_DECIMALES_COORD.md)
decimales, pour que deux saisies du meme contour donnent les memes
octets - sans quoi le chainage cesserait d'etre reproductible.

Une longitude hors de \[-180, 180\] ou une latitude hors de \[-90, 90\]
est refusee, avec la mention du cas le plus probable : des coordonnees
projetees passees telles quelles.

## Examples

``` r
geom_point(4.951, 47.271)
#> $type
#> [1] "Point"
#> 
#> $coordinates
#> [1]  4.951 47.271
#> 

geom_ligne(rbind(c(4.950, 47.270), c(4.952, 47.271)))
#> $type
#> [1] "LineString"
#> 
#> $coordinates
#> $coordinates[[1]]
#> [1]  4.95 47.27
#> 
#> $coordinates[[2]]
#> [1]  4.952 47.271
#> 
#> 

geom_polygone(rbind(
  c(4.950, 47.270), c(4.952, 47.270), c(4.952, 47.272), c(4.950, 47.272)
))
#> $type
#> [1] "Polygon"
#> 
#> $coordinates
#> $coordinates[[1]]
#> $coordinates[[1]][[1]]
#> [1]  4.95 47.27
#> 
#> $coordinates[[1]][[2]]
#> [1]  4.952 47.270
#> 
#> $coordinates[[1]][[3]]
#> [1]  4.952 47.272
#> 
#> $coordinates[[1]][[4]]
#> [1]  4.950 47.272
#> 
#> $coordinates[[1]][[5]]
#> [1]  4.95 47.27
#> 
#> 
#> 
```
