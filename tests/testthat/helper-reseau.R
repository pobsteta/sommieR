# Deux tests seulement vont chercher la source reelle : ils verifient le chemin
# de telechargement contre le vrai serveur, ce qu'aucun cache pre-rempli ne
# peut faire. Ils ont donc besoin d'un garde-fou, et `skip_if_offline()` n'en
# est pas un suffisant : il demande « y a-t-il un internet ? », pas « cet
# hote-la repond-il ? ». Un endpoint d'Etalab injoignable a ainsi fait echouer
# la CI de `main` le 27 aout 2026, garde-fou franchi.
#
# Ce qui suit distingue les deux echecs que `telecharger()` sait desormais
# nommer :
#
# * `sommier_reseau_indisponible` - hote injoignable, delai depasse, 5xx : une
#   panne d'infrastructure, rien de casse ici. Le test se saute.
# * `sommier_ressource_absente` - 404, fichier vide : le fichier n'est pas la
#   ou on le cherche, donc l'URL qu'on batit est fausse ou la source a bouge.
#   Le test echoue, et il le doit.
#
# Sauter les deux rendrait un vert trompeur le jour ou la source deplacerait
# ses fichiers ; echouer sur les deux rend la CI otage d'un serveur tiers.
sauter_si_source_indisponible <- function(expr) {
  tryCatch(
    expr,
    sommier_reseau_indisponible = function(condition) {
      testthat::skip(paste0("source distante injoignable : ",
                            conditionMessage(condition)))
    }
  )
}
