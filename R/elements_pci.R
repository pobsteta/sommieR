#' Elements du plan cadastral retenus pour le suivi des limites
#'
#' @description
#' Les categories d'elements physiques que [sommier_elements_pci()] va
#' chercher dans le PCI vecteur, avec le prefixe de leur numero court.
#'
#' @details
#' Ne sont retenues que les couches qui materialisent quelque chose sur le
#' terrain. `PARCELLE`, `SECTION`, `SUBDSECT`, `SUBDFISC`, `COMMUNE`, `LIEUDIT`
#' et `NUMVOIE` decoupent ou nomment le territoire sans rien poser au sol ; la
#' couche `ID_S_OBJ_Z_1_2_2` ne porte que la position des etiquettes des
#' numeros de parcelle. On les ecarte.
#'
#' L'ordre des lignes est celui des tableaux du rapport : les bornes et les
#' signes de limite d'abord, qui disent la limite elle-meme, puis les details
#' qui la jalonnent.
#'
#' @export
SOMMIER_ELEMENTS_PCI <- data.frame(
  couche = c("bornes", "signes", "points", "details", "surfaces",
             "cours_eau", "voies", "routes", "batiments"),
  categorie = c("borne", "signe de limite", "détail ponctuel",
                "détail linéaire", "détail surfacique",
                "cours d'eau", "voie", "tronçon de route",
                "bâtiment"),
  prefixe = c("B", "S", "P", "L", "T", "E", "V", "R", "H"),
  stringsAsFactors = FALSE
)

#' Elements du plan cadastral dans la foret et a ses abords
#'
#' @description
#' Rassemble tous les elements physiques du PCI vecteur - bornes, signes de
#' limite, details topographiques, cours d'eau, voies, batiments - qui
#' touchent la foret elargie de `tampon_m` metres, les situe, cite le texte
#' que le plan leur attache, et les numerote.
#'
#' @details
#' **La selection se fait au tampon, sans autre filtre.** Est retenu tout
#' element qui touche l'union des contours des unites, elargie de `tampon_m`.
#' Le tampon capte les bornes et les murs de la limite, que deux dessins
#' superposent rarement au metre, et les elements du riverain immediat.
#'
#' **La situation se calcule, elle ne s'enregistre pas.** `situation` vaut
#' `"foret"` si l'element touche l'union des unites, `"tampon"` sinon, et
#' `distance_limite_m` donne sa distance au contour de cette union. C'est une
#' lecture du plan, comme les tenements du rapport. La distance compte plus
#' que la situation : une borne posee sur la limite cadastrale tombe souvent
#' a quelques metres hors d'unites dessinees a une autre main.
#'
#' **La nature vient de la couche ou d'une table fournie, jamais du texte.**
#' Pour une borne, un cours d'eau, une voie ou un batiment, la couche suffit a
#' dire ce qu'est l'objet (`nature_source = "couche"`). Pour un detail
#' ponctuel, lineaire ou surfacique, seul le code `SYM` le distingue, et sa
#' nomenclature n'est pas dans l'archive : la table `symboles` fournie par
#' l'appelant le nomme (`"appelant"`), sinon `nature` reste `NA`.
#'
#' **Le texte du plan est cite, pas interprete.** `TEX` sur l'objet, ou une
#' etiquette des couches `*_LABEL` rattachee par `OGR_OBJ_LNK`, rend `texte`.
#' Il nomme parfois l'objet (« pylone telecom » sur un detail ponctuel de
#' Loury), et parfois seulement ce qui l'entoure : sur Couchey, les lignes de
#' code 19 portent « COMMUNE DE FLAVIGNEROT », le nom de la commune voisine le
#' long de la limite. En faire une nature ferait dire au document qu'une ligne
#' est une commune. Le texte reste donc a cote de la nature, cite tel quel.
#'
#' **Un nom morcele n'est pas recompose.** Le plan pose le nom d'une voie mot
#' par mot le long du trace, et l'ordre de ses attributs `TEX`, `TEX2`...
#' n'est pas celui de la lecture. `texte` reste alors `NA` et
#' `texte_morcele` vaut `TRUE` : recomposer serait inventer l'ordre.
#'
#' **Chaque element a un identifiant stable** : `feuille:OBJECT_RID`. Le
#' numero court (`B-001`, `P-001`...) suit l'ordre du cadastre - feuille, puis
#' position d'ouest en est et du sud au nord - et ne vaut que pour un
#' millesime ; l'identifiant vaut au-dela.
#'
#' Le PCI reste un decor : rien de ce qui est rendu ici n'entre dans un
#' registre, une empreinte ou un manifeste.
#'
#' @param fond Objet `sommier_fond_pci` ([sommier_fond_pci()]).
#' @param emprise Couche des unites de gestion ([sommier_couche_ug()]), ou
#'   `data.frame` a colonne `wkt` en Lambert-93. Obligatoire : sans contour,
#'   ni le tampon ni la situation n'ont de sens.
#' @param tampon_m Largeur du tampon autour de la foret, en metres.
#' @param symboles Vecteur nomme donnant la nature d'un code `SYM` des details,
#'   par exemple `c("21" = "mur")`. Il vous appartient : le paquet n'en
#'   embarque aucun tant qu'une source n'est pas citable.
#'
#' @return Un `data.frame` : `id`, `numero`, `categorie`, `couche`, `feuille`,
#'   `objet`, `sym`, `texte`, `texte_morcele`, `nature`, `nature_source`,
#'   `situation`,
#'   `distance_limite_m`, `orientation`, `cree_le`, `modifie_le`, `millesime`, `x`, `y` (point
#'   d'ancrage en Lambert-93) et `wkt`. Attributs `tampon_m` et `source`.
#'
#' @seealso [sommier_exporter_elements_pci()], [sommier_rapport_quarto()]
#'
#' @examples
#' # Necessite `sf`, un acces reseau et une connexion :
#' # ug <- sommier_couche_ug(con, foret)
#' # feuilles <- sommier_feuilles_pci("45188", emprise = ug)
#' # fond <- sommier_fond_pci("45188", feuilles$feuille)
#' # elements <- sommier_elements_pci(fond, ug)
#'
#' @export
sommier_elements_pci <- function(fond, emprise, tampon_m = 20,
                                 symboles = NULL) {
  if (!inherits(fond, "sommier_fond_pci")) {
    stop("`fond` doit venir de sommier_fond_pci().", call. = FALSE)
  }
  if (!requireNamespace("sf", quietly = TRUE)) {
    stop("Le paquet `sf` est requis pour lire le PCI vecteur.", call. = FALSE)
  }
  if (is.null(emprise) || !is.data.frame(emprise) || nrow(emprise) == 0L ||
      is.null(emprise$wkt)) {
    stop("`emprise` est obligatoire : sans contour de la foret, ni le tampon ",
         "ni la situation d'un element n'ont de sens.", call. = FALSE)
  }
  tampon_m <- valider_nombre(tampon_m, "tampon_m", min = 0)

  feuilles <- fond$feuilles
  if (is.null(feuilles$millesime)) {
    feuilles$millesime <- do.call(c, lapply(feuilles$thf, millesime_lot))
  }

  morceaux <- lapply(seq_len(nrow(feuilles)), function(i) {
    lire_elements_feuille(feuilles$thf[[i]], feuilles$feuille[[i]],
                          feuilles$millesime[[i]])
  })
  elements <- assembler_elements(morceaux)
  elements <- restreindre_emprise(elements, emprise, tampon_m)
  elements <- situer_elements(elements, emprise)
  elements <- nommer_elements(elements, symboles)
  elements <- numeroter_elements(elements)

  attr(elements, "tampon_m") <- tampon_m
  attr(elements, "source") <- fond$source
  elements
}

#' Export des elements du plan cadastral en GeoPackage
#'
#' @description
#' Ecrit les elements de [sommier_elements_pci()] dans un GeoPackage, une
#' couche par type de geometrie : `elements_points`, `elements_lignes`,
#' `elements_surfaces`.
#'
#' @details
#' Trois couches plutot qu'une : un GeoPackage admet une couche a geometrie
#' mixte, mais QGIS et QField la lisent mal - la symbologie, les etiquettes et
#' la saisie supposent un seul type. Les attributs sont ceux du tableau, en
#' Lambert-93. Le fichier est remplace s'il existe, comme les autres exports
#' SIG : c'est une lecture du plan, pas une ecriture.
#'
#' @param elements Tableau rendu par [sommier_elements_pci()].
#' @param chemin Fichier `.gpkg` de destination.
#'
#' @return Invisiblement, le nombre d'elements ecrits par couche.
#'
#' @examples
#' # sommier_exporter_elements_pci(elements, "elements-pci.gpkg")
#'
#' @export
sommier_exporter_elements_pci <- function(elements, chemin) {
  if (!requireNamespace("sf", quietly = TRUE)) {
    stop("Le paquet `sf` est requis pour ecrire un GeoPackage.", call. = FALSE)
  }
  if (!is.data.frame(elements) || is.null(elements$categorie) ||
      is.null(elements$wkt)) {
    stop("`elements` doit venir de sommier_elements_pci().", call. = FALSE)
  }
  chemin <- valider_texte(chemin, "chemin")
  if (!identical(tolower(tools::file_ext(chemin)), "gpkg")) {
    stop("`chemin` doit porter l'extension .gpkg.", call. = FALSE)
  }
  if (nrow(elements) == 0L) {
    stop("Aucun element a ecrire.", call. = FALSE)
  }

  geometries <- sf::st_as_sfc(elements$wkt, crs = 2154)
  dimension <- sf::st_dimension(geometries)
  couches <- c(elements_points = 0L, elements_lignes = 1L,
               elements_surfaces = 2L)
  attributs <- elements[, setdiff(names(elements), "wkt"), drop = FALSE]

  if (file.exists(chemin)) {
    unlink(chemin)
  }
  ecrits <- vapply(names(couches), function(nom) {
    garde <- which(dimension == couches[[nom]])
    if (length(garde) == 0L) {
      return(0L)
    }
    couche <- sf::st_sf(attributs[garde, , drop = FALSE],
                        geometry = geometries[garde])
    sf::st_write(couche, chemin, layer = nom, append = FALSE, quiet = TRUE)
    length(garde)
  }, integer(1))
  invisible(ecrits)
}

# ---------------------------------------------------------------------------

# Les colonnes d'un element, dans l'ordre ou le tableau les rend. Un tableau
# vide a les memes : l'appelant n'a qu'une forme a traiter.
COLONNES_ELEMENTS <- c("id", "numero", "categorie", "couche", "feuille",
                       "objet", "sym", "texte", "texte_morcele", "nature",
                       "nature_source",
                       "situation", "distance_limite_m", "orientation",
                       "cree_le", "modifie_le",
                       "millesime", "x", "y", "wkt")

lire_elements_feuille <- function(thf, feuille, millesime) {
  presentes <- sf::st_layers(thf)$name
  morceaux <- lapply(SOMMIER_ELEMENTS_PCI$couche, function(couche) {
    edigeo <- SOMMIER_COUCHES_PCI[[couche]]
    if (!edigeo %in% presentes) {
      return(NULL)
    }
    objets <- sf::read_sf(thf, layer = edigeo, quiet = TRUE)
    if (nrow(objets) == 0L) {
      return(NULL)
    }
    rid <- objets[["OBJECT_RID"]] %||% NA_character_
    lu <- textes_objets(sf::st_drop_geometry(objets))
    texte <- lu$texte
    morcele <- lu$morcele
    etiquettes <- paste0(edigeo, "_LABEL")
    if (any(is.na(texte) & !morcele) && etiquettes %in% presentes) {
      complete <- completer_par_etiquettes(
        texte, rid, sf::read_sf(thf, layer = etiquettes, quiet = TRUE)
      )
      morcele <- morcele | complete$morcele
      texte <- complete$texte
    }
    data.frame(
      couche = couche, feuille = feuille, objet = rid,
      sym = as.character(objets[["SYM"]] %||% NA_character_),
      texte = texte, texte_morcele = morcele,
      orientation = suppressWarnings(
        as.numeric(objets[["ORI"]] %||% NA_real_)
      ),
      cree_le = date_edigeo(objets[["CREAT_DATE"]]),
      modifie_le = date_edigeo(objets[["UPDATE_DATE"]]),
      millesime = millesime,
      wkt = wkt_plein(poser_projection(sf::st_geometry(objets), thf)),
      stringsAsFactors = FALSE
    )
  })
  garde <- morceaux[!vapply(morceaux, is.null, logical(1))]
  if (length(garde) == 0L) NULL else do.call(rbind, garde)
}

# Le texte d'un objet. Le plan pose le nom d'une voie ou d'un cours d'eau
# mot par mot le long du trace, un mot par attribut - `TEX`, `TEX2`... `TEX10`
# -, et l'ordre de ces attributs n'est pas celui de la lecture : « Route de la
# Vallee Jaune » arrive en `Jaune`, `de`, `la`, `Vallee`, `Route`. Rien dans
# les attributs ne dit l'ordre ; le recomposer serait l'inventer. Un texte
# d'un seul tenant est donc garde, et un texte morcele se dit tel, sans etre
# recompose. Plusieurs attributs portant le meme texte entier - le nom repete
# a chaque troncon - ne font qu'un texte.
textes_objets <- function(attributs) {
  colonnes <- grep("^TEX[0-9]*$", names(attributs), value = TRUE)
  if (length(colonnes) == 0L) {
    return(list(texte = rep(NA_character_, nrow(attributs)),
                morcele = rep(FALSE, nrow(attributs))))
  }
  valeurs <- lapply(seq_len(nrow(attributs)), function(i) {
    v <- texte_propre(unlist(attributs[i, colonnes, drop = TRUE],
                             use.names = FALSE))
    unique(v[!is.na(v)])
  })
  list(
    texte = vapply(valeurs, function(v) if (length(v) == 1L) v
                   else NA_character_, character(1)),
    morcele = vapply(valeurs, function(v) length(v) > 1L, logical(1))
  )
}

# Une etiquette se rattache a son objet par `OGR_OBJ_LNK`. Meme regle que sur
# l'objet : un texte unique est garde, plusieurs mots poses separement ne se
# recomposent pas.
completer_par_etiquettes <- function(texte, rid, etiquettes) {
  lien <- etiquettes[["OGR_OBJ_LNK"]]
  valeur <- texte_propre(etiquettes[["OGR_ATR_VAL"]])
  morcele <- rep(FALSE, length(texte))
  if (is.null(lien) || is.null(valeur)) {
    return(list(texte = texte, morcele = morcele))
  }
  for (i in which(is.na(texte))) {
    trouves <- unique(valeur[lien == rid[[i]] & !is.na(valeur)])
    if (length(trouves) == 1L) {
      texte[[i]] <- trouves
    } else if (length(trouves) > 1L) {
      morcele[[i]] <- TRUE
    }
  }
  list(texte = texte, morcele = morcele)
}

# Un texte fait de blancs n'en est pas un : le cadastre en laisse sur des
# objets sans nom.
texte_propre <- function(x) {
  x <- trimws(as.character(x))
  x[!is.na(x) & !nzchar(x)] <- NA_character_
  x
}

date_edigeo <- function(x) {
  if (is.null(x)) {
    return(as.Date(NA))
  }
  as.Date(as.character(x), format = "%Y%m%d")
}

assembler_elements <- function(morceaux) {
  garde <- morceaux[!vapply(morceaux, is.null, logical(1))]
  if (length(garde) == 0L) {
    vide <- as.data.frame(
      stats::setNames(replicate(length(COLONNES_ELEMENTS), character(0),
                                simplify = FALSE), COLONNES_ELEMENTS),
      stringsAsFactors = FALSE
    )
    return(vide)
  }
  do.call(rbind, garde)
}

# « foret » si l'element touche l'union des unites, « tampon » sinon. L'union
# a tampon nul est l'union elle-meme : la meme fonction sert aux deux regles.
#
# La situation seule tromperait : a Loury, 64 des 68 bornes retenues tombent
# « dans le tampon », a 8 m du contour en mediane. Elles sont sur la limite
# cadastrale ; ce sont les unites, dessinees a une autre main, qui ne la
# suivent pas au metre. La distance au contour de l'union est donc rendue a
# cote : elle mesure, la ou la situation classe.
situer_elements <- function(elements, emprise) {
  if (nrow(elements) == 0L) {
    elements$situation <- character(0)
    elements$distance_limite_m <- numeric(0)
    return(elements)
  }
  formes <- sf::st_as_sfc(elements$wkt, crs = 2154)
  union <- emprise_tamponnee(emprise, 0)
  dans_foret <- sf::st_intersects(formes, union, sparse = FALSE)[, 1L]
  elements$situation <- ifelse(dans_foret, "foret", "tampon")
  elements$distance_limite_m <- round(as.numeric(
    sf::st_distance(formes, sf::st_boundary(union))[, 1L]
  ), 1L)
  elements
}

nommer_elements <- function(elements, symboles) {
  n <- nrow(elements)
  elements$categorie <- SOMMIER_ELEMENTS_PCI$categorie[
    match(elements$couche, SOMMIER_ELEMENTS_PCI$couche)
  ]
  if (n == 0L) {
    elements$nature <- character(0)
    elements$nature_source <- character(0)
    return(elements)
  }
  details <- elements$couche %in% c("points", "details", "surfaces")
  table <- if (is.null(symboles)) {
    rep(NA_character_, n)
  } else {
    unname(symboles[elements$sym])
  }

  nature <- ifelse(details, NA_character_, elements$categorie)
  source <- ifelse(details, NA_character_, "couche")
  par_table <- details & !is.na(table)
  nature[par_table] <- table[par_table]
  source[par_table] <- "appelant"

  elements$nature <- nature
  elements$nature_source <- source
  elements
}

# L'ordre du cadastre : categorie, feuille, puis position d'ouest en est et du
# sud au nord. Le point d'ancrage d'une ligne ou d'une surface est un point qui
# lui appartient (`st_point_on_surface`), non son centroide, qui peut tomber
# hors d'un fosse coude ou d'un batiment en L.
numeroter_elements <- function(elements) {
  if (nrow(elements) == 0L) {
    elements$id <- character(0)
    elements$numero <- character(0)
    elements$x <- numeric(0)
    elements$y <- numeric(0)
    return(elements[, COLONNES_ELEMENTS, drop = FALSE])
  }
  ancres <- sf::st_coordinates(
    suppressWarnings(sf::st_point_on_surface(
      sf::st_as_sfc(elements$wkt, crs = 2154)
    ))
  )
  elements$x <- round(ancres[, 1L], 2L)
  elements$y <- round(ancres[, 2L], 2L)
  rang_categorie <- match(elements$couche, SOMMIER_ELEMENTS_PCI$couche)
  elements <- elements[order(rang_categorie, elements$feuille, elements$x,
                             elements$y, elements$objet), , drop = FALSE]

  prefixe <- SOMMIER_ELEMENTS_PCI$prefixe[
    match(elements$couche, SOMMIER_ELEMENTS_PCI$couche)
  ]
  rang <- stats::ave(seq_along(prefixe), prefixe, FUN = seq_along)
  elements$numero <- sprintf("%s-%03d", prefixe, rang)
  elements$id <- paste0(elements$feuille, ":", elements$objet)
  rownames(elements) <- NULL
  elements[, COLONNES_ELEMENTS, drop = FALSE]
}
