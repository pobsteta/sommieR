#' Installer une placette de suivi
#'
#' @description
#' Inscrit au registre 6 une placette permanente qui suivra une plantation ou
#' une regeneration : son centre, son rayon, et les travaux qu'elle suit.
#'
#' @details
#' Les travaux suivis doivent etre une intervention du registre 6 de la meme
#' foret, dans la meme unite de gestion : une placette de l'UG 35 ne suit pas
#' une plantation de l'UG 12. Le code d'une placette est unique dans son
#' unite ; une placette deplacee se rectifie, elle ne se reinstalle pas sous
#' le meme code.
#'
#' @param con Connexion DBI.
#' @param travaux_id UUID de l'intervention suivie.
#' @param code_placette Code lisible ("P35-03").
#' @param geometrie Le centre, un point en WGS84 ([geom_point()]).
#' @param auteur Compte qui ecrit.
#' @param date_evenement Date d'installation.
#' @param id UUID de l'entree ; un import de terrain y met celui du releve.
#' @param ... Champs de [registre6_placette()] : `rayon_m`,
#'   `materialisation`, `precision_m`, `source_gnss`, `observations`.
#'
#' @return Invisiblement, l'entree chainee (liste d'une entree).
#'
#' @seealso [sommier_controler_placette()], [registre6_placette()]
#'
#' @export
sommier_installer_placette <- function(con, travaux_id, code_placette,
                                       geometrie, auteur,
                                       date_evenement = Sys.Date(),
                                       id = uuid_v4(), ...) {
  sommier_ajouter(con, entree_placette(
    con, travaux_id, code_placette, geometrie, auteur,
    date_evenement = date_evenement, id = id, ...
  ))
}

#' Controler une placette de suivi
#'
#' @description
#' Inscrit au registre 6 un passage sur une placette : plants comptes,
#' vivants, hauteur, abroutis, concurrence, et le travail qui s'impose
#' ensuite. L'entree prend l'unite de gestion de la placette.
#'
#' @details
#' Une placette inconnue, ou qui n'en est pas une, est refusee, de meme qu'un
#' second controle de la meme placette le meme jour : une erreur de
#' comptage se rectifie, elle ne se double pas.
#'
#' @param con Connexion DBI.
#' @param placette_id UUID de la placette.
#' @param nb_total,nb_vivants Plants comptes, et vivants parmi eux.
#' @param auteur Compte qui ecrit.
#' @param visite_le Instant du controle ; sa date est la date de l'entree.
#' @param id UUID de l'entree.
#' @param ... Champs de [registre6_controle()] : `h_moy_cm`, `nb_abroutis`,
#'   `concurrence`, `besoin`, `operateur`, `releve_uuid`, `photos`,
#'   `observations`.
#'
#' @return Invisiblement, l'entree chainee (liste d'une entree).
#'
#' @seealso [sommier_installer_placette()], [registre6_controle()]
#'
#' @export
sommier_controler_placette <- function(con, placette_id, nb_total, nb_vivants,
                                       auteur, visite_le = Sys.time(),
                                       id = uuid_v4(), ...) {
  sommier_ajouter(con, entree_controle(
    con, placette_id, nb_total, nb_vivants, auteur,
    visite_le = visite_le, id = id, ...
  ))
}

# ---------------------------------------------------------------------------

# Les entrees, sans les ecrire : l'import d'une tournee les ecrit toutes en
# une transaction, travaux puis placettes puis controles.

entree_placette <- function(con, travaux_id, code_placette, geometrie, auteur,
                            date_evenement = Sys.Date(), id = uuid_v4(),
                            ...) {
  travaux_id <- valider_uuid(travaux_id, "travaux_id")
  code_placette <- valider_texte(code_placette, "code_placette")
  travaux <- DBI::dbGetQuery(
    con,
    "SELECT foret_id::text AS foret_id, ug_uuid::text AS ug_uuid
       FROM v_travaux WHERE id = $1",
    params = list(travaux_id)
  )
  if (nrow(travaux) == 0L) {
    stop("Les travaux ", travaux_id, " ne sont pas une intervention courante ",
         "du registre 6.", call. = FALSE)
  }
  ug <- travaux$ug_uuid[[1L]]
  if (est_vide(ug)) {
    stop("Les travaux ", travaux_id, " ne sont rattaches a aucune unite de ",
         "gestion : une placette suit des travaux dans une unite.",
         call. = FALSE)
  }
  pris <- DBI::dbGetQuery(
    con,
    "SELECT id::text AS id FROM v_placette
      WHERE ug_uuid = $1 AND code_placette = $2",
    params = list(ug, code_placette)
  )
  if (nrow(pris) > 0L) {
    stop("Le code ", code_placette, " est deja pris dans cette unite (",
         pris$id[[1L]], ").", call. = FALSE)
  }
  sommier_entree(
    foret_id = travaux$foret_id[[1L]],
    registre = 6L,
    date_evenement = date_evenement,
    auteur = auteur,
    ug_uuid = ug,
    ndp = 0L,
    id = id,
    payload = registre6_placette(code_placette, travaux_id, geometrie, ...)
  )
}

entree_controle <- function(con, placette_id, nb_total, nb_vivants, auteur,
                            visite_le = Sys.time(), id = uuid_v4(), ...) {
  placette_id <- valider_uuid(placette_id, "placette_id")
  visite_le <- format_instant(visite_le, "visite_le")
  jour <- substr(visite_le, 1L, 10L)
  placette <- DBI::dbGetQuery(
    con,
    "SELECT foret_id::text AS foret_id, ug_uuid::text AS ug_uuid
       FROM v_placette WHERE id = $1",
    params = list(placette_id)
  )
  if (nrow(placette) == 0L) {
    stop("Placette inconnue : ", placette_id, ".", call. = FALSE)
  }
  deja <- DBI::dbGetQuery(
    con,
    "SELECT id::text AS id FROM v_controle_plantation
      WHERE placette_id = $1 AND visite_le = $2::date",
    params = list(placette_id, jour)
  )
  if (nrow(deja) > 0L) {
    stop("La placette ", placette_id, " a deja ete controlee le ", jour,
         " (", deja$id[[1L]], ") : un comptage faux se rectifie.",
         call. = FALSE)
  }
  sommier_entree(
    foret_id = placette$foret_id[[1L]],
    registre = 6L,
    date_evenement = jour,
    auteur = auteur,
    ug_uuid = placette$ug_uuid[[1L]],
    ndp = 0L,
    id = id,
    payload = registre6_controle(placette_id, nb_total, nb_vivants,
                                 visite_le = visite_le, ...)
  )
}
