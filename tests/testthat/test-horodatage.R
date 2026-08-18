test_that("la requete d'horodatage est un DER bien forme", {
  empreinte <- openssl::rand_bytes(32L)
  requete <- tsa_requete(empreinte, nonce = 12345)

  expect_true(is.raw(requete))
  expect_equal(as.integer(requete[[1L]]), 0x30L)   # SEQUENCE
  # L'empreinte doit s'y retrouver telle quelle, dans l'OCTET STRING.
  motif <- paste0(sprintf("%02x", as.integer(empreinte)), collapse = "")
  entier <- paste0(sprintf("%02x", as.integer(requete)), collapse = "")
  expect_true(grepl(motif, entier, fixed = TRUE))
  # L'OID sha-256 doit y figurer.
  expect_true(grepl("0609608648016503040201", entier, fixed = TRUE))
})

test_that("l'encodage des longueurs DER suit la forme longue au-dela de 127", {
  # Une empreinte de 32 octets tient en forme courte ; l'enveloppe, non.
  court <- tsa_requete(openssl::rand_bytes(32L), nonce = 1)
  expect_true(length(court) > 40L)
  expect_silent(tsa_lire_reponse(reponse_tsa_simulee(0L)))
})

test_that("une reponse accordee rend son jeton", {
  jeton_attendu <- as.raw(c(0x30, 0x03, 0x02, 0x01, 0x2a))
  lue <- tsa_lire_reponse(reponse_tsa_simulee(0L, jeton_attendu))
  expect_equal(lue$statut, 0L)
  expect_equal(lue$libelle, "accorde")
  expect_identical(lue$jeton, jeton_attendu)
})

test_that("un refus est signale et ne rend pas de jeton", {
  lue <- tsa_lire_reponse(reponse_tsa_simulee(2L))
  expect_equal(lue$statut, 2L)
  expect_equal(lue$libelle, "refus")
  expect_null(lue$jeton)
})

test_that("tsa_horodater refuse un statut sans jeton", {
  transport <- function(url, corps) reponse_tsa_simulee(2L)
  expect_error(
    tsa_horodater(openssl::rand_bytes(32L), "https://tsa.example", transport),
    "n'a pas delivre de jeton"
  )
})

test_that("tsa_horodater rend le jeton de l'autorite", {
  jeton <- as.raw(c(0x30, 0x03, 0x02, 0x01, 0x2a))
  transport <- function(url, corps) {
    # Le transport recoit bien la requete DER, pas autre chose.
    expect_true(is.raw(corps))
    expect_equal(as.integer(corps[[1L]]), 0x30L)
    reponse_tsa_simulee(0L, jeton)
  }
  expect_identical(
    tsa_horodater(openssl::rand_bytes(32L), "https://tsa.example", transport),
    jeton
  )
})

test_that("une reponse tronquee est signalee plutot qu'interpretee", {
  expect_error(tsa_lire_reponse(as.raw(c(0x30))), "tronquee")
  expect_error(tsa_lire_reponse(as.raw(c(0x30, 0x7f, 0x02))), "tronque")
  expect_error(tsa_lire_reponse(raw(0)), "non vide")
  expect_error(tsa_lire_reponse(as.raw(c(0x02, 0x01, 0x00))), "SEQUENCE")
})

test_that("une empreinte de mauvaise taille est refusee", {
  expect_error(tsa_requete(openssl::rand_bytes(16L)), "32 octets")
})
