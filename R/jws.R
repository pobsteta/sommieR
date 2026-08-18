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
#' `RS256` seulement pour l'instant : RSASSA-PKCS1-v1_5 avec SHA-256, qui est
#' l'algorithme par defaut de Keycloak et d'AgentConnect.
#'
#' `ES256` n'est pas encore accepte, et ce n'est pas un oubli : JOSE exige la
#' signature ECDSA au format brut R||S, alors qu'OpenSSL la produit encodee en
#' DER. Accepter `ES256` sans faire la conversion produirait des signatures
#' que rien d'autre ne saurait verifier - mieux vaut refuser franchement.
#'
#' @export
SOMMIER_ALGOS_JWS <- c("RS256")

#' Construction d'un signataire
#'
#' @description
#' Contrat generique attendu par [sommier_viser()] : des claims d'identite, et
#' de quoi signer. Les deux sont volontairement separes, parce qu'ils viennent
#' de sources differentes - le fournisseur d'identite (Keycloak, AgentConnect)
#' atteste **qui** signe, une cle ou un service de signature eIDAS produit
#' **la** signature. Keycloak ne signe pas de contenu arbitraire.
#'
#' @param claims Liste nommee des claims d'identite (au minimum `sub`).
#' @param signer Fonction prenant un vecteur `raw` et rendant la signature,
#'   en `raw`.
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
#' @param cle Cle privee lue par [openssl::read_key()].
#' @param claims Liste nommee des claims d'identite.
#' @param kid Identifiant de cle (facultatif).
#' @return Un objet `sommier_signataire`.
#'
#' @examples
#' cle <- openssl::rsa_keygen(2048)
#' signataire_cle(cle, claims = list(sub = "agent-01", name = "Maire"))
#'
#' @export
signataire_cle <- function(cle, claims, kid = NULL) {
  sommier_signataire(
    claims = claims,
    signer = function(donnees) openssl::signature_create(donnees, openssl::sha256, key = cle),
    alg = "RS256",
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

  entree <- c(charToRaw(paste0(parties[[1L]], ".")), charge)
  resultat <- try(
    openssl::signature_verify(entree, base64url_decoder(parties[[2L]]),
                              openssl::sha256, pubkey = cle_publique),
    silent = TRUE
  )
  isTRUE(!inherits(resultat, "try-error") && resultat)
}
