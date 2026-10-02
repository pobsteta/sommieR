#' Codes des travaux sylvicoles
#'
#' @description
#' La nomenclature fermee des travaux du registre 6 : le code qu'on agrege, a
#' cote du libelle libre de l'A50J. Chaque code fixe sa famille, l'unite de sa
#' quantite et la forme de sa geometrie (`point`, `ligne` ou `surface`).
#'
#' @format Un `data.frame` : `code`, `famille`, `libelle`, `unite`, `forme`.
#'
#' @seealso [registre6_travaux()]
#'
#' @export
SOMMIER_CODES_TRAVAUX <- data.frame(
  code = c("PS", "PL", "RG", "PA", "PG", "PI", "DG", "DS", "BI", "CL", "NT",
           "DE", "TF", "EL", "RN"),
  famille = c(
    "plantation", "plantation", "plantation", "plantation",
    "protection", "protection",
    "entretien", "entretien", "entretien", "entretien",
    "amelioration", "amelioration", "amelioration", "amelioration",
    "regeneration"
  ),
  libelle = c(
    "Pr\u00e9paration du sol", "Plantation", "Regarni", "Paillage",
    "Protection contre le gibier (cl\u00f4ture)", "Protection individuelle",
    "D\u00e9gagement", "D\u00e9broussaillement", "Broyage en interbande",
    "Cloisonnement", "Nettoiement", "D\u00e9pressage",
    "Taille de formation", "\u00c9lagage",
    "Travaux de r\u00e9g\u00e9n\u00e9ration naturelle"
  ),
  unite = c("ha", "ha", "plants", "ha", "ml", "u", "ha", "ha", "ha", "km",
            "ha", "ha", "ha", "ha", "ha"),
  forme = c("surface", "surface", "point", "surface", "ligne", "surface",
            "surface", "surface", "surface", "ligne", "surface", "surface",
            "surface", "surface", "surface"),
  stringsAsFactors = FALSE
)

#' Modes d'execution des travaux
#' @export
SOMMIER_EXECUTIONS_TRAVAUX <- c("regie", "entreprise", "autre")

#' Travaux prevus, reportes ou non prevus
#'
#' @description
#' Constate a la reception : `prevu` (au document de gestion), `reporte`
#' (prevu un autre exercice), `non_prevu`. Hors `prevu`, un motif est exige.
#'
#' @export
SOMMIER_PREVUS_TRAVAUX <- c("prevu", "reporte", "non_prevu")

#' Niveaux de concurrence d'une plantation
#' @export
SOMMIER_CONCURRENCES <- c("faible", "moyenne", "forte")

#' Types d'entree du registre 6
#'
#' @description
#' * `travaux` : une intervention (A50J, A50H) ; le type est implicite, une
#'   entree sans `type_entree` en est une.
#' * `placette` : une placette permanente de suivi d'une plantation ou d'une
#'   regeneration.
#' * `controle` : un passage sur une placette.
#'
#' @export
SOMMIER_TYPES_TRAVAUX <- c("travaux", "placette", "controle")

#' Payload du registre 6 - placette de suivi
#'
#' @description
#' Une placette permanente installee pour suivre une plantation ou une
#' regeneration. Ses passages s'inscrivent ensuite en [registre6_controle()],
#' qui y renvoient : c'est le couple detection et suite du registre 8.
#'
#' @param code_placette Code lisible, unique dans l'unite ("P35-03").
#' @param travaux_id UUID de l'intervention suivie (une plantation, une
#'   regeneration).
#' @param geometrie Le centre de la placette, un point en WGS84 (voir
#'   [geom_point()]).
#' @param rayon_m Rayon, en metres : 3,99 m font 50 m2.
#' @param materialisation Comment la placette se retrouve (piquet,
#'   peinture...).
#' @param precision_m,source_gnss Precision et source de la position.
#' @param observations Observations libres.
#'
#' @return Une liste nommee, prete a etre passee a [sommier_entree()].
#'
#' @seealso [sommier_installer_placette()]
#'
#' @export
registre6_placette <- function(code_placette, travaux_id, geometrie,
                               rayon_m = 3.99, materialisation = NULL,
                               precision_m = NULL, source_gnss = NULL,
                               observations = NULL) {
  if (est_vide(geometrie)) {
    stop("Une placette se retrouve par son centre : `geometrie` (un point) ",
         "est obligatoire.", call. = FALSE)
  }
  compacter(list(
    type_entree     = "placette",
    code_placette   = valider_texte(code_placette, "code_placette"),
    travaux_id      = valider_uuid(travaux_id, "travaux_id"),
    rayon_m         = valider_nombre(rayon_m, "rayon_m", min = 0.5, max = 50),
    materialisation = si_present(materialisation, valider_texte,
                                 "materialisation"),
    geometrie       = geometrie_si_presente(geometrie, "Point"),
    precision_m     = si_present(precision_m, valider_nombre, "precision_m",
                                 min = 0),
    source_gnss     = si_present(source_gnss, valider_texte, "source_gnss"),
    observations    = si_present(observations, valider_texte, "observations")
  ))
}

#' Payload du registre 6 - controle d'une placette
#'
#' @description
#' Un passage sur une placette : ce qu'on y compte. Le taux de reprise, la
#' densite a l'hectare et la part d'abroutis ne s'inscrivent pas : la vue
#' `v_controle_plantation` les calcule, et l'age de la plantation se deduit de
#' l'annee des travaux suivis.
#'
#' @param placette_id UUID de la placette controlee.
#' @param nb_total,nb_vivants Plants comptes, et vivants parmi eux.
#' @param h_moy_cm Hauteur moyenne des tiges objectif, en cm.
#' @param nb_abroutis Plants vivants abroutis.
#' @param concurrence L'un de [SOMMIER_CONCURRENCES].
#' @param besoin Le travail qui s'impose ensuite : un code de
#'   [SOMMIER_CODES_TRAVAUX], ou `"aucun"`.
#' @param operateur Agent qui a controle.
#' @param visite_le Instant du controle.
#' @param releve_uuid Identifiant du releve de terrain.
#' @param photos Photos, par leur empreinte.
#' @param observations Observations libres.
#'
#' @return Une liste nommee, prete a etre passee a [sommier_entree()].
#'
#' @seealso [sommier_controler_placette()]
#'
#' @export
registre6_controle <- function(placette_id, nb_total, nb_vivants,
                               h_moy_cm = NULL, nb_abroutis = NULL,
                               concurrence = NULL, besoin = NULL,
                               operateur = NULL, visite_le = NULL,
                               releve_uuid = NULL, photos = NULL,
                               observations = NULL) {
  nb_total <- valider_entier(nb_total, "nb_total", min = 0)
  nb_vivants <- valider_entier(nb_vivants, "nb_vivants", min = 0)
  if (nb_vivants > nb_total) {
    stop("Plus de plants vivants (", nb_vivants, ") que de plants comptes (",
         nb_total, ").", call. = FALSE)
  }
  nb_abroutis <- si_present(nb_abroutis, valider_entier, "nb_abroutis",
                            min = 0)
  if (!is.null(nb_abroutis) && nb_abroutis > nb_vivants) {
    stop("Plus de plants abroutis (", nb_abroutis, ") que de vivants (",
         nb_vivants, ") : un abroutissement se compte sur les vivants.",
         call. = FALSE)
  }
  compacter(list(
    type_entree = "controle",
    placette_id = valider_uuid(placette_id, "placette_id"),
    nb_total    = nb_total,
    nb_vivants  = nb_vivants,
    h_moy_cm    = si_present(h_moy_cm, valider_entier, "h_moy_cm", min = 0),
    nb_abroutis = nb_abroutis,
    concurrence = si_present(concurrence, valider_choix, "concurrence",
                             SOMMIER_CONCURRENCES),
    besoin      = si_present(besoin, valider_choix, "besoin",
                             c(SOMMIER_CODES_TRAVAUX$code, "aucun")),
    operateur   = si_present(operateur, valider_texte, "operateur"),
    visite_le   = si_present(visite_le, format_instant, "visite_le"),
    releve_uuid = si_present(releve_uuid, valider_uuid, "releve_uuid"),
    photos      = valider_photos(photos),
    observations = si_present(observations, valider_texte, "observations")
  ))
}

#' Relecture d'un payload du registre 6
#'
#' @description
#' Rappelle le constructeur du type que le payload declare. Un payload sans
#' `type_entree` est une intervention : c'est le cas de toutes celles inscrites
#' avant la v0.28.0.
#'
#' @param payload Payload relu (liste nommee).
#'
#' @return Le payload revalide.
#'
#' @export
registre6_depuis_payload <- function(payload) {
  if (!is.list(payload) || is.null(names(payload))) {
    stop("`payload` doit etre une liste nommee.", call. = FALSE)
  }
  type <- if (est_vide(payload$type_entree)) "travaux" else
    valider_choix(payload$type_entree, "type_entree", SOMMIER_TYPES_TRAVAUX)
  arguments <- payload
  if (type != "travaux") {
    arguments$type_entree <- NULL
  }
  do.call(switch(
    type,
    travaux  = registre6_travaux,
    placette = registre6_placette,
    controle = registre6_controle
  ), arguments)
}

# La forme d'un code, en types GeoJSON.
FORMES_GEOJSON <- list(
  point = "Point", ligne = "LineString", surface = "Polygon"
)
