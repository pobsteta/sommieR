#' Autorites de validation
#'
#' @description
#' Qui valide, selon le regime. C'est le seul point ou les trois regimes
#' divergent vraiment pour ce registre : arrete ministeriel ou prefectoral et
#' visa ONF en domanial, deliberations du conseil municipal en plus en foret
#' communale, agrement CRPF en prive.
#'
#' @export
SOMMIER_AUTORITES <- c(
  "onf", "commune", "crpf", "proprietaire", "prefet", "ministre", "expert"
)

#' Types d'acte du registre 1
#'
#' @description
#' * `visa_annuel` : le visa du responsable du niveau de gestion (imprime
#'   A10), obligatoire et annuel.
#' * `visa_direction` : le visa du niveau de direction, second cadre de
#'   l'imprime A10.
#' * `arrete` : arrete ministeriel ou prefectoral d'amenagement.
#' * `deliberation` : deliberation du conseil municipal (foret communale).
#' * `agrement` : agrement du PSG par le CRPF (foret privee).
#' * `avenant` : avenant au document de gestion.
#' * `engagement_fiscal` : engagement pris au titre d'un dispositif fiscal
#'   (DEFI, Monichon, IFI).
#'
#' @export
SOMMIER_TYPES_VALIDATION <- c(
  "visa_annuel", "visa_direction", "arrete", "deliberation",
  "agrement", "avenant", "engagement_fiscal"
)

#' Payload du registre 1 - validations
#'
#' @description
#' Construit et valide le payload d'une entree du registre 1 (imprime A10 et
#' actes de validation du document de gestion). C'est ce registre qui rend le
#' sommier opposable : il trace qui a valide quoi, et quand.
#'
#' @details
#' Ce registre enregistre l'**acte** de validation. Il ne porte pas la
#' signature cryptographique, qui vit dans la table `visa` et couvre la tete
#' de chaine : voir [sommier_viser()]. Les deux sont complementaires - le
#' registre dit qu'un visa a ete donne, la table `visa` prouve sur quel etat
#' du sommier il portait.
#'
#' @param type_validation L'un de [SOMMIER_TYPES_VALIDATION].
#' @param autorite L'un de [SOMMIER_AUTORITES].
#' @param nom_qualite Nom et qualite du signataire, tels que portes sur
#'   l'imprime.
#' @param exercice Exercice couvert (entier), pour un visa annuel.
#' @param reference Reference de l'acte : numero d'arrete, de deliberation,
#'   d'agrement (facultatif).
#' @param date_effet Date d'effet si elle differe de la date de l'acte
#'   (facultatif).
#' @param portee Portee de l'acte : `"sommier"`, `"amenagement"`, `"psg"`
#'   (facultatif).
#' @param observations Observations libres (facultatif).
#'
#' @return Une liste nommee, prete a etre passee a [sommier_entree()].
#'
#' @examples
#' registre1_validation(
#'   type_validation = "visa_annuel", autorite = "commune",
#'   nom_qualite = "Maire de Chaux", exercice = 2026
#' )
#'
#' @export
registre1_validation <- function(type_validation,
                                 autorite,
                                 nom_qualite,
                                 exercice = NULL,
                                 reference = NULL,
                                 date_effet = NULL,
                                 portee = NULL,
                                 observations = NULL) {
  type_validation <- valider_choix(type_validation, "type_validation",
                                   SOMMIER_TYPES_VALIDATION)
  # Le visa annuel de l'imprime A10 est justement annuel : sans exercice, il
  # ne se rattache a rien et le controle de tenue du sommier devient
  # invérifiable.
  if (type_validation %in% c("visa_annuel", "visa_direction") && est_vide(exercice)) {
    stop("`exercice` est obligatoire pour un visa annuel : c'est ce qui ",
         "rattache le visa a une periode de gestion.", call. = FALSE)
  }
  compacter(list(
    type_validation = type_validation,
    autorite        = valider_choix(autorite, "autorite", SOMMIER_AUTORITES),
    nom_qualite     = valider_texte(nom_qualite, "nom_qualite"),
    exercice        = si_present(exercice, valider_entier, "exercice",
                                 min = 1500, max = 2999),
    reference       = si_present(reference, valider_texte, "reference"),
    date_effet      = if (est_vide(date_effet)) NULL else format_date(date_effet, "date_effet"),
    portee          = si_present(portee, valider_choix, "portee",
                                 choix = c("sommier", "amenagement", "psg")),
    observations    = si_present(observations, valider_texte, "observations")
  ))
}
