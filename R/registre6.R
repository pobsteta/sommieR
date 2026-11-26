#' Codes des travaux sylvicoles
#'
#' @description
#' La nomenclature fermee des travaux du registre 6, celle du brief metier du
#' suivi sylvicole : le code qu'on agrege, a cote du libelle libre de l'A50J.
#' Chaque code fixe sa famille, les unites admises pour sa quantite et les
#' formes admises pour sa geometrie (`point`, `ligne`, `surface`). Une
#' plantation se mesure en hectares, ses plants dans `nb_plants`.
#'
#' @format Un `data.frame` : `code`, `famille`, `libelle`, `unites` et
#'   `formes` (une ou plusieurs valeurs, separees par une virgule).
#'
#' @seealso [registre6_travaux()]
#'
#' @export
SOMMIER_CODES_TRAVAUX <- data.frame(
  code = c("PS", "PL", "RG", "PG", "PI", "DG", "CL", "NT", "TF", "EL", "DE",
           "RN", "BI", "DS", "PA"),
  famille = c("preparation", "plantation", "plantation", "protection",
              "protection", "education", "education", "education",
              "education", "education", "education", "regeneration",
              "biodiversite", "desserte", "parcellaire"),
  libelle = c(
    "Pr\u00e9paration du sol (broyage, andainage, crochetage, potets)",
    "Plantation en plein, placeaux, enrichissement",
    "Regarnis, compl\u00e9ments",
    "Cl\u00f4ture",
    "Protections individuelles, r\u00e9pulsifs",
    "D\u00e9gagement (manuel, m\u00e9canique)",
    "Cloisonnement sylvicole (ouverture, entretien)",
    "Nettoiement, d\u00e9pressage",
    "Taille de formation",
    "\u00c9lagage",
    "D\u00e9signation d'arbres objectif",
    "Travaux en r\u00e9g\u00e9n\u00e9ration naturelle (d\u00e9gagement de semis, crochetage localis\u00e9)",
    "\u00celots, arbres habitat, mares, lisi\u00e8res",
    "Entretien de piste, foss\u00e9s, places de d\u00e9p\u00f4t",
    "Entretien des limites (peinture, bornes)"
  ),
  unites = c("ha", "ha", "plants", "m", "nb", "ha", "m, ha", "ha", "tiges",
             "tiges", "tiges", "ha", "ha, nb", "m", "m"),
  formes = c("surface", "surface", "surface, point", "ligne", "surface",
             "surface", "ligne", "surface", "surface", "surface",
             "surface, point", "surface", "surface, point", "ligne",
             "ligne"),
  stringsAsFactors = FALSE
)

#' Modes d'execution des travaux
#' @export
SOMMIER_EXECUTIONS_TRAVAUX <- c("regie", "entreprise", "autre")

#' Travaux prevus, reportes ou non prevus
#'
#' @description
#' Constate a la reception : `prevu` (au document de gestion), `reporte`
#' (prevu un autre exercice), `non_prevu`. Hors `prevu`, un motif est exige.
#'
#' @export
SOMMIER_PREVUS_TRAVAUX <- c("prevu", "reporte", "non_prevu")

#' Niveaux de concurrence d'une plantation
#'
#' @description
#' Les trois niveaux admis, dans l'ordre croissant. Leur definition de terrain
#' (critere, seuils, nature, valeur manquante) est dans
#' [SOMMIER_DEFINITIONS_CONCURRENCE] ; la regle de passage du plant a la
#' placette, dans [sommier_niveau_concurrence()].
#'
#' @export
SOMMIER_CONCURRENCES <- c("faible", "moyenne", "forte")

#' Definition de terrain des niveaux de concurrence
#'
#' @description
#' Ce qui distingue `faible`, `moyenne` et `forte` au controle d'une
#' plantation (brief `surculus` 2026-11-04, issue #69). Colonnes : `niveau`
#' (un de [SOMMIER_CONCURRENCES]), `libelle` (ecran), `part_plants_min_pct` et
#' `part_plants_max_pct` (part des plants vivants au contact de la vegetation
#' concurrente, bornes `[min, max[`), `critere_hauteur` (position de la
#' vegetation par rapport au plant) et `travail` (suite usuelle).
#'
#' **Un seul critere decide : la part de plants vivants au contact de la
#' vegetation.** `critere_hauteur` et `travail` sont une aide descriptive pour
#' le controleur : ils ne decident jamais du niveau (60 % des plants au contact
#' avec une vegetation au pied seulement : `forte`).
#'
#' Aucune des cinq sources publiees lues par l'acquereur de Surculus (guide
#' "Reussir la plantation forestiere" 2014 p. 52 ; DSF bilan 2024 p. 13 et
#' 16 ; RENFOR/INRAE ; CNPF CONQueTh ; MRNF Quebec 2024 p. 12) ne definit trois
#' niveaux : leurs criteres sont binaires et portent sur le plant ("aucune
#' touffe de vegetation concurrente au pied des plants", guide 2014 p. 52).
#' Les seuils ci-dessous sont donc une **convention de sommieR**, derivee de ce
#' critere par plant, a confirmer sur le terrain ; elle n'est pas une norme.
#'
#' @format Un `data.frame` de trois lignes.
#' @seealso [sommier_niveau_concurrence()], [SOMMIER_CONCURRENCES]
#' @export
SOMMIER_DEFINITIONS_CONCURRENCE <- data.frame(
  niveau = c("faible", "moyenne", "forte"),
  libelle = c("Faible", "Moyenne", "Forte"),
  part_plants_min_pct = c(0, 20, 50),
  part_plants_max_pct = c(20, 50, Inf),
  critere_hauteur = c(
    "vegetation au pied seulement, plant dominant",
    "vegetation atteignant le plant sans le depasser",
    "vegetation depassant le plant ou l'etouffant"),
  travail = c("aucun", "degagement a prevoir", "degagement a faire"),
  stringsAsFactors = FALSE
)

#' Niveau de concurrence d'une placette, depuis les plants
#'
#' @description
#' Regle de passage du critere binaire par plant (concurrence ou non, guide 2014
#' p. 52) au niveau de placette : on compte la part des plants vivants concurrences
#' par la vegetation, puis on la lit dans
#' [SOMMIER_DEFINITIONS_CONCURRENCE]. Un seul niveau couvre l'herbacee et la
#' ligneuse (fougere aigle, ronce) : il se calcule sur le comptage commun (un
#' plant touche par l'une ou l'autre compte une fois). La nature (herbacee,
#' ligneuse, mixte) se note a part, en `observations` : elle decrit, elle ne
#' decide pas.
#'
#' Sans plant vivant compte, le resultat est `NA` : jamais un niveau devine.
#'
#' @param nb_concurrences Plants vivants au contact de la vegetation concurrente.
#' @param nb_vivants Plants vivants comptes.
#'
#' @return Un element de [SOMMIER_CONCURRENCES], ou `NA_character_`.
#' @seealso [registre6_controle()]
#' @export
sommier_niveau_concurrence <- function(nb_concurrences, nb_vivants) {
  nb_concurrences <- valider_entier(nb_concurrences, "nb_concurrences", min = 0)
  nb_vivants <- valider_entier(nb_vivants, "nb_vivants", min = 0)
  if (nb_concurrences > nb_vivants) {
    stop("Plus de plants concurrences (", nb_concurrences, ") que de vivants (",
         nb_vivants, ").", call. = FALSE)
  }
  if (nb_vivants == 0L) return(NA_character_)
  part <- 100 * nb_concurrences / nb_vivants
  d <- SOMMIER_DEFINITIONS_CONCURRENCE
  d$niveau[part >= d$part_plants_min_pct & part < d$part_plants_max_pct]
}

#' Types d'entree du registre 6
#'
#' @description
#' * `travaux` : une intervention (A50J, A50H) ; le type est implicite, une
#'   entree sans `type_entree` en est une.
#' * `placette` : une placette permanente de suivi d'une plantation ou d'une
#'   regeneration.
#' * `controle` : un passage sur une placette.
#' * `plant` : un plant pointe dans une placette, qu'on retrouve d'un passage
#'   a l'autre (voir [registre6_plant()]).
#'
#' @export
SOMMIER_TYPES_TRAVAUX <- c("travaux", "placette", "controle", "plant")

#' Etats d'un plant a un controle
#'
#' @description
#' La nomenclature du DSF (`etats-plants.yaml` de Surculus, DSF 2024 p. 8) :
#' `sain`, `atteint`, `mort`, `absent` ; plus `non_observe`, qui n'est pas un
#' etat mais une absence de mesure : le plant pointe n'a pas ete retrouve ce
#' jour-la. Il sort des totaux du controle et reste a chercher au passage
#' suivant. Un plant `atteint` compte comme vivant.
#'
#' @seealso [registre6_controle()]
#' @export
SOMMIER_ETATS_PLANT <- c("sain", "atteint", "mort", "absent", "non_observe")

#' Methodes de pointage d'un plant
#'
#' @description
#' Comment la position d'un plant a ete obtenue, en quatre valeurs fermees,
#' **propres a sommieR** (definies le 2026-11-25, mission 065 ; Surculus n'a pas
#' ce vocabulaire) : `relatif_boussole` et `relatif_saisie` (le plant est
#' pointe **relativement au piquet** de la placette ; l'azimut vient de la
#' boussole du telephone ou est saisi), `gnss_plant` (position GNSS prise sur le
#' plant lui-meme) et `construit` (position de demonstration ou reconstituee,
#' jamais mesuree). La seule trace voisine chez Surculus est `source_azimut`
#' (`boussole_telephone` ou `saisie`, `docs/formats/journal-valeurs-v1.md`).
#'
#' @seealso [registre6_plant()]
#' @export
SOMMIER_METHODES_POINTAGE <- c("relatif_boussole", "relatif_saisie",
                               "gnss_plant", "construit")

#' Groupes de causes d'une atteinte ou d'une mort de plant
#'
#' @description
#' Les quatre groupes du bilan du DSF. Le detail (`abroutissement`, `gel`,
#' `hylobe`...) est un texte libre a cote du groupe.
#'
#' @seealso [registre6_controle()]
#' @export
SOMMIER_GROUPES_CAUSE_PLANT <- c("entomologique", "pathologique", "animaux",
                                 "abiotique_complexe_indetermine")

#' Detail de cause qui fait d'un plant un plant abrouti
#' @noRd
DETAIL_ABROUTISSEMENT <- "abroutissement"

#' Payload du registre 6 - placette de suivi
#'
#' @description
#' Une placette permanente installee pour suivre une plantation ou une
#' regeneration. Ses passages s'inscrivent ensuite en [registre6_controle()],
#' qui y renvoient : c'est le couple detection et suite du registre 8.
#'
#' @param code_placette Code lisible, unique dans l'unite ("P35-03").
#' @param travaux_id UUID de l'intervention suivie (une plantation, une
#'   regeneration).
#' @param geometrie Le centre de la placette, un point en WGS84 (voir
#'   [geom_point()]).
#' @param rayon_m Rayon, en metres : 3,99 m font 50 m2.
#' @param materialisation Comment la placette se retrouve (piquet,
#'   peinture...).
#' @param precision_m,source_gnss Precision et source de la position.
#' @param observations Observations libres.
#'
#' @return Une liste nommee, prete a etre passee a [sommier_entree()].
#'
#' @seealso [sommier_installer_placette()]
#'
#' @export
registre6_placette <- function(code_placette, travaux_id, geometrie,
                               rayon_m = 3.99, materialisation = NULL,
                               precision_m = NULL, source_gnss = NULL,
                               observations = NULL) {
  if (est_vide(geometrie)) {
    stop("Une placette se retrouve par son centre : `geometrie` (un point) ",
         "est obligatoire.", call. = FALSE)
  }
  compacter(list(
    type_entree     = "placette",
    code_placette   = valider_texte(code_placette, "code_placette"),
    travaux_id      = valider_uuid(travaux_id, "travaux_id"),
    rayon_m         = valider_nombre(rayon_m, "rayon_m", min = 0.5, max = 50),
    materialisation = si_present(materialisation, valider_texte,
                                 "materialisation"),
    geometrie       = geometrie_si_presente(geometrie, "Point"),
    precision_m     = si_present(precision_m, valider_nombre, "precision_m",
                                 min = 0),
    source_gnss     = si_present(source_gnss, valider_texte, "source_gnss"),
    observations    = si_present(observations, valider_texte, "observations")
  ))
}

#' Payload du registre 6 - plant pointe
#'
#' @description
#' Un plant pointe dans une placette de suivi, par son observation brute
#' relative au piquet (distance horizontale et azimut magnetique, comme
#' Surculus les releve) ; sa position (`geometrie`) en est derivee. Il porte
#' son identifiant (l'`id` de l'entree), qu'il garde d'un passage a l'autre,
#' et son numero dans la placette, donne au premier pointage et jamais
#' recalcule : sommieR le recoit tel quel. L'etat du plant a chaque passage
#' est porte par le controle ([registre6_controle()]), pas par le plant.
#'
#' Un plant s'inscrit une fois, au passage ou il est pointe. Un regarni est un
#' nouveau plant (`regarni = TRUE`), lie au plant mort ou absent qu'il remplace
#' (`remplace_uuid`) : le plant remplace compte encore au controle ou le regarni
#' est pose, puis sort des totaux des controles suivants.
#'
#' @param placette_id UUID de la placette ([registre6_placette()]).
#' @param numero Numero du plant dans la placette (entier, au moins 1).
#' @param geometrie La position du plant, un point en WGS84 ([geom_point()]).
#' @param essence Essence du plant (code ONF, texte libre pour sommieR) ;
#'   [sommier_pointer_plant()] la prerempli avec l'essence objectif des
#'   travaux suivis.
#' @param regarni,remplace_uuid `regarni = TRUE` exige `remplace_uuid`, l'UUID
#'   du plant mort ou absent que ce plant remplace ; `remplace_uuid` exige
#'   `regarni` vrai ou omis.
#' @param distance_m Distance horizontale du piquet au plant, en metres.
#' @param azimut_mag,unite_azimut Azimut magnetique tel que lu, et son unite
#'   (`deg` : [0, 360[ ; `gr` : [0, 400[). L'un exige l'autre.
#' @param declinaison_deg,convergence_deg,azimut_geo_deg Termes derives :
#'   declinaison magnetique, convergence des meridiens, azimut geographique
#'   dans [0, 360[ (nord geographique, sens horaire).
#' @param modele_geomagnetique Modele de la declinaison (`WMM2025`).
#' @param methode_pointage Comment la position a ete obtenue : l'une de
#'   [SOMMIER_METHODES_POINTAGE] (facultatif ; omise, elle n'est pas inscrite).
#' @param pointe_le Instant du pointage (UTC) ; sa date civile, en Europe/Paris, est celle du plant.
#' @param observations Observations libres.
#'
#' @return Une liste nommee, prete a etre passee a [sommier_entree()].
#'
#' @seealso [sommier_pointer_plant()]
#'
#' @export
registre6_plant <- function(placette_id, numero, geometrie, essence = NULL,
                            regarni = NULL, remplace_uuid = NULL,
                            distance_m = NULL, azimut_mag = NULL,
                            unite_azimut = NULL, declinaison_deg = NULL,
                            convergence_deg = NULL, azimut_geo_deg = NULL,
                            modele_geomagnetique = NULL, pointe_le = NULL,
                            observations = NULL, methode_pointage = NULL) {
  if (est_vide(geometrie)) {
    stop("Un plant se retrouve par sa position : `geometrie` (un point) ",
         "est obligatoire.", call. = FALSE)
  }
  point <- tryCatch(
    valider_geometrie(geometrie, "Point"),
    error = function(e) {
      stop("`geometrie` du plant : un point WGS 84 (longitude, latitude en ",
           "degres) est attendu : ", conditionMessage(e), call. = FALSE)
    })
  if (!est_vide(regarni) && (!is.logical(regarni) || length(regarni) != 1L)) {
    stop("`regarni` doit valoir TRUE ou FALSE.", call. = FALSE)
  }
  remplace_uuid <- si_present(remplace_uuid, valider_uuid, "remplace_uuid")
  regarni <- if (est_vide(regarni)) NULL else regarni
  if (isTRUE(regarni) && is.null(remplace_uuid)) {
    stop("Un regarni remplace exactement un plant mort ou absent : ",
         "`remplace_uuid` est obligatoire.", call. = FALSE)
  }
  if (isFALSE(regarni) && !is.null(remplace_uuid)) {
    stop("`remplace_uuid` n'a de sens que pour un regarni (`regarni = TRUE`).",
         call. = FALSE)
  }
  unite_azimut <- si_present(unite_azimut, valider_choix, "unite_azimut",
                             c("deg", "gr"))
  if (!is.null(azimut_mag) && !est_vide(azimut_mag) && is.null(unite_azimut)) {
    stop("`azimut_mag` exige `unite_azimut` (deg ou gr) : un azimut sans ",
         "unite ne se relit pas.", call. = FALSE)
  }
  if (is.null(azimut_mag) || est_vide(azimut_mag)) {
    if (!is.null(unite_azimut)) {
      stop("`unite_azimut` sans `azimut_mag`.", call. = FALSE)
    }
    azimut_mag <- NULL
  } else {
    azimut_mag <- valider_nombre(azimut_mag, "azimut_mag", min = 0)
    borne <- if (identical(unite_azimut, "gr")) 400 else 360
    if (azimut_mag >= borne) {
      stop("`azimut_mag` doit etre dans [0, ", borne, "[ (", unite_azimut,
           "), recu : ", azimut_mag, ".", call. = FALSE)
    }
  }
  compacter(list(
    type_entree   = "plant",
    placette_id   = valider_uuid(placette_id, "placette_id"),
    numero        = valider_entier(numero, "numero", min = 1),
    essence       = si_present(essence, valider_texte, "essence"),
    regarni       = if (isTRUE(regarni)) TRUE,
    remplace_uuid = remplace_uuid,
    pointe_le     = si_present(pointe_le, format_instant, "pointe_le"),
    distance_m    = si_present(distance_m, valider_nombre, "distance_m",
                               min = 0),
    azimut_mag    = azimut_mag,
    unite_azimut  = unite_azimut,
    declinaison_deg = si_present(declinaison_deg, valider_nombre,
                                 "declinaison_deg", min = -180, max = 180),
    convergence_deg = si_present(convergence_deg, valider_nombre,
                                 "convergence_deg", min = -180, max = 180),
    azimut_geo_deg = si_present(azimut_geo_deg, function(x, nom) {
      x <- valider_nombre(x, nom, min = 0)
      if (x >= 360) {
        stop("`", nom, "` doit etre dans [0, 360[, recu : ", x, ".",
             call. = FALSE)
      }
      x
    }, "azimut_geo_deg"),
    modele_geomagnetique = si_present(modele_geomagnetique, valider_texte,
                                      "modele_geomagnetique"),
    methode_pointage = si_present(methode_pointage, valider_choix,
                                  "methode_pointage", SOMMIER_METHODES_POINTAGE),
    geometrie     = point,
    observations  = si_present(observations, valider_texte, "observations")
  ))
}

#' Payload du registre 6 - controle d'une placette
#'
#' @description
#' Un passage sur une placette : ce qu'on y compte. Le taux de reprise, la
#' densite a l'hectare et la part d'abroutis ne s'inscrivent pas : la vue
#' `v_controle_plantation` les calcule, et l'age de la plantation se deduit de
#' l'annee des travaux suivis.
#'
#' @param placette_id UUID de la placette controlee.
#' @param nb_total,nb_vivants Plants comptes, et vivants parmi eux. Obligatoires
#'   sans `plants` ; avec `plants`, ils se deduisent des etats et, s'ils sont
#'   donnes, doivent concorder (voir `plants`).
#' @param h_moy_cm Hauteur moyenne des tiges objectif, en cm.
#' @param nb_abroutis Plants vivants abroutis.
#' @param concurrence L'un de [SOMMIER_CONCURRENCES], defini dans
#'   [SOMMIER_DEFINITIONS_CONCURRENCE].
#' @param besoin Le travail qui s'impose ensuite : un code de
#'   [SOMMIER_CODES_TRAVAUX], ou `"aucun"`.
#' @param operateur Agent qui a controle.
#' @param visite_le Instant du controle.
#' @param releve_uuid Identifiant du releve de terrain.
#' @param photos Photos, par leur empreinte.
#' @param observations Observations libres.
#' @param nb_plants_vivants,nb_plants_concurrences Facultatifs : le comptage
#'   dont `concurrence` est tiree, pour qu'on puisse la verifier. Plants
#'   vivants sur lesquels le contact avec la vegetation a ete note (au plus
#'   `nb_vivants`), et parmi eux ceux au contact de la vegetation concurrente.
#'   `nb_plants_concurrences` peut arriver **sans** `nb_plants_vivants` : il est
#'   alors garde tel quel, sans niveau deduit ni compare, et un avertissement le
#'   dit (rien ne se perd, rien n'est muet ; pas d'avertissement au rejeu).
#'   Ajout seul : `NULL` est accepte, et un controle sans ces champs se relit a
#'   l'identique. Lis avec [sommier_niveau_concurrence()]. Quand les deux sont
#'   fournis : si `concurrence` est absent, il est **deduit** par
#'   [sommier_niveau_concurrence()] ; s'il est saisi et contredit les
#'   comptages, il est **conserve tel que saisi**, un avertissement le dit et
#'   le niveau calcule est inscrit au payload sous `concurrence_calculee`.
#' @param plants Facultatif : l'etat de chaque plant a ce passage, une liste
#'   d'elements `list(plant_id, etat, cause_groupe, cause_detail, hauteur_cm)`
#'   (ou un `data.frame` a ces colonnes). `etat` : l'un de
#'   [SOMMIER_ETATS_PLANT] ; `cause_groupe` : l'un de
#'   [SOMMIER_GROUPES_CAUSE_PLANT], admis pour un plant `atteint` ou `mort`
#'   seulement ; `cause_detail` : texte libre, admis pour un `atteint` ou un
#'   `mort`, et pour un `sain` seulement s'il vaut `"abroutissement"` (jamais
#'   pour un `absent` ni un `non_observe`) ; `hauteur_cm` : entier strictement
#'   positif, refuse pour un `absent` et un `non_observe`. Un meme plant ne
#'   porte qu'un etat par controle.
#'
#'   **Les totaux en decoulent** : `nb_total` = plants dont l'etat est sain,
#'   atteint, mort ou absent (hors `non_observe` et hors plants remplaces),
#'   `nb_vivants` = sains + atteints, `nb_abroutis` = vivants dont le detail
#'   est `"abroutissement"` (un plant mort d'abroutissement n'y compte pas),
#'   `h_moy_cm` = moyenne des hauteurs des vivants mesures, arrondie a l'entier
#'   le plus proche, demi vers le haut (42,5 donne 43 ; `round()` de R donnerait
#'   42). Totaux omis : ils sont deduits et inscrits. Totaux donnes qui
#'   contredisent les etats : refus, avant toute ecriture. Un controle sans
#'   `plants` s'ecrit comme avant.
#' @param plants_remplaces Facultatif : ceux des `plants` qu'un regarni pose a
#'   un passage anterieur a remplaces ; ils sortent des totaux. Doit etre inclus
#'   dans `plants`. [sommier_controler_placette()] le calcule.
#' @param concurrence_calculee Ne se saisit pas : c'est la trace que la
#'   fonction inscrit quand le niveau saisi contredit les comptages. Accepte
#'   pour que la relecture d'un payload ecrit se rejoue (il est recalcule).
#' @param geometrie,precision_m,rattache_par_identite,sans_position_mesuree
#'   Facultatifs : la position **mesuree** du controle (noms de Surculus). Ajout
#'   seul : un controle sans ces champs se relit a l'identique.
#'   `geometrie` est un point WGS 84 (voir [geom_point()]) ; `entree_sommier.geom`
#'   la projette comme pour toute entree, et la vue `v_controle_plantation` la
#'   rend. `precision_m` est la precision de cette position, en metres
#'   (strictement positive ; elle ne s'inscrit qu'avec une `geometrie`).
#'   `rattache_par_identite` (`TRUE`/`FALSE`) dit que le code lu du piquet a
#'   designe la placette, et non la position mesuree (piquet a plus de 15 m, ou
#'   controle sans position mesuree).
#'   `sans_position_mesuree = TRUE` dit que le controle a ete ouvert sans aucun
#'   fix : il n'a alors **ni** `geometrie` **ni** `precision_m` (jamais un
#'   point (0, 0), jamais un point vide), et sa position est celle de la
#'   placette. Un point hors des bornes WGS 84 (par exemple des metres
#'   Lambert-93), ou une position donnee avec `sans_position_mesuree = TRUE`,
#'   est refuse.
#'
#' @return Une liste nommee, prete a etre passee a [sommier_entree()].
#'
#' @seealso [sommier_controler_placette()]
#'
#' @export
registre6_controle <- function(placette_id, nb_total = NULL,
                               nb_vivants = NULL, h_moy_cm = NULL, nb_abroutis = NULL,
                               concurrence = NULL, besoin = NULL,
                               operateur = NULL, visite_le = NULL,
                               releve_uuid = NULL, photos = NULL,
                               observations = NULL,
                               nb_plants_vivants = NULL,
                               nb_plants_concurrences = NULL,
                               concurrence_calculee = NULL,
                               geometrie = NULL, precision_m = NULL,
                               rattache_par_identite = NULL,
                               sans_position_mesuree = NULL,
                               plants = NULL, plants_remplaces = NULL) {
  # Avec l'etat des plants, les totaux en decoulent : omis, ils sont deduits ;
  # donnes, ils doivent concorder. Sans plants, tout est comme avant.
  detail_plants <- normaliser_plants_controle(plants, plants_remplaces)
  if (!is.null(detail_plants)) {
    deduits <- totaux_des_plants(detail_plants$plants,
                                 detail_plants$remplaces)
    nb_total <- concorder_total(nb_total, deduits$nb_total, "nb_total")
    nb_vivants <- concorder_total(nb_vivants, deduits$nb_vivants,
                                  "nb_vivants")
    nb_abroutis <- concorder_total(nb_abroutis, deduits$nb_abroutis,
                                   "nb_abroutis")
    h_moy_cm <- concorder_total(h_moy_cm, deduits$h_moy_cm, "h_moy_cm")
  }
  nb_total <- valider_entier(nb_total, "nb_total", min = 0)
  nb_vivants <- valider_entier(nb_vivants, "nb_vivants", min = 0)
  if (nb_vivants > nb_total) {
    stop("Plus de plants vivants (", nb_vivants, ") que de plants comptes (",
         nb_total, ").", call. = FALSE)
  }
  nb_abroutis <- si_present(nb_abroutis, valider_entier, "nb_abroutis",
                            min = 0)
  if (!is.null(nb_abroutis) && nb_abroutis > nb_vivants) {
    stop("Plus de plants abroutis (", nb_abroutis, ") que de vivants (",
         nb_vivants, ") : un abroutissement se compte sur les vivants.",
         call. = FALSE)
  }
  nb_plants_vivants <- si_present(nb_plants_vivants, valider_entier,
                                  "nb_plants_vivants", min = 0)
  nb_plants_concurrences <- si_present(nb_plants_concurrences, valider_entier,
                                       "nb_plants_concurrences", min = 0)
  if (!is.null(nb_plants_vivants) && nb_plants_vivants > nb_vivants) {
    stop("Plus de plants notes (", nb_plants_vivants, ") que de vivants (",
         nb_vivants, ").", call. = FALSE)
  }
  if (!is.null(nb_plants_concurrences) && !is.null(nb_plants_vivants) &&
      nb_plants_concurrences > nb_plants_vivants) {
    stop("Plus de plants au contact (", nb_plants_concurrences,
         ") que de plants vivants notes (", nb_plants_vivants, ").",
         call. = FALSE)
  }
  concurrence <- si_present(concurrence, valider_choix, "concurrence",
                            SOMMIER_CONCURRENCES)
  # Les deux comptages permettent de deduire le niveau (regle de
  # sommier_niveau_concurrence()). Un niveau saisi qui les contredit est
  # accepte tel quel : le terrain n'est jamais bloque, l'ecart est inscrit.
  relu <- !is.null(concurrence_calculee)  # relecture d'un payload deja ecrit
  concurrence_calculee <- NULL
  if (!is.null(nb_plants_concurrences) && is.null(nb_plants_vivants)) {
    warning("comptage de plants au contact (", nb_plants_concurrences,
            ") sans plants vivants notes : garde tel quel, aucun niveau de ",
            "concurrence calcule.", call. = FALSE)
  } else if (!is.null(nb_plants_concurrences)) {
    concurrence_calculee <- sommier_niveau_concurrence(
      nb_plants_concurrences, nb_plants_vivants)
    # Aucun vivant note (0 sur 0) : pas de niveau a calculer, donc rien a
    # deduire, rien a comparer, rien a inscrire.
    if (is.na(concurrence_calculee)) {
      concurrence_calculee <- NULL
    } else if (is.null(concurrence)) {
      concurrence <- concurrence_calculee
      concurrence_calculee <- NULL
    } else if (identical(concurrence, concurrence_calculee)) {
      concurrence_calculee <- NULL
    } else if (!relu) {
      warning("concurrence saisie (", concurrence, ") differente du niveau ",
              "calcule sur les comptages (", concurrence_calculee, ") : ",
              "saisie conservee, ecart inscrit (concurrence_calculee).",
              call. = FALSE)
    }
  }
  position <- valider_position_controle(geometrie, precision_m,
                                        rattache_par_identite,
                                        sans_position_mesuree)
  compacter(list(
    type_entree = "controle",
    placette_id = valider_uuid(placette_id, "placette_id"),
    nb_total    = nb_total,
    nb_vivants  = nb_vivants,
    h_moy_cm    = si_present(h_moy_cm, valider_entier, "h_moy_cm", min = 0),
    nb_abroutis = nb_abroutis,
    concurrence = concurrence,
    besoin      = si_present(besoin, valider_choix, "besoin",
                             c(SOMMIER_CODES_TRAVAUX$code, "aucun")),
    operateur   = si_present(operateur, valider_texte, "operateur"),
    visite_le   = si_present(visite_le, format_instant, "visite_le"),
    releve_uuid = si_present(releve_uuid, valider_uuid, "releve_uuid"),
    photos      = valider_photos(photos),
    observations = si_present(observations, valider_texte, "observations"),
    nb_plants_vivants = nb_plants_vivants,
    nb_plants_concurrences = nb_plants_concurrences,
    concurrence_calculee = concurrence_calculee,
    geometrie = position$geometrie,
    precision_m = position$precision_m,
    rattache_par_identite = position$rattache_par_identite,
    sans_position_mesuree = position$sans_position_mesuree,
    plants = detail_plants$plants,
    plants_remplaces = detail_plants$remplaces_ecrits
  ))
}

# L'etat des plants d'un controle, valide un par un. NULL quand le controle
# n'en porte pas (une liste vide ne dit rien : elle vaut l'absence). Rend les
# etats normalises, et les plants remplaces dans la liste. Accepte une liste de
# listes nommees ou un data.frame (relecture par jsonlite).
normaliser_plants_controle <- function(plants, plants_remplaces) {
  if (is.data.frame(plants)) {
    plants <- lapply(seq_len(nrow(plants)), function(i) {
      x <- as.list(plants[i, , drop = FALSE])
      x[!vapply(x, function(v) length(v) == 0L || is.na(v), logical(1))]
    })
  }
  if (est_vide(plants)) {
    if (!est_vide(plants_remplaces)) {
      stop("`plants_remplaces` sans `plants`.", call. = FALSE)
    }
    return(NULL)
  }
  if (!is.list(plants) || !is.null(names(plants))) {
    stop("`plants` doit etre une liste d'etats, chacun une liste nommee.",
         call. = FALSE)
  }
  etats <- lapply(seq_along(plants), function(i) {
    valider_etat_plant(plants[[i]], paste0("plants[[", i, "]]"))
  })
  ids <- vapply(etats, function(e) e$plant_id, character(1))
  doubles <- unique(ids[duplicated(ids)])
  if (length(doubles) > 0L) {
    stop("Un plant n'a qu'un etat par controle : ",
         paste(doubles, collapse = ", "), " en a plusieurs.", call. = FALSE)
  }
  remplaces <- character(0)
  if (!est_vide(plants_remplaces)) {
    remplaces <- vapply(unlist(plants_remplaces), valider_uuid, character(1),
                        "plants_remplaces", USE.NAMES = FALSE)
    hors <- setdiff(remplaces, ids)
    if (length(hors) > 0L) {
      stop("`plants_remplaces` ne nomme que des plants de `plants` : ",
           paste(hors, collapse = ", "), " n'y est pas.", call. = FALSE)
    }
    remplaces <- unique(remplaces)
  }
  list(plants = etats, remplaces = remplaces,
       remplaces_ecrits = if (length(remplaces) > 0L) as.list(remplaces))
}

# L'etat d'un plant a un controle : etat, cause, detail, hauteur, et ce que
# chacun admet (spec de Surculus § 4.3 et § 6, cas de fixtures/regles/plants).
valider_etat_plant <- function(e, nom) {
  if (!is.list(e) || is.null(names(e))) {
    stop("`", nom, "` doit etre une liste nommee.", call. = FALSE)
  }
  etat <- valider_choix(e$etat, paste0(nom, "$etat"), SOMMIER_ETATS_PLANT)
  groupe <- si_present(e$cause_groupe, valider_choix,
                       paste0(nom, "$cause_groupe"),
                       SOMMIER_GROUPES_CAUSE_PLANT)
  detail <- si_present(e$cause_detail, valider_texte,
                       paste0(nom, "$cause_detail"))
  hauteur <- si_present(e$hauteur_cm, valider_entier,
                        paste0(nom, "$hauteur_cm"), min = 1)
  if (!is.null(groupe) && !etat %in% c("atteint", "mort")) {
    stop("`", nom, "` : un plant ", etat, " n'a pas de groupe de cause ",
         "(seulement atteint ou mort).", call. = FALSE)
  }
  if (!is.null(detail) && etat %in% c("absent", "non_observe")) {
    stop("`", nom, "` : un plant ", etat, " n'a pas de detail de cause.",
         call. = FALSE)
  }
  if (!is.null(detail) && etat == "sain" && detail != DETAIL_ABROUTISSEMENT) {
    stop("`", nom, "` : sur un plant sain, seul le detail \"",
         DETAIL_ABROUTISSEMENT, "\" est permis, recu : ", detail, ".",
         call. = FALSE)
  }
  if (!is.null(hauteur) && etat %in% c("absent", "non_observe")) {
    stop("`", nom, "` : un plant ", etat, " ne porte aucune hauteur.",
         call. = FALSE)
  }
  compacter(list(
    plant_id = valider_uuid(e$plant_id, paste0(nom, "$plant_id")),
    etat = etat, cause_groupe = groupe, cause_detail = detail,
    hauteur_cm = hauteur
  ))
}

# Les totaux qui decoulent des etats (spec de Surculus § 4.3 : non observes et
# plants remplaces exclus ; un atteint compte vivant ; un mort d'abroutissement
# n'est pas un abrouti ; h_moy_cm = moyenne des vivants mesures, demi vers le
# haut).
totaux_des_plants <- function(plants, remplaces = character(0)) {
  comptes <- Filter(function(p) {
    p$etat != "non_observe" && !p$plant_id %in% remplaces
  }, plants)
  vivants <- Filter(function(p) p$etat %in% c("sain", "atteint"), comptes)
  hauteurs <- unlist(lapply(vivants, function(p) p$hauteur_cm))
  list(
    nb_total = length(comptes),
    nb_vivants = length(vivants),
    nb_abroutis = sum(vapply(vivants, function(p) {
      identical(p$cause_detail, DETAIL_ABROUTISSEMENT)
    }, logical(1))),
    h_moy_cm = if (length(hauteurs) > 0L) floor(mean(hauteurs) + 0.5)
  )
}

# Un total donne a cote des etats : omis, il prend la valeur deduite ; donne, il
# doit l'egaler.
concorder_total <- function(donne, deduit, nom) {
  if (est_vide(donne)) {
    return(deduit)
  }
  if (is.null(deduit)) {
    stop("`", nom, "` = ", donne, " alors qu'aucun plant n'a de hauteur : ",
         "les totaux decoulent des etats des plants.", call. = FALSE)
  }
  if (!is.numeric(donne) || length(donne) != 1L || donne != deduit) {
    stop("`", nom, "` = ", paste(donne, collapse = ", "), " ne concorde ",
         "pas avec les etats des plants (", deduit, ") : les totaux ",
         "decoulent des etats.", call. = FALSE)
  }
  deduit
}

# La position mesuree d'un controle. Tout est facultatif ; une position et
# l'absence de position ne se melangent pas : `sans_position_mesuree` vrai
# n'admet ni geometrie ni precision, et une precision n'a de sens qu'avec une
# geometrie. Rien n'est devine, rien n'est ecrit a moitie.
valider_position_controle <- function(geometrie, precision_m,
                                      rattache_par_identite,
                                      sans_position_mesuree) {
  booleen <- function(x, nom) {
    if (est_vide(x)) return(NULL)
    if (!is.logical(x) || length(x) != 1L) {
      stop("`", nom, "` doit valoir TRUE ou FALSE.", call. = FALSE)
    }
    x
  }
  rattache <- booleen(rattache_par_identite, "rattache_par_identite")
  sans <- booleen(sans_position_mesuree, "sans_position_mesuree")
  precision <- si_present(precision_m, valider_nombre, "precision_m")
  if (!is.null(precision) && precision <= 0) {
    stop("`precision_m` doit etre strictement positive (jamais 0 : un zero ",
         "n'est pas une precision), recu : ", precision, ".", call. = FALSE)
  }
  point <- if (est_vide(geometrie)) NULL else tryCatch(
    valider_geometrie(geometrie, "Point"),
    error = function(e) {
      stop("`geometrie` du controle : un point WGS 84 (longitude, latitude ",
           "en degres) est attendu : ", conditionMessage(e), call. = FALSE)
    })
  if (isTRUE(sans) && !is.null(point)) {
    stop("Un controle `sans_position_mesuree` ne porte pas de `geometrie` : ",
         "sans mesure, pas de point (jamais (0, 0)).", call. = FALSE)
  }
  if (isTRUE(sans) && !is.null(precision)) {
    stop("Un controle `sans_position_mesuree` ne porte pas de `precision_m` : ",
         "il n'y a rien a mesurer.", call. = FALSE)
  }
  if (!is.null(precision) && is.null(point)) {
    stop("`precision_m` est la precision d'une position mesuree : il faut ",
         "une `geometrie`.", call. = FALSE)
  }
  list(geometrie = point, precision_m = precision,
       rattache_par_identite = rattache, sans_position_mesuree = sans)
}

#' Relecture d'un payload du registre 6
#'
#' @description
#' Rappelle le constructeur du type que le payload declare. Un payload sans
#' `type_entree` est une intervention : c'est le cas de toutes celles inscrites
#' avant la v0.28.0.
#'
#' @param payload Payload relu (liste nommee).
#'
#' @return Le payload revalide.
#'
#' @export
registre6_depuis_payload <- function(payload) {
  if (!is.list(payload) || is.null(names(payload))) {
    stop("`payload` doit etre une liste nommee.", call. = FALSE)
  }
  type <- if (est_vide(payload$type_entree)) "travaux" else
    valider_choix(payload$type_entree, "type_entree", SOMMIER_TYPES_TRAVAUX)
  arguments <- payload
  if (type != "travaux") {
    arguments$type_entree <- NULL
  }
  # Un rejeu ne signale rien : l'ecart a ete dit a l'ecriture.
  suppressWarnings(do.call(switch(
    type,
    travaux  = registre6_travaux,
    placette = registre6_placette,
    controle = registre6_controle,
    plant    = registre6_plant
  ), arguments))
}

# Les formes d'un code, en types GeoJSON.
FORMES_GEOJSON <- c(point = "Point", ligne = "LineString", surface = "Polygon")

# "m, ha" -> c("m", "ha")
alternatives <- function(x) strsplit(x, ",\\s*")[[1L]]
