#' Couches du PCI vecteur (EDIGEO)
#'
#' @description
#' Ce que le Plan Cadastral Informatise porte et que les livraisons GeoJSON
#' d'Etalab ecartent : les bornes, et les details topographiques lineaires -
#' murs, fosses, haies, clotures.
#'
#' @details
#' Les noms sont ceux des couches EDIGEO, tels que le pilote de GDAL les
#' expose. `bornes` correspond a `BORNE_id`, `details` a `TLINE_id`.
#'
#' @export
SOMMIER_COUCHES_PCI <- c(bornes = "BORNE_id", details = "TLINE_id",
                         parcelles = "PARCELLE_id", voies = "ZONCOMMUNI_id")

SOMMIER_SOURCE_PCI <- "https://cadastre.data.gouv.fr/data/dgfip-pci-vecteur"

# Lambert-93 : le proj4 que rend le pilote EDIGEO pour la France
# metropolitaine, reconnaissable a son parallele d'origine et son meridien.
MOTIF_LAMBERT93 <- "lat_0=46\\.5.*lon_0=3.*x_0=700000"

#' Feuilles cadastrales d'une commune
#'
#' @description
#' Rend les feuilles du plan cadastral, avec leur emprise, et permet de
#' retenir celles qui intersectent la foret.
#'
#' @details
#' Les feuilles se lisent sur la couche legere d'Etalab, dont les identifiants
#' correspondent exactement aux noms des archives EDIGEO. C'est ce qui rend le
#' lot praticable : Couchey compte dix-sept feuilles et une foret en touche
#' une ou deux, alors que rien dans l'archive EDIGEO ne dit ou elle se trouve
#' avant de l'avoir telechargee.
#'
#' @param code_insee Code INSEE de la commune.
#' @param emprise Couche des unites de gestion ([sommier_couche_ug()]), ou tout
#'   `data.frame` portant une colonne `wkt` en Lambert-93. `NULL` : toutes les
#'   feuilles.
#' @param marge_m Marge autour de l'emprise, en metres.
#' @param cache Repertoire de cache.
#'
#' @return Un `data.frame` : `feuille`, `section`, `echelle`, `wkt`.
#'
#' @seealso [sommier_fond_pci()]
#'
#' @examples
#' # Necessite un acces reseau :
#' # sommier_feuilles_pci("21200")
#'
#' @export
sommier_feuilles_pci <- function(code_insee, emprise = NULL, marge_m = 100,
                                 cache = NULL) {
  fond <- sommier_fond_cadastral(code_insee, couche = "feuilles",
                                 cache = cache)
  if (!requireNamespace("sf", quietly = TRUE)) {
    stop("Le paquet `sf` est requis pour lire les feuilles cadastrales.",
         call. = FALSE)
  }
  marge_m <- valider_nombre(marge_m, "marge_m", min = 0)

  couche <- sf::st_transform(
    sf::read_sf(paste0("/vsigzip/", normalizePath(fond$chemin))), 2154
  )
  if (!is.null(emprise) && nrow(emprise) > 0L && !is.null(emprise$wkt)) {
    boite <- sf::st_buffer(
      sf::st_as_sfc(sf::st_bbox(sf::st_as_sfc(emprise$wkt, crs = 2154))),
      marge_m
    )
    couche <- couche[sf::st_intersects(couche, boite, sparse = FALSE)[, 1L], ,
                     drop = FALSE]
  }

  data.frame(
    feuille = couche[["id"]], section = couche[["section"]] %||% NA_character_,
    echelle = suppressWarnings(as.numeric(couche[["echelle"]] %||% NA)),
    wkt = sf::st_as_text(sf::st_geometry(couche)),
    stringsAsFactors = FALSE
  )
}

#' Fond PCI vecteur d'une ou plusieurs feuilles
#'
#' @description
#' Telecharge et decompresse les archives EDIGEO des feuilles demandees.
#'
#' @details
#' **Le PCI est un decor, jamais une ecriture.** Rien de ce qui est telecharge
#' ici n'entre dans un registre, une empreinte ou un manifeste : une borne
#' relevee par la DGFiP est la donnee d'un tiers, et le constat qui fait foi
#' est celui du gestionnaire, porte au registre 2 avec sa geometrie (voir
#' [geometries]).
#'
#' Le telechargement est explicite, comme pour le fond parcellaire : ni le
#' rapport ni un export ne declenchent d'appel reseau.
#'
#' @param code_insee Code INSEE de la commune.
#' @param feuilles Identifiants de feuilles, tels que les rend
#'   [sommier_feuilles_pci()].
#' @param cache Repertoire de cache.
#' @param force Retelecharger meme si l'archive est deja decompressee.
#'
#' @return Invisiblement, un objet `sommier_fond_pci` : `feuilles` (table des
#'   feuilles et de leurs fichiers `.THF`), `code_insee`, `source`.
#'
#' @examples
#' # Necessite un acces reseau :
#' # sommier_fond_pci("21200", "212000000A01")
#'
#' @export
sommier_fond_pci <- function(code_insee, feuilles, cache = NULL,
                             force = FALSE) {
  code_insee <- valider_code_insee(code_insee)
  feuilles <- valider_liste_texte(feuilles, "feuilles")
  cache <- file.path(repertoire_cache(cache), "pci")
  if (!dir.exists(cache)) {
    dir.create(cache, recursive = TRUE)
  }
  departement <- substr(code_insee, 1L, 2L)

  chemins <- vapply(feuilles, function(feuille) {
    dossier <- file.path(cache, feuille)
    thf <- if (dir.exists(dossier)) fichier_thf(dossier) else NA_character_

    if (isTRUE(force) || is.na(thf)) {
      unlink(dossier, recursive = TRUE)
      dir.create(dossier, recursive = TRUE)
      archive <- file.path(dossier, paste0("edigeo-", feuille, ".tar.bz2"))
      telecharger(
        sprintf("%s/latest/edigeo/feuilles/%s/%s/edigeo-%s.tar.bz2",
                SOMMIER_SOURCE_PCI, departement, code_insee, feuille),
        archive
      )
      # `tar = "internal"` : l'implementation de R lit bzip2 sans dependre
      # d'un tar systeme, dont le comportement varie selon la plateforme.
      utils::untar(archive, exdir = dossier, tar = "internal")
      unlink(archive)
      thf <- fichier_thf(dossier)
      if (is.na(thf)) {
        stop("Archive EDIGEO sans fichier .THF : ", feuille,
             ". La livraison est incomplete ou son format a change.",
             call. = FALSE)
      }
    }
    thf
  }, character(1))

  structure(
    list(
      feuilles = data.frame(feuille = feuilles, thf = unname(chemins),
                            stringsAsFactors = FALSE),
      code_insee = code_insee, source = SOMMIER_SOURCE_PCI
    ),
    class = "sommier_fond_pci"
  )
}

#' @export
print.sommier_fond_pci <- function(x, ...) {
  cat("<fond PCI vecteur>\n")
  cat("  commune : ", x$code_insee, "\n", sep = "")
  cat("  feuilles: ", paste(x$feuilles$feuille, collapse = ", "), "\n", sep = "")
  invisible(x)
}

#' Lecture d'une couche du PCI vecteur
#'
#' @description
#' Lit une couche EDIGEO sur les feuilles telechargees, restreinte a l'emprise
#' de la foret.
#'
#' @details
#' **La nature d'un detail n'est pas devinee.** `TLINE_id` porte un attribut
#' `SYM` qui distingue mur, fosse, haie et cloture, mais sa nomenclature ne
#' figure ni dans le `.DIC` ni dans le `.SCD` de l'archive : elle appartient a
#' la symbolisation du plan, publiee ailleurs. Le code est donc rendu tel quel,
#' et `symboles` permet de fournir la correspondance. Sans elle, `nature` reste
#' `NA` - un paquet dont l'objet est la valeur probante ne peut pas afficher
#' « fosse » la ou le terrain montre un mur.
#'
#' Le systeme de coordonnees est **pose explicitement** : le pilote EDIGEO rend
#' un proj4 sans code EPSG. Il n'est pose que si ce proj4 est bien du
#' Lambert-93 ; une projection inattendue - les livraisons `edigeo-cc` sont en
#' coniques conformes par zone - est signalee plutot que reinterpretee.
#'
#' @param fond Objet `sommier_fond_pci`.
#' @param couche L'une des noms de [SOMMIER_COUCHES_PCI].
#' @param emprise Couche des unites de gestion, ou `data.frame` a colonne
#'   `wkt` en Lambert-93.
#' @param marge_m Marge autour de l'emprise, en metres.
#' @param symboles Vecteur nomme donnant la nature de chaque code `SYM`, par
#'   exemple `c("21" = "mur", "22" = "fosse")`. Il vous appartient : le paquet
#'   n'en embarque aucun tant qu'une source n'est pas citable.
#'
#' @return Un `data.frame` : `feuille`, `objet`, `sym`, `nature`, `wkt`.
#'
#' @examples
#' # Necessite `sf` et un fond telecharge :
#' # sommier_fond_pci_lire(fond, "bornes")
#'
#' @export
sommier_fond_pci_lire <- function(fond, couche = "bornes", emprise = NULL,
                                  marge_m = 100, symboles = NULL) {
  if (!inherits(fond, "sommier_fond_pci")) {
    stop("`fond` doit venir de sommier_fond_pci().", call. = FALSE)
  }
  if (!requireNamespace("sf", quietly = TRUE)) {
    stop("Le paquet `sf` est requis pour lire le PCI vecteur.", call. = FALSE)
  }
  couche <- valider_choix(couche, "couche", names(SOMMIER_COUCHES_PCI))
  marge_m <- valider_nombre(marge_m, "marge_m", min = 0)
  edigeo <- SOMMIER_COUCHES_PCI[[couche]]

  morceaux <- lapply(seq_len(nrow(fond$feuilles)), function(i) {
    thf <- fond$feuilles$thf[[i]]
    presentes <- sf::st_layers(thf)$name
    if (!edigeo %in% presentes) {
      return(NULL)
    }
    objets <- sf::read_sf(thf, layer = edigeo, quiet = TRUE)
    if (nrow(objets) == 0L) {
      return(NULL)
    }
    data.frame(
      feuille = fond$feuilles$feuille[[i]],
      objet = objets[["OBJECT_RID"]] %||% NA_character_,
      sym = as.character(objets[["SYM"]] %||% NA_character_),
      wkt = sf::st_as_text(poser_lambert93(sf::st_geometry(objets), thf)),
      stringsAsFactors = FALSE
    )
  })
  resultat <- do.call(rbind, morceaux[!vapply(morceaux, is.null, logical(1))])
  if (is.null(resultat)) {
    resultat <- data.frame(feuille = character(0), objet = character(0),
                           sym = character(0), wkt = character(0),
                           stringsAsFactors = FALSE)
  }

  if (!is.null(emprise) && nrow(resultat) > 0L && nrow(emprise) > 0L &&
      !is.null(emprise$wkt)) {
    boite <- sf::st_buffer(
      sf::st_as_sfc(sf::st_bbox(sf::st_as_sfc(emprise$wkt, crs = 2154))),
      marge_m
    )
    dedans <- sf::st_intersects(sf::st_as_sfc(resultat$wkt, crs = 2154),
                                boite, sparse = FALSE)[, 1L]
    resultat <- resultat[dedans, , drop = FALSE]
  }

  # `character(0)` et non `NA` quand rien ne subsiste : affecter une valeur
  # unique a un tableau vide echouerait, et une couche vide est un cas
  # ordinaire - une foret peut n'avoir aucune borne sur ses feuilles.
  resultat$nature <- appliquer_symboles(resultat, symboles)
  resultat <- resultat[, c("feuille", "objet", "sym", "nature", "wkt")]
  rownames(resultat) <- NULL
  attr(resultat, "source") <- fond$source
  attr(resultat, "couche") <- couche
  resultat
}

# ---------------------------------------------------------------------------

# Sans table fournie, la nature reste inconnue plutot qu'inventee : une
# correspondance plausible mais fausse ferait dire au document « fosse » la ou
# le terrain montre un mur.
#
# `character(0)` et non `NA` sur un tableau vide : affecter une valeur unique a
# zero ligne echouerait, et une couche vide est un cas ordinaire - une foret
# peut n'avoir aucune borne sur ses feuilles.
appliquer_symboles <- function(objets, symboles) {
  if (nrow(objets) == 0L) {
    return(character(0))
  }
  if (is.null(symboles)) {
    return(rep(NA_character_, nrow(objets)))
  }
  unname(symboles[objets$sym])
}

fichier_thf <- function(dossier) {
  trouves <- list.files(dossier, pattern = "\\.THF$", full.names = TRUE,
                        ignore.case = TRUE)
  if (length(trouves) == 0L) NA_character_ else trouves[[1L]]
}

# Le pilote EDIGEO rend un proj4 sans code EPSG. On ne pose le 2154 que si ce
# proj4 est bien du Lambert-93 : reprojeter au hasard poserait la feuille a
# cote de la foret sans que rien ne l'annonce.
poser_lambert93 <- function(geometrie, thf) {
  systeme <- sf::st_crs(geometrie)
  if (!is.na(systeme$epsg) && systeme$epsg == 2154L) {
    return(geometrie)
  }
  proj <- systeme$proj4string %||% ""
  if (!grepl(MOTIF_LAMBERT93, proj)) {
    stop("Feuille en projection inattendue (", thf, ") : ",
         if (nzchar(proj)) proj else "systeme absent",
         ".\nLes livraisons `edigeo-cc` sont en coniques conformes par zone ",
         "et ne sont pas du Lambert-93 ; les reprojeter au hasard poserait ",
         "la feuille a cote de la foret.", call. = FALSE)
  }
  # `st_set_crs()` avertit qu'il ne reprojette pas : c'est bien ce qu'on veut,
  # la donnee est deja en Lambert-93 et il lui manque seulement son etiquette.
  suppressWarnings(sf::st_set_crs(geometrie, 2154))
}
