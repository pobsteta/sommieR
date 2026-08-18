cle_test <- function() openssl::rsa_keygen(2048L)

test_that("base64url fait l'aller-retour sans remplissage", {
  for (n in 1:8) {
    octets <- openssl::rand_bytes(n)
    encode <- base64url_encoder(octets)
    expect_false(grepl("=", encode, fixed = TRUE))
    expect_false(grepl("[+/]", encode))
    expect_identical(base64url_decoder(encode), octets)
  }
})

test_that("une signature detachee se verifie", {
  cle <- cle_test()
  s <- signataire_cle(cle, claims = list(sub = "agent-01", name = "Maire"))
  charge <- openssl::rand_bytes(32L)
  jws <- jws_signer_detache(charge, s)

  # Charge detachee : le jeton porte deux points consecutifs a sa place.
  expect_match(jws, "^[A-Za-z0-9_-]+\\.\\.[A-Za-z0-9_-]+$")
  expect_true(jws_verifier_detache(jws, charge, cle$pubkey))
})

test_that("une charge alteree invalide la signature", {
  cle <- cle_test()
  s <- signataire_cle(cle, claims = list(sub = "agent-01"))
  charge <- openssl::rand_bytes(32L)
  jws <- jws_signer_detache(charge, s)

  autre <- charge
  autre[[1L]] <- as.raw(bitwXor(as.integer(autre[[1L]]), 1L))
  expect_false(jws_verifier_detache(jws, autre, cle$pubkey))
})

test_that("une autre cle ne valide pas la signature", {
  cle <- cle_test()
  s <- signataire_cle(cle, claims = list(sub = "agent-01"))
  charge <- openssl::rand_bytes(32L)
  jws <- jws_signer_detache(charge, s)
  expect_false(jws_verifier_detache(jws, charge, cle_test()$pubkey))
})

test_that("l'en-tete declare bien une charge non encodee", {
  # RFC 7797 : sans `b64: false` et `crit`, un verificateur conforme
  # interpreterait la charge comme encodee en base64url.
  cle <- cle_test()
  s <- signataire_cle(cle, claims = list(sub = "agent-01"), kid = "cle-2026")
  jws <- jws_signer_detache(openssl::rand_bytes(32L), s)
  entete <- jsonlite::fromJSON(
    rawToChar(base64url_decoder(strsplit(jws, "..", fixed = TRUE)[[1]][[1]])),
    simplifyVector = FALSE
  )
  expect_equal(entete$alg, "RS256")
  expect_false(entete$b64)
  expect_equal(entete$crit, list("b64"))
  expect_equal(entete$kid, "cle-2026")
})

test_that("un en-tete sans b64 false est refuse", {
  cle <- cle_test()
  charge <- openssl::rand_bytes(32L)
  entete <- base64url_encoder('{"alg":"RS256"}')
  faux <- paste0(entete, "..", base64url_encoder(openssl::rand_bytes(256L)))
  expect_error(jws_verifier_detache(faux, charge, cle$pubkey), "b64")
})

test_that("un signataire sans identite est refuse", {
  # Un visa dont on ignore qui l'a pose n'est pas opposable.
  expect_error(sommier_signataire(list(), function(x) x), "sub")
  expect_error(sommier_signataire(list(sub = "a"), "pas une fonction"),
               "fonction")
  expect_error(
    sommier_signataire(list(sub = "a"), function(x) x, alg = "ES256"),
    "alg"
  )
})

test_that("les claims d'un jeton OIDC sont extraits", {
  charge <- base64url_encoder('{"sub":"u-42","given_name":"Jean","siret":"123"}')
  jeton <- paste0(base64url_encoder('{"alg":"RS256"}'), ".", charge, ".sig")
  claims <- jwt_claims(jeton)
  expect_equal(claims$sub, "u-42")

  s <- signataire_keycloak(jeton, cle_test())
  expect_equal(s$claims$sub, "u-42")
  expect_equal(s$claims$given_name, "Jean")
  expect_equal(s$claims$siret, "123")
  # Les claims non retenus ne sont pas archives.
  expect_null(s$claims$aud)
})

test_that("un jeton malforme ou sans sub est refuse", {
  expect_error(jwt_claims("pas-un-jwt"), "malforme")
  jeton <- paste0(base64url_encoder('{"alg":"RS256"}'), ".",
                  base64url_encoder('{"nom":"sans sub"}'), ".sig")
  expect_error(signataire_keycloak(jeton, cle_test()), "sub")
})
