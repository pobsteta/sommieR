# Contrat sommieR -> nemeton (mission 014).
#
# Ce que sommieR lit dans nemeton
# -------------------------------
# sommieR ne dépend de nemeton qu'en Suggests (Remotes: pobsteta/nemeton) et
# n'en utilise qu'un objet, dans `sommier_reference_ifn()` (R/nemeton.R) :
#
#   nemeton::ifn_prelevement_essence_ser(ser = <code SER>)
#
# La fonction est appelée avec l'argument nommé `ser`, et le code lit trois
# colonnes de la table rendue : `niveau` (filtré sur "ser"),
# `prelev_ha_an_maille` (sommée, non NA) et `millesime` (affiché dans la
# source). Ce test verrouille ces trois points : une release de nemeton qui
# renomme la fonction, retire `ser`, ou change ces colonnes fait échouer la CI
# ici, pas chez l'utilisateur. Changer ces tables = changer le contrat :
# prévenir nemeton.
#
# Hors de ce test : `sommier_lire_indices_nemeton()` lit le fichier
# `data/indicators.parquet` d'un projet nemeton (colonnes `ug_id`, `label`,
# `surface_m2`, `indicateur_p1_volume`, `indicateur_t3_coupes_rases`,
# `cadastral_refs`), sans appeler nemeton : c'est un format de fichier, que
# test-nemeton.R exerce sur un parquet d'essai.
#
# La CI installe nemeton et exige qu'il se charge (r.yml, « Vérifier que les
# paquets facultatifs se chargent ») : le saut ci-dessous ne peut donc pas
# être silencieux là-bas.

# Fonctions : noms des arguments, dans l'ordre (formals()).
.contrat_fonctions <- list(
  ifn_prelevement_essence_ser = c("espar", "ser", "greco", "niveau")
)

# Colonnes de la table rendue que sommieR lit : nom et classe.
.contrat_colonnes <- list(
  niveau              = "character",
  prelev_ha_an_maille = "numeric",
  millesime           = "character"
)

test_that("le contrat nemeton compte un objet, sans doublon", {
  expect_length(names(.contrat_fonctions), 1L)
  expect_false(anyDuplicated(names(.contrat_fonctions)) > 0L)
})

test_that("chaque fonction de nemeton utilisée existe, exportée, avec ses arguments", {
  skip_if_not_installed("nemeton")
  ns <- asNamespace("nemeton")
  for (nom in names(.contrat_fonctions)) {
    expect_true(exists(nom, envir = ns, inherits = FALSE),
                info = paste("objet absent :", nom))
    obj <- get(nom, envir = ns, inherits = FALSE)
    expect_true(is.function(obj), info = paste("pas une fonction :", nom))
    expect_true(nom %in% getNamespaceExports("nemeton"),
                info = paste("non exporté :", nom))
    expect_identical(names(formals(obj)), .contrat_fonctions[[nom]],
                     info = paste("signature changée :", nom))
  }
})

test_that("la table rendue porte les colonnes que sommieR lit", {
  skip_if_not_installed("nemeton")
  table <- nemeton::ifn_prelevement_essence_ser(ser = "B70")
  expect_s3_class(table, "data.frame")
  expect_gt(nrow(table), 0L)
  for (col in names(.contrat_colonnes)) {
    expect_true(col %in% names(table), info = paste("colonne absente :", col))
    expect_true(methods::is(table[[col]], .contrat_colonnes[[col]]),
                info = paste("type changé :", col))
  }
  # Le filtre de sommier_reference_ifn() retient des lignes.
  expect_true("ser" %in% table$niveau)
  expect_true(any(!is.na(table$prelev_ha_an_maille[table$niveau == "ser"])))
})
