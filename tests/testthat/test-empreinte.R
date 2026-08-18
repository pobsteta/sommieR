test_that("la genese est le SHA-256 de l'identifiant de la foret", {
  attendu <- paste0(sprintf("%02x", as.integer(openssl::sha256(charToRaw(FORET_TEST)))),
                    collapse = "")
  expect_equal(empreinte_hex(sommier_empreinte_genese(FORET_TEST)), attendu)
  expect_length(sommier_empreinte_genese(FORET_TEST), 32L)
})

test_that("la genese normalise la casse de l'identifiant", {
  expect_identical(
    sommier_empreinte_genese(toupper(FORET_TEST)),
    sommier_empreinte_genese(FORET_TEST)
  )
})

test_that("l'empreinte est deterministe et longue de 32 octets", {
  e <- entree_test(1L)
  e$seq <- 1
  h1 <- sommier_empreinte(e, sommier_empreinte_genese(FORET_TEST))
  h2 <- sommier_empreinte(e, sommier_empreinte_genese(FORET_TEST))
  expect_identical(h1, h2)
  expect_length(h1, 32L)
})

test_that("l'empreinte couvre les metadonnees, pas seulement le payload", {
  # C'est la propriete qui permet a un tiers de verifier un export : si une
  # metadonnee restait hors chaine, on pourrait reaffecter une coupe a une
  # autre unite de gestion sans qu'aucune empreinte ne bouge.
  base <- entree_test(1L)
  base$seq <- 1
  reference <- sommier_empreinte(base, sommier_empreinte_genese(FORET_TEST))

  alterations <- list(
    seq            = 2,
    registre       = 6,
    ug_uuid        = UG_TEST,
    date_evenement = "2020-01-01",
    date_saisie    = "2020-01-01T00:00:00Z",
    auteur         = "quelqu-un-d-autre",
    ndp            = 2,
    corrige_id     = "cccccccc-dddd-4eee-8fff-000000000001",
    schema_version = "r5-9.9.9",
    foret_id       = "99999999-8888-4777-8666-555555555555"
  )

  for (champ in names(alterations)) {
    modifiee <- base
    modifiee[[champ]] <- alterations[[champ]]
    expect_false(
      identical(sommier_empreinte(modifiee, sommier_empreinte_genese(FORET_TEST)),
                reference),
      label = paste0("alteration de `", champ, "` detectee")
    )
  }
})

test_that("tous les champs annonces comme couverts le sont effectivement", {
  # Garde-fou : si un champ est ajoute a SOMMIER_CHAMPS_EMPREINTE sans etre
  # repris dans l'enregistrement canonique, ce test le signale.
  e <- entree_test(1L)
  e$seq <- 1
  canonique <- sommier_enregistrement_canonique(e)
  couverts <- setdiff(SOMMIER_CHAMPS_EMPREINTE, c("ug_uuid", "corrige_id"))
  expect_true(all(couverts %in% names(canonique)))
  expect_true("version_chaine" %in% names(canonique))
})

test_that("l'empreinte change avec l'empreinte precedente", {
  e <- entree_test(1L)
  e$seq <- 1
  a <- sommier_empreinte(e, sommier_empreinte_genese(FORET_TEST))
  b <- sommier_empreinte(e, as.raw(rep(0L, 32L)))
  expect_false(identical(a, b))
})

test_that("un enregistrement incomplet est refuse", {
  expect_error(sommier_enregistrement_canonique(list(foret_id = FORET_TEST)),
               "absent")
})

test_that("l'aller-retour hexadecimal est fidele", {
  h <- sommier_empreinte_genese(FORET_TEST)
  expect_identical(empreinte_depuis_hex(empreinte_hex(h)), h)
  expect_identical(empreinte_depuis_hex(toupper(empreinte_hex(h))), h)
  expect_error(empreinte_depuis_hex("abc"), "64 caracteres")
  expect_error(empreinte_depuis_hex(strrep("z", 64L)), "64 caracteres")
})

test_that("uuid_v4 produit des identifiants canoniques et distincts", {
  ids <- uuid_v4(50L)
  expect_length(unique(ids), 50L)
  expect_true(all(grepl(
    "^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$",
    ids
  )))
})
