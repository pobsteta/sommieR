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

#' Projections declarees par les lots EDIGEO
#'
#' @description
#' Correspondance entre le code de reference porte par le fichier `.GEO` d'une
#' archive EDIGEO et le code EPSG de la projection.
#'
#' @details
#' EDIGEO est auto-descripteur : le lot declare son referentiel dans son
#' fichier `.GEO`, sous la forme `RELSA06:LAMB93` pour la metropole. On le lit
#' donc plutot que de reconnaitre une chaine proj4 - la declaration est
#' l'intention du producteur, le proj4 n'en est qu'une traduction par le
#' pilote, et elle arrive sans code EPSG.
#'
#' Les livraisons `edigeo-cc` declarent une conique conforme par zone, de CC42
#' a CC50, soit les codes EPSG 3942 a 3950.
#'
#' @export
SOMMIER_PROJECTIONS_EDIGEO <- c(
  LAMB93 = 2154L,
  CC42 = 3942L, CC43 = 3943L, CC44 = 3944L, CC45 = 3945L, CC46 = 3946L,
  CC47 = 3947L, CC48 = 3948L, CC49 = 3949L, CC50 = 3950L
)

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
    couche <- couche[sf::st_intersects(couche, boite_emprise(emprise, marge_m),
                                       sparse = FALSE)[, 1L], , drop = FALSE]
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
#' Le systeme de coordonnees vient de la **declaration du lot**. EDIGEO est
#' auto-descripteur : le fichier `.GEO` porte le referentiel employe
#' (`LAMB93` pour la metropole, `CC42` a `CC50` pour les livraisons
#' `edigeo-cc`). Le pilote de GDAL, lui, rend un proj4 sans code EPSG. On lit
#' donc la declaration a la source, et la sortie est ramenee en Lambert-93 quel
#' que soit le lot. Un referentiel non reconnu est signale plutot que
#' reinterprete - reprojeter au hasard poserait la feuille a cote de la foret.
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
      wkt = sf::st_as_text(poser_projection(sf::st_geometry(objets), thf)),
      stringsAsFactors = FALSE
    )
  })
  resultat <- assembler_objets(morceaux)
  resultat <- restreindre_emprise(resultat, emprise, marge_m)
  resultat$nature <- appliquer_symboles(resultat, symboles)
  resultat <- resultat[, c("feuille", "objet", "sym", "nature", "wkt")]
  rownames(resultat) <- NULL
  attr(resultat, "source") <- fond$source
  attr(resultat, "couche") <- couche
  resultat
}

# ---------------------------------------------------------------------------

# Une feuille peut ne porter aucun objet de la couche demandee, et toutes
# peuvent etre vides : le tableau vide doit alors avoir les memes colonnes que
# le tableau plein, sinon l'appelant aurait deux formes a traiter.
assembler_objets <- function(morceaux) {
  garde <- morceaux[!vapply(morceaux, is.null, logical(1))]
  if (length(garde) == 0L) {
    return(data.frame(feuille = character(0), objet = character(0),
                      sym = character(0), wkt = character(0),
                      stringsAsFactors = FALSE))
  }
  do.call(rbind, garde)
}

# Restreint un tableau a colonne `wkt` a l'emprise tamponnee d'un autre. La
# regle sert au parcellaire, aux feuilles et aux objets PCI : trois endroits ou
# la meme boite se calculait, donc trois occasions de diverger.
restreindre_emprise <- function(objets, emprise, marge_m) {
  if (is.null(emprise) || nrow(objets) == 0L || nrow(emprise) == 0L ||
      is.null(emprise$wkt)) {
    return(objets)
  }
  dedans <- sf::st_intersects(sf::st_as_sfc(objets$wkt, crs = 2154),
                              boite_emprise(emprise, marge_m),
                              sparse = FALSE)[, 1L]
  objets[dedans, , drop = FALSE]
}

# La boite englobante tamponnee, et non le contour exact : une foret collee au
# bord de sa carte se lit mal, et decouper au contour retirerait les objets qui
# la bordent - ceux-la interessent justement le gestionnaire.
boite_emprise <- function(emprise, marge_m) {
  sf::st_buffer(
    sf::st_as_sfc(sf::st_bbox(sf::st_as_sfc(emprise$wkt, crs = 2154))),
    marge_m
  )
}

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

# EDIGEO declare son referentiel dans le fichier `.GEO` du lot, a cote du
# `.THF`. Le pilote de GDAL construit bien les couches et leurs champs a partir
# de ces fichiers de description, mais il rend un proj4 sans code EPSG : on lit
# donc la declaration a la source plutot que de reconnaitre une chaine.
projection_declaree <- function(thf) {
  geo <- list.files(dirname(thf), pattern = "\\.GEO$", full.names = TRUE,
                    ignore.case = TRUE)
  if (length(geo) == 0L) {
    return(NA_character_)
  }
  lignes <- readLines(geo[[1L]], warn = FALSE)
  declaration <- grep("^REL[A-Z]{2}[0-9]{2}:", lignes, value = TRUE)
  if (length(declaration) == 0L) {
    return(NA_character_)
  }
  trimws(sub("^REL[A-Z]{2}[0-9]{2}:", "", declaration[[1L]]))
}

# La geometrie arrive sans code EPSG : on pose celui que le lot declare.
# Reprojeter au hasard poserait la feuille a cote de la foret sans que rien ne
# l'annonce - c'est le defaut du GeoJSON en Lambert-93 corrige en v0.6.0.
poser_projection <- function(geometrie, thf) {
  systeme <- sf::st_crs(geometrie)
  if (!is.na(systeme$epsg)) {
    return(geometrie)
  }
  code <- projection_declaree(thf)
  if (is.na(code) || !code %in% names(SOMMIER_PROJECTIONS_EDIGEO)) {
    stop("Projection non reconnue pour la feuille ", basename(thf), " : ",
         if (is.na(code)) "aucune declaration dans le fichier .GEO du lot"
         else paste0("referentiel declare `", code, "`"),
         ".\nProjections connues : ",
         paste(names(SOMMIER_PROJECTIONS_EDIGEO), collapse = ", "), ".",
         call. = FALSE)
  }
  # `st_set_crs()` avertit qu'il ne reprojette pas : c'est bien ce qu'on veut,
  # la donnee est deja dans cette projection, il lui manque son etiquette.
  epsg <- SOMMIER_PROJECTIONS_EDIGEO[[code]]
  geometrie <- suppressWarnings(sf::st_set_crs(geometrie, epsg))
  if (epsg == 2154L) geometrie else sf::st_transform(geometrie, 2154)
}
