#' Contours des unites de gestion
#'
#' @description
#' Rend, pour une foret, la geometrie en vigueur a une date de chaque unite de
#' gestion active, en WKT.
#'
#' @details
#' Seule la version de geometrie en vigueur a la date demandee est rendue :
#' `ug_geometrie` est versionnee, et le contour d'une unite change avec les
#' revisions d'amenagement. Une carte editee pour une periode passee doit
#' montrer le parcellaire de l'epoque, non celui d'aujourd'hui.
#'
#' La geometrie sort en **WKT et en Lambert-93**, les deux volontairement.
#' Le WKT parce que `sf::st_as_sfc()` a une methode caractere pour lui, la ou
#' lire une geometrie GeoJSON nue dependrait du pilote GDAL ; le Lambert-93
#' parce qu'une carte se mesure en metres, et que reprojeter ici deformerait
#' les surfaces que la colonne `surface_ha` annonce.
#'
#' Une unite sans contour connu est **rendue avec un WKT `NA`** plutot
#' qu'omise : c'est a l'appelant de decider s'il la signale ou l'ignore, et
#' l'escamoter ici lui retirerait ce choix.
#'
#' @param con Connexion DBI.
#' @param foret_id UUID de la foret.
#' @param a_la_date Date de reference (defaut : aujourd'hui).
#'
#' @return Un `data.frame` : `uuid`, `numero_affichage`, `surface_ha`
#'   (calculee par PostGIS sur le contour, `NA` faute de contour), `wkt`.
#'
#' @seealso [sommier_indicateurs_ug()], [sommier_exporter_sig()]
#'
#' @examples
#' # Necessite une connexion :
#' # sommier_geometrie_ug(con, foret)
#'
#' @export
sommier_geometrie_ug <- function(con, foret_id, a_la_date = Sys.Date()) {
  foret_id <- valider_uuid(foret_id, "foret_id")
  a_la_date <- format_date(a_la_date, "a_la_date")

  DBI::dbGetQuery(
    con,
    "SELECT u.uuid, u.numero_affichage,
            round((ST_Area(g.geom) / 10000)::numeric, 2) AS surface_ha,
            ST_AsText(g.geom) AS wkt
       FROM ug u
       LEFT JOIN LATERAL (
         SELECT geom FROM ug_geometrie gg
          WHERE gg.ug_uuid = u.uuid
            AND gg.date_debut <= $2::date
            AND (gg.date_fin IS NULL OR gg.date_fin >= $2::date)
          ORDER BY gg.version DESC LIMIT 1
       ) g ON TRUE
      WHERE u.foret_id = $1
        AND u.date_debut <= $2::date
        AND (u.date_fin IS NULL OR u.date_fin >= $2::date)
      ORDER BY u.numero_affichage",
    params = parametres(list(foret_id, a_la_date))
  )
}

#' Indicateurs par unite de gestion
#'
#' @description
#' Agrege par unite de gestion, sur une periode, ce que le sommier permet de
#' porter sur une carte : entrees, volumes marteles, surfaces coupees,
#' travaux.
#'
#' @details
#' Les entrees **hors unite de gestion** (`ug_uuid` nul, imprime A50H pour les
#' travaux) sont exclues : elles ne se placent nulle part, et les compter dans
#' un total cartographie ferait mentir la carte sur ce qu'elle montre.
#'
#' Le volume martele exclut `coupe_realisee`, comme la balance de possibilite
#' : la meme coupe est d'abord martelee puis exploitee, l'imputer deux fois
#' doublerait le prelevement.
#'
#' Une unite sans aucune ecriture figure avec des zeros, non par son absence.
#' La distinction porte : une unite ou rien n'a ete fait n'est pas une unite
#' inconnue, et sur une carte choroplethe la premiere doit se teinter.
#'
#' @param con Connexion DBI.
#' @param foret_id UUID de la foret.
#' @param debut,fin Bornes de la periode (`NULL` : sans borne).
#'
#' @return Un `data.frame` : `uuid`, `n_entrees`, `volume_martele_m3`,
#'   `surface_coupee_ha`, `montant_travaux_eur`, `n_travaux`.
#'
#' @seealso [sommier_geometrie_ug()]
#'
#' @examples
#' # Necessite une connexion :
#' # sommier_indicateurs_ug(con, foret, "2016-01-01", "2025-12-31")
#'
#' @export
sommier_indicateurs_ug <- function(con, foret_id, debut = NULL, fin = NULL) {
  foret_id <- valider_uuid(foret_id, "foret_id")
  debut <- if (est_vide(debut)) "0001-01-01" else format_date(debut, "debut")
  fin <- if (est_vide(fin)) "9999-12-31" else format_date(fin, "fin")
  if (fin < debut) {
    stop("`fin` (", fin, ") precede `debut` (", debut, ").", call. = FALSE)
  }

  DBI::dbGetQuery(
    con,
    "SELECT u.uuid,
            coalesce(e.n_entrees, 0)           AS n_entrees,
            coalesce(c.volume_martele_m3, 0)   AS volume_martele_m3,
            coalesce(c.surface_coupee_ha, 0)   AS surface_coupee_ha,
            coalesce(t.montant_travaux_eur, 0) AS montant_travaux_eur,
            coalesce(t.n_travaux, 0)           AS n_travaux
       FROM ug u
       LEFT JOIN (
         SELECT ug_uuid, count(*) AS n_entrees
           FROM v_entree_courante
          WHERE foret_id = $1 AND ug_uuid IS NOT NULL
            AND date_evenement BETWEEN $2::date AND $3::date
          GROUP BY ug_uuid
       ) e ON e.ug_uuid = u.uuid
       LEFT JOIN (
         SELECT ug_uuid,
                SUM(volume_m3) FILTER (
                  WHERE type_entree <> 'coupe_realisee') AS volume_martele_m3,
                SUM(surface_ha) AS surface_coupee_ha
           FROM v_coupe
          WHERE foret_id = $1 AND ug_uuid IS NOT NULL
            AND date_evenement BETWEEN $2::date AND $3::date
          GROUP BY ug_uuid
       ) c ON c.ug_uuid = u.uuid
       LEFT JOIN (
         SELECT ug_uuid, SUM(montant_eur) AS montant_travaux_eur,
                count(*) AS n_travaux
           FROM v_travaux
          WHERE foret_id = $1 AND ug_uuid IS NOT NULL
            AND date_evenement BETWEEN $2::date AND $3::date
          GROUP BY ug_uuid
       ) t ON t.ug_uuid = u.uuid
      WHERE u.foret_id = $1
      ORDER BY u.numero_affichage",
    params = parametres(list(foret_id, debut, fin))
  )
}

#' Couche cartographique des unites de gestion
#'
#' @description
#' Rassemble [sommier_geometrie_ug()] et [sommier_indicateurs_ug()] en une
#' seule table, prete a etre portee sur une carte.
#'
#' @details
#' Le resultat porte l'attribut `unites_sans_geometrie` : les numeros
#' d'affichage des unites actives dont le contour est inconnu. Les cartes du
#' rapport s'en servent pour le dire au lecteur — une foret partiellement
#' cartographiee doit se declarer telle, sans quoi la carte laisse croire
#' qu'elle montre tout.
#'
#' @inheritParams sommier_indicateurs_ug
#' @param a_la_date Date de reference des contours (defaut : la borne `fin`
#'   si elle est donnee, sinon aujourd'hui). Ce defaut n'est pas cosmetique :
#'   une carte qui accompagne un bilan de periode doit montrer le parcellaire
#'   de la fin de cette periode, non celui du jour de l'edition.
#'
#' @return Un `data.frame` des unites avec contour, joint de leurs
#'   indicateurs, portant l'attribut `unites_sans_geometrie`.
#'
#' @examples
#' # Necessite une connexion :
#' # sommier_couche_ug(con, foret, "2016-01-01", "2025-12-31")
#'
#' @export
sommier_couche_ug <- function(con, foret_id, debut = NULL, fin = NULL,
                              a_la_date = NULL) {
  if (est_vide(a_la_date)) {
    a_la_date <- if (est_vide(fin)) Sys.Date() else fin
  }
  geometries <- sommier_geometrie_ug(con, foret_id, a_la_date = a_la_date)
  indicateurs <- sommier_indicateurs_ug(con, foret_id, debut = debut,
                                        fin = fin)

  sans <- geometries$numero_affichage[is.na(geometries$wkt)]
  couche <- merge(
    geometries[!is.na(geometries$wkt), , drop = FALSE],
    indicateurs, by = "uuid", all.x = TRUE, sort = FALSE
  )
  couche <- couche[order(couche$numero_affichage), , drop = FALSE]
  rownames(couche) <- NULL
  attr(couche, "unites_sans_geometrie") <- sans
  couche
}
