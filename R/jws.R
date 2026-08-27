#' Encodage base64url (RFC 4648 section 5)
#'
#' Variante du base64 sans remplissage, ou `+` et `/` deviennent `-` et `_`.
#' C'est l'encodage impose par JOSE pour les en-tetes et les signatures.
#'
#' @param x Vecteur `raw` ou chaine de caracteres.
#' @return Une chaine de caracteres.
#' @export
base64url_encoder <- function(x) {
  if (is.character(x)) {
    x <- charToRaw(enc2utf8(x))
  }
  texte <- openssl::base64_encode(x)
  texte <- gsub("=+$", "", texte)
  chartr("+/", "-_", texte)
}

#' Decodage base64url
#'
#' @param x Chaine base64url.
#' @return Un vecteur `raw`.
#' @export
base64url_decoder <- function(x) {
  x <- chartr("-_", "+/", as.character(x))
  # Le remplissage est absent en base64url ; openssl l'exige.
  reste <- nchar(x) %% 4L
  if (reste > 0L) {
    x <- paste0(x, strrep("=", 4L - reste))
  }
  openssl::base64_decode(x)
}

#' Algorithmes de signature reconnus
#'
#' @description
#' * `RS256` : RSASSA-PKCS1-v1_5 avec SHA-256, algorithme par defaut de
#'   Keycloak et d'AgentConnect.
#' * `ES256` : ECDSA sur P-256 avec SHA-256.
#'
#' @details
#' `ES256` demande une conversion, parce que JOSE veut la signature en `R||S`
#' brut la ou OpenSSL la produit encodee en DER. [ecdsa_der_vers_brut()] et
#' [ecdsa_brut_vers_der()] la font dans les deux sens.
#'
#' Seule la courbe P-256 est acceptee : `ES384` et `ES512` supposent des
#' composantes de 48 et 66 octets, et les rembourrer a 32 tronquerait la
#' signature.
#'
#' @export
SOMMIER_ALGOS_JWS <- c("RS256", "ES256")

# Taille d'une composante ECDSA en P-256 : 32 octets, comme l'ordre du groupe.
TAILLE_COMPOSANTE_ES256 <- 32L

# Un bignum ne porte pas ses zeros de tete - c'est un nombre, pas une chaine
# d'octets. Les rendre est ce qui distingue une composante JOSE valide d'une
# signature courte que rien d'autre n'accepterait.
bignum_rembourre <- function(x, taille) {
  octets <- as.raw(x)
  if (length(octets) > taille) {
    stop("Composante ECDSA de ", length(octets), " octets, ", taille,
         " attendus : la courbe n'est pas celle attendue.", call. = FALSE)
  }
  c(raw(taille - length(octets)), octets)
}

#' Conversion d'une signature ECDSA du DER vers le format JOSE
#'
#' @description
#' OpenSSL encode une signature ECDSA en DER (`SEQUENCE { INTEGER r,
#' INTEGER s }`), JOSE l'attend en `R||S` : les deux composantes concatenees,
#' chacune sur la taille de la courbe.
#'
#' @details
#' Le rembourrage n'est pas une precaution de style. `openssl::ecdsa_parse()`
#' rend deux `bignum`, et un `bignum` ne porte pas ses zeros de tete : une
#' composante dont le premier octet est nul s'y presente sur 31 octets. Sur
#' 4 000 signatures P-256 mesurees, 29 - soit 0,72 % - ont au moins une
#' composante courte. Les concatener telles quelles produirait une signature de
#' 63 octets, refusee par toute autre implementation JOSE, et le defaut ne se
#' manifesterait qu'une fois sur cent quarante.
#'
#' @param der Signature encodee en DER (`raw`).
#' @param taille Taille d'une composante, en octets. 32 pour P-256.
#' @return Un vecteur `raw` de `2 * taille` octets.
#'
#' @seealso [ecdsa_brut_vers_der()]
#' @export
ecdsa_der_vers_brut <- function(der, taille = TAILLE_COMPOSANTE_ES256) {
  composantes <- openssl::ecdsa_parse(der)
  c(bignum_rembourre(composantes$r, taille),
    bignum_rembourre(composantes$s, taille))
}

#' Conversion d'une signature ECDSA du format JOSE vers le DER
#'
#' @description
#' L'inverse d'[ecdsa_der_vers_brut()] : `openssl::signature_verify()` attend
#' du DER, une signature JOSE n'en est pas.
#'
#' @param brut Signature `R||S` (`raw`), de longueur paire.
#' @return Un vecteur `raw` : la signature encodee en DER.
#'
#' @seealso [ecdsa_der_vers_brut()]
#' @export
ecdsa_brut_vers_der <- function(brut) {
  if (!is.raw(brut) || length(brut) == 0L || length(brut) %% 2L != 0L) {
    stop("Signature ECDSA brute attendue : R et S concatenes, donc un ",
         "nombre pair d'octets.", call. = FALSE)
  }
  moitie <- length(brut) %/% 2L
  openssl::ecdsa_write(
    openssl::bignum(brut[seq_len(moitie)]),
    openssl::bignum(brut[(moitie + 1L):length(brut)])
  )
}

# L'algorithme JOSE que la cle impose. Le deduire plutot que le demander evite
# le seul defaut qu'une cle et un `alg` separes rendent possible : un en-tete
# annoncant RS256 au-dessus d'une signature ECDSA.
alg_de_la_cle <- function(cle) {
  type <- cle$type %||% ""
  if (identical(type, "rsa")) {
    return("RS256")
  }
  if (identical(type, "ecdsa")) {
    courbe <- cle$data$curve %||% "(inconnue)"
    if (!identical(courbe, "P-256")) {
      stop("Courbe ", courbe, " non prise en charge : `ES256` suppose P-256. ",
           "Signer sur une autre courbe produirait une signature qu'aucun ",
           "verificateur JOSE ne saurait lire.", call. = FALSE)
    }
    return("ES256")
  }
  stop("Type de cle non pris en charge : ", if (nzchar(type)) type else "(inconnu)",
       ". Attendus : rsa (RS256) ou ecdsa P-256 (ES256).", call. = FALSE)
}

#' Construction d'un signataire
#'
#' @description
#' Contrat generique attendu par [sommier_viser()] : des claims d'identite, et
#' de quoi signer. Les deux sont volontairement separes, parce qu'ils viennent
#' de sources differentes - le fournisseur d'identite (Keycloak, AgentConnect)
#' atteste **qui** signe, une cle ou un service de signature eIDAS produit
#' **la** signature. Keycloak ne signe pas de contenu arbitraire.
#'
#' @details
#' `signer` doit rendre la signature **au format que JOSE attend pour `alg`** :
#' pour `ES256`, les 64 octets `R||S`, et non le DER que produit OpenSSL.
#' [signataire_cle()] s'en charge, puisqu'elle tient la cle ;
#' un service de signature externe branche ici doit le faire de son cote. Le
#' paquet ne devine pas le format rendu : une signature ECDSA en DER peut, tres
#' rarement, faire exactement 64 octets, et un reniflage se tromperait alors
#' sans que rien ne le signale.
#'
#' @param claims Liste nommee des claims d'identite (au minimum `sub`).
#' @param signer Fonction prenant un vecteur `raw` et rendant la signature,
#'   en `raw`, au format JOSE de `alg`.
#' @param alg Algorithme JOSE, parmi [SOMMIER_ALGOS_JWS].
#' @param kid Identifiant de cle, porte dans l'en-tete JWS (facultatif).
#'
#' @return Un objet de classe `sommier_signataire`.
#'
#' @seealso [signataire_cle()], [signataire_keycloak()]
#' @export
sommier_signataire <- function(claims, signer, alg = "RS256", kid = NULL) {
  if (!is.list(claims) || est_vide(claims$sub)) {
    stop("`claims` doit etre une liste nommee portant au moins `sub` : ",
         "un visa sans signataire identifie n'est pas opposable.", call. = FALSE)
  }
  if (!is.function(signer)) {
    stop("`signer` doit etre une fonction (raw) -> raw.", call. = FALSE)
  }
  structure(
    list(
      claims = claims,
      signer = signer,
      alg    = valider_choix(alg, "alg", SOMMIER_ALGOS_JWS),
      kid    = if (est_vide(kid)) NULL else valider_texte(kid, "kid")
    ),
    class = "sommier_signataire"
  )
}

#' @export
print.sommier_signataire <- function(x, ...) {
  cat("<signataire de sommier>\n")
  cat("  sub : ", x$claims$sub, "\n", sep = "")
  cat("  alg : ", x$alg, if (!is.null(x$kid)) paste0(" (kid ", x$kid, ")"), "\n", sep = "")
  invisible(x)
}

#' Signataire adosse a une cle privee
#'
#' @description
#' L'algorithme se deduit de la cle : `RS256` pour une cle RSA, `ES256` pour
#' une cle ECDSA sur P-256.
#'
#' @details
#' Il n'est volontairement pas demandable. Laisser l'appelant declarer `alg`
#' tout en passant une cle d'un autre type produirait un en-tete annoncant
#' `RS256` au-dessus d'une signature ECDSA : invalide partout, y compris ici,
#' et decouvert seulement au moment ou quelqu'un cherche a verifier le visa -
#' c'est-a-dire trop tard.
#'
#' La conversion vers le format JOSE est faite ici : `openssl` signe en DER,
#' `ES256` veut du `R||S`, voir [ecdsa_der_vers_brut()].
#'
#' @param cle Cle privee lue par [openssl::read_key()], RSA ou ECDSA P-256.
#' @param claims Liste nommee des claims d'identite.
#' @param kid Identifiant de cle (facultatif).
#' @return Un objet `sommier_signataire`.
#'
#' @examples
#' cle <- openssl::rsa_keygen(2048)
#' signataire_cle(cle, claims = list(sub = "agent-01", name = "Maire"))
#'
#' # Une cle ECDSA donne un signataire ES256, sans rien declarer.
#' signataire_cle(openssl::ec_keygen("P-256"), claims = list(sub = "agent-02"))
#'
#' @export
signataire_cle <- function(cle, claims, kid = NULL) {
  alg <- alg_de_la_cle(cle)
  sommier_signataire(
    claims = claims,
    signer = function(donnees) {
      signature <- openssl::signature_create(donnees, openssl::sha256, key = cle)
      if (identical(alg, "ES256")) ecdsa_der_vers_brut(signature) else signature
    },
    alg = alg,
    kid = kid
  )
}

#' Signataire dont l'identite vient de Keycloak ou d'AgentConnect
#'
#' @description
#' Les claims sont extraits du jeton d'identite OIDC ; la signature reste
#' produite par la cle fournie.
#'
#' @details
#' Cette separation n'est pas un contournement, c'est le fonctionnement du
#' protocole : un fournisseur OIDC delivre des jetons attestant une identite,
#' il ne signe pas un contenu qu'on lui soumet. Le jeton prouve **qui** est la
#' personne, la cle produit la signature detachee sur la tete de chaine. Pour
#' un niveau eIDAS qualifie, `cle` doit etre remplacee par un appel au service
#' de signature du prestataire - c'est exactement ce que permet le parametre
#' `signer` de [sommier_signataire()].
#'
#' Le jeton n'est pas verifie ici : sa validite releve du client OIDC qui l'a
#' obtenu. Ce qui est archive dans le visa, ce sont ses claims.
#'
#' @param jeton_id Jeton d'identite OIDC (JWT compact).
#' @param cle Cle privee servant a signer.
#' @param kid Identifiant de cle (facultatif).
#' @param claims_retenus Claims a archiver dans le visa. Par defaut ceux que
#'   le brief nomme, plus `siret`.
#' @return Un objet `sommier_signataire`.
#'
#' @export
signataire_keycloak <- function(jeton_id, cle, kid = NULL,
                                claims_retenus = c("sub", "given_name",
                                                   "usual_name", "family_name",
                                                   "email", "siret", "iss")) {
  claims <- jwt_claims(jeton_id)
  retenus <- claims[intersect(claims_retenus, names(claims))]
  if (est_vide(retenus$sub)) {
    stop("Le jeton d'identite ne porte pas de claim `sub`.", call. = FALSE)
  }
  signataire_cle(cle, claims = retenus, kid = kid)
}

#' Claims d'un jeton JWT
#'
#' Decode la charge utile d'un JWT compact. **Ne verifie pas la signature** :
#' la validation du jeton releve du client OIDC qui l'a obtenu.
#'
#' @param jeton JWT compact (`en-tete.charge.signature`).
#' @return Une liste nommee.
#' @export
jwt_claims <- function(jeton) {
  parties <- strsplit(as.character(jeton), ".", fixed = TRUE)[[1]]
  if (length(parties) < 2L) {
    stop("Jeton JWT malforme : trois parties separees par des points ",
         "attendues.", call. = FALSE)
  }
  jsonlite::fromJSON(
    rawToChar(base64url_decoder(parties[[2L]])),
    simplifyVector = FALSE
  )
}

#' Signature JWS detachee sur charge non encodee
#'
#' @description
#' Produit une signature JWS detachee au sens des RFC 7515 et 7797 : l'en-tete
#' declare `"b64": false`, la charge utile ne transite pas dans le jeton, et
#' l'entree de signature est `BASE64URL(en-tete) || "." || charge`.
#'
#' @details
#' La charge est ici les 32 octets bruts de la tete de chaine. La signer
#' detachee plutot qu'encodee evite de recopier dans le jeton une valeur qui
#' vit deja dans la base : le verificateur la relit du registre, ce qui lie la
#' signature a la chaine et non a une copie.
#'
#' @param charge Vecteur `raw` a signer.
#' @param signataire Objet [sommier_signataire()].
#' @return Une chaine `en-tete..signature` (charge omise, d'ou le double point).
#'
#' @export
jws_signer_detache <- function(charge, signataire) {
  if (!inherits(signataire, "sommier_signataire")) {
    stop("`signataire` doit venir de sommier_signataire().", call. = FALSE)
  }
  charge <- if (is.character(charge)) charToRaw(enc2utf8(charge)) else charge

  entete <- compacter(list(
    alg  = signataire$alg,
    b64  = FALSE,
    crit = I("b64"),
    kid  = signataire$kid
  ))
  entete_encode <- base64url_encoder(jcs(entete))

  entree <- c(charToRaw(paste0(entete_encode, ".")), charge)
  signature <- signataire$signer(entree)

  paste0(entete_encode, "..", base64url_encoder(signature))
}

#' Verification d'une signature JWS detachee
#'
#' @details
#' Une signature `ES256` est reconvertie en DER avant d'etre soumise a
#' `openssl::signature_verify()`, qui n'accepte que ce format. Sa longueur est
#' d'abord verifiee : `ES256` impose exactement 64 octets, et une signature
#' plus courte revele une implementation qui a concatene deux `bignum` sans les
#' rembourrer. La refuser franchement vaut mieux que de la reconvertir en un
#' DER syntaxiquement correct mais portant un `r` faux.
#'
#' @param jws Jeton `en-tete..signature`.
#' @param charge Vecteur `raw` signe.
#' @param cle_publique Cle publique, lue par [openssl::read_pubkey()].
#' @return `TRUE` si la signature est valide, `FALSE` sinon.
#'
#' @examples
#' cle <- openssl::rsa_keygen(2048)
#' s <- signataire_cle(cle, claims = list(sub = "agent-01"))
#' charge <- openssl::rand_bytes(32)
#' jws <- jws_signer_detache(charge, s)
#' jws_verifier_detache(jws, charge, cle$pubkey)
#'
#' @export
jws_verifier_detache <- function(jws, charge, cle_publique) {
  # Decoupe sur le double point litteral : couper sur "." rendrait trois
  # elements, la charge omise laissant un element vide au milieu.
  parties <- strsplit(as.character(jws), "..", fixed = TRUE)[[1]]
  if (length(parties) != 2L || !nzchar(parties[[1L]]) || !nzchar(parties[[2L]])) {
    stop("JWS detache malforme : `en-tete..signature` attendu.", call. = FALSE)
  }
  charge <- if (is.character(charge)) charToRaw(enc2utf8(charge)) else charge

  entete <- jsonlite::fromJSON(
    rawToChar(base64url_decoder(parties[[1L]])),
    simplifyVector = FALSE
  )
  # Une charge non encodee verifiee comme si elle l'etait donnerait un faux
  # negatif ; l'inverse, un faux positif. L'en-tete doit donc etre lu.
  if (!identical(entete$b64, FALSE)) {
    stop("Cet en-tete ne declare pas `b64: false` : ce n'est pas une ",
         "signature detachee sur charge non encodee.", call. = FALSE)
  }
  if (!entete$alg %in% SOMMIER_ALGOS_JWS) {
    stop("Algorithme non reconnu : ", entete$alg, ".", call. = FALSE)
  }

  signature <- base64url_decoder(parties[[2L]])
  if (identical(entete$alg, "ES256")) {
    attendu <- 2L * TAILLE_COMPOSANTE_ES256
    if (length(signature) != attendu) {
      stop("Signature ES256 de ", length(signature), " octets, ", attendu,
           " attendus : les composantes n'ont pas ete rembourrees.",
           call. = FALSE)
    }
    signature <- ecdsa_brut_vers_der(signature)
  }

  entree <- c(charToRaw(paste0(parties[[1L]], ".")), charge)
  resultat <- try(
    openssl::signature_verify(entree, signature, openssl::sha256,
                              pubkey = cle_publique),
    silent = TRUE
  )
  isTRUE(!inherits(resultat, "try-error") && resultat)
}
