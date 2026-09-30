#' Projet QGIS/QField pour verifier les limites sur le terrain
#'
#' @description
#' Ecrit un dossier autonome - un projet QGIS, un GeoPackage et un dossier
#' `DCIM/` vide - que l'on copie sur le telephone ou la tablette et que l'on
#' ouvre avec QField. On y trouve les elements du plan cadastral a verifier,
#' colores selon leur derniere visite, et une couche ou saisir un constat par
#' element visite, avec ses photos.
#'
#' @details
#' **Le projet est engendre sans QGIS.** Le modele - styles, formulaires,
#' relation entre constats et photos - a ete produit une fois par QGIS lui-meme
#' (`data-raw/qfield_modele.py`) et se trouve dans `inst/qgis/`. Cette fonction
#' le copie, remplit les couches de donnees et pose quelques valeurs : titre,
#' operateur, emprise d'ouverture.
#'
#' **Aucun service en ligne n'est requis.** Le dossier se copie par cable ou
#' par un partage de fichiers, et revient de la meme facon ; QFieldCloud reste
#' possible, le dossier etant un projet QGIS ordinaire. Seul le fond
#' d'orthophotographie de l'IGN demande du reseau pour s'afficher.
#'
#' **Le formulaire en fait le plus possible.** Un nouveau constat propose
#' l'element du plan le plus proche a moins de 30 m, et remplit la date,
#' l'operateur, la precision et la source GNSS. L'etat, lui, doit etre choisi :
#' c'est le constat.
#'
#' Les elements sont colores selon leur derniere reconnaissance au sommier :
#' a voir (jamais vu, ou reste inaccessible), vu il y a plus de
#' `anciennete_ans` ans, vu en place, vu endommage, non retrouve ou detruit.
#'
#' Le projet vise QField 4.x ; il le declare dans ses metadonnees.
#'
#' @param con Connexion DBI.
#' @param foret_id UUID de la foret.
#' @param elements Elements du plan, tels que les rend [sommier_elements_pci()].
#' @param dossier Dossier a creer. Il ne doit pas exister : une tournee non
#'   rapatriee ne doit jamais etre ecrasee.
#' @param operateur Nom de l'operateur, propose par defaut dans chaque constat.
#' @param fond Parcellaire cadastral pour se reperer, tel que le rend
#'   [sommier_fond_lire()] (facultatif).
#' @param anciennete_ans Au-dela de ce nombre d'annees, une visite est dite
#'   ancienne.
#'
#' @return Invisiblement, le chemin du projet `.qgs`.
#'
#' @seealso [sommier_importer_qfield()], [sommier_elements_pci()]
#'
#' @examples
#' # sommier_projet_qfield(con, foret, elements, "limites-loury",
#' #                       operateur = "P. Obstetar")
#'
#' @export
sommier_projet_qfield <- function(con, foret_id, elements, dossier, operateur,
                                  fond = NULL, anciennete_ans = 10) {
  if (!requireNamespace("sf", quietly = TRUE)) {
    stop("Le paquet `sf` est requis pour ecrire le projet QField.",
         call. = FALSE)
  }
  foret_id <- valider_uuid(foret_id, "foret_id")
  dossier <- valider_texte(dossier, "dossier")
  operateur <- valider_texte(operateur, "operateur")
  anciennete_ans <- valider_nombre(anciennete_ans, "anciennete_ans", min = 0)
  if (!is.data.frame(elements) || is.null(elements$categorie) ||
      nrow(elements) == 0L) {
    stop("`elements` doit venir de sommier_elements_pci() et n'etre pas vide.",
         call. = FALSE)
  }
  if (file.exists(dossier)) {
    stop("Le dossier existe deja : ", dossier, ". Un projet de terrain n'est ",
         "jamais ecrase - il porte peut-etre une tournee non rapatriee.",
         call. = FALSE)
  }
  foret <- DBI::dbGetQuery(con, "SELECT nom FROM foret WHERE id = $1",
                           params = list(foret_id))
  if (nrow(foret) == 0L) {
    stop("Foret inconnue : ", foret_id, ".", call. = FALSE)
  }
  ug <- sommier_couche_ug(con, foret_id)
  ug <- ug[!is.na(ug$wkt), , drop = FALSE]
  if (nrow(ug) == 0L) {
    stop("Aucune unite de gestion n'a de contour : le projet n'aurait pas de ",
         "foret a montrer.", call. = FALSE)
  }

  modele <- system.file("qgis", package = "sommieR")
  fichiers <- c("limites.qgs", "limites_attachments.zip", "terrain.gpkg")
  if (!all(file.exists(file.path(modele, fichiers)))) {
    stop("Modele QGIS introuvable dans le paquet.", call. = FALSE)
  }
  dir.create(file.path(dossier, "DCIM"), recursive = TRUE)
  file.copy(file.path(modele, fichiers), dossier)
  gpkg <- file.path(dossier, "terrain.gpkg")

  elements <- etat_des_elements(con, foret_id, elements, anciennete_ans)
  ecrire_couches_elements(elements, gpkg)

  contours <- sf::st_as_sfc(ug$wkt, crs = 2154)
  union <- sf::st_union(contours)
  tampon_m <- attr(elements, "tampon_m") %||% 20
  tampon <- sf::st_buffer(union, tampon_m)
  ecrire_couche(sf::st_sf(nom = foret$nom[[1L]],
                          geometry = sf::st_cast(union, "MULTIPOLYGON")),
                gpkg, "foret")
  ecrire_couche(sf::st_sf(tampon_m = tampon_m,
                          geometry = sf::st_cast(tampon, "MULTIPOLYGON")),
                gpkg, "tampon")
  ecrire_couche(sf::st_sf(numero = ug$numero_affichage,
                          geometry = sf::st_cast(contours, "MULTIPOLYGON")),
                gpkg, "ug")
  if (!is.null(fond) && nrow(fond) > 0L) {
    ecrire_couche(sf::st_sf(
      reference = fond$reference,
      designation = paste(sub("^0+", "", fond$section),
                          sub("^0+", "", fond$numero)),
      geometry = sf::st_cast(sf::st_as_sfc(fond$wkt, crs = 2154),
                             "MULTIPOLYGON")
    ), gpkg, "parcelles")
  }

  qgs <- file.path(dossier, "limites.qgs")
  cadre <- sf::st_bbox(sf::st_buffer(tampon, 50))
  poser_valeurs_projet(qgs, c(
    "@@TITRE@@" = paste0("Limites - ", foret$nom[[1L]]),
    "@@OPERATEUR@@" = operateur,
    "@@FORET@@" = foret_id,
    'xmin="111111"' = sprintf('xmin="%.2f"', cadre[["xmin"]]),
    'ymin="2222222"' = sprintf('ymin="%.2f"', cadre[["ymin"]]),
    'xmax="333333"' = sprintf('xmax="%.2f"', cadre[["xmax"]]),
    'ymax="4444444"' = sprintf('ymax="%.2f"', cadre[["ymax"]])
  ))
  invisible(qgs)
}

#' Import des constats d'un projet QField
#'
#' @description
#' Relit le projet rapporte du terrain et inscrit au registre 2 une
#' reconnaissance de limite par constat, avec ses photos deposees sous leur
#' empreinte.
#'
#' @details
#' **Tout ou rien.** Chaque constat est controle avant toute ecriture : etat
#' connu, element present dans le projet (sauf `hors_plan`), date de visite,
#' photos presentes. Une seule faute fait echouer l'import, qui les liste
#' toutes a la fois : on corrige dans QField, puis on reimporte. Les entrees
#' s'ecrivent ensuite en une transaction.
#'
#' **Rejouable.** Chaque constat porte l'UUID que QField lui a donne a la
#' saisie ; il devient l'identifiant de l'entree. Reimporter le meme dossier
#' n'ecrit rien de plus, et le bilan le dit.
#'
#' **Le constat recopie l'element tel que l'agent l'a vu** : identifiant,
#' numero, categorie, nature, texte, millesime et coordonnees du plan, lus
#' dans le projet emporte. Au millesime suivant, le constat restera lisible.
#'
#' La position relevee entre au payload en WGS84, comme toute geometrie du
#' sommier. Les photos sont deposees par [sommier_deposer_photo()], qui ne les
#' modifie jamais ; la date et la position EXIF y sont des declarations de
#' l'appareil. L'entree porte NDP 0 : c'est un constat de terrain.
#'
#' @param con Connexion DBI.
#' @param foret_id UUID de la foret.
#' @param dossier Dossier du projet, rapporte du terrain.
#' @param depot Repertoire du depot de photos.
#' @param auteur Compte qui importe. L'agent qui a constate est l'operateur
#'   de chaque constat.
#'
#' @return Invisiblement, un bilan : `ecrits`, `deja_presents`, `photos`
#'   (nombre de photos deposees) et `entrees` (les entrees chainees).
#'
#' @seealso [sommier_projet_qfield()], [sommier_verifier_photos()]
#'
#' @export
sommier_importer_qfield <- function(con, foret_id, dossier, depot, auteur) {
  if (!requireNamespace("sf", quietly = TRUE)) {
    stop("Le paquet `sf` est requis pour lire le projet QField.",
         call. = FALSE)
  }
  foret_id <- valider_uuid(foret_id, "foret_id")
  dossier <- valider_texte(dossier, "dossier")
  depot <- valider_texte(depot, "depot")
  auteur <- valider_texte(auteur, "auteur")
  gpkg <- file.path(dossier, "terrain.gpkg")
  if (!file.exists(gpkg)) {
    stop("Pas de terrain.gpkg dans ", dossier, " : ce n'est pas un projet ",
         "engendre par sommier_projet_qfield().", call. = FALSE)
  }

  constats <- suppressWarnings(sf::read_sf(gpkg, layer = "constats"))
  photos <- suppressWarnings(sf::read_sf(gpkg, layer = "photos"))
  photos <- as.data.frame(photos)
  elements <- lire_elements_projet(gpkg)
  if (nrow(constats) == 0L) {
    return(invisible(list(ecrits = 0L, deja_presents = 0L, photos = 0L,
                          entrees = list())))
  }

  fautes <- controler_constats(constats, photos, elements, dossier)
  if (length(fautes) > 0L) {
    stop("Import refuse, rien n'est ecrit :\n",
         paste0("- ", fautes, collapse = "\n"), call. = FALSE)
  }

  constats$uuid <- tolower(constats$uuid)
  presents <- DBI::dbGetQuery(
    con, "SELECT id::text AS id FROM entree_sommier WHERE id = ANY($1::uuid[])",
    params = list(paste0("{", paste(constats$uuid, collapse = ","), "}"))
  )$id
  nouveaux <- constats[!constats$uuid %in% presents, ]

  positions <- positions_wgs84(nouveaux)
  n_photos <- 0L
  entrees <- lapply(seq_len(nrow(nouveaux)), function(i) {
    c <- nouveaux[i, ]
    siennes <- photos[tolower(photos$constat_uuid) == c$uuid, , drop = FALSE]
    deposees <- lapply(siennes$fichier, function(f) {
      sommier_deposer_photo(file.path(dossier, f), depot)
    })
    n_photos <<- n_photos + length(deposees)
    element <- if (is.na(c$element_id)) NULL else
      element_vu(elements[elements$id == c$element_id, , drop = FALSE])
    visite <- as.POSIXct(c$visite_le)
    sommier_entree(
      foret_id = foret_id,
      registre = 2L,
      date_evenement = as.Date(format(visite, "%Y-%m-%d")),
      auteur = auteur,
      ndp = 0L,
      id = c$uuid,
      payload = registre2_foncier(
        type_entree = "reconnaissance_limite",
        description = if (is.null(element)) "Element hors plan" else
          paste0("Reconnaissance de ", element$numero, " (",
                 element$categorie, ")"),
        etat = c$etat,
        element_pci = element,
        visite_le = visite,
        operateur = texte_ou_null(c$operateur),
        precision_m = nombre_ou_null(c$precision_m),
        source_gnss = texte_ou_null(c$source_gnss),
        releve_uuid = c$uuid,
        observations = texte_ou_null(c$observations),
        photos = if (length(deposees) > 0L) deposees,
        geometrie = positions[[i]]
      )
    )
  })
  chainees <- if (length(entrees) > 0L) sommier_ajouter(con, entrees) else list()
  invisible(list(ecrits = length(chainees), deja_presents = length(presents),
                 photos = n_photos, entrees = chainees))
}

# ---------------------------------------------------------------------------

# La designation d'un element, comme dans le rapport : la nature fournie par
# une table, sinon la categorie et le code ; le texte du plan cite a cote.
designation_element <- function(e) {
  details <- e$couche %in% c("points", "details", "surfaces")
  base <- ifelse(e$nature_source %in% "appelant", e$nature,
                 ifelse(details, paste0(e$categorie, ", code ", e$sym),
                        e$categorie))
  ifelse(is.na(e$texte), base,
         paste0(base, " - \u00ab ", e$texte, " \u00bb"))
}

# La derniere visite de chaque element, lue au sommier, et la couleur qui en
# decoule sur le terrain.
etat_des_elements <- function(con, foret_id, elements, anciennete_ans) {
  dernieres <- DBI::dbGetQuery(
    con,
    "SELECT element_id, date_evenement, etat FROM v_reconnaissance_derniere
      WHERE foret_id = $1",
    params = list(foret_id)
  )
  rang <- match(elements$id, dernieres$element_id)
  elements$derniere_visite <- as.Date(dernieres$date_evenement[rang])
  elements$dernier_etat <- dernieres$etat[rang]
  limite <- seq(Sys.Date(), by = paste0("-", anciennete_ans, " years"),
                length.out = 2L)[[2L]]
  etat <- elements$dernier_etat
  elements$a_visiter <- ifelse(
    is.na(etat) | etat == "inaccessible", "a_voir",
    ifelse(etat %in% c("non_retrouve", "detruit"), "perdu",
           ifelse(elements$derniere_visite < limite, "ancienne",
                  ifelse(etat == "endommage", "defaut", "vu"))))
  elements$designation <- designation_element(elements)
  elements
}

ecrire_couches_elements <- function(elements, gpkg) {
  colonnes <- c("id", "numero", "categorie", "nature", "texte", "designation",
                "situation", "distance_limite_m", "millesime",
                "derniere_visite", "dernier_etat", "a_visiter", "x", "y")
  geometries <- sf::st_as_sfc(elements$wkt, crs = 2154)
  dimension <- sf::st_dimension(geometries)
  for (couche in list(list("elements_points", 0L, "MULTIPOINT"),
                      list("elements_lignes", 1L, "MULTILINESTRING"),
                      list("elements_surfaces", 2L, "MULTIPOLYGON"))) {
    garde <- which(dimension == couche[[2L]])
    donnees <- elements[garde, colonnes, drop = FALSE]
    ecrire_couche(sf::st_sf(donnees,
                            geometry = sf::st_cast(geometries[garde],
                                                   couche[[3L]])),
                  gpkg, couche[[1L]])
  }
  # Les ancres : un point par element, pour la liste de choix du formulaire.
  ancres <- sf::st_as_sf(
    data.frame(id = elements$id, numero = elements$numero,
               libelle = paste0(elements$numero, " - ", elements$designation),
               x = elements$x, y = elements$y, stringsAsFactors = FALSE),
    coords = c("x", "y"), crs = 2154
  )
  ecrire_couche(ancres, gpkg, "elements")
}

# Une couche de donnees est remplacee ; les autres couches du GeoPackage -
# les couches de saisie, surtout - n'en sont pas touchees.
ecrire_couche <- function(couche, gpkg, nom) {
  sf::st_write(couche, gpkg, layer = nom, delete_layer = TRUE, quiet = TRUE)
}

# Les valeurs reperes du modele. Le texte est echappe pour le XML : un nom de
# foret avec une esperluette ne doit pas casser le projet.
poser_valeurs_projet <- function(qgs, valeurs) {
  xml <- readLines(qgs, warn = FALSE, encoding = "UTF-8")
  for (repere in names(valeurs)) {
    valeur <- valeurs[[repere]]
    if (startsWith(repere, "@@")) {
      valeur <- echapper_xml(valeur)
    }
    xml <- gsub(repere, valeur, xml, fixed = TRUE)
  }
  writeLines(enc2utf8(xml), qgs, useBytes = TRUE)
}

echapper_xml <- function(x) {
  x <- gsub("&", "&amp;", x, fixed = TRUE)
  x <- gsub("<", "&lt;", x, fixed = TRUE)
  x <- gsub(">", "&gt;", x, fixed = TRUE)
  gsub("\"", "&quot;", x, fixed = TRUE)
}

lire_elements_projet <- function(gpkg) {
  morceaux <- lapply(c("elements_points", "elements_lignes",
                       "elements_surfaces"), function(nom) {
    couche <- tryCatch(sf::read_sf(gpkg, layer = nom), error = function(e) NULL)
    if (is.null(couche) || nrow(couche) == 0L) return(NULL)
    as.data.frame(sf::st_drop_geometry(couche))
  })
  garde <- morceaux[!vapply(morceaux, is.null, logical(1))]
  if (length(garde) == 0L) {
    return(data.frame(id = character(0), stringsAsFactors = FALSE))
  }
  do.call(rbind, garde)
}

controler_constats <- function(constats, photos, elements, dossier) {
  fautes <- character(0)
  for (i in seq_len(nrow(constats))) {
    c <- constats[i, ]
    nom <- paste0("constat ", i, if (!is.na(c$uuid)) paste0(" (", c$uuid, ")"))
    if (is.na(c$uuid) || !grepl(MOTIF_UUID, tolower(c$uuid))) {
      fautes <- c(fautes, paste0(nom, " : identifiant absent ou invalide"))
    }
    if (is.na(c$etat) || !c$etat %in% SOMMIER_ETATS_LIMITE) {
      fautes <- c(fautes, paste0(nom, " : etat inconnu (",
                                 if (is.na(c$etat)) "vide" else c$etat, ")"))
    } else if (identical(c$etat, "hors_plan") && !is.na(c$element_id)) {
      fautes <- c(fautes, paste0(nom, " : un element hors plan ne se ",
                                 "rattache a aucun element du plan"))
    } else if (!identical(c$etat, "hors_plan") && is.na(c$element_id)) {
      fautes <- c(fautes, paste0(nom, " : aucun element du plan choisi"))
    }
    if (!is.na(c$element_id) && !c$element_id %in% elements$id) {
      fautes <- c(fautes, paste0(nom, " : element inconnu du projet (",
                                 c$element_id, ")"))
    }
    if (is.na(c$visite_le)) {
      fautes <- c(fautes, paste0(nom, " : date de visite absente"))
    }
    if (!is.na(c$uuid)) {
      siennes <- photos$fichier[tolower(photos$constat_uuid) == tolower(c$uuid)]
      for (f in siennes) {
        if (is.na(f) || !file.exists(file.path(dossier, f))) {
          fautes <- c(fautes, paste0(nom, " : photo introuvable (",
                                     if (is.na(f)) "vide" else f, ")"))
        } else if (!tolower(tools::file_ext(f)) %in% names(SOMMIER_TYPES_PHOTO)) {
          fautes <- c(fautes, paste0(nom, " : type de photo non reconnu (", f,
                                     ")"))
        }
      }
    }
  }
  fautes
}

# La position relevee, en WGS84 comme toute geometrie de payload. Un constat
# sans position reste un constat : l'agent a pu saisir sans signal.
positions_wgs84 <- function(constats) {
  geometries <- sf::st_geometry(constats)
  vide <- sf::st_is_empty(geometries)
  if (all(vide)) {
    return(vector("list", nrow(constats)))
  }
  coordonnees <- matrix(NA_real_, nrow(constats), 2L)
  coordonnees[!vide, ] <- sf::st_coordinates(
    sf::st_transform(geometries[!vide], 4326)
  )[, 1:2, drop = FALSE]
  lapply(seq_len(nrow(constats)), function(i) {
    if (vide[[i]]) NULL else geom_point(coordonnees[i, 1L], coordonnees[i, 2L])
  })
}

element_vu <- function(e) {
  vide <- function(x) is.null(x) || length(x) == 0L || is.na(x)
  compacter(list(
    id = e$id[[1L]],
    numero = if (!vide(e$numero)) e$numero[[1L]],
    categorie = if (!vide(e$categorie)) e$categorie[[1L]],
    nature = if (!vide(e$nature)) e$nature[[1L]],
    texte = if (!vide(e$texte)) e$texte[[1L]],
    millesime = if (!vide(e$millesime)) format(as.Date(e$millesime[[1L]])),
    x = if (!vide(e$x)) as.numeric(e$x[[1L]]),
    y = if (!vide(e$y)) as.numeric(e$y[[1L]])
  ))
}

texte_ou_null <- function(x) {
  if (length(x) == 0L || is.na(x) || !nzchar(trimws(x))) NULL else x
}

nombre_ou_null <- function(x) {
  if (length(x) == 0L || is.na(x)) NULL else as.numeric(x)
}
