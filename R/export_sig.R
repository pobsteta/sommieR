#' Formats d'export cartographique
#'
#' @description
#' `geojson` n'exige rien de plus que PostGIS : la geometrie est rendue par
#' `ST_AsGeoJSON` et assemblee en R. `gpkg` passe par le paquet `sf`, qui doit
#' etre installe.
#'
#' Le brief prevoit a terme un GeoPackage accompagne du manifeste
#' ([sommier_exporter_manifeste()]). Le GeoJSON est propose en plus parce
#' qu'il ne demande aucune dependance : un destinataire peut ouvrir l'export
#' sans installer quoi que ce soit, ce qui sert le « partage sans confiance »
#' recherche.
#'
#' @export
SOMMIER_FORMATS_SIG <- c("geojson", "gpkg")

#' Export cartographique des unites de gestion
#'
#' @description
#' Exporte les unites de gestion et leur geometrie courante, enrichies du
#' nombre d'entrees de sommier qui s'y rattachent.
#'
#' @details
#' Seule la version de geometrie en vigueur a la date demandee est exportee.
#' Une unite sans geometrie connue est **omise de la couche mais signalee** :
#' la faire figurer sans contour serait une entite fantome dans le SIG, et
#' l'omettre en silence laisserait croire que la foret est entierement
#' cartographiee.
#'
#' L'export cartographique ne remplace pas le manifeste : la valeur probante
#' est dans la chaine, que [sommier_exporter_manifeste()] transporte. Les deux
#' se completent, et le destinataire verifie l'un avant de lire l'autre.
#'
#' @param con Connexion DBI.
#' @param foret_id UUID de la foret.
#' @param chemin Fichier de destination.
#' @param format L'un de [SOMMIER_FORMATS_SIG].
#' @param a_la_date Date de reference pour la version de geometrie et
#'   l'activite des unites (defaut : aujourd'hui).
#'
#' @return Invisiblement, une liste : `chemin`, `n_unites`,
#'   `unites_sans_geometrie` (leurs numeros d'affichage).
#'
#' @export
sommier_exporter_sig <- function(con, foret_id, chemin, format = "geojson",
                                 a_la_date = Sys.Date()) {
  foret_id <- valider_uuid(foret_id, "foret_id")
  format <- valider_choix(format, "format", SOMMIER_FORMATS_SIG)
  a_la_date <- format_date(a_la_date, "a_la_date")

  unites <- DBI::dbGetQuery(
    con,
    "SELECT u.uuid, u.numero_affichage, u.date_debut, u.date_fin,
            (SELECT count(*) FROM entree_sommier e WHERE e.ug_uuid = u.uuid)
              AS n_entrees,
            ST_AsGeoJSON(g.geom) AS geometrie,
            ST_AsText(g.geom)    AS geometrie_wkt
       FROM ug u
       LEFT JOIN LATERAL (
         SELECT geom FROM ug_geometrie gg
          WHERE gg.ug_uuid = u.uuid
            AND gg.date_debut <= $2::date
            AND (gg.date_fin IS NULL OR gg.date_fin >= $2::date)
          ORDER BY gg.version DESC LIMIT 1
       ) g ON TRUE
      WHERE u.foret_id = $1
        AND (u.date_fin IS NULL OR u.date_fin >= $2::date)
      ORDER BY u.numero_affichage",
    params = parametres(list(foret_id, a_la_date))
  )

  sans_geometrie <- unites$numero_affichage[is.na(unites$geometrie)]
  avec <- unites[!is.na(unites$geometrie), , drop = FALSE]

  if (identical(format, "geojson")) {
    ecrire_geojson(avec, chemin)
  } else {
    ecrire_geopackage(avec, chemin)
  }

  invisible(list(chemin = chemin, n_unites = nrow(avec),
                 unites_sans_geometrie = sans_geometrie))
}

ecrire_geojson <- function(unites, chemin) {
  entites <- lapply(seq_len(nrow(unites)), function(i) {
    list(
      type = "Feature",
      properties = list(
        uuid = unites$uuid[[i]],
        numero_affichage = unites$numero_affichage[[i]],
        date_debut = as.character(unites$date_debut[[i]]),
        n_entrees = as.integer(unites$n_entrees[[i]])
      ),
      # La geometrie vient deja en JSON de PostGIS : la reserialiser la
      # deformerait, on l'insere telle quelle.
      geometry = structure(unites$geometrie[[i]], class = "json")
    )
  })
  collection <- list(
    type = "FeatureCollection",
    name = "unites_de_gestion",
    features = entites
  )
  writeLines(
    jsonlite::toJSON(collection, auto_unbox = TRUE, null = "null",
                     na = "null", json_verbatim = TRUE, pretty = TRUE),
    chemin, useBytes = TRUE
  )
  invisible(chemin)
}

ecrire_geopackage <- function(unites, chemin) {
  if (!requireNamespace("sf", quietly = TRUE)) {
    stop("Le paquet `sf` est requis pour ecrire un GeoPackage ; l'installer, ",
         "ou choisir format = \"geojson\", qui n'exige aucune dependance.",
         call. = FALSE)
  }
  if (nrow(unites) == 0L) {
    stop("Aucune unite de gestion avec geometrie : rien a ecrire.", call. = FALSE)
  }
  # Conversion depuis le WKT et non depuis le GeoJSON : `st_as_sfc()` a une
  # methode caractere pour le WKT, la ou lire une geometrie GeoJSON nue
  # dependrait du pilote GDAL et de sa tolerance aux fragments sans enveloppe
  # Feature.
  geometries <- sf::st_as_sfc(unites$geometrie_wkt, crs = 2154)
  couche <- sf::st_sf(
    uuid = unites$uuid,
    numero_affichage = unites$numero_affichage,
    n_entrees = as.integer(unites$n_entrees),
    geometry = geometries
  )
  sf::st_write(couche, chemin, layer = "unites_de_gestion",
               delete_dsn = TRUE, quiet = TRUE)
  invisible(chemin)
}
