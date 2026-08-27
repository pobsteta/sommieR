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
  empreinte <- openssl::rand_bytes(32L)
  autorite <- tsa_simulee()
  transport <- function(url, corps) {
    # Le transport recoit bien la requete DER, pas autre chose.
    expect_true(is.raw(corps))
    expect_equal(as.integer(corps[[1L]]), 0x30L)
    autorite(url, corps)
  }
  jeton <- tsa_horodater(empreinte, "https://tsa.example", transport)
  expect_true(is.raw(jeton))
  # Le jeton rendu atteste bien ce qui a ete envoye.
  expect_identical(tsa_lire_jeton(jeton)$empreinte, empreinte)
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

# ---------------------------------------------------------------------------
# Contenu du jeton
# ---------------------------------------------------------------------------

test_that("un vrai jeton dit ce qu'il atteste", {
  # Le jeton fige du depot, dont fixtures/PROVENANCE.md donne les valeurs.
  lu <- tsa_lire_jeton(tsa_lire_reponse(REPONSE_TSA_FIGEE())$jeton)

  expect_s3_class(lu, "sommier_jeton_tsa")
  expect_equal(lu$version, 1L)
  expect_equal(lu$algorithme, "sha256")
  expect_equal(empreinte_hex(lu$empreinte), EMPREINTE_TSA_FIGEE)
  expect_equal(lu$serie, "11")
  expect_equal(lu$nonce, "11f71fb04cb")
  expect_equal(lu$politique, "1.2.3.4.1")
  expect_equal(format(lu$date, "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
               "2026-08-27T06:04:56Z")
})

test_that("le nonce lu est celui que sommieR avait encode", {
  # La requete figee vient de tsa_requete() : le nonce doit y revenir tel quel.
  lu <- tsa_lire_jeton(tsa_lire_reponse(REPONSE_TSA_FIGEE())$jeton)
  expect_equal(lu$nonce, nombre_vers_hex(NONCE_TSA_FIGE))
})

test_that("un jeton obtenu pour autre chose est refuse", {
  transport <- function(url, corps) REPONSE_TSA_FIGEE()
  expect_error(
    tsa_horodater(openssl::rand_bytes(32L), "https://tsa.example", transport,
                  nonce = NONCE_TSA_FIGE),
    "alors que"
  )
})

test_that("un nonce different est refuse : la reponse ne repond pas", {
  transport <- function(url, corps) REPONSE_TSA_FIGEE()
  expect_error(
    tsa_horodater(empreinte_depuis_hex(EMPREINTE_TSA_FIGEE),
                  "https://tsa.example", transport, nonce = 42),
    "Nonce rendu"
  )
})

test_that("le meme nonce et la meme empreinte passent", {
  transport <- function(url, corps) REPONSE_TSA_FIGEE()
  expect_silent(
    tsa_horodater(empreinte_depuis_hex(EMPREINTE_TSA_FIGEE),
                  "https://tsa.example", transport, nonce = NONCE_TSA_FIGE)
  )
})

test_that("ce qui n'est pas un TimeStampToken est signale", {
  expect_error(tsa_lire_jeton(as.raw(c(0x30, 0x03, 0x02, 0x01, 0x2a))),
               "SignedData")
  expect_error(tsa_lire_jeton(raw(0)), "non vide")
  expect_error(tsa_lire_jeton("pas du raw"), "raw")
})

test_that("un OID se lit en notation pointee", {
  # 1.2.840.113549.1.7.2 : les composantes au-dela de 127 tiennent sur
  # plusieurs octets, c'est le cas qui distingue un decodeur d'un raccourci.
  octets <- as.raw(c(0x06, 0x09, 0x2a, 0x86, 0x48, 0x86, 0xf7, 0x0d, 0x01,
                     0x07, 0x02))
  expect_equal(der_oid_texte(octets, der_lire(octets, 1L)),
               "1.2.840.113549.1.7.2")
})

test_that("un entier DER se rend sans son zero de tete", {
  # DER prefixe d'un zero les entiers dont le premier octet depasse 0x7f ;
  # ce zero n'appartient pas a la valeur.
  octets <- as.raw(c(0x02, 0x02, 0x00, 0xff))
  expect_equal(der_entier_hex(octets, der_lire(octets, 1L)), "ff")
})

test_that("un entier de plus de quatre octets ne deborde pas", {
  # Un nonce de six octets passerait a NA si l'accumulation restait entiere.
  octets <- as.raw(c(0x02, 0x06, 0x01, 0x1f, 0x71, 0xfb, 0x04, 0xcb))
  expect_equal(der_entier_valeur(octets, der_lire(octets, 1L)), 1234567890123)
})

test_that("un genTime hors format est refuse plutot qu'interprete", {
  heure_locale <- charToRaw("20260827060456+0200")
  octets <- c(as.raw(c(0x18, length(heure_locale))), heure_locale)
  expect_error(der_temps_generalise(octets, der_lire(octets, 1L)),
               "RFC 3161")
})
