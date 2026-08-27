# Reponse RFC 3161 simulee : SEQUENCE { PKIStatusInfo { INTEGER statut }, jeton }
# Construite a la main pour que les tests d'analyse tournent hors ligne, sans
# autorite d'horodatage joignable. Le jeton, lui, n'est pas analysable : elle
# ne sert qu'aux cas ou seul le statut compte.
reponse_tsa_simulee <- function(statut, jeton = NULL) {
  info <- as.raw(c(0x30, 0x03, 0x02, 0x01, statut))
  contenu <- if (is.null(jeton)) info else c(info, jeton)
  c(as.raw(c(0x30, length(contenu))), contenu)
}

# --------------------------------------------------------------------------
# Une autorite d'horodatage de test, montee a la volee.
#
# Depuis que tsa_horodater() confronte l'empreinte et le nonce du jeton a ce
# qu'elle a envoye, un jeton bricole ne passe plus - et c'est le but. Il faut
# donc une autorite qui reponde vraiment. Elle est engendree ici plutot que
# versee au depot : cela evite d'y laisser une cle privee, et donne au lot
# suivant de quoi fabriquer ses cas de refus.
# --------------------------------------------------------------------------

cache_tsa <- new.env(parent = emptyenv())

openssl_en_ligne_de_commande <- function() {
  nzchar(Sys.which("openssl"))
}

# Racine, certificat d'autorite portant l'EKU timeStamping, et configuration.
# Monte une fois par execution de la suite.
autorite_tsa_de_test <- function() {
  testthat::skip_if_not(openssl_en_ligne_de_commande(),
                        "openssl en ligne de commande absent")
  if (!is.null(cache_tsa$repertoire)) {
    return(cache_tsa$repertoire)
  }
  rep <- file.path(tempdir(), "sommier-tsa-de-test")
  dir.create(rep, showWarnings = FALSE)
  chemin <- function(nom) file.path(rep, nom)

  writeLines(c(
    "[ tsa_ext ]",
    "basicConstraints = CA:FALSE",
    "keyUsage = critical, digitalSignature, nonRepudiation",
    "extendedKeyUsage = critical, timeStamping"
  ), chemin("ext.cnf"))

  # system2() ne cite pas ses arguments : un sujet de certificat, qui porte des
  # espaces, se scinderait en plusieurs mots.
  executer <- function(...) {
    arguments <- shQuote(c(...))
    code <- suppressWarnings(
      system2("openssl", arguments, stdout = FALSE, stderr = FALSE)
    )
    if (!identical(code, 0L)) {
      testthat::skip(paste("openssl a echoue :", paste(c(...), collapse = " ")))
    }
  }
  executer("req", "-x509", "-newkey", "rsa:2048", "-nodes",
           "-keyout", chemin("ca.key"), "-out", chemin("ca.crt"),
           "-days", "3650", "-subj", "/CN=Racine de test sommieR")
  executer("req", "-newkey", "rsa:2048", "-nodes",
           "-keyout", chemin("tsa.key"), "-out", chemin("tsa.csr"),
           "-subj", "/CN=Autorite d horodatage de test")
  executer("x509", "-req", "-in", chemin("tsa.csr"),
           "-CA", chemin("ca.crt"), "-CAkey", chemin("ca.key"),
           "-CAcreateserial", "-out", chemin("tsa.crt"), "-days", "3650",
           "-extfile", chemin("ext.cnf"), "-extensions", "tsa_ext")

  writeLines(c(
    "[ tsa_config ]",
    paste0("serial = ", chemin("serial")),
    paste0("signer_cert = ", chemin("tsa.crt")),
    paste0("certs = ", chemin("ca.crt")),
    paste0("signer_key = ", chemin("tsa.key")),
    "signer_digest = sha256",
    "default_policy = 1.2.3.4.1",
    "digests = sha256",
    "accuracy = secs:1",
    "ordering = yes",
    "tsa_name = yes",
    "ess_cert_id_chain = yes",
    "ess_cert_id_alg = sha256"
  ), chemin("tsa.cnf"))
  writeLines("01", chemin("serial"))

  cache_tsa$repertoire <- rep
  rep
}

# Le transport a brancher sur tsa_horodater() : il repond a la requete recue,
# comme le ferait l'autorite au bout du fil.
tsa_simulee <- function() {
  rep <- autorite_tsa_de_test()
  function(url, corps) {
    requete <- tempfile(fileext = ".tsq")
    reponse <- tempfile(fileext = ".tsr")
    on.exit(unlink(c(requete, reponse)), add = TRUE)
    writeBin(corps, requete)
    code <- suppressWarnings(system2(
      "openssl",
      shQuote(c("ts", "-reply", "-config", file.path(rep, "tsa.cnf"),
                "-section", "tsa_config", "-queryfile", requete,
                "-out", reponse)),
      stdout = FALSE, stderr = FALSE
    ))
    if (!identical(code, 0L) || !file.exists(reponse)) {
      testthat::skip("l'autorite d'horodatage de test n'a pas repondu")
    }
    readBin(reponse, "raw", file.size(reponse))
  }
}

# Le jeton fige du depot, et ce qu'il atteste (voir fixtures/PROVENANCE.md).
REPONSE_TSA_FIGEE <- function() {
  chemin <- testthat::test_path("fixtures", "tsa-test-reponse.tsr")
  readBin(chemin, "raw", file.size(chemin))
}
EMPREINTE_TSA_FIGEE <-
  "38f5282a5c6e0b415f02b0ad7ae7f2d5413e4313fe893c61f484b2c950e4205c"
NONCE_TSA_FIGE <- 1234567890123

# Le jeton fige, en hexadecimal : la forme sous laquelle un manifeste le porte.
JETON_TSA_FIGE_HEX <- function() {
  empreinte_hex(tsa_lire_reponse(REPONSE_TSA_FIGEE())$jeton)
}
