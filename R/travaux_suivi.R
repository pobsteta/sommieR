#' Seuil de reprise d'une plantation
#'
#' @description
#' Taux de reprise, en pourcentage, sous lequel une plantation appelle un
#' regarni. Le rapport le trace en trait sur la courbe de reprise par age.
#'
#' @export
SOMMIER_SEUIL_REPRISE_PCT <- 80

#' Suivi des plantations
#'
#' @description
#' Rend, par unite de gestion, par plantation suivie et par age, ce que les
#' placettes ont mesure : taux de reprise, densite a l'hectare, hauteur et
#' part d'abroutis, en moyenne des placettes controlees a cet age, et les
#' besoins qu'elles ont signales.
#'
#' @details
#' Un etat courant, comme les limites : il n'est pas borne par une periode.
#' Les valeurs viennent de `v_controle_plantation`, qui les calcule depuis les
#' comptages ; rien n'y est saisi. Une plantation controlee deux fois la meme
#' annee (deux placettes a des jours differents) donne une ligne : l'age est
#' en annees.
#'
#' @param con Connexion DBI.
#' @param foret_id UUID de la foret.
#'
#' @return Un `data.frame` : `ug`, `travaux_id`, `annee_travaux`,
#'   `code_travaux`, `age_ans`, `annee_controle`, `n_placettes`,
#'   `taux_reprise_pct`, `densite_ha`, `h_moy_cm`, `abroutis_pct`, `besoins`
#'   (codes signales, hors `aucun`, separes par une virgule ; `NA` s'il n'y en
#'   a pas).
#'
#' @seealso [sommier_controler_placette()], [sommier_bilan_travaux()]
#'
#' @export
sommier_suivi_plantations <- function(con, foret_id) {
  foret_id <- valider_uuid(foret_id, "foret_id")
  DBI::dbGetQuery(
    con,
    "SELECT u.numero_affichage AS ug, c.travaux_id::text AS travaux_id,
            c.annee_travaux, c.code_travaux, c.age_ans,
            min(EXTRACT(YEAR FROM c.visite_le))::integer AS annee_controle,
            count(DISTINCT c.placette_id)::integer AS n_placettes,
            round(avg(c.taux_reprise_pct), 1)::float8 AS taux_reprise_pct,
            round(avg(c.densite_ha), 0)::float8 AS densite_ha,
            round(avg(c.h_moy_cm), 0)::float8 AS h_moy_cm,
            round(avg(c.abroutis_pct), 1)::float8 AS abroutis_pct,
            string_agg(DISTINCT c.besoin, ', ' ORDER BY c.besoin)
              FILTER (WHERE c.besoin <> 'aucun') AS besoins
       FROM v_controle_plantation c
       LEFT JOIN ug u ON u.uuid = c.ug_uuid
      WHERE c.foret_id = $1
      GROUP BY u.numero_affichage, c.travaux_id, c.annee_travaux,
               c.code_travaux, c.age_ans
      ORDER BY u.numero_affichage, c.annee_travaux, c.age_ans",
    params = parametres(list(foret_id))
  )
}

#' Bilan des travaux : cout a l'hectare et ecart au prevu
#'
#' @description
#' Rend ce que les travaux ont coute, unite par unite et famille par famille,
#' rapporte a la surface de l'unite ; et, annee par annee, les hectares
#' traites selon qu'ils etaient prevus, reportes ou non prevus.
#'
#' @details
#' **La famille** vient du code ([SOMMIER_CODES_TRAVAUX]) ; une intervention
#' sans code, inscrite avant la v0.28.0, est rangee "non codee".
#'
#' **Le cout a l'hectare** rapporte le montant cumule d'une unite a la surface
#' de son contour en vigueur. Les travaux hors unite de gestion (une desserte)
#' sont comptes a part, sans hectare.
#'
#' **Les hectares** d'une intervention sont sa quantite quand elle est en
#' hectares, a defaut l'aire de sa geometrie quand c'en est une surface ; une
#' intervention mesuree autrement (des metres de cloture, des tiges) n'en a
#' pas, et le dit.
#'
#' @param con Connexion DBI.
#' @param foret_id UUID de la foret.
#' @param debut,fin Bornes de la periode, sur la date de l'intervention.
#'
#' @return Une liste : `cout` (`ug`, `famille`, `montant_eur`, `surface_ug_ha`,
#'   `cout_ha_eur`, `n`), `prevu` (`annee`, `prevu`, `hectares`, `n`,
#'   `n_sans_hectares`), et `hors_ug_eur` (montant des travaux hors unite).
#'
#' @seealso [sommier_suivi_plantations()]
#'
#' @export
sommier_bilan_travaux <- function(con, foret_id, debut = NULL, fin = NULL) {
  foret_id <- valider_uuid(foret_id, "foret_id")
  debut <- if (est_vide(debut)) "0001-01-01" else format_date(debut, "debut")
  fin <- if (est_vide(fin)) "9999-12-31" else format_date(fin, "fin")
  t <- DBI::dbGetQuery(
    con,
    "SELECT t.annee, u.numero_affichage AS ug, t.code_travaux,
            coalesce(t.prevu, 'non_renseigne') AS prevu,
            t.montant_eur::float8 AS montant_eur,
            CASE WHEN t.unite = 'ha' THEN t.quantite::float8
                 WHEN GeometryType(e.geom) IN ('POLYGON', 'MULTIPOLYGON')
                   THEN ST_Area(e.geom) / 10000 END AS hectares,
            (SELECT ST_Area(g.geom) / 10000 FROM ug_geometrie g
              WHERE g.ug_uuid = t.ug_uuid
              ORDER BY (g.date_fin IS NULL) DESC, g.version DESC LIMIT 1)
              AS surface_ug_ha
       FROM v_travaux t
       JOIN entree_sommier e ON e.id = t.id
       LEFT JOIN ug u ON u.uuid = t.ug_uuid
      WHERE t.foret_id = $1
        AND t.date_evenement BETWEEN $2::date AND $3::date",
    params = parametres(list(foret_id, debut, fin))
  )
  t$famille <- SOMMIER_CODES_TRAVAUX$famille[
    match(t$code_travaux, SOMMIER_CODES_TRAVAUX$code)]
  t$famille[is.na(t$famille)] <- "non_codee"

  dans_ug <- t[!is.na(t$ug), , drop = FALSE]
  cout <- if (nrow(dans_ug) == 0L) {
    data.frame(ug = character(0), famille = character(0),
               montant_eur = numeric(0), surface_ug_ha = numeric(0),
               cout_ha_eur = numeric(0), n = integer(0))
  } else {
    cles <- unique(dans_ug[, c("ug", "famille")])
    cles <- cles[order(cles$ug, cles$famille), , drop = FALSE]
    do.call(rbind, lapply(seq_len(nrow(cles)), function(i) {
      x <- dans_ug[dans_ug$ug == cles$ug[[i]] &
                     dans_ug$famille == cles$famille[[i]], , drop = FALSE]
      montant <- sum(x$montant_eur, na.rm = TRUE)
      surface <- x$surface_ug_ha[[1L]]
      data.frame(ug = cles$ug[[i]], famille = cles$famille[[i]],
                 montant_eur = montant, surface_ug_ha = surface,
                 cout_ha_eur = if (is.na(surface) || surface == 0) NA_real_
                   else montant / surface,
                 n = nrow(x), stringsAsFactors = FALSE)
    }))
  }
  rownames(cout) <- NULL

  cles <- unique(t[, c("annee", "prevu")])
  cles <- cles[order(cles$annee, cles$prevu), , drop = FALSE]
  prevu <- if (nrow(cles) == 0L) {
    data.frame(annee = integer(0), prevu = character(0), hectares = numeric(0),
               n = integer(0), n_sans_hectares = integer(0))
  } else {
    do.call(rbind, lapply(seq_len(nrow(cles)), function(i) {
      x <- t[t$annee == cles$annee[[i]] & t$prevu == cles$prevu[[i]], ,
             drop = FALSE]
      data.frame(annee = as.integer(cles$annee[[i]]), prevu = cles$prevu[[i]],
                 hectares = sum(x$hectares, na.rm = TRUE), n = nrow(x),
                 n_sans_hectares = sum(is.na(x$hectares)),
                 stringsAsFactors = FALSE)
    }))
  }
  rownames(prevu) <- NULL

  list(cout = cout, prevu = prevu,
       hors_ug_eur = sum(t$montant_eur[is.na(t$ug)], na.rm = TRUE))
}

# Les placettes dont le dernier controle signale un besoin : ce qu'il reste a
# programmer. Un etat courant, sans borne de periode.
placettes_a_programmer <- function(con, foret_id) {
  DBI::dbGetQuery(
    con,
    "SELECT u.numero_affichage AS ug, d.code_placette, d.visite_le,
            d.age_ans, d.taux_reprise_pct::float8 AS taux_reprise_pct,
            d.abroutis_pct::float8 AS abroutis_pct, d.concurrence, d.besoin
       FROM (SELECT DISTINCT ON (placette_id) *
               FROM v_controle_plantation
              WHERE foret_id = $1
              ORDER BY placette_id, visite_le DESC, seq DESC) d
       LEFT JOIN ug u ON u.uuid = d.ug_uuid
      WHERE d.besoin IS NOT NULL AND d.besoin <> 'aucun'
      ORDER BY u.numero_affichage, d.code_placette",
    params = parametres(list(foret_id))
  )
}
