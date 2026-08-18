#' Version de l'algorithme de chainage
#'
#' Identifiant de l'algorithme d'empreinte, inclus dans les octets haches afin
#' que la chaine soit auto-descriptive : un verificateur lisant un export sait
#' quelle regle appliquer, et un changement d'algorithme ne peut pas passer
#' pour la meme chaine.
#'
#' @export
SOMMIER_VERSION_CHAINE <- "sommier-chaine-1"

#' Champs couverts par l'empreinte d'une entree
#'
#' @description
#' Les champs de [entree_sommier][sommier_entree()] qui entrent dans le calcul
#' de l'empreinte, dans l'ordre ou ils sont documentes. `payload` en fait
#' partie, mais il n'est pas le seul.
#'
#' @details
#' **Ecart assume par rapport au brief.** La section 6.1 du brief pose
#' `hash_n = SHA-256( JCS(payload_n) || hash_{n-1} )`, ou seul le payload est
#' hache. Cette formule laisse hors chaine `registre`, `ug_uuid`,
#' `date_evenement`, `auteur`, `ndp`, `seq` et `corrige_id` : on pourrait
#' reaffecter une coupe a une autre unite de gestion, en changer la date ou
#' l'auteur, sans qu'aucune empreinte ne bouge. Le declencheur PostgreSQL
#' l'interdit cote serveur, mais l'objectif annonce est justement que
#' "chaque acteur peut reverifier la chaine localement a partir d'un export,
#' sans faire confiance au serveur" : un export dont les metadonnees ne sont
#' pas couvertes n'est pas verifiable.
#'
#' La forme de la formule est conservee - SHA-256 d'une serialisation
#' canonique concatenee a l'empreinte precedente - mais elle porte sur
#' l'enregistrement complet plutot que sur le seul payload.
#'
#' @export
SOMMIER_CHAMPS_EMPREINTE <- c(
  "foret_id", "seq", "registre", "ug_uuid", "date_evenement",
  "date_saisie", "auteur", "ndp", "corrige_id", "schema_version", "payload"
)

#' Empreinte de genese d'une foret
#'
#' Premier maillon de la chaine : l'empreinte precedente de l'entree de
#' sequence 1. Conformement au brief (section 6.2), il s'agit du SHA-256 de
#' l'identifiant de la foret, pris sur ses octets UTF-8 en forme canonique
#' minuscule.
#'
#' @param foret_id Identifiant UUID de la foret.
#' @return Un vecteur `raw` de 32 octets.
#'
#' @examples
#' sommier_empreinte_genese("3f2b1c4d-5e6f-4a7b-8c9d-0e1f2a3b4c5d")
#'
#' @export
sommier_empreinte_genese <- function(foret_id) {
  foret_id <- valider_uuid(foret_id, "foret_id")
  as.raw(openssl::sha256(charToRaw(foret_id)))
}

#' Enregistrement canonique d'une entree
#'
#' Construit la liste nommee effectivement serialisee puis hachee. Isolee dans
#' sa propre fonction pour qu'un verificateur tiers puisse la reproduire, et
#' pour que les tests puissent constater exactement ce qui est couvert.
#'
#' @param entree Liste nommee decrivant l'entree (voir
#'   [SOMMIER_CHAMPS_EMPREINTE]).
#' @return Une liste nommee prete pour [jcs()].
#'
#' @export
sommier_enregistrement_canonique <- function(entree) {
  manquants <- setdiff(SOMMIER_CHAMPS_EMPREINTE, names(entree))
  if (length(manquants) > 0L) {
    stop(
      "sommier_enregistrement_canonique(): champ(s) absent(s) : ",
      paste(manquants, collapse = ", "), ".",
      call. = FALSE
    )
  }

  list(
    version_chaine = SOMMIER_VERSION_CHAINE,
    foret_id       = valider_uuid(entree$foret_id, "foret_id"),
    seq            = valider_entier(entree$seq, "seq", min = 1),
    registre       = valider_entier(entree$registre, "registre", min = 1, max = 9),
    ug_uuid        = if (est_vide(entree$ug_uuid)) NULL else valider_uuid(entree$ug_uuid, "ug_uuid"),
    date_evenement = format_date(entree$date_evenement, "date_evenement"),
    date_saisie    = format_instant(entree$date_saisie, "date_saisie"),
    auteur         = valider_texte(entree$auteur, "auteur"),
    ndp            = valider_entier(entree$ndp, "ndp", min = 0),
    corrige_id     = if (est_vide(entree$corrige_id)) NULL else valider_uuid(entree$corrige_id, "corrige_id"),
    schema_version = valider_texte(entree$schema_version, "schema_version"),
    payload        = entree$payload
  )
}

#' Empreinte d'une entree de sommier
#'
#' @description
#' `hash_n = SHA-256( JCS(enregistrement_n) || hash_{n-1} )`, ou
#' `enregistrement_n` est produit par [sommier_enregistrement_canonique()] et
#' `||` designe la concatenation des octets.
#'
#' @param entree Liste nommee decrivant l'entree.
#' @param hash_prev Vecteur `raw` de 32 octets : l'empreinte de l'entree
#'   precedente, ou [sommier_empreinte_genese()] pour la premiere.
#' @return Un vecteur `raw` de 32 octets.
#'
#' @seealso [sommier_verifier_chaine()]
#'
#' @export
sommier_empreinte <- function(entree, hash_prev) {
  hash_prev <- valider_empreinte(hash_prev, "hash_prev")
  canonique <- sommier_enregistrement_canonique(entree)
  octets <- c(charToRaw(enc2utf8(jcs(canonique))), hash_prev)
  as.raw(openssl::sha256(octets))
}

#' Empreinte en hexadecimal
#'
#' @param x Vecteur `raw`.
#' @return Chaine hexadecimale minuscule.
#' @export
empreinte_hex <- function(x) {
  paste0(sprintf("%02x", as.integer(x)), collapse = "")
}

#' Empreinte depuis une chaine hexadecimale
#'
#' @param x Chaine hexadecimale de 64 caracteres.
#' @return Vecteur `raw` de 32 octets.
#' @export
empreinte_depuis_hex <- function(x) {
  x <- tolower(trimws(as.character(x)))
  if (length(x) != 1L || is.na(x) || !grepl("^[0-9a-f]{64}$", x)) {
    stop(
      "empreinte_depuis_hex(): 64 caracteres hexadecimaux attendus.",
      call. = FALSE
    )
  }
  as.raw(strtoi(substring(x, seq(1L, 63L, by = 2L), seq(2L, 64L, by = 2L)), 16L))
}
