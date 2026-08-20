# Fond cadastral d'une commune

Telecharge et met en cache une couche du cadastre pour une commune. Le
fichier obtenu sert de fond de plan aux cartes du sommier.

## Usage

``` r
sommier_fond_cadastral(
  code_insee,
  couche = "parcelles",
  cache = NULL,
  force = FALSE
)
```

## Arguments

- code_insee:

  Code INSEE de la commune, sur cinq caracteres.

- couche:

  L'une de
  [SOMMIER_COUCHES_CADASTRE](https://pobsteta.github.io/sommieR/reference/SOMMIER_COUCHES_CADASTRE.md).

- cache:

  Repertoire de cache (defaut : le repertoire de cache de l'utilisateur
  pour ce paquet).

- force:

  Retelecharger meme si le fichier est deja en cache.

## Value

Invisiblement, un objet `sommier_fond` : `chemin`, `code_insee`,
`couche`, `millesime`, `source`, `telecharge_le`.

## Details

**Le cadastre n'est pas une ecriture du sommier.** Rien de ce qui est
telecharge ici n'entre dans un registre, dans une empreinte ou dans un
manifeste : ce serait faire passer la donnee d'un tiers pour un constat
du gestionnaire, exactement ce que le registre existe pour empecher. Le
fond est un decor, date et source ; sa perte n'affecte rien.

**Le telechargement est explicite.** Ni le rapport ni un export ne
declenchent d'appel reseau : un document de gestion doit pouvoir
s'engendrer sur un poste hors ligne. C'est l'appelant qui va chercher le
fond, une fois, et le passe ensuite a
[`sommier_rapport_quarto()`](https://pobsteta.github.io/sommieR/reference/sommier_rapport_quarto.md).

Le millesime est lu sur le serveur et conserve avec le fichier. Un fond
sans millesime induit en erreur des l'annee suivante - le parcellaire
bouge.

## See also

[`sommier_fond_lire()`](https://pobsteta.github.io/sommieR/reference/sommier_fond_lire.md)

## Examples

``` r
# Necessite un acces reseau :
# fond <- sommier_fond_cadastral("21200")
```
