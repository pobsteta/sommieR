# Etats constates d'un element de limite

Tous les etats qu'un constat peut porter. Ils dependent de la forme de
l'element (voir
[SOMMIER_ETATS_PAR_FORME](https://pobsteta.github.io/sommieR/reference/SOMMIER_ETATS_PAR_FORME.md)).

Un point - une borne, un signe, un detail ponctuel :

- `en_place` : l'element est la, en etat ;

- `endommage` : il est la, abime (borne penchee, mur en partie effondre)
  ;

- `non_retrouve` : cherche sans succes ;

- `detruit` : ses vestiges sont constates.

Une ligne - une voie, un fosse, un detail lineaire -, par sa visibilite
:

- `visible` : elle se suit sans peine ;

- `partiellement_visible` : elle se suit par endroits ;

- `peu_visible` : quelques traces seulement ;

- `non_visible` : aucune trace sur le terrain.

Une surface - un batiment, un cours d'eau, un detail surfacique :

- `conforme` : presente, conforme au plan ;

- `modifiee` : presente, d'emprise ou de forme differente du plan ;

- `degradee` : en ruine, comblee, envahie ;

- `disparue` : plus rien sur le terrain.

Pour toutes : `inaccessible`, on n'a pas pu l'approcher. Et `hors_plan`
: trouve sur le terrain, absent du plan cadastral.

## Usage

``` r
SOMMIER_ETATS_LIMITE
```

## Details

Des etats constates, pas des verdicts. Il n'y a pas d'etat « deplace » :
un ecart de quelques metres entre un GNSS et un plan au 1/5000 ne prouve
rien, et juger qu'une borne a bouge revient au geometre. L'ecart se
calcule a la lecture, a la lumiere de la precision declaree du releve.
