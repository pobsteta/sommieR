#' Serialisation JSON canonique (RFC 8785, JCS)
#'
#' @description
#' `jcs()` produit la representation canonique JCS d'une valeur R. C'est la
#' brique de base du chainage de hachages du sommier : deux representations
#' d'un meme payload doivent produire des octets strictement identiques, sinon
#' la chaine n'est pas verifiable par un tiers.
#'
#' Le JSONB restitue par PostgreSQL ne convient pas (il reordonne les cles et
#' normalise les nombres) : conformement au brief, le hachage est calcule cote
#' R et la base ne fait que stocker et contraindre.
#'
#' @details
#' Regles appliquees (RFC 8785 sections 3.2.2 a 3.2.4) :
#'
#' * **Objets** : cles triees par ordre des unites de code UTF-16, aucun
#'   espace, `"cle":valeur`.
#' * **Tableaux** : ordre d'origine preserve.
#' * **Chaines** : echappement minimal RFC 8259 (`\"`, `\\`, `\b`, `\f`,
#'   `\n`, `\r`, `\t`), autres caracteres de controle en `\u00xx` minuscule,
#'   tout le reste litteral en UTF-8.
#' * **Nombres** : algorithme ECMAScript `Number::toString` (voir
#'   [jcs_nombre()]). `NaN` et les infinis sont refuses, JSON ne les
#'   representant pas.
#' * **Litteraux** : `true`, `false`, `null`.
#'
#' Correspondance R -> JSON :
#'
#' | Valeur R                                   | JSON              |
#' | ------------------------------------------ | ----------------- |
#' | `NULL`                                     | `null`            |
#' | liste nommee                               | objet             |
#' | liste non nommee                           | tableau           |
#' | `structure(list(), names = character(0))`  | `{}`              |
#' | `list()`                                   | `[]`              |
#' | atomique de longueur 1                     | scalaire          |
#' | atomique de longueur != 1                  | tableau           |
#' | atomique de longueur 1 dans `I()`          | tableau a 1 element |
#' | `NA`                                       | erreur (ambigu)   |
#'
#' Ces conventions sont celles de `jsonlite::toJSON(auto_unbox = TRUE)`, a
#' ceci pres que `NA` est refuse : `null` et "valeur manquante" ne sont pas
#' interchangeables dans un registre a valeur probante, il faut ecrire `NULL`
#' explicitement.
#'
#' @param x Valeur R a serialiser.
#'
#' @return Une chaine de caracteres de longueur 1, en UTF-8.
#'
#' @seealso [jcs_nombre()], [sommier_empreinte()]
#'
#' @examples
#' jcs(list(b = 1, a = "x"))
#' #> {"a":"x","b":1}
#' jcs(list(volume_m3 = 12.5, essence = "HET"))
#'
#' @export
jcs <- function(x) {
  paste0(jcs_valeur(x), collapse = "")
}

jcs_valeur <- function(x) {
  if (is.null(x)) {
    return("null")
  }

  if (inherits(x, "AsIs")) {
    x <- unclass(x)
    if (is.atomic(x)) {
      return(jcs_tableau(as.list(x)))
    }
  }

  if (is.list(x)) {
    nms <- names(x)
    if (is.null(nms)) {
      return(jcs_tableau(x))
    }
    if (any(is.na(nms)) || any(nms == "")) {
      stop(
        "jcs(): liste partiellement nommee ; un objet JSON exige que ",
        "toutes les cles soient renseignees.",
        call. = FALSE
      )
    }
    return(jcs_objet(x))
  }

  if (!is.atomic(x)) {
    stop(
      "jcs(): type non serialisable en JSON : ", class(x)[1], ".",
      call. = FALSE
    )
  }

  # Les dates et horodatages sont serialises en texte ISO-8601 : le sommier
  # doit rester lisible et reverifiable hors de R.
  if (inherits(x, "Date") || inherits(x, "POSIXt")) {
    x <- format_temps(x)
  }

  if (anyNA(x)) {
    stop(
      "jcs(): NA rencontre. JSON ne distingue pas NA de null ; ecrire NULL ",
      "explicitement si la valeur est absente.",
      call. = FALSE
    )
  }

  if (length(x) == 1L) {
    return(jcs_scalaire(x))
  }
  jcs_tableau(as.list(x))
}

jcs_objet <- function(x) {
  cles <- names(x)
  if (anyDuplicated(cles)) {
    stop(
      "jcs(): cles dupliquees dans un objet JSON : ",
      paste(unique(cles[duplicated(cles)]), collapse = ", "), ".",
      call. = FALSE
    )
  }
  ordre <- ordre_utf16(cles)
  membres <- vapply(
    ordre,
    function(i) paste0(jcs_chaine(cles[[i]]), ":", jcs_valeur(x[[i]])),
    character(1)
  )
  paste0("{", paste0(membres, collapse = ","), "}")
}

jcs_tableau <- function(x) {
  if (length(x) == 0L) {
    return("[]")
  }
  elements <- vapply(seq_along(x), function(i) jcs_valeur(x[[i]]), character(1))
  paste0("[", paste0(elements, collapse = ","), "]")
}

jcs_scalaire <- function(x) {
  if (is.character(x)) {
    return(jcs_chaine(x))
  }
  if (is.logical(x)) {
    return(if (isTRUE(x)) "true" else "false")
  }
  if (is.numeric(x)) {
    return(jcs_nombre(as.numeric(x)))
  }
  if (is.raw(x)) {
    # Le brut n'a pas de representation JSON : on impose un choix explicite en
    # amont (hexadecimal ou base64) plutot que d'en inventer un ici.
    stop(
      "jcs(): vecteur raw non serialisable ; convertir explicitement ",
      "(par exemple avec openssl::base64_encode()).",
      call. = FALSE
    )
  }
  stop("jcs(): type atomique non gere : ", typeof(x), ".", call. = FALSE)
}

#' Tri des cles par unites de code UTF-16
#'
#' RFC 8785 impose l'ordre des unites de code UTF-16, qui differe de l'ordre
#' par points de code des que des caracteres hors du plan multilingue de base
#' sont presents (les substituts U+D800..U+DFFF se classent avant U+E000).
#' `order()` de R depend de surcroit de la locale : on encode donc chaque cle
#' en UTF-16BE et on compare les octets.
#'
#' @param cles Vecteur de caracteres.
#' @return Vecteur d'entiers, permutation de `seq_along(cles)`.
#' @noRd
ordre_utf16 <- function(cles) {
  if (length(cles) <= 1L) {
    return(seq_along(cles))
  }
  cles_utf8 <- enc2utf8(cles)
  # Chaque cle devient une chaine d'octets UTF-16BE representee en hexadecimal,
  # ce qui rend la comparaison lexicographique independante de la locale.
  cles_hex <- vapply(
    cles_utf8,
    function(cle) {
      octets <- iconv(cle, from = "UTF-8", to = "UTF-16BE", toRaw = TRUE)[[1]]
      if (is.null(octets)) {
        stop("jcs(): cle non convertible en UTF-16 : ", cle, ".", call. = FALSE)
      }
      paste0(sprintf("%02x", as.integer(octets)), collapse = "")
    },
    character(1),
    USE.NAMES = FALSE
  )
  order(cles_hex, method = "radix")
}

#' Echappement JCS d'une chaine
#'
#' @param s Chaine de longueur 1.
#' @return La chaine entre guillemets, echappee.
#' @noRd
jcs_chaine <- function(s) {
  s <- enc2utf8(as.character(s))
  points <- utf8ToInt(s)
  if (length(points) == 0L) {
    return("\"\"")
  }
  if (anyNA(points)) {
    stop("jcs(): chaine invalide en UTF-8.", call. = FALSE)
  }

  morceaux <- vapply(
    points,
    function(cp) {
      if (cp == 0x22L) {
        return("\\\"")
      }
      if (cp == 0x5CL) {
        return("\\\\")
      }
      if (cp == 0x08L) {
        return("\\b")
      }
      if (cp == 0x0CL) {
        return("\\f")
      }
      if (cp == 0x0AL) {
        return("\\n")
      }
      if (cp == 0x0DL) {
        return("\\r")
      }
      if (cp == 0x09L) {
        return("\\t")
      }
      if (cp < 0x20L) {
        return(sprintf("\\u%04x", cp))
      }
      intToUtf8(cp)
    },
    character(1)
  )
  paste0("\"", paste0(morceaux, collapse = ""), "\"")
}

#' Serialisation d'un nombre selon ECMAScript `Number::toString`
#'
#' @description
#' RFC 8785 renvoie a l'algorithme ECMAScript : la representation decimale la
#' plus courte qui se relit exactement en IEEE 754 double precision, avec
#' bascule en notation exponentielle en dehors de la plage `1e-7` .. `1e21`.
#'
#' @details
#' Soient `n`, `k` et `s` les entiers tels que `k >= 1`,
#' `10^(k-1) <= s < 10^k`, `s * 10^(n-k) == m`, et `k` minimal. Alors :
#'
#' * `k <= n <= 21` : chiffres de `s` suivis de `n - k` zeros ;
#' * `0 < n <= 21` : chiffres de `s` avec un point apres `n` chiffres ;
#' * `-6 < n <= 0` : `"0."`, `-n` zeros, puis les chiffres de `s` ;
#' * sinon : notation exponentielle sur `n - 1`.
#'
#' `k` minimal est obtenu en augmentant le nombre de chiffres significatifs
#' jusqu'a ce que la relecture redonne la valeur d'origine au bit pres.
#'
#' @param m Nombre fini de longueur 1.
#' @return Une chaine de caracteres.
#'
#' @examples
#' jcs_nombre(1)       # "1"
#' jcs_nombre(1e21)    # "1e+21"
#' jcs_nombre(1e-7)    # "1e-7"
#' jcs_nombre(0.1)     # "0.1"
#'
#' @export
jcs_nombre <- function(m) {
  m <- as.numeric(m)
  if (length(m) != 1L) {
    stop("jcs_nombre(): un seul nombre attendu.", call. = FALSE)
  }
  if (is.na(m)) {
    stop("jcs_nombre(): NA/NaN n'a pas de representation JSON.", call. = FALSE)
  }
  if (is.infinite(m)) {
    stop("jcs_nombre(): les infinis n'ont pas de representation JSON.",
         call. = FALSE)
  }
  # ECMAScript : String(-0) vaut "0".
  if (m == 0) {
    return("0")
  }

  signe <- if (m < 0) "-" else ""
  m <- abs(m)

  # Plus petit nombre de chiffres significatifs qui se relit exactement.
  k <- 1L
  repere <- sprintf("%.*e", 0L, m)
  while (k < 17L && as.numeric(repere) != m) {
    k <- k + 1L
    repere <- sprintf("%.*e", k - 1L, m)
  }

  parties <- strsplit(repere, "e", fixed = TRUE)[[1]]
  chiffres <- gsub(".", "", parties[[1]], fixed = TRUE)
  exposant <- as.integer(parties[[2]])

  # sprintf peut rendre des zeros de queue lorsque la valeur exacte se termine
  # par des zeros ; ils ne font pas partie de la representation minimale.
  chiffres <- sub("0+$", "", chiffres)
  if (chiffres == "") {
    chiffres <- "0"
  }
  k <- nchar(chiffres)
  n <- exposant + 1L

  corps <- if (k <= n && n <= 21L) {
    paste0(chiffres, strrep("0", n - k))
  } else if (n > 0L && n <= 21L) {
    paste0(substr(chiffres, 1L, n), ".", substr(chiffres, n + 1L, k))
  } else if (n > -6L && n <= 0L) {
    paste0("0.", strrep("0", -n), chiffres)
  } else {
    mantisse <- if (k == 1L) {
      chiffres
    } else {
      paste0(substr(chiffres, 1L, 1L), ".", substr(chiffres, 2L, k))
    }
    paste0(mantisse, "e", if (n - 1L >= 0L) "+" else "-", abs(n - 1L))
  }

  paste0(signe, corps)
}

#' Recanonisation d'un document JSON existant
#'
#' Utile pour verifier une chaine a partir d'un export : le payload y est du
#' texte JSON, qu'il faut recanoniser avant de recalculer l'empreinte.
#'
#' @param texte Chaine de caracteres contenant un document JSON.
#' @return La forme canonique JCS de ce document.
#'
#' @examples
#' jcs_depuis_json('{"b":1,"a":2}')
#' #> {"a":2,"b":1}
#'
#' @export
jcs_depuis_json <- function(texte) {
  valeur <- jsonlite::fromJSON(
    texte,
    simplifyVector = FALSE,
    simplifyDataFrame = FALSE,
    simplifyMatrix = FALSE
  )
  jcs(normaliser_json_lu(valeur))
}

# jsonlite rend `{}` comme une liste nommee vide et `[]` comme une liste nue :
# la distinction est deja portee par l'attribut names, il n'y a rien a
# reconstruire. On se contente de refuser ce que JCS ne sait pas hacher.
normaliser_json_lu <- function(x) {
  if (is.null(x)) {
    return(NULL)
  }
  if (is.list(x)) {
    if (length(x) == 0L) {
      return(if (is.null(names(x))) list() else structure(list(), names = character(0)))
    }
    return(lapply(x, normaliser_json_lu))
  }
  x
}

format_temps <- function(x) {
  if (inherits(x, "Date")) {
    return(format(x, "%Y-%m-%d"))
  }
  format(as.POSIXct(x, tz = "UTC"), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
}
