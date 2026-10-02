#' Referentiel taxonomique TAXREF
#'
#' @description
#' Rend TAXREF, le referentiel taxonomique national, qui fait reference pour
#' nommer une espece en France : un taxon s'y identifie par son `CD_NOM`, et
#' son nom valide par son `CD_REF`.
#'
#' @details
#' TAXREF se lit dans un fichier, pas dans une API : l'archive Darwin Core que
#' PatriNat publie sur l'IPT de GBIF France se telecharge une fois,
#' explicitement, et se garde en cache, reduite aux especes et a leurs noms
#' valides. Ni le rapport ni [sommier_especes_observees()] ne la redemandent
#' au reseau, et ils ne dependent donc pas de l'etat des serveurs du Museum.
#' La version est lue dans l'archive (`eml.xml`), pas dans son adresse : une
#' archive qui ne la dit pas est refusee.
#'
#' @param cache Repertoire de cache.
#' @param source Adresse de l'archive Darwin Core de TAXREF, ou chemin d'une
#'   archive deja telechargee.
#' @param force Relire la source meme si TAXREF est en cache.
#'
#' @return Un `data.frame` : `cd_nom`, `cd_ref`, `nom` (sans auteur),
#'   `auteur`, `rang`, `regne`, `embranchement`, `classe`, `ordre`, `famille`,
#'   `nom_vernaculaire`. Attributs `version` (par exemple `"TAXREF v18.0"`) et
#'   `source`.
#'
#' @seealso [sommier_especes_observees()]
#'
#' @examples
#' # Necessite un acces reseau au premier appel (32 Mo) :
#' # taxref <- sommier_taxref()
#'
#' @export
sommier_taxref <- function(cache = NULL, source = SOMMIER_SOURCE_TAXREF,
                           force = FALSE) {
  source <- valider_texte(source, "source")
  dossier <- file.path(repertoire_cache(cache), "taxref")
  rds <- file.path(dossier, "taxref.rds")
  if (file.exists(rds) && !isTRUE(force)) {
    return(readRDS(rds))
  }
  dir.create(dossier, recursive = TRUE, showWarnings = FALSE)
  archive <- source
  if (!file.exists(source)) {
    archive <- file.path(dossier, "taxref-dwca.zip")
    telecharger(source, archive)
    on.exit(unlink(archive), add = TRUE)
  }
  taxref <- lire_archive_taxref(archive)
  attr(taxref, "source") <- source
  saveRDS(taxref, rds)
  taxref
}

#' Especes observees dans la foret et a ses abords
#'
#' @description
#' Rend les especes que d'autres ont observees dans la foret et autour - des
#' ornithologues, des botanistes, les inventaires nationaux -, nommees dans
#' TAXREF : une ligne par `CD_REF`, deux synonymes etant une espece.
#'
#' @details
#' **Un contexte, hors de la chaine.** Une observation d'un tiers n'est pas un
#' constat : rien n'entre au registre 9, et ce que le registre inventorie ne
#' change pas. Le rapport presente ces especes comme la reference IFN :
#' sourcees, datees, hors registre.
#'
#' **La source.** GBIF, par `rgbif`, sur la boite de la foret elargie de
#' `tampon_m` ; les observations sont ensuite retenues si elles tombent dans
#' la foret tamponnee. Seules les observations presentes, georeferencees, sans
#' defaut geographique signale par GBIF et depuis `depuis` sont lues. OpenObs,
#' qui nomme nativement en TAXREF, s'ajoutera quand le Museum l'aura retabli.
#'
#' **Le rapprochement avec TAXREF.** GBIF nomme dans sa propre taxonomie. Le
#' nom d'espece de chaque observation est cherche parmi les noms d'espece de
#' TAXREF, du meme regne, hors emplois errones (`auct.`, `sensu`). Un homonyme
#' se departage par l'auteur, a l'annee pres ; un nom qui ne mene a rien est
#' retente sous le nom d'origine de l'observation (`originalNameUsage`), s'il
#' a la forme d'un binome latin. Ce qui mene encore a plusieurs noms valides,
#' ou a aucun, reste non rapproche : compte a part, pas devine.
#'
#' **Les unites de gestion.** Une observation n'est placee dans une unite que
#' si l'incertitude de sa position est connue et ne depasse pas
#' `incertitude_max_m` : une position floutee - c'est le sort des especes
#' sensibles - ne designe pas une unite.
#'
#' @param emprise Couche des unites de gestion ([sommier_couche_ug()]).
#' @param taxref TAXREF, tel que le rend [sommier_taxref()].
#' @param source Source des observations : `"gbif"`.
#' @param tampon_m Elargissement de la foret, en metres.
#' @param depuis Premiere annee d'observation retenue.
#' @param incertitude_max_m Incertitude de position au-dela de laquelle une
#'   observation n'est pas placee dans une unite, en metres.
#' @param limite Nombre maximal d'observations lues a la source.
#' @param occurrences Observations deja extraites (colonnes GBIF : `key`,
#'   `species`, `kingdom`, `decimalLongitude`, `decimalLatitude`,
#'   `coordinateUncertaintyInMeters`, `year`, `datasetKey`, `license`) ;
#'   `NULL` pour interroger la source.
#'
#' @return Un `data.frame` : `cd_ref`, `nom_valide`, `nom_vernaculaire`,
#'   `groupe`, `n_observations`, `premiere_annee`, `derniere_annee`, `ug`
#'   (unites ou des observations sont placees, separees par des virgules),
#'   `n_jeux`. Attributs : `source`, `extrait_le`, `parametres`, `taxref`
#'   (version), `jeux` (cle, titre, licence et nombre d'observations de chaque
#'   jeu de donnees, a citer), `non_rapprochees` (noms et nombres
#'   d'observations), `tronque` (la source avait plus que `limite`).
#'
#' @seealso [sommier_taxref()], [sommier_rapport_quarto()] et son argument
#'   `especes_observees`.
#'
#' @examples
#' # Necessite un acces reseau :
#' # taxref <- sommier_taxref()
#' # sommier_especes_observees(sommier_couche_ug(con, foret), taxref)
#'
#' @export
sommier_especes_observees <- function(emprise, taxref, source = "gbif",
                                      tampon_m = 500, depuis = 2000,
                                      incertitude_max_m = 100,
                                      limite = 20000, occurrences = NULL) {
  if (!requireNamespace("sf", quietly = TRUE)) {
    stop("Le paquet `sf` est requis pour situer les observations.",
         call. = FALSE)
  }
  source <- valider_choix(source, "source", SOMMIER_SOURCES_OBSERVATIONS)
  if (!is.data.frame(taxref) || is.null(attr(taxref, "version"))) {
    stop("`taxref` doit venir de sommier_taxref().", call. = FALSE)
  }
  zone <- emprise_tamponnee(emprise, tampon_m)
  tronque <- FALSE
  titres <- NULL
  if (is.null(occurrences)) {
    lu <- occurrences_gbif(zone, depuis, limite)
    occurrences <- lu$occurrences
    tronque <- lu$tronque
    titres <- titres_jeux_gbif(unique(occurrences$datasetKey))
  }
  especes <- especes_depuis_occurrences(occurrences, zone, emprise, taxref,
                                        depuis, incertitude_max_m)
  jeux <- attr(especes, "jeux")
  jeux$titre <- if (is.null(titres)) NA_character_ else
    unname(titres[jeux$cle])
  attr(especes, "jeux") <- jeux
  attr(especes, "source") <- source
  attr(especes, "extrait_le") <- format(Sys.Date())
  attr(especes, "parametres") <- list(tampon_m = tampon_m, depuis = depuis,
                                      incertitude_max_m = incertitude_max_m)
  attr(especes, "taxref") <- attr(taxref, "version")
  attr(especes, "tronque") <- tronque
  especes
}

# ---------------------------------------------------------------------------

SOMMIER_SOURCE_TAXREF <- "https://ipt.gbif.fr/archive.do?r=taxref"
SOMMIER_SOURCES_OBSERVATIONS <- "gbif"

# Les colonnes de `taxon.txt` que le sommier lit, et leur nom ici.
COLONNES_TAXREF <- c(
  taxonID = "cd_nom", acceptedNameUsageID = "cd_ref", scientificName = "nom",
  scientificNameAuthorship = "auteur", taxonRank = "rang", kingdom = "regne",
  phylum = "embranchement", class = "classe", order = "ordre",
  family = "famille", vernacularName = "nom_vernaculaire"
)

lire_archive_taxref <- function(archive) {
  contenu <- utils::unzip(archive, list = TRUE)$Name
  if (!all(c("taxon.txt", "eml.xml") %in% contenu)) {
    stop("L'archive TAXREF doit contenir `taxon.txt` et `eml.xml` : son ",
         "format a change.", call. = FALSE)
  }
  eml <- paste(readLines(unz(archive, "eml.xml"), warn = FALSE,
                         encoding = "UTF-8"), collapse = " ")
  version <- regmatches(eml, regexpr("TAXREF v[0-9]+(\\.[0-9]+)*", eml))
  if (length(version) == 0L) {
    stop("L'archive TAXREF ne dit pas sa version (`eml.xml`) : on ne cite ",
         "pas un referentiel sans version.", call. = FALSE)
  }
  entete <- strsplit(readLines(unz(archive, "taxon.txt"), n = 1L,
                               encoding = "UTF-8"), "\t", fixed = TRUE)[[1L]]
  manquantes <- setdiff(names(COLONNES_TAXREF), entete)
  if (length(manquantes) > 0L) {
    stop("Colonnes absentes de `taxon.txt` : ",
         paste(manquantes, collapse = ", "), ".", call. = FALSE)
  }
  classes <- ifelse(entete %in% names(COLONNES_TAXREF), "character", "NULL")
  brut <- utils::read.delim(unz(archive, "taxon.txt"), quote = "",
                            colClasses = classes, na.strings = "",
                            encoding = "UTF-8", check.names = FALSE)
  brut <- brut[, names(COLONNES_TAXREF)]
  names(brut) <- unname(COLONNES_TAXREF)
  # Les especes, et les noms valides auxquels elles renvoient : un synonyme
  # d'espece peut valoir pour une sous-espece.
  especes <- brut$rang %in% "species"
  garder <- especes | brut$cd_nom %in% brut$cd_ref[especes]
  taxref <- brut[garder, , drop = FALSE]
  taxref$cd_nom <- as.integer(taxref$cd_nom)
  taxref$cd_ref <- as.integer(taxref$cd_ref)
  rownames(taxref) <- NULL
  attr(taxref, "version") <- version[[1L]]
  taxref
}

# Les observations GBIF sur la boite de la zone : une boite, et non le contour,
# parce que GBIF veut des polygones dans un sens donne et d'une longueur
# bornee ; le contour sert ensuite, a la lecture.
occurrences_gbif <- function(zone, depuis, limite) {
  if (!requireNamespace("rgbif", quietly = TRUE)) {
    stop("Le paquet `rgbif` est requis pour interroger GBIF.", call. = FALSE)
  }
  boite <- sf::st_bbox(sf::st_transform(zone, 4326))
  wkt <- sprintf(
    "POLYGON((%1$.5f %2$.5f,%3$.5f %2$.5f,%3$.5f %4$.5f,%1$.5f %4$.5f,%1$.5f %2$.5f))",
    boite[["xmin"]], boite[["ymin"]], boite[["xmax"]], boite[["ymax"]]
  )
  lu <- rgbif::occ_data(
    geometry = wkt, hasCoordinate = TRUE, hasGeospatialIssue = FALSE,
    occurrenceStatus = "PRESENT",
    year = paste0(depuis, ",", format(Sys.Date(), "%Y")), limit = limite
  )
  occurrences <- as.data.frame(lu$data)
  list(occurrences = occurrences,
       tronque = isTRUE(lu$meta$count > nrow(occurrences)))
}

titres_jeux_gbif <- function(cles) {
  cles <- cles[!is.na(cles)]
  titres <- vapply(cles, function(cle) {
    jeu <- try(rgbif::dataset_get(cle), silent = TRUE)
    if (inherits(jeu, "try-error") || is.null(jeu$title)) NA_character_ else
      as.character(jeu$title)
  }, character(1))
  stats::setNames(titres, cles)
}

especes_depuis_occurrences <- function(occurrences, zone, emprise, taxref,
                                       depuis, incertitude_max_m) {
  colonnes <- c("species", "kingdom", "scientificName", "originalNameUsage",
                "decimalLongitude", "decimalLatitude",
                "coordinateUncertaintyInMeters", "year", "datasetKey",
                "license")
  for (colonne in setdiff(colonnes, names(occurrences))) {
    occurrences[[colonne]] <- rep(NA, nrow(occurrences))
  }
  occurrences <- occurrences[!is.na(occurrences$species) &
                               !is.na(occurrences$decimalLongitude) &
                               !is.na(occurrences$decimalLatitude) &
                               (is.na(occurrences$year) |
                                  occurrences$year >= depuis), , drop = FALSE]

  # La boite deborde la foret : on ne garde que ce qui tombe dans la zone.
  points <- sf::st_transform(sf::st_as_sf(
    occurrences, coords = c("decimalLongitude", "decimalLatitude"),
    crs = 4326, remove = FALSE
  ), 2154)
  dedans <- lengths(sf::st_intersects(points, zone)) > 0L
  occurrences <- occurrences[dedans, , drop = FALSE]
  points <- points[dedans, ]

  # L'unite, pour les seules positions assez precises.
  occurrences$ug <- NA_character_
  precis <- !is.na(occurrences$coordinateUncertaintyInMeters) &
    as.numeric(occurrences$coordinateUncertaintyInMeters) <= incertitude_max_m
  unites <- emprise[!is.na(emprise$wkt), , drop = FALSE]
  if (any(precis) && nrow(unites) > 0L) {
    formes <- sf::st_sf(numero = unites$numero_affichage,
                        geometry = sf::st_as_sfc(unites$wkt, crs = 2154))
    touche <- sf::st_intersects(points[precis, ], formes)
    occurrences$ug[precis] <- vapply(touche, function(i) {
      if (length(i) == 0L) NA_character_ else as.character(formes$numero[[i[[1L]]]])
    }, character(1))
  }

  # Un rapprochement par nom distinct, et non par observation : la meme
  # espece revient des centaines de fois.
  cles <- paste(occurrences$species, occurrences$kingdom,
                occurrences$scientificName, occurrences$originalNameUsage,
                sep = "\r")
  uniques <- !duplicated(cles)
  trouves <- rapprocher_taxref(
    occurrences$species[uniques], occurrences$kingdom[uniques], taxref,
    noms_complets = as.character(occurrences$scientificName[uniques]),
    noms_originaux = as.character(occurrences$originalNameUsage[uniques])
  )
  occurrences$cd_ref <- trouves[match(cles, cles[uniques])]
  rapprochees <- occurrences[!is.na(occurrences$cd_ref), , drop = FALSE]
  orphelines <- occurrences[is.na(occurrences$cd_ref), , drop = FALSE]

  especes <- if (nrow(rapprochees) == 0L) {
    data.frame(cd_ref = integer(0), n_observations = integer(0),
               premiere_annee = integer(0), derniere_annee = integer(0),
               ug = character(0), n_jeux = integer(0))
  } else {
    do.call(rbind, lapply(split(rapprochees, rapprochees$cd_ref), function(o) {
      ug <- sort(unique(o$ug[!is.na(o$ug)]))
      annees <- suppressWarnings(as.integer(o$year))
      data.frame(
        cd_ref = o$cd_ref[[1L]],
        n_observations = nrow(o),
        premiere_annee = if (all(is.na(annees))) NA_integer_ else
          min(annees, na.rm = TRUE),
        derniere_annee = if (all(is.na(annees))) NA_integer_ else
          max(annees, na.rm = TRUE),
        ug = if (length(ug) == 0L) NA_character_ else
          paste(ug, collapse = ", "),
        n_jeux = length(unique(o$datasetKey[!is.na(o$datasetKey)]))
      )
    }))
  }
  valides <- taxref[taxref$cd_nom == taxref$cd_ref, , drop = FALSE]
  fiche <- valides[match(especes$cd_ref, valides$cd_nom), , drop = FALSE]
  especes$nom_valide <- ifelse(is.na(fiche$auteur), fiche$nom,
                               paste(fiche$nom, fiche$auteur))
  especes$nom_vernaculaire <- fiche$nom_vernaculaire
  especes$groupe <- groupe_taxref(fiche$regne, fiche$embranchement,
                                  fiche$classe, fiche$ordre)
  especes <- especes[order(especes$groupe, -especes$n_observations,
                           especes$nom_valide), c(
    "cd_ref", "nom_valide", "nom_vernaculaire", "groupe", "n_observations",
    "premiere_annee", "derniere_annee", "ug", "n_jeux"
  )]
  rownames(especes) <- NULL

  attr(especes, "non_rapprochees") <- if (nrow(orphelines) == 0L) {
    data.frame(nom = character(0), n_observations = integer(0))
  } else {
    n <- table(orphelines$species)
    data.frame(nom = names(n), n_observations = as.integer(n),
               stringsAsFactors = FALSE)
  }
  jeux <- table(occurrences$datasetKey)
  licences <- tapply(as.character(occurrences$license), occurrences$datasetKey,
                     function(l) l[!is.na(l)][1L])
  attr(especes, "jeux") <- data.frame(
    cle = names(jeux), n_observations = as.integer(jeux),
    licence = unname(licences[names(jeux)]), stringsAsFactors = FALSE
  )
  especes
}

# Un nom d'espece, dans son regne, mene-t-il a un seul nom valide de TAXREF ?
# Un emploi errone ("auct. non", "sensu") designe un autre taxon que le nom :
# il ne sert pas au rapprochement. Deux noms valides pour un meme nom - un
# homonyme - se departagent par l'auteur, que GBIF donne dans son nom complet,
# a l'annee pres (Bechstein, 1792 chez GBIF, 1793 chez TAXREF). Un nom qui ne
# mene a rien est retente sous le nom d'origine de l'observation, s'il a la
# forme d'un binome latin : GBIF ecrit "sibillatrix" ce que l'observateur et
# TAXREF ecrivent "sibilatrix".
rapprocher_taxref <- function(noms, regnes, taxref, noms_complets = NULL,
                              noms_originaux = NULL) {
  candidats <- unique(taxref[taxref$rang %in% "species" &
                               !grepl("^(auct\\.|sensu)", taxref$auteur),
                             c("nom", "auteur", "regne", "cd_ref")])
  chercher <- function(nom, regne, complet) {
    if (is.na(nom)) {
      return(NA_integer_)
    }
    t <- candidats[candidats$nom == nom &
                     (is.na(regne) | candidats$regne %in% regne), ,
                   drop = FALSE]
    if (length(unique(t$cd_ref)) > 1L && !is.na(complet)) {
      auteur <- auteur_normalise(substring(complet, nchar(nom) + 1L))
      t <- t[nzchar(auteur) & auteur_normalise(t$auteur) == auteur, ,
             drop = FALSE]
    }
    trouve <- unique(t$cd_ref)
    if (length(trouve) == 1L) trouve else NA_integer_
  }
  vapply(seq_along(noms), function(i) {
    complet <- if (is.null(noms_complets)) NA_character_ else noms_complets[[i]]
    trouve <- chercher(noms[[i]], regnes[[i]], complet)
    original <- if (is.null(noms_originaux)) NA_character_ else
      noms_originaux[[i]]
    binome <- regmatches(original, regexpr("^[A-Z][a-z]+ [a-z-]+", original))
    if (is.na(trouve) && length(binome) == 1L && !identical(binome, noms[[i]])) {
      trouve <- chercher(binome, regnes[[i]], NA_character_)
    }
    trouve
  }, integer(1))
}

# "(Bechstein, 1793)" et "Bechstein 1792" designent le meme auteur.
auteur_normalise <- function(x) {
  x <- tolower(gsub("[0-9(),.&]", " ", x))
  x[is.na(x)] <- ""
  trimws(gsub("\\s+", " ", x))
}

# Le groupe que le lecteur reconnait, tire de la classification TAXREF. Les
# reptiles n'y ont pas de classe : ils se reconnaissent a leur ordre.
groupe_taxref <- function(regne, embranchement, classe, ordre) {
  groupe <- rep("Autres", length(regne))
  animal <- regne %in% "Animalia"
  groupe[animal] <- "Autres animaux"
  groupe[animal & embranchement %in% "Mollusca"] <- "Mollusques"
  groupe[animal & classe %in% "Arachnida"] <- "Arachnides"
  groupe[animal & classe %in% "Insecta"] <- "Insectes"
  groupe[animal & classe %in% c("Actinopterygii", "Petromyzonti",
                                "Elasmobranchii")] <- "Poissons"
  groupe[animal & classe %in% "Amphibia"] <- "Amphibiens"
  groupe[animal & ordre %in% c("Squamata", "Testudines")] <- "Reptiles"
  groupe[animal & classe %in% "Aves"] <- "Oiseaux"
  groupe[animal & classe %in% "Mammalia"] <- "Mammif\u00e8res"
  groupe[regne %in% "Plantae"] <- "Plantes"
  groupe[regne %in% "Fungi"] <- "Champignons et lichens"
  groupe
}
