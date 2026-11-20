# Garde-fou de version (mission 029) : on exécute le script même de la CI
# (.github/scripts/verifier-version.sh) sur des fichiers fabriqués.

script <- normalizePath(
  testthat::test_path("..", "..", ".github", "scripts", "verifier-version.sh"),
  mustWork = FALSE
)

# Dans le dépôt source (présence de pilotage/), l'absence du script est un échec
# explicite qui arrête le test, pas un saut. Seule la copie installée du paquet
# (couverture, R CMD check : .github et pilotage exclus) saute.
exiger_script <- function() {
  if (file.exists(script)) return(invisible(TRUE))
  racine <- dirname(dirname(dirname(script)))
  if (dir.exists(file.path(racine, "pilotage"))) {
    stop("script de version absent : ", script, call. = FALSE)
  }
  skip("script de version absent (paquet installé, hors dépôt source)")
}

lancer <- function(fichiers) {
  sortie <- suppressWarnings(system2(
    "bash", c(shQuote(script), shQuote(fichiers)),
    stdout = TRUE, stderr = TRUE
  ))
  statut <- attr(sortie, "status")
  list(code = if (is.null(statut)) 0L else statut,
       sortie = paste(sortie, collapse = "\n"))
}

verifier <- function(version, news_version = version, cff_version = version,
                     date_news = "2026-11-20") {
  exiger_script()
  skip_if(Sys.which("bash") == "", "bash absent")
  d <- tempfile("version-")
  dir.create(d)
  on.exit(unlink(d, recursive = TRUE), add = TRUE)
  writeLines(c("Package: sommieR", paste("Version:", version)), file.path(d, "DESCRIPTION"))
  writeLines(sprintf("# sommieR %s (%s)", news_version, date_news), file.path(d, "NEWS.md"))
  writeLines(sprintf('version: "%s"', cff_version), file.path(d, "CITATION.cff"))
  lancer(file.path(d, c("DESCRIPTION", "NEWS.md", "CITATION.cff")))
}

test_that("2026.11.1 daté de novembre 2026 passe", {
  expect_identical(verifier("2026.11.1")$code, 0L)
})

test_that("un mois à un chiffre passe sans zéro en tête, échoue avec", {
  expect_identical(verifier("2026.1.1", date_news = "2026-01-15")$code, 0L)
  r <- verifier("2026.01.1", date_news = "2026-01-15")
  expect_identical(r$code, 1L)
  expect_match(r$sortie, "mal formée")
})

test_that("une date NEWS d'un autre mois ou d'une autre année échoue", {
  expect_identical(verifier("2026.11.1", date_news = "2026-12-01")$code, 1L)
  expect_identical(verifier("2026.11.1", date_news = "2025-11-20")$code, 1L)
  expect_match(verifier("2026.11.1", date_news = "2026-10-31")$sortie, "attendu 2026.10.N")
})

test_that("DESCRIPTION, NEWS et CITATION désalignés échouent", {
  expect_identical(verifier("2026.11.1", news_version = "2026.11.2")$code, 1L)
  expect_identical(verifier("2026.11.1", cff_version = "0.44.0")$code, 1L)
})

test_that("la version de dev .9000 n'est pas contrôlée", {
  expect_identical(verifier("2026.11.2.9000", news_version = "2026.11.1")$code, 0L)
})

test_that("une version 0.x ne demande que l'alignement", {
  expect_identical(verifier("0.44.0", date_news = "2026-10-01")$code, 0L)
})

test_that("l'ordre des versions reste croissant", {
  expect_gt(package_version("2026.11.1"), package_version("0.44.0"))
  expect_gt(package_version("2026.12.1"), package_version("2026.11.9"))
  expect_gt(package_version("2027.1.1"), package_version("2026.12.3"))
})

test_that("DESCRIPTION, NEWS et CITATION du dépôt sont alignés", {
  racine <- dirname(dirname(dirname(script)))
  exiger_script()
  skip_if(!file.exists(file.path(racine, "CITATION.cff")), "dépôt source absent")
  r <- lancer(file.path(racine, c("DESCRIPTION", "NEWS.md", "CITATION.cff")))
  expect_identical(r$code, 0L, info = r$sortie)
})
