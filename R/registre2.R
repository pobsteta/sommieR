#' Types d'entree du registre 2 (foncier et limites)
#'
#' @description
#' * `delimitation` et `bornage` : operations de limite, avec leurs elements
#'   de calcul et leur repartition (imprime A40).
#' * `application_regime` et `distraction_regime` : entree ou sortie du regime
#'   forestier, sans objet en foret privee.
#' * `acquisition` et `cession` : mouvements de propriete.
#' * `servitude` : servitude constituee ou subie.
#'
#' @export
SOMMIER_TYPES_FONCIER <- c(
  "delimitation", "bornage", "application_regime", "distraction_regime",
  "acquisition", "cession", "servitude"
)

#' Payload du registre 2 - foncier et limites (imprime A40)
#'
#' @description
#' Une operation foncière : limite, mouvement de propriete, servitude, ou
#' application du regime forestier.
#'
#' @details
#' L'imprime A40 detaille les elements de calcul des frais de delimitation
#' (heures d'ingenieur et de technicien, arpentage, fourniture et pose des
#' bornes) et leur repartition entre le proprietaire et les riverains. Ces
#' champs ne sont exiges que pour les operations de limite : une acquisition
#' n'a pas d'heures d'arpentage.
#'
#' La coherence de la repartition est verifiee lorsque les deux parts et le
#' cout total sont renseignes : une repartition qui ne totalise pas le cout
#' est une erreur de saisie, pas une subtilite comptable.
#'
#' @param type_entree L'un de [SOMMIER_TYPES_FONCIER].
#' @param description Description de l'operation.
#' @param heures_ingenieur,heures_technicien Temps passe (facultatif).
#' @param arpentage_eur Frais d'arpentage (facultatif).
#' @param nb_bornes Nombre de bornes fournies et posees (facultatif).
#' @param cout_total_eur Cout total de l'operation (facultatif).
#' @param charge_proprietaire_eur,charge_riverains_eur Repartition du cout
#'   (facultatif).
#' @param surface_ha Surface concernee (facultatif).
#' @param reference_acte Reference de l'acte, de l'arrete ou du proces-verbal
#'   (facultatif).
#' @param references_cadastrales References cadastrales, en un ou plusieurs
#'   elements (facultatif).
#' @param beneficiaire Beneficiaire d'une servitude (facultatif).
#' @param observations Observations libres (facultatif).
#'
#' @param geometrie Position ou trace, en WGS84 : une borne est un point (voir
#'   [geom_point()]), une limite une ligne (voir [geom_ligne()]).
#'   Facultative — un gestionnaire sans releve continue de saisir sans, et son
#'   sommier reste conforme.
#'
#' @return Une liste nommee, prete a etre passee a [sommier_entree()].
#'
#' @examples
#' registre2_foncier(
#'   type_entree = "bornage", description = "Limite nord, canton des Vernes",
#'   heures_technicien = 14, nb_bornes = 8, cout_total_eur = 1200,
#'   charge_proprietaire_eur = 600, charge_riverains_eur = 600
#' )
#'
#' @export
registre2_foncier <- function(type_entree,
                              description,
                              heures_ingenieur = NULL,
                              heures_technicien = NULL,
                              arpentage_eur = NULL,
                              nb_bornes = NULL,
                              cout_total_eur = NULL,
                              charge_proprietaire_eur = NULL,
                              charge_riverains_eur = NULL,
                              surface_ha = NULL,
                              reference_acte = NULL,
                              references_cadastrales = NULL,
                              beneficiaire = NULL,
                              observations = NULL,
                              geometrie = NULL) {
  type_entree <- valider_choix(type_entree, "type_entree", SOMMIER_TYPES_FONCIER)

  # Une repartition qui ne totalise pas le cout est une erreur de saisie.
  if (!est_vide(cout_total_eur) && !est_vide(charge_proprietaire_eur) &&
      !est_vide(charge_riverains_eur)) {
    total <- charge_proprietaire_eur + charge_riverains_eur
    if (abs(total - cout_total_eur) > 0.01) {
      stop("La repartition ne totalise pas le cout : ",
           charge_proprietaire_eur, " + ", charge_riverains_eur, " = ", total,
           ", attendu ", cout_total_eur, ".", call. = FALSE)
    }
  }

  compacter(list(
    type_entree             = type_entree,
    description             = valider_texte(description, "description"),
    heures_ingenieur        = si_present(heures_ingenieur, valider_nombre,
                                         "heures_ingenieur", min = 0),
    heures_technicien       = si_present(heures_technicien, valider_nombre,
                                         "heures_technicien", min = 0),
    arpentage_eur           = si_present(arpentage_eur, valider_nombre,
                                         "arpentage_eur", min = 0),
    nb_bornes               = si_present(nb_bornes, valider_entier,
                                         "nb_bornes", min = 0),
    cout_total_eur          = si_present(cout_total_eur, valider_nombre,
                                         "cout_total_eur", min = 0),
    charge_proprietaire_eur = si_present(charge_proprietaire_eur, valider_nombre,
                                         "charge_proprietaire_eur", min = 0),
    charge_riverains_eur    = si_present(charge_riverains_eur, valider_nombre,
                                         "charge_riverains_eur", min = 0),
    surface_ha              = si_present(surface_ha, valider_nombre,
                                         "surface_ha", min = 0),
    reference_acte          = si_present(reference_acte, valider_texte,
                                         "reference_acte"),
    references_cadastrales  = valider_liste_texte(references_cadastrales,
                                                 "references_cadastrales"),
    beneficiaire            = si_present(beneficiaire, valider_texte,
                                         "beneficiaire"),
    geometrie        = geometrie_si_presente(geometrie, c("Point", "LineString")),
    observations            = si_present(observations, valider_texte,
                                         "observations")
  ))
}

# Un champ qui peut porter plusieurs valeurs : rendu en tableau JSON meme a un
# seul element, sans quoi la forme du payload changerait avec le nombre de
# valeurs et compliquerait la relecture.
valider_liste_texte <- function(x, nom) {
  if (est_vide(x)) {
    return(NULL)
  }
  valeurs <- vapply(as.character(x), valider_texte, character(1), nom = nom,
                    USE.NAMES = FALSE)
  I(valeurs)
}
