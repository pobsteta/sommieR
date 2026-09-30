# Lecture des reconnaissances de limite pour le rapport : les constats, leur
# ecart au plan, et les photos qu'ils referencent.

# Precision graphique du plan : 0,2 mm a l'echelle d'origine de la feuille,
# soit 0,4 m au 1/2000 et 1 m au 1/5000. L'echelle vient des elements du plan
# passes au rapport ; faute de quoi on retient 1 m, la valeur de la plus
# petite echelle courante en foret, et le rapport le dit.
PRECISION_GRAPHIQUE_M <- 0.0002
PRECISION_PLAN_DEFAUT_M <- 1

lire_reconnaissances <- function(con, foret_id, elements = NULL) {
  lignes <- DBI::dbGetQuery(
    con,
    "SELECT r.id::text AS id, r.seq, r.date_evenement, r.date_saisie,
            e.payload::text AS payload, ST_X(r.geom) AS x_releve,
            ST_Y(r.geom) AS y_releve
       FROM v_reconnaissance_limite r
       JOIN entree_sommier e ON e.id = r.id
      WHERE r.foret_id = $1
      ORDER BY r.date_evenement, r.seq",
    params = list(foret_id)
  )
  if (nrow(lignes) == 0L) {
    return(NULL)
  }
  payloads <- lapply(lignes$payload, jsonlite::fromJSON,
                     simplifyVector = FALSE)
  champ <- function(nom, sous = NULL) {
    vapply(payloads, function(p) {
      v <- if (is.null(sous)) p[[nom]] else p[[sous]][[nom]]
      if (is.null(v)) NA_character_ else as.character(v)
    }, character(1))
  }

  constats <- data.frame(
    id = lignes$id, seq = as.numeric(lignes$seq),
    element_id = champ("id", "element_pci"),
    numero = champ("numero", "element_pci"),
    categorie = champ("categorie", "element_pci"),
    etat = champ("etat"),
    date_visite = as.Date(lignes$date_evenement),
    visite_le = as.POSIXct(champ("visite_le"), format = "%Y-%m-%dT%H:%M:%SZ",
                           tz = "UTC"),
    date_saisie = as.POSIXct(lignes$date_saisie, tz = "UTC"),
    operateur = champ("operateur"),
    precision_m = suppressWarnings(as.numeric(champ("precision_m"))),
    x_releve = as.numeric(lignes$x_releve),
    y_releve = as.numeric(lignes$y_releve),
    x_plan = suppressWarnings(as.numeric(champ("x", "element_pci"))),
    y_plan = suppressWarnings(as.numeric(champ("y", "element_pci"))),
    nb_photos = vapply(payloads, function(p) length(p$photos), integer(1)),
    stringsAsFactors = FALSE
  )
  # Un ecart au plan n'a de sens que pour une position mesuree. Sans
  # precision declaree, la position a ete pointee sur la carte - c'est ce que
  # montre le premier retour de QField quand le positionnement est coupe - et
  # l'ecart ne mesurerait que le doigt de l'agent.
  constats$mesure <- !is.na(constats$precision_m) & !is.na(constats$x_releve)
  constats$ecart_m <- ifelse(
    constats$mesure & !is.na(constats$x_plan),
    sqrt((constats$x_releve - constats$x_plan)^2 +
           (constats$y_releve - constats$y_plan)^2),
    NA_real_
  )
  echelle <- if (!is.null(elements) && !is.null(elements$echelle)) {
    elements$echelle[match(constats$element_id, elements$id)]
  } else {
    rep(NA_real_, nrow(constats))
  }
  constats$echelle <- echelle
  constats$tolerance_plan_m <- ifelse(is.na(echelle), PRECISION_PLAN_DEFAUT_M,
                                      echelle * PRECISION_GRAPHIQUE_M)
  constats$compatible <- ifelse(
    is.na(constats$ecart_m), NA,
    constats$ecart_m <= constats$precision_m + constats$tolerance_plan_m
  )
  constats$delai_h <- as.numeric(difftime(constats$date_saisie,
                                          constats$visite_le, units = "hours"))

  photos <- do.call(rbind, lapply(seq_along(payloads), function(i) {
    p <- payloads[[i]]$photos
    if (length(p) == 0L) return(NULL)
    data.frame(
      entree_id = constats$id[[i]], numero = constats$numero[[i]],
      etat = constats$etat[[i]], date_visite = constats$date_visite[[i]],
      sha256 = vapply(p, function(x) x$sha256, ""),
      type = vapply(p, function(x) x$type, ""),
      exif_date = vapply(p, function(x) x$exif_date %||% NA_character_, ""),
      exif_position = vapply(p, function(x) x$exif_position %||% NA_character_,
                             ""),
      stringsAsFactors = FALSE
    )
  }))
  list(constats = constats, photos = photos)
}

# Les vignettes de la planche. Seul l'original est atteste : la vignette est
# une reduction faite au rendu, pour que le document reste lisible et leger.
# Une photo dont l'empreinte ne tient plus n'en recoit pas - l'afficher
# montrerait autre chose que ce que la chaine atteste.
preparer_vignettes <- function(photos, depot, atelier, cote = 600L) {
  if (is.null(photos) || nrow(photos) == 0L) {
    return(photos)
  }
  dossier <- file.path(atelier, "vignettes")
  dir.create(dossier, showWarnings = FALSE)
  photos$statut <- NA_character_
  photos$vignette <- NA_character_
  for (i in seq_len(nrow(photos))) {
    source <- chemin_photo(depot, photos$sha256[[i]], photos$type[[i]])
    if (!file.exists(source)) {
      photos$statut[[i]] <- "manquante"
      next
    }
    if (!identical(empreinte_fichier(source), photos$sha256[[i]])) {
      photos$statut[[i]] <- "alteree"
      next
    }
    photos$statut[[i]] <- "conforme"
    cible <- file.path(dossier, paste0(photos$sha256[[i]], ".jpg"))
    if (reduire_photo(source, cible, cote)) {
      photos$vignette[[i]] <- file.path("vignettes", basename(cible))
    }
  }
  photos
}

# GDAL, deja la par `sf`, lit le JPEG et le PNG et reduit sans autre
# dependance. Un format qu'il ne lit pas (HEIC) laisse la photo sans vignette,
# et le rapport le dit.
reduire_photo <- function(source, cible, cote) {
  if (!requireNamespace("sf", quietly = TRUE)) {
    return(FALSE)
  }
  info <- try(sf::gdal_utils("info", source, quiet = TRUE), silent = TRUE)
  if (inherits(info, "try-error")) {
    return(FALSE)
  }
  taille <- regmatches(info, regexec("Size is ([0-9]+), ([0-9]+)", info))[[1L]]
  if (length(taille) != 3L) {
    return(FALSE)
  }
  largeur <- as.numeric(taille[[2L]])
  hauteur <- as.numeric(taille[[3L]])
  dimensions <- if (largeur >= hauteur) c(cote, 0L) else c(0L, cote)
  fait <- try(sf::gdal_utils(
    "translate", source, cible, quiet = TRUE,
    options = c("-of", "JPEG", "-outsize", as.character(dimensions),
                "-co", "QUALITY=80")
  ), silent = TRUE)
  unlink(paste0(cible, ".aux.xml"))
  !inherits(fait, "try-error") && file.exists(cible)
}
