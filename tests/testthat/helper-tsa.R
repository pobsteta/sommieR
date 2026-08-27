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

# Racine, certificat d'autorite et configuration. Monte une fois par nom et
# par execution de la suite.
#
# `usage` decide de l'extension d'usage etendu du certificat signataire :
# `"timeStamping"` est ce qu'exige la RFC 3161, les autres valeurs servent a
# fabriquer les cas de refus.
autorite_tsa_de_test <- function(nom = "principale", usage = "timeStamping",
                                 critique = TRUE) {
  testthat::skip_if_not(openssl_en_ligne_de_commande(),
                        "openssl en ligne de commande absent")
  cle_cache <- paste(nom, usage, critique, sep = "/")
  if (!is.null(cache_tsa[[cle_cache]])) {
    return(cache_tsa[[cle_cache]])
  }
  rep <- file.path(tempdir(),
                   paste0("sommier-tsa-", nom, "-", gsub("[^a-z]", "", usage),
                          if (critique) "-crit" else ""))
  dir.create(rep, showWarnings = FALSE, recursive = TRUE)
  chemin <- function(f) file.path(rep, f)

  writeLines(c(
    "[ tsa_ext ]",
    "basicConstraints = CA:FALSE",
    "keyUsage = critical, digitalSignature, nonRepudiation",
    if (nzchar(usage)) {
      paste0("extendedKeyUsage = ", if (critique) "critical, " else "", usage)
    }
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
           "-days", "3650", "-subj", paste0("/CN=Racine de test ", nom))
  executer("req", "-newkey", "rsa:2048", "-nodes",
           "-keyout", chemin("tsa.key"), "-out", chemin("tsa.csr"),
           "-subj", paste0("/CN=Autorite d horodatage ", nom))
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

  cache_tsa[[cle_cache]] <- rep
  rep
}

# La racine de l'autorite, prete a servir d'ancre de confiance.
racine_tsa_de_test <- function(nom = "principale", usage = "timeStamping",
                               critique = TRUE) {
  rep <- autorite_tsa_de_test(nom, usage, critique)
  certificat_lire(openssl::write_der(
    openssl::read_cert(file.path(rep, "ca.crt"))
  ))
}

# Le transport a brancher sur tsa_horodater() : il repond a la requete recue,
# comme le ferait l'autorite au bout du fil.
tsa_simulee <- function(nom = "principale", usage = "timeStamping",
                        critique = TRUE) {
  rep <- autorite_tsa_de_test(nom, usage, critique)
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

# Un certificat seul, sans autorite d'horodatage autour : de quoi eprouver les
# regles d'usage sans avoir a produire un jeton.
certificat_de_test <- function(usage = "timeStamping", critique = TRUE) {
  testthat::skip_if_not(openssl_en_ligne_de_commande(),
                        "openssl en ligne de commande absent")
  rep <- file.path(tempdir(), paste0("sommier-cert-", gsub("[^a-z]", "", usage),
                                     if (critique) "-crit" else ""))
  if (!dir.exists(rep)) {
    dir.create(rep, recursive = TRUE)
    chemin <- function(f) file.path(rep, f)
    lignes <- c("[ ext ]", "basicConstraints = CA:FALSE")
    if (nzchar(usage)) {
      lignes <- c(lignes, paste0("extendedKeyUsage = ",
                                 if (critique) "critical, " else "", usage))
    }
    writeLines(lignes, chemin("ext.cnf"))
    executer <- function(...) {
      if (!identical(suppressWarnings(system2("openssl", shQuote(c(...)),
                                              stdout = FALSE, stderr = FALSE)),
                     0L)) {
        testthat::skip("openssl a echoue en fabriquant un certificat de test")
      }
    }
    executer("req", "-x509", "-newkey", "rsa:2048", "-nodes",
             "-keyout", chemin("ca.key"), "-out", chemin("ca.crt"),
             "-days", "3650", "-subj", "/CN=Racine de certificat de test")
    executer("req", "-newkey", "rsa:2048", "-nodes", "-keyout", chemin("f.key"),
             "-out", chemin("f.csr"), "-subj", "/CN=Feuille de test")
    executer("x509", "-req", "-in", chemin("f.csr"), "-CA", chemin("ca.crt"),
             "-CAkey", chemin("ca.key"), "-CAcreateserial", "-out",
             chemin("f.crt"), "-days", "3650", "-extfile", chemin("ext.cnf"),
             "-extensions", "ext")
  }
  certificat_lire(openssl::write_der(
    openssl::read_cert(file.path(rep, "f.crt"))
  ))
}

# Un signataire de visa muni de son certificat : de quoi eprouver le visa
# autoporteur, celui que son destinataire verifie sans rien se procurer.
signataire_avec_certificat <- function(sub = "maire-01") {
  testthat::skip_if_not(openssl_en_ligne_de_commande(),
                        "openssl en ligne de commande absent")
  rep <- file.path(tempdir(), "sommier-signataire")
  if (!dir.exists(rep)) {
    dir.create(rep, recursive = TRUE)
    code <- suppressWarnings(system2("openssl", shQuote(c(
      "req", "-x509", "-newkey", "rsa:2048", "-nodes",
      "-keyout", file.path(rep, "cle.pem"), "-out", file.path(rep, "cert.pem"),
      "-days", "3650", "-subj", "/CN=Maire de test"
    )), stdout = FALSE, stderr = FALSE))
    if (!identical(code, 0L)) {
      testthat::skip("openssl a echoue en fabriquant le certificat du signataire")
    }
  }
  cle <- openssl::read_key(file.path(rep, "cle.pem"))
  certificat <- openssl::write_der(openssl::read_cert(file.path(rep, "cert.pem")))
  list(
    cle = cle,
    certificat = certificat,
    signataire = signataire_cle(cle, claims = list(sub = sub),
                                certificat = certificat)
  )
}

# Un CMS bien forme, portant un vrai TSTInfo et correctement signe - mais par
# un certificat quelconque, sans rien qui le designe. C'est la contrefacon que
# le lien `signingCertificate` existe pour arreter : un verificateur naif, qui
# prendrait le premier certificat venu du champ `certificates`, l'accepterait.
#
# `signataires` permet d'en fabriquer une variante a deux signataires, que la
# RFC 3161 interdit.
jeton_contrefait <- function(contenu, signataires = 1L) {
  testthat::skip_if_not(openssl_en_ligne_de_commande(),
                        "openssl en ligne de commande absent")
  rep <- file.path(tempdir(), "sommier-contrefacon")
  if (!dir.exists(rep)) {
    dir.create(rep, recursive = TRUE)
    for (n in c("a", "b")) {
      code <- suppressWarnings(system2("openssl", shQuote(c(
        "req", "-x509", "-newkey", "rsa:2048", "-nodes",
        "-keyout", file.path(rep, paste0(n, ".key")),
        "-out", file.path(rep, paste0(n, ".crt")),
        "-days", "3650", "-subj", paste0("/CN=Signataire ", n)
      )), stdout = FALSE, stderr = FALSE))
      if (!identical(code, 0L)) {
        testthat::skip("openssl a echoue en fabriquant la contrefacon")
      }
    }
  }
  entree <- tempfile(fileext = ".der")
  sortie <- tempfile(fileext = ".der")
  on.exit(unlink(c(entree, sortie)), add = TRUE)
  writeBin(contenu, entree)

  noms <- if (signataires >= 2L) c("a", "b") else "a"
  arguments <- c("cms", "-sign", "-in", entree, "-binary", "-nodetach",
                 "-outform", "DER", "-out", sortie,
                 "-econtent_type", "1.2.840.113549.1.9.16.1.4", "-md", "sha256")
  for (n in noms) {
    arguments <- c(arguments, "-signer", file.path(rep, paste0(n, ".crt")),
                   "-inkey", file.path(rep, paste0(n, ".key")))
  }
  code <- suppressWarnings(system2("openssl", shQuote(arguments),
                                   stdout = FALSE, stderr = FALSE))
  if (!identical(code, 0L) || !file.exists(sortie)) {
    testthat::skip("openssl cms n'a pas produit la contrefacon")
  }
  readBin(sortie, "raw", file.size(sortie))
}
