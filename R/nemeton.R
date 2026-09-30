#' Sylvoecoregion d'une foret
#'
#' @description
#' Rend la sylvoecoregion (SER) de l'IGN qui contient la foret : son code et
#' son nom. C'est a cette maille que l'IFN publie ses references - le
#' prelevement observe, le volume sur pied par essence -, et c'est donc elle
#' qui dit a quoi comparer une possibilite.
#'
#' @details
#' La couche des SER est celle que l'IGN publie
#' (`inventaire-forestier.ign.fr`, `ser_l93.zip`). Elle se telecharge une
#' fois, explicitement, et se garde en cache ; ni le rapport ni la balance ne
#' la demandent au reseau. La foret est situee par le point interieur de
#' l'union de ses unites : une foret a cheval sur deux SER est rattachee a
#' celle qui contient ce point, et la fonction le signale.
#'
#' @param emprise Couche des unites de gestion ([sommier_couche_ug()]), ou
#'   `data.frame` a colonne `wkt` en Lambert-93.
#' @param cache Repertoire de cache.
#' @param force Retelecharger la couche meme si elle est en cache.
#'
#' @return Une liste : `code` (par exemple `"B70"`), `nom`
#'   (`"Sologne-Orleanais"`), `plusieurs` (la foret touche-t-elle plusieurs
#'   SER ?) et `source`.
#'
#' @seealso [sommier_rapport_quarto()] et son argument `reference_ifn`.
#'
#' @examples
#' # Necessite un acces reseau au premier appel :
#' # sommier_ser(sommier_couche_ug(con, foret))
#'
#' @export
sommier_ser <- function(emprise, cache = NULL, force = FALSE) {
  if (!requireNamespace("sf", quietly = TRUE)) {
    stop("Le paquet `sf` est requis pour situer la foret.", call. = FALSE)
  }
  shp <- couche_ser(cache, force)
  ser <- sf::st_make_valid(sf::st_transform(sf::read_sf(shp), 2154))
  union <- emprise_tamponnee(emprise, 0)
  point <- sf::st_point_on_surface(union)
  dedans <- sf::st_intersects(point, ser)[[1L]]
  if (length(dedans) == 0L) {
    stop("La foret n'est dans aucune sylvoecoregion de la couche de l'IGN : ",
         "est-elle bien en France metropolitaine ?", call. = FALSE)
  }
  touchees <- sf::st_intersects(union, ser)[[1L]]
  attributs <- sf::st_drop_geometry(ser)
  list(
    code = as.character(attributs$codeser[[dedans[[1L]]]]),
    nom = as.character(attributs$NomSER[[dedans[[1L]]]]),
    plusieurs = length(touchees) > 1L,
    source = SOMMIER_SOURCE_SER
  )
}

#' Indices d'un projet nemeton, par unite
#'
#' @description
#' Lit les indicateurs qu'un projet nemeton a calcules pour ses unites de
#' gestion (`data/indicators.parquet`) et en rend ceux qui eclairent la
#' possibilite : le volume sur pied, la part recente en coupe rase.
#'
#' @details
#' **Des estimations, pas des ecritures.** Rien de ce qui est lu ici n'entre
#' dans la chaine. Les indices se passent au rapport
#' ([sommier_rapport_quarto()], argument `indices`), qui les presente comme
#' tels, avec leur source et leur date.
#'
#' **Le rapprochement se fait par le numero de parcelle.** nemeton identifie
#' ses unites par un `ug_id` et un libelle (« Foret domaniale d'Orleans -
#' parcelle 1039 ») ; le sommier, par un UUID et un `numero_affichage`
#' (« 1039 »). Le numero est lu a la fin du libelle, et le rapport dit
#' combien d'unites il n'a pas su apparier plutot que d'en deviner.
#'
#' Le volume sur pied (`P1`, m3/ha) est calcule par nemeton sur la hauteur
#' LiDAR HD et les tarifs de l'IFN, le diametre et la densite pouvant etre
#' synthetises depuis la hauteur ; nemeton ne declare pas sa precision. `T3`
#' est la part de l'unite en coupe rase sur les cinq dernieres annees
#' (SUFOSAT) : une coupe plus ancienne n'y figure pas - voir
#' [sommier_coupes_sufosat()] pour l'historique.
#'
#' @param projet Dossier du projet nemeton (celui qui contient `data/`).
#'
#' @return Un `data.frame` : `ug_id`, `libelle`, `numero`, `surface_ha`,
#'   `volume_m3_ha` (P1), `coupe_rase_5ans_pct` (T3), `cadastral_refs`.
#'   Attributs `date_calcul` et `source`.
#'
#' @export
sommier_lire_indices_nemeton <- function(projet) {
  if (!requireNamespace("arrow", quietly = TRUE)) {
    stop("Le paquet `arrow` est requis pour lire les indices de nemeton.",
         call. = FALSE)
  }
  projet <- valider_texte(projet, "projet")
  fichier <- file.path(projet, "data", "indicators.parquet")
  if (!file.exists(fichier)) {
    stop("Pas d'indices dans ", projet, " : `data/indicators.parquet` ",
         "manque.", call. = FALSE)
  }
  brut <- as.data.frame(arrow::read_parquet(fichier))
  colonne <- function(nom) {
    if (nom %in% names(brut)) brut[[nom]] else rep(NA, nrow(brut))
  }
  libelle <- as.character(colonne("label"))
  indices <- data.frame(
    ug_id = as.character(colonne("ug_id")),
    libelle = libelle,
    numero = numero_du_libelle(libelle),
    surface_ha = as.numeric(colonne("surface_m2")) / 10000,
    volume_m3_ha = as.numeric(colonne("indicateur_p1_volume")),
    coupe_rase_5ans_pct = as.numeric(colonne("indicateur_t3_coupes_rases")),
    cadastral_refs = as.character(colonne("cadastral_refs")),
    stringsAsFactors = FALSE
  )
  attr(indices, "date_calcul") <- as.Date(file.mtime(fichier))
  attr(indices, "source") <- paste0("nemeton, projet ", basename(projet))
  indices
}

#' Coupes rases detectees par SUFOSAT, par unite et par annee
#'
#' @description
#' Agrege les rasters SUFOSAT - date de coupe (`AAJJJ`) et probabilite (%) -
#' par unite de gestion et par annee : surface detectee, date mediane,
#' probabilite moyenne.
#'
#' @details
#' **Une detection, pas un constat.** SUFOSAT voit un couvert disparaitre ; il
#' ne dit pas si c'est une coupe de regeneration, une coupe sanitaire ou un
#' chablis. Le rapport s'en sert pour signaler une coupe qu'aucun martelage
#' n'explique (argument `coupes_detectees` de [sommier_rapport_quarto()]), et
#' [sommier_importer_detections()] peut l'inscrire au registre 8 comme
#' detection a verifier.
#'
#' **Les petites surfaces sont ecartees.** Sous `surface_min_ha`, une
#' detection tient plus du liseret de lisiere que de la coupe. SUFOSAT repose
#' sur Sentinel-2 : il ne dit rien d'avant 2018.
#'
#' La lecture passe par GDAL (via `sf`), sans autre dependance.
#'
#' @param dates,proba Rasters SUFOSAT des dates (`AAJJJ`) et des
#'   probabilites (%), en Lambert-93, meme grille.
#' @param emprise Couche des unites de gestion ([sommier_couche_ug()]).
#' @param seuil_proba Probabilite minimale d'un pixel, en %.
#' @param surface_min_ha Surface minimale d'une detection, par unite et par
#'   annee.
#'
#' @return Un `data.frame` : `ug`, `annee`, `surface_ha`, `date_mediane`,
#'   `debut`, `fin`, `proba_moyenne`.
#'
#' @export
sommier_coupes_sufosat <- function(dates, proba, emprise, seuil_proba = 90,
                                   surface_min_ha = 0.5) {
  if (!requireNamespace("sf", quietly = TRUE)) {
    stop("Le paquet `sf` est requis pour lire SUFOSAT.", call. = FALSE)
  }
  for (f in c(dates, proba)) {
    if (!file.exists(f)) stop("Raster introuvable : ", f, ".", call. = FALSE)
  }
  seuil_proba <- valider_nombre(seuil_proba, "seuil_proba", min = 0, max = 100)
  surface_min_ha <- valider_nombre(surface_min_ha, "surface_min_ha", min = 0)
  if (is.null(emprise$numero_affichage) || is.null(emprise$wkt)) {
    stop("`emprise` doit porter `numero_affichage` et `wkt` ",
         "(voir sommier_couche_ug()).", call. = FALSE)
  }

  pixels <- merge(lire_xyz(dates), lire_xyz(proba), by = c("x", "y"),
                  suffixes = c("_date", "_proba"))
  pixels <- pixels[!is.na(pixels$v_date) & pixels$v_date > 0 &
                     pixels$v_date < 1e6 & !is.na(pixels$v_proba) &
                     pixels$v_proba >= seuil_proba & pixels$v_proba <= 100, ]
  vide <- data.frame(ug = character(0), annee = integer(0),
                     surface_ha = numeric(0), date_mediane = as.Date(character(0)),
                     debut = as.Date(character(0)), fin = as.Date(character(0)),
                     proba_moyenne = numeric(0), stringsAsFactors = FALSE)
  if (nrow(pixels) == 0L) {
    return(vide)
  }
  cote <- resolution_raster(dates)
  pixels$annee <- 2000L + as.integer(pixels$v_date %/% 1000)
  pixels$date <- as.Date(sprintf("%d-01-01", pixels$annee)) +
    (pixels$v_date %% 1000) - 1
  unites <- emprise[!is.na(emprise$wkt), , drop = FALSE]
  dedans <- sf::st_intersects(
    sf::st_as_sf(pixels, coords = c("x", "y"), crs = 2154),
    sf::st_as_sfc(unites$wkt, crs = 2154)
  )
  pixels$ug <- vapply(dedans, function(k) {
    if (length(k)) unites$numero_affichage[[k[[1L]]]] else NA_character_
  }, character(1))
  pixels <- pixels[!is.na(pixels$ug), ]
  if (nrow(pixels) == 0L) {
    return(vide)
  }
  groupes <- split(pixels, list(pixels$ug, pixels$annee), drop = TRUE)
  res <- do.call(rbind, lapply(groupes, function(g) {
    dates_g <- sort(g$date)
    data.frame(ug = g$ug[[1L]], annee = g$annee[[1L]],
               surface_ha = nrow(g) * cote^2 / 10000,
               date_mediane = dates_g[[ceiling(length(dates_g) / 2)]],
               debut = dates_g[[1L]], fin = dates_g[[length(dates_g)]],
               proba_moyenne = mean(g$v_proba), stringsAsFactors = FALSE)
  }))
  res <- res[res$surface_ha >= surface_min_ha, , drop = FALSE]
  res <- res[order(res$annee, -res$surface_ha), , drop = FALSE]
  rownames(res) <- NULL
  attr(res, "seuil_proba") <- seuil_proba
  attr(res, "surface_min_ha") <- surface_min_ha
  res
}

# ---------------------------------------------------------------------------

SOMMIER_SOURCE_SER <- "https://inventaire-forestier.ign.fr/IMG/zip/ser_l93.zip"

couche_ser <- function(cache, force) {
  dossier <- file.path(repertoire_cache(cache), "ser")
  shp <- file.path(dossier, "ser_l93.shp")
  if (file.exists(shp) && !isTRUE(force)) {
    return(shp)
  }
  dir.create(dossier, recursive = TRUE, showWarnings = FALSE)
  archive <- file.path(dossier, "ser_l93.zip")
  telecharger(SOMMIER_SOURCE_SER, archive)
  utils::unzip(archive, exdir = dossier)
  unlink(archive)
  if (!file.exists(shp)) {
    stop("L'archive des SER ne contient pas `ser_l93.shp` : son format a ",
         "change.", call. = FALSE)
  }
  shp
}

# « Foret domaniale d'Orleans - parcelle 1039 » : le numero est ce qui suit
# « parcelle ». Un libelle qui ne le porte pas rend NA - on n'apparie pas au
# hasard.
numero_du_libelle <- function(libelle) {
  trouve <- regmatches(libelle, regexec("parcelle\\s+(\\S+)\\s*$", libelle,
                                        ignore.case = TRUE))
  vapply(trouve, function(t) if (length(t) == 2L) t[[2L]] else NA_character_,
         character(1))
}

lire_xyz <- function(raster) {
  xyz <- tempfile(fileext = ".xyz")
  on.exit(unlink(xyz), add = TRUE)
  sf::gdal_utils("translate", raster, xyz, options = c("-of", "XYZ"),
                 quiet = TRUE)
  valeurs <- utils::read.table(xyz, col.names = c("x", "y", "v"))
  valeurs
}

resolution_raster <- function(raster) {
  info <- sf::gdal_utils("info", raster, quiet = TRUE)
  taille <- regmatches(info, regexec("Pixel Size = \\(([0-9.]+),", info))[[1L]]
  as.numeric(taille[[2L]])
}
