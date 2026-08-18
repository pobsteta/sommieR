#' Import de detections par teledetection
#'
#' @description
#' Inscrit au registre 8 des phenomenes proposes par une chaine de
#' teledetection (FORDEAD, FAST). Chaque detection est ecrite avec le NDP de
#' sa source, jamais NDP 0 : c'est une proposition, pas un constat.
#'
#' @details
#' Le sommier reste le receptacle NDP 0 de la plateforme sans pour autant se
#' fermer aux observations moins precises. La distinction est portee par le
#' champ `ndp` de l'entree : une detection FORDEAD arrive avec le NDP de la
#' chaine, et seule [sommier_valider_detection()] inscrit l'entree NDP 0 qui
#' la confirme ou l'ecarte apres passage sur le terrain.
#'
#' Ecrire les propositions dans la chaine plutot que dans une table d'attente
#' est deliberé : une detection est un fait date - la chaine a bien produit ce
#' signal ce jour-la - et le sommier enregistre ce qui advient. La suite
#' donnee, elle, se lit au registre.
#'
#' @param con Connexion DBI.
#' @param foret_id UUID de la foret.
#' @param detections `data.frame` ou liste de listes. Colonnes attendues :
#'   `nature`, `description`, `date_evenement` ; facultatives : `ug_uuid`,
#'   `surface_ha`, `indice`, `date_detection`, `observations`.
#' @param source Chaine de detection : `"fordead"`, `"fast"`, autre.
#' @param ndp Niveau de precision de la source (entier >= 1). Une detection
#'   ne peut pas etre NDP 0 : ce niveau est reserve au constat de terrain.
#' @param auteur Identifiant du compte ayant lance l'import.
#'
#' @return Invisiblement, la liste des entrees chainees.
#'
#' @seealso [sommier_valider_detection()], [registre8_detection()]
#' @export
sommier_importer_detections <- function(con, foret_id, detections, source,
                                        ndp, auteur) {
  foret_id <- valider_uuid(foret_id, "foret_id")
  source <- valider_texte(source, "source")
  auteur <- valider_texte(auteur, "auteur")
  ndp <- valider_entier(ndp, "ndp", min = 1)

  if (is.data.frame(detections)) {
    detections <- lapply(seq_len(nrow(detections)), function(i) {
      as.list(detections[i, , drop = FALSE])
    })
  }
  if (!is.list(detections) || length(detections) == 0L) {
    stop("`detections` doit etre un data.frame ou une liste non vide.",
         call. = FALSE)
  }

  entrees <- lapply(detections, function(d) {
    sommier_entree(
      foret_id = foret_id,
      registre = 8L,
      date_evenement = d$date_evenement,
      auteur = auteur,
      ug_uuid = d$ug_uuid,
      ndp = ndp,
      payload = registre8_detection(
        nature = d$nature,
        source = source,
        description = d$description,
        surface_ha = d$surface_ha,
        indice = d$indice,
        date_detection = d$date_detection,
        observations = d$observations
      )
    )
  })
  sommier_ajouter(con, entrees)
}

#' Suite donnee a une detection apres passage sur le terrain
#'
#' @description
#' Inscrit le constat de terrain qui confirme ou ecarte une detection. La
#' nouvelle entree porte NDP 0 et rectifie la detection : celle-ci sort des
#' vues de consultation sans sortir de la chaine.
#'
#' @details
#' Un constat qui ecarte la detection la rectifie tout autant qu'un constat
#' qui la confirme : dans les deux cas la proposition ne doit plus etre lue
#' comme un fait etabli. La difference tient au champ `statut_detection` du
#' payload, que les vues exposent.
#'
#' @param con Connexion DBI.
#' @param detection_id UUID de l'entree de detection.
#' @param auteur Identifiant de l'agent ayant constate.
#' @param statut `"confirme"` ou `"ecarte"`.
#' @param description Constat de terrain.
#' @param date_evenement Date du constat. Par defaut, aujourd'hui.
#' @param nature Nature retenue. Par defaut, celle de la detection.
#' @param surface_ha Surface constatee (facultatif).
#' @param volume_impacte_m3 Volume affecte (facultatif).
#' @param observations Observations libres (facultatif).
#'
#' @return Invisiblement, l'entree chainee.
#' @export
sommier_valider_detection <- function(con, detection_id, auteur, statut,
                                      description,
                                      date_evenement = Sys.Date(),
                                      nature = NULL,
                                      surface_ha = NULL,
                                      volume_impacte_m3 = NULL,
                                      observations = NULL) {
  detection_id <- valider_uuid(detection_id, "detection_id")
  statut <- valider_choix(statut, "statut", c("confirme", "ecarte"))

  detection <- DBI::dbGetQuery(
    con,
    "SELECT foret_id, ug_uuid, registre, payload::text AS payload
       FROM entree_sommier WHERE id = $1",
    params = list(detection_id)
  )
  if (nrow(detection) == 0L) {
    stop("Entree inconnue : ", detection_id, ".", call. = FALSE)
  }
  if (detection$registre[[1L]] != 8L) {
    stop("L'entree ", detection_id, " n'appartient pas au registre 8.",
         call. = FALSE)
  }
  payload <- jsonlite::fromJSON(detection$payload[[1L]], simplifyVector = FALSE)
  if (!identical(payload$type_entree, "detection")) {
    stop("L'entree ", detection_id, " n'est pas une detection ",
         "(type_entree = ", payload$type_entree %||% "absent", ").",
         call. = FALSE)
  }

  sommier_ajouter(con, sommier_entree(
    foret_id = detection$foret_id[[1L]],
    registre = 8L,
    date_evenement = date_evenement,
    auteur = auteur,
    ug_uuid = if (est_vide(detection$ug_uuid[[1L]])) NULL else detection$ug_uuid[[1L]],
    ndp = 0L,                       # constat de terrain, par definition
    corrige_id = detection_id,
    payload = registre8_suite_detection(
      statut = statut,
      detection_id = detection_id,
      nature = nature %||% payload$nature,
      description = description,
      surface_ha = surface_ha,
      volume_impacte_m3 = volume_impacte_m3,
      observations = observations
    )
  ))
}
