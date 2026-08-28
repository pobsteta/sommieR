# Provenances usuelles d'une reprise, et le NDP qu'elles portent

L'echelle de precision applicable a ce qui entre dans le sommier par
transcription. Elle evite que le NDP d'une reprise soit laisse au
jugement de l'appelant : deux communes qui transcrivent le meme genre de
piece doivent porter le meme niveau, sans quoi le champ ne dit plus
rien.

## Usage

``` r
SOMMIER_SOURCES_REPRISE
```

## Format

`data.frame` de 4 lignes et 3 colonnes : `source`, `ndp`, `description`.

## Details

Le NDP croit avec la distance entre l'ecriture et un fait attestable.
NDP 0 n'y figure pas : il est reserve au constat de terrain, et une
transcription n'en est jamais un - voir
[`sommier_reprise()`](https://pobsteta.github.io/sommieR/reference/sommier_reprise.md).

|  |  |  |
|----|----|----|
| Provenance | NDP | Ce qui la distingue |
| `registre_signe` | 1 | une piece datee et signee, opposable telle quelle |
| `base_gestionnaire` | 2 | une base tenue, mais sans visa piece a piece |
| `tableur` | 3 | un fichier sans tenue verifiable ni signature |
| `temoignage` | 4 | une declaration recueillie, sans piece qui la porte |

L'echelle est volontairement courte. Une provenance qui n'y figure pas
se rattache a la ligne la plus proche par le bas - une piece dont on ne
sait pas dire qui la tenait ne vaut pas mieux qu'un tableur.

## See also

[`reprise_source()`](https://pobsteta.github.io/sommieR/reference/reprise_source.md),
[`sommier_reprise()`](https://pobsteta.github.io/sommieR/reference/sommier_reprise.md)

## Examples

``` r
SOMMIER_SOURCES_REPRISE
#>              source ndp
#> 1    registre_signe   1
#> 2 base_gestionnaire   2
#> 3           tableur   3
#> 4        temoignage   4
#>                                                                                                                 description
#> 1        Registre ou imprime de la serie A50 tenu et vise, arrete, deliberation, proces-verbal : une piece datee et signee.
#> 2          Extrait date d'une base tenue par un gestionnaire - ONF, cooperative, expert - sans visa attache a chaque ligne.
#> 3     Tableur ou fichier bureautique sans visa ni tenue verifiable : le contenu est plausible, sa tenue n'est pas attestee.
#> 4 Declaration recueillie, note non datee, piece sans auteur identifiable : ce qui reste quand aucun ecrit ne porte le fait.
```
