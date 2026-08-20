#' Types de geometrie admis dans un payload
#'
#' @description
#' Les trois types GeoJSON que le sommier accepte : un point, une ligne, un
#' polygone. Ni collection ni multi-partie — un constat porte sur un objet, et
#' regrouper plusieurs objets dans une entree ferait perdre a chacun sa date
#' et son auteur.
#'
#' @export
SOMMIER_TYPES_GEOMETRIE <- c("Point", "LineString", "Polygon")

#' Nombre de decimales conservees sur une coordonnee
#'
#' @description
#' Sept decimales de degre valent environ un centimetre. Aucun instrument de
#' terrain forestier ne fait mieux, et deux saisies du meme point doivent
#' produire les memes octets pour que le chainage reste reproductible.
#'
#' @details
#' Arrondir n'est pas simplifier : on ne retire pas de sommets, on cesse
#' d'afficher une precision que la mesure n'a pas. Simplifier un contour,
#' lui, falsifierait un constat et n'est fait nulle part.
#'
#' @export
SOMMIER_DECIMALES_COORD <- 7L

#' Geometries d'un payload
#'
#' @description
#' Construisent la geometrie GeoJSON qu'une entree de sommier peut porter :
#' `geom_point()` pour une borne, un arbre ou un equipement, `geom_ligne()`
#' pour une voirie ou un fosse, `geom_polygone()` pour une emprise de coupe,
#' un habitat ou un phenomene.
#'
#' @details
#' **La geometrie est dans le payload, donc dans l'empreinte.** Elle n'est pas
#' une commodite d'affichage rangee a cote du registre : c'est un constat date
#' et chaine au meme titre qu'un volume ou un montant, et le contour d'une
#' coupe devient aussi opposable que son volume.
#'
#' Deux consequences de ce choix. Les coordonnees sont en **WGS84
#' (EPSG:4326)**, comme l'exige la RFC 7946 : un payload doit s'interpreter
#' sans contexte exterieur, et une coordonnee Lambert-93 nue n'aurait de sens
#' que pour qui connait la convention du producteur. Elles sont arrondies a
#' [SOMMIER_DECIMALES_COORD] decimales, pour que deux saisies du meme contour
#' donnent les memes octets - sans quoi le chainage cesserait d'etre
#' reproductible.
#'
#' Une longitude hors de \[-180, 180\] ou une latitude hors de \[-90, 90\] est
#' refusee, avec la mention du cas le plus probable : des coordonnees
#' projetees passees telles quelles.
#'
#' @param lon,lat Longitude et latitude en degres decimaux (WGS84).
#' @param coords Sommets : matrice ou `data.frame` a deux colonnes
#'   (longitude, latitude), ou liste de couples.
#' @param fermer Fermer l'anneau si le dernier sommet ne repete pas le
#'   premier (defaut `TRUE`). Un anneau non ferme n'est pas un polygone ; le
#'   refermer est une convention de saisie, pas une correction de mesure.
#'
#' @return Une liste nommee `type` / `coordinates`, prete a etre passee en
#'   `geometrie` a un constructeur de payload.
#'
#' @examples
#' geom_point(4.951, 47.271)
#'
#' geom_ligne(rbind(c(4.950, 47.270), c(4.952, 47.271)))
#'
#' geom_polygone(rbind(
#'   c(4.950, 47.270), c(4.952, 47.270), c(4.952, 47.272), c(4.950, 47.272)
#' ))
#'
#' @name geometries
NULL

#' @rdname geometries
#' @export
geom_point <- function(lon, lat) {
  list(
    type = "Point",
    coordinates = couple(valider_nombre(lon, "lon"), valider_nombre(lat, "lat"))
  )
}

#' @rdname geometries
#' @export
geom_ligne <- function(coords) {
  sommets <- normaliser_sommets(coords, "coords", minimum = 2L)
  list(type = "LineString", coordinates = sommets)
}

#' @rdname geometries
#' @export
geom_polygone <- function(coords, fermer = TRUE) {
  sommets <- normaliser_sommets(coords, "coords", minimum = 3L)
  sommets <- fermer_anneau(sommets, fermer)
  list(type = "Polygon", coordinates = list(sommets))
}

# ---------------------------------------------------------------------------
# Validation, appelee par les constructeurs de payload.
# ---------------------------------------------------------------------------

#' Valide une geometrie de payload
#'
#' @description
#' Verifie qu'une geometrie est d'un type admis, correctement formee, et en
#' coordonnees geographiques. Rend la forme canonique.
#'
#' @details
#' La normalisation n'est pas cosmetique. Un payload relu depuis la base ou
#' depuis un manifeste revient avec ses coordonnees en matrice et non en liste
#' de couples, parce que c'est ainsi que `jsonlite` simplifie un tableau de
#' tableaux. Serialisees telles quelles, les deux formes ne donneraient pas
#' les memes octets, et l'empreinte recalculee ne retomberait pas sur celle du
#' registre. Toute geometrie repasse donc par la meme mise en forme, a
#' l'ecriture comme a la relecture.
#'
#' @param geometrie Geometrie a valider.
#' @param types Types admis pour ce type d'objet.
#' @param nom Nom de l'argument, pour les messages.
#' @return La geometrie canonique.
#' @keywords internal
#' @export
valider_geometrie <- function(geometrie, types = SOMMIER_TYPES_GEOMETRIE,
                              nom = "geometrie") {
  if (!is.list(geometrie) || is.null(geometrie$type)) {
    stop("`", nom, "` doit etre une geometrie GeoJSON : une liste `type` / ",
         "`coordinates`, telle que la rendent geom_point(), geom_ligne() ou ",
         "geom_polygone().", call. = FALSE)
  }
  type <- valider_choix(geometrie$type, paste0(nom, "$type"), types)
  coords <- geometrie$coordinates

  canonique <- switch(
    type,
    "Point" = {
      paire <- as.numeric(unlist(coords, use.names = FALSE))
      if (length(paire) != 2L) {
        stop("`", nom, "` de type Point attend un couple longitude/latitude.",
             call. = FALSE)
      }
      couple(paire[[1L]], paire[[2L]])
    },
    "LineString" = normaliser_sommets(coords, nom, minimum = 2L),
    "Polygon" = {
      anneaux <- anneaux_de(coords)
      if (length(anneaux) != 1L) {
        stop("`", nom, "` : un seul anneau est admis. Un polygone a trou se ",
             "decrit mal dans un registre ou chaque entree porte un constat ",
             "unique.", call. = FALSE)
      }
      list(fermer_anneau(normaliser_sommets(anneaux[[1L]], nom, minimum = 3L),
                         fermer = FALSE))
    }
  )

  list(type = type, coordinates = canonique)
}

# Un couple de coordonnees, arrondi et verifie.
couple <- function(lon, lat) {
  lon <- valider_nombre(lon, "longitude", min = -180, max = 180)
  lat <- valider_nombre(lat, "latitude", min = -90, max = 90)
  c(arrondir_coord(lon), arrondir_coord(lat))
}

arrondir_coord <- function(x) round(x, SOMMIER_DECIMALES_COORD)

# Accepte matrice, data.frame ou liste de couples ; rend une liste de couples.
normaliser_sommets <- function(coords, nom, minimum) {
  if (is.data.frame(coords)) {
    coords <- as.matrix(coords)
  }
  lignes <- if (is.matrix(coords)) {
    if (ncol(coords) != 2L) {
      stop("`", nom, "` doit avoir deux colonnes (longitude, latitude), ",
           "recu : ", ncol(coords), ".", call. = FALSE)
    }
    lapply(seq_len(nrow(coords)), function(i) as.numeric(coords[i, ]))
  } else if (is.list(coords)) {
    lapply(coords, function(p) as.numeric(unlist(p, use.names = FALSE)))
  } else {
    stop("`", nom, "` doit etre une matrice, un data.frame ou une liste de ",
         "couples.", call. = FALSE)
  }

  if (length(lignes) < minimum) {
    stop("`", nom, "` demande au moins ", minimum, " sommets, recu : ",
         length(lignes), ".", call. = FALSE)
  }
  lapply(lignes, function(p) {
    if (length(p) != 2L) {
      stop("`", nom, "` : chaque sommet est un couple longitude/latitude.",
           call. = FALSE)
    }
    couple(p[[1L]], p[[2L]])
  })
}

# Rend la liste des anneaux d'un polygone, quelle que soit la forme recue.
#
# Les trois formes viennent du meme JSON lu differemment : `jsonlite` simplifie
# `[[[x,y],...]]` en tableau a trois dimensions, la construction directe donne
# une liste d'anneaux, et un anneau seul arrive en matrice. Les distinguer ici
# evite de les distinguer partout ailleurs.
anneaux_de <- function(coords) {
  if (is.array(coords) && length(dim(coords)) == 3L) {
    return(lapply(seq_len(dim(coords)[[1L]]),
                  function(i) matrix(coords[i, , ], ncol = 2L)))
  }
  if (is.matrix(coords) || is.data.frame(coords)) {
    return(list(coords))
  }
  if (!is.list(coords) || length(coords) == 0L) {
    return(list(coords))
  }
  premier <- coords[[1L]]
  # Un anneau unique commence par un couple de nombres ; une liste d'anneaux
  # commence par une liste de couples.
  if (is.numeric(premier) && length(premier) == 2L) list(coords) else coords
}

fermer_anneau <- function(sommets, fermer) {
  n <- length(sommets)
  ferme <- isTRUE(all.equal(sommets[[1L]], sommets[[n]]))
  if (ferme) {
    return(sommets)
  }
  if (!fermer) {
    stop("Anneau non ferme : le dernier sommet doit repeter le premier.",
         call. = FALSE)
  }
  c(sommets, sommets[1L])
}

# Raccourci des constructeurs de payload : geometrie facultative, validee
# quant au type admis pour l'objet.
geometrie_si_presente <- function(geometrie, types) {
  if (est_vide(geometrie)) NULL else valider_geometrie(geometrie, types)
}
