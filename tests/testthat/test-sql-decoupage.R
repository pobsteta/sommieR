test_that("un script simple se decoupe sur les points-virgules", {
  expect_equal(decouper_sql("SELECT 1; SELECT 2;"), c("SELECT 1", "SELECT 2"))
  expect_equal(decouper_sql("SELECT 1"), "SELECT 1")
  expect_equal(decouper_sql(c("SELECT a;", "SELECT b;")), c("SELECT a", "SELECT b"))
})

test_that("les points-virgules vides ne produisent pas d'instruction", {
  # Un intervalle `debut:(i-1)` compterait a rebours et rendrait du texte
  # inverse : le cas doit etre ecarte, pas rendu.
  expect_equal(decouper_sql("SELECT 1;;SELECT 2;"), c("SELECT 1", "SELECT 2"))
  expect_equal(decouper_sql(";;;"), character(0))
  expect_equal(decouper_sql("-- rien a faire\n"), character(0))
})

test_that("un point-virgule en commentaire ne coupe pas", {
  expect_length(decouper_sql("-- commentaire; piege\nSELECT 1;"), 1L)
  expect_length(decouper_sql("/* bloc; piege */ SELECT 1;"), 1L)
  # PostgreSQL imbrique les commentaires de bloc, contrairement au C.
  expect_length(decouper_sql("/* a /* imbrique; */ b */ SELECT 1;"), 1L)
})

test_that("un point-virgule dans une chaine ne coupe pas", {
  expect_length(decouper_sql("SELECT 'a;b';"), 1L)
  # Une apostrophe doublee reste dans la chaine et ne la ferme pas.
  expect_length(decouper_sql("SELECT 'l''index; ici';"), 1L)
  expect_length(decouper_sql('SELECT "colonne;bizarre";'), 1L)
})

test_that("un corps de fonction delimite par le dollar reste entier", {
  # Le cas qui a motive ce decoupage : sans lui, le corps plpgsql serait
  # tranche sur ses propres points-virgules.
  script <- paste(
    "CREATE FUNCTION f() RETURNS trigger AS $$",
    "BEGIN",
    "  RAISE EXCEPTION 'non';",
    "  RETURN NEW;",
    "END;",
    "$$ LANGUAGE plpgsql;",
    "CREATE TRIGGER t BEFORE UPDATE ON x",
    "  FOR EACH ROW EXECUTE FUNCTION f();",
    sep = "\n"
  )
  instructions <- decouper_sql(script)
  expect_length(instructions, 2L)
  expect_match(instructions[[1]], "LANGUAGE plpgsql$")
  expect_match(instructions[[2]], "^CREATE TRIGGER")
})

test_that("un bloc dollar nomme est reconnu", {
  script <- "CREATE FUNCTION g() RETURNS int AS $corps$ BEGIN RETURN 1; END; $corps$ LANGUAGE plpgsql;\nSELECT 1;"
  expect_length(decouper_sql(script), 2L)
})

test_that("les scripts livres se decoupent en instructions autonomes", {
  for (fichier in c("001_schema.sql", "002_vues.sql")) {
    chemin <- system.file("sql", fichier, package = "sommieR")
    skip_if(chemin == "", paste("fichier absent :", fichier))
    instructions <- decouper_sql(readLines(chemin, warn = FALSE, encoding = "UTF-8"))
    expect_gt(length(instructions), 5L)
    # Aucune instruction ne doit etre vide : le pilote la rejetterait.
    expect_true(all(nzchar(trimws(instructions))))
  }
})
