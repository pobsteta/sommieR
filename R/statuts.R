#' Statuts des especes : la BDC Statuts de TAXREF
#'
#' @description
#' Rend les statuts reglementaires et de conservation des especes - protection
#' nationale, regionale et departementale, listes rouges, annexes des
#' directives Habitats et Oiseaux, sensibilite - tels que la base de
#' connaissance "Statuts" (BDC Statuts) de PatriNat les donne au lieu de la
#' foret, rapportes par `CD_REF`.
#'
#' @details
#' **D'ou vient la donnee.** Le fichier de la BDC Statuts que l'INPN publiait
#' (`inpn.mnhn.fr/telechargement/referentielEspece/bdc-statuts-especes`, vers
#' lequel data.gouv.fr renvoie toujours) ne repond plus depuis la cyberattaque
#' de l'ete 2025. L'API de TAXREF, elle, sert de nouveau la BDC Statuts
#' (`taxref.mnhn.fr/api`, ressource `status/search/lines`), et c'est elle que
#' la fonction interroge. La version citee est celle de TAXREF que l'API
#' declare courante (`taxrefVersions/current`) : la BDC Statuts suit les
#' versions de TAXREF.
#'
#' **Le lieu de la foret, et non une liste nationale.** L'API rend, pour un
#' point, les statuts qui s'y appliquent : nationaux, de la region, du
#' departement. Le point est pris dans la foret (un point de sa surface, en
#' WGS84) : une liste rouge regionale du Centre-Val de Loire vaut pour
#' Orleans, pas celle de Bourgogne. Une foret a cheval sur deux departements
#' ne recoit que les statuts departementaux de l'un d'eux.
#'
#' **Un taxon a la fois.** Une requete portant plusieurs taxons, ou un type de
#' statut sur tout le lieu, dedoublonne les lignes d'un taxon a l'autre : le
#' Pic mar y perd sa protection nationale, que le Pouillot siffleur garde. La
#' fonction interroge donc l'API taxon par taxon, et garde en cache, par lieu,
#' ce qu'elle a lu : un second appel ne demande au reseau que les taxons
#' nouveaux, et le rapport ne le sollicite jamais. Une nouvelle version de
#' TAXREF invalide le cache du lieu.
#'
#' @param cd_ref `CD_REF` des especes, ou la table que rend
#'   [sommier_especes_observees()].
#' @param emprise Couche des unites de gestion ([sommier_couche_ug()]) : la
#'   foret, dont un point fixe le lieu des statuts.
#' @param cache Repertoire de cache.
#' @param source Adresse de l'API TAXREF.
#' @param force Relire tous les taxons, meme en cache.
#'
#' @return Un `data.frame`, une ligne par statut : `cd_ref`, `cd_nom` (le nom
#'   sous lequel le texte cite l'espece), `type` (`PN`, `PR`, `PD`, `LRN`,
#'   `LRR`, `DH`, `DO`, `SENSNAT`...), `groupe`, `code`, `libelle`,
#'   `remarque`, `lieu`, `niveau`. Attributs : `version` (par exemple
#'   `"BDC Statuts, TAXREF v18.0"`), `source`, `lieu` (code INSEE du lieu
#'   des statuts), `consulte_le`, `consultes` (les `CD_REF` interroges, avec
#'   ou sans statut).
#'
#' @seealso [sommier_especes_observees()] et son argument `statuts`.
#'
#' @examples
#' # Necessite un acces reseau (un appel par espece, puis le cache) :
#' # statuts <- sommier_statuts_taxref(c(3619L, 2660L), sommier_couche_ug(con, foret))
#'
#' @export
sommier_statuts_taxref <- function(cd_ref, emprise, cache = NULL,
                                   source = SOMMIER_SOURCE_STATUTS,
                                   force = FALSE) {
  if (is.data.frame(cd_ref)) {
    cd_ref <- cd_ref$cd_ref
  }
  cd_ref <- unique(as.integer(cd_ref[!is.na(cd_ref)]))
  source <- valider_texte(source, "source")
  point <- point_foret(emprise)
  dossier <- file.path(repertoire_cache(cache), "statuts")
  dir.create(dossier, recursive = TRUE, showWarnings = FALSE)
  rds <- file.path(dossier, sprintf("statuts_%.4f_%.4f.rds", point[["lat"]],
                                    point[["lon"]]))
  garde <- if (file.exists(rds) && !isTRUE(force)) readRDS(rds) else NULL
  manquants <- setdiff(cd_ref, garde$consultes)
  if (length(manquants) > 0L) {
    version <- version_taxref_api(source)
    if (is.null(garde) || !identical(garde$version, version)) {
      garde <- NULL
      manquants <- cd_ref
    }
    lus <- lapply(manquants, statuts_taxon_api, source = source,
                  point = point)
    lieu <- unique(stats::na.omit(unlist(lapply(lus, attr, "lieu"))))
    garde <- list(
      lignes = do.call(rbind, c(list(garde$lignes %||% statuts_vides()), lus)),
      consultes = c(garde$consultes, manquants),
      version = version,
      source = source,
      lieu = if (length(lieu) > 0L) lieu[[1L]] else garde$lieu %||% NA_character_,
      consulte_le = format(Sys.Date())
    )
    saveRDS(garde, rds)
  }
  statuts <- garde$lignes[garde$lignes$cd_ref %in% cd_ref, , drop = FALSE]
  rownames(statuts) <- NULL
  attr(statuts, "version") <- garde$version %||% NA_character_
  attr(statuts, "source") <- garde$source %||% source
  attr(statuts, "lieu") <- garde$lieu %||% NA_character_
  attr(statuts, "consulte_le") <- garde$consulte_le %||% NA_character_
  attr(statuts, "consultes") <- intersect(cd_ref, garde$consultes)
  statuts
}

# ---------------------------------------------------------------------------

SOMMIER_SOURCE_STATUTS <- "https://taxref.mnhn.fr/api"

# Ce que le rapport dit d'une protection, et dans quel ordre.
LIBELLES_PROTECTION <- c(PN = "nationale", PR = "r\u00e9gionale",
                         PD = "d\u00e9partementale")

# Les categories des listes rouges, de la plus grave a la moins renseignee :
# une espece peut figurer plusieurs fois a la meme liste (nicheuse,
# hivernante, de passage), et c'est la plus menacee qui se rapporte.
CATEGORIES_LISTE_ROUGE <- c("EX", "EW", "RE", "CR", "EN", "VU", "NT", "LC",
                            "DD", "NA", "NE")

# Un point de la foret, en WGS84 : sur sa surface, pas a son centre, qui
# peut tomber hors d'une foret en croissant.
point_foret <- function(emprise) {
  if (!requireNamespace("sf", quietly = TRUE)) {
    stop("Le paquet `sf` est requis pour situer la foret.", call. = FALSE)
  }
  contours <- emprise$wkt[!is.na(emprise$wkt)]
  if (length(contours) == 0L) {
    stop("L'emprise ne porte aucun contour connu : on ne sait pas ou ",
         "chercher les statuts.", call. = FALSE)
  }
  surface <- sf::st_union(sf::st_as_sfc(contours, crs = 2154))
  xy <- sf::st_coordinates(sf::st_transform(sf::st_point_on_surface(surface),
                                            4326))
  c(lon = round(unname(xy[1L, 1L]), 4L), lat = round(unname(xy[1L, 2L]), 4L))
}

# Un appel a l'API TAXREF : la reponse lue, ou NULL si l'API dit ne rien
# avoir (404 : elle le dit ainsi d'un taxon sans statut). Tout autre echec
# arrete : un statut absent faute de reseau n'est pas une absence de statut.
api_taxref <- function(source, chemin, requete = list()) {
  if (!requireNamespace("curl", quietly = TRUE)) {
    stop("Le paquet `curl` est requis pour interroger l'API TAXREF.",
         call. = FALSE)
  }
  url <- paste0(sub("/+$", "", source), "/", chemin)
  if (length(requete) > 0L) {
    url <- paste0(url, "?", paste0(names(requete), "=",
                                   vapply(requete, as.character, character(1)),
                                   collapse = "&"))
  }
  poignee <- curl::new_handle()
  curl::handle_setheaders(poignee, Accept = "application/hal+json;version=1")
  reponse <- try(curl::curl_fetch_memory(url, handle = poignee), silent = TRUE)
  if (inherits(reponse, "try-error")) {
    stop("API TAXREF injoignable : ", url, "\n",
         trimws(conditionMessage(attr(reponse, "condition"))), call. = FALSE)
  }
  if (reponse$status_code == 404L) {
    return(NULL)
  }
  type <- curl::parse_headers_list(reponse$headers)[["content-type"]]
  if (reponse$status_code >= 400L || is.null(type) || !grepl("json", type)) {
    stop("L'API TAXREF ne repond pas comme attendu : ", url, " (statut HTTP ",
         reponse$status_code, ", ", type %||% "sans type", ").",
         call. = FALSE)
  }
  jsonlite::fromJSON(rawToChar(reponse$content), simplifyVector = FALSE)
}

version_taxref_api <- function(source) {
  courante <- api_taxref(source, "taxrefVersions/current")
  if (is.null(courante$name)) {
    stop("L'API TAXREF ne dit pas sa version : on ne cite pas des statuts ",
         "sans version.", call. = FALSE)
  }
  paste0("BDC Statuts, TAXREF v", courante$name)
}

statuts_vides <- function() {
  data.frame(cd_ref = integer(0), cd_nom = integer(0), type = character(0),
             groupe = character(0), code = character(0),
             libelle = character(0), remarque = character(0),
             lieu = character(0), niveau = character(0),
             stringsAsFactors = FALSE)
}

statuts_taxon_api <- function(cd_ref, source, point) {
  lignes <- list()
  page <- 1L
  repeat {
    lu <- api_taxref(source, "status/search/lines", list(
      taxrefId = cd_ref, latitude = point[["lat"]],
      longitude = point[["lon"]], page = page, size = 1000L
    ))
    lignes <- c(lignes, lu[["_embedded"]][["status"]])
    pages <- lu$page$totalPages %||% 1L
    if (is.null(lu) || page >= pages) {
      break
    }
    page <- page + 1L
  }
  statuts <- lignes_statuts(lignes, cd_ref)
  lieux <- unlist(lapply(lignes, `[[`, "requestedLocationId"))
  attr(statuts, "lieu") <- if (length(lieux) > 0L) lieux[[1L]] else
    NA_character_
  statuts
}

lignes_statuts <- function(lignes, cd_ref) {
  if (length(lignes) == 0L) {
    return(statuts_vides())
  }
  champ <- function(...) {
    vapply(lignes, function(l) {
      v <- l[[c(...)]]
      if (is.null(v)) NA_character_ else as.character(v)
    }, character(1))
  }
  data.frame(
    # La reponse rapporte le nom au nom valide ; a defaut, celui demande.
    cd_ref = as.integer(ifelse(is.na(champ("taxon", "referenceId")), cd_ref,
                               champ("taxon", "referenceId"))),
    cd_nom = as.integer(champ("taxon", "id")),
    type = basename(champ("_links", "statusType", "href")),
    groupe = champ("statusTypeGroup"),
    code = champ("statusCode"),
    libelle = champ("statusName"),
    remarque = champ("statusRemarks"),
    lieu = champ("locationName"),
    niveau = champ("locationAdminLevel"),
    stringsAsFactors = FALSE
  )
}

# Les statuts d'une table d'especes, une colonne par question que le
# gestionnaire se pose : est-elle protegee, menacee, d'interet
# communautaire, sensible ? Une espece que l'API n'a pas renseignee porte
# NA partout : on ne sait pas, et on ne dit pas non.
ajouter_statuts <- function(especes, statuts) {
  if (!is.data.frame(statuts) || is.null(attr(statuts, "version")) ||
      !all(c("cd_ref", "type", "code", "libelle") %in% names(statuts))) {
    stop("`statuts` doit venir de sommier_statuts_taxref().", call. = FALSE)
  }
  consultes <- attr(statuts, "consultes") %||% unique(statuts$cd_ref)
  par_espece <- function(f) {
    vapply(especes$cd_ref, function(cd) {
      if (!cd %in% consultes) {
        return(NA_character_)
      }
      f(statuts[statuts$cd_ref == cd, , drop = FALSE])
    }, character(1))
  }
  especes$protection <- par_espece(function(s) {
    types <- intersect(names(LIBELLES_PROTECTION), s$type)
    if (length(types) == 0L) NA_character_ else
      paste(LIBELLES_PROTECTION[types], collapse = ", ")
  })
  liste_rouge <- function(type) function(s) {
    codes <- intersect(CATEGORIES_LISTE_ROUGE, s$code[s$type == type])
    if (length(codes) == 0L) NA_character_ else codes[[1L]]
  }
  especes$liste_rouge_nationale <- par_espece(liste_rouge("LRN"))
  especes$liste_rouge_regionale <- par_espece(liste_rouge("LRR"))
  especes$directives <- par_espece(function(s) {
    annexes <- function(type) {
      a <- unique(sub("^.*Annexe\\s+([IVX]+(/[0-9]+)?).*$", "\\1",
                      s$libelle[s$type == type & grepl("Annexe", s$libelle)]))
      if (length(a) == 0L) NULL else paste(type, paste(sort(a), collapse = ", "))
    }
    d <- c(annexes("DH"), annexes("DO"))
    if (length(d) == 0L) NA_character_ else paste(d, collapse = " ; ")
  })
  consulte <- especes$cd_ref %in% consultes
  especes$protegee <- ifelse(consulte, !is.na(especes$protection), NA)
  especes$sensible <- ifelse(consulte, especes$cd_ref %in% statuts$cd_ref[
    statuts$type %in% c("SENSNAT", "SENSREG", "SENSDEP")], NA)
  attr(especes, "statuts") <- attr(statuts, "version")
  attr(especes, "statuts_lieu") <- attr(statuts, "lieu")
  attr(especes, "statuts_consultes_le") <- attr(statuts, "consulte_le")
  especes
}
