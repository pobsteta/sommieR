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
  expect_match(r$anomalies$message, "et non")
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

# ---------------------------------------------------------------------------
# Format 2 : le visa porte son certificat, donc se verifie seul
# ---------------------------------------------------------------------------

# Un visa reel : signature detachee sur la tete, et le certificat qui permet
# de la confronter. C'est ce que recoit un tiers - une commune, un CRPF - qui
# n'a que le manifeste et ses ancres.
visa_signe <- function(chaine, seq = 4L, id = "vvvvvvvv-0000-4000-8000-000000000009") {
  materiel <- signataire_avec_certificat("maire-01")
  hash <- chaine[[seq]]$hash
  data.frame(
    id = id, exercice = 2026, seq_tete = seq,
    hash_tete = empreinte_hex(hash), autorite = "commune",
    signataire = '{"sub":"maire-01"}',
    signature_jws = jws_signer_detache(hash, materiel$signataire),
    certificat = empreinte_hex(materiel$certificat),
    date_visa = "2026-08-18T10:00:00Z", stringsAsFactors = FALSE
  )
}

test_that("la signature d'un visa se verifie sous le certificat qu'il porte", {
  ch <- chaine_test(4L)
  r <- sommier_verifier_manifeste(manifeste_test(ch, visas = visa_signe(ch)))
  expect_true(r$valide)
  # Aucune reserve sur la signature : elle a bien ete verifiee.
  expect_false(any(grepl("sans certificat", r$reserves)))
})

test_that("une signature de visa alteree est signalee", {
  ch <- chaine_test(4L)
  visa <- visa_signe(ch)
  # Un octet de la signature suffit ; la charge, elle, n'est pas dans le jeton.
  parties <- strsplit(visa$signature_jws, "..", fixed = TRUE)[[1]]
  brute <- base64url_decoder(parties[[2L]])
  brute[[1L]] <- as.raw(bitwXor(as.integer(brute[[1L]]), 1L))
  visa$signature_jws <- paste0(parties[[1L]], "..", base64url_encoder(brute))

  r <- sommier_verifier_manifeste(manifeste_test(ch, visas = visa))
  expect_false(r$valide)
  expect_equal(r$anomalies$type, "visa_signature")
})

test_that("un visa sans certificat laisse une reserve, non une anomalie", {
  # Il n'y a rien de faux a ne pas pouvoir verifier : le dire en reserve, et
  # non en anomalie, est la difference entre « je n'ai pas pu » et « c'est
  # faux ».
  ch <- chaine_test(4L)
  visa <- visa_signe(ch)
  visa$certificat <- NA_character_
  r <- sommier_verifier_manifeste(manifeste_test(ch, visas = visa))
  expect_true(r$valide)
  expect_match(paste(r$reserves, collapse = " ; "), "sans certificat")
})

test_that("la revocation non verifiee est dite, toujours", {
  r <- sommier_verifier_manifeste(manifeste_test())
  expect_true(r$valide)
  expect_match(paste(r$reserves, collapse = " ; "), "[Rr]evocation")
})

test_that("un manifeste du format precedent reste verifiable", {
  # Un manifeste est un export destine a etre verifie des annees plus tard :
  # refuser l'ancien format annulerait cela meme qu'il promet.
  expect_true(
    sommier_verifier_manifeste(
      manifeste_test(format = "sommier-manifeste-1")
    )$valide
  )
  expect_error(sommier_verifier_manifeste(manifeste_test(format = "autre")),
               "Format de manifeste inconnu")
})

test_that("un destinataire n'ayant que le manifeste et ses ancres verifie tout", {
  # Le critere du lot : ni reseau, ni base, ni cle a se procurer.
  ch <- chaine_test(4L)
  visa <- visa_signe(ch)
  hash <- ch[[4]]$hash
  visa$tst_rfc3161 <- empreinte_hex(
    tsa_horodater(hash, "https://tsa.test", tsa_simulee())
  )
  chemin <- manifeste_test(ch, visas = visa)

  r <- sommier_verifier_manifeste(chemin, ancres = list(racine_tsa_de_test()))
  expect_true(r$valide)
  # Rien ne reste en suspens, hors la revocation qui exige le reseau.
  expect_false(any(grepl("ancre", r$reserves)))
  expect_false(any(grepl("sans certificat", r$reserves)))

  # Sans ancre, le meme manifeste reste valide, avec une reserve.
  sans <- sommier_verifier_manifeste(chemin)
  expect_true(sans$valide)
  expect_match(paste(sans$reserves, collapse = " ; "), "aucune ancre")
})
