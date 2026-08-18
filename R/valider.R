# Validateurs partages. Ils sont volontairement stricts : une entree de
# sommier est destinee a etre hachee puis opposable, une coercition
# silencieuse y produirait une empreinte qui ne correspond pas a ce que
# l'utilisateur croit avoir ecrit.

est_vide <- function(x) {
  is.null(x) || length(x) == 0L || (length(x) == 1L && is.na(x))
}

MOTIF_UUID <- "^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$"

valider_uuid <- function(x, nom) {
  if (est_vide(x)) {
    stop("`", nom, "` est obligatoire.", call. = FALSE)
  }
  x <- tolower(trimws(as.character(x)))
  if (length(x) != 1L || !grepl(MOTIF_UUID, x)) {
    stop("`", nom, "` doit etre un UUID canonique, recu : ",
         paste(x, collapse = ", "), ".", call. = FALSE)
  }
  x
}

valider_texte <- function(x, nom, longueur_min = 1L) {
  if (est_vide(x)) {
    stop("`", nom, "` est obligatoire.", call. = FALSE)
  }
  if (!is.character(x) || length(x) != 1L) {
    stop("`", nom, "` doit etre une chaine de caracteres de longueur 1.",
         call. = FALSE)
  }
  if (nchar(x) < longueur_min) {
    stop("`", nom, "` doit compter au moins ", longueur_min, " caractere(s).",
         call. = FALSE)
  }
  enc2utf8(x)
}

valider_entier <- function(x, nom, min = NULL, max = NULL) {
  if (est_vide(x)) {
    stop("`", nom, "` est obligatoire.", call. = FALSE)
  }
  if (!is.numeric(x) || length(x) != 1L) {
    stop("`", nom, "` doit etre un nombre de longueur 1.", call. = FALSE)
  }
  if (x != trunc(x)) {
    stop("`", nom, "` doit etre entier, recu : ", x, ".", call. = FALSE)
  }
  x <- as.numeric(x)
  if (!is.null(min) && x < min) {
    stop("`", nom, "` doit etre >= ", min, ", recu : ", x, ".", call. = FALSE)
  }
  if (!is.null(max) && x > max) {
    stop("`", nom, "` doit etre <= ", max, ", recu : ", x, ".", call. = FALSE)
  }
  x
}

valider_nombre <- function(x, nom, min = NULL, max = NULL) {
  if (est_vide(x)) {
    stop("`", nom, "` est obligatoire.", call. = FALSE)
  }
  if (!is.numeric(x) || length(x) != 1L) {
    stop("`", nom, "` doit etre un nombre de longueur 1.", call. = FALSE)
  }
  if (is.infinite(x)) {
    stop("`", nom, "` doit etre fini.", call. = FALSE)
  }
  x <- as.numeric(x)
  if (!is.null(min) && x < min) {
    stop("`", nom, "` doit etre >= ", min, ", recu : ", x, ".", call. = FALSE)
  }
  if (!is.null(max) && x > max) {
    stop("`", nom, "` doit etre <= ", max, ", recu : ", x, ".", call. = FALSE)
  }
  x
}

valider_choix <- function(x, nom, choix) {
  x <- valider_texte(x, nom)
  if (!x %in% choix) {
    stop("`", nom, "` doit valoir l'une de : ", paste(choix, collapse = ", "),
         " ; recu : ", x, ".", call. = FALSE)
  }
  x
}

format_date <- function(x, nom) {
  if (est_vide(x)) {
    stop("`", nom, "` est obligatoire.", call. = FALSE)
  }
  if (inherits(x, "Date")) {
    return(format(x, "%Y-%m-%d"))
  }
  if (inherits(x, "POSIXt")) {
    return(format(as.Date(x, tz = "UTC"), "%Y-%m-%d"))
  }
  x <- as.character(x)
  if (length(x) != 1L || !grepl("^[0-9]{4}-[0-9]{2}-[0-9]{2}$", x)) {
    stop("`", nom, "` doit etre une date ISO-8601 (AAAA-MM-JJ), recu : ",
         paste(x, collapse = ", "), ".", call. = FALSE)
  }
  if (is.na(as.Date(x, format = "%Y-%m-%d"))) {
    stop("`", nom, "` n'est pas une date valide : ", x, ".", call. = FALSE)
  }
  x
}

format_instant <- function(x, nom) {
  if (est_vide(x)) {
    stop("`", nom, "` est obligatoire.", call. = FALSE)
  }
  if (inherits(x, "POSIXt")) {
    return(format(as.POSIXct(x, tz = "UTC"), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"))
  }
  x <- as.character(x)
  if (length(x) != 1L || !grepl("^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$", x)) {
    stop("`", nom, "` doit etre un instant UTC ISO-8601 ",
         "(AAAA-MM-JJTHH:MM:SSZ), recu : ", paste(x, collapse = ", "), ".",
         call. = FALSE)
  }
  x
}

valider_empreinte <- function(x, nom) {
  if (is.character(x)) {
    x <- empreinte_depuis_hex(x)
  }
  if (!is.raw(x) || length(x) != 32L) {
    stop("`", nom, "` doit etre une empreinte SHA-256 de 32 octets.",
         call. = FALSE)
  }
  x
}

#' Generation d'un UUID version 4
#'
#' Utilise le generateur d'aleas cryptographique d'openssl : les identifiants
#' d'unites de gestion ne doivent jamais entrer en collision ni etre
#' devinables, puisqu'ils sont stables a vie.
#'
#' @param n Nombre d'identifiants a produire.
#' @return Un vecteur de caracteres.
#'
#' @examples
#' uuid_v4()
#'
#' @export
uuid_v4 <- function(n = 1L) {
  vapply(seq_len(n), function(i) {
    octets <- openssl::rand_bytes(16L)
    octets[7L] <- as.raw(bitwOr(bitwAnd(as.integer(octets[7L]), 0x0f), 0x40))
    octets[9L] <- as.raw(bitwOr(bitwAnd(as.integer(octets[9L]), 0x3f), 0x80))
    hex <- sprintf("%02x", as.integer(octets))
    paste0(
      paste0(hex[1:4], collapse = ""), "-",
      paste0(hex[5:6], collapse = ""), "-",
      paste0(hex[7:8], collapse = ""), "-",
      paste0(hex[9:10], collapse = ""), "-",
      paste0(hex[11:16], collapse = "")
    )
  }, character(1))
}
