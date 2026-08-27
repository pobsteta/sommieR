# Verification d'un jeton d'horodatage : qui atteste, et non plus seulement ce
# qui est atteste. Les autorites sont montees a la volee (helper-tsa.R) : les
# cas de refus se fabriquent, ils ne se simulent pas.

jeton_de_test <- function(empreinte, nom = "principale",
                          usage = "timeStamping", critique = TRUE) {
  tsa_horodater(empreinte, "https://tsa.test",
                tsa_simulee(nom, usage, critique))
}

test_that("un jeton rattache a son ancre est valide", {
  empreinte <- openssl::rand_bytes(32L)
  verdict <- tsa_verifier_jeton(jeton_de_test(empreinte), empreinte,
                                list(racine_tsa_de_test()))
  expect_s3_class(verdict, "sommier_verdict_tsa")
  expect_equal(verdict$etat, "valide")
  expect_length(verdict$motifs, 0L)
  expect_false(verdict$revocation_verifiee)
})

test_that("le meme jeton sans ancre est lu, non rattache - et non invalide", {
  # La distinction est le coeur du lot : dire « invalide » a une commune dont
  # le jeton est parfait mais dont on n'a pas la racine serait faux.
  empreinte <- openssl::rand_bytes(32L)
  verdict <- tsa_verifier_jeton(jeton_de_test(empreinte), empreinte)
  expect_equal(verdict$etat, "non_rattache")
  expect_match(verdict$motifs, "aucune ancre")
  # Le contenu, lui, a bien ete lu.
  expect_identical(verdict$jeton$empreinte, empreinte)
})

test_that("une ancre etrangere ne rattache pas le jeton", {
  empreinte <- openssl::rand_bytes(32L)
  verdict <- tsa_verifier_jeton(jeton_de_test(empreinte), empreinte,
                                list(racine_tsa_de_test("etrangere")))
  expect_equal(verdict$etat, "non_rattache")
  expect_match(verdict$motifs, "ne remonte a aucune ancre")
})

# Ce que la RFC 3161 (section 2.3) exige du certificat d'une autorite :
# l'usage `timeStamping`, LUI SEUL, et marque critique.
#
# Ces trois regles s'eprouvent sur le certificat plutot que sur un jeton, et
# non par commodite : `openssl ts` refuse lui-meme de signer avec un
# certificat non conforme (« invalid signer certificate purpose »). La
# contrefaçon n'est donc pas fabricable par cette voie - ce qui est une bonne
# nouvelle, et vaut d'etre consigne. Le predicat teste ici est exactement
# celui que consulte tsa_verifier_jeton().
test_that("l'usage timeStamping doit etre le seul, et critique", {
  expect_true(certificat_horodateur(certificat_de_test("timeStamping")))

  # Un certificat qui sert aussi a authentifier un serveur web n'est plus
  # dedie a l'horodatage, et c'est la dedicace qui fait la garantie.
  expect_false(certificat_horodateur(
    certificat_de_test("timeStamping,serverAuth")))
  # Non critique, l'usage devient une indication qu'un verificateur peut
  # ignorer : ce n'est plus une contrainte.
  expect_false(certificat_horodateur(
    certificat_de_test("timeStamping", critique = FALSE)))
  expect_false(certificat_horodateur(certificat_de_test("serverAuth")))
  expect_false(certificat_horodateur(certificat_de_test("")))
})

test_that("un jeton attestant une autre empreinte est invalide", {
  empreinte <- openssl::rand_bytes(32L)
  verdict <- tsa_verifier_jeton(jeton_de_test(empreinte),
                                openssl::rand_bytes(32L),
                                list(racine_tsa_de_test()))
  expect_equal(verdict$etat, "invalide")
  expect_match(verdict$motifs, "et non")
})

test_that("un contenu altere rompt le lien avec la signature", {
  empreinte <- openssl::rand_bytes(32L)
  jeton <- jeton_de_test(empreinte)
  # L'empreinte vit dans le TSTInfo ; en changer un octet doit faire echouer
  # le messageDigest des attributs signes, donc la signature.
  position <- which(vapply(seq_len(length(jeton) - 31L), function(i) {
    identical(jeton[i:(i + 31L)], empreinte)
  }, logical(1)))[[1L]]
  jeton[[position]] <- as.raw(bitwXor(as.integer(jeton[[position]]), 1L))

  verdict <- tsa_verifier_jeton(jeton, NULL, list(racine_tsa_de_test()))
  expect_equal(verdict$etat, "invalide")
  expect_match(verdict$motifs, "messageDigest")
})

test_that("le certificat designe doit etre celui du jeton", {
  # Sans le lien pose par signingCertificate, un certificat substitue dans le
  # champ `certificates` passerait pour celui qui a signe.
  empreinte <- openssl::rand_bytes(32L)
  sd <- cms_signed_data(jeton_de_test(empreinte))
  signataire <- sd$signataires[[1L]]

  expect_s3_class(certificat_du_signataire(signataire, sd$certificats),
                  "sommier_certificat")
  # Prive du certificat designe, le jeton n'a plus de signataire identifiable.
  autres <- Filter(function(c) !certificat_horodateur(c), sd$certificats)
  expect_match(certificat_du_signataire(signataire, autres), "n'est pas")
  expect_match(certificat_du_signataire(signataire, list()), "n'est pas")
})

test_that("la date attestee est celle qui juge la validite du certificat", {
  # Un jeton reste bon apres l'expiration du certificat qui l'a produit :
  # c'est tout l'interet de l'horodatage.
  empreinte <- openssl::rand_bytes(32L)
  sd <- cms_signed_data(jeton_de_test(empreinte))
  cert <- certificat_du_signataire(sd$signataires[[1L]], sd$certificats)

  expect_true(certificat_valide_a(cert, cert$debut))
  expect_true(certificat_valide_a(cert, cert$fin))
  expect_false(certificat_valide_a(cert, cert$debut - 1))
  expect_false(certificat_valide_a(cert, cert$fin + 1))
})

test_that("un certificat se lit : usages, validite, emetteur", {
  sd <- cms_signed_data(jeton_de_test(openssl::rand_bytes(32L)))
  cert <- certificat_du_signataire(sd$signataires[[1L]], sd$certificats)
  racine <- racine_tsa_de_test()

  expect_equal(certificat_usages(cert), OID_KP_HORODATAGE)
  expect_true(certificat_horodateur(cert))
  expect_false(certificat_horodateur(racine))
  # Le rattachement se fait sur les octets du nom, pas sur son impression.
  expect_identical(cert$emetteur, racine$sujet)
  expect_true(certificat_signe_par(cert, racine))
  expect_false(certificat_signe_par(cert, cert))
})

test_that("ce qui n'est pas un jeton est refuse, non interprete", {
  expect_equal(tsa_verifier_jeton(as.raw(c(0x30, 0x03, 0x02, 0x01, 0x2a)))$etat,
               "invalide")
  expect_match(tsa_verifier_jeton(as.raw(c(0x30, 0x03, 0x02, 0x01, 0x2a)))$motifs,
               "illisible")
  expect_error(certificat_lire(raw(0)), "non vide")
  expect_error(certificat_lire(as.raw(c(0x02, 0x01, 0x00))), "SEQUENCE")
})

test_that("un UTCTime se lit avec le siecle que la RFC 5280 impose", {
  lire <- function(texte) {
    octets <- c(as.raw(c(0x17, nchar(texte))), charToRaw(texte))
    x509_temps(octets, der_lire(octets, 1L))
  }
  expect_equal(format(lire("260827060456Z"), "%Y", tz = "UTC"), "2026")
  # 50 et au-dela valent 19xx.
  expect_equal(format(lire("990827060456Z"), "%Y", tz = "UTC"), "1999")
  expect_equal(format(lire("490827060456Z"), "%Y", tz = "UTC"), "2049")
  expect_error(lire("2608270604Z"), "YYMMDDHHMMSSZ")
})

# ---------------------------------------------------------------------------
# Contrefacons
# ---------------------------------------------------------------------------

test_that("un CMS bien signe mais par n'importe qui est refuse", {
  # Le TSTInfo est vrai, la signature est bonne, le certificat voyage dans le
  # jeton : tout y est, sauf ce qui designe le certificat qui a signe. Un
  # verificateur qui prendrait le premier certificat venu l'accepterait.
  empreinte <- openssl::rand_bytes(32L)
  contenu <- cms_signed_data(jeton_de_test(empreinte))$contenu

  verdict <- tsa_verifier_jeton(jeton_contrefait(contenu), empreinte)
  expect_equal(verdict$etat, "invalide")
  expect_match(verdict$motifs, "signingCertificate")
  # Le contenu, lui, se lit : c'est bien le TSTInfo d'origine.
  expect_identical(verdict$jeton$empreinte, empreinte)
})

test_that("un jeton a deux signataires est refuse", {
  empreinte <- openssl::rand_bytes(32L)
  contenu <- cms_signed_data(jeton_de_test(empreinte))$contenu
  verdict <- tsa_verifier_jeton(jeton_contrefait(contenu, signataires = 2L),
                                empreinte)
  expect_equal(verdict$etat, "invalide")
  expect_match(verdict$motifs, "un seul")
})

test_that("une signature d'autorite alteree est refusee", {
  empreinte <- openssl::rand_bytes(32L)
  jeton <- jeton_de_test(empreinte)
  # La signature est un OCTET STRING : en changer un octet ne deplace rien.
  sd <- cms_signed_data(jeton)
  signature <- sd$signataires[[1L]]$signature
  position <- which(vapply(seq_len(length(jeton) - length(signature) + 1L),
                           function(i) identical(jeton[i:(i + length(signature) - 1L)],
                                                 signature), logical(1)))[[1L]]
  jeton[[position]] <- as.raw(bitwXor(as.integer(jeton[[position]]), 1L))

  verdict <- tsa_verifier_jeton(jeton, empreinte, list(racine_tsa_de_test()))
  expect_equal(verdict$etat, "invalide")
  expect_match(verdict$motifs, "ne se verifie pas")
})

test_that("une enveloppe tronquee est signalee, non interpretee", {
  jeton <- jeton_de_test(openssl::rand_bytes(32L))
  expect_equal(tsa_verifier_jeton(jeton[1:200])$etat, "invalide")
})

test_that("les verdicts et les certificats s'impriment", {
  empreinte <- openssl::rand_bytes(32L)
  jeton <- jeton_de_test(empreinte)
  verdict <- tsa_verifier_jeton(jeton, empreinte, list(racine_tsa_de_test()))

  expect_output(print(verdict), "valide")
  # La reserve sur la revocation est dite a chaque fois, pas une fois pour
  # toutes dans un coin de la documentation.
  expect_output(print(verdict), "[Rr]evocation")
  expect_output(print(tsa_verifier_jeton(jeton, empreinte)), "non rattache")
  expect_output(print(tsa_lire_jeton(jeton)), "atteste")
  expect_output(print(certificat_de_test()), "usages")
  expect_output(print(certificat_de_test("")), "aucun declare")
})
