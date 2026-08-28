#' Fixation du budget previsionnel
#'
#' @description
#' Inscrit ou revise le montant prevu pour un poste et un exercice.
#'
#' @details
#' Le previsionnel **n'est pas** une entree de sommier. Le brief le pose
#' clairement : « le programme previsionnel appartient a l'amenagement ou au
#' PSG ; le sommier n'enregistre que le realise et le constate ». Il vit donc
#' a cote du registre, comme la possibilite annuelle, et il est **mutable** :
#' un budget se revise, et cette revision n'a pas a etre opposable. Ce qui
#' doit l'etre, c'est le realise - et celui-la est dans la chaine.
#'
#' @param con Connexion DBI.
#' @param foret_id UUID de la foret.
#' @param annee Exercice budgetaire.
#' @param poste L'un des postes de [SOMMIER_POSTES_COMPTABLES].
#' @param montant_eur Montant prevu, positif ou nul. Le sens vient du poste.
#' @return Invisiblement, le nombre de lignes ecrites.
#'
#' @seealso [sommier_execution_budgetaire()]
#' @export
budget_definir <- function(con, foret_id, annee, poste, montant_eur) {
  # Les validations precedent l'appel plutot que d'habiter sa liste
  # d'arguments : R les evaluerait alors paresseusement, c'est-a-dire apres
  # que le pilote a ouvert son objet de resultat. Un argument refuse laissait
  # ainsi la connexion sale, et l'ordre suivant - quel qu'il fut - annulait la
  # requete morte en le signalant.
  valeurs <- parametres(list(
    valider_uuid(foret_id, "foret_id"),
    valider_entier(annee, "annee", min = 1500, max = 2999),
    valider_choix(poste, "poste", SOMMIER_POSTES_COMPTABLES$poste),
    valider_nombre(montant_eur, "montant_eur", min = 0)
  ))
  invisible(DBI::dbExecute(
    con,
    "INSERT INTO budget_previsionnel (foret_id, annee, poste, montant_eur)
     VALUES ($1, $2, $3, $4)
     ON CONFLICT (foret_id, annee, poste)
     DO UPDATE SET montant_eur = EXCLUDED.montant_eur, revise_le = now()",
    params = valeurs
  ))
}

#' Bilan financier (imprime A50G)
#'
#' @description
#' Recettes, depenses et solde par exercice, avec le cumul. Vue calculee :
#' rien n'est stocke, tout se deduit du registre 7.
#'
#' @details
#' `bois_delivres_eur` isole la valeur des bois delivres - l'affouage, propre
#' a la foret communale - parce que l'imprime A50G lui reserve sa colonne et
#' que le conseil municipal la lit pour elle-meme.
#'
#' @param con Connexion DBI.
#' @param foret_id UUID de la foret.
#' @return Un `data.frame` : `exercice`, `recettes_eur`, `depenses_eur`, les
#'   trois rubriques de depense, `bois_delivres_eur`, `solde_eur`,
#'   `solde_cumule_eur`.
#'
#' @export
sommier_bilan_financier <- function(con, foret_id) {
  # Valide avant d'ouvrir un resultat : voir budget_definir().
  valeurs <- parametres(list(valider_uuid(foret_id, "foret_id")))
  DBI::dbGetQuery(
    con,
    "SELECT exercice, recettes_eur, depenses_eur, travaux_entretien_eur,
            travaux_neufs_eur, autres_frais_eur, bois_delivres_eur,
            solde_eur, solde_cumule_eur
       FROM v_bilan_financier
      WHERE foret_id = $1
      ORDER BY exercice",
    params = valeurs
  )
}

#' Execution budgetaire
#'
#' @description
#' Confronte le realise du registre 7 au budget previsionnel, poste par poste.
#'
#' @details
#' Un poste budgete mais jamais execute apparait avec un realise nul, et un
#' poste execute hors budget avec un prevu nul : les deux sont des faits de
#' gestion, aucun ne doit disparaitre du tableau. `execution_pct` vaut `NA`
#' lorsque rien n'etait budgete, un taux sur une base nulle n'ayant pas de
#' sens - l'ecart en euros suffit a le dire.
#'
#' @param con Connexion DBI.
#' @param foret_id UUID de la foret.
#' @param exercice Restreindre a un exercice (facultatif).
#' @return Un `data.frame` : `exercice`, `poste`, `prevu_eur`, `realise_eur`,
#'   `ecart_eur`, `execution_pct`.
#'
#' @export
sommier_execution_budgetaire <- function(con, foret_id, exercice = NULL) {
  params <- list(valider_uuid(foret_id, "foret_id"))
  condition <- "foret_id = $1"
  if (!est_vide(exercice)) {
    params <- c(params, list(valider_entier(exercice, "exercice",
                                            min = 1500, max = 2999)))
    condition <- paste0(condition, " AND exercice = $2")
  }
  DBI::dbGetQuery(
    con,
    paste0("SELECT exercice, poste, prevu_eur, realise_eur, ecart_eur,
                   execution_pct
              FROM v_execution_budgetaire
             WHERE ", condition, "
             ORDER BY exercice, poste"),
    params = parametres(params)
  )
}
