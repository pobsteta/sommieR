# Kanban de sommieR

> Cinq colonnes (fiche n° 8). Chaque carte porte l'Homme (qui), la Mission (quoi, quand,
> combien) et les Moyens (comment, où, avec qui), et renvoie à sa fiche dans
> `pilotage/missions/`. Elle note aussi depuis quel cycle de `/boucle` elle est dans sa
> colonne ; on change ce numéro chaque fois qu'elle change de colonne.
> **Une carte qui ne bouge pas est souvent la mauvaise nouvelle à dire tout de suite.**

**Dernier cycle :** 0 _(augmenté de 1 à la fin de chaque `/boucle`, même quand elle n'a
rien lancé. Une carte est immobile quand dernier cycle − N ≥ 2.)_

_Modèle de carte :_

```
- [NNN-titre](missions/NNN-titre.md) · depuis le cycle N
  - Homme : qui
  - Mission : quoi, quand, combien
  - Moyens : comment, où, avec qui
```

## Bac à sable

## Validé

## Planifié

## Terminé

## Abandonné

_Avec la raison, en une ligne._

## Livraisons

_Une ligne par cycle, ajoutée sous la précédente à la fin de chaque `/boucle`, et une
par `/bilan` : la livraison que Pascal a retenue, pour qui, et ce qu'elle apporte de plus
que la précédente du même rythme. On lance petit (fiche n° 12) : la plus petite version
qui rend déjà un service réel, un MVP, essayée tout de suite sur le terrain. Un cycle sans livraison neuve livre sa mauvaise
nouvelle, car
« une mauvaise nouvelle est une livraison sur laquelle on apprend » (Pascal) : on
l'inscrit avec ce qu'elle nous apprend._

```
- cycle N · livraison · pour qui · ce qu'elle apporte de plus que la précédente
- cycle N · mauvaise nouvelle : … · pour qui · ce qu'elle nous apprend
- bilan du AAAA-MM-JJ · livraison · pour qui · ce qu'elle apporte de plus que la précédente
- bilan du AAAA-MM-JJ · mauvaise nouvelle : … · pour qui · ce qu'elle nous apprend
```
