#' Postes comptables du registre 7 (imprime A50G)
#'
#' @description
#' Nomenclature des postes de recettes et de depenses, reprise de la structure
#' de l'imprime A50G. Chaque poste porte son sens (recette ou depense) et sa
#' rubrique, de sorte que le sens n'a pas a etre saisi : il decoule du poste,
#' et ne peut donc pas le contredire.
#'
#' @details
#' Les rubriques suivent les quatre blocs de l'imprime :
#'
#' * `produits` : recettes (bois sur pied, faconnes, delivres, chasse et
#'   peche, concessions).
#' * `travaux_entretien` : entretien des peuplements, des infrastructures, du
#'   tourisme, de la chasse et de la peche, exploitation en regie.
#' * `travaux_neufs` : reboisement, equipement, tourisme.
#' * `autres_frais` : impots fonciers, frais de garderie, honoraires.
#'
#' `frais_garderie` ne concerne en pratique que la foret communale, et
#' `bois_delivres` que l'affouage ; ils ne sont pas pour autant interdits
#' ailleurs. Le sommier enregistre ce qui advient : refuser a priori une
#' ecriture parce qu'elle est inhabituelle rendrait le registre infidele.
#'
#' @format `data.frame` de 4 colonnes : `poste`, `sens`, `rubrique`, `libelle`.
#'
#' @examples
#' SOMMIER_POSTES_COMPTABLES
#'
#' @export
SOMMIER_POSTES_COMPTABLES <- data.frame(
  poste = c(
    "bois_sur_pied", "bois_faconnes", "bois_delivres", "chasse_peche",
    "concessions", "subventions", "autres_produits",
    "entretien_peuplements", "entretien_infrastructure", "entretien_tourisme",
    "entretien_chasse_peche", "exploitation_regie",
    "reboisement", "equipement", "tourisme_neuf",
    "impots_fonciers", "frais_garderie", "honoraires", "autres_frais"
  ),
  sens = c(
    rep("recette", 7L),
    rep("depense", 12L)
  ),
  rubrique = c(
    rep("produits", 7L),
    rep("travaux_entretien", 5L),
    rep("travaux_neufs", 3L),
    rep("autres_frais", 4L)
  ),
  libelle = c(
    "Bois vendus sur pied", "Bois faconnes", "Bois delivres (affouage)",
    "Locations de chasse et de peche", "Concessions diverses",
    "Subventions percues", "Autres produits",
    "Entretien des peuplements", "Entretien des infrastructures",
    "Entretien des equipements touristiques",
    "Entretien chasse et peche", "Exploitation en regie",
    "Reboisement", "Equipement nouveau", "Equipement touristique nouveau",
    "Impots fonciers", "Frais de garderie", "Honoraires", "Autres frais"
  ),
  stringsAsFactors = FALSE
)

#' Dispositifs fiscaux de la foret privee
#'
#' Rattachement facultatif d'une ecriture a un dispositif fiscal, prevu par le
#' brief pour la foret privee.
#'
#' @export
SOMMIER_DISPOSITIFS_FISCAUX <- c("defi_travaux", "defi_foret", "defi_contrat",
                                 "monichon", "ifi", "autre")

#' Payload du registre 7 - comptabilite
#'
#' @description
#' Une ecriture de recette ou de depense (imprime A50G). Le sens est deduit du
#' poste, et le montant est toujours **positif** : c'est le poste qui dit s'il
#' s'ajoute ou se retranche.
#'
#' @details
#' Porter le sens dans le signe du montant est la source classique de doubles
#' negations - une depense saisie a `-500` sur un poste deja debiteur devient
#' une recette sans que rien ne le signale. Ici `montant_eur` est contraint
#' positif ou nul, et `sens` est calcule : les deux ne peuvent pas diverger.
#'
#' **Donnees personnelles.** `tiers` (acheteur, titulaire de bail,
#' affouagiste, entreprise) est une donnee a caractere personnel des lors
#' qu'il designe une personne physique. Le champ est facultatif, et il doit
#' etre omis lorsqu'il n'est pas necessaire : une entree de sommier ne
#' s'efface pas, l'append-only s'appliquant aussi aux donnees personnelles
#' qu'on y aurait mises sans besoin.
#'
#' @param poste L'un des postes de [SOMMIER_POSTES_COMPTABLES].
#' @param exercice Exercice budgetaire (entier).
#' @param montant_eur Montant en euros, positif ou nul.
#' @param libelle Libelle de l'ecriture (facultatif).
#' @param quantite,unite Quantite et unite associees - par exemple le volume
#'   vendu en metres cubes (facultatif).
#' @param tiers Contrepartie (facultatif). Voir la note sur les donnees
#'   personnelles.
#' @param reference Reference de la piece : numero de titre de recette, de
#'   facture, de mandat (facultatif).
#' @param dispositif_fiscal L'un de [SOMMIER_DISPOSITIFS_FISCAUX]
#'   (facultatif, foret privee).
#' @param observations Observations libres (facultatif).
#'
#' @return Une liste nommee, prete a etre passee a [sommier_entree()].
#'
#' @examples
#' registre7_ecriture(
#'   poste = "bois_sur_pied", exercice = 2026, montant_eur = 18400,
#'   quantite = 320, unite = "m3", reference = "TR-2026-014"
#' )
#'
#' @export
registre7_ecriture <- function(poste,
                               exercice,
                               montant_eur,
                               libelle = NULL,
                               quantite = NULL,
                               unite = NULL,
                               tiers = NULL,
                               reference = NULL,
                               dispositif_fiscal = NULL,
                               observations = NULL) {
  poste <- valider_choix(poste, "poste", SOMMIER_POSTES_COMPTABLES$poste)
  ligne <- SOMMIER_POSTES_COMPTABLES[SOMMIER_POSTES_COMPTABLES$poste == poste, ]

  if (!est_vide(quantite) && est_vide(unite)) {
    stop("`unite` est obligatoire des lors que `quantite` est renseignee.",
         call. = FALSE)
  }

  compacter(list(
    poste             = poste,
    # Deduits du poste : les stocker rend le payload lisible sans la
    # nomenclature, sans risque de contradiction puisqu'ils ne se saisissent
    # pas.
    sens              = ligne$sens[[1L]],
    rubrique          = ligne$rubrique[[1L]],
    exercice          = valider_entier(exercice, "exercice", min = 1500, max = 2999),
    montant_eur       = valider_nombre(montant_eur, "montant_eur", min = 0),
    libelle           = si_present(libelle, valider_texte, "libelle"),
    quantite          = si_present(quantite, valider_nombre, "quantite", min = 0),
    unite             = si_present(unite, valider_texte, "unite"),
    tiers             = si_present(tiers, valider_texte, "tiers"),
    reference         = si_present(reference, valider_texte, "reference"),
    dispositif_fiscal = si_present(dispositif_fiscal, valider_choix,
                                   "dispositif_fiscal",
                                   choix = SOMMIER_DISPOSITIFS_FISCAUX),
    observations      = si_present(observations, valider_texte, "observations")
  ))
}
