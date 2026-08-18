# Decoupage d'un script SQL en instructions

Separe un script sur les points-virgules de premier niveau. Necessaire
parce que les pilotes qui passent par le protocole etendu de PostgreSQL
(RPostgres, via une instruction preparee) refusent plusieurs commandes
en un seul envoi : « cannot insert multiple commands into a prepared
statement ». Les pilotes en protocole simple l'acceptent, ce qui rend le
defaut invisible tant qu'on ne change pas de pilote.

## Usage

``` r
decouper_sql(sql)
```

## Arguments

- sql:

  Le script, en une chaine de caracteres.

## Value

Un vecteur de caracteres : une instruction par element, sans le
point-virgule final, les instructions vides ecartees.

## Details

Un simple `strsplit(sql, ";")` ne convient pas : le schema du sommier
contient des corps de fonction plpgsql delimites par `$$`, qui portent
leurs propres points-virgules. Le decoupage suit donc l'etat lexical du
script :

- chaines `'...'`, ou `''` designe une apostrophe litterale et ne ferme
  pas la chaine ;

- identifiants entre guillemets `"..."` ;

- blocs delimites par le dollar, `$$...$$` ou `$tag$...$tag$`, ou seul
  le meme tag ferme le bloc ;

- commentaires de ligne `-- ...` ;

- commentaires de bloc, imbricables en PostgreSQL.

## Examples

``` r
decouper_sql("SELECT 1; SELECT 2;")
#> [1] "SELECT 1" "SELECT 2"
```
