#' Nom de la foret du jeu de demonstration de Marsannay
#'
#' Comme [NOM_FORET_DEMO], le nom porte la mention « jeu de demonstration »
#' pour qu'aucune lecture de la base ne prenne ces ecritures pour reelles.
#'
#' @export
NOM_FORET_DEMO_MARSANNAY <-
  "Foret communale de Marsannay-la-Cote (jeu de demonstration)"

#' Parcelles du jeu de demonstration de Marsannay
#'
#' @description
#' Trois parcelles de la foret communale de Marsannay-la-Cote (Cote-d'Or,
#' INSEE 21390), a la foret ONF `F21866Z`, avec leurs references, leurs
#' contenances et leurs contours **reels** : ceux du cadastre de la DGFiP
#' (livraison etalab), reperes par l'ONF comme appartenant a la foret
#' `F21866Z` ; proprietaire « Commune ». Les references sont sur quatorze
#' caracteres (`213900000A0033`).
#'
#' @details
#' Comme pour [SOMMIER_PARCELLES_COUCHEY], les contours sont authentiques et
#' les ecritures que [sommier_demo_marsannay()] inscrit dessus sont inventees.
#' Les trois parcelles se touchent, la A 33 et la A 34 par un cote commun.
#' `ugf` est le numero de l'unite de gestion fonciere de l'ONF.
#'
#' @format Un `data.frame` de trois lignes : `numero`, `geo_parcelle`,
#'   `section`, `contenance_m2`, `surface_ha`, `ugf`, `wkt_4326`.
#' @source Cadastre DGFiP (etalab) ; parcellaire de la foret `F21866Z`
#'   (ONF), extraits le 2026-10-15.
#' @seealso [sommier_demo_marsannay()]
#'
#' @examples
#' SOMMIER_PARCELLES_MARSANNAY[, c("geo_parcelle", "surface_ha")]
#'
#' @export
SOMMIER_PARCELLES_MARSANNAY <- data.frame(
  numero        = c("33", "34", "39"),
  geo_parcelle  = c("213900000A0033", "213900000A0034", "213900000A0039"),
  section       = c("A", "A", "A"),
  contenance_m2 = c(30875, 35375, 64700),
  surface_ha    = c(3.0875, 3.5375, 6.47),
  ugf           = c("35", "37", "34"),
  wkt_4326 = c(
    paste0(
      "POLYGON((",
      "4.970187 47.281005, 4.970191 47.281004, ",
      "4.970332 47.281002, 4.970498 47.281012, ",
      "4.970629 47.281018, 4.970757 47.281009, ",
      "4.971794 47.280870, 4.972057 47.280830, ",
      "4.972814 47.280730, 4.972817 47.280729, ",
      "4.973375 47.281865, 4.973127 47.281995, ",
      "4.973181 47.282081, 4.972351 47.282226, ",
      "4.971143 47.282439, 4.970925 47.282464, ",
      "4.970923 47.282464, 4.970187 47.281005",
      "))"
    ),
    paste0(
      "POLYGON((",
      "4.967562 47.283016, 4.967379 47.281661, ",
      "4.967449 47.281643, 4.967571 47.281601, ",
      "4.967653 47.281576, 4.967733 47.281553, ",
      "4.967783 47.281542, 4.968252 47.281474, ",
      "4.969525 47.281247, 4.969625 47.281225, ",
      "4.969712 47.281205, 4.969781 47.281174, ",
      "4.970044 47.281052, 4.970109 47.281028, ",
      "4.970187 47.281005, 4.970923 47.282464, ",
      "4.969209 47.282649, 4.968772 47.282714, ",
      "4.968227 47.282792, 4.968108 47.282820, ",
      "4.968025 47.282850, 4.967978 47.282865, ",
      "4.967562 47.283016",
      "))"
    ),
    paste0(
      "POLYGON((",
      "4.972821 47.278085, 4.972913 47.278058, ",
      "4.973942 47.277754, 4.974641 47.277548, ",
      "4.975931 47.280262, 4.975432 47.280346, ",
      "4.974950 47.280412, 4.972788 47.280666, ",
      "4.972785 47.280666, 4.972087 47.279216, ",
      "4.972124 47.279195, 4.972466 47.278853, ",
      "4.972723 47.278425, 4.972752 47.278352, ",
      "4.972824 47.278129, 4.972821 47.278090, ",
      "4.972821 47.278085",
      "))"
    )
  ),
  stringsAsFactors = FALSE
)

#' Jeu de demonstration : foret communale de Marsannay-la-Cote
#'
#' @description
#' Peuple une base vierge avec un petit sommier de demonstration, ancre sur
#' les trois parcelles de [SOMMIER_PARCELLES_MARSANNAY] : une plantation, un
#' degagement, trois placettes de suivi controlees deux fois (six controles)
#' et un entretien de la desserte, soit la meme taille que
#' [sommier_demo_couchey()] pour ce que lit la tournee de
#' [sommier_projet_qfield_travaux()]. Sert a montrer le paquet, et la
#' tournee des travaux, sans donnees de client.
#'
#' @details
#' **Les ecritures sont fictives, le terrain ne l'est pas.** Aucune donnee de
#' plantation n'existe pour Marsannay : chantiers, quantites, montants, dates
#' et releves sont inventes. Le nom de la foret porte la mention « jeu de
#' demonstration » ([NOM_FORET_DEMO_MARSANNAY]), et la fonction refuse de
#' s'executer sur une base ou le jeu existe deja. Les `code_travaux`
#' employes (`PL`, `DG`) sont de [SOMMIER_CODES_TRAVAUX].
#'
#' @inheritParams sommier_demo_couchey
#' @return Invisiblement, une liste : `foret_id`, `ug` (UUID par numero de
#'   parcelle), `n_entrees`.
#'
#' @examples
#' # Necessite une connexion :
#' # sommier_init_schema(con)
#' # demo <- sommier_demo_marsannay(con)
#' # sommier_projet_qfield_travaux(con, demo$foret_id, tempdir(), "operateur")
#'
#' @export
sommier_demo_marsannay <- function(con, auteur = "demo-sommieR",
                                   geometries = TRUE, suffixe = NULL) {
  auteur <- valider_texte(auteur, "auteur")
  nom <- if (est_vide(suffixe)) {
    NOM_FORET_DEMO_MARSANNAY
  } else {
    paste0(NOM_FORET_DEMO_MARSANNAY, " ", valider_texte(suffixe, "suffixe"))
  }

  deja <- DBI::dbGetQuery(
    con, "SELECT id FROM foret WHERE nom = $1",
    params = parametres(list(nom))
  )
  if (nrow(deja) > 0L) {
    stop("Le jeu de demonstration '", nom, "' existe deja dans cette base ",
         "(foret ", deja$id[[1L]], "). Le registre etant append-only, il ne ",
         "peut pas etre efface : utiliser une base vierge, ou un `suffixe` ",
         "distinct.", call. = FALSE)
  }

  parcelles <- SOMMIER_PARCELLES_MARSANNAY
  foret <- foret_creer(
    con, nom, "communal",
    proprietaire = "Commune de Marsannay-la-Cote (ecritures fictives)",
    surface_ha = sum(parcelles$surface_ha)
  )
  ug <- vapply(seq_len(nrow(parcelles)), function(i) {
    ug_creer(con, foret, numero_affichage = parcelles$numero[[i]],
             date_debut = "2016-01-01")
  }, character(1))
  names(ug) <- parcelles$numero

  if (isTRUE(geometries)) {
    for (i in seq_len(nrow(parcelles))) {
      DBI::dbExecute(
        con,
        "INSERT INTO ug_geometrie (ug_uuid, version, geom, source, date_debut)
         VALUES ($1, 1,
                 ST_Multi(ST_Transform(ST_GeomFromText($2, 4326), 2154)),
                 $3, $4::date)",
        params = parametres(list(
          ug[[i]], parcelles$wkt_4326[[i]],
          paste0("cadastre DGFiP (etalab), foret ONF F21866Z - ",
                 parcelles$geo_parcelle[[i]]),
          "2016-01-01"
        ))
      )
    }
  }

  n <- 0L
  ecrire <- function(payload, date, unite = NULL) {
    n <<- n + 1L
    sommier_ajouter(con, sommier_entree(
      foret_id = foret, registre = 6L, date_evenement = date,
      auteur = auteur, ug_uuid = unite, payload = payload
    ))
  }

  plantation <- ecrire(registre6_travaux(
    2022, "plantation", nb_plants = 1100, provenance_plants = "CHS - Bourgogne",
    quantite = 1.8, unite = "ha", montant_eur = 5280,
    repere_plan = "P-22-A", code_travaux = "PL", essence_objectif = "CHS",
    execution = "entreprise", prevu = "prevu", date_reception = "2022-12-02"
  ), "2022-11-08", unite = ug[["33"]])[[1L]]
  ecrire(registre6_travaux(
    2024, "degagement", quantite = 1.8, unite = "ha", montant_eur = 1440,
    code_travaux = "DG", execution = "regie", prevu = "non_prevu",
    motif_ecart = "Concurrence de la ronce signalee au controle de 2023"
  ), "2024-06-18", unite = ug[["33"]])

  # Trois placettes de 50 m2 dans la plantation (A 33), a 40 m d'ecart d'ouest
  # en est, controlees a n+1 et n+3. Les points tombent dans le contour reel.
  centres <- list(c(4.971258, 47.281451), c(4.971787, 47.281442),
                  c(4.972316, 47.281433))
  placettes <- vapply(seq_along(centres), function(k) {
    sommier_installer_placette(
      con, plantation$id, sprintf("P33-%02d", k),
      geom_point(centres[[k]][[1L]], centres[[k]][[2L]]), auteur,
      date_evenement = "2022-12-02", materialisation = "piquet bois"
    )[[1L]]$id
  }, character(1))
  releves <- data.frame(
    annee = c(2023L, 2023L, 2023L, 2025L, 2025L, 2025L),
    k = c(1L, 2L, 3L, 1L, 2L, 3L),
    vivants = c(18L, 17L, 16L, 17L, 15L, 14L),
    hauteur = c(40L, 37L, 35L, 95L, 88L, 79L),
    abroutis = c(2L, 3L, 4L, 1L, 3L, 3L),
    concurrence = c("moyenne", "forte", "forte", "faible", "moyenne",
                    "forte"),
    besoin = c("aucun", "DG", "DG", "aucun", "aucun", "DG")
  )
  for (i in seq_len(nrow(releves))) {
    r <- releves[i, ]
    sommier_controler_placette(
      con, placettes[[r$k]], nb_total = 20L, nb_vivants = r$vivants, auteur,
      visite_le = sprintf("%d-06-1%dT09:30:00Z", r$annee, r$k),
      h_moy_cm = r$hauteur, nb_abroutis = r$abroutis,
      concurrence = r$concurrence, besoin = r$besoin,
      operateur = "Agent patrimonial"
    )
    n <- n + 1L
  }
  ecrire(registre6_travaux(
    2023, "entretien de la desserte", localisation = "Chemin de la section A",
    quantite = 0.8, unite = "km", montant_eur = 1520
  ), "2023-08-02")

  invisible(list(foret_id = foret, ug = ug, n_entrees = n))
}
