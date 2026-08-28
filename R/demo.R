#' Nom de la foret du jeu de demonstration
#'
#' Le nom porte la mention « jeu de demonstration » pour qu'aucune lecture de
#' la base ne puisse prendre ces ecritures pour des enregistrements reels.
#'
#' @export
NOM_FORET_DEMO <- "Foret communale de Couchey (jeu de demonstration)"

#' Parcelles du jeu de demonstration
#'
#' @description
#' Les trois parcelles cadastrales de la fixture Couchey de `nemetonshiny`,
#' reprises a l'identique : memes identifiants, memes contenances, memes
#' contours. Les deux paquets decrivent ainsi le meme terrain, ce qui permet
#' de rapprocher un sommier des indicateurs nemeton calcules dessus.
#'
#' @details
#' La fixture d'origine se decrit elle-meme comme « 3 mock cadastral parcels » :
#' la geometrie et les identifiants sont plausibles et situes dans Couchey,
#' mais ce ne sont pas des donnees cadastrales officielles. Le code INSEE
#' 21200 y est documente comme verifie contre geo.api.gouv.fr et IGN
#' ADMINEXPRESS, apres correction d'une valeur anterieure erronee (21189,
#' qui designe Corberon).
#'
#' Les contours sont en WGS84 (EPSG:4326) comme dans la fixture ; ils sont
#' reprojetes en Lambert-93 a l'insertion, le schema du sommier stockant en
#' EPSG:2154.
#'
#' @format `data.frame` de 3 lignes : `numero`, `geo_parcelle`, `section`,
#'   `contenance_m2`, `surface_ha`, `wkt_4326`.
#'
#' @examples
#' SOMMIER_PARCELLES_COUCHEY[, c("geo_parcelle", "surface_ha")]
#'
#' @export
SOMMIER_PARCELLES_COUCHEY <- data.frame(
  numero        = c("54", "55", "56"),
  geo_parcelle  = c("21200000A0054", "21200000A0055", "21200000A0056"),
  section       = c("A", "A", "A"),
  contenance_m2 = c(25000, 18000, 32000),
  surface_ha    = c(2.5, 1.8, 3.2),
  wkt_4326 = c(
    "POLYGON((4.950 47.270, 4.952 47.270, 4.952 47.272, 4.950 47.272, 4.950 47.270))",
    "POLYGON((4.952 47.270, 4.954 47.270, 4.954 47.272, 4.952 47.272, 4.952 47.270))",
    "POLYGON((4.954 47.270, 4.956 47.270, 4.956 47.272, 4.954 47.272, 4.954 47.270))"
  ),
  stringsAsFactors = FALSE
)

#' Jeu de demonstration : foret communale de Couchey
#'
#' @description
#' Peuple une base vierge avec un sommier complet et coherent couvrant les neuf
#' registres sur dix exercices, ancre sur les trois parcelles de
#' [SOMMIER_PARCELLES_COUCHEY]. Sert a faire tourner les exemples, les rapports
#' et la prise en main sans rien saisir.
#'
#' @details
#' **Les ecritures sont fictives.** Couchey est une commune reelle, et la
#' geometrie vient d'une fixture qui se declare elle-meme « mock » ; mais aucun
#' des volumes, montants, dates, coupes ou visas qui suivent ne provient de ses
#' registres. Ils sont construits pour la demonstration, a une echelle
#' coherente avec les 7,5 hectares des trois parcelles.
#'
#' Depuis la v0.7.0, treize ecritures portent une geometrie : voirie, bornage,
#' emprises de phenomene, arbres et habitats remarquables. Les coordonnees sont
#' posees dans l'emprise des trois parcelles et **inventees comme le reste** -
#' elles servent a montrer ce que la carte sait faire, non a situer quoi que ce
#' soit sur le terrain.
#'
#' Depuis la v0.11.0, la tenue du sommier commence en 2021 - c'est la date du
#' premier visa annuel. Les faits anterieurs ont bien eu lieu, mais la commune
#' ne les a pas enregistres ici : quatorze ecritures sont donc **transcrites**
#' et non constatees, depuis quatre pieces - le registre papier de la serie
#' A50, une deliberation, la base du gestionnaire, et le souvenir de l'agent
#' patrimonial pour la secheresse de 2020. Elles portent leur provenance et un
#' NDP superieur a 0, et forment un bloc contigu en fin de chaine : la
#' sequence est celle de l'ecriture, seules les dates d'evenement remontent le
#' temps. Le jeu montre ainsi les deux etats qu'un sommier repris melange, et
#' ce que le rapport engendre doit en dire. Voir [sommier_reprise()].
#'
#' Trois precautions le rendent visible plutot que de compter sur la memoire du
#' lecteur : le nom de la foret porte la mention, le rapport engendre l'affiche
#' en tete, et la fonction refuse de s'executer sur une base ou le jeu existe
#' deja. Un paquet dont l'objet est la valeur probante ne peut pas produire de
#' fausses ecritures qui passeraient pour authentiques.
#'
#' @param con Connexion DBI vers une base ou le schema est deploye.
#' @param auteur Identifiant porte comme auteur des entrees.
#' @param geometries Inserer les contours des parcelles (defaut `TRUE`).
#'   Necessite PostGIS, qui assure la reprojection depuis le WGS84.
#' @param suffixe Discriminant ajoute au nom, pour poser plusieurs jeux dans
#'   une meme base. Il s'ajoute a [NOM_FORET_DEMO] au lieu de le remplacer :
#'   la mention « jeu de demonstration » survit ainsi a toute personnalisation,
#'   et c'est elle que le rapport lit pour afficher son avertissement.
#' @return Invisiblement, une liste : `foret_id`, `ug` (UUID par numero de
#'   parcelle), `n_entrees`.
#'
#' @examples
#' # Necessite une connexion :
#' # sommier_init_schema(con)
#' # demo <- sommier_demo_couchey(con)
#' # sommier_verifier(con, demo$foret_id)
#'
#' @export
sommier_demo_couchey <- function(con, auteur = "demo-sommieR",
                                 geometries = TRUE, suffixe = NULL) {
  auteur <- valider_texte(auteur, "auteur")
  nom <- if (est_vide(suffixe)) {
    NOM_FORET_DEMO
  } else {
    paste0(NOM_FORET_DEMO, " ", valider_texte(suffixe, "suffixe"))
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

  parcelles <- SOMMIER_PARCELLES_COUCHEY
  surface_totale <- sum(parcelles$surface_ha)

  foret <- foret_creer(
    con, nom, "communal",
    proprietaire = "Commune de Couchey (ecritures fictives)",
    date_application_regime_forestier = "1827-05-21",
    surface_ha = surface_totale
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
          paste0("fixture nemetonshiny - ", parcelles$geo_parcelle[[i]]),
          "2016-01-01"
        ))
      )
    }
  }

  # Possibilite : ~5 m3/ha/an sur 7,5 ha de chenaie, arrondie a 38.
  exercices <- 2016:2025
  for (annee in exercices) {
    exercice_definir(con, foret, annee, possibilite_m3_an = 38)
  }

  ecrire <- function(registre, payload, date, unite = NULL) {
    sommier_ajouter(con, sommier_entree(
      foret_id = foret, registre = registre, date_evenement = date,
      auteur = auteur, ug_uuid = unite, payload = payload
    ))
  }

  # La tenue du sommier commence en 2021 - c'est la date du premier visa
  # annuel. Ce qui precede a bien eu lieu, mais la commune ne l'a pas
  # enregistre ici : il vient du registre papier, de la base du gestionnaire
  # ou de la memoire de l'agent. Ces faits entrent donc en transcription,
  # avec leur piece et un NDP superieur a 0.
  papier <- reprise_source(
    "registre_signe",
    "Sommier papier de Couchey, serie A50, exercices 2016-2020",
    date_piece = "2021-01-18", detenteur = "Commune de Couchey"
  )
  deliberation <- reprise_source(
    "registre_signe",
    "Deliberation du conseil municipal du 12 mars 2018 - location de chasse",
    date_piece = "2018-03-12", detenteur = "Commune de Couchey"
  )
  base_gestionnaire <- reprise_source(
    "base_gestionnaire",
    "Extrait de la base du gestionnaire, arrete au 31/12/2020",
    date_piece = "2021-02-04", detenteur = "Gestionnaire de l'epoque"
  )
  memoire <- reprise_source(
    "temoignage",
    "Secheresse 2020 rapportee par l'agent patrimonial",
    observations = "Aucune fiche A50K retrouvee ; surface estimee de memoire."
  )

  # Les transcriptions s'accumulent et s'ecrivent en un seul lot, apres les
  # constats : la sequence est celle de l'ecriture, et une reprise forme un
  # bloc contigu. Seules les dates d'evenement remontent le temps.
  transcrites <- list()
  transcrire <- function(registre, payload, date, source, unite = NULL) {
    transcrites[[length(transcrites) + 1L]] <<- sommier_reprise(
      foret_id = foret, registre = registre, date_evenement = date,
      auteur = auteur, ug_uuid = unite, payload = payload, source = source
    )
    invisible(NULL)
  }

  # Registre 2 - foncier. Le bornage de 2017 precede la tenue : transcrit.
  transcrire(2L, registre2_foncier(
    "bornage", "Refection de la limite nord de la section A",
    heures_technicien = 9, nb_bornes = 6, cout_total_eur = 1480,
    charge_proprietaire_eur = 740, charge_riverains_eur = 740,
    references_cadastrales = parcelles$geo_parcelle,
    geometrie = geom_ligne(rbind(
      c(4.9500, 47.2720), c(4.9530, 47.2720), c(4.9560, 47.2720)
    ))
  ), "2017-09-14", papier)

  # Registre 3 - bail de chasse et affouage.
  transcrire(3L, registre3_droit(
    "bail_chasse", "Location de chasse - lot communal", numero = "1",
    date_debut = "2018-04-01", date_expiration = "2027-03-31",
    redevance_eur = 310, surface_ha = surface_totale
  ), "2018-04-01", deliberation)
  for (annee in 2021:2025) {
    ecrire(3L, registre3_affouage(
      campagne = paste0(annee, "-", annee + 1L),
      nb_affouagistes = 8 + (annee %% 3L),
      volume_m3 = 14 + 2 * (annee - 2021L),
      taxe_eur = 38, mode_partage = "par_feu"
    ), paste0(annee, "-10-15"))
  }

  # Registre 4 - desserte. Relevee en 2016 dans la base du gestionnaire, donc
  # transcrite : le sommier ne l'a pas constatee.
  transcrire(4L, registre4_voirie(
    "Chemin de la section A", "empierree", longueur_m = 620,
    largeur_chaussee_m = 3, usage = "exploitation", ouverte_public = FALSE,
    geometrie = geom_ligne(rbind(
      c(4.9502, 47.2703), c(4.9522, 47.2705), c(4.9542, 47.2704)
    ))
  ), "2016-06-01", base_gestionnaire)
  transcrire(4L, registre4_voirie(
    "Piste de desserte est", "terrain_naturel", longueur_m = 340,
    largeur_chaussee_m = 2.5, usage = "exploitation", ouverte_public = FALSE,
    geometrie = geom_ligne(rbind(
      c(4.9545, 47.2703), c(4.9550, 47.2712), c(4.9552, 47.2718)
    ))
  ), "2016-06-01", base_gestionnaire)
  transcrire(4L, registre4_equipement(
    "equipement", "Place de depot", nom = "PD-01", capacite = 250,
    unite = "m2", etat = "bon", date_controle = "2019-05-06",
    geometrie = geom_point(4.9518, 47.2706)
  ), "2016-06-01", base_gestionnaire)

  # Registre 5 - un martelage par exercice, plus un chablis. Les exercices
  # anterieurs a la tenue viennent du registre papier ; les suivants ont ete
  # portes ici le jour du martelage.
  natures <- c("amelioration", "reguliere", "sanitaire")
  for (i in seq_along(exercices)) {
    annee <- exercices[[i]]
    coupe <- registre5_coupe(
      "martelage", annee, natures[[(i %% 3L) + 1L]],
      volume_m3 = 34 + 3 * ((i * 7L) %% 5L),
      surface_ha = parcelles$surface_ha[[(i %% 3L) + 1L]], essence = "CHS"
    )
    date_coupe <- paste0(annee, "-03-05")
    unite <- ug[[(i %% 3L) + 1L]]
    if (annee < 2021) {
      transcrire(5L, coupe, date_coupe, papier, unite)
    } else {
      ecrire(5L, coupe, date_coupe, unite)
    }
  }
  ecrire(5L, registre5_coupe(
    "produit_accidentel", 2022, "chablis", volume_m3 = 22, surface_ha = 0.8,
    observations = "Suites du coup de vent de fevrier"
  ), "2022-03-20", unite = ug[["55"]])

  # Registre 6 - travaux, avec taux de reprise.
  ecrire(6L, registre6_travaux(
    2022, "plantation", nb_plants = 480, provenance_plants = "CHS - Bourgogne",
    quantite = 0.8, unite = "ha", montant_eur = 2350, taux_reprise_pct = 78,
    repere_plan = "P-22-A"
  ), "2022-11-08", unite = ug[["55"]])
  ecrire(6L, registre6_travaux(
    2024, "degagement", quantite = 0.8, unite = "ha", montant_eur = 640,
    taux_reprise_pct = 84
  ), "2024-06-18", unite = ug[["55"]])
  ecrire(6L, registre6_travaux(
    2023, "entretien de la desserte", localisation = "Chemin de la section A",
    quantite = 0.62, unite = "km", montant_eur = 1180
  ), "2023-08-02")

  # Registre 7 - comptabilite et budget previsionnel en regard.
  for (annee in 2021:2025) {
    ecrire(7L, registre7_ecriture(
      "bois_sur_pied", annee, montant_eur = 1900 + 120 * (annee - 2021L),
      quantite = 34, unite = "m3", reference = paste0("TR-", annee, "-001")
    ), paste0(annee, "-12-15"))
    ecrire(7L, registre7_ecriture(
      "chasse_peche", annee, montant_eur = 310,
      reference = paste0("TR-", annee, "-002")
    ), paste0(annee, "-12-15"))
    ecrire(7L, registre7_ecriture(
      "bois_delivres", annee, montant_eur = 530 + 40 * (annee - 2021L)
    ), paste0(annee, "-12-15"))
    ecrire(7L, registre7_ecriture(
      "frais_garderie", annee, montant_eur = 240
    ), paste0(annee, "-12-20"))
    budget_definir(con, foret, annee, "bois_sur_pied", 2000)
    budget_definir(con, foret, annee, "chasse_peche", 300)
    budget_definir(con, foret, annee, "frais_garderie", 250)
  }
  ecrire(7L, registre7_ecriture(
    "reboisement", 2022, montant_eur = 2350, reference = "MD-2022-014"
  ), "2022-12-15")
  budget_definir(con, foret, 2022, "reboisement", 2000)
  # Budgete mais jamais execute : le tableau d'execution doit le montrer.
  budget_definir(con, foret, 2025, "equipement", 1200)

  # Registre 8 - phenomenes, chasse, equilibre foret-gibier.
  ecrire(8L, registre8_phenomene(
    "tempete", "Coup de vent du 17 fevrier", surface_ha = 0.8,
    volume_impacte_m3 = 22, intensite = "moderee",
    geometrie = geom_polygone(rbind(
      c(4.9525, 47.2712), c(4.9535, 47.2712), c(4.9535, 47.2718),
      c(4.9525, 47.2718)
    ))
  ), "2022-02-17", unite = ug[["55"]])
  # Aucune fiche A50K pour 2020 : le fait est rapporte, pas retrouve. NDP 4,
  # le plus eloigne de l'echelle - et le rapport le montrera comme tel.
  transcrire(8L, registre8_phenomene(
    "secheresse", "Deficit hydrique estival, roussissement des cimes",
    surface_ha = 3.1,
    geometrie = geom_polygone(rbind(
      c(4.9505, 47.2708), c(4.9555, 47.2708), c(4.9555, 47.2716),
      c(4.9505, 47.2716)
    ))
  ), "2020-08-10", memoire)
  for (annee in 2021:2024) {
    saison <- paste0(annee, "-", annee + 1L)
    ecrire(8L, registre8_tableau_chasse(
      saison, "chevreuil", nombre = 2 + (annee %% 3L), classe_age = "adulte",
      attribue = 4
    ), paste0(annee + 1L, "-03-20"))
    ecrire(8L, registre8_equilibre_gibier(
      saison, surface_sensible_ha = 1.4,
      taux_abroutissement_pct = 31 - 2 * (annee - 2021L),
      methode = "indice de consommation", diagnostic = "desequilibre_leger"
    ), paste0(annee + 1L, "-03-31"))
  }

  # Registre 9 - patrimoine remarquable, dont un sujet revisite.
  # Le premier releve du chene vient de l'inventaire du gestionnaire ; celui
  # de 2024 a ete fait par la commune. Le meme sujet porte donc les deux
  # provenances, et c'est le releve constate qui fait etat courant.
  transcrire(9L, registre9_arbre(
    "Chene de la Justice", "CHS",
    "Age estime a 280 ans, port en candelabre, arbre limite historique",
    circonference_cm = 486, hauteur_m = 26, etat_sanitaire = "bon",
    geometrie = geom_point(4.9512, 47.2714)
  ), "2016-07-12", base_gestionnaire, ug[["54"]])
  ecrire(9L, registre9_arbre(
    "Chene de la Justice", "CHS",
    "Age estime a 280 ans, port en candelabre, arbre limite historique",
    circonference_cm = 502, hauteur_m = 26, etat_sanitaire = "moyen",
    observations = "Descente de cime amorcee au nord",
    geometrie = geom_point(4.9512, 47.2714)
  ), "2024-07-09", unite = ug[["54"]])
  ecrire(9L, registre9_arbre(
    "Chandelle du talus est", "SAP", "Bois mort sur pied, cavites de pics",
    circonference_cm = 210, etat_sanitaire = "mort",
    geometrie = geom_point(4.9548, 47.2716)
  ), "2023-05-22", unite = ug[["56"]])
  # Vivant mais sous le seuil des tres gros bois : le jeu d'essai doit montrer
  # que le seuil separe reellement, et pas seulement qu'il s'applique.
  ecrire(9L, registre9_arbre(
    "Alisier de la lisiere sud", "ALT", "Essence rare sur le massif, port libre",
    circonference_cm = 118, hauteur_m = 17, etat_sanitaire = "bon",
    geometrie = geom_point(4.9531, 47.2702)
  ), "2022-09-15", unite = ug[["55"]])
  transcrire(9L, registre9_habitat(
    "Pelouse calcicole seche", surface_ha = 0.6, code_natura2000 = "6210",
    etat_conservation = "favorable", localisation = "Rebord de plateau, A 56",
    geometrie = geom_polygone(rbind(
      c(4.9543, 47.2707), c(4.9553, 47.2707), c(4.9553, 47.2711),
      c(4.9543, 47.2711)
    ))
  ), "2019-06-03", base_gestionnaire, ug[["56"]])
  ecrire(9L, registre9_espece(
    "Sabot de Venus", "Cypripedium calceolus",
    statut_protection = "Directive Habitats, annexe II", effectif = 12,
    localisation = "Versant nord, A 56",
    geometrie = geom_point(4.9546, 47.2718)
  ), "2021-05-28", unite = ug[["56"]])
  transcrire(9L, registre9_vestige(
    "Charbonniere de la section A", "Charbonniere",
    "Plateforme circulaire de 8 m, charbon de bois affleurant",
    bibliographie = "Inventaire archeologique de la Cote 2018",
    geometrie = geom_point(4.9508, 47.2709)
  ), "2018-10-04", base_gestionnaire, ug[["54"]])

  # Registre 1 - visas annuels de tenue du sommier.
  for (annee in 2021:2024) {
    ecrire(1L, registre1_validation(
      "visa_annuel", "commune", "Maire de Couchey", exercice = annee,
      portee = "sommier"
    ), paste0(annee + 1L, "-02-15"))
  }

  # Le lot de transcriptions, ecrit en une fois et en dernier : quatorze
  # ecritures, quatre pieces, des faits de 2016 a 2020. Le compte-rendu dit ce
  # qui est entre ; la sequence, elle, montre un bloc contigu en fin de chaine.
  sommier_reprendre(con, transcrites)

  n <- DBI::dbGetQuery(
    con, "SELECT count(*) AS n FROM entree_sommier WHERE foret_id = $1",
    params = parametres(list(foret))
  )$n

  invisible(list(foret_id = foret, ug = ug, n_entrees = as.integer(n)))
}
