# ---------------------------------------------------------------------------
# Lecture de certificats X.509, juste ce qu'exige la validation d'un jeton
# d'horodatage. `openssl::read_cert()` rend le sujet, l'emetteur et la cle,
# mais ni les extensions ni des dates exploitables : l'extension d'usage et la
# validite a une date donnee se lisent donc dans le DER.
#
# Les lecteurs DER viennent de horodatage.R.
# ---------------------------------------------------------------------------

# Seuls les OID qui servent sont cites, comme OID_SHA256 : un catalogue
# general serait du code mort.
OID_EXT_EKU       <- "2.5.29.37"
OID_KP_HORODATAGE <- "1.3.6.1.5.5.7.3.8"

# Algorithmes de signature de certificat, et le condensat qu'ils emploient.
OID_SIGNATURES <- c(
  "1.2.840.113549.1.1.11" = "sha256",   # sha256WithRSAEncryption
  "1.2.840.113549.1.1.12" = "sha384",
  "1.2.840.113549.1.1.13" = "sha512",
  "1.2.840.10045.4.3.2"   = "sha256",   # ecdsa-with-SHA256
  "1.2.840.10045.4.3.3"   = "sha384",
  "1.2.840.10045.4.3.4"   = "sha512"
)

# Un BIT STRING porte en tete le nombre de bits inutilises du dernier octet.
# Pour une signature ou une cle il vaut zero ; on l'ecarte quand meme plutot
# que de le supposer.
der_bitstring <- function(octets, tlv) {
  if (tlv$fin < tlv$debut) {
    stop("BIT STRING vide.", call. = FALSE)
  }
  inutilises <- as.integer(octets[[tlv$debut]])
  if (inutilises != 0L) {
    stop("BIT STRING a ", inutilises, " bits inutilises : inattendu ici.",
         call. = FALSE)
  }
  if (tlv$debut + 1L > tlv$fin) raw(0) else octets[(tlv$debut + 1L):tlv$fin]
}

# UTCTime (YYMMDDHHMMSSZ) ou GeneralizedTime. La RFC 5280 fixe le siecle
# implicite de l'UTCTime : 50 et au-dela valent 19xx.
x509_temps <- function(octets, tlv) {
  if (tlv$tag == 0x18L) {
    return(der_temps_generalise(octets, tlv))
  }
  if (tlv$tag != 0x17L) {
    stop("Date de certificat d'un type inattendu (tag ", tlv$tag, ").",
         call. = FALSE)
  }
  texte <- rawToChar(der_contenu(octets, tlv))
  if (!grepl("^[0-9]{12}Z$", texte)) {
    stop("UTCTime hors format : ", texte, " ; YYMMDDHHMMSSZ attendu.",
         call. = FALSE)
  }
  annee <- as.integer(substr(texte, 1L, 2L))
  siecle <- if (annee >= 50L) "19" else "20"
  quand <- as.POSIXct(paste0(siecle, substr(texte, 1L, 12L)),
                      format = "%Y%m%d%H%M%S", tz = "UTC")
  if (is.na(quand)) {
    stop("UTCTime illisible : ", texte, ".", call. = FALSE)
  }
  quand
}

#' Lecture d'un certificat X.509
#'
#' @description
#' Rend ce dont la validation d'un jeton d'horodatage a besoin, et que
#' `openssl::read_cert()` n'expose pas : les bornes de validite comme dates,
#' les extensions, et les octets exacts sur lesquels porte la signature.
#'
#' @details
#' `emetteur` et `sujet` sont rendus **en octets**, non en texte : rattacher un
#' certificat a son emetteur se fait par egalite binaire des noms encodes.
#' Comparer des chaines rendues par un formateur ferait dependre la confiance
#' de la facon dont on imprime un nom.
#'
#' @param der Vecteur `raw` : le certificat encode en DER.
#' @return Un objet `sommier_certificat` : `der`, `tbs` (les octets signes),
#'   `signature`, `condensat`, `serie`, `emetteur`, `sujet`, `debut`, `fin`,
#'   `cle_publique`, `extensions`.
#'
#' @seealso [certificat_horodateur()], [certificat_valide_a()]
#' @export
certificat_lire <- function(der) {
  if (!is.raw(der) || length(der) == 0L) {
    stop("`der` doit etre un vecteur raw non vide.", call. = FALSE)
  }
  racine <- der_lire(der, 1L)
  if (racine$tag != 0x30L) {
    stop("Certificat malforme : SEQUENCE attendue.", call. = FALSE)
  }
  parties <- der_enfants(der, racine)
  if (length(parties) != 3L) {
    stop("Certificat malforme : tbsCertificate, algorithme et signature ",
         "attendus.", call. = FALSE)
  }
  tbs <- parties[[1L]]
  champs <- der_enfants(der, tbs)
  # La version est facultative et explicitement taguee ; sans elle, la
  # numerotation des champs suivants glisse d'un cran.
  decalage <- if (length(champs) > 0L && champs[[1L]]$tag == 0xA0L) 1L else 0L
  if (length(champs) < decalage + 6L) {
    stop("tbsCertificate tronque.", call. = FALSE)
  }
  a <- function(i) champs[[decalage + i]]

  validite <- der_enfants(der, a(4L))
  if (length(validite) != 2L) {
    stop("Validite malformee : deux dates attendues.", call. = FALSE)
  }

  oid_signature <- der_oid_texte(der, der_lire(der, parties[[2L]]$debut))
  condensat <- unname(OID_SIGNATURES[oid_signature])
  if (is.na(condensat)) {
    condensat <- NA_character_
  }

  structure(
    list(
      der          = der,
      tbs          = der_tlv_octets(der, tbs),
      signature    = der_bitstring(der, parties[[3L]]),
      condensat    = condensat,
      algorithme   = oid_signature,
      serie        = der_entier_hex(der, a(1L)),
      emetteur     = der_tlv_octets(der, a(3L)),
      sujet        = der_tlv_octets(der, a(5L)),
      debut        = x509_temps(der, validite[[1L]]),
      fin          = x509_temps(der, validite[[2L]]),
      cle_publique = der_tlv_octets(der, a(6L)),
      extensions   = extensions_du_certificat(der, champs, decalage)
    ),
    class = "sommier_certificat"
  )
}

extensions_du_certificat <- function(der, champs, decalage) {
  extensions <- list()
  for (champ in champs[-seq_len(decalage + 6L)]) {
    if (champ$tag != 0xA3L) {
      next
    }
    for (ext in der_enfants(der, der_lire(der, champ$debut))) {
      morceaux <- der_enfants(der, ext)
      oid <- der_oid_texte(der, morceaux[[1L]])
      critique <- length(morceaux) >= 3L && morceaux[[2L]]$tag == 0x01L &&
        as.integer(der[[morceaux[[2L]]$debut]]) != 0L
      extensions[[oid]] <- list(
        critique = critique,
        valeur = der_contenu(der, morceaux[[length(morceaux)]])
      )
    }
  }
  extensions
}

#' @export
print.sommier_certificat <- function(x, ...) {
  cat("<certificat X.509>\n")
  cat("  serie    : ", x$serie, "\n", sep = "")
  cat("  validite : ", format(x$debut, "%Y-%m-%d", tz = "UTC"), " a ",
      format(x$fin, "%Y-%m-%d", tz = "UTC"), "\n", sep = "")
  cat("  usages   : ",
      if (length(certificat_usages(x))) paste(certificat_usages(x), collapse = ", ")
      else "(aucun declare)", "\n", sep = "")
  invisible(x)
}

#' Usages etendus declares par un certificat
#'
#' @param certificat Objet [certificat_lire()].
#' @return Les OID de l'extension `extKeyUsage`, en notation pointee.
#'   Un vecteur vide si l'extension est absente.
#' @export
certificat_usages <- function(certificat) {
  ext <- certificat$extensions[[OID_EXT_EKU]]
  if (is.null(ext)) {
    return(character(0))
  }
  # extnValue est un OCTET STRING qui encapsule la SEQUENCE OF OID.
  contenu <- ext$valeur
  sequence <- der_lire(contenu, 1L)
  vapply(der_enfants(contenu, sequence),
         function(oid) der_oid_texte(contenu, oid), character(1))
}

#' Le certificat est-il celui d'une autorite d'horodatage ?
#'
#' @description
#' La RFC 3161 (section 2.3) exige que le certificat de l'autorite porte
#' l'extension d'usage `id-kp-timeStamping`, **et elle seule**, marquee
#' critique.
#'
#' @details
#' L'exigence n'est pas formelle. Un certificat de serveur web signant des
#' jetons d'horodatage ferait d'une cle prevue pour l'authentification une cle
#' d'attestation dans le temps : c'est exactement ce que l'extension sert a
#' empecher.
#'
#' @param certificat Objet [certificat_lire()].
#' @return `TRUE` ou `FALSE`.
#' @export
certificat_horodateur <- function(certificat) {
  ext <- certificat$extensions[[OID_EXT_EKU]]
  # « et elle seule », « critique » : les deux comptent. Un certificat portant
  # aussi `serverAuth` reste accepte par bien des outils, mais il n'est plus
  # dedie a l'horodatage - et c'est la dedicace qui fait la garantie.
  !is.null(ext) && isTRUE(ext$critique) &&
    identical(certificat_usages(certificat), OID_KP_HORODATAGE)
}

#' Validite d'un certificat a une date donnee
#'
#' @description
#' `quand`, non « maintenant ». Un jeton de 2019 reste bon apres l'expiration
#' du certificat qui l'a produit - c'est meme tout l'interet de l'horodatage :
#' il atteste qu'une empreinte existait a une date ou le certificat, lui,
#' etait valide.
#'
#' @param certificat Objet [certificat_lire()].
#' @param quand Date d'appreciation (`POSIXct`).
#' @return `TRUE` ou `FALSE`.
#' @export
certificat_valide_a <- function(certificat, quand) {
  quand >= certificat$debut && quand <= certificat$fin
}

# Le certificat a-t-il ete signe par cet emetteur ? La signature porte sur les
# octets du tbsCertificate, tag et longueur compris.
certificat_signe_par <- function(certificat, emetteur) {
  if (is.na(certificat$condensat)) {
    return(FALSE)
  }
  cle <- try(openssl::read_pubkey(emetteur$cle_publique, der = TRUE),
             silent = TRUE)
  if (inherits(cle, "try-error")) {
    return(FALSE)
  }
  resultat <- try(
    openssl::signature_verify(certificat$tbs, certificat$signature,
                              fonction_de_condensat(certificat$condensat),
                              pubkey = cle),
    silent = TRUE
  )
  isTRUE(!inherits(resultat, "try-error") && resultat)
}

# La fonction de hachage nommee par l'algorithme de signature. Une
# correspondance explicite plutot qu'un `get()` dans le paquet openssl : un
# nom construit a l'execution rendrait la resolution invisible au controle du
# paquet, et muette le jour ou elle echouerait.
fonction_de_condensat <- function(nom) {
  switch(nom,
    sha256 = openssl::sha256,
    sha384 = openssl::sha384,
    sha512 = openssl::sha512,
    stop("Condensat non pris en charge : ", nom, ".", call. = FALSE)
  )
}

# Remonte du certificat vers une ancre de confiance, en s'aidant des
# certificats intermediaires transportes par le jeton. Chaque lien est
# verifie : le nom de l'emetteur, la signature, et la validite **a la date
# attestee**.
#
# Rend une liste : `rattache` (booleen), `motif` (NA si rattache), `chemin`
# (les sujets traverses).
chaine_vers_ancre <- function(certificat, intermediaires, ancres, quand,
                              profondeur_max = 10L) {
  if (length(ancres) == 0L) {
    return(list(rattache = FALSE, motif = "aucune ancre de confiance fournie",
                chemin = character(0)))
  }
  courant <- certificat
  vus <- list()
  for (i in seq_len(profondeur_max)) {
    vus[[length(vus) + 1L]] <- courant$sujet

    ancre <- Position(function(a) {
      identical(a$sujet, courant$emetteur) && certificat_signe_par(courant, a)
    }, ancres)
    if (!is.na(ancre)) {
      if (!certificat_valide_a(ancres[[ancre]], quand)) {
        return(list(rattache = FALSE, chemin = character(0),
                    motif = "l'ancre de confiance n'etait pas valide a la date attestee"))
      }
      return(list(rattache = TRUE, motif = NA_character_,
                  chemin = paste0(length(vus), " lien(s)")))
    }

    suivant <- Position(function(c) {
      identical(c$sujet, courant$emetteur) && !identical(c$sujet, courant$sujet) &&
        certificat_signe_par(courant, c)
    }, intermediaires)
    if (is.na(suivant)) {
      return(list(rattache = FALSE, chemin = character(0),
                  motif = "la chaine ne remonte a aucune ancre fournie"))
    }
    courant <- intermediaires[[suivant]]
    if (!certificat_valide_a(courant, quand)) {
      return(list(rattache = FALSE, chemin = character(0),
                  motif = "un certificat intermediaire n'etait pas valide a la date attestee"))
    }
  }
  list(rattache = FALSE, chemin = character(0),
       motif = paste0("chaine plus longue que ", profondeur_max, " liens"))
}
