#' Referentiels d'export de la gestion anterieure
#'
#' @description
#' * `psg` : section « gestion anterieure » du plan simple de gestion
#'   (bloc 3 de l'arrete du 19 juillet 2012).
#' * `amenagement` : bilan de l'amenagement precedent (partie 2 du document
#'   d'amenagement ONF).
#' * `ct88` : evaluation de fin de plan (etape 5 du CT88).
#'
#' @export
SOMMIER_REFERENTIELS <- c("psg", "amenagement", "ct88")

#' Gestion anterieure : coupes, travaux, evenements et comptes
#'
#' @description
#' Assemble, sur une periode, ce que les trois referentiels reclament sous des
#' noms differents. Le brief le dit : « les trois se generent depuis les memes
#' registres ». Il y a donc **un seul assemblage** et trois presentations, et
#' non trois extractions paralleles qui divergeraient a la premiere evolution.
#'
#' @details
#' Ce que chaque referentiel retient :
#'
#' | Section | psg | amenagement | ct88 |
#' | --- | :-: | :-: | :-: |
#' | Provenance des ecritures | oui | oui | oui |
#' | Coupes realisees et balance | oui | oui | oui |
#' | Travaux realises | oui | oui | oui |
#' | Evenements marquants | oui | oui | oui |
#' | Bilan financier | non | oui | oui |
#' | Equilibre foret-gibier | oui | oui | non |
#' | Patrimoine remarquable | oui | oui | non |
#'
#' Le PSG ne demande pas le detail financier, que le proprietaire n'a pas a
#' produire au CRPF ; le CT88, tourne vers l'evaluation d'un contrat, ne
#' reclame pas l'inventaire du patrimoine remarquable. Restreindre la sortie a
#' ce qui est demande evite de diffuser plus que necessaire - les registres 3
#' et 7 portent des donnees personnelles.
#'
#' **Constate et transcrit ne se melent pas.** Les trois referentiels portent
#' sur une periode ecoulee ; un sommier ouvert en cours de route ne la couvre
#' donc qu'en partie par ses propres constats, le reste ayant ete transcrit de
#' l'existant (voir [sommier_reprise()]). Les tableaux de coupes et de travaux
#' portent pour cette raison une colonne `provenance`, et la section
#' `provenance` compte registre par registre ce qui a ete constate et ce qui a
#' ete recopie. Un tableau qui les additionnerait sans le dire ferait passer
#' la recopie pour de la mesure.
#'
#' @param con Connexion DBI.
#' @param foret_id UUID de la foret.
#' @param debut,fin Bornes de la periode (`Date` ou `"AAAA-MM-JJ"`). Par
#'   defaut, tout le sommier.
#' @param referentiel L'un de [SOMMIER_REFERENTIELS].
#'
#' @return Un objet de classe `sommier_gestion_anterieure` : liste de sections,
#'   chacune un `data.frame`, plus les metadonnees de periode et de foret.
#'
#' @seealso [sommier_rapport_markdown()]
#' @export
sommier_gestion_anterieure <- function(con, foret_id, debut = NULL, fin = NULL,
                                       referentiel = "psg") {
  foret_id <- valider_uuid(foret_id, "foret_id")
  referentiel <- valider_choix(referentiel, "referentiel", SOMMIER_REFERENTIELS)
  debut <- if (est_vide(debut)) "0001-01-01" else format_date(debut, "debut")
  fin <- if (est_vide(fin)) "9999-12-31" else format_date(fin, "fin")
  if (fin < debut) {
    stop("`fin` (", fin, ") precede `debut` (", debut, ").", call. = FALSE)
  }

  foret <- DBI::dbGetQuery(
    con, "SELECT nom, regime, surface_ha FROM foret WHERE id = $1",
    params = parametres(list(foret_id))
  )
  if (nrow(foret) == 0L) {
    stop("Foret inconnue : ", foret_id, ".", call. = FALSE)
  }

  # `lire()` borne sur la periode ; `lire_etat()` ne prend que la foret. La
  # distinction n'est pas cosmetique : le patrimoine remarquable est un etat
  # courant et non un releve de periode - le borner ecarterait un arbre
  # inventorie avant la periode, alors que le document de gestion veut
  # l'inventaire tel qu'il est aujourd'hui.
  bornes <- parametres(list(foret_id, debut, fin))
  lire <- function(sql) DBI::dbGetQuery(con, sql, params = bornes)
  lire_etat <- function(sql) {
    DBI::dbGetQuery(con, sql, params = parametres(list(foret_id)))
  }

  sections <- list(
    provenance = sommier_provenance(con, foret_id, debut = debut, fin = fin),
    coupes = lire(
      "SELECT exercice, type_entree, nature_coupe,
              CASE WHEN repris THEN 'transcrit' ELSE 'constate' END AS provenance,
              SUM(volume_m3) AS volume_m3, SUM(surface_ha) AS surface_ha,
              count(*) AS n
         FROM v_coupe
        WHERE foret_id = $1 AND date_evenement BETWEEN $2::date AND $3::date
        GROUP BY exercice, type_entree, nature_coupe, repris
        ORDER BY exercice, type_entree, nature_coupe, repris"),
    balance = lire(
      "SELECT exercice, possibilite_m3_an, volume_martele_m3,
              balance_exercice_m3, balance_cumulee_m3
         FROM v_balance_possibilite
        WHERE foret_id = $1
          AND exercice BETWEEN EXTRACT(YEAR FROM $2::date)
                           AND EXTRACT(YEAR FROM $3::date)
        ORDER BY exercice"),
    travaux = lire(
      "SELECT annee, nature_travaux,
              CASE WHEN repris THEN 'transcrit' ELSE 'constate' END AS provenance,
              SUM(quantite) AS quantite,
              max(unite) AS unite, SUM(montant_eur) AS montant_eur,
              avg(taux_reprise_pct) AS taux_reprise_moyen_pct, count(*) AS n
         FROM v_travaux
        WHERE foret_id = $1 AND date_evenement BETWEEN $2::date AND $3::date
        GROUP BY annee, nature_travaux, repris
        ORDER BY annee, nature_travaux, repris"),
    evenements = lire(
      "SELECT date_evenement, nature, description, surface_ha,
              volume_impacte_m3, ndp
         FROM v_evenement
        WHERE foret_id = $1 AND date_evenement BETWEEN $2::date AND $3::date
          AND type_entree = 'phenomene'
        ORDER BY date_evenement")
  )

  if (referentiel %in% c("amenagement", "ct88")) {
    sections$finances <- lire(
      "SELECT exercice, recettes_eur, depenses_eur, solde_eur, solde_cumule_eur
         FROM v_bilan_financier
        WHERE foret_id = $1
          AND exercice BETWEEN EXTRACT(YEAR FROM $2::date)
                           AND EXTRACT(YEAR FROM $3::date)
        ORDER BY exercice")
  }
  if (referentiel %in% c("psg", "amenagement")) {
    sections$equilibre_gibier <- lire(
      "SELECT saison, surface_sensible_ha, taux_abroutissement_pct, diagnostic
         FROM v_equilibre_gibier
        WHERE foret_id = $1 AND date_evenement BETWEEN $2::date AND $3::date
        ORDER BY saison")
    sections$patrimoine <- lire_etat(
      "SELECT type_fiche, appellation, nom_latin, type_habitat, surface_ha,
              etat_sanitaire, statut_protection
         FROM v_remarquable_dernier_releve
        WHERE foret_id = $1
        ORDER BY type_fiche, appellation")
  }

  structure(
    list(
      foret_id = foret_id,
      foret = foret$nom[[1L]],
      regime = foret$regime[[1L]],
      surface_ha = foret$surface_ha[[1L]],
      referentiel = referentiel,
      debut = debut,
      fin = fin,
      sections = sections
    ),
    class = "sommier_gestion_anterieure"
  )
}

#' @export
print.sommier_gestion_anterieure <- function(x, ...) {
  cat("<gestion anterieure - ", x$referentiel, ">\n", sep = "")
  cat("  foret   : ", x$foret, " (", x$regime, ")\n", sep = "")
  cat("  periode : ", x$debut, " a ", x$fin, "\n", sep = "")
  for (nom in names(x$sections)) {
    cat("  ", nom, " : ", nrow(x$sections[[nom]]), " ligne(s)\n", sep = "")
  }
  invisible(x)
}

#' Rendu Markdown de la gestion anterieure
#'
#' @description
#' Met en forme le resultat de [sommier_gestion_anterieure()] en Markdown,
#' pret a etre colle dans un document de gestion ou converti.
#'
#' @details
#' Le rendu est du Markdown et non un formulaire officiel : la mise en page
#' reglementaire appartient a l'outil de redaction du document de gestion, et
#' la reproduire ici la figerait sur une version des textes. Ce qui est fourni,
#' c'est le contenu exige, structure et etiquete.
#'
#' @param x Objet `sommier_gestion_anterieure`.
#' @param chemin Fichier de destination (facultatif : la chaine est rendue si
#'   absent).
#' @return Invisiblement, le Markdown produit.
#'
#' @export
sommier_rapport_markdown <- function(x, chemin = NULL) {
  if (!inherits(x, "sommier_gestion_anterieure")) {
    stop("`x` doit venir de sommier_gestion_anterieure().", call. = FALSE)
  }
  titres <- c(
    provenance = "Provenance des ecritures",
    coupes = "Coupes realisees", balance = "Balance de possibilite",
    travaux = "Travaux realises", evenements = "Evenements marquants",
    finances = "Bilan financier", equilibre_gibier = "Equilibre foret-gibier",
    patrimoine = "Patrimoine remarquable"
  )
  entete <- c(
    paste0("# Gestion anterieure - ", x$foret),
    "",
    paste0("- Regime : ", x$regime),
    paste0("- Surface : ", if (is.na(x$surface_ha)) "non renseignee" else
           paste0(x$surface_ha, " ha")),
    paste0("- Periode : ", x$debut, " a ", x$fin),
    paste0("- Referentiel : ", x$referentiel),
    ""
  )
  corps <- unlist(lapply(names(x$sections), function(nom) {
    c(paste0("## ", titres[[nom]] %||% nom), "",
      markdown_tableau(x$sections[[nom]]), "")
  }))
  texte <- paste(c(entete, corps), collapse = "\n")
  if (!is.null(chemin)) {
    writeLines(texte, chemin, useBytes = TRUE)
  }
  invisible(texte)
}

# Table Markdown depuis un data.frame. Une section vide se dit, elle ne se
# rend pas par un tableau sans ligne : « aucune ecriture » est une information.
markdown_tableau <- function(df) {
  if (nrow(df) == 0L) {
    return("*Aucun enregistrement sur la periode.*")
  }
  cellule <- function(v) {
    v <- ifelse(is.na(v), "", format(v, trim = TRUE, scientific = FALSE))
    gsub("|", "\\|", v, fixed = TRUE)
  }
  lignes <- apply(as.data.frame(lapply(df, cellule), stringsAsFactors = FALSE),
                  1L, function(l) paste0("| ", paste(l, collapse = " | "), " |"))
  c(paste0("| ", paste(names(df), collapse = " | "), " |"),
    paste0("|", paste(rep(" --- ", ncol(df)), collapse = "|"), "|"),
    unname(lignes))
}
