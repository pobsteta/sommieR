# Le document engendré

L’[article
précédent](https://pobsteta.github.io/sommieR/articles/gestion-anterieure.md)
montre les données qui alimentent le rapport de gestion antérieure.
Celui-ci montre **le document lui-même** : ce que
[`sommier_rapport_quarto()`](https://pobsteta.github.io/sommieR/reference/sommier_rapport_quarto.md)
dépose sur le disque, sans retouche, dans sa propre mise en page.

Rien n’est recopié ni réécrit ici. Le document encadré plus bas est
produit à la construction de ce site, par un appel à la fonction ; ses
chiffres sont lus dans la base au moment du rendu, et son empreinte de
tête est celle du registre à cet instant.

## L’appel

Une ligne, une fois le sommier peuplé : la fonction extrait les données,
vérifie la chaîne, rend le document et retourne son chemin.

``` r

sommier_rapport_quarto(
  con, foret,
  chemin      = document,
  format      = "html",
  debut       = "2016-01-01",
  fin         = "2025-12-31",
  referentiel = "amenagement"
)
```

Les données sont extraites **avant** le rendu et déposées dans un RDS
que le document lit : aucun identifiant de connexion ne circule dans le
document ni dans ses paramètres, et le même instantané se rejoue des
mois plus tard sans accès à la base. `format = "pdf"` produit le même
contenu en PDF, pour un dossier à déposer.

## Le document

[Ouvrir le document dans un
onglet](https://pobsteta.github.io/sommieR/articles/rapport-gestion-anterieure.md)
— il est autoportant : enregistré seul, il s’ouvre sans réseau et sans
le paquet qui l’a produit.

## Ce qu’il faut y regarder

Le document s’ouvre sur un **avertissement de démonstration** : la
fonction le pose d’elle-même dès que le nom de la forêt porte la
mention. Un paquet dont l’objet est la valeur probante ne peut pas
produire de fausses écritures qui passeraient pour authentiques ;
l’avertissement ne dépend donc pas de la vigilance de celui qui édite.

Vient ensuite l’**état de la chaîne** au moment de l’édition — nombre
d’entrées, séquence et empreinte de tête. C’est le seul endroit du
document qui engage quelque chose. Tout le reste est une mise en forme,
et le document le dit lui-même plutôt que de laisser croire qu’un HTML
vaut attestation :

``` r

sommier_verifier(con, foret)
#> Verification de chaine - sommier
#>   foret     : 90aac88f-35b3-412e-b0d3-fcd07571ea7c
#>   entrees   : 66
#>   seq tete  : 66
#>   hash tete : 03bf72ae819de467b2c9d4cec8b8a01510d983997f1d9f1868bb51c6976912b7
#>   etat      : chaine intacte
```

L’empreinte affichée dans le cadre ci-dessus est celle-là. Un
destinataire qui veut contrôler les chiffres ne relit pas le document :
il demande le manifeste et le vérifie hors ligne, sans base et sans
confiance envers l’émetteur.

## Rejouer cette page

Il faut une base PostGIS et Quarto dans le `PATH` :

``` sh
docker run -d --name sommier-pg -p 5432:5432 \
  -e POSTGRES_PASSWORD=postgres -e POSTGRES_DB=sommier_article \
  postgis/postgis:16-3.4

SOMMIER_ARTICLE_DB=sommier_article \
SOMMIER_ARTICLE_USER=postgres \
SOMMIER_ARTICLE_PASSWORD=postgres \
  Rscript -e 'pkgdown::build_article("articles/rapport-engendre")'
```

L’un ou l’autre manquant, la page se construit quand même et affiche un
encart qui le dit : un cadre vide sans explication ressemblerait à un
document raté plutôt qu’à un document non engendré.
