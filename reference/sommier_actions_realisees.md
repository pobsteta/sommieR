# Le realise des travaux, rendu au plan d'action de nemetonshiny

Ecrit, pour une foret et une periode, le CSV du realise : une ligne par
travaux recu au registre 6 qui porte une `action_id` du plan d'action de
nemetonshiny. C'est le fichier que le bouton "realise" du module Plan
d'action lit (`TOURNEE_REALISE_COLONNES` de nemetonshiny) ; sommieR en
est la seule source : nemetonshiny ne lit jamais les saisies du
telephone.

## Usage

``` r
sommier_actions_realisees(
  con,
  foret_id,
  debut = NULL,
  fin = NULL,
  fichier = NULL
)
```

## Arguments

- con:

  Connexion DBI.

- foret_id:

  UUID de la foret.

- debut, fin:

  Bornes de la periode, sur la date de reception (facultatives).

- fichier:

  Chemin du CSV a ecrire (facultatif).

## Value

Invisiblement, le `data.frame` des six colonnes.

## Details

**Le contrat**, exactement ces six colonnes, dans cet ordre :
`action_id`, `travaux_id` (l'identifiant de l'entree du registre 6),
`code_travaux`, `date_reception`, `quantite`, `unite`. UTF-8, separateur
virgule, decimale point, cellule vide pour une valeur absente. Une meme
`action_id` revient sur autant de lignes que de travaux recus :
nemetonshiny regroupe et somme.

**Un travaux recu** est une entree courante du registre 6 (une
correction remplace l'entree qu'elle corrige) dont la `date_reception`
est renseignee. Un travaux sans reception, ou sans `action_id`, n'y
figure pas. La periode borne la `date_reception`.

**Le chemin de l'`action_id`.** L'action nait dans la couche `actions`
de `<projet>-programme-travaux.gpkg` (nemetonshiny), dont la colonne
`id` est l'`action_id` :

1.  [`sommier_lire_programme_travaux()`](https://pobsteta.github.io/sommieR/reference/sommier_lire_programme_travaux.md)
    lit cette couche ;

2.  `sommier_projet_qfield_travaux(programme = )` verse les actions dans
    la table `programme` du projet de tournee et offre leur liste au
    champ `action_id` des trois couches de travaux ;

3.  l'operateur choisit l'action en saisissant le travaux ;
    [`sommier_importer_qfield_travaux()`](https://pobsteta.github.io/sommieR/reference/sommier_importer_qfield_travaux.md)
    refuse un `action_id` absent du programme et inscrit les travaux au
    registre 6 avec leur `action_id` ;

4.  `sommier_actions_realisees()` rend les travaux recus au plan.

L'`action_id` entre aussi au registre 6 par la reprise tableur
([`sommier_reprendre_travaux()`](https://pobsteta.github.io/sommieR/reference/sommier_reprendre_travaux.md),
colonne `action_id`, voir
[SOMMIER_COLONNES_TABLEUR_TRAVAUX](https://pobsteta.github.io/sommieR/reference/SOMMIER_COLONNES_TABLEUR_TRAVAUX.md))
et par l'ecriture directe, `registre6_travaux(action_id = )`.

## See also

[`registre6_travaux()`](https://pobsteta.github.io/sommieR/reference/registre6_travaux.md),
[`sommier_bilan_travaux()`](https://pobsteta.github.io/sommieR/reference/sommier_bilan_travaux.md)
