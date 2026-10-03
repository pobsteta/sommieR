#' Projet QField pour les travaux et le suivi des plantations
#'
#' @description
#' Ecrit un dossier autonome - un projet QGIS, un GeoPackage et un dossier
#' `DCIM/` vide - que l'on copie sur le telephone ou la tablette et que l'on
#' ouvre avec QField. On y releve les travaux faits, chacun dessine en surface,
#' en ligne ou en point selon son code, on y installe des placettes de suivi et
#' on y saisit leurs controles.
#'
#' @details
#' **Un troisieme projet**, a cote de ceux des limites et des detections, sur
#' le meme principe : le modele a ete produit une fois par QGIS
#' (`data-raw/qfield_modele.py`), cette fonction le copie et en remplit les
#' couches.
#'
#' **Les codes viennent de [SOMMIER_CODES_TRAVAUX]**, ecrits a chaque projet :
#' la couche des surfaces ne propose que les codes qui admettent une surface,
#' et l'unite par defaut est la premiere du code.
#'
#' **Les placettes deja installees sont dans le projet**, colorees selon leur
#' dernier controle : besoin signale, sans besoin, jamais controlee. On les
#' controle en ajoutant un controle a la placette ; on en installe une
#' nouvelle en placant un point, rattache a des travaux de la liste des
#' travaux suivis (ceux d'une unite de gestion).
#'
#' @param con Connexion DBI.
#' @param foret_id UUID de la foret.
#' @param dossier Dossier a creer. Il ne doit pas exister : une tournee non
#'   rapatriee ne doit jamais etre ecrasee.
#' @param operateur Nom de l'operateur, propose par defaut a chaque saisie.
#' @param fond Parcellaire cadastral pour se reperer, tel que le rend
#'   [sommier_fond_lire()] (facultatif).
#' @param ortho GeoTIFF d'orthophotographie a joindre au projet, tel que
#'   l'ecrit [sommier_ortho_ign()] (facultatif).
#'
#' @return Invisiblement, le chemin du projet `.qgs`.
#'
#' @seealso [sommier_importer_qfield_travaux()]
#'
#' @export
sommier_projet_qfield_travaux <- function(con, foret_id, dossier, operateur,
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

  copier_modele(dossier, c("travaux.qgs", "travaux_attachments.zip",
                           "travaux.gpkg"))
  gpkg <- file.path(dossier, "travaux.gpkg")

  codes <- SOMMIER_CODES_TRAVAUX[, c("code", "libelle", "unites", "formes")]
  codes$libelle <- paste0(codes$code, " - ", codes$libelle)
  # "aucun" : le besoin d'un controle qui ne demande rien. Sans forme,
  # aucune couche de travaux ne le propose.
  codes <- rbind(codes, data.frame(code = "aucun", libelle = "Aucun",
                                   unites = "", formes = ""))
  ecrire_table(codes, gpkg, "codes")

  suivis <- DBI::dbGetQuery(
    con,
    "SELECT t.id::text AS id, u.numero_affichage AS ug, t.annee,
            coalesce(t.code_travaux || ' ', '') || t.nature_travaux AS nature
       FROM v_travaux t JOIN ug u ON u.uuid = t.ug_uuid
      WHERE t.foret_id = $1
      ORDER BY u.numero_affichage, t.annee",
    params = list(foret_id)
  )
  ecrire_table(data.frame(
    id = suivis$id,
    libelle = paste0("UG ", suivis$ug, " - ", suivis$annee, " - ",
                     suivis$nature),
    ug = suivis$ug, stringsAsFactors = FALSE
  ), gpkg, "suivis")

  placettes <- placettes_du_projet(con, foret_id)
  if (nrow(placettes) > 0L) {
    ecrire_couche(sf::st_sf(
      placettes[, c("uuid", "code_placette", "travaux_id", "rayon_m",
                    "materialisation", "ug", "etat_suivi",
                    "dernier_controle", "dernier_besoin")],
      geometry = sf::st_as_sfc(placettes$wkt, crs = 2154)
    ), gpkg, "placettes")
  }

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

  qgs <- file.path(dossier, "travaux.qgs")
  joindre_ortho(qgs, dossier, ortho, "travaux_ortho")
  poser_cadre_projet(qgs, paste0("Travaux - ", terrain$foret$nom[[1L]]),
                     operateur, foret_id, sf::st_buffer(union, 100))
  invisible(qgs)
}

#' Import d'une tournee de travaux et de suivi des plantations
#'
#' @description
#' Relit le projet rapporte du terrain et inscrit au registre 6 les travaux
#' releves, les placettes installees et les controles saisis, avec leurs
#' photos deposees sous leur empreinte.
#'
#' @details
#' **Tout ou rien.** Chaque saisie est controlee avant toute ecriture : code
#' connu et forme de la couche admise par le code, unite du code, motif d'un
#' ecart au prevu, placette rattachee a des travaux connus, controle sur une
#' placette connue, vivants et abroutis coherents, photos presentes. Une faute
#' fait echouer l'import, qui les liste toutes. Un controle ajoute depuis sa
#' couche, sans placette choisie, se rattache a la placette la plus proche de
#' sa position, a 15 m pres. L'ecriture se fait en une
#' transaction, dans cet ordre : travaux, placettes, controles - une placette
#' peut suivre des travaux releves dans la meme tournee, un controle porter sur
#' une placette qui vient d'etre installee.
#'
#' **Rejouable.** L'UUID que QField a donne a chaque saisie devient celui de
#' l'entree : reimporter le meme dossier n'ecrit rien de plus. Les placettes
#' deja inscrites, versees dans le projet, ne se reinscrivent pas.
#'
#' **L'unite de gestion** d'une intervention est celle qui contient sa
#' geometrie (le point interieur d'une surface, le milieu d'une ligne) ; hors
#' de toute unite, l'intervention est inscrite a l'echelle de la foret.
#'
#' Toutes les entrees portent NDP 0 : ce sont des constats de terrain.
#'
#' @param con Connexion DBI.
#' @param foret_id UUID de la foret.
#' @param dossier Dossier du projet, rapporte du terrain.
#' @param depot Repertoire du depot de photos.
#' @param auteur Compte qui importe. L'agent qui a releve est l'operateur.
#'
#' @return Invisiblement, un bilan : `travaux`, `placettes`, `controles`
#'   (nombres d'entrees ecrites), `deja_presents`, `photos` et `entrees`.
#'
#' @seealso [sommier_projet_qfield_travaux()], [sommier_verifier_photos()]
#'
#' @export
sommier_importer_qfield_travaux <- function(con, foret_id, dossier, depot,
                                            auteur) {
  if (!requireNamespace("sf", quietly = TRUE)) {
    stop("Le paquet `sf` est requis pour lire le projet QField.",
         call. = FALSE)
  }
  foret_id <- valider_uuid(foret_id, "foret_id")
  dossier <- valider_texte(dossier, "dossier")
  depot <- valider_texte(depot, "depot")
  auteur <- valider_texte(auteur, "auteur")
  gpkg <- file.path(dossier, "travaux.gpkg")
  if (!file.exists(gpkg)) {
    stop("Pas de travaux.gpkg dans ", dossier, " : ce n'est pas un projet ",
         "engendre par sommier_projet_qfield_travaux().", call. = FALSE)
  }
  lire <- function(nom) suppressWarnings(sf::read_sf(gpkg, layer = nom))
  travaux <- do.call(rbind, lapply(names(COUCHES_TRAVAUX), function(nom) {
    t <- lire(nom)
    if (nrow(t) == 0L) return(NULL)
    t$couche <- nom
    sf::st_geometry(t) <- "geometry"
    t
  }))
  placettes <- lire("placettes")
  controles <- rattacher_controles(lire("controles"), placettes)
  photos <- as.data.frame(lire("photos"))
  bilan <- list(travaux = 0L, placettes = 0L, controles = 0L,
                deja_presents = 0L, photos = 0L, entrees = list())

  ids <- tolower(c(if (!is.null(travaux)) travaux$uuid, placettes$uuid,
                   controles$uuid))
  presents <- if (length(ids) == 0L) character(0) else DBI::dbGetQuery(
    con, "SELECT id::text AS id FROM entree_sommier WHERE id = ANY($1::uuid[])",
    params = list(paste0("{", paste(ids[!is.na(ids)], collapse = ","), "}"))
  )$id
  garder <- function(x) {
    if (is.null(x) || nrow(x) == 0L) return(x)
    x$uuid <- tolower(x$uuid)
    x[!x$uuid %in% presents, , drop = FALSE]
  }
  bilan$deja_presents <- sum(ids %in% presents)
  travaux <- garder(travaux)
  placettes <- garder(placettes)
  controles <- garder(controles)
  if ((is.null(travaux) || nrow(travaux) == 0L) && nrow(placettes) == 0L &&
      nrow(controles) == 0L) {
    return(invisible(bilan))
  }

  connus <- DBI::dbGetQuery(
    con, "SELECT id::text AS id, ug_uuid::text AS ug_uuid FROM v_travaux
           WHERE foret_id = $1", params = list(foret_id))
  placettes_connues <- DBI::dbGetQuery(
    con, "SELECT id::text AS id FROM v_placette WHERE foret_id = $1",
    params = list(foret_id))$id
  fautes <- controler_tournee_travaux(
    travaux, placettes, controles, photos, dossier,
    travaux_connus = connus$id, placettes_connues = placettes_connues)
  if (length(fautes) > 0L) {
    stop("Import refuse, rien n'est ecrit :\n",
         paste0("- ", fautes, collapse = "\n"), call. = FALSE)
  }

  ug <- DBI::dbGetQuery(
    con, "SELECT u.uuid::text AS uuid, ST_AsText(g.geom) AS wkt
            FROM ug u JOIN ug_geometrie g ON g.ug_uuid = u.uuid
           WHERE u.foret_id = $1 AND g.date_fin IS NULL",
    params = list(foret_id))
  photo <- function(uuid) {
    deposees <- deposer_photos_constat(uuid, photos, dossier, depot)
    bilan$photos <<- bilan$photos + length(deposees)
    if (length(deposees) > 0L) deposees
  }

  transaction(con, {
    if (!is.null(travaux) && nrow(travaux) > 0L) {
      unites <- ug_des_geometries(travaux, ug)
      geometries <- geometries_wgs84(travaux)
      entrees <- lapply(seq_len(nrow(travaux)), function(i) {
        t <- as.data.frame(travaux)[i, ]
        visite <- as.POSIXct(t$visite_le)
        sommier_entree(
          foret_id = foret_id, registre = 6L,
          date_evenement = if (!is.na(t$date_reception))
            as.Date(t$date_reception) else as.Date(format(visite, "%Y-%m-%d")),
          auteur = auteur, ug_uuid = unites[[i]], ndp = 0L, id = t$uuid,
          payload = payload_travaux(t, geometries[[i]], photo(t$uuid))
        )
      })
      ecrites <- sommier_ajouter(con, entrees)
      bilan$travaux <- length(ecrites)
      bilan$entrees <- c(bilan$entrees, ecrites)
    }
    if (nrow(placettes) > 0L) {
      centres <- positions_wgs84(placettes)
      ecrites <- lapply(seq_len(nrow(placettes)), function(i) {
        p <- as.data.frame(placettes)[i, ]
        sommier_installer_placette(
          con, p$travaux_id, p$code_placette, centres[[i]], auteur,
          date_evenement = Sys.Date(), id = p$uuid,
          rayon_m = if (is.na(p$rayon_m)) 3.99 else p$rayon_m,
          materialisation = texte_ou_null(p$materialisation)
        )[[1L]]
      })
      bilan$placettes <- length(ecrites)
      bilan$entrees <- c(bilan$entrees, ecrites)
    }
    if (nrow(controles) > 0L) {
      ecrites <- lapply(seq_len(nrow(controles)), function(i) {
        k <- controles[i, ]
        sommier_controler_placette(
          con, tolower(k$placette_uuid), k$nb_total, k$nb_vivants, auteur,
          visite_le = as.POSIXct(k$visite_le), id = k$uuid,
          h_moy_cm = nombre_ou_null(k$h_moy_cm),
          nb_abroutis = nombre_ou_null(k$nb_abroutis),
          concurrence = texte_ou_null(k$concurrence),
          besoin = texte_ou_null(k$besoin),
          operateur = texte_ou_null(k$operateur),
          releve_uuid = k$uuid,
          photos = photo(k$uuid),
          observations = texte_ou_null(k$observations)
        )[[1L]]
      })
      bilan$controles <- length(ecrites)
      bilan$entrees <- c(bilan$entrees, ecrites)
    }
  })
  invisible(bilan)
}

# ---------------------------------------------------------------------------

# Un controle saisi depuis sa couche, et non depuis la fiche d'une placette,
# n'en porte pas l'identifiant : il se rattache a la placette du projet la
# plus proche de sa position, a RAYON_RATTACHEMENT_M pres. Au-dela, il reste
# sans placette, et l'import le refuse.
RAYON_RATTACHEMENT_M <- 15

rattacher_controles <- function(controles, placettes) {
  manquants <- is.na(controles$placette_uuid) &
    !sf::st_is_empty(sf::st_geometry(controles))
  if (any(manquants) && nrow(placettes) > 0L) {
    proches <- sf::st_nearest_feature(controles[manquants, ], placettes)
    distances <- as.numeric(sf::st_distance(
      controles[manquants, ], placettes[proches, ], by_element = TRUE))
    controles$placette_uuid[manquants] <- ifelse(
      distances <= RAYON_RATTACHEMENT_M, placettes$uuid[proches], NA_character_)
  }
  as.data.frame(sf::st_drop_geometry(controles))
}

# Les couches de saisie des travaux, et la forme qu'elles portent.
COUCHES_TRAVAUX <- c(travaux_surf = "surface", travaux_lin = "ligne",
                     travaux_pt = "point")

ecrire_table <- function(x, gpkg, nom) {
  sf::st_write(x, gpkg, layer = nom, delete_layer = TRUE, quiet = TRUE)
}

# Les placettes deja inscrites, avec l'etat de leur dernier controle.
placettes_du_projet <- function(con, foret_id) {
  p <- DBI::dbGetQuery(
    con,
    "SELECT p.id::text AS uuid, p.code_placette, p.travaux_id::text AS travaux_id,
            p.rayon_m::float8 AS rayon_m, p.materialisation,
            u.numero_affichage AS ug, ST_AsText(p.geom) AS wkt,
            d.visite_le AS dernier_controle, d.besoin AS dernier_besoin
       FROM v_placette p
       LEFT JOIN ug u ON u.uuid = p.ug_uuid
       LEFT JOIN (SELECT DISTINCT ON (placette_id) placette_id, visite_le, besoin
                    FROM v_controle_plantation
                   ORDER BY placette_id, visite_le DESC, seq DESC) d
              ON d.placette_id = p.id
      WHERE p.foret_id = $1 AND p.geom IS NOT NULL
      ORDER BY u.numero_affichage, p.code_placette",
    params = list(foret_id)
  )
  p$etat_suivi <- ifelse(is.na(p$dernier_controle), "jamais",
                         ifelse(is.na(p$dernier_besoin) |
                                  p$dernier_besoin == "aucun",
                                "a_jour", "a_programmer"))
  p
}

controler_tournee_travaux <- function(travaux, placettes, controles, photos,
                                      dossier, travaux_connus,
                                      placettes_connues) {
  fautes <- character(0)
  if (!is.null(travaux) && nrow(travaux) > 0L) {
    t <- as.data.frame(travaux)
    for (i in seq_len(nrow(t))) {
      x <- t[i, ]
      nom <- paste0("travaux ", i, " (", x$couche, ")")
      if (is.na(x$uuid) || !grepl(MOTIF_UUID, x$uuid)) {
        fautes <- c(fautes, paste0(nom, " : identifiant absent ou invalide"))
        next
      }
      if (is.na(x$code_travaux) ||
          !x$code_travaux %in% SOMMIER_CODES_TRAVAUX$code) {
        fautes <- c(fautes, paste0(nom, " : code inconnu (",
                                   x$code_travaux, ")"))
        next
      }
      formes <- alternatives(SOMMIER_CODES_TRAVAUX$formes[
        SOMMIER_CODES_TRAVAUX$code == x$code_travaux])
      if (!COUCHES_TRAVAUX[[x$couche]] %in% formes) {
        fautes <- c(fautes, paste0(nom, " : un ", x$code_travaux, " ne se ",
                                   "trace pas en ", COUCHES_TRAVAUX[[x$couche]]))
      }
      if (is.na(x$visite_le) && is.na(x$date_reception)) {
        fautes <- c(fautes, paste0(nom, " : ni date de releve ni de reception"))
      }
      essai <- tryCatch({
        payload_travaux(x, NULL, NULL); NULL
      }, error = function(e) conditionMessage(e))
      if (!is.null(essai)) fautes <- c(fautes, paste0(nom, " : ", essai))
      fautes <- c(fautes, controler_photos_constat(x, nom, photos, dossier))
    }
  }
  nouveaux_travaux <- if (!is.null(travaux)) tolower(travaux$uuid)
  p <- as.data.frame(placettes)
  for (i in seq_len(nrow(p))) {
    x <- p[i, ]
    nom <- paste0("placette ", if (is.na(x$code_placette)) i else
      x$code_placette)
    if (is.na(x$uuid) || !grepl(MOTIF_UUID, x$uuid)) {
      fautes <- c(fautes, paste0(nom, " : identifiant absent ou invalide"))
    }
    if (is.na(x$code_placette)) {
      fautes <- c(fautes, paste0(nom, " : sans code"))
    }
    if (is.na(x$travaux_id) || !tolower(x$travaux_id) %in%
        c(travaux_connus, nouveaux_travaux)) {
      fautes <- c(fautes, paste0(nom, " : travaux suivis inconnus"))
    }
  }
  doubles <- unique(p$code_placette[duplicated(p$code_placette)])
  for (d in doubles[!is.na(doubles)]) {
    fautes <- c(fautes, paste0("placette ", d, " : installee deux fois"))
  }
  connues <- c(placettes_connues, tolower(p$uuid))
  for (i in seq_len(nrow(controles))) {
    x <- controles[i, ]
    nom <- paste0("controle ", i)
    if (is.na(x$uuid) || !grepl(MOTIF_UUID, x$uuid)) {
      fautes <- c(fautes, paste0(nom, " : identifiant absent ou invalide"))
    }
    if (is.na(x$placette_uuid)) {
      fautes <- c(fautes, paste0(nom, " : aucune placette choisie, ni a moins ",
                                 "de ", RAYON_RATTACHEMENT_M, " m"))
    } else if (!tolower(x$placette_uuid) %in% connues) {
      fautes <- c(fautes, paste0(nom, " : placette inconnue"))
    }
    if (is.na(x$visite_le)) {
      fautes <- c(fautes, paste0(nom, " : date de controle absente"))
    }
    essai <- tryCatch({
      registre6_controle(
        uuid_v4(), x$nb_total, x$nb_vivants,
        h_moy_cm = nombre_ou_null(x$h_moy_cm),
        nb_abroutis = nombre_ou_null(x$nb_abroutis),
        concurrence = texte_ou_null(x$concurrence),
        besoin = texte_ou_null(x$besoin))
      NULL
    }, error = function(e) conditionMessage(e))
    if (!is.null(essai)) fautes <- c(fautes, paste0(nom, " : ", essai))
    fautes <- c(fautes, controler_photos_constat(x, nom, photos, dossier))
  }
  avec <- !is.na(controles$placette_uuid)
  jours <- paste(tolower(controles$placette_uuid[avec]),
                 substr(as.character(controles$visite_le[avec]), 1L, 10L))
  if (any(duplicated(jours))) {
    fautes <- c(fautes, "deux controles d'une meme placette le meme jour")
  }
  fautes
}

payload_travaux <- function(t, geometrie, photos) {
  visite <- if (!is.na(t$visite_le)) as.POSIXct(t$visite_le)
  annee <- if (!is.na(t$annee)) t$annee else
    as.integer(format(visite %||% Sys.Date(), "%Y"))
  registre6_travaux(
    annee = annee,
    nature_travaux = texte_ou_null(t$nature_travaux) %||% t$code_travaux,
    quantite = nombre_ou_null(t$quantite),
    unite = texte_ou_null(t$unite),
    nb_plants = nombre_ou_null(t$nb_plants),
    montant_eur = nombre_ou_null(t$montant_eur),
    observations = texte_ou_null(t$observations),
    code_travaux = t$code_travaux,
    modalite = texte_ou_null(t$modalite),
    essence_objectif = texte_ou_null(t$essence_objectif),
    execution = texte_ou_null(t$execution),
    intervenant = texte_ou_null(t$intervenant),
    prevu = texte_ou_null(t$prevu),
    motif_ecart = texte_ou_null(t$motif_ecart),
    date_reception = if (!is.na(t$date_reception)) as.Date(t$date_reception),
    geometrie = geometrie,
    precision_m = nombre_ou_null(t$precision_m),
    source_gnss = texte_ou_null(t$source_gnss),
    photos = photos
  )
}

# L'unite qui contient le point interieur de chaque geometrie ; NULL hors de
# toute unite.
ug_des_geometries <- function(x, ug) {
  if (nrow(ug) == 0L) return(vector("list", nrow(x)))
  formes <- sf::st_as_sfc(ug$wkt, crs = 2154)
  points <- sf::st_point_on_surface(sf::st_geometry(x))
  dedans <- sf::st_intersects(points, formes)
  lapply(dedans, function(i) if (length(i) == 0L) NULL else ug$uuid[[i[[1L]]]])
}

# Une geometrie de saisie, en WGS84 comme toute geometrie de payload.
geometries_wgs84 <- function(x) {
  g <- sf::st_transform(sf::st_geometry(x), 4326)
  lapply(seq_along(g), function(i) {
    if (sf::st_is_empty(g[[i]])) return(NULL)
    m <- sf::st_coordinates(g[[i]])[, 1:2, drop = FALSE]
    switch(
      as.character(sf::st_geometry_type(g[[i]])),
      POINT = geom_point(m[1L, 1L], m[1L, 2L]),
      LINESTRING = geom_ligne(m),
      POLYGON = geom_polygone(m[-nrow(m), , drop = FALSE]),
      NULL
    )
  })
}
