# ---------------------------------------------------------------------------
# Verification d'un jeton d'horodatage : la structure CMS (RFC 5652) qui
# l'enveloppe, et ce qui rattache la signature de l'autorite a une racine.
#
# horodatage.R lit ce que le jeton dit ; ce fichier verifie qui le dit.
# ---------------------------------------------------------------------------

OID_ATTR_TYPE_CONTENU   <- "1.2.840.113549.1.9.3"
OID_ATTR_CONDENSAT      <- "1.2.840.113549.1.9.4"
OID_ATTR_CERT_SIGNATURE <- "1.2.840.113549.1.9.16.2.12"   # signingCertificate
OID_ATTR_CERT_SIGNATURE_V2 <- "1.2.840.113549.1.9.16.2.47"

# Le SignedData d'un jeton : le contenu encapsule, les certificats transportes
# et l'unique SignerInfo que la RFC 3161 autorise.
cms_signed_data <- function(jeton) {
  contenu_info <- der_lire(jeton, 1L)
  type <- der_lire(jeton, contenu_info$debut)
  if (!identical(der_oid_texte(jeton, type), OID_SIGNED_DATA)) {
    stop("Ce n'est pas un SignedData.", call. = FALSE)
  }
  signed_data <- der_lire(jeton, der_lire(jeton, type$suivant)$debut)
  champs <- der_enfants(jeton, signed_data)
  if (length(champs) < 4L) {
    stop("SignedData tronque : signerInfos attendus.", call. = FALSE)
  }

  encap <- der_enfants(jeton, champs[[3L]])
  contenu <- if (length(encap) >= 2L) {
    der_contenu(jeton, der_lire(jeton, encap[[2L]]$debut))
  } else {
    stop("Contenu encapsule absent.", call. = FALSE)
  }

  certificats <- list()
  signataires <- NULL
  for (champ in champs[-seq_len(3L)]) {
    if (champ$tag == 0xA0L) {           # certificates [0] IMPLICIT
      certificats <- lapply(der_enfants(jeton, champ), function(c) {
        certificat_lire(der_tlv_octets(jeton, c))
      })
    } else if (champ$tag == 0x31L) {    # signerInfos SET OF
      signataires <- lapply(der_enfants(jeton, champ), function(s) {
        cms_signer_info(jeton, s)
      })
    }
    # crls [1] : ignore, voir la note sur la revocation dans tsa_verifier_jeton().
  }
  if (is.null(signataires) || length(signataires) == 0L) {
    stop("SignedData sans signataire.", call. = FALSE)
  }
  list(contenu = contenu, certificats = certificats, signataires = signataires)
}

cms_signer_info <- function(jeton, tlv) {
  champs <- der_enfants(jeton, tlv)
  if (length(champs) < 5L) {
    stop("SignerInfo tronque.", call. = FALSE)
  }
  # version, sid, digestAlgorithm, [signedAttrs], signatureAlgorithm,
  # signature, [unsignedAttrs].
  sid <- champs[[2L]]
  emetteur <- NULL
  serie <- NA_character_
  if (sid$tag == 0x30L) {                       # issuerAndSerialNumber
    morceaux <- der_enfants(jeton, sid)
    emetteur <- der_tlv_octets(jeton, morceaux[[1L]])
    serie <- der_entier_hex(jeton, morceaux[[2L]])
  }
  oid_condensat <- der_oid_texte(jeton, der_lire(jeton, champs[[3L]]$debut))
  condensat <- unname(OID_HACHAGES[oid_condensat])

  reste <- champs[-seq_len(3L)]
  attributs_signes <- NULL
  if (length(reste) && reste[[1L]]$tag == 0xA0L) {
    attributs_signes <- reste[[1L]]
    reste <- reste[-1L]
  }
  if (length(reste) < 2L) {
    stop("SignerInfo sans signature.", call. = FALSE)
  }

  list(
    emetteur   = emetteur,
    serie      = serie,
    condensat  = if (is.na(condensat)) NA_character_ else condensat,
    attributs  = if (is.null(attributs_signes)) list() else
      cms_attributs(jeton, attributs_signes),
    # Les octets exactement signes : le [0] IMPLICIT retagge en SET OF, comme
    # l'exige la RFC 5652 section 5.4. Seul le premier octet change ; la
    # longueur, elle, est deja celle du SET.
    octets_signes = if (is.null(attributs_signes)) NULL else {
      octets <- der_tlv_octets(jeton, attributs_signes)
      octets[[1L]] <- as.raw(0x31L)
      octets
    },
    algorithme = der_oid_texte(jeton, der_lire(jeton, reste[[1L]]$debut)),
    signature  = der_contenu(jeton, reste[[2L]])
  )
}

# Les attributs signes, indexes par OID. La valeur rendue est le contenu du
# SET, dont on garde les octets bruts : chaque attribut se relit selon son type.
cms_attributs <- function(jeton, tlv) {
  attributs <- list()
  for (attribut in der_enfants(jeton, tlv)) {
    morceaux <- der_enfants(jeton, attribut)
    if (length(morceaux) < 2L) {
      next
    }
    attributs[[der_oid_texte(jeton, morceaux[[1L]])]] <-
      der_contenu(jeton, morceaux[[2L]])
  }
  attributs
}

# L'empreinte du certificat que l'attribut signingCertificate[V2] designe.
# Rendre NULL veut dire « l'attribut est absent », ce qui est une anomalie en
# soi : sans lui, un certificat substitue dans le champ `certificates`
# passerait pour celui qui a signe.
cms_empreinte_du_signataire <- function(signataire) {
  v2 <- signataire$attributs[[OID_ATTR_CERT_SIGNATURE_V2]]
  v1 <- signataire$attributs[[OID_ATTR_CERT_SIGNATURE]]
  contenu <- v2 %||% v1
  if (is.null(contenu)) {
    return(NULL)
  }
  # SigningCertificateV2 { certs SEQUENCE OF ESSCertIDv2 { [algo], certHash,
  # [issuerSerial] } } - le premier ESSCertID designe le signataire.
  bloc <- der_lire(contenu, 1L)
  certs <- der_enfants(contenu, bloc)
  if (length(certs) == 0L) {
    return(NULL)
  }
  premier <- der_enfants(contenu, der_lire(contenu, certs[[1L]]$debut))
  if (length(premier) == 0L) {
    return(NULL)
  }
  # hashAlgorithm est facultatif et vaut SHA-256 par defaut ; le certHash est
  # le premier OCTET STRING rencontre.
  algorithme <- if (premier[[1L]]$tag == 0x30L) {
    unname(OID_HACHAGES[der_oid_texte(contenu, der_lire(contenu, premier[[1L]]$debut))])
  } else {
    "sha256"
  }
  for (champ in premier) {
    if (champ$tag == 0x04L) {
      return(list(algorithme = algorithme %||% NA_character_,
                  empreinte = der_contenu(contenu, champ)))
    }
  }
  NULL
}

#' Verification d'un jeton d'horodatage
#'
#' @description
#' Verifie qui atteste, et non plus seulement ce qui est atteste : la
#' signature de l'autorite sur le contenu du jeton, l'usage que son certificat
#' declare, sa validite a la date attestee, et la chaine qui le rattache a une
#' ancre de confiance.
#'
#' @details
#' **Trois etats, pas deux.**
#'
#' * `"valide"` : tout est verifie, et la chaine remonte a une ancre fournie.
#' * `"non_rattache"` : le jeton est intact - signature de l'autorite verifiee,
#'   empreinte concordante, usages et dates bons - mais aucune ancre ne le
#'   couvre, soit qu'aucune n'ait ete fournie, soit qu'aucune ne convienne.
#' * `"invalide"` : quelque chose cloche dans le jeton lui-meme.
#'
#' La distinction n'est pas cosmetique. Dire « invalide » a une commune dont le
#' jeton est parfait mais emis par une autorite qu'on n'a pas listee serait
#' faux, et lui faire croire a une garantie qu'on n'a pas verifiee le serait
#' tout autant.
#'
#' **Ce qui est verifie**, dans cet ordre :
#'
#' 1. le contenu se lit, et l'empreinte attestee est celle attendue ;
#' 2. le jeton porte un signataire et un seul (RFC 3161 section 2.4.2) ;
#' 3. l'attribut `contentType` annonce bien un `TSTInfo` ;
#' 4. l'attribut `messageDigest` correspond au condensat du contenu - sans
#'    quoi la signature porterait sur autre chose que ce qu'on a lu ;
#' 5. l'attribut `signingCertificate` designe le certificat employe, par son
#'    empreinte : sans lui, un certificat substitue dans le champ
#'    `certificates` passerait pour celui qui a signe ;
#' 6. la signature porte sur les attributs signes, reencodes en `SET OF`
#'    (RFC 5652 section 5.4) ;
#' 7. le certificat porte l'usage `id-kp-timeStamping` et lui seul ;
#' 8. il etait valide **a la date attestee**, non aujourd'hui ;
#' 9. la chaine remonte a une ancre, chaque lien verifie a cette meme date.
#'
#' **Ce qui n'est pas verifie : la revocation.** CRL et OCSP demandent le
#' reseau, ce que la verification hors ligne exclut par construction. Un
#' certificat revoque mais non expire passe donc. La limite est reelle ; elle
#' est ecrite ici et rendue dans le verdict plutot que passee sous silence.
#'
#' @param jeton Vecteur `raw` : le `TimeStampToken`.
#' @param empreinte Empreinte attendue (`raw` de 32 octets), ou `NULL` pour ne
#'   pas la confronter.
#' @param ancres Liste de certificats de confiance, lus par
#'   [certificat_lire()]. Aucune n'est embarquee dans le paquet : ce serait
#'   faire dependre du rythme de publication de sommieR la question de savoir
#'   qui est digne de confiance, et une racine retiree resterait attestee par
#'   toute version installee.
#' @return Un objet `sommier_verdict_tsa`.
#'
#' @seealso [tsa_lire_jeton()], [certificat_lire()]
#' @export
tsa_verifier_jeton <- function(jeton, empreinte = NULL, ancres = list()) {
  verdict <- function(etat, motifs, ...) {
    structure(c(list(etat = etat, motifs = motifs,
                     revocation_verifiee = FALSE), list(...)),
              class = "sommier_verdict_tsa")
  }

  lu <- try(tsa_lire_jeton(jeton), silent = TRUE)
  if (inherits(lu, "try-error")) {
    return(verdict("invalide",
                   paste0("jeton illisible : ",
                          trimws(conditionMessage(attr(lu, "condition")))),
                   jeton = NULL))
  }
  if (!is.null(empreinte)) {
    empreinte <- valider_empreinte(empreinte, "empreinte")
    if (!identical(lu$empreinte, empreinte)) {
      return(verdict("invalide", paste0(
        "le jeton atteste ", lu$algorithme, ":", empreinte_hex(lu$empreinte),
        ", et non ", empreinte_hex(empreinte)), jeton = lu))
    }
  }

  sd <- try(cms_signed_data(jeton), silent = TRUE)
  if (inherits(sd, "try-error")) {
    return(verdict("invalide",
                   paste0("enveloppe CMS illisible : ",
                          trimws(conditionMessage(attr(sd, "condition")))),
                   jeton = lu))
  }
  if (length(sd$signataires) != 1L) {
    return(verdict("invalide", paste0(
      "le jeton porte ", length(sd$signataires),
      " signataires ; la RFC 3161 en veut un seul"), jeton = lu))
  }
  signataire <- sd$signataires[[1L]]

  motifs <- verifier_attributs_signes(signataire, sd$contenu)
  if (length(motifs)) {
    return(verdict("invalide", motifs, jeton = lu))
  }

  certificat <- certificat_du_signataire(signataire, sd$certificats)
  if (is.character(certificat)) {
    return(verdict("invalide", certificat, jeton = lu))
  }

  if (!signature_du_signataire_valide(signataire, certificat)) {
    return(verdict("invalide",
                   "la signature de l'autorite ne se verifie pas sous son certificat",
                   jeton = lu))
  }
  if (!certificat_horodateur(certificat)) {
    usages <- certificat_usages(certificat)
    return(verdict("invalide", paste0(
      "le certificat ne declare pas le seul usage `timeStamping` (",
      if (length(usages)) paste(usages, collapse = ", ") else "aucun usage",
      ") : la RFC 3161 l'exige"), jeton = lu, certificat = certificat))
  }
  if (!certificat_valide_a(certificat, lu$date)) {
    return(verdict("invalide", paste0(
      "le certificat n'etait pas valide a la date attestee (",
      format(lu$date, "%Y-%m-%d", tz = "UTC"), ")"),
      jeton = lu, certificat = certificat))
  }

  chaine <- chaine_vers_ancre(certificat, sd$certificats, ancres, lu$date)
  if (!isTRUE(chaine$rattache)) {
    return(verdict("non_rattache", chaine$motif, jeton = lu,
                   certificat = certificat))
  }
  verdict("valide", character(0), jeton = lu, certificat = certificat)
}

# Les attributs qui lient la signature au contenu qu'on a lu.
verifier_attributs_signes <- function(signataire, contenu) {
  motifs <- character(0)
  if (is.null(signataire$octets_signes)) {
    return("le signataire ne porte pas d'attributs signes")
  }
  if (is.na(signataire$condensat)) {
    return("condensat du signataire non reconnu")
  }

  type <- signataire$attributs[[OID_ATTR_TYPE_CONTENU]]
  if (is.null(type) ||
      !identical(der_oid_texte(type, der_lire(type, 1L)), OID_CT_TSTINFO)) {
    motifs <- c(motifs, "l'attribut contentType n'annonce pas un TSTInfo")
  }

  declare <- signataire$attributs[[OID_ATTR_CONDENSAT]]
  if (is.null(declare)) {
    motifs <- c(motifs, "l'attribut messageDigest est absent")
  } else {
    attendu <- as.raw(fonction_de_condensat(signataire$condensat)(contenu))
    if (!identical(der_contenu(declare, der_lire(declare, 1L)), attendu)) {
      motifs <- c(motifs, paste0(
        "l'attribut messageDigest ne correspond pas au contenu : la ",
        "signature porte sur autre chose que le TSTInfo lu"))
    }
  }
  motifs
}

# Le certificat que l'attribut signingCertificate designe, par empreinte. On
# ne se fie pas a l'ordre du champ `certificates` : rien n'y garantit que le
# premier soit le signataire.
certificat_du_signataire <- function(signataire, certificats) {
  designe <- cms_empreinte_du_signataire(signataire)
  if (is.null(designe)) {
    return(paste0("le jeton ne porte pas d'attribut signingCertificate : ",
                  "rien n'y designe le certificat qui a signe"))
  }
  if (is.na(designe$algorithme)) {
    return("l'attribut signingCertificate emploie un condensat non reconnu")
  }
  condenser <- fonction_de_condensat(designe$algorithme)
  trouve <- Position(function(c) identical(as.raw(condenser(c$der)), designe$empreinte),
                     certificats)
  if (is.na(trouve)) {
    return(paste0("le certificat designe par signingCertificate n'est pas ",
                  "dans le jeton : il en porte ", length(certificats)))
  }
  certificats[[trouve]]
}

signature_du_signataire_valide <- function(signataire, certificat) {
  cle <- try(openssl::read_pubkey(certificat$cle_publique, der = TRUE),
             silent = TRUE)
  if (inherits(cle, "try-error")) {
    return(FALSE)
  }
  resultat <- try(
    openssl::signature_verify(signataire$octets_signes, signataire$signature,
                              fonction_de_condensat(signataire$condensat),
                              pubkey = cle),
    silent = TRUE
  )
  isTRUE(!inherits(resultat, "try-error") && resultat)
}

#' @export
print.sommier_verdict_tsa <- function(x, ...) {
  libelle <- c(valide = "valide",
               non_rattache = "lu, non rattache a une ancre",
               invalide = "invalide")[[x$etat]]
  cat("<verdict d'horodatage> ", libelle, "\n", sep = "")
  if (!is.null(x$jeton)) {
    cat("  atteste : ", x$jeton$algorithme, ":", empreinte_hex(x$jeton$empreinte),
        "\n", sep = "")
    cat("  date    : ", format(x$jeton$date, "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
        "\n", sep = "")
  }
  for (motif in x$motifs) {
    cat("  ! ", motif, "\n", sep = "")
  }
  cat("  (revocation non verifiee : CRL et OCSP demandent le reseau)\n")
  invisible(x)
}
