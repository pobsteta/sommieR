#' Le realise des travaux, rendu au plan d'action de nemetonshiny
#'
#' @description
#' Ecrit, pour une foret et une periode, le CSV du realise : une ligne par
#' travaux recu au registre 6 qui porte une `action_id` du plan d'action de
#' nemetonshiny. C'est le fichier que le bouton "realise" du module Plan
#' d'action lit (`TOURNEE_REALISE_COLONNES` de nemetonshiny) ; sommieR en est
#' la seule source : nemetonshiny ne lit jamais les saisies du telephone.
#'
#' @details
#' **Le contrat**, exactement ces six colonnes, dans cet ordre : `action_id`,
#' `travaux_id` (l'identifiant de l'entree du registre 6), `code_travaux`,
#' `date_reception`, `quantite`, `unite`. UTF-8, separateur virgule, decimale
#' point, cellule vide pour une valeur absente. Une meme `action_id` revient
#' sur autant de lignes que de travaux recus : nemetonshiny regroupe et somme.
#'
#' **Un travaux recu** est une entree courante du registre 6 (une correction
#' remplace l'entree qu'elle corrige) dont la `date_reception` est renseignee.
#' Un travaux sans reception, ou sans `action_id`, n'y figure pas. La
#' periode borne la `date_reception`.
#'
#' **Le chemin de l'`action_id`.** L'action nait dans la couche `actions` de
#' `<projet>-programme-travaux.gpkg` (nemetonshiny), dont la colonne `id` est
#' l'`action_id` :
#' 1. [sommier_lire_programme_travaux()] lit cette couche ;
#' 2. `sommier_projet_qfield_travaux(programme = )` verse les actions dans la
#'    table `programme` du projet de tournee et offre leur liste au champ
#'    `action_id` des trois couches de travaux ;
#' 3. l'operateur choisit l'action en saisissant le travaux ;
#'    [sommier_importer_qfield_travaux()] refuse un `action_id` absent du
#'    programme et inscrit les travaux au registre 6 avec leur `action_id` ;
#' 4. `sommier_actions_realisees()` rend les travaux recus au plan.
#'
#' L'`action_id` entre aussi au registre 6 par la reprise tableur
#' ([sommier_reprendre_travaux()], colonne `action_id`, voir
#' [SOMMIER_COLONNES_TABLEUR_TRAVAUX]) et par l'ecriture directe,
#' `registre6_travaux(action_id = )`.
#'
#' @param con Connexion DBI.
#' @param foret_id UUID de la foret.
#' @param debut,fin Bornes de la periode, sur la date de reception
#'   (facultatives).
#' @param fichier Chemin du CSV a ecrire (facultatif).
#'
#' @return Invisiblement, le `data.frame` des six colonnes.
#'
#' @seealso [registre6_travaux()], [sommier_bilan_travaux()]
#'
#' @export
sommier_actions_realisees <- function(con, foret_id, debut = NULL, fin = NULL,
                                      fichier = NULL) {
  foret_id <- valider_uuid(foret_id, "foret_id")
  debut <- if (est_vide(debut)) "0001-01-01" else format_date(debut, "debut")
  fin <- if (est_vide(fin)) "9999-12-31" else format_date(fin, "fin")
  t <- DBI::dbGetQuery(
    con,
    "SELECT action_id, id::text AS travaux_id, code_travaux,
            to_char(date_reception, 'YYYY-MM-DD') AS date_reception,
            quantite::float8 AS quantite, unite
       FROM v_travaux
      WHERE foret_id = $1
        AND action_id IS NOT NULL AND date_reception IS NOT NULL
        AND date_reception BETWEEN $2::date AND $3::date
      ORDER BY date_reception, seq",
    params = parametres(list(foret_id, debut, fin))
  )
  t <- t[, COLONNES_ACTIONS_REALISEES, drop = FALSE]
  if (!est_vide(fichier)) ecrire_actions_realisees(t, fichier)
  invisible(t)
}

COLONNES_ACTIONS_REALISEES <- c("action_id", "travaux_id", "code_travaux",
                                "date_reception", "quantite", "unite")

# Le CSV du contrat : UTF-8, virgule, decimale point, vide pour l'absent.
ecrire_actions_realisees <- function(x, fichier) {
  utils::write.csv(x, fichier, row.names = FALSE, na = "",
                   fileEncoding = "UTF-8")
  invisible(fichier)
}

#' Lire le programme de travaux de nemetonshiny
#'
#' @description
#' Lit la couche `actions` de `<projet>-programme-travaux.gpkg`, tel que
#' l'ecrit `export_action_plan_gpkg()` de nemetonshiny : une ligne par action
#' du plan d'action, l'identifiant de l'action dans la colonne `id`. C'est le
#' point de depart du chemin de l'`action_id` : voir
#' [sommier_actions_realisees()].
#'
#' @param fichier Chemin du GeoPackage du programme.
#'
#' @return Un `data.frame` sans geometrie : `action_id` (la colonne `id` du
#'   programme), `ug_id`, puis celles des colonnes `type`, `annee_civile`,
#'   `surface_ha` et `statut` que le fichier porte.
#'
#' @seealso [sommier_projet_qfield_travaux()]
#'
#' @export
sommier_lire_programme_travaux <- function(fichier) {
  if (!requireNamespace("sf", quietly = TRUE)) {
    stop("Le paquet `sf` est requis pour lire le programme.", call. = FALSE)
  }
  fichier <- valider_texte(fichier, "fichier")
  if (!file.exists(fichier)) {
    stop("Programme de travaux introuvable : ", fichier, call. = FALSE)
  }
  if (!"actions" %in% sf::st_layers(fichier)$name) {
    stop("Pas de couche `actions` dans ", fichier, " : ce n'est pas le ",
         "programme exporte par nemetonshiny.", call. = FALSE)
  }
  x <- as.data.frame(suppressWarnings(sf::read_sf(fichier, layer = "actions")))
  if (!"id" %in% names(x)) {
    stop("La couche `actions` n'a pas de colonne `id`.", call. = FALSE)
  }
  x$id <- as.character(x$id)
  if (anyNA(x$id) || any(!nzchar(trimws(x$id)))) {
    stop("La couche `actions` porte des actions sans `id`.", call. = FALSE)
  }
  if (anyDuplicated(x$id)) {
    stop("La couche `actions` porte deux fois l'identifiant ",
         x$id[anyDuplicated(x$id)], ".", call. = FALSE)
  }
  x$action_id <- x$id
  if (!"ug_id" %in% names(x)) x$ug_id <- NA_character_
  x$ug_id <- as.character(x$ug_id)
  garde <- intersect(c("action_id", "ug_id", "type", "annee_civile",
                       "surface_ha", "statut"), names(x))
  x <- x[, garde, drop = FALSE]
  rownames(x) <- NULL
  x
}

# Ce que l'operateur lit dans la liste des actions : l'identifiant, l'unite,
# le type, l'annee civile et la surface.
libelle_action_programme <- function(x) {
  champ <- function(nom) {
    if (nom %in% names(x)) ifelse(is.na(x[[nom]]), "", as.character(x[[nom]]))
    else rep("", nrow(x))
  }
  surface <- champ("surface_ha")
  trimws(paste0(x$action_id, " - UG ", champ("ug_id"), " ", champ("type"),
                " ", champ("annee_civile"), " ",
                ifelse(nzchar(surface), paste0(surface, " ha"), "")))
}
