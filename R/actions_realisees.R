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
#' `<projet>-programme-travaux.gpkg` (nemetonshiny). Elle arrive au registre 6
#' en portant la meme `action_id` dans le champ `action_id` des travaux :
#' * par la reprise tableur, [sommier_reprendre_travaux()] : colonne
#'   `action_id` (voir [SOMMIER_COLONNES_TABLEUR_TRAVAUX]) ;
#' * par l'ecriture directe, `registre6_travaux(action_id = )` ;
#' * par la tournee QField, [sommier_importer_qfield_travaux()] reprend la
#'   colonne `action_id` des couches de travaux si le GeoPackage rapporte la
#'   porte. Le modele de projet QField distribue ne la porte pas encore : la
#'   lecture du programme dans la tournee reste a faire.
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
