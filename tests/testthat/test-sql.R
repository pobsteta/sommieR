# Le SQL n'est pas execute ici (aucune base n'est garantie disponible) ; ces
# tests verifient que les fichiers livres portent bien les garanties que la
# documentation leur prete.
lire_sql <- function(fichier) {
  chemin <- system.file("sql", fichier, package = "sommieR")
  expect_true(chemin != "", label = paste("presence de", fichier))
  paste(readLines(chemin, warn = FALSE), collapse = "\n")
}

test_that("le schema impose l'append-only par la base", {
  sql <- lire_sql("001_schema.sql")
  expect_match(sql, "CREATE TRIGGER sommier_immutable\\b")
  expect_match(sql, "BEFORE UPDATE OR DELETE ON entree_sommier")
  # Un trigger FOR EACH ROW ne se declenche pas sur TRUNCATE : sans ce second
  # declencheur, le registre entier resterait effacable d'une commande.
  expect_match(sql, "BEFORE TRUNCATE ON entree_sommier")
  expect_match(sql, "FOR EACH STATEMENT")
})

test_that("le schema porte les contraintes d'unicite de la chaine", {
  sql <- lire_sql("001_schema.sql")
  expect_match(sql, "UNIQUE \\(foret_id, seq\\)")
  expect_match(sql, "UNIQUE \\(foret_id, hash\\)")
  expect_match(sql, "octet_length\\(hash\\) = 32")
  expect_match(sql, "octet_length\\(hash_prev\\) = 32")
})

test_that("visa et ancrage sont eux aussi immuables", {
  # Sans cela, une attestation pourrait etre antidatee apres coup.
  sql <- lire_sql("001_schema.sql")
  expect_match(sql, "CREATE TRIGGER visa_immutable")
  expect_match(sql, "CREATE TRIGGER ancrage_immutable")
})

test_that("la filiation des unites de gestion sait representer une fusion", {
  sql <- lire_sql("001_schema.sql")
  expect_match(sql, "CREATE TABLE IF NOT EXISTS ug_filiation")
  expect_match(sql, "type_filiation IN \\('scission', 'fusion'\\)")
})

test_that("la balance est une vue, jamais une colonne stockee", {
  sql <- lire_sql("002_vues.sql")
  expect_match(sql, "CREATE OR REPLACE VIEW v_balance_possibilite")
  expect_match(sql, "balance_cumulee_m3")
  # La jointure part de `exercice` : un exercice sans coupe pese pour un
  # deficit egal a toute sa possibilite, il ne doit pas disparaitre.
  expect_match(sql, "FROM exercice x")
  expect_match(sql, "LEFT JOIN martele")
  # coupe_realisee hors du martele, sinon double imputation.
  expect_match(sql, "'martelage', 'produit_accidentel', 'bois_delivre'")
})

test_that("les vues metier excluent les entrees corrigees", {
  sql <- lire_sql("002_vues.sql")
  expect_match(sql, "CREATE OR REPLACE VIEW v_entree_courante")
  expect_match(sql, "WHERE NOT EXISTS")
  expect_match(sql, "FROM v_entree_courante e\\s*\\n\\s*WHERE e\\.registre = 5")
})
