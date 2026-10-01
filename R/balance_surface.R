#' Natures de coupe qui ouvrent une surface en regeneration
#'
#' @description
#' La nature d'une coupe est un texte libre du registre 5. Une coupe ouvre une
#' surface en regeneration quand sa nature contient l'un de ces mots, une fois
#' mise en minuscules, sans accents, les espaces et tirets changes en `_` :
#' « Coupe de regeneration », « ensemencement », « secondaire »,
#' « definitive », « coupe rase ».
#'
#' @export
SOMMIER_NATURES_REGENERATION <- c("regeneration", "ensemencement",
                                  "secondaire", "definitive", "coupe_rase")

#' Balance en surface : la regeneration ouverte contre la regeneration prevue
#'
#' @description
#' Pour les amenagements qui fixent une surface a ouvrir en regeneration -
#' c'est ce que fixent les arretes recents de l'ONF, plus que des volumes -,
#' confronte exercice par exercice la surface ouverte par les martelages de
#' regeneration a la surface prevue, et en cumule l'ecart.
#'
#' @details
#' **Prevue.** La surface a regenerer de la periode
#' (`surface_regeneration_ha`, celle du dernier avenant qui la revise),
#' repartie egalement sur les exercices de l'amenagement. L'arrete fixe un
#' total, pas un calendrier : le rythme regulier n'est qu'un repere.
#'
#' **Ouverte.** La surface des martelages dont la nature releve de
#' `natures` (voir [SOMMIER_NATURES_REGENERATION]). Une unite ne s'ouvre
#' qu'une fois : une coupe secondaire puis definitive sur la meme parcelle
#' n'ouvrent pas deux fois la meme surface. Des surfaces partielles saisies -
#' 7,2 ha d'une parcelle de 39 - s'additionnent d'un exercice a l'autre, sans
#' depasser la surface de l'unite. Un martelage sans surface saisie parcourt
#' son unite (voir `v_coupe`).
#'
#' **L'ecart se cumule par amenagement**, jusqu'a l'exercice courant, comme
#' la balance en volume. Un ecart negatif est un retard de regeneration.
#'
#' @param con Connexion DBI.
#' @param foret_id UUID de la foret.
#' @param natures Natures de coupe qui ouvrent une surface en regeneration.
#'
#' @return Un `data.frame` : `amenagement_id`, `amenagement`, `exercice`,
#'   `surface_prevue_ha`, `surface_ouverte_ha`, `ecart_ha`, `ecart_cumule_ha`,
#'   `surface_regeneration_ha` (le total de la periode). Vide si aucun
#'   amenagement ne fixe de surface a regenerer.
#'
#' @seealso [sommier_balance_possibilite()], [sommier_amenagement()]
#'
#' @export
sommier_balance_surface <- function(con, foret_id,
                                    natures = SOMMIER_NATURES_REGENERATION) {
  foret_id <- valider_uuid(foret_id, "foret_id")
  natures <- normaliser_nature(valider_liste_texte(natures, "natures"))
  amenagements <- DBI::dbGetQuery(
    con,
    "SELECT amenagement_id, libelle, annee_debut, annee_fin,
            surface_regeneration_ha
       FROM v_amenagement
      WHERE foret_id = $1 AND surface_regeneration_ha IS NOT NULL
        AND annee_fin >= annee_debut
      ORDER BY annee_debut",
    params = list(foret_id)
  )
  vide <- data.frame(amenagement_id = character(0), amenagement = character(0),
                     exercice = integer(0), surface_prevue_ha = numeric(0),
                     surface_ouverte_ha = numeric(0), ecart_ha = numeric(0),
                     ecart_cumule_ha = numeric(0),
                     surface_regeneration_ha = numeric(0),
                     stringsAsFactors = FALSE)
  if (nrow(amenagements) == 0L) {
    return(vide)
  }
  coupes <- DBI::dbGetQuery(
    con,
    "SELECT c.ug_uuid::text AS ug, c.exercice, c.seq, c.nature_coupe,
            c.surface_ha,
            (SELECT ST_Area(g.geom) / 10000 FROM ug_geometrie g
              WHERE g.ug_uuid = c.ug_uuid
              ORDER BY g.version DESC LIMIT 1) AS surface_unite_ha
       FROM v_coupe c
      WHERE c.foret_id = $1 AND c.type_entree = 'martelage'
      ORDER BY c.exercice, c.seq",
    params = list(foret_id)
  )
  motif <- paste0("(^|_)(", paste(natures, collapse = "|"), ")(_|$)")
  coupes <- coupes[grepl(motif, normaliser_nature(coupes$nature_coupe)) &
                     !is.na(coupes$surface_ha), , drop = FALSE]
  coupes$exercice <- as.integer(coupes$exercice)
  coupes$surface_ha <- as.numeric(coupes$surface_ha)
  coupes$surface_unite_ha <- as.numeric(coupes$surface_unite_ha)
  courant <- as.integer(format(Sys.Date(), "%Y"))

  lignes <- lapply(seq_len(nrow(amenagements)), function(i) {
    a <- amenagements[i, ]
    debut <- as.integer(a$annee_debut)
    fin <- as.integer(a$annee_fin)
    leurs <- coupes[coupes$exercice >= debut & coupes$exercice <= fin, ,
                    drop = FALSE]
    dernier <- min(fin, max(courant, leurs$exercice, debut - 1L))
    if (dernier < debut) {
      return(NULL)
    }
    exercices <- debut:dernier
    ouverte <- surface_ouverte(leurs, exercices)
    prevue <- as.numeric(a$surface_regeneration_ha) / (fin - debut + 1L)
    ecart <- ouverte - prevue
    data.frame(amenagement_id = a$amenagement_id,
               amenagement = if (is.na(a$libelle)) a$amenagement_id else
                 a$libelle,
               exercice = exercices, surface_prevue_ha = prevue,
               surface_ouverte_ha = ouverte, ecart_ha = ecart,
               ecart_cumule_ha = cumsum(ecart),
               surface_regeneration_ha = as.numeric(a$surface_regeneration_ha),
               stringsAsFactors = FALSE)
  })
  lignes <- lignes[!vapply(lignes, is.null, logical(1))]
  if (length(lignes) == 0L) vide else do.call(rbind, lignes)
}

# ---------------------------------------------------------------------------

# Ce qu'ouvre chaque exercice : la surface nouvelle de chaque unite, plafonnee
# a l'unite. Un martelage sans unite ouvre ce qu'il dit.
surface_ouverte <- function(coupes, exercices) {
  ouverte <- stats::setNames(numeric(length(exercices)), exercices)
  deja <- list()
  for (k in seq_len(nrow(coupes))) {
    c <- coupes[k, ]
    ajout <- c$surface_ha
    if (!is.na(c$ug)) {
      avant <- deja[[c$ug]] %||% 0
      plafond <- if (is.na(c$surface_unite_ha)) Inf else c$surface_unite_ha
      apres <- min(plafond, avant + c$surface_ha)
      ajout <- max(0, apres - avant)
      deja[[c$ug]] <- apres
    }
    cle <- as.character(c$exercice)
    if (cle %in% names(ouverte)) ouverte[[cle]] <- ouverte[[cle]] + ajout
  }
  unname(ouverte)
}

normaliser_nature <- function(x) {
  x <- tolower(iconv(as.character(x), from = "UTF-8", to = "ASCII//TRANSLIT"))
  gsub("[^a-z0-9]+", "_", x)
}
