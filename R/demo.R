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
#' Trois parcelles de la foret communale de Couchey, avec leurs references,
#' leurs contenances et leurs contours **reels** : ceux que publie la DGFiP,
#' repris par le projet Couchey de nemeton qui porte le meme parcellaire. Un
#' sommier se rapproche ainsi des indicateurs nemeton calcules sur le meme
#' terrain, sans qu'il faille croire deux dessins sur parole.
#'
#' @details
#' **Les contours sont authentiques, les ecritures ne le sont pas.** La
#' geometrie et les references cadastrales sont celles de la DGFiP ; tout ce
#' que [sommier_demo_couchey()] inscrit dessus est invente. La distinction
#' porte : un contour faux se voit a la premiere superposition, une ecriture
#' fausse ne se voit jamais. C'est donc elle, et elle seule, que le nom de la
#' foret et le rapport engendre signalent.
#'
#' Jusqu'a la v0.11.1, le paquet reprenait la fixture « mock » de
#' `nemetonshiny` : trois carres de 0,002 degre portant les references
#' `21200000A0054` a `56`. Ces parcelles n'existent pas - la section A de
#' Couchey passe de 38 a 61 - et la reference etait meme mal formee, le
#' cadastre ecrivant `212000000A0054` sur quatorze caracteres. Une geometrie
#' plausible mais fausse est exactement ce qu'un sommier existe pour
#' interdire ; la garder en exemple revenait a demontrer le contraire de ce
#' que le paquet affirme.
#'
#' **Trois blocs, et non un tenant.** A 102 est a 485 metres de A 35, et A 15
#' a 1,7 kilometre a l'est. Une foret communale en plusieurs blocs est la
#' regle plutot que l'exception, et le jeu y gagne : la « piste de desserte
#' est » dessert reellement le bloc est.
#'
#' Les contours sont simplifies a 1 metre par `ST_SimplifyPreserveTopology`,
#' ce qui coute 55 m2 sur 16,4 hectares - 0,03 %. La tolerance de 5 metres en
#' coutait 866, dont 1 % sur la seule A 15 : pour trois parcelles, la
#' simplification n'economise pas assez de code pour qu'on abime une surface.
#'
#' `contenance_m2` est la contenance cadastrale et `surface_ha` la meme valeur
#' en hectares. Ni l'une ni l'autre n'est l'aire du contour, qui en differe de
#' quelques dizaines de metres carres : le cadastre fait foi sur la
#' contenance, le dessin ne fait foi sur rien.
#'
#' Les contours sont en WGS84 (EPSG:4326) ; ils sont reprojetes en Lambert-93
#' a l'insertion, le schema du sommier stockant en EPSG:2154.
#'
#' @source Cadastre DGFiP, livraison etalab du 1er juin 2026, par le projet
#'   Couchey de nemeton (`20260828_140251_hwuy`).
#'
#' @format `data.frame` de 3 lignes : `numero`, `geo_parcelle`, `section`,
#'   `contenance_m2`, `surface_ha`, `wkt_4326`.
#'
#' @examples
#' SOMMIER_PARCELLES_COUCHEY[, c("geo_parcelle", "surface_ha")]
#'
#' @export
SOMMIER_PARCELLES_COUCHEY <- data.frame(
  numero        = c("15", "35", "102"),
  geo_parcelle  = c("212000000A0015", "212000000A0035", "212000000A0102"),
  section       = c("A", "A", "A"),
  contenance_m2 = c(48750, 71900, 43095),
  surface_ha    = c(4.875, 7.19, 4.3095),
  wkt_4326 = c(
    paste0(
      "POLYGON((4.959091 47.256187, 4.95808 47.255214, 4.959932 47.255024, ",
      "4.961013 47.254696, 4.962156 47.254251, 4.963129 47.253913, ",
      "4.96394 47.255175, 4.959091 47.256187))"
    ),
    paste0(
      "POLYGON((4.930607 47.258671, 4.9321 47.258052, 4.932376 47.257952, ",
      "4.932939 47.257786, 4.933462 47.258218, 4.93418 47.258648, ",
      "4.934725 47.259068, 4.935374 47.259496, 4.935678 47.259742, ",
      "4.935654 47.259763, 4.935167 47.259929, 4.935017 47.259965, ",
      "4.934362 47.260026, 4.934006 47.260137, 4.93255 47.260796, ",
      "4.931864 47.260941, 4.931481 47.260217, 4.931054 47.25962, ",
      "4.930997 47.259277, 4.930607 47.258671))"
    ),
    paste0(
      "POLYGON((4.941584 47.263658, 4.938331 47.265611, 4.937312 47.264936, ",
      "4.937994 47.264282, 4.939507 47.263255, 4.940544 47.262794, ",
      "4.940998 47.263207, 4.941584 47.263658))"
    )
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
#' **Les ecritures sont fictives, le terrain ne l'est pas.** Couchey est une
#' commune reelle et les contours viennent du cadastre (voir
#' [SOMMIER_PARCELLES_COUCHEY]) ; mais aucun des volumes, montants, dates,
#' coupes ou visas qui suivent ne provient de ses registres. Ils sont
#' construits pour la demonstration, a une echelle coherente avec les 16,4
#' hectares des trois parcelles.
#'
#' Depuis la v0.7.0, treize ecritures portent une geometrie : voirie, bornage,
#' emprises de phenomene, arbres et habitats remarquables. Depuis la v0.12.0,
#' elles sont **posees dans les contours reels** : chaque arbre tombe dans la
#' parcelle qui le porte, l'emprise de la tempete tient dans A 35, le chemin
#' relie les deux blocs de l'ouest et la limite bornee suit le cote nord-est
#' de A 102. Les objets restent inventes ; leurs positions, elles, ne
#' contredisent plus le parcellaire.
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
          paste0("cadastre DGFiP, livraison etalab 2026-06-01 - ",
                 parcelles$geo_parcelle[[i]]),
          "2016-01-01"
        ))
      )
    }
  }

  # Possibilite : ~5 m3/ha/an sur 16,4 ha de chenaie, arrondie a 82.
  exercices <- 2016:2025
  for (annee in exercices) {
    exercice_definir(con, foret, annee, possibilite_m3_an = 82)
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
    heures_technicien = 12, nb_bornes = 9, cout_total_eur = 1950,
    charge_proprietaire_eur = 975, charge_riverains_eur = 975,
    references_cadastrales = parcelles$geo_parcelle,
    # Le cote nord-est de A 102, soit 328 metres : neuf bornes tous les 36 m.
    geometrie = geom_ligne(rbind(
      c(4.941584, 47.263658), c(4.939958, 47.264635), c(4.938331, 47.265611)
    ))
  ), "2017-09-14", papier)

  # Registre 3 - bail de chasse et affouage.
  transcrire(3L, registre3_droit(
    "bail_chasse", "Location de chasse - lot communal", numero = "1",
    date_debut = "2018-04-01", date_expiration = "2027-03-31",
    redevance_eur = 680, surface_ha = surface_totale
  ), "2018-04-01", deliberation)
  for (annee in 2021:2025) {
    ecrire(3L, registre3_affouage(
      campagne = paste0(annee, "-", annee + 1L),
      nb_affouagistes = 17 + 2L * (annee %% 3L),
      volume_m3 = 31 + 4 * (annee - 2021L),
      taxe_eur = 38, mode_partage = "par_feu"
    ), paste0(annee, "-10-15"))
  }

  # Registre 4 - desserte. Relevee en 2016 dans la base du gestionnaire, donc
  # transcrite : le sommier ne l'a pas constatee.
  transcrire(4L, registre4_voirie(
    "Chemin de la section A", "empierree", longueur_m = 1040,
    largeur_chaussee_m = 3, usage = "exploitation", ouverte_public = FALSE,
    # Le chemin traverse A 35 puis rejoint A 102. La longueur est celle du
    # trace, mesuree en Lambert-93 : une desserte dont le dessin et l'attribut
    # se contredisent ne renseigne ni la carte ni l'imprime A50D.
    geometrie = geom_ligne(rbind(
      c(4.931000, 47.258500), c(4.933100, 47.259400), c(4.934700, 47.260100),
      c(4.937400, 47.262900), c(4.939800, 47.264000), c(4.941300, 47.263700)
    ))
  ), "2016-06-01", base_gestionnaire)
  transcrire(4L, registre4_voirie(
    "Piste de desserte est", "terrain_naturel", longueur_m = 480,
    largeur_chaussee_m = 2.5, usage = "exploitation", ouverte_public = FALSE,
    # Le bloc est, c'est A 15 : la piste porte bien son nom.
    geometrie = geom_ligne(rbind(
      c(4.957900, 47.255300), c(4.960000, 47.255100),
      c(4.962200, 47.254500), c(4.964000, 47.254200)
    ))
  ), "2016-06-01", base_gestionnaire)
  transcrire(4L, registre4_equipement(
    "equipement", "Place de depot", nom = "PD-01", capacite = 550,
    unite = "m2", etat = "bon", date_controle = "2019-05-06",
    geometrie = geom_point(4.933034, 47.259315)
  ), "2016-06-01", base_gestionnaire)

  # Registre 5 - un martelage par exercice, plus un chablis. Les exercices
  # anterieurs a la tenue viennent du registre papier ; les suivants ont ete
  # portes ici le jour du martelage.
  natures <- c("amelioration", "reguliere", "sanitaire")
  for (i in seq_along(exercices)) {
    annee <- exercices[[i]]
    coupe <- registre5_coupe(
      "martelage", annee, natures[[(i %% 3L) + 1L]],
      volume_m3 = 74 + 6 * ((i * 7L) %% 5L),
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
    "produit_accidentel", 2022, "chablis", volume_m3 = 48, surface_ha = 1.75,
    observations = "Suites du coup de vent de fevrier"
  ), "2022-03-20", unite = ug[["35"]])

  # Registre 6 - travaux, avec taux de reprise.
  ecrire(6L, registre6_travaux(
    2022, "plantation", nb_plants = 1050, provenance_plants = "CHS - Bourgogne",
    quantite = 1.75, unite = "ha", montant_eur = 5130, taux_reprise_pct = 78,
    repere_plan = "P-22-A"
  ), "2022-11-08", unite = ug[["35"]])
  ecrire(6L, registre6_travaux(
    2024, "degagement", quantite = 1.75, unite = "ha", montant_eur = 1400,
    taux_reprise_pct = 84
  ), "2024-06-18", unite = ug[["35"]])
  ecrire(6L, registre6_travaux(
    2023, "entretien de la desserte", localisation = "Chemin de la section A",
    quantite = 1.04, unite = "km", montant_eur = 1980
  ), "2023-08-02")

  # Registre 7 - comptabilite et budget previsionnel en regard.
  for (annee in 2021:2025) {
    ecrire(7L, registre7_ecriture(
      "bois_sur_pied", annee, montant_eur = 4150 + 260 * (annee - 2021L),
      quantite = 74, unite = "m3", reference = paste0("TR-", annee, "-001")
    ), paste0(annee, "-12-15"))
    ecrire(7L, registre7_ecriture(
      "chasse_peche", annee, montant_eur = 680,
      reference = paste0("TR-", annee, "-002")
    ), paste0(annee, "-12-15"))
    ecrire(7L, registre7_ecriture(
      "bois_delivres", annee, montant_eur = 1160 + 90 * (annee - 2021L)
    ), paste0(annee, "-12-15"))
    ecrire(7L, registre7_ecriture(
      "frais_garderie", annee, montant_eur = 520
    ), paste0(annee, "-12-20"))
    budget_definir(con, foret, annee, "bois_sur_pied", 4400)
    budget_definir(con, foret, annee, "chasse_peche", 650)
    budget_definir(con, foret, annee, "frais_garderie", 550)
  }
  ecrire(7L, registre7_ecriture(
    "reboisement", 2022, montant_eur = 5130, reference = "MD-2022-014"
  ), "2022-12-15")
  budget_definir(con, foret, 2022, "reboisement", 4400)
  # Budgete mais jamais execute : le tableau d'execution doit le montrer.
  budget_definir(con, foret, 2025, "equipement", 2600)

  # Registre 8 - phenomenes, chasse, equilibre foret-gibier.
  ecrire(8L, registre8_phenomene(
    "tempete", "Coup de vent du 17 fevrier", surface_ha = 1.75,
    volume_impacte_m3 = 48, intensite = "moderee",
    # 1,75 ha entierement contenus dans A 35 : l'emprise d'un chablis rattache
    # a une unite ne peut pas deborder de l'unite qui le porte.
    geometrie = geom_polygone(rbind(
      c(4.931911, 47.258862), c(4.931945, 47.259804),
      c(4.934157, 47.259767), c(4.934123, 47.258826)
    ))
  ), "2022-02-17", unite = ug[["35"]])
  # Aucune fiche A50K pour 2020 : le fait est rapporte, pas retrouve. NDP 4,
  # le plus eloigne de l'echelle - et le rapport le montrera comme tel.
  transcrire(8L, registre8_phenomene(
    "secheresse", "Deficit hydrique estival, roussissement des cimes",
    surface_ha = 6.8,
    # Rattachee a la foret et non a une unite : l'emprise deborde A 35, comme
    # un deficit hydrique deborde un parcellaire.
    geometrie = geom_polygone(rbind(
      c(4.930820, 47.258423), c(4.930887, 47.260279),
      c(4.935247, 47.260206), c(4.935181, 47.258351)
    ))
  ), "2020-08-10", memoire)
  for (annee in 2021:2024) {
    saison <- paste0(annee, "-", annee + 1L)
    ecrire(8L, registre8_tableau_chasse(
      saison, "chevreuil", nombre = 4 + 2L * (annee %% 3L),
      classe_age = "adulte", attribue = 9
    ), paste0(annee + 1L, "-03-20"))
    ecrire(8L, registre8_equilibre_gibier(
      saison, surface_sensible_ha = 3.1,
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
    geometrie = geom_point(4.961429, 47.255078)
  ), "2016-07-12", base_gestionnaire, ug[["15"]])
  ecrire(9L, registre9_arbre(
    "Chene de la Justice", "CHS",
    "Age estime a 280 ans, port en candelabre, arbre limite historique",
    circonference_cm = 502, hauteur_m = 26, etat_sanitaire = "moyen",
    observations = "Descente de cime amorcee au nord",
    geometrie = geom_point(4.961429, 47.255078)
  ), "2024-07-09", unite = ug[["15"]])
  ecrire(9L, registre9_arbre(
    "Chandelle du talus est", "SAP", "Bois mort sur pied, cavites de pics",
    circonference_cm = 210, etat_sanitaire = "mort",
    geometrie = geom_point(4.940670, 47.263505)
  ), "2023-05-22", unite = ug[["102"]])
  # Vivant mais sous le seuil des tres gros bois : le jeu d'essai doit montrer
  # que le seuil separe reellement, et pas seulement qu'il s'applique.
  ecrire(9L, registre9_arbre(
    "Alisier de la lisiere sud", "ALT", "Essence rare sur le massif, port libre",
    circonference_cm = 118, hauteur_m = 17, etat_sanitaire = "bon",
    geometrie = geom_point(4.933943, 47.258849)
  ), "2022-09-15", unite = ug[["35"]])
  transcrire(9L, registre9_habitat(
    "Pelouse calcicole seche", surface_ha = 1.3, code_natura2000 = "6210",
    etat_conservation = "favorable", localisation = "Rebord de plateau, A 102",
    # Un rectangle oriente selon A 102, qui est une bande en diagonale : une
    # emprise a l'equerre en serait sortie.
    geometrie = geom_polygone(rbind(
      c(4.938800, 47.264962), c(4.938167, 47.264473),
      c(4.939947, 47.263404), c(4.940580, 47.263893)
    ))
  ), "2019-06-03", base_gestionnaire, ug[["102"]])
  ecrire(9L, registre9_espece(
    "Sabot de Venus", "Cypripedium calceolus",
    statut_protection = "Directive Habitats, annexe II", effectif = 26,
    localisation = "Versant nord, A 102",
    geometrie = geom_point(4.938980, 47.264344)
  ), "2021-05-28", unite = ug[["102"]])
  transcrire(9L, registre9_vestige(
    "Charbonniere de la section A", "Charbonniere",
    "Plateforme circulaire de 8 m, charbon de bois affleurant",
    bibliographie = "Inventaire archeologique de la Cote 2018",
    geometrie = geom_point(4.960649, 47.255452)
  ), "2018-10-04", base_gestionnaire, ug[["15"]])

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
