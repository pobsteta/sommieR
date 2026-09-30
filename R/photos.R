#' Types de photo admis au depot
#'
#' @description
#' Extensions reconnues et type de media associe. Le type est ecrit dans le
#' payload, l'extension sert au nom du fichier dans le depot.
#'
#' @export
SOMMIER_TYPES_PHOTO <- c(jpg = "image/jpeg", jpeg = "image/jpeg",
                         png = "image/png", heic = "image/heic")

#' Depot d'une photo, sous son empreinte
#'
#' @description
#' Hache une photo (SHA-256), la copie dans le depot sous le nom
#' `<sha256>.<extension>`, et rend sa description prete pour le payload d'une
#' reconnaissance de limite.
#'
#' @details
#' **La photo n'entre pas dans la base, son empreinte oui.** Le payload porte
#' le SHA-256 du fichier ; les octets vivent dans le depot, sous ce nom. La
#' chaine atteste donc les octets : un recadrage, une retouche ou un
#' remplacement changent l'empreinte, et [sommier_verifier_photos()] le voit.
#'
#' **Le fichier n'est jamais modifie**, pas meme pour en retirer des
#' metadonnees. Un fichier retouche par l'outil qui pretend en garantir
#' l'integrite, ce serait la preuve fabriquee par son propre gardien.
#'
#' **Ce que l'EXIF dit est une declaration de l'appareil.** La date de prise
#' de vue et la position, lues dans l'en-tete EXIF d'un JPEG, sont recopiees
#' comme telles (`exif_date`, `exif_position`) et jamais presentees comme des
#' faits : la chaine atteste que la photo existait, avec ces octets, au moment
#' de l'ecriture - pas quand ni ou elle a ete prise. `exif_date` est l'heure
#' locale de l'appareil, sans fuseau : l'EXIF n'en porte pas.
#'
#' Deposer deux fois la meme photo ne la copie qu'une fois. Un fichier deja
#' present sous ce nom mais d'un autre contenu est une alteration du depot :
#' elle est signalee, et rien n'est ecrase.
#'
#' @param fichier Chemin de la photo.
#' @param depot Repertoire du depot. Cree s'il n'existe pas.
#'
#' @return Une liste : `sha256`, `octets`, `type`, `fichier` (nom d'origine),
#'   et `exif_date`, `exif_position` lorsque l'EXIF les porte.
#'
#' @seealso [sommier_verifier_photos()], [sommier_importer_qfield()]
#'
#' @examples
#' # p <- sommier_deposer_photo("DCIM/borne-12.jpg", "photos")
#'
#' @export
sommier_deposer_photo <- function(fichier, depot) {
  fichier <- valider_texte(fichier, "fichier")
  depot <- valider_texte(depot, "depot")
  if (!file.exists(fichier)) {
    stop("Photo introuvable : ", fichier, ".", call. = FALSE)
  }
  type <- type_photo(fichier)
  empreinte <- empreinte_fichier(fichier)
  if (!dir.exists(depot)) {
    dir.create(depot, recursive = TRUE)
  }

  cible <- chemin_photo(depot, empreinte, type)
  if (file.exists(cible)) {
    if (!identical(empreinte_fichier(cible), empreinte)) {
      stop("Le depot porte deja ", basename(cible), " sous un autre contenu : ",
           "il a ete altere. Rien n'est ecrase ; voir ",
           "sommier_verifier_photos().", call. = FALSE)
    }
  } else if (!file.copy(fichier, cible, copy.date = TRUE)) {
    stop("Impossible de copier la photo dans le depot : ", cible, ".",
         call. = FALSE)
  }

  exif <- if (identical(type, "image/jpeg")) lire_exif(fichier) else list()
  compacter(list(
    sha256 = empreinte,
    octets = as.integer(file.size(fichier)),
    type = type,
    fichier = basename(fichier),
    exif_date = exif$date,
    exif_position = exif$position
  ))
}

#' Verification des photos d'un sommier
#'
#' @description
#' Confronte chaque photo que le registre 2 reference a son fichier dans le
#' depot : conforme, alteree ou manquante.
#'
#' @details
#' **Une photo absente n'est pas une chaine rompue.** Trois cas sont
#' distingues :
#' * `conforme` : le fichier est la, et son empreinte est celle du registre ;
#' * `alteree` : le fichier est la, mais son empreinte differe - c'est une
#'   modification apres depot, et elle est signalee comme telle ;
#' * `manquante` : le fichier n'est pas dans le depot. La photo est perdue
#'   pour la lecture, mais l'empreinte chainee n'en est pas moins intacte :
#'   [sommier_verifier()] reste valide.
#'
#' @param con Connexion DBI.
#' @param foret_id UUID de la foret.
#' @param depot Repertoire du depot.
#'
#' @return Un `data.frame` : `entree_id`, `seq`, `element`, `sha256`, `type`,
#'   `fichier`, `statut`.
#'
#' @seealso [sommier_deposer_photo()]
#'
#' @export
sommier_verifier_photos <- function(con, foret_id, depot) {
  foret_id <- valider_uuid(foret_id, "foret_id")
  depot <- valider_texte(depot, "depot")
  photos <- DBI::dbGetQuery(
    con,
    "SELECT e.id::text AS entree_id, e.seq,
            e.payload -> 'element_pci' ->> 'numero' AS element,
            p ->> 'sha256' AS sha256, p ->> 'type' AS type,
            p ->> 'fichier' AS fichier
       FROM entree_sommier e
       CROSS JOIN LATERAL jsonb_array_elements(e.payload -> 'photos') AS p
      WHERE e.foret_id = $1 AND e.registre = 2 AND e.payload ? 'photos'
      ORDER BY e.seq",
    params = list(foret_id)
  )
  photos$seq <- as.numeric(photos$seq)
  photos$statut <- vapply(seq_len(nrow(photos)), function(i) {
    cible <- chemin_photo(depot, photos$sha256[[i]], photos$type[[i]])
    if (!file.exists(cible)) {
      "manquante"
    } else if (identical(empreinte_fichier(cible), photos$sha256[[i]])) {
      "conforme"
    } else {
      "alteree"
    }
  }, character(1))
  photos
}

# ---------------------------------------------------------------------------

# Une chaine nue : `openssl` rend un objet de classe `hash`, que `identical()`
# distingue d'un texte portant les memes caracteres.
empreinte_fichier <- function(chemin) {
  connexion <- file(chemin, open = "rb")
  on.exit(close(connexion), add = TRUE)
  as.vector(unclass(as.character(openssl::sha256(connexion))))
}

type_photo <- function(fichier) {
  extension <- tolower(tools::file_ext(fichier))
  if (!extension %in% names(SOMMIER_TYPES_PHOTO)) {
    stop("Type de photo non reconnu : ", basename(fichier), ". Types admis : ",
         paste(names(SOMMIER_TYPES_PHOTO), collapse = ", "), ".", call. = FALSE)
  }
  unname(SOMMIER_TYPES_PHOTO[[extension]])
}

# Le nom dans le depot ne depend que du contenu : deux photos identiques n'en
# font qu'une, et le nom suffit a verifier le fichier.
chemin_photo <- function(depot, empreinte, type) {
  extension <- c("image/jpeg" = "jpg", "image/png" = "png",
                 "image/heic" = "heic")[[type]]
  file.path(depot, paste0(empreinte, ".", extension))
}

# Lecteur EXIF minimal, pour un JPEG : la date de prise de vue et la position
# GNSS, rien d'autre. Un en-tete absent ou illisible rend une liste vide - une
# photo sans EXIF reste une photo, et l'on ne devine pas ce qu'il aurait dit.
lire_exif <- function(chemin) {
  octets <- readBin(chemin, "raw", n = min(file.size(chemin), 262144L))
  tiff <- tryCatch(segment_exif(octets), error = function(e) NULL)
  if (is.null(tiff)) {
    return(list())
  }
  tryCatch(decoder_tiff(tiff), error = function(e) list())
}

# Parcourt les marqueurs JPEG jusqu'au segment APP1 « Exif », et en rend le
# contenu TIFF.
segment_exif <- function(octets) {
  if (length(octets) < 4L || !identical(octets[1:2], as.raw(c(0xFF, 0xD8)))) {
    return(NULL)
  }
  i <- 3L
  while (i + 3L <= length(octets)) {
    if (octets[[i]] != as.raw(0xFF)) {
      return(NULL)
    }
    marqueur <- as.integer(octets[[i + 1L]])
    if (marqueur == 0xDA || marqueur == 0xD9) {
      return(NULL)
    }
    longueur <- as.integer(octets[[i + 2L]]) * 256L + as.integer(octets[[i + 3L]])
    debut <- i + 4L
    fin <- i + 1L + longueur
    if (marqueur == 0xE1 && fin <= length(octets) &&
        identical(rawToChar(octets[debut:(debut + 3L)]), "Exif")) {
      return(octets[(debut + 6L):fin])
    }
    i <- fin + 1L
  }
  NULL
}

decoder_tiff <- function(tiff) {
  petit <- identical(rawToChar(tiff[1:2]), "II")
  entier <- function(position, taille) {
    b <- as.integer(tiff[(position + 1L):(position + taille)])
    if (!petit) b <- rev(b)
    sum(b * 256^(seq_along(b) - 1L))
  }
  lire_ifd <- function(position) {
    n <- entier(position, 2L)
    entrees <- lapply(seq_len(n), function(k) {
      p <- position + 2L + (k - 1L) * 12L
      list(balise = entier(p, 2L), type = entier(p + 2L, 2L),
           nombre = entier(p + 4L, 4L), valeur = p + 8L)
    })
    stats::setNames(entrees, vapply(entrees, function(e) e$balise, 0))
  }
  # Une valeur de plus de quatre octets est rangee ailleurs, a l'adresse que
  # porte le champ.
  adresse <- function(e, taille) {
    if (taille <= 4L) e$valeur else entier(e$valeur, 4L)
  }
  texte <- function(e) {
    b <- tiff[(adresse(e, e$nombre) + 1L):(adresse(e, e$nombre) + e$nombre)]
    rawToChar(b[b != as.raw(0)])
  }
  rationnels <- function(e) {
    a <- adresse(e, 8L * e$nombre)
    vapply(seq_len(e$nombre) - 1L, function(k) {
      entier(a + 8L * k, 4L) / entier(a + 8L * k + 4L, 4L)
    }, 0)
  }

  ifd0 <- lire_ifd(entier(4L, 4L))
  resultat <- list()

  date <- NULL
  if (!is.null(ifd0[["34665"]])) {
    exif <- lire_ifd(entier(ifd0[["34665"]]$valeur, 4L))
    if (!is.null(exif[["36867"]])) date <- texte(exif[["36867"]])
  }
  if (is.null(date) && !is.null(ifd0[["306"]])) {
    date <- texte(ifd0[["306"]])
  }
  if (!is.null(date) && grepl("^[0-9]{4}:[0-9]{2}:[0-9]{2} [0-9:]{8}$", date)) {
    resultat$date <- sub("^([0-9]{4}):([0-9]{2}):([0-9]{2}) ", "\\1-\\2-\\3T",
                         date)
  }

  if (!is.null(ifd0[["34853"]])) {
    gps <- lire_ifd(entier(ifd0[["34853"]]$valeur, 4L))
    if (all(c("1", "2", "3", "4") %in% names(gps))) {
      degres <- function(r) sum(r * c(1, 1 / 60, 1 / 3600))
      lat <- degres(rationnels(gps[["2"]]))
      lon <- degres(rationnels(gps[["4"]]))
      if (identical(texte(gps[["1"]]), "S")) lat <- -lat
      if (identical(texte(gps[["3"]]), "W")) lon <- -lon
      if (is.finite(lat) && is.finite(lon)) {
        resultat$position <- sprintf("%.6f,%.6f", lat, lon)
      }
    }
  }
  resultat
}
