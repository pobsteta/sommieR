# ---------------------------------------------------------------------------
# Encodage DER minimal, juste ce qu'exige une requete d'horodatage RFC 3161.
# openssl (le paquet R) n'expose pas l'ASN.1 : on encode a la main, et on ne
# code que les quelques types necessaires plutot qu'un ASN.1 general.
# ---------------------------------------------------------------------------

der_longueur <- function(n) {
  if (n < 128L) {
    return(as.raw(n))
  }
  octets <- raw(0)
  while (n > 0L) {
    octets <- c(as.raw(n %% 256L), octets)
    n <- n %/% 256L
  }
  c(as.raw(128L + length(octets)), octets)
}

der_tlv <- function(tag, contenu) {
  c(as.raw(tag), der_longueur(length(contenu)), contenu)
}

der_entier <- function(n) {
  if (n == 0) {
    return(der_tlv(0x02L, as.raw(0L)))
  }
  octets <- raw(0)
  reste <- n
  while (reste > 0) {
    octets <- c(as.raw(reste %% 256), octets)
    reste <- reste %/% 256
  }
  # DER code des entiers signes : un premier octet >= 0x80 serait lu comme
  # negatif, il faut donc le prefixer d'un zero.
  if (as.integer(octets[[1L]]) >= 128L) {
    octets <- c(as.raw(0L), octets)
  }
  der_tlv(0x02L, octets)
}

der_octets <- function(x) der_tlv(0x04L, x)
der_booleen <- function(x) der_tlv(0x01L, as.raw(if (isTRUE(x)) 255L else 0L))
der_nul <- function() der_tlv(0x05L, raw(0))
der_sequence <- function(...) der_tlv(0x30L, c(...))

# OID 2.16.840.1.101.3.4.2.1 (sha-256), deja encode : le sommier ne hache
# qu'en SHA-256, un encodeur d'OID general serait du code mort.
OID_SHA256 <- as.raw(c(0x06, 0x09, 0x60, 0x86, 0x48, 0x01, 0x65, 0x03, 0x04, 0x02, 0x01))

#' Requete d'horodatage RFC 3161
#'
#' @description
#' Encode une `TimeStampReq` (RFC 3161 section 2.4.1) portant l'empreinte
#' SHA-256 a horodater.
#'
#' @param empreinte Vecteur `raw` de 32 octets.
#' @param nonce Entier aleatoire liant la reponse a la requete. Un nonce
#'   permet de detecter le rejeu d'une reponse anterieure.
#' @param demander_certificat Demander a l'autorite d'inclure son certificat
#'   dans le jeton, ce qui rend celui-ci verifiable de facon autonome.
#' @return Un vecteur `raw` : la requete encodee en DER.
#'
#' @export
tsa_requete <- function(empreinte, nonce = NULL, demander_certificat = TRUE) {
  empreinte <- valider_empreinte(empreinte, "empreinte")
  if (is.null(nonce)) {
    # 8 octets d'alea, ramenes sous 2^53 pour rester exactement representables
    # en double : au-dela, l'entier serait arrondi et le nonce rendu ne
    # correspondrait plus a celui qu'on croit avoir envoye.
    nonce <- sum(as.integer(openssl::rand_bytes(6L)) * 256^(0:5))
  }
  der_sequence(
    der_entier(1),                                   # version v1
    der_sequence(                                    # messageImprint
      der_sequence(OID_SHA256, der_nul()),
      der_octets(empreinte)
    ),
    der_entier(nonce),
    der_booleen(demander_certificat)
  )
}

# Lecture d'un TLV DER a la position `i`. Rend le tag, les bornes du contenu
# et la position suivante.
der_lire <- function(octets, i = 1L) {
  n <- length(octets)
  if (i + 1L > n) {
    stop("Reponse d'horodatage tronquee.", call. = FALSE)
  }
  tag <- as.integer(octets[[i]])
  premier <- as.integer(octets[[i + 1L]])
  if (premier < 128L) {
    longueur <- premier
    debut <- i + 2L
  } else {
    nb <- premier - 128L
    if (nb == 0L || i + 1L + nb > n) {
      stop("Longueur DER indefinie ou tronquee dans la reponse.", call. = FALSE)
    }
    longueur <- 0L
    for (k in seq_len(nb)) {
      longueur <- longueur * 256L + as.integer(octets[[i + 1L + k]])
    }
    debut <- i + 2L + nb
  }
  if (debut + longueur - 1L > n) {
    stop("Contenu DER tronque dans la reponse.", call. = FALSE)
  }
  list(tag = tag, debut = debut, fin = debut + longueur - 1L,
       suivant = debut + longueur)
}

der_entier_valeur <- function(octets, tlv) {
  if (tlv$fin < tlv$debut) {
    return(0L)
  }
  Reduce(function(a, b) a * 256L + as.integer(b),
         octets[tlv$debut:tlv$fin], accumulate = FALSE, init = 0L)
}

#' Statuts PKIStatus (RFC 3161 section 2.4.2)
#' @export
SOMMIER_STATUTS_TSA <- c(
  "0" = "accorde", "1" = "accorde avec modifications", "2" = "refus",
  "3" = "en attente", "4" = "revocation avertie", "5" = "revocation notifiee"
)

#' Lecture d'une reponse d'horodatage RFC 3161
#'
#' @description
#' Verifie le `PKIStatus` et extrait le jeton d'horodatage.
#'
#' @details
#' Le jeton est rendu tel quel, sans verification cryptographique de la chaine
#' de certification de l'autorite : celle-ci exige un magasin de confiance et
#' une validation CMS complete, hors de portee de ce paquet. Ce qui est
#' garanti ici, c'est que l'autorite a accorde l'horodatage et que le jeton
#' est syntaxiquement exploitable. La verification complete se fait avec
#' `openssl ts -verify`, en s'appuyant sur le certificat inclus quand
#' `demander_certificat` valait `TRUE`.
#'
#' @param reponse Vecteur `raw` : la reponse DER de l'autorite.
#' @return Une liste : `statut` (entier), `libelle`, `jeton` (`raw` ou `NULL`).
#'
#' @export
tsa_lire_reponse <- function(reponse) {
  if (!is.raw(reponse) || length(reponse) == 0L) {
    stop("`reponse` doit etre un vecteur raw non vide.", call. = FALSE)
  }
  enveloppe <- der_lire(reponse, 1L)
  if (enveloppe$tag != 0x30L) {
    stop("Reponse d'horodatage malformee : SEQUENCE attendue.", call. = FALSE)
  }

  info_statut <- der_lire(reponse, enveloppe$debut)
  if (info_statut$tag != 0x30L) {
    stop("PKIStatusInfo malforme.", call. = FALSE)
  }
  tlv_statut <- der_lire(reponse, info_statut$debut)
  if (tlv_statut$tag != 0x02L) {
    stop("PKIStatus malforme : INTEGER attendu.", call. = FALSE)
  }
  statut <- der_entier_valeur(reponse, tlv_statut)
  libelle <- unname(SOMMIER_STATUTS_TSA[as.character(statut)])
  if (is.na(libelle)) {
    libelle <- paste("statut inconnu", statut)
  }

  jeton <- NULL
  if (info_statut$suivant <= enveloppe$fin) {
    tlv_jeton <- der_lire(reponse, info_statut$suivant)
    jeton <- reponse[info_statut$suivant:tlv_jeton$fin]
  }

  list(statut = statut, libelle = libelle, jeton = jeton)
}

#' Transport HTTP pour l'horodatage
#'
#' @description
#' Rend la fonction qui poste une requete DER a l'autorite. Le transport est
#' un parametre et non un appel en dur : les tests injectent une autorite
#' simulee, et un deploiement ferme peut brancher son propre client.
#'
#' @param timeout Delai maximal, en secondes.
#' @return Une fonction `(url, corps) -> raw`.
#' @export
tsa_transport_curl <- function(timeout = 30) {
  function(url, corps) {
    if (!requireNamespace("curl", quietly = TRUE)) {
      stop("Le paquet `curl` est requis pour interroger une autorite ",
           "d'horodatage ; l'installer, ou fournir `transport`.", call. = FALSE)
    }
    poignee <- curl::new_handle()
    curl::handle_setheaders(poignee, "Content-Type" = "application/timestamp-query")
    curl::handle_setopt(poignee, post = TRUE, postfields = corps,
                        timeout = timeout)
    reponse <- curl::curl_fetch_memory(url, handle = poignee)
    if (reponse$status_code != 200L) {
      stop("L'autorite d'horodatage a repondu ", reponse$status_code, ".",
           call. = FALSE)
    }
    reponse$content
  }
}

#' Obtention d'un jeton d'horodatage
#'
#' @param empreinte Vecteur `raw` de 32 octets a horodater.
#' @param url URL de l'autorite d'horodatage.
#' @param transport Fonction de transport, voir [tsa_transport_curl()].
#' @param nonce Nonce a employer (facultatif).
#' @return Un vecteur `raw` : le jeton d'horodatage.
#'
#' @export
tsa_horodater <- function(empreinte, url, transport = tsa_transport_curl(),
                          nonce = NULL) {
  requete <- tsa_requete(empreinte, nonce = nonce)
  reponse <- tsa_lire_reponse(transport(valider_texte(url, "url"), requete))
  # 0 accorde, 1 accorde avec modifications : au-dela, il n'y a pas de jeton.
  if (!reponse$statut %in% c(0L, 1L) || is.null(reponse$jeton)) {
    stop("L'autorite d'horodatage n'a pas delivre de jeton (statut ",
         reponse$statut, " : ", reponse$libelle, ").", call. = FALSE)
  }
  reponse$jeton
}
