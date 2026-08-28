# Gestion anterieure : coupes, travaux, evenements et comptes

Assemble, sur une periode, ce que les trois referentiels reclament sous
des noms differents. Le brief le dit : « les trois se generent depuis
les memes registres ». Il y a donc **un seul assemblage** et trois
presentations, et non trois extractions paralleles qui divergeraient a
la premiere evolution.

## Usage

``` r
sommier_gestion_anterieure(
  con,
  foret_id,
  debut = NULL,
  fin = NULL,
  referentiel = "psg"
)
```

## Arguments

- con:

  Connexion DBI.

- foret_id:

  UUID de la foret.

- debut, fin:

  Bornes de la periode (`Date` ou `"AAAA-MM-JJ"`). Par defaut, tout le
  sommier.

- referentiel:

  L'un de
  [SOMMIER_REFERENTIELS](https://pobsteta.github.io/sommieR/reference/SOMMIER_REFERENTIELS.md).

## Value

Un objet de classe `sommier_gestion_anterieure` : liste de sections,
chacune un `data.frame`, plus les metadonnees de periode et de foret.

## Details

Ce que chaque referentiel retient :

|                             |     |             |      |
|-----------------------------|-----|-------------|------|
| Section                     | psg | amenagement | ct88 |
| Provenance des ecritures    | oui | oui         | oui  |
| Coupes realisees et balance | oui | oui         | oui  |
| Travaux realises            | oui | oui         | oui  |
| Evenements marquants        | oui | oui         | oui  |
| Bilan financier             | non | oui         | oui  |
| Equilibre foret-gibier      | oui | oui         | non  |
| Patrimoine remarquable      | oui | oui         | non  |

Le PSG ne demande pas le detail financier, que le proprietaire n'a pas a
produire au CRPF ; le CT88, tourne vers l'evaluation d'un contrat, ne
reclame pas l'inventaire du patrimoine remarquable. Restreindre la
sortie a ce qui est demande evite de diffuser plus que necessaire - les
registres 3 et 7 portent des donnees personnelles.

**Constate et transcrit ne se melent pas.** Les trois referentiels
portent sur une periode ecoulee ; un sommier ouvert en cours de route ne
la couvre donc qu'en partie par ses propres constats, le reste ayant ete
transcrit de l'existant (voir
[`sommier_reprise()`](https://pobsteta.github.io/sommieR/reference/sommier_reprise.md)).
Les tableaux de coupes et de travaux portent pour cette raison une
colonne `provenance`, et la section `provenance` compte registre par
registre ce qui a ete constate et ce qui a ete recopie. Un tableau qui
les additionnerait sans le dire ferait passer la recopie pour de la
mesure.

## See also

[`sommier_rapport_markdown()`](https://pobsteta.github.io/sommieR/reference/sommier_rapport_markdown.md)
