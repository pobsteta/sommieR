#' Codes des travaux sylvicoles
#'
#' @description
#' La nomenclature fermee des travaux du registre 6, celle du brief metier du
#' suivi sylvicole : le code qu'on agrege, a cote du libelle libre de l'A50J.
#' Chaque code fixe sa famille, les unites admises pour sa quantite et les
#' formes admises pour sa geometrie (`point`, `ligne`, `surface`). Une
#' plantation se mesure en hectares, ses plants dans `nb_plants`.
#'
#' @format Un `data.frame` : `code`, `famille`, `libelle`, `unites` et
#'   `formes` (une ou plusieurs valeurs, separees par une virgule).
#'
#' @seealso [registre6_travaux()]
#'
#' @export
SOMMIER_CODES_TRAVAUX <- data.frame(
  code = c("PS", "PL", "RG", "PG", "PI", "DG", "CL", "NT", "TF", "EL", "DE",
           "RN", "BI", "DS", "PA"),
  famille = c("preparation", "plantation", "plantation", "protection",
              "protection", "education", "education", "education",
              "education", "education", "education", "regeneration",
              "biodiversite", "desserte", "parcellaire"),
  libelle = c(
    "Pr\u00e9paration du sol (broyage, andainage, crochetage, potets)",
    "Plantation en plein, placeaux, enrichissement",
    "Regarnis, compl\u00e9ments",
    "Cl\u00f4ture",
    "Protections individuelles, r\u00e9pulsifs",
    "D\u00e9gagement (manuel, m\u00e9canique)",
    "Cloisonnement sylvicole (ouverture, entretien)",
    "Nettoiement, d\u00e9pressage",
    "Taille de formation",
    "\u00c9lagage",
    "D\u00e9signation d'arbres objectif",
    "Travaux en r\u00e9g\u00e9n\u00e9ration naturelle (d\u00e9gagement de semis, crochetage localis\u00e9)",
    "\u00celots, arbres habitat, mares, lisi\u00e8res",
    "Entretien de piste, foss\u00e9s, places de d\u00e9p\u00f4t",
    "Entretien des limites (peinture, bornes)"
  ),
  unites = c("ha", "ha", "plants", "m", "nb", "ha", "m, ha", "ha", "tiges",
             "tiges", "tiges", "ha", "ha, nb", "m", "m"),
  formes = c("surface", "surface", "surface, point", "ligne", "surface",
             "surface", "ligne", "surface", "surface", "surface",
             "surface, point", "surface", "surface, point", "ligne",
             "ligne"),
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
#'
#' @description
#' Les trois niveaux admis, dans l'ordre croissant. Leur definition de terrain
#' (critere, seuils, nature, valeur manquante) est dans
#' [SOMMIER_DEFINITIONS_CONCURRENCE] ; la regle de passage du plant a la
#' placette, dans [sommier_niveau_concurrence()].
#'
#' @export
SOMMIER_CONCURRENCES <- c("faible", "moyenne", "forte")

#' Definition de terrain des niveaux de concurrence
#'
#' @description
#' Ce qui distingue `faible`, `moyenne` et `forte` au controle d'une
#' plantation (brief `surculus` 2026-11-04, issue #69). Colonnes : `niveau`
#' (un de [SOMMIER_CONCURRENCES]), `libelle` (ecran), `part_plants_min_pct` et
#' `part_plants_max_pct` (part des plants vivants au contact de la vegetation
#' concurrente, bornes `[min, max[`), `critere_hauteur` (position de la
#' vegetation par rapport au plant) et `travail` (suite usuelle).
#'
#' **Un seul critere decide : la part de plants vivants au contact de la
#' vegetation.** `critere_hauteur` et `travail` sont une aide descriptive pour
#' le controleur : ils ne decident jamais du niveau (60 % des plants au contact
#' avec une vegetation au pied seulement : `forte`).
#'
#' Aucune des cinq sources publiees lues par l'acquereur de Surculus (guide
#' "Reussir la plantation forestiere" 2014 p. 52 ; DSF bilan 2024 p. 13 et
#' 16 ; RENFOR/INRAE ; CNPF CONQueTh ; MRNF Quebec 2024 p. 12) ne definit trois
#' niveaux : leurs criteres sont binaires et portent sur le plant ("aucune
#' touffe de vegetation concurrente au pied des plants", guide 2014 p. 52).
#' Les seuils ci-dessous sont donc une **convention de sommieR**, derivee de ce
#' critere par plant, a confirmer sur le terrain ; elle n'est pas une norme.
#'
#' @format Un `data.frame` de trois lignes.
#' @seealso [sommier_niveau_concurrence()], [SOMMIER_CONCURRENCES]
#' @export
SOMMIER_DEFINITIONS_CONCURRENCE <- data.frame(
  niveau = c("faible", "moyenne", "forte"),
  libelle = c("Faible", "Moyenne", "Forte"),
  part_plants_min_pct = c(0, 20, 50),
  part_plants_max_pct = c(20, 50, Inf),
  critere_hauteur = c(
    "vegetation au pied seulement, plant dominant",
    "vegetation atteignant le plant sans le depasser",
    "vegetation depassant le plant ou l'etouffant"),
  travail = c("aucun", "degagement a prevoir", "degagement a faire"),
  stringsAsFactors = FALSE
)

#' Niveau de concurrence d'une placette, depuis les plants
#'
#' @description
#' Regle de passage du critere binaire par plant (concurrence ou non, guide 2014
#' p. 52) au niveau de placette : on compte la part des plants vivants concurrences
#' par la vegetation, puis on la lit dans
#' [SOMMIER_DEFINITIONS_CONCURRENCE]. Un seul niveau couvre l'herbacee et la
#' ligneuse (fougere aigle, ronce) : il se calcule sur le comptage commun (un
#' plant touche par l'une ou l'autre compte une fois). La nature (herbacee,
#' ligneuse, mixte) se note a part, en `observations` : elle decrit, elle ne
#' decide pas.
#'
#' Sans plant vivant compte, le resultat est `NA` : jamais un niveau devine.
#'
#' @param nb_concurrences Plants vivants au contact de la vegetation concurrente.
#' @param nb_vivants Plants vivants comptes.
#'
#' @return Un element de [SOMMIER_CONCURRENCES], ou `NA_character_`.
#' @seealso [registre6_controle()]
#' @export
sommier_niveau_concurrence <- function(nb_concurrences, nb_vivants) {
  nb_concurrences <- valider_entier(nb_concurrences, "nb_concurrences", min = 0)
  nb_vivants <- valider_entier(nb_vivants, "nb_vivants", min = 0)
  if (nb_concurrences > nb_vivants) {
    stop("Plus de plants concurrences (", nb_concurrences, ") que de vivants (",
         nb_vivants, ").", call. = FALSE)
  }
  if (nb_vivants == 0L) return(NA_character_)
  part <- 100 * nb_concurrences / nb_vivants
  d <- SOMMIER_DEFINITIONS_CONCURRENCE
  d$niveau[part >= d$part_plants_min_pct & part < d$part_plants_max_pct]
}

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
#' @param concurrence L'un de [SOMMIER_CONCURRENCES], defini dans
#'   [SOMMIER_DEFINITIONS_CONCURRENCE].
#' @param besoin Le travail qui s'impose ensuite : un code de
#'   [SOMMIER_CODES_TRAVAUX], ou `"aucun"`.
#' @param operateur Agent qui a controle.
#' @param visite_le Instant du controle.
#' @param releve_uuid Identifiant du releve de terrain.
#' @param photos Photos, par leur empreinte.
#' @param observations Observations libres.
#' @param nb_plants_vivants,nb_plants_concurrences Facultatifs : le comptage
#'   dont `concurrence` est tiree, pour qu'on puisse la verifier. Plants
#'   vivants sur lesquels le contact avec la vegetation a ete note (au plus
#'   `nb_vivants`), et parmi eux ceux au contact de la vegetation concurrente.
#'   Ajout seul : `NULL` est accepte, et un controle sans ces champs se relit a
#'   l'identique. Lis avec [sommier_niveau_concurrence()]. Quand les deux sont
#'   fournis : si `concurrence` est absent, il est **deduit** par
#'   [sommier_niveau_concurrence()] ; s'il est saisi et contredit les
#'   comptages, il est **conserve tel que saisi**, un avertissement le dit et
#'   le niveau calcule est inscrit au payload sous `concurrence_calculee`.
#' @param concurrence_calculee Ne se saisit pas : c'est la trace que la
#'   fonction inscrit quand le niveau saisi contredit les comptages. Accepte
#'   pour que la relecture d'un payload ecrit se rejoue (il est recalcule).
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
                               observations = NULL,
                               nb_plants_vivants = NULL,
                               nb_plants_concurrences = NULL,
                               concurrence_calculee = NULL) {
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
  nb_plants_vivants <- si_present(nb_plants_vivants, valider_entier,
                                  "nb_plants_vivants", min = 0)
  nb_plants_concurrences <- si_present(nb_plants_concurrences, valider_entier,
                                       "nb_plants_concurrences", min = 0)
  if (!is.null(nb_plants_concurrences) && is.null(nb_plants_vivants)) {
    stop("nb_plants_concurrences exige nb_plants_vivants : une part ",
         "se lit sur un denominateur.", call. = FALSE)
  }
  if (!is.null(nb_plants_vivants) && nb_plants_vivants > nb_vivants) {
    stop("Plus de plants notes (", nb_plants_vivants, ") que de vivants (",
         nb_vivants, ").", call. = FALSE)
  }
  if (!is.null(nb_plants_concurrences) &&
      nb_plants_concurrences > nb_plants_vivants) {
    stop("Plus de plants au contact (", nb_plants_concurrences,
         ") que de plants vivants notes (", nb_plants_vivants, ").",
         call. = FALSE)
  }
  concurrence <- si_present(concurrence, valider_choix, "concurrence",
                            SOMMIER_CONCURRENCES)
  # Les deux comptages permettent de deduire le niveau (regle de
  # sommier_niveau_concurrence()). Un niveau saisi qui les contredit est
  # accepte tel quel : le terrain n'est jamais bloque, l'ecart est inscrit.
  relu <- !is.null(concurrence_calculee)  # relecture d'un payload deja ecrit
  concurrence_calculee <- NULL
  if (!is.null(nb_plants_concurrences)) {
    concurrence_calculee <- sommier_niveau_concurrence(
      nb_plants_concurrences, nb_plants_vivants)
    # Aucun vivant note (0 sur 0) : pas de niveau a calculer, donc rien a
    # deduire, rien a comparer, rien a inscrire.
    if (is.na(concurrence_calculee)) {
      concurrence_calculee <- NULL
    } else if (is.null(concurrence)) {
      concurrence <- concurrence_calculee
      concurrence_calculee <- NULL
    } else if (identical(concurrence, concurrence_calculee)) {
      concurrence_calculee <- NULL
    } else if (!relu) {
      warning("concurrence saisie (", concurrence, ") differente du niveau ",
              "calcule sur les comptages (", concurrence_calculee, ") : ",
              "saisie conservee, ecart inscrit (concurrence_calculee).",
              call. = FALSE)
    }
  }
  compacter(list(
    type_entree = "controle",
    placette_id = valider_uuid(placette_id, "placette_id"),
    nb_total    = nb_total,
    nb_vivants  = nb_vivants,
    h_moy_cm    = si_present(h_moy_cm, valider_entier, "h_moy_cm", min = 0),
    nb_abroutis = nb_abroutis,
    concurrence = concurrence,
    besoin      = si_present(besoin, valider_choix, "besoin",
                             c(SOMMIER_CODES_TRAVAUX$code, "aucun")),
    operateur   = si_present(operateur, valider_texte, "operateur"),
    visite_le   = si_present(visite_le, format_instant, "visite_le"),
    releve_uuid = si_present(releve_uuid, valider_uuid, "releve_uuid"),
    photos      = valider_photos(photos),
    observations = si_present(observations, valider_texte, "observations"),
    nb_plants_vivants = nb_plants_vivants,
    nb_plants_concurrences = nb_plants_concurrences,
    concurrence_calculee = concurrence_calculee
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

# Les formes d'un code, en types GeoJSON.
FORMES_GEOJSON <- c(point = "Point", ligne = "LineString", surface = "Polygon")

# "m, ha" -> c("m", "ha")
alternatives <- function(x) strsplit(x, ",\\s*")[[1L]]
