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
    return(0)
  }
  # Accumulation en double, non en entier : un INTEGER de plus de quatre
  # octets - un numero de serie, un nonce - deborderait le type entier de R et
  # se rendrait en NA sans que rien ne l'annonce.
  Reduce(function(a, b) a * 256 + as.integer(b),
         octets[tlv$debut:tlv$fin], accumulate = FALSE, init = 0)
}

# Les enfants d'un TLV constructeur (SEQUENCE, SET, [n] EXPLICIT), dans
# l'ordre. Rend une liste de TLV tels que les rend der_lire().
der_enfants <- function(octets, tlv) {
  enfants <- list()
  i <- tlv$debut
  while (i <= tlv$fin) {
    enfant <- der_lire(octets, i)
    enfants[[length(enfants) + 1L]] <- enfant
    i <- enfant$suivant
  }
  enfants
}

# Un INTEGER en hexadecimal minuscule, sans zero de tete. DER prefixe d'un
# zero les entiers dont le premier octet depasse 0x7f, pour qu'ils ne soient
# pas lus comme negatifs : ce zero n'appartient pas a la valeur, et le garder
# ferait differer deux ecritures du meme nombre.
der_entier_hex <- function(octets, tlv) {
  if (tlv$fin < tlv$debut) {
    return("0")
  }
  brut <- octets[tlv$debut:tlv$fin]
  while (length(brut) > 1L && brut[[1L]] == as.raw(0L)) {
    brut <- brut[-1L]
  }
  hex <- paste0(sprintf("%02x", as.integer(brut)), collapse = "")
  sub("^0+(?=.)", "", hex, perl = TRUE)
}

# Un OBJECT IDENTIFIER en notation pointee. Contrairement a l'OID sha-256, qui
# est connu d'avance et code en dur, la politique d'horodatage varie d'une
# autorite a l'autre : il faut savoir la lire, pas seulement la reconnaitre.
der_oid_texte <- function(octets, tlv) {
  if (tlv$fin < tlv$debut) {
    stop("OBJECT IDENTIFIER vide.", call. = FALSE)
  }
  brut <- as.integer(octets[tlv$debut:tlv$fin])
  # Le premier octet encode les deux premieres composantes : 40 * a + b.
  arcs <- c(brut[[1L]] %/% 40L, brut[[1L]] %% 40L)
  valeur <- 0
  for (o in brut[-1L]) {
    valeur <- valeur * 128 + (o %% 128L)
    if (o < 128L) {
      arcs <- c(arcs, valeur)
      valeur <- 0
    }
  }
  paste(format(arcs, scientific = FALSE, trim = TRUE), collapse = ".")
}

# GeneralizedTime : YYYYMMDDHHMMSS[.fff]Z. La RFC 3161 impose l'heure UTC, le
# suffixe Z, et interdit les decalages locaux (section 2.4.2).
der_temps_generalise <- function(octets, tlv) {
  texte <- rawToChar(octets[tlv$debut:tlv$fin])
  if (!grepl("^[0-9]{14}([.,][0-9]+)?Z$", texte)) {
    stop("genTime hors du format impose par la RFC 3161 : ", texte,
         " ; YYYYMMDDHHMMSS[.fff]Z attendu en UTC.", call. = FALSE)
  }
  quand <- as.POSIXct(substr(texte, 1L, 14L), format = "%Y%m%d%H%M%S",
                      tz = "UTC")
  if (is.na(quand)) {
    stop("genTime illisible : ", texte, ".", call. = FALSE)
  }
  quand
}

# OID des enveloppes CMS traversees pour atteindre le TSTInfo (RFC 5652).
OID_SIGNED_DATA <- "1.2.840.113549.1.7.2"
OID_CT_TSTINFO  <- "1.2.840.113549.1.9.16.1.4"
# Les algorithmes de hachage qu'une autorite peut nommer dans le
# messageImprint. Le sommier ne demande que du SHA-256 ; savoir nommer les
# autres sert a dire ce qu'on a recu plutot que « inconnu ».
OID_HACHAGES <- c(
  "2.16.840.1.101.3.4.2.1" = "sha256",
  "2.16.840.1.101.3.4.2.2" = "sha384",
  "2.16.840.1.101.3.4.2.3" = "sha512",
  "1.3.14.3.2.26"          = "sha1"
)

# Descend du ContentInfo CMS jusqu'au TSTInfo encapsule :
#   ContentInfo { id-signedData, [0] SignedData { .., encapContentInfo
#                 { id-ct-TSTInfo, [0] OCTET STRING { TSTInfo } }, .. } }
tstinfo_du_jeton <- function(jeton) {
  contenu_info <- der_lire(jeton, 1L)
  if (contenu_info$tag != 0x30L) {
    stop("Jeton d'horodatage malforme : ContentInfo attendu.", call. = FALSE)
  }
  type <- der_lire(jeton, contenu_info$debut)
  if (type$tag != 0x06L || !identical(der_oid_texte(jeton, type), OID_SIGNED_DATA)) {
    stop("Jeton d'horodatage sans SignedData : ce n'est pas un ",
         "TimeStampToken.", call. = FALSE)
  }
  explicite <- der_lire(jeton, type$suivant)
  if (explicite$tag != 0xA0L) {
    stop("SignedData absent du ContentInfo.", call. = FALSE)
  }
  signed_data <- der_lire(jeton, explicite$debut)
  enfants <- der_enfants(jeton, signed_data)
  # version, digestAlgorithms, encapContentInfo, puis les champs facultatifs.
  if (length(enfants) < 3L) {
    stop("SignedData tronque : encapContentInfo attendu.", call. = FALSE)
  }
  encap <- enfants[[3L]]
  type_encapsule <- der_lire(jeton, encap$debut)
  if (!identical(der_oid_texte(jeton, type_encapsule), OID_CT_TSTINFO)) {
    stop("Le contenu encapsule n'est pas un TSTInfo.", call. = FALSE)
  }
  porteur <- der_lire(jeton, type_encapsule$suivant)
  if (porteur$tag != 0xA0L) {
    stop("Contenu encapsule absent : le jeton ne porte pas son TSTInfo.",
         call. = FALSE)
  }
  chaine <- der_lire(jeton, porteur$debut)
  if (chaine$tag != 0x04L) {
    stop("TSTInfo attendu dans un OCTET STRING.", call. = FALSE)
  }
  jeton[chaine$debut:chaine$fin]
}

#' Lecture du contenu d'un jeton d'horodatage
#'
#' @description
#' Rend le `TSTInfo` que le jeton encapsule (RFC 3161 section 2.4.2) : ce que
#' l'autorite a horodate, et quand.
#'
#' @details
#' Sans cette lecture, un jeton n'est qu'une colonne non vide. Le paquet
#' saurait dire qu'un visa « est horodate » sans savoir ni a quelle date, ni
#' sur quelle empreinte : un jeton parfaitement valide, obtenu pour une autre
#' tete de chaine - une autre foret, un autre exercice - passerait exactement
#' comme le bon.
#'
#' Ce que cette fonction ne fait pas : verifier la signature de l'autorite et
#' la chaine de certification qui la rattache a une racine. Un `TSTInfo` lu
#' n'est pas un `TSTInfo` authentifie ; c'est l'objet du lot suivant, cadre
#' dans `specs/brief_probant-2`. La lecture n'exige, elle, aucun magasin de
#' confiance et aucun reseau.
#'
#' @param jeton Vecteur `raw` : le `TimeStampToken` rendu par
#'   [tsa_horodater()].
#' @return Un objet `sommier_jeton_tsa` : `empreinte` (`raw`), `algorithme`,
#'   `date` (`POSIXct` UTC), `serie` et `nonce` (hexadecimal), `politique`
#'   (OID pointe), `version`.
#'
#' @seealso [tsa_horodater()], [tsa_lire_reponse()]
#' @export
tsa_lire_jeton <- function(jeton) {
  if (!is.raw(jeton) || length(jeton) == 0L) {
    stop("`jeton` doit etre un vecteur raw non vide.", call. = FALSE)
  }
  info <- tstinfo_du_jeton(jeton)
  racine <- der_lire(info, 1L)
  if (racine$tag != 0x30L) {
    stop("TSTInfo malforme : SEQUENCE attendue.", call. = FALSE)
  }
  champs <- der_enfants(info, racine)
  # version, policy, messageImprint, serialNumber et genTime sont obligatoires
  # et positionnels ; ce qui suit est facultatif et se reconnait a son tag.
  if (length(champs) < 5L) {
    stop("TSTInfo tronque : ", length(champs),
         " champs, cinq obligatoires attendus.", call. = FALSE)
  }
  empreinte_seq <- champs[[3L]]
  parties <- der_enfants(info, empreinte_seq)
  if (length(parties) != 2L || parties[[2L]]$tag != 0x04L) {
    stop("messageImprint malforme.", call. = FALSE)
  }
  oid_hachage <- der_oid_texte(info, der_lire(info, parties[[1L]]$debut))
  algorithme <- unname(OID_HACHAGES[oid_hachage])
  if (is.na(algorithme)) {
    algorithme <- oid_hachage
  }

  nonce <- NA_character_
  for (champ in champs[-seq_len(5L)]) {
    if (champ$tag == 0x02L) {
      nonce <- der_entier_hex(info, champ)
      break
    }
  }

  structure(
    list(
      version    = as.integer(der_entier_valeur(info, champs[[1L]])),
      politique  = der_oid_texte(info, champs[[2L]]),
      algorithme = algorithme,
      empreinte  = info[parties[[2L]]$debut:parties[[2L]]$fin],
      serie      = der_entier_hex(info, champs[[4L]]),
      date       = der_temps_generalise(info, champs[[5L]]),
      nonce      = nonce
    ),
    class = "sommier_jeton_tsa"
  )
}

#' @export
print.sommier_jeton_tsa <- function(x, ...) {
  cat("<jeton d'horodatage RFC 3161>\n")
  cat("  atteste   : ", x$algorithme, ":", empreinte_hex(x$empreinte), "\n", sep = "")
  cat("  date      : ", format(x$date, "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"), "\n", sep = "")
  cat("  serie     : ", x$serie, "\n", sep = "")
  cat("  politique : ", x$politique, "\n", sep = "")
  if (!is.na(x$nonce)) {
    cat("  nonce     : ", x$nonce, "\n", sep = "")
  }
  cat("  (contenu lu, signature de l'autorite non verifiee)\n")
  invisible(x)
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
#' Ce qui est garanti ici, c'est que l'autorite a accorde l'horodatage et que
#' le jeton est syntaxiquement exploitable. Son contenu se lit avec
#' [tsa_lire_jeton()] : empreinte attestee, date, nonce.
#'
#' La signature de l'autorite et la chaine de certification qui la rattache a
#' une racine ne sont pas verifiees : cela demande un magasin de confiance, et
#' fait l'objet du lot suivant. En attendant, `openssl ts -verify` s'en charge,
#' en s'appuyant sur le certificat inclus quand `demander_certificat` valait
#' `TRUE`.
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
  statut <- as.integer(der_entier_valeur(reponse, tlv_statut))
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

# Un entier positif en hexadecimal minimal. sprintf("%x") refuse les doubles,
# et le nonce depasse ce qu'un entier de R peut porter.
nombre_vers_hex <- function(n) {
  if (n == 0) {
    return("0")
  }
  chiffres <- character(0)
  reste <- n
  while (reste > 0) {
    chiffres <- c(sprintf("%x", as.integer(reste %% 16)), chiffres)
    reste <- reste %/% 16
  }
  paste0(chiffres, collapse = "")
}

#' Obtention d'un jeton d'horodatage
#'
#' @description
#' Interroge l'autorite, et confronte le jeton rendu a ce qui a ete demande.
#'
#' @details
#' Deux confrontations, que la RFC 3161 rend obligatoires et que le jeton seul
#' permet :
#'
#' * **L'empreinte attestee est celle qui a ete envoyee.** Sans quoi le
#'   registre archiverait un jeton portant sur autre chose que sa tete de
#'   chaine.
#' * **Le nonce rendu est celui qui a ete envoye** (section 2.4.2 : present
#'   dans la requete, il doit l'etre dans la reponse, avec la meme valeur).
#'   C'est ce qui distingue une reponse fraiche du rejeu d'une reponse
#'   anterieure. Le nonce etait pose depuis la v0.2.0, mais personne ne le
#'   relisait : la detection annoncee n'avait jamais lieu.
#'
#' @param empreinte Vecteur `raw` de 32 octets a horodater.
#' @param url URL de l'autorite d'horodatage.
#' @param transport Fonction de transport, voir [tsa_transport_curl()].
#' @param nonce Nonce a employer. Par defaut, six octets d'alea.
#' @return Un vecteur `raw` : le jeton d'horodatage.
#'
#' @seealso [tsa_lire_jeton()]
#' @export
tsa_horodater <- function(empreinte, url, transport = tsa_transport_curl(),
                          nonce = NULL) {
  empreinte <- valider_empreinte(empreinte, "empreinte")
  if (is.null(nonce)) {
    # Tire ici plutot que dans tsa_requete() : pour confronter le nonce rendu,
    # encore faut-il savoir lequel a ete envoye.
    nonce <- sum(as.integer(openssl::rand_bytes(6L)) * 256^(0:5))
  }
  requete <- tsa_requete(empreinte, nonce = nonce)
  reponse <- tsa_lire_reponse(transport(valider_texte(url, "url"), requete))
  # 0 accorde, 1 accorde avec modifications : au-dela, il n'y a pas de jeton.
  if (!reponse$statut %in% c(0L, 1L) || is.null(reponse$jeton)) {
    stop("L'autorite d'horodatage n'a pas delivre de jeton (statut ",
         reponse$statut, " : ", reponse$libelle, ").", call. = FALSE)
  }

  lu <- tsa_lire_jeton(reponse$jeton)
  if (!identical(lu$empreinte, empreinte)) {
    stop("Le jeton atteste ", lu$algorithme, ":", empreinte_hex(lu$empreinte),
         ", alors que ", empreinte_hex(empreinte), " a ete envoye.",
         call. = FALSE)
  }
  attendu <- nombre_vers_hex(nonce)
  if (is.na(lu$nonce)) {
    stop("Le jeton ne porte pas de nonce, alors que la requete en portait un ",
         "(RFC 3161 section 2.4.2) : rien ne le distingue du rejeu d'une ",
         "reponse anterieure.", call. = FALSE)
  }
  if (!identical(lu$nonce, attendu)) {
    stop("Nonce rendu (", lu$nonce, ") different de celui envoye (", attendu,
         ") : la reponse ne repond pas a cette requete.", call. = FALSE)
  }
  reponse$jeton
}
