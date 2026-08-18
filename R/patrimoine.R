#' Densite de la voirie forestiere (imprime A50D)
#'
#' @description
#' Longueur et densite par nature de revetement, en kilometres pour cent
#' hectares. Vue calculee : rien n'est saisi.
#'
#' @details
#' Seule la voirie **privee** forestiere entre au numerateur. L'imprime A50D
#' distingue voirie privee et voirie publique, et une route departementale qui
#' traverse la foret ne dit rien de sa desserte : l'y compter gonflerait la
#' densite sans qu'un metre de plus soit utilisable pour l'exploitation.
#'
#' La densite vaut `NA` lorsque la surface de la foret est inconnue : sans
#' denominateur, elle serait inventee.
#'
#' @param con Connexion DBI.
#' @param foret_id UUID de la foret.
#' @return Un `data.frame` : `revetement`, `longueur_km`, `densite_km_100ha`,
#'   plus une ligne `total`.
#'
#' @export
sommier_densite_voirie <- function(con, foret_id) {
  foret_id <- valider_uuid(foret_id, "foret_id")
  detail <- DBI::dbGetQuery(
    con,
    "SELECT revetement, longueur_km, densite_km_100ha, surface_ha
       FROM v_densite_voirie WHERE foret_id = $1 ORDER BY revetement",
    params = parametres(list(foret_id))
  )
  if (nrow(detail) == 0L) {
    return(data.frame(revetement = character(0), longueur_km = numeric(0),
                      densite_km_100ha = numeric(0), stringsAsFactors = FALSE))
  }
  surface <- detail$surface_ha[[1L]]
  total <- data.frame(
    revetement = "total",
    longueur_km = sum(detail$longueur_km),
    densite_km_100ha = if (is.na(surface) || surface == 0) NA_real_ else
      round(sum(detail$longueur_km) / (surface / 100), 2),
    stringsAsFactors = FALSE
  )
  rbind(detail[, c("revetement", "longueur_km", "densite_km_100ha")], total)
}

#' Seuil de circonference des tres gros bois
#'
#' Circonference a 1,30 m au-dela de laquelle un arbre est compte comme tres
#' gros bois pour l'IBP. La valeur par defaut, 220 cm, correspond a environ
#' 70 cm de diametre ; le seuil retenu varie selon la region et le referentiel,
#' d'ou le parametre de [sommier_elements_ibp()].
#'
#' @export
SOMMIER_SEUIL_TGB_CM <- 220

#' Elements du sommier utiles a l'IBP
#'
#' @description
#' Rassemble ce que le registre 9 peut fournir a l'Indice de Biodiversite
#' Potentielle : arbres porteurs de microhabitats, bois mort sur pied, tres
#' gros bois vivants, milieux ouverts, especes protegees.
#'
#' @details
#' **Cette fonction ne cote pas l'IBP, et ne le pretend pas.** L'IBP se releve
#' sur le terrain selon son protocole, sur des placettes et avec des classes
#' de notation qui ne se deduisent pas d'un registre. Ce que le sommier
#' apporte, ce sont des elements deja constates et dates - des arbres
#' remarquables identifies, des habitats mesures - qui alimentent les facteurs
#' correspondants sans s'y substituer.
#'
#' Rendre une note serait plus vendeur et faux : un facteur IBP se cote par
#' densite a l'hectare sur placette, pas par comptage d'un registre qui
#' n'inventorie que le remarquable.
#'
#' @param con Connexion DBI.
#' @param foret_id UUID de la foret.
#' @param seuil_tgb_cm Seuil de circonference des tres gros bois, en
#'   centimetres (defaut [SOMMIER_SEUIL_TGB_CM]).
#' @return Un `data.frame` : `facteur_ibp`, `element`, `valeur`, `unite`,
#'   `n_entrees`.
#'
#' @examples
#' # Necessite une connexion :
#' # sommier_elements_ibp(con, foret)
#'
#' @export
sommier_elements_ibp <- function(con, foret_id,
                                 seuil_tgb_cm = SOMMIER_SEUIL_TGB_CM) {
  foret_id <- valider_uuid(foret_id, "foret_id")
  seuil_tgb_cm <- valider_nombre(seuil_tgb_cm, "seuil_tgb_cm", min = 0)

  releves <- DBI::dbGetQuery(
    con,
    "SELECT type_fiche, etat_sanitaire, circonference_cm, surface_ha,
            type_habitat, effectif
       FROM v_remarquable_dernier_releve WHERE foret_id = $1",
    params = parametres(list(foret_id))
  )

  arbres <- releves[releves$type_fiche == "arbre", , drop = FALSE]
  morts <- arbres$etat_sanitaire %in% "mort"
  circonference <- suppressWarnings(as.numeric(arbres$circonference_cm))
  tgb <- !morts & !is.na(circonference) & circonference >= seuil_tgb_cm

  habitats <- releves[releves$type_fiche == "habitat", , drop = FALSE]
  # « Ouvert » au sens de l'IBP : clairiere, lande, pelouse, tourbiere. La
  # detection porte sur le libelle saisi, faute de nomenclature imposee - le
  # facteur est donc indicatif, ce que la sortie dit.
  ouverts <- grepl("ouvert|clairi|lande|pelouse|tourbi|prairie",
                   habitats$type_habitat, ignore.case = TRUE)

  especes <- releves[releves$type_fiche == "espece", , drop = FALSE]

  data.frame(
    facteur_ibp = c("F - arbres a microhabitats", "C - bois mort sur pied",
                    "E - tres gros bois vivants", "G - milieux ouverts",
                    "contexte - especes protegees"),
    element = c(
      "Arbres remarquables vivants au registre 9",
      "Arbres remarquables releves morts sur pied",
      paste0("Arbres vivants de circonference >= ", seuil_tgb_cm, " cm"),
      "Habitats remarquables au libelle evoquant un milieu ouvert",
      "Especes protegees inventoriees"
    ),
    valeur = c(sum(!morts), sum(morts), sum(tgb),
               sum(suppressWarnings(as.numeric(habitats$surface_ha[ouverts])), na.rm = TRUE),
               nrow(especes)),
    unite = c("arbres", "arbres", "arbres", "ha", "especes"),
    n_entrees = c(nrow(arbres), nrow(arbres), nrow(arbres),
                  nrow(habitats), nrow(especes)),
    stringsAsFactors = FALSE
  )
}
