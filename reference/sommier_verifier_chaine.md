# Verification d'une chaine d'entrees de sommier

Recalcule la chaine de la genese a la tete et confronte chaque empreinte
stockee a l'empreinte recalculee. C'est la fonction que le brief
(section 6.3) designe comme utilisable "par un auditeur tiers sur un
export" : elle ne touche pas la base et ne fait confiance a aucun
serveur, elle ne travaille que sur les donnees qu'on lui remet.

## Usage

``` r
sommier_verifier_chaine(entrees, foret_id = NULL, hash_prev_initial = NULL)
```

## Arguments

- entrees:

  `data.frame` ou liste de listes nommees, portant au moins les colonnes
  de
  [SOMMIER_CHAMPS_EMPREINTE](https://pobsteta.github.io/sommieR/reference/SOMMIER_CHAMPS_EMPREINTE.md)
  plus `hash` et `hash_prev`. Les empreintes sont acceptees en `raw` ou
  en hexadecimal. Le `payload` peut etre une liste R ou du texte JSON
  (recanonise via
  [`jcs_depuis_json()`](https://pobsteta.github.io/sommieR/reference/jcs_depuis_json.md)).

- foret_id:

  Identifiant de la foret ; deduit des entrees si absent.

- hash_prev_initial:

  Empreinte precedant la premiere entree fournie. Par defaut, la genese
  de la foret - a renseigner pour verifier un fragment de chaine a
  partir d'une ancre.

## Value

Un objet de classe `sommier_rapport` : liste comportant `valide`
(booleen), `n_entrees`, `foret_id`, `seq_tete`, `hash_tete`
(hexadecimal) et `anomalies` (`data.frame` a colonnes `seq`, `id`,
`type`, `message`).

## Details

Cinq classes d'anomalies sont distinguees, parce qu'elles ne se
corrigent pas de la meme facon :

- `sequence_manquante` : un trou dans `seq` - une entree a ete retiree
  de l'export, ou n'a jamais ete inseree.

- `sequence_dupliquee` : deux entrees portant le meme `seq` - signe
  d'une fourche d'ecriture concurrente que le verrou consultatif aurait
  du empecher.

- `chainage_rompu` : le `hash_prev` d'une entree ne correspond pas au
  `hash` de la precedente - une entree a ete inseree, retiree ou
  reordonnee.

- `empreinte_invalide` : le `hash` stocke ne correspond pas au recalcul
  sur le contenu - le contenu de l'entree a ete modifie apres coup.

- `genese_invalide` : la premiere entree ne part pas de
  [`sommier_empreinte_genese()`](https://pobsteta.github.io/sommieR/reference/sommier_empreinte_genese.md) -
  la chaine a ete tronquee par le debut.

Une chaine dont la premiere entree n'a pas `seq == 1` est signalee comme
tronquee : la verification reste possible a partir d'une ancre connue,
mais l'appelant doit alors fournir `hash_prev_initial`.

## Examples

``` r
entrees <- sommier_chainer(list(
  sommier_entree(
    foret_id = "3f2b1c4d-5e6f-4a7b-8c9d-0e1f2a3b4c5d",
    registre = 5L, date_evenement = "2026-03-01", auteur = "agent-01",
    payload = registre5_coupe(
      type_entree = "martelage", exercice = 2026,
      nature_coupe = "amelioration", volume_m3 = 120
    )
  )
))
sommier_verifier_chaine(entrees)
#> Verification de chaine - sommier
#>   foret     : 3f2b1c4d-5e6f-4a7b-8c9d-0e1f2a3b4c5d
#>   entrees   : 1
#>   seq tete  : 1
#>   hash tete : 2c391eed86f29d2b13b809e14f29a6c87f29646d05445015700fae57af340fda
#>   etat      : chaine intacte
```
