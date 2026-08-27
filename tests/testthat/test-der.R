# Les briques DER, et surtout leurs refus. Un encodeur qu'aucun test
# n'emprunte n'est pas verifie : la forme longue des longueurs, par exemple,
# ne sert jamais a une requete d'horodatage - 68 octets tiennent en forme
# courte - et resterait donc a l'etat de promesse.

test_that("la forme longue des longueurs DER est correcte", {
  # < 128 : un seul octet, la valeur elle-meme.
  expect_identical(der_longueur(0L), as.raw(0x00))
  expect_identical(der_longueur(127L), as.raw(0x7f))
  # >= 128 : 0x80 + nombre d'octets, puis la longueur en gros-boutiste.
  expect_identical(der_longueur(128L), as.raw(c(0x81, 0x80)))
  expect_identical(der_longueur(200L), as.raw(c(0x81, 0xc8)))
  expect_identical(der_longueur(300L), as.raw(c(0x82, 0x01, 0x2c)))
  expect_identical(der_longueur(65536L), as.raw(c(0x83, 0x01, 0x00, 0x00)))
})

test_that("un TLV long se relit comme il s'est ecrit", {
  contenu <- openssl::rand_bytes(300L)
  tlv <- der_tlv(0x04L, contenu)
  lu <- der_lire(tlv, 1L)
  expect_equal(lu$tag, 0x04L)
  expect_identical(der_contenu(tlv, lu), contenu)
  expect_identical(der_tlv_octets(tlv, lu), tlv)
})

test_that("un entier DER se code signe", {
  expect_identical(der_entier(0), as.raw(c(0x02, 0x01, 0x00)))
  expect_identical(der_entier(127), as.raw(c(0x02, 0x01, 0x7f)))
  # 128 aurait un premier octet >= 0x80, donc lu comme negatif : DER le
  # prefixe d'un zero.
  expect_identical(der_entier(128), as.raw(c(0x02, 0x02, 0x00, 0x80)))
})

test_that("un nombre se rend en hexadecimal minimal", {
  expect_equal(nombre_vers_hex(0), "0")
  expect_equal(nombre_vers_hex(255), "ff")
  expect_equal(nombre_vers_hex(1234567890123), "11f71fb04cb")
})

test_that("une requete sans nonce fourni en tire un", {
  # Le nonce par defaut tient sous 2^53, pour rester exactement representable.
  requete <- tsa_requete(openssl::rand_bytes(32L))
  expect_true(is.raw(requete))
  expect_equal(as.integer(requete[[1L]]), 0x30L)
})

test_that("un BIT STRING a bits inutilises est refuse", {
  # Pour une signature ou une cle il vaut zero ; l'accepter autrement
  # reviendrait a rendre des octets qui ne sont pas ceux qu'on croit.
  octets <- as.raw(c(0x03, 0x03, 0x04, 0xff, 0xf0))
  expect_error(der_bitstring(octets, der_lire(octets, 1L)), "bits inutilises")
  vide <- as.raw(c(0x03, 0x00))
  expect_error(der_bitstring(vide, der_lire(vide, 1L)), "vide")
})

test_that("une date de certificat d'un type inattendu est refusee", {
  octets <- as.raw(c(0x04, 0x02, 0x41, 0x42))
  expect_error(x509_temps(octets, der_lire(octets, 1L)), "type inattendu")
})

test_that("un certificat malforme est refuse a chaque etape", {
  expect_error(certificat_lire("pas du raw"), "raw")
  # SEQUENCE vide : ni tbsCertificate, ni algorithme, ni signature.
  expect_error(certificat_lire(as.raw(c(0x30, 0x00))), "tbsCertificate")
})

test_that("un condensat non pris en charge est signale", {
  expect_error(fonction_de_condensat("sha3"), "non pris en charge")
})

test_that("un type de cle non pris en charge est refuse", {
  # ed25519 ne correspond a aucun `alg` JOSE que le paquet accepte ; le
  # laisser passer produirait un en-tete mentant sur l'algorithme.
  expect_error(alg_de_la_cle(openssl::ed25519_keygen()), "non pris en charge")
})

test_that("une signature ECDSA brute malformee est refusee", {
  expect_error(ecdsa_brut_vers_der(raw(0)), "nombre pair")
  expect_error(ecdsa_brut_vers_der(openssl::rand_bytes(63L)), "nombre pair")
  expect_error(ecdsa_brut_vers_der("pas du raw"), "nombre pair")
})

test_that("une composante ECDSA trop longue est refusee, non tronquee", {
  expect_error(bignum_rembourre(openssl::bignum(openssl::rand_bytes(48L)), 32L),
               "48 octets")
})

test_that("un signataire porteur de certificat le dit", {
  materiel <- signataire_avec_certificat()
  expect_output(print(materiel$signataire), "autoporteur")
  expect_output(print(signataire_cle(openssl::rsa_keygen(2048L),
                                     list(sub = "a"))), "RS256")
})

test_that("un certificat illisible confie a un signataire est refuse tout de suite", {
  # Decouvrir des annees plus tard, au moment de verifier, qu'un visa porte un
  # certificat illisible serait le decouvrir trop tard.
  expect_error(
    sommier_signataire(list(sub = "a"), function(x) x,
                       certificat = as.raw(c(0x30, 0x00))),
    "tbsCertificate"
  )
  expect_error(
    sommier_signataire(list(sub = "a"), function(x) x, certificat = "pas du raw"),
    "DER"
  )
})
