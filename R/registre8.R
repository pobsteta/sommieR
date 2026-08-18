#' Types d'entree du registre 8
#'
#' @description
#' Le registre 8 recouvre trois imprimes et un flux entrant :
#'
#' * `phenomene` : journal chronologique des phenomenes interessant la vie de
#'   la foret (imprime A50K) - tempetes, incendies, crises sanitaires, gel.
#' * `tableau_chasse` : prelevement cynegetique par saison et par espece
#'   (imprime A50L).
#' * `equilibre_gibier` : constat d'equilibre foret-gibier, obligatoire en
#'   PSG depuis la LAAAF de 2014.
#' * `detection` : phenomene propose par teledetection, en attente de
#'   validation terrain (voir [sommier_importer_detections()]).
#'
#' @export
SOMMIER_TYPES_EVENEMENT <- c(
  "phenomene", "tableau_chasse", "equilibre_gibier", "detection"
)

#' Natures de phenomene (imprime A50K)
#' @export
SOMMIER_NATURES_PHENOMENE <- c(
  "tempete", "incendie", "secheresse", "crise_sanitaire", "gel",
  "inondation", "neige", "degat_gibier", "autre"
)

#' Payload du registre 8 - phenomene (imprime A50K)
#'
#' @description
#' Une ligne du journal chronologique des phenomenes interessant la vie de la
#' foret. C'est le registre qui, avec les registres 5 et 6, constitue
#' l'historique de gestion anterieure exige par les trois referentiels.
#'
#' @param nature L'une de [SOMMIER_NATURES_PHENOMENE].
#' @param description Description du phenomene.
#' @param surface_ha Surface affectee en hectares (facultatif).
#' @param volume_impacte_m3 Volume de bois affecte (facultatif).
#' @param intensite Intensite ou gravite, echelle libre du gestionnaire
#'   (facultatif).
#' @param observations Observations libres (facultatif).
#'
#' @return Une liste nommee, prete a etre passee a [sommier_entree()].
#'
#' @examples
#' registre8_phenomene(
#'   nature = "tempete", description = "Coup de vent du 12 mars",
#'   surface_ha = 8.5, volume_impacte_m3 = 340
#' )
#'
#' @export
registre8_phenomene <- function(nature,
                                description,
                                surface_ha = NULL,
                                volume_impacte_m3 = NULL,
                                intensite = NULL,
                                observations = NULL) {
  compacter(list(
    type_entree       = "phenomene",
    nature            = valider_choix(nature, "nature", SOMMIER_NATURES_PHENOMENE),
    description       = valider_texte(description, "description"),
    surface_ha        = si_present(surface_ha, valider_nombre, "surface_ha", min = 0),
    volume_impacte_m3 = si_present(volume_impacte_m3, valider_nombre,
                                   "volume_impacte_m3", min = 0),
    intensite         = si_present(intensite, valider_texte, "intensite"),
    observations      = si_present(observations, valider_texte, "observations")
  ))
}

#' Payload du registre 8 - tableau de chasse (imprime A50L)
#'
#' @description
#' Un prelevement cynegetique, pour une saison, une espece et une categorie.
#' L'imprime A50L est une matrice especes x saisons ; on l'enregistre ligne a
#' ligne, la matrice se reconstituant par requete.
#'
#' @details
#' La saison cynegetique court du 1er avril au 31 mars et se note
#' `"AAAA-AAAA"` (par exemple `"2025-2026"`). Les deux annees doivent se
#' suivre : `"2025-2027"` est refuse, une saison ne durant pas deux ans.
#'
#' @param saison Saison cynegetique, au format `"AAAA-AAAA"`.
#' @param espece Espece prelevee.
#' @param nombre Nombre d'individus preleves (entier positif ou nul).
#' @param classe_age Classe d'age (facultatif) : `"jeune"`, `"subadulte"`,
#'   `"adulte"`, ou notation propre au plan de chasse.
#' @param sexe Sexe (facultatif) : `"male"`, `"femelle"`, `"indetermine"`.
#' @param attribue Nombre attribue au plan de chasse (facultatif), pour
#'   confronter realise et attribue.
#' @param observations Observations libres (facultatif).
#'
#' @return Une liste nommee, prete a etre passee a [sommier_entree()].
#'
#' @examples
#' registre8_tableau_chasse(
#'   saison = "2025-2026", espece = "chevreuil",
#'   classe_age = "adulte", sexe = "male", nombre = 12, attribue = 15
#' )
#'
#' @export
registre8_tableau_chasse <- function(saison,
                                     espece,
                                     nombre,
                                     classe_age = NULL,
                                     sexe = NULL,
                                     attribue = NULL,
                                     observations = NULL) {
  compacter(list(
    type_entree  = "tableau_chasse",
    saison       = valider_saison(saison),
    espece       = valider_texte(espece, "espece"),
    nombre       = valider_entier(nombre, "nombre", min = 0),
    classe_age   = si_present(classe_age, valider_texte, "classe_age"),
    sexe         = si_present(sexe, valider_choix, "sexe",
                              choix = c("male", "femelle", "indetermine")),
    attribue     = si_present(attribue, valider_entier, "attribue", min = 0),
    observations = si_present(observations, valider_texte, "observations")
  ))
}

#' Payload du registre 8 - equilibre foret-gibier
#'
#' @description
#' Constat d'equilibre entre la foret et les populations de grand gibier,
#' obligatoire dans les PSG depuis la LAAAF de 2014. Alimente la famille R
#' (r4_abroutissement) de nemeton.
#'
#' @param saison Saison cynegetique, au format `"AAAA-AAAA"`.
#' @param surface_sensible_ha Surface sensible aux degats, en hectares.
#' @param taux_abroutissement_pct Taux d'abroutissement constate, 0 a 100
#'   (facultatif).
#' @param methode Methode de constat : enclos-exclos, indice de consommation,
#'   observation directe (facultatif).
#' @param diagnostic Diagnostic porte : `"equilibre"`, `"desequilibre_leger"`,
#'   `"desequilibre_marque"` (facultatif).
#' @param observations Observations libres (facultatif).
#'
#' @return Une liste nommee, prete a etre passee a [sommier_entree()].
#'
#' @examples
#' registre8_equilibre_gibier(
#'   saison = "2025-2026", surface_sensible_ha = 42,
#'   taux_abroutissement_pct = 23.5, diagnostic = "desequilibre_leger"
#' )
#'
#' @export
registre8_equilibre_gibier <- function(saison,
                                       surface_sensible_ha,
                                       taux_abroutissement_pct = NULL,
                                       methode = NULL,
                                       diagnostic = NULL,
                                       observations = NULL) {
  compacter(list(
    type_entree             = "equilibre_gibier",
    saison                  = valider_saison(saison),
    surface_sensible_ha     = valider_nombre(surface_sensible_ha,
                                             "surface_sensible_ha", min = 0),
    taux_abroutissement_pct = si_present(taux_abroutissement_pct, valider_nombre,
                                         "taux_abroutissement_pct",
                                         min = 0, max = 100),
    methode                 = si_present(methode, valider_texte, "methode"),
    diagnostic              = si_present(diagnostic, valider_choix, "diagnostic",
                                         choix = c("equilibre", "desequilibre_leger",
                                                   "desequilibre_marque")),
    observations            = si_present(observations, valider_texte, "observations")
  ))
}

#' Payload du registre 8 - detection par teledetection
#'
#' @description
#' Un phenomene propose par une chaine de teledetection (FORDEAD, FAST),
#' en attente de validation terrain.
#'
#' @details
#' Une detection **n'est pas** un constat : elle porte le NDP de sa source, et
#' non NDP 0. C'est [sommier_valider_detection()] qui, apres passage sur le
#' terrain, inscrit l'entree NDP 0 qui la confirme ou l'ecarte. Le sommier
#' reste ainsi le receptacle NDP 0 de la plateforme sans se fermer aux
#' propositions moins precises.
#'
#' @param nature L'une de [SOMMIER_NATURES_PHENOMENE].
#' @param source Chaine de detection : `"fordead"`, `"fast"`, ou autre.
#' @param description Description de la detection.
#' @param surface_ha Surface detectee en hectares (facultatif).
#' @param indice Valeur de l'indice ayant declenche la detection (facultatif).
#' @param date_detection Date de l'observation satellitaire (facultatif).
#' @param observations Observations libres (facultatif).
#'
#' @return Une liste nommee, prete a etre passee a [sommier_entree()].
#'
#' @seealso [sommier_importer_detections()], [sommier_valider_detection()]
#'
#' @examples
#' registre8_detection(
#'   nature = "crise_sanitaire", source = "fordead",
#'   description = "Deperissement detecte sur pessiere",
#'   surface_ha = 3.2, indice = 0.42
#' )
#'
#' @export
registre8_detection <- function(nature,
                                source,
                                description,
                                surface_ha = NULL,
                                indice = NULL,
                                date_detection = NULL,
                                observations = NULL) {
  compacter(list(
    type_entree    = "detection",
    nature         = valider_choix(nature, "nature", SOMMIER_NATURES_PHENOMENE),
    source         = valider_texte(source, "source"),
    description    = valider_texte(description, "description"),
    surface_ha     = si_present(surface_ha, valider_nombre, "surface_ha", min = 0),
    indice         = si_present(indice, valider_nombre, "indice"),
    date_detection = if (est_vide(date_detection)) NULL else
      format_date(date_detection, "date_detection"),
    observations   = si_present(observations, valider_texte, "observations")
  ))
}

#' Payload du registre 8 - suite donnee a une detection
#'
#' @description
#' Constat de terrain confirmant ou ecartant une detection. Produit par
#' [sommier_valider_detection()] ; rarement construit a la main.
#'
#' @param statut `"confirme"` ou `"ecarte"`.
#' @param detection_id UUID de l'entree de detection concernee.
#' @param nature L'une de [SOMMIER_NATURES_PHENOMENE].
#' @param description Constat de terrain.
#' @param surface_ha Surface constatee en hectares (facultatif).
#' @param volume_impacte_m3 Volume de bois affecte (facultatif).
#' @param observations Observations libres (facultatif).
#'
#' @return Une liste nommee, prete a etre passee a [sommier_entree()].
#'
#' @export
registre8_suite_detection <- function(statut,
                                      detection_id,
                                      nature,
                                      description,
                                      surface_ha = NULL,
                                      volume_impacte_m3 = NULL,
                                      observations = NULL) {
  compacter(list(
    type_entree       = "phenomene",
    nature            = valider_choix(nature, "nature", SOMMIER_NATURES_PHENOMENE),
    description       = valider_texte(description, "description"),
    surface_ha        = si_present(surface_ha, valider_nombre, "surface_ha", min = 0),
    volume_impacte_m3 = si_present(volume_impacte_m3, valider_nombre,
                                   "volume_impacte_m3", min = 0),
    statut_detection  = valider_choix(statut, "statut", c("confirme", "ecarte")),
    detection_id      = valider_uuid(detection_id, "detection_id"),
    observations      = si_present(observations, valider_texte, "observations")
  ))
}

# Redirige un payload de registre 8 vers le constructeur de son type. Le
# registre couvre quatre imprimes ou flux distincts : la discriminante voyage
# dans le payload, pas dans la signature d'appel.
registre8_depuis_payload <- function(payload) {
  if (!is.list(payload) || est_vide(payload$type_entree)) {
    stop("Le payload du registre 8 doit porter `type_entree`, l'un de : ",
         paste(SOMMIER_TYPES_EVENEMENT, collapse = ", "), ".", call. = FALSE)
  }
  type <- valider_choix(payload$type_entree, "type_entree", SOMMIER_TYPES_EVENEMENT)
  arguments <- payload[setdiff(names(payload), "type_entree")]

  if (type == "phenomene" && !est_vide(payload$statut_detection)) {
    arguments$statut <- payload$statut_detection
    arguments$statut_detection <- NULL
    return(do.call(registre8_suite_detection, arguments))
  }

  do.call(switch(
    type,
    phenomene        = registre8_phenomene,
    tableau_chasse   = registre8_tableau_chasse,
    equilibre_gibier = registre8_equilibre_gibier,
    detection        = registre8_detection
  ), arguments)
}

# La saison cynegetique court du 1er avril au 31 mars : elle enjambe deux
# annees civiles, qui doivent se suivre.
valider_saison <- function(x) {
  x <- valider_texte(x, "saison")
  if (!grepl("^[0-9]{4}-[0-9]{4}$", x)) {
    stop("`saison` doit etre une saison cynegetique au format AAAA-AAAA ",
         "(du 1er avril au 31 mars), recu : ", x, ".", call. = FALSE)
  }
  annees <- as.integer(strsplit(x, "-", fixed = TRUE)[[1]])
  if (annees[[2]] != annees[[1]] + 1L) {
    stop("`saison` doit couvrir deux annees consecutives, recu : ", x, ".",
         call. = FALSE)
  }
  x
}
