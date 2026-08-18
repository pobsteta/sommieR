#' Natures de revetement de la voirie forestiere (imprime A50D)
#' @export
SOMMIER_REVETEMENTS <- c("revetue", "empierree", "terrain_naturel", "piste")

#' Usages de la voirie forestiere (imprime A50D bis)
#' @export
SOMMIER_USAGES_VOIRIE <- c("exploitation", "dfci", "tourisme", "mixte")

#' Types d'entree du registre 4 (infrastructures)
#' @export
SOMMIER_TYPES_INFRASTRUCTURE <- c("voirie", "equipement", "ouvrage_dfci")

#' Payload du registre 4 - voirie forestiere (imprimes A50D et A50D bis)
#'
#' @description
#' Un troncon de voirie forestiere, avec son revetement, sa longueur, sa
#' largeur de chaussee et son usage.
#'
#' @details
#' L'imprime A50D inventorie la voirie et en tire des densites en km pour
#' 100 hectares ; ces densites sont une vue calculee
#' ([sommier_densite_voirie()]), pas une saisie. L'imprime A50D bis y ajoute,
#' route par route, l'usage et l'ouverture au public.
#'
#' `ouverte_public` est distinct de l'usage : une route peut servir au
#' tourisme tout en etant fermee a la circulation motorisee, et c'est
#' precisement ce que l'imprime demande de tracer.
#'
#' @param nom Nom ou numero du troncon.
#' @param revetement L'un de [SOMMIER_REVETEMENTS].
#' @param longueur_m Longueur en metres.
#' @param largeur_chaussee_m Largeur de chaussee (facultatif).
#' @param usage L'un de [SOMMIER_USAGES_VOIRIE] (facultatif).
#' @param ouverte_public Ouverture a la circulation publique (facultatif).
#' @param voirie_publique Le troncon releve de la voirie publique et non de la
#'   voirie privee forestiere (defaut `FALSE`). L'imprime A50D les distingue,
#'   et seule la voirie privee entre dans la densite.
#' @param structure_chaussee Description de la structure (facultatif).
#' @param date_structure Date de realisation de la structure (facultatif).
#' @param observations Observations libres (facultatif).
#'
#' @return Une liste nommee, prete a etre passee a [sommier_entree()].
#'
#' @examples
#' registre4_voirie(
#'   nom = "Route du Haut-Bois", revetement = "empierree",
#'   longueur_m = 2400, largeur_chaussee_m = 4, usage = "exploitation",
#'   ouverte_public = FALSE
#' )
#'
#' @export
registre4_voirie <- function(nom,
                             revetement,
                             longueur_m,
                             largeur_chaussee_m = NULL,
                             usage = NULL,
                             ouverte_public = NULL,
                             voirie_publique = FALSE,
                             structure_chaussee = NULL,
                             date_structure = NULL,
                             observations = NULL) {
  compacter(list(
    type_entree        = "voirie",
    nom                = valider_texte(nom, "nom"),
    revetement         = valider_choix(revetement, "revetement", SOMMIER_REVETEMENTS),
    longueur_m         = valider_nombre(longueur_m, "longueur_m", min = 0),
    largeur_chaussee_m = si_present(largeur_chaussee_m, valider_nombre,
                                    "largeur_chaussee_m", min = 0),
    usage              = si_present(usage, valider_choix, "usage",
                                    choix = SOMMIER_USAGES_VOIRIE),
    ouverte_public     = if (est_vide(ouverte_public)) NULL else isTRUE(ouverte_public),
    voirie_publique    = isTRUE(voirie_publique),
    structure_chaussee = si_present(structure_chaussee, valider_texte,
                                    "structure_chaussee"),
    date_structure     = if (est_vide(date_structure)) NULL else
      format_date(date_structure, "date_structure"),
    observations       = si_present(observations, valider_texte, "observations")
  ))
}

#' Payload du registre 4 - equipement ou ouvrage DFCI
#'
#' @description
#' Un equipement forestier (place de depot, barriere, aire d'accueil) ou un
#' ouvrage de defense de la foret contre l'incendie.
#'
#' @details
#' L'analyse DFCI est obligatoire dans les PSG depuis la loi du 10 juillet
#' 2023 ; le brief la range dans le socle commun du registre 4 plutot que dans
#' un registre propre a la foret privee, ce que suit cette implementation :
#' un point d'eau se decrit de la meme facon quel que soit le regime.
#'
#' @param type_entree `"equipement"` ou `"ouvrage_dfci"`.
#' @param nature Nature de l'equipement ou de l'ouvrage.
#' @param nom Nom ou identifiant (facultatif).
#' @param capacite Capacite, par exemple le volume d'un point d'eau
#'   (facultatif).
#' @param unite Unite de la capacite (facultatif).
#' @param etat Etat constate : `"bon"`, `"moyen"`, `"degrade"`, `"hors_service"`
#'   (facultatif).
#' @param date_controle Date du dernier controle (facultatif).
#' @param observations Observations libres (facultatif).
#'
#' @return Une liste nommee, prete a etre passee a [sommier_entree()].
#'
#' @examples
#' registre4_equipement(
#'   type_entree = "ouvrage_dfci", nature = "Point d'eau",
#'   nom = "PE-03", capacite = 120, unite = "m3", etat = "bon"
#' )
#'
#' @export
registre4_equipement <- function(type_entree,
                                 nature,
                                 nom = NULL,
                                 capacite = NULL,
                                 unite = NULL,
                                 etat = NULL,
                                 date_controle = NULL,
                                 observations = NULL) {
  type_entree <- valider_choix(type_entree, "type_entree",
                               c("equipement", "ouvrage_dfci"))
  if (!est_vide(capacite) && est_vide(unite)) {
    stop("`unite` est obligatoire des lors que `capacite` est renseignee.",
         call. = FALSE)
  }
  compacter(list(
    type_entree   = type_entree,
    nature        = valider_texte(nature, "nature"),
    nom           = si_present(nom, valider_texte, "nom"),
    capacite      = si_present(capacite, valider_nombre, "capacite", min = 0),
    unite         = si_present(unite, valider_texte, "unite"),
    etat          = si_present(etat, valider_choix, "etat",
                               choix = c("bon", "moyen", "degrade", "hors_service")),
    date_controle = if (est_vide(date_controle)) NULL else
      format_date(date_controle, "date_controle"),
    observations  = si_present(observations, valider_texte, "observations")
  ))
}

registre4_depuis_payload <- function(payload) {
  if (!is.list(payload) || est_vide(payload$type_entree)) {
    stop("Le payload du registre 4 doit porter `type_entree`, l'un de : ",
         paste(SOMMIER_TYPES_INFRASTRUCTURE, collapse = ", "), ".", call. = FALSE)
  }
  type <- valider_choix(payload$type_entree, "type_entree",
                        SOMMIER_TYPES_INFRASTRUCTURE)
  arguments <- payload[setdiff(names(payload), "type_entree")]
  if (type == "voirie") {
    return(do.call(registre4_voirie, arguments))
  }
  arguments$type_entree <- type
  do.call(registre4_equipement, arguments)
}
