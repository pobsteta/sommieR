#' Inscription des coupes SUFOSAT comme detections
#'
#' @description
#' Inscrit au registre 8, comme detections a verifier, les coupes rases
#' detectees par SUFOSAT qu'aucun martelage n'explique : celles que le rapport
#' signale sous la balance. Une fois inscrites, elles se confirment ou
#' s'ecartent sur le terrain comme toute detection.
#'
#' @details
#' **Un pas explicite.** Une coupe detectee n'est au registre que si le
#' gestionnaire l'y met : c'est une ecriture dans la chaine, et elle se decide.
#' Chaque coupe entre en NDP 1, source `sufosat`, nature `autre` - SUFOSAT ne
#' dit pas si c'est une coupe de regeneration, une coupe sanitaire ou un
#' chablis ; le terrain le dira.
#'
#' **Pas de doublon.** Une coupe deja inscrite - meme unite, meme annee, meme
#' source - ne l'est pas une seconde fois, qu'elle soit encore en attente ou
#' deja suivie.
#'
#' @param con Connexion DBI.
#' @param foret_id UUID de la foret.
#' @param coupes Coupes detectees, telles que les rend
#'   [sommier_coupes_sufosat()].
#' @param auteur Compte qui inscrit.
#'
#' @return Invisiblement, les entrees chainees (une liste vide si rien n'est a
#'   inscrire).
#'
#' @seealso [sommier_coupes_sufosat()], [sommier_projet_qfield_detections()]
#'
#' @export
sommier_inscrire_coupes_sufosat <- function(con, foret_id, coupes, auteur) {
  foret_id <- valider_uuid(foret_id, "foret_id")
  auteur <- valider_texte(auteur, "auteur")
  a_inscrire <- coupes_sans_martelage(con, foret_id, coupes)
  if (is.null(a_inscrire) || nrow(a_inscrire) == 0L) {
    return(invisible(list()))
  }
  deja <- DBI::dbGetQuery(
    con,
    "SELECT u.numero_affichage AS ug,
            EXTRACT(YEAR FROM e.date_evenement)::int AS annee
       FROM entree_sommier e JOIN ug u ON u.uuid = e.ug_uuid
      WHERE e.foret_id = $1 AND e.registre = 8
        AND e.payload ->> 'type_entree' = 'detection'
        AND e.payload ->> 'source' = 'sufosat'",
    params = list(foret_id)
  )
  cle <- paste(a_inscrire$ug, a_inscrire$annee)
  a_inscrire <- a_inscrire[!cle %in% paste(deja$ug, deja$annee), , drop = FALSE]
  if (nrow(a_inscrire) == 0L) {
    return(invisible(list()))
  }
  unites <- DBI::dbGetQuery(
    con, "SELECT uuid::text AS uuid, numero_affichage FROM ug WHERE foret_id = $1",
    params = list(foret_id)
  )
  detections <- data.frame(
    nature = "autre",
    description = paste("Coupe rase detectee par SUFOSAT - nature a etablir",
                        "sur le terrain (regeneration, coupe sanitaire ou",
                        "chablis)"),
    date_evenement = format(a_inscrire$date_mediane),
    ug_uuid = unites$uuid[match(a_inscrire$ug, unites$numero_affichage)],
    surface_ha = round(a_inscrire$surface_ha, 2L),
    indice = round(a_inscrire$proba_moyenne, 1L),
    date_detection = format(a_inscrire$date_mediane),
    observations = sprintf(paste(
      "SUFOSAT (Sentinel-2, 10 m) : %.2f ha de pixels a probabilite >= %g %%",
      "(moyenne %.1f %%), detectes du %s au %s. Aucun martelage de l'unite",
      "ne l'explique, l'exercice de la detection ou le precedent."),
      a_inscrire$surface_ha, attr(coupes, "seuil_proba") %||% 90,
      a_inscrire$proba_moyenne, format(a_inscrire$debut, "%d/%m/%Y"),
      format(a_inscrire$fin, "%d/%m/%Y")),
    stringsAsFactors = FALSE
  )
  sommier_importer_detections(con, foret_id, detections, source = "sufosat",
                              ndp = 1L, auteur = auteur)
}

#' Contours des detections en attente
#'
#' @description
#' Dessine, pour chaque detection en attente au registre 8, les pixels qui
#' l'ont produite : ceux que RECONFORT classe en deperissement, ceux que
#' SUFOSAT date de l'annee de la coupe. A defaut, le contour est celui de
#' l'unite de gestion.
#'
#' @details
#' **Un decor, pas une ecriture.** Les detections inscrites n'ont pas de
#' geometrie, et on ne la leur ajoute pas : une entree chainee ne se complete
#' pas apres coup. Le contour se recalcule depuis les rasters fournis ; il
#' aide l'agent a trouver ou regarder dans une unite de trente hectares, il ne
#' prouve rien.
#'
#' - **RECONFORT** : le raster des classes (1 sain, 2 deperissant, 3 tres
#'   deperissant) ; sont retenus les pixels de l'unite de classe au moins
#'   `classe_min`.
#' - **SUFOSAT** : les rasters des dates (`AAJJJ`) et des probabilites ; sont
#'   retenus les pixels de l'unite dates de l'annee de la detection, a
#'   probabilite au moins `seuil_proba`.
#'
#' @param con Connexion DBI.
#' @param foret_id UUID de la foret.
#' @param reconfort Raster des classes RECONFORT (facultatif).
#' @param sufosat Liste `dates`, `proba` : rasters SUFOSAT (facultatif).
#' @param classe_min Classe RECONFORT minimale retenue.
#' @param seuil_proba Probabilite SUFOSAT minimale, en %.
#'
#' @return Un `data.frame` : `detection_id`, `ug`, `source`, `nature`,
#'   `surface_ha`, `date_evenement`, `description`, `contour_source`
#'   (`"pixels"` ou `"unite"`), `contour_ha`, `wkt` (Lambert-93).
#'
#' @export
sommier_contours_detections <- function(con, foret_id, reconfort = NULL,
                                        sufosat = NULL, classe_min = 2L,
                                        seuil_proba = 90) {
  if (!requireNamespace("sf", quietly = TRUE)) {
    stop("Le paquet `sf` est requis pour dessiner les contours.", call. = FALSE)
  }
  foret_id <- valider_uuid(foret_id, "foret_id")
  detections <- DBI::dbGetQuery(
    con,
    "SELECT d.id::text AS detection_id, u.numero_affichage AS ug, d.source,
            d.nature, d.surface_ha, d.date_evenement, d.description
       FROM v_detection_en_attente d
       LEFT JOIN ug u ON u.uuid = d.ug_uuid
      WHERE d.foret_id = $1
      ORDER BY d.surface_ha DESC NULLS LAST, d.seq",
    params = list(foret_id)
  )
  if (nrow(detections) == 0L) {
    detections$contour_source <- character(0)
    detections$contour_ha <- numeric(0)
    detections$wkt <- character(0)
    return(detections)
  }
  unites <- sommier_couche_ug(con, foret_id)
  fenetre <- fenetre_emprise(unites)
  pixels_reconfort <- if (!is.null(reconfort)) {
    p <- lire_xyz(reconfort, fenetre)
    p[!is.na(p$v) & p$v >= classe_min & p$v <= 3, c("x", "y")]
  }
  pixels_sufosat <- if (!is.null(sufosat)) {
    p <- merge(lire_xyz(sufosat$dates, fenetre),
               lire_xyz(sufosat$proba, fenetre),
               by = c("x", "y"), suffixes = c("_date", "_proba"))
    p <- p[!is.na(p$v_date) & p$v_date > 0 & p$v_date < 1e6 &
             p$v_proba >= seuil_proba & p$v_proba <= 100, ]
    p$annee <- 2000L + as.integer(p$v_date %/% 1000)
    p
  }
  cote <- function(raster) resolution_raster(raster)

  contours <- lapply(seq_len(nrow(detections)), function(i) {
    d <- detections[i, ]
    unite <- unites$wkt[match(d$ug, unites$numero_affichage)]
    forme_unite <- if (!is.na(unite)) sf::st_as_sfc(unite, crs = 2154)
    pixels <- NULL
    taille <- NA_real_
    if (identical(d$source, "reconfort") && !is.null(pixels_reconfort)) {
      pixels <- pixels_reconfort
      taille <- cote(reconfort)
    } else if (identical(d$source, "sufosat") && !is.null(pixels_sufosat)) {
      annee <- as.integer(format(as.Date(d$date_evenement), "%Y"))
      pixels <- pixels_sufosat[pixels_sufosat$annee == annee, c("x", "y")]
      taille <- cote(sufosat$dates)
    }
    forme <- NULL
    if (!is.null(pixels) && nrow(pixels) > 0L && !is.null(forme_unite)) {
      points <- sf::st_as_sf(pixels, coords = c("x", "y"), crs = 2154)
      dedans <- lengths(sf::st_intersects(points, forme_unite)) > 0L
      if (any(dedans)) {
        carres <- sf::st_buffer(sf::st_geometry(points[dedans, ]), taille / 2,
                                endCapStyle = "SQUARE")
        forme <- sf::st_union(carres)
      }
    }
    source <- if (is.null(forme)) "unite" else "pixels"
    if (is.null(forme)) forme <- forme_unite
    if (is.null(forme)) {
      return(c(source = "aucun", ha = NA, wkt = NA))
    }
    forme <- sf::st_cast(sf::st_make_valid(forme), "MULTIPOLYGON")
    c(source = source, ha = as.numeric(sf::st_area(forme)) / 10000,
      wkt = wkt_plein(forme))
  })
  detections$contour_source <- vapply(contours, `[[`, "", "source")
  detections$contour_ha <- round(as.numeric(vapply(contours, `[[`, "", "ha")),
                                 2L)
  detections$wkt <- vapply(contours, `[[`, "", "wkt")
  detections$date_evenement <- as.Date(detections$date_evenement)
  detections$surface_ha <- as.numeric(detections$surface_ha)
  detections
}

#' Projet QGIS/QField pour verifier les detections sur le terrain
#'
#' @description
#' Ecrit un dossier autonome - un projet QGIS, un GeoPackage et un dossier
#' `DCIM/` vide - que l'on copie sur le telephone ou la tablette et que l'on
#' ouvre avec QField. On y trouve les detections en attente au registre 8,
#' chacune dessinee par les pixels qui l'ont produite, et une couche ou saisir
#' un constat par detection visitee, avec ses photos.
#'
#' @details
#' **Un projet a part de celui des limites**, sur le meme principe : le modele
#' a ete produit une fois par QGIS (`data-raw/qfield_modele.py`), cette
#' fonction le copie et en remplit les couches.
#'
#' **Les detections sont numerotees** D01, D02... par surface decroissante,
#' et portent un libelle - unite, source, surface, date - que le formulaire
#' montre. Leur contour est un decor, recalcule par
#' [sommier_contours_detections()] depuis les rasters fournis ; sans raster,
#' c'est l'unite entiere.
#'
#' **Le formulaire.** Un nouveau constat propose la detection sous les pieds
#' de l'agent, ou la plus proche a 100 m, et remplit la date, l'operateur, la
#' precision et la source GNSS. L'etat - confirme, ecarte, non vu - doit etre
#' choisi. Une detection confirmee demande sa nature : crise sanitaire,
#' chablis, secheresse, coupe programmee... C'est ce que la teledetection ne
#' sait pas dire. La surface et le volume constates sont facultatifs.
#'
#' @param con Connexion DBI.
#' @param foret_id UUID de la foret.
#' @param dossier Dossier a creer. Il ne doit pas exister : une tournee non
#'   rapatriee ne doit jamais etre ecrasee.
#' @param operateur Nom de l'operateur, propose par defaut dans chaque constat.
#' @param reconfort,sufosat Rasters des detections, pour en dessiner les
#'   contours : voir [sommier_contours_detections()] (facultatifs).
#' @param fond Parcellaire cadastral pour se reperer, tel que le rend
#'   [sommier_fond_lire()] (facultatif).
#' @param ortho GeoTIFF d'orthophotographie a joindre au projet, tel que
#'   l'ecrit [sommier_ortho_ign()] (facultatif).
#'
#' @return Invisiblement, le chemin du projet `.qgs`.
#'
#' @seealso [sommier_importer_qfield_detections()],
#'   [sommier_inscrire_coupes_sufosat()], [sommier_projet_qfield()] pour les
#'   limites.
#'
#' @export
sommier_projet_qfield_detections <- function(con, foret_id, dossier, operateur,
                                             reconfort = NULL, sufosat = NULL,
                                             fond = NULL, ortho = NULL) {
  for (paquet in c("sf", "xml2")) {
    if (!requireNamespace(paquet, quietly = TRUE)) {
      stop("Le paquet `", paquet, "` est requis pour ecrire le projet ",
           "QField.", call. = FALSE)
    }
  }
  ortho <- controler_ortho(ortho)
  foret_id <- valider_uuid(foret_id, "foret_id")
  dossier <- valider_texte(dossier, "dossier")
  operateur <- valider_texte(operateur, "operateur")
  terrain <- preparer_terrain(con, foret_id, dossier)
  detections <- sommier_contours_detections(con, foret_id,
                                            reconfort = reconfort,
                                            sufosat = sufosat)
  sans_lieu <- is.na(detections$wkt)
  if (any(sans_lieu)) {
    warning(sum(sans_lieu), " detection(s) sans unite dessinee ni pixels : ",
            "elles ne sont pas dans le projet.", call. = FALSE)
    detections <- detections[!sans_lieu, , drop = FALSE]
  }
  if (nrow(detections) == 0L) {
    stop("Aucune detection en attente a montrer : rien a verifier sur le ",
         "terrain.", call. = FALSE)
  }

  copier_modele(dossier, c("detections.qgs", "detections_attachments.zip",
                           "detections.gpkg"))
  gpkg <- file.path(dossier, "detections.gpkg")
  detections$numero <- sprintf("D%02d", seq_len(nrow(detections)))
  detections$libelle <- libelle_detection(detections)
  colonnes <- renommer_colonnes(
    detections[, c("detection_id", "numero", "libelle", "ug", "source",
                   "nature", "surface_ha", "date_evenement", "description",
                   "contour_source")],
    c(detection_id = "id", date_evenement = "date_detection",
      contour_source = "contour")
  )
  ecrire_couche(sf::st_sf(colonnes,
                          geometry = sf::st_as_sfc(detections$wkt, crs = 2154)),
                gpkg, "detections")

  ug <- terrain$ug
  contours <- sf::st_as_sfc(ug$wkt, crs = 2154)
  union <- sf::st_union(contours)
  ecrire_couche(sf::st_sf(nom = terrain$foret$nom[[1L]],
                          geometry = sf::st_cast(union, "MULTIPOLYGON")),
                gpkg, "foret")
  ecrire_couche(sf::st_sf(numero = ug$numero_affichage,
                          geometry = sf::st_cast(contours, "MULTIPOLYGON")),
                gpkg, "ug")
  ecrire_parcelles(fond, gpkg)

  qgs <- file.path(dossier, "detections.qgs")
  joindre_ortho(qgs, dossier, ortho, "detections_ortho")
  poser_cadre_projet(qgs, paste0("Detections - ", terrain$foret$nom[[1L]]),
                     operateur, foret_id, sf::st_buffer(union, 100))
  invisible(qgs)
}

#' Import des constats d'une tournee de verification des detections
#'
#' @description
#' Relit le projet rapporte du terrain et inscrit au registre 8 la suite de
#' chaque detection visitee : confirmee ou ecartee, avec la position, la
#' nature retenue et les photos deposees sous leur empreinte.
#'
#' @details
#' **Tout ou rien.** Chaque constat est controle avant toute ecriture : etat
#' connu, detection presente dans le projet et appartenant a la foret, nature
#' connue - et exigee pour une detection confirmee -, date de visite, photos
#' presentes, une seule suite par detection. Une faute fait echouer l'import,
#' qui les liste toutes. Les suites s'ecrivent en une transaction.
#'
#' **Rejouable.** L'UUID que QField a donne au constat devient celui de
#' l'entree : reimporter le meme dossier n'ecrit rien de plus.
#'
#' **« Non vu » n'ecrit rien** : la detection reste en attente. Une detection
#' deja suivie - par une autre tournee, ou a la main - ne l'est pas une
#' seconde fois ; le bilan la signale.
#'
#' L'entree porte NDP 0 : c'est un constat de terrain. Elle rectifie la
#' detection, qui sort des vues de consultation sans sortir de la chaine (voir
#' [sommier_valider_detection()]).
#'
#' @param con Connexion DBI.
#' @param foret_id UUID de la foret.
#' @param dossier Dossier du projet, rapporte du terrain.
#' @param depot Repertoire du depot de photos.
#' @param auteur Compte qui importe. L'agent qui a constate est l'operateur
#'   de chaque constat.
#'
#' @return Invisiblement, un bilan : `ecrits`, `deja_presents`, `non_vus`,
#'   `deja_suivies` (les numeros des detections deja suivies), `photos` et
#'   `entrees` (les entrees chainees).
#'
#' @seealso [sommier_projet_qfield_detections()], [sommier_verifier_photos()]
#'
#' @export
sommier_importer_qfield_detections <- function(con, foret_id, dossier, depot,
                                               auteur) {
  if (!requireNamespace("sf", quietly = TRUE)) {
    stop("Le paquet `sf` est requis pour lire le projet QField.",
         call. = FALSE)
  }
  foret_id <- valider_uuid(foret_id, "foret_id")
  dossier <- valider_texte(dossier, "dossier")
  depot <- valider_texte(depot, "depot")
  auteur <- valider_texte(auteur, "auteur")
  gpkg <- file.path(dossier, "detections.gpkg")
  if (!file.exists(gpkg)) {
    stop("Pas de detections.gpkg dans ", dossier, " : ce n'est pas un projet ",
         "engendre par sommier_projet_qfield_detections().", call. = FALSE)
  }
  bilan <- list(ecrits = 0L, deja_presents = 0L, non_vus = 0L,
                deja_suivies = character(0), photos = 0L, entrees = list())
  constats <- suppressWarnings(sf::read_sf(gpkg, layer = "constats"))
  if (nrow(constats) == 0L) {
    return(invisible(bilan))
  }
  photos <- as.data.frame(suppressWarnings(sf::read_sf(gpkg, layer = "photos")))
  projet <- as.data.frame(sf::st_drop_geometry(
    suppressWarnings(sf::read_sf(gpkg, layer = "detections"))
  ))
  de_la_foret <- DBI::dbGetQuery(
    con,
    "SELECT id::text AS id FROM entree_sommier
      WHERE foret_id = $1 AND registre = 8 AND id = ANY($2::uuid[])",
    params = list(foret_id, paste0("{", paste(projet$id, collapse = ","), "}"))
  )$id

  fautes <- controler_constats_detections(constats, photos, projet,
                                          de_la_foret, dossier)
  if (length(fautes) > 0L) {
    stop("Import refuse, rien n'est ecrit :\n",
         paste0("- ", fautes, collapse = "\n"), call. = FALSE)
  }

  constats$uuid <- tolower(constats$uuid)
  bilan$non_vus <- sum(constats$etat == "non_vu")
  constats <- constats[constats$etat != "non_vu", ]
  presents <- DBI::dbGetQuery(
    con, "SELECT id::text AS id FROM entree_sommier WHERE id = ANY($1::uuid[])",
    params = list(paste0("{", paste(constats$uuid, collapse = ","), "}"))
  )$id
  bilan$deja_presents <- length(presents)
  constats <- constats[!constats$uuid %in% presents, ]
  suivies <- DBI::dbGetQuery(
    con,
    "SELECT corrige_id::text AS id FROM entree_sommier
      WHERE corrige_id = ANY($1::uuid[])",
    params = list(paste0("{", paste(constats$detection_id, collapse = ","),
                         "}"))
  )$id
  if (length(suivies) > 0L) {
    bilan$deja_suivies <- projet$numero[projet$id %in% suivies]
    constats <- constats[!constats$detection_id %in% suivies, ]
  }
  if (nrow(constats) == 0L) {
    return(invisible(bilan))
  }

  positions <- positions_wgs84(constats)
  entrees <- lapply(seq_len(nrow(constats)), function(i) {
    c <- constats[i, ]
    d <- projet[projet$id == c$detection_id, , drop = FALSE]
    deposees <- deposer_photos_constat(c$uuid, photos, dossier, depot)
    bilan$photos <<- bilan$photos + length(deposees)
    visite <- as.POSIXct(c$visite_le)
    entree_suite_detection(
      con, c$detection_id, auteur = auteur, statut = c$etat,
      description = paste0(
        "Detection ", d$numero, " (", d$source, ", unite ", d$ug, ") ",
        if (c$etat == "confirme") paste0("confirmee sur le terrain : ",
                                         c$nature) else
          "ecartee sur le terrain"),
      date_evenement = as.Date(format(visite, "%Y-%m-%d")),
      nature = if (c$etat == "confirme") c$nature,
      surface_ha = nombre_ou_null(c$surface_ha),
      volume_impacte_m3 = nombre_ou_null(c$volume_m3),
      observations = texte_ou_null(c$observations),
      id = c$uuid,
      geometrie = positions[[i]],
      precision_m = nombre_ou_null(c$precision_m),
      source_gnss = texte_ou_null(c$source_gnss),
      operateur = texte_ou_null(c$operateur),
      visite_le = visite,
      releve_uuid = c$uuid,
      photos = if (length(deposees) > 0L) deposees
    )
  })
  bilan$entrees <- sommier_ajouter(con, entrees)
  bilan$ecrits <- length(bilan$entrees)
  invisible(bilan)
}

# ---------------------------------------------------------------------------

SOMMIER_ETATS_DETECTION <- c("confirme", "ecarte", "non_vu")

libelle_detection <- function(d) {
  sources <- c(reconfort = "RECONFORT", sufosat = "SUFOSAT")
  source <- ifelse(d$source %in% names(sources), sources[d$source], d$source)
  paste0(d$numero, " - unite ", d$ug, " - ", source, ", ",
         formatC(d$surface_ha, format = "f", digits = 1L, decimal.mark = ","),
         " ha (", format(as.Date(d$date_evenement), "%d/%m/%Y"), ")")
}

renommer_colonnes <- function(x, noms) {
  names(x)[match(names(noms), names(x))] <- unname(noms)
  x
}

controler_constats_detections <- function(constats, photos, projet,
                                          de_la_foret, dossier) {
  fautes <- character(0)
  for (i in seq_len(nrow(constats))) {
    c <- constats[i, ]
    nom <- paste0("constat ", i, if (!is.na(c$uuid)) paste0(" (", c$uuid, ")"))
    if (is.na(c$uuid) || !grepl(MOTIF_UUID, tolower(c$uuid))) {
      fautes <- c(fautes, paste0(nom, " : identifiant absent ou invalide"))
    }
    if (is.na(c$etat) || !c$etat %in% SOMMIER_ETATS_DETECTION) {
      fautes <- c(fautes, paste0(nom, " : etat inconnu (",
                                 if (is.na(c$etat)) "vide" else c$etat, ")"))
    }
    if (is.na(c$detection_id)) {
      fautes <- c(fautes, paste0(nom, " : aucune detection choisie"))
    } else if (!c$detection_id %in% projet$id) {
      fautes <- c(fautes, paste0(nom, " : detection inconnue du projet (",
                                 c$detection_id, ")"))
    } else if (!c$detection_id %in% de_la_foret) {
      fautes <- c(fautes, paste0(nom, " : la detection n'est pas au registre ",
                                 "8 de cette foret (", c$detection_id, ")"))
    }
    if (identical(c$etat, "confirme") && is.na(c$nature)) {
      fautes <- c(fautes, paste0(nom, " : une detection confirmee appelle ",
                                 "sa nature"))
    }
    if (!is.na(c$nature) && !c$nature %in% SOMMIER_NATURES_PHENOMENE) {
      fautes <- c(fautes, paste0(nom, " : nature inconnue (", c$nature, ")"))
    }
    for (champ in c("surface_ha", "volume_m3")) {
      if (!is.na(c[[champ]]) && c[[champ]] < 0) {
        fautes <- c(fautes, paste0(nom, " : ", champ, " negatif"))
      }
    }
    if (is.na(c$visite_le)) {
      fautes <- c(fautes, paste0(nom, " : date de visite absente"))
    }
    fautes <- c(fautes, controler_photos_constat(c, nom, photos, dossier))
  }
  vus <- constats[!is.na(constats$etat) & constats$etat != "non_vu" &
                    !is.na(constats$detection_id), ]
  doubles <- unique(vus$detection_id[duplicated(vus$detection_id)])
  for (d in doubles) {
    fautes <- c(fautes, paste0(
      "detection ", projet$numero[match(d, projet$id)], " : plusieurs ",
      "constats la confirment ou l'ecartent ; un seul doit rester"))
  }
  fautes
}
