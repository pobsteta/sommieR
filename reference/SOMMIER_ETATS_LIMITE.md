# Etats constates d'un element de limite

- `en_place` : l'element est la, en etat ;

- `endommage` : il est la, abime (borne penchee, mur en partie effondre)
  ;

- `non_retrouve` : cherche sans succes ;

- `detruit` : ses vestiges sont constates ;

- `inaccessible` : on n'a pas pu l'approcher ;

- `hors_plan` : trouve sur le terrain, absent du plan cadastral.

## Usage

``` r
SOMMIER_ETATS_LIMITE
```

## Details

Des etats constates, pas des verdicts. Il n'y a pas d'etat « deplace » :
un ecart de quelques metres entre un GNSS et un plan au 1/5000 ne prouve
rien, et juger qu'une borne a bouge revient au geometre. L'ecart se
calcule a la lecture, a la lumiere de la precision declaree du releve.
