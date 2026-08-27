# Manifeste construit a la main : la verification hors ligne doit fonctionner
# sans base, c'est precisement sa raison d'etre.
manifeste_test <- function(entrees = chaine_test(4L), visas = NULL,
                           ancrages = NULL, format = SOMMIER_VERSION_MANIFESTE,
                           version_chaine = SOMMIER_VERSION_CHAINE) {
  chemin <- withr::local_tempfile(fileext = ".json", .local_envir = parent.frame())
  df <- entrees_en_data_frame(entrees)
  writeLines(jsonlite::toJSON(list(
    format         = format,
    version_chaine = version_chaine,
    genere_le      = "2026-08-18T10:00:00Z",
    foret          = list(id = FORET_TEST, nom = "Foret test", regime = "communal"),
    hash_genese    = empreinte_hex(sommier_empreinte_genese(FORET_TEST)),
    entrees        = df,
    visas          = visas %||% data.frame(),
    ancrages       = ancrages %||% data.frame()
  ), auto_unbox = TRUE, null = "null", na = "null", dataframe = "rows"), chemin)
  chemin
}

`%||%` <- function(x, y) if (is.null(x)) y else x

test_that("un manifeste intact se verifie hors ligne", {
  expect_true(sommier_verifier_manifeste(manifeste_test())$valide)
})

test_that("un manifeste altere est detecte", {
  chemin <- manifeste_test()
  # Le payload voyage comme chaine JSON dans le manifeste : ses guillemets y
  # sont echappes, l'alteration doit viser cette forme-la.
  contenu <- readLines(chemin, warn = FALSE)
  altere <- sub('\\"volume_m3\\":300', '\\"volume_m3\\":1', contenu, fixed = TRUE)
  expect_false(identical(contenu, altere), label = "l'alteration a bien porte")
  writeLines(altere, chemin)
  r <- sommier_verifier_manifeste(chemin)
  expect_false(r$valide)
  expect_true("empreinte_invalide" %in% r$anomalies$type)
})

test_that("un visa concordant est accepte", {
  ch <- chaine_test(4L)
  visa <- data.frame(
    id = "vvvvvvvv-0000-4000-8000-000000000001", exercice = 2026,
    seq_tete = 4, hash_tete = empreinte_hex(ch[[4]]$hash),
    autorite = "commune", signataire = '{"sub":"maire"}',
    signature_jws = "jws", date_visa = "2026-08-18T10:00:00Z",
    stringsAsFactors = FALSE
  )
  expect_true(sommier_verifier_manifeste(manifeste_test(ch, visas = visa))$valide)
})

test_that("un visa attestant une empreinte etrangere est signale", {
  # Cas d'une attestation rapportee d'une autre chaine.
  ch <- chaine_test(4L)
  visa <- data.frame(
    id = "vvvvvvvv-0000-4000-8000-000000000001", exercice = 2026,
    seq_tete = 4, hash_tete = strrep("ab", 32L),
    autorite = "commune", signataire = '{"sub":"maire"}',
    signature_jws = "jws", date_visa = "2026-08-18T10:00:00Z",
    stringsAsFactors = FALSE
  )
  r <- sommier_verifier_manifeste(manifeste_test(ch, visas = visa))
  expect_false(r$valide)
  expect_equal(r$anomalies$type, "visa_orphelin")
})

test_that("un visa attestant une sequence absente est signale", {
  ch <- chaine_test(4L)
  visa <- data.frame(
    id = "vvvvvvvv-0000-4000-8000-000000000001", exercice = 2026,
    seq_tete = 99, hash_tete = strrep("ab", 32L),
    autorite = "commune", signataire = '{"sub":"maire"}',
    signature_jws = "jws", date_visa = "2026-08-18T10:00:00Z",
    stringsAsFactors = FALSE
  )
  r <- sommier_verifier_manifeste(manifeste_test(ch, visas = visa))
  expect_false(r$valide)
  expect_match(r$anomalies$message, "absente de la chaine")
})

test_that("un ancrage discordant est signale", {
  ch <- chaine_test(4L)
  ancrage <- data.frame(
    id = "nnnnnnnn-0000-4000-8000-000000000001", seq_tete = 2,
    hash_tete = strrep("cd", 32L),
    date_ancrage = "2026-08-18T10:00:00Z", stringsAsFactors = FALSE
  )
  r <- sommier_verifier_manifeste(manifeste_test(ch, ancrages = ancrage))
  expect_false(r$valide)
  expect_equal(r$anomalies$type, "ancrage_orphelin")
})

test_that("un jeton obtenu pour autre chose est signale", {
  # L'ancrage declare la bonne empreinte, et son jeton en atteste une autre :
  # la colonne dit vrai, l'autorite dit autre chose. Un booleen « horodate »
  # comptait ce cas comme bon.
  ch <- chaine_test(4L)
  ancrage <- data.frame(
    id = "nnnnnnnn-0000-4000-8000-000000000002", seq_tete = 2,
    hash_tete = empreinte_hex(ch[[2]]$hash),
    tst_rfc3161 = JETON_TSA_FIGE_HEX(),
    date_ancrage = "2026-08-18T10:00:00Z", stringsAsFactors = FALSE
  )
  r <- sommier_verifier_manifeste(manifeste_test(ch, ancrages = ancrage))
  expect_false(r$valide)
  expect_equal(r$anomalies$type, "ancrage_horodatage")
  expect_match(r$anomalies$message, "obtenu pour autre chose")
})

test_that("un jeton illisible est signale plutot qu'ignore", {
  ch <- chaine_test(4L)
  ancrage <- data.frame(
    id = "nnnnnnnn-0000-4000-8000-000000000003", seq_tete = 2,
    hash_tete = empreinte_hex(ch[[2]]$hash), tst_rfc3161 = "00",
    date_ancrage = "2026-08-18T10:00:00Z", stringsAsFactors = FALSE
  )
  r <- sommier_verifier_manifeste(manifeste_test(ch, ancrages = ancrage))
  expect_false(r$valide)
  expect_equal(r$anomalies$type, "ancrage_horodatage")
  expect_match(r$anomalies$message, "illisible")
})

test_that("un format ou une version de chaine inconnus sont refuses", {
  expect_error(sommier_verifier_manifeste(manifeste_test(format = "autre-chose")),
               "Format de manifeste inconnu")
  expect_error(
    sommier_verifier_manifeste(manifeste_test(version_chaine = "sommier-chaine-0")),
    "incompatible"
  )
})
