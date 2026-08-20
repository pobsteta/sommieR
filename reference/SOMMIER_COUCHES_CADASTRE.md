# Couches du fond cadastral

Ce que les livraisons publiques du cadastre exposent reellement, verifie
le 20 aout 2026 sur `cadastre.data.gouv.fr` : parcelles, sections,
batiments, lieux-dits, feuilles, prefixes de section et subdivisions
fiscales.

## Usage

``` r
SOMMIER_COUCHES_CADASTRE
```

## Details

**Ce que ces livraisons ne portent pas.** Ni bornes, ni fosses, ni aucun
objet topographique ponctuel ou lineaire. Ceux-la figurent dans la forme
EDIGEO du Plan Cadastral Informatise, publiee sur le meme site mais dans
un autre jeu de donnees (`dgfip-pci-vecteur`), par feuille cadastrale et
dans un format qui demande le pilote EDIGEO de GDAL. Elle n'est donc pas
hors d'atteinte : elle est hors de ce que ce paquet va chercher
aujourd'hui.

Et quand bien meme on l'irait chercher, une borne relevee par la DGFiP
reste la donnee d'un tiers. Ce qui fait foi dans un sommier, c'est le
**constat du gestionnaire** - registre 2 pour le foncier, registre 4
pour les infrastructures - saisi avec sa geometrie (voir
[geometries](https://pobsteta.github.io/sommieR/reference/geometries.md))
et chaine avec le reste.
