#' Projet QField pour les travaux et le suivi des plantations
#'
#' @description
#' Ecrit un dossier autonome - un projet QGIS, un GeoPackage et un dossier
#' `DCIM/` vide - que l'on copie sur le telephone ou la tablette et que l'on
#' ouvre avec QField. On y releve les travaux faits, chacun dessine en surface,
#' en ligne ou en point selon son code, on y installe des placettes de suivi et
#' on y saisit leurs controles.
#'
#' @details
#' **Un troisieme projet**, a cote de ceux des limites et des detections, sur
#' le meme principe : le modele a ete produit une fois par QGIS
#' (`data-raw/qfield_modele.py`), cette fonction le copie et en remplit les
#' couches.
#'
#' **Les codes viennent de [SOMMIER_CODES_TRAVAUX]**, ecrits a chaque projet :
#' la couche des surfaces ne propose que les codes qui admettent une surface,
#' et l'unite par defaut est la premiere du code.
#'
#' **Les placettes deja installees sont dans le projet**, colorees selon leur
#' dernier controle : besoin signale, sans besoin, jamais controlee. On les
#' controle en ajoutant un controle a la placette ; on en installe une
#' nouvelle en placant un point, rattache a des travaux de la liste des
#' travaux suivis (ceux d'une unite de gestion).
#'
#' @param con Connexion DBI.
#' @param foret_id UUID de la foret.
#' @param dossier Dossier a creer. Il ne doit pas exister : une tournee non
#'   rapatriee ne doit jamais etre ecrasee.
#' @param operateur Nom de l'operateur, propose par defaut a chaque saisie.
#' @param fond Parcellaire cadastral pour se reperer, tel que le rend
#'   [sommier_fond_lire()] (facultatif).
#' @param ortho GeoTIFF d'orthophotographie a joindre au projet, tel que
#'   l'ecrit [sommier_ortho_ign()] (facultatif). Il est converti en un seul
#'   fichier `ortho.mbtiles`, tuile en EPSG:3857 (zooms 12 a 18, tuiles
#'   PNG, fond hors emprise transparent), avec `attribution` et
#'   `date_mise_a_jour` (AAAA-MM-JJ, la date du GeoTIFF) dans sa table
#'   `metadata`. Il remplace `ortho.tif` : QField et Surculus le lisent sans
#'   reseau. Necessite `sf` et `RSQLite`.
#' @param date_ortho Date facultative (AAAA-MM-JJ, ou `Date`) inscrite comme
#'   `date_mise_a_jour` de `ortho.mbtiles`. Elle dit **quand l'image a ete
#'   obtenue** (jour du telechargement), pas quand elle a ete prise : le
#'   service ne donne pas la date de prise de vue. Sans elle, la date du
#'   fichier GeoTIFF, qui est le jour du telechargement tant qu'on ne l'a pas
#'   copie ; passez la vraie date si le fichier a ete copie ou touche depuis.
#' @param programme Chemin du `<projet>-programme-travaux.gpkg` de
#'   nemetonshiny (facultatif), lu par [sommier_lire_programme_travaux()] : ses
#'   actions sont versees dans la table `programme` du projet, et l'import
#'   refuse un `action_id` saisi qui n'y figure pas.
#' @param depot Repertoire du depot de photos (facultatif). S'il est donne, la
#'   tournee emporte les photos du **dernier controle de chaque placette**,
#'   pour que l'agent les voie au passage suivant : les fichiers sous
#'   `DCIM/<uuid>.<extension>`, une ligne de la couche `photos` par photo
#'   (rattachee au controle precedent, qui n'est pas dans la tournee). Une
#'   photo absente du depot ou alteree (empreinte differente) n'est pas
#'   versee, et un avertissement le dit. Ces lignes restent telles quelles au
#'   retour : elles ne rattachent aucune photo a un controle de la tournee,
#'   donc l'import ne les redepose jamais. **Elles ne sont visibles que pour
#'   Surculus**, qui lit la couche `photos` ; la relation `photos_du_controle`
#'   de QField, elle, ne montre que les photos des controles de la tournee.
#'   La couche `photos_terrain` n'est **pas** ecrite a l'aller : c'est
#'   Surculus qui la cree.
#'
#' @details
#' **Les plants sont dans le projet** (couches `plants`, POINT en Lambert-93, et
#' `etats_plants`, table, celles que Surculus lit) : tous les plants non remplaces
#' par un regarni, vivants, morts, absents ou jamais controles, chacun avec son
#' numero, sa position, son observation brute et son dernier etat s'il en a un
#' (cause, detail, hauteur ; `non_observe` n'est pas un etat : le dernier etat
#' mesure compte). Le forestier retrouve chaque plant et le renote au controle
#' suivant : l'import exige un etat de chaque plant a chaque controle, il confirme
#' `mort` ou `absent`, ou met `non_observe`. Seuls les plants remplaces par un
#' regarni restent au registre sans partir ; un regarni part comme un plant. Sans
#' plant a verser, aucune de ces couches n'est ecrite. A l'import, ces lignes ne se
#' reinscrivent pas : le plant est deja au registre, et l'etat porte sur un
#' controle deja inscrit.
#'
#' **Le champ `action_id`** des trois couches de travaux est celui de l'action
#' du programme que le travaux realise : l'operateur la choisit dans la liste
#' tiree du programme (table `programme`). Elle passe telle quelle au registre 6.
#'
#' **La couche `photos_terrain`** est celle de Surculus (`docs/spec.md` § 5,
#' amendee le 2026-10-28) : POINT, une ligne par photo, `photo_uuid`
#' (= `photos.uuid`), `sujet` (`placette` ou `plant`), `placette_uuid`,
#' `plant_uuid`, `azimut_visee_mag_deg`, `declinaison_deg`,
#' `modele_geomagnetique`, `precision_m`, `source_gnss`, `referentiel_source`
#' (`RGF93` ou `WGS84`), `age_fix_ms`, `simulee`, `sha256`.
#' [sommier_importer_qfield_travaux()] la lit au retour, si elle est
#' presente. Une colonne obligatoire manquante (`photo_uuid`, `sujet`,
#' `sha256`) refuse la tournee ; une colonne en plus est ignoree et nommee
#' dans les `avertissements` du bilan. Une empreinte vide (non verifiee) ou
#' deux lignes pour la meme photo (la premiere est gardee) sont aussi des
#' avertissements ; chaque ligne reste controlee (sujet inconnu ou empreinte
#' fausse : faute, y compris sur la seconde ligne d'une meme photo). La geometrie POINT est lue et inscrite au payload de la
#' photo, sous `terrain` : `fix_x`, `fix_y` et `fix_scr` (code EPSG de la
#' couche), a cote de `exif_position`, sans conversion de repere.
#'
#' **La symbologie est celle de Marculus** (brief du 2026-10-16) : parcelles
#' coloriees par proprietaire (remplissage a 20 %, contour plein, numero de la
#' parcelle au centre ; gris-vert sans proprietaire), houppiers en contour
#' seul masques par defaut, desserte ocre. Les couleurs sont dans une seule
#' liste interne (`SYMBOLOGIE_MARCULUS`, `R/symbologie_travaux.R`).
#'
#' @return Invisiblement, le chemin du projet `.qgs`.
#'
#' @seealso [sommier_importer_qfield_travaux()]
#'
#' @export
sommier_projet_qfield_travaux <- function(con, foret_id, dossier, operateur,
                                          fond = NULL, ortho = NULL,
                                          programme = NULL,
                                          depot = NULL,
                                          date_ortho = NULL) {
  for (paquet in c("sf", "xml2")) {
    if (!requireNamespace(paquet, quietly = TRUE)) {
      stop("Le paquet `", paquet, "` est requis pour ecrire le projet ",
           "QField.", call. = FALSE)
    }
  }
  ortho <- controler_ortho(ortho)
  foret_id <- valider_uuid(foret_id, "foret_id")
  dossier <- valider_texte(dossier, "dossier")
  operateur <- valider_texte(operateur, "operateur")
  # Lu avant toute ecriture : un programme illisible ne laisse pas de projet.
  actions <- if (!is.null(programme)) sommier_lire_programme_travaux(programme)
  terrain <- preparer_terrain(con, foret_id, dossier)

  copier_modele(dossier, c("travaux.qgs", "travaux_attachments.zip",
                           "travaux.gpkg"))
  gpkg <- file.path(dossier, "travaux.gpkg")
  if (!is.null(actions)) {
    ecrire_table(data.frame(
      action_id = actions$action_id,
      libelle = libelle_action_programme(actions),
      ug = actions$ug_id, stringsAsFactors = FALSE
    ), gpkg, "programme")
  }

  codes <- SOMMIER_CODES_TRAVAUX[, c("code", "libelle", "unites", "formes")]
  codes$libelle <- paste0(codes$code, " - ", codes$libelle)
  # "aucun" : le besoin d'un controle qui ne demande rien. Sans forme,
  # aucune couche de travaux ne le propose.
  codes <- rbind(codes, data.frame(code = "aucun", libelle = "Aucun",
                                   unites = "", formes = ""))
  ecrire_table(codes, gpkg, "codes")

  suivis <- DBI::dbGetQuery(
    con,
    "SELECT t.id::text AS id, u.numero_affichage AS ug, t.annee,
            coalesce(t.code_travaux || ' ', '') || t.nature_travaux AS nature
       FROM v_travaux t JOIN ug u ON u.uuid = t.ug_uuid
      WHERE t.foret_id = $1
      ORDER BY u.numero_affichage, t.annee",
    params = list(foret_id)
  )
  ecrire_table(data.frame(
    id = suivis$id,
    libelle = paste0("UG ", suivis$ug, " - ", suivis$annee, " - ",
                     suivis$nature),
    ug = suivis$ug, stringsAsFactors = FALSE
  ), gpkg, "suivis")

  placettes <- placettes_du_projet(con, foret_id)
  if (nrow(placettes) > 0L) {
    ecrire_couche(sf::st_sf(
      placettes[, c("uuid", "code_placette", "travaux_id", "rayon_m",
                    "materialisation", "ug", "etat_suivi",
                    "dernier_controle", "dernier_besoin")],
      geometry = sf::st_as_sfc(placettes$wkt, crs = 2154)
    ), gpkg, "placettes")
  }

  verser_plants_aller(con, foret_id, gpkg)

  verser_photos_aller(con, foret_id, dossier, gpkg, depot)

  ug <- terrain$ug
  contours <- sf::st_as_sfc(ug$wkt, crs = 2154)
  union <- sf::st_union(contours)
  ecrire_couche(sf::st_sf(nom = terrain$foret$nom[[1L]],
                          geometry = sf::st_cast(union, "MULTIPOLYGON")),
                gpkg, "foret")
  ecrire_couche(sf::st_sf(numero = ug$numero_affichage,
                          geometry = sf::st_cast(contours, "MULTIPOLYGON")),
                gpkg, "ug")
  proprietaires <- ecrire_parcelles(fond, gpkg)

  qgs <- file.path(dossier, "travaux.qgs")
  joindre_ortho(qgs, dossier, ortho, "travaux_ortho", tuilee = TRUE,
                date_ortho = date_ortho)
  if (!is.null(actions)) {
    poser_liste_actions(qgs, actions$action_id, libelle_action_programme(actions))
  }
  poser_cadre_projet(qgs, paste0("Travaux - ", terrain$foret$nom[[1L]]),
                     operateur, foret_id, sf::st_buffer(union, 100))
  poser_symbologie_travaux(qgs, proprietaires)
  invisible(qgs)
}

#' Import d'une tournee de travaux et de suivi des plantations
#'
#' @description
#' Relit le projet rapporte du terrain et inscrit au registre 6 les travaux
#' releves, les placettes installees et les controles saisis, avec leurs
#' photos deposees sous leur empreinte.
#'
#' @details
#' **Tout ou rien.** Chaque saisie est controlee avant toute ecriture : code
#' connu et forme de la couche admise par le code, unite du code, motif d'un
#' ecart au prevu, placette rattachee a des travaux connus, controle sur une
#' placette connue, vivants et abroutis coherents, photos presentes. Une faute
#' fait echouer l'import, qui les liste toutes. Un controle ajoute depuis sa
#' couche, sans placette choisie, se rattache a la placette la plus proche de
#' sa position, a 15 m pres. L'ecriture se fait en une
#' transaction, dans cet ordre : travaux, placettes, controles - une placette
#' peut suivre des travaux releves dans la meme tournee, un controle porter sur
#' une placette qui vient d'etre installee.
#'
#' **La position mesuree des controles.** Si la tournee porte la couche
#' `positions_controles` de Surculus (cle `controle_uuid`, un point par
#' controle), chaque position est inscrite au controle : `geometrie` (WGS 84,
#' reprojetee depuis le SCR de la couche), `precision_m`,
#' `rattache_par_identite`, `sans_position_mesuree`. Une ligne a geometrie NULL
#' (ou POINT EMPTY) donne un controle **sans** geometrie et
#' `sans_position_mesuree = TRUE` : jamais un point (0, 0). Une couche sans SCR,
#' une position hors des bornes WGS 84, une position qui contredit son drapeau
#' ou deux lignes pour un meme controle sont des fautes (rien n'est ecrit) ; une
#' ligne pour un controle absent de la tournee est ignoree et dite aux
#' avertissements. Sans la couche, la tournee s'importe comme avant.
#'
#' **Les plants.** Si la tournee porte les couches `plants` (POINT) et
#' `etats_plants` de Surculus, les plants s'inscrivent entre les placettes et
#' les controles (type `plant`, UUID de la couche), et les etats de chaque
#' controle entrent dans son payload (`plants`), les totaux devant en decouler.
#' Fautes (rien n'est ecrit) : plant sans placette ou sans position, numero deja
#' pris dans la placette, plant deja inscrit sous un autre numero ou une autre
#' placette, regarni qui ne remplace pas un plant mort ou absent de sa placette
#' (le mort peut l'etre dans un controle de la meme tournee), etat d'un plant
#' inconnu ou d'un controle absent de la tournee, deux etats du meme plant dans
#' un controle, totaux qui ne concordent pas avec les etats, plant vivant (ou
#' jamais vu) au passage precedent sans etat, plant mort ou absent redit
#' vivant. Un plant remplace par un regarni d'un passage anterieur n'a plus
#' d'etat a donner. La colonne facultative `methode_pointage` de `plants` doit
#' valoir l'une de [SOMMIER_METHODES_POINTAGE] (sinon faute, rien n'est ecrit) ; un
#' etat dont le controle est deja au registre (ceux verses a l'aller) est ignore.
#' Sans les couches, la tournee s'importe comme avant.
#'
#' **Rejouable.** L'UUID que QField a donne a chaque saisie devient celui de
#' l'entree : reimporter le meme dossier n'ecrit rien de plus. Les placettes
#' deja inscrites, versees dans le projet, ne se reinscrivent pas.
#'
#' **L'unite de gestion** d'une intervention est celle qui contient sa
#' geometrie (le point interieur d'une surface, le milieu d'une ligne) ; hors
#' de toute unite, l'intervention est inscrite a l'echelle de la foret.
#'
#' Toutes les entrees portent NDP 0 : ce sont des constats de terrain.
#'
#' @param con Connexion DBI.
#' @param foret_id UUID de la foret.
#' @param dossier Dossier du projet, rapporte du terrain.
#' @param depot Repertoire du depot de photos.
#' @param auteur Compte qui importe. L'agent qui a releve est l'operateur.
#'
#' @return Invisiblement, un bilan : `travaux`, `placettes`, `plants`,
#'   `controles` (nombres d'entrees ecrites), `deja_presents`, `photos`, `entrees` et
#'   `avertissements` (ecarts de forme acceptes : colonnes en trop de
#'   `photos_terrain`, empreinte vide, photo en double, niveau de concurrence
#'   contredit par les comptages de plants ; chacun est aussi
#'   rendu par `warning()`).
#'
#' @seealso [sommier_projet_qfield_travaux()], [sommier_verifier_photos()]
#'
#' @export
sommier_importer_qfield_travaux <- function(con, foret_id, dossier, depot,
                                            auteur) {
  if (!requireNamespace("sf", quietly = TRUE)) {
    stop("Le paquet `sf` est requis pour lire le projet QField.",
         call. = FALSE)
  }
  foret_id <- valider_uuid(foret_id, "foret_id")
  dossier <- valider_texte(dossier, "dossier")
  depot <- valider_texte(depot, "depot")
  auteur <- valider_texte(auteur, "auteur")
  gpkg <- file.path(dossier, "travaux.gpkg")
  if (!file.exists(gpkg)) {
    stop("Pas de travaux.gpkg dans ", dossier, " : ce n'est pas un projet ",
         "engendre par sommier_projet_qfield_travaux().", call. = FALSE)
  }
  lire <- function(nom) suppressWarnings(sf::read_sf(gpkg, layer = nom))
  travaux <- do.call(rbind, lapply(names(COUCHES_TRAVAUX), function(nom) {
    t <- lire(nom)
    if (nrow(t) == 0L) return(NULL)
    t$couche <- nom
    sf::st_geometry(t) <- "geometry"
    # Une couche sans la colonne (projet d'avant 0.41.0) : pas d'action, pas
    # une faute ; et rbind exige les memes colonnes partout.
    if (!"action_id" %in% names(t)) t$action_id <- NA_character_
    t
  }))
  programme <- if ("programme" %in% sf::st_layers(gpkg)$name) {
    as.data.frame(lire("programme"))$action_id
  }
  placettes <- lire("placettes")
  controles <- rattacher_controles(lire("controles"), placettes)
  photos <- as.data.frame(lire("photos"))
  # Couche ajoutee (brief du 2026-10-28) : un projet engendre avant elle n'en
  # porte pas, et la tournee s'importe comme avant.
  photos_terrain <- lire_photos_terrain(gpkg)
  # Couche de Surculus (brief du 2026-10-22) : la position mesuree de chaque
  # controle. Absente d'une tournee ancienne : elle s'importe comme avant.
  positions <- lire_positions_controles(gpkg)
  # Couches de Surculus (brief travaux-2) : les plants pointes et leurs etats.
  # Absentes d'une tournee ancienne : elle s'importe comme avant.
  plants_tournee <- lire_plants_tournee(gpkg)
  bilan <- list(travaux = 0L, placettes = 0L, plants = 0L, controles = 0L,
                deja_presents = 0L, photos = 0L, entrees = list(),
                avertissements = c(
                  avertir_photos_terrain(photos_terrain),
                  avertir_positions_orphelines(positions, controles$uuid)))

  uuids_plants <- if (!is.null(plants_tournee$plants)) {
    tolower(as.character(plants_tournee$plants$uuid))
  }
  ids <- tolower(c(if (!is.null(travaux)) travaux$uuid, placettes$uuid,
                   uuids_plants, controles$uuid))
  presents <- if (length(ids) == 0L) character(0) else DBI::dbGetQuery(
    con, "SELECT id::text AS id FROM entree_sommier WHERE id = ANY($1::uuid[])",
    params = list(paste0("{", paste(ids[!is.na(ids)], collapse = ","), "}"))
  )$id
  garder <- function(x) {
    if (is.null(x) || nrow(x) == 0L) return(x)
    x$uuid <- tolower(x$uuid)
    x[!x$uuid %in% presents, , drop = FALSE]
  }
  bilan$deja_presents <- sum(ids %in% presents)
  travaux <- garder(travaux)
  placettes <- garder(placettes)
  controles_tournee <- data.frame(
    uuid = tolower(controles$uuid),
    jour = as.Date(vapply(seq_len(nrow(controles)), function(i) {
      format(jour_paris(controles$visite_le[i]))
    }, character(1))), stringsAsFactors = FALSE)
  controles <- garder(controles)
  plants_a_ecrire <- if (length(uuids_plants) > 0L) {
    which(!is.na(uuids_plants) & !uuids_plants %in% presents)
  } else integer(0)
  if ((is.null(travaux) || nrow(travaux) == 0L) && nrow(placettes) == 0L &&
      nrow(controles) == 0L && length(plants_a_ecrire) == 0L) {
    return(invisible(bilan))
  }

  connus <- DBI::dbGetQuery(
    con, "SELECT id::text AS id, ug_uuid::text AS ug_uuid FROM v_travaux
           WHERE foret_id = $1", params = list(foret_id))
  placettes_connues <- DBI::dbGetQuery(
    con, "SELECT id::text AS id FROM v_placette WHERE foret_id = $1",
    params = list(foret_id))$id
  plants_db <- DBI::dbGetQuery(
    con, "SELECT id::text AS plant_id, placette_id::text AS placette_id,
                 numero, pointe_le, remplace_uuid::text AS remplace_uuid
            FROM v_plant WHERE foret_id = $1", params = list(foret_id))
  plants_db$pointe_le <- as.Date(plants_db$pointe_le)
  histoire_db <- DBI::dbGetQuery(
    con, "SELECT plant_id::text AS plant_id, visite_le AS jour, etat
            FROM v_etat_plant WHERE foret_id = $1", params = list(foret_id))
  histoire_db$jour <- as.Date(histoire_db$jour)
  # Les controles deja au registre : les etats que l'aller a verses s'y
  # rattachent et ne sont pas rejoues.
  controles_db <- DBI::dbGetQuery(
    con, "SELECT id::text AS id FROM v_controle_plantation
           WHERE foret_id = $1", params = list(foret_id))$id
  plants_prets <- preparer_plants_tournee(
    plants_tournee, controles,
    placettes_valides = c(placettes_connues, tolower(placettes$uuid)),
    controles_tournee = controles_tournee, plants_db = plants_db,
    histoire_db = histoire_db, controles_db = controles_db)
  fautes <- controler_tournee_travaux(
    travaux, placettes, controles, photos, dossier,
    travaux_connus = connus$id, placettes_connues = placettes_connues,
    programme = programme, photos_terrain = photos_terrain,
    positions = positions, plants_prets = plants_prets)
  if (length(fautes) > 0L) {
    stop("Import refuse, rien n'est ecrit :\n",
         paste0("- ", fautes, collapse = "\n"), call. = FALSE)
  }

  ug <- DBI::dbGetQuery(
    con, "SELECT u.uuid::text AS uuid, ST_AsText(g.geom) AS wkt
            FROM ug u JOIN ug_geometrie g ON g.ug_uuid = u.uuid
           WHERE u.foret_id = $1 AND g.date_fin IS NULL",
    params = list(foret_id))
  photo <- function(uuid) {
    deposees <- deposer_photos_travaux(uuid, photos, photos_terrain, dossier,
                                       depot)
    bilan$photos <<- bilan$photos + length(deposees)
    if (length(deposees) > 0L) deposees
  }

  transaction(con, {
    if (!is.null(travaux) && nrow(travaux) > 0L) {
      unites <- ug_des_geometries(travaux, ug)
      geometries <- geometries_wgs84(travaux)
      entrees <- lapply(seq_len(nrow(travaux)), function(i) {
        t <- as.data.frame(travaux)[i, ]
        visite <- as.POSIXct(t$visite_le)
        sommier_entree(
          foret_id = foret_id, registre = 6L,
          date_evenement = if (!is.na(t$date_reception))
            as.Date(t$date_reception) else as.Date(format(visite, "%Y-%m-%d")),
          auteur = auteur, ug_uuid = unites[[i]], ndp = 0L, id = t$uuid,
          payload = payload_travaux(t, geometries[[i]], photo(t$uuid))
        )
      })
      ecrites <- sommier_ajouter(con, entrees)
      bilan$travaux <- length(ecrites)
      bilan$entrees <- c(bilan$entrees, ecrites)
    }
    if (nrow(placettes) > 0L) {
      centres <- positions_wgs84(placettes)
      ecrites <- lapply(seq_len(nrow(placettes)), function(i) {
        p <- as.data.frame(placettes)[i, ]
        sommier_installer_placette(
          con, p$travaux_id, p$code_placette, centres[[i]], auteur,
          date_evenement = Sys.Date(), id = p$uuid,
          rayon_m = if (is.na(p$rayon_m)) 3.99 else p$rayon_m,
          materialisation = texte_ou_null(p$materialisation)
        )[[1L]]
      })
      bilan$placettes <- length(ecrites)
      bilan$entrees <- c(bilan$entrees, ecrites)
    }
    if (length(plants_prets$nouveaux) > 0L) {
      pp <- plants_tournee$plants
      ecrites <- lapply(plants_prets$nouveaux, function(i) {
        champs <- champs_plant(pp, i)
        jour <- format(jour_paris(pp$pointe_le[[i]]))
        do.call(sommier_pointer_plant, c(
          list(con, tolower(pp$placette_uuid[[i]]),
               plants_tournee$geometries[[i]], pp$numero[[i]], auteur,
               date_evenement = jour, id = tolower(pp$uuid[[i]]),
               verifier_regarni = FALSE), champs))[[1L]]
      })
      bilan$plants <- length(ecrites)
      bilan$entrees <- c(bilan$entrees, ecrites)
    }
    if (nrow(controles) > 0L) {
      ecrites <- lapply(seq_len(nrow(controles)), function(i) {
        k <- controles[i, ]
        cpt <- comptages_concurrence(k)
        prets <- plants_prets$par_controle[[tolower(k$uuid)]]
        pos <- position_du_controle(positions, k$uuid)
        # Tous les avertissements de sommier_controler_placette() (dont
        # l'ecart entre niveau saisi et comptages, un warning() de
        # registre6_controle()) vont au bilan, comme les autres.
        withCallingHandlers(
          sommier_controler_placette(
            con, tolower(k$placette_uuid), k$nb_total, k$nb_vivants, auteur,
            visite_le = as.POSIXct(k$visite_le), id = k$uuid,
            h_moy_cm = nombre_ou_null(k$h_moy_cm),
            nb_abroutis = nombre_ou_null(k$nb_abroutis),
            nb_plants_vivants = cpt$nb_plants_vivants,
            nb_plants_concurrences = cpt$nb_plants_concurrences,
            concurrence = texte_ou_null(k$concurrence),
            besoin = texte_ou_null(k$besoin),
            operateur = texte_ou_null(k$operateur),
            releve_uuid = k$uuid,
            photos = photo(k$uuid),
            observations = texte_ou_null(k$observations),
            geometrie = pos$geometrie,
            precision_m = pos$precision_m,
            rattache_par_identite = pos$rattache_par_identite,
            sans_position_mesuree = pos$sans_position_mesuree,
            plants = prets$plants, plants_remplaces = prets$remplaces,
            verifier_plants = FALSE
          ),
          warning = function(w) {
            bilan$avertissements <<- c(
              bilan$avertissements,
              paste0("controle ", i, " : ", conditionMessage(w)))
            invokeRestart("muffleWarning")
          })[[1L]]
      })
      bilan$controles <- length(ecrites)
      bilan$entrees <- c(bilan$entrees, ecrites)
    }
  })
  for (a in bilan$avertissements) {
    warning(a, call. = FALSE)
  }
  invisible(bilan)
}

# ---------------------------------------------------------------------------

# Un controle saisi depuis sa couche, et non depuis la fiche d'une placette,
# n'en porte pas l'identifiant : il se rattache a la placette du projet la
# plus proche de sa position, a RAYON_RATTACHEMENT_M pres. Au-dela, il reste
# sans placette, et l'import le refuse.
RAYON_RATTACHEMENT_M <- 15

rattacher_controles <- function(controles, placettes) {
  # Un projet engendre avant la v0.31.0 n'a pas de position aux controles :
  # la placette saisie fait foi, a defaut l'import refuse.
  if (!inherits(controles, "sf")) {
    return(as.data.frame(controles))
  }
  manquants <- is.na(controles$placette_uuid) &
    !sf::st_is_empty(sf::st_geometry(controles))
  if (any(manquants) && nrow(placettes) > 0L) {
    proches <- sf::st_nearest_feature(controles[manquants, ], placettes)
    distances <- as.numeric(sf::st_distance(
      controles[manquants, ], placettes[proches, ], by_element = TRUE))
    controles$placette_uuid[manquants] <- ifelse(
      distances <= RAYON_RATTACHEMENT_M, placettes$uuid[proches], NA_character_)
  }
  as.data.frame(sf::st_drop_geometry(controles))
}

# Les couches de saisie des travaux, et la forme qu'elles portent.
COUCHES_TRAVAUX <- c(travaux_surf = "surface", travaux_lin = "ligne",
                     travaux_pt = "point")

ecrire_table <- function(x, gpkg, nom) {
  sf::st_write(x, gpkg, layer = nom, delete_layer = TRUE, quiet = TRUE)
}

# Les placettes deja inscrites, avec l'etat de leur dernier controle.
placettes_du_projet <- function(con, foret_id) {
  p <- DBI::dbGetQuery(
    con,
    "SELECT p.id::text AS uuid, p.code_placette, p.travaux_id::text AS travaux_id,
            p.rayon_m::float8 AS rayon_m, p.materialisation,
            u.numero_affichage AS ug, ST_AsText(p.geom) AS wkt,
            d.visite_le AS dernier_controle, d.besoin AS dernier_besoin
       FROM v_placette p
       LEFT JOIN ug u ON u.uuid = p.ug_uuid
       LEFT JOIN (SELECT DISTINCT ON (placette_id) placette_id, visite_le, besoin
                    FROM v_controle_plantation
                   ORDER BY placette_id, visite_le DESC, seq DESC) d
              ON d.placette_id = p.id
      WHERE p.foret_id = $1 AND p.geom IS NOT NULL
      ORDER BY u.numero_affichage, p.code_placette",
    params = list(foret_id)
  )
  p$etat_suivi <- ifelse(is.na(p$dernier_controle), "jamais",
                         ifelse(is.na(p$dernier_besoin) |
                                  p$dernier_besoin == "aucun",
                                "a_jour", "a_programmer"))
  p
}

controler_tournee_travaux <- function(travaux, placettes, controles, photos,
                                      dossier, travaux_connus,
                                      placettes_connues, programme = NULL,
                                      photos_terrain = NULL,
                                      positions = NULL,
                                      plants_prets = NULL) {
  fautes <- controler_photos_terrain(photos_terrain, photos, dossier)
  fautes <- c(fautes, positions$fautes, plants_prets$fautes)
  if (!is.null(travaux) && nrow(travaux) > 0L) {
    t <- as.data.frame(travaux)
    for (i in seq_len(nrow(t))) {
      x <- t[i, ]
      nom <- paste0("travaux ", i, " (", x$couche, ")")
      if (is.na(x$uuid) || !grepl(MOTIF_UUID, x$uuid)) {
        fautes <- c(fautes, paste0(nom, " : identifiant absent ou invalide"))
        next
      }
      if (is.na(x$code_travaux) ||
          !x$code_travaux %in% SOMMIER_CODES_TRAVAUX$code) {
        fautes <- c(fautes, paste0(nom, " : code inconnu (",
                                   x$code_travaux, ")"))
        next
      }
      formes <- alternatives(SOMMIER_CODES_TRAVAUX$formes[
        SOMMIER_CODES_TRAVAUX$code == x$code_travaux])
      if (!COUCHES_TRAVAUX[[x$couche]] %in% formes) {
        fautes <- c(fautes, paste0(nom, " : un ", x$code_travaux, " ne se ",
                                   "trace pas en ", COUCHES_TRAVAUX[[x$couche]]))
      }
      if (is.na(x$visite_le) && is.na(x$date_reception)) {
        fautes <- c(fautes, paste0(nom, " : ni date de releve ni de reception"))
      }
      if (!is.null(programme) && !is.null(texte_ou_null(x$action_id)) &&
          !x$action_id %in% programme) {
        fautes <- c(fautes, paste0(nom, " : action_id ", x$action_id,
                                   " absent du programme du projet"))
      }
      essai <- tryCatch({
        payload_travaux(x, NULL, NULL); NULL
      }, error = function(e) conditionMessage(e))
      if (!is.null(essai)) fautes <- c(fautes, paste0(nom, " : ", essai))
      fautes <- c(fautes, controler_photos_constat(x, nom, photos, dossier))
    }
  }
  nouveaux_travaux <- if (!is.null(travaux)) tolower(travaux$uuid)
  p <- as.data.frame(placettes)
  for (i in seq_len(nrow(p))) {
    x <- p[i, ]
    nom <- paste0("placette ", if (is.na(x$code_placette)) i else
      x$code_placette)
    if (is.na(x$uuid) || !grepl(MOTIF_UUID, x$uuid)) {
      fautes <- c(fautes, paste0(nom, " : identifiant absent ou invalide"))
    }
    if (is.na(x$code_placette)) {
      fautes <- c(fautes, paste0(nom, " : sans code"))
    }
    if (is.na(x$travaux_id) || !tolower(x$travaux_id) %in%
        c(travaux_connus, nouveaux_travaux)) {
      fautes <- c(fautes, paste0(nom, " : travaux suivis inconnus"))
    }
  }
  doubles <- unique(p$code_placette[duplicated(p$code_placette)])
  for (d in doubles[!is.na(doubles)]) {
    fautes <- c(fautes, paste0("placette ", d, " : installee deux fois"))
  }
  connues <- c(placettes_connues, tolower(p$uuid))
  for (i in seq_len(nrow(controles))) {
    x <- controles[i, ]
    nom <- paste0("controle ", i)
    if (is.na(x$uuid) || !grepl(MOTIF_UUID, x$uuid)) {
      fautes <- c(fautes, paste0(nom, " : identifiant absent ou invalide"))
    }
    if (is.na(x$placette_uuid)) {
      fautes <- c(fautes, paste0(nom, " : aucune placette choisie, ni a moins ",
                                 "de ", RAYON_RATTACHEMENT_M, " m"))
    } else if (!tolower(x$placette_uuid) %in% connues) {
      fautes <- c(fautes, paste0(nom, " : placette inconnue"))
    }
    if (is.na(x$visite_le)) {
      fautes <- c(fautes, paste0(nom, " : date de controle absente"))
    }
    cpt <- comptages_concurrence(x)
    pos <- position_du_controle(positions, x$uuid)
    prets <- plants_prets$par_controle[[tolower(x$uuid)]]
    essai <- tryCatch(suppressWarnings({
      registre6_controle(
        uuid_v4(), x$nb_total, x$nb_vivants,
        plants = prets$plants, plants_remplaces = prets$remplaces,
        h_moy_cm = nombre_ou_null(x$h_moy_cm),
        nb_abroutis = nombre_ou_null(x$nb_abroutis),
        nb_plants_vivants = cpt$nb_plants_vivants,
        nb_plants_concurrences = cpt$nb_plants_concurrences,
        concurrence = texte_ou_null(x$concurrence),
        besoin = texte_ou_null(x$besoin),
        geometrie = pos$geometrie,
        precision_m = pos$precision_m,
        rattache_par_identite = pos$rattache_par_identite,
        sans_position_mesuree = pos$sans_position_mesuree)
      NULL
    }), error = function(e) conditionMessage(e))
    if (!is.null(essai)) fautes <- c(fautes, paste0(nom, " : ", essai))
    fautes <- c(fautes, controler_photos_constat(x, nom, photos, dossier))
  }
  avec <- !is.na(controles$placette_uuid)
  jours <- paste(tolower(controles$placette_uuid[avec]),
                 vapply(controles$visite_le[avec], function(v) {
                   format(jour_paris(v))
                 }, character(1)))
  if (any(duplicated(jours))) {
    fautes <- c(fautes, "deux controles d'une meme placette le meme jour")
  }
  fautes
}

# Les deux comptages de plants d'un controle (nb_plants_vivants,
# nb_plants_concurrences : les noms de l'API R, la spec de Surculus ne les nomme
# pas). Colonnes absentes (tournee d'un ancien format) ou NA : rien. Les regles
# de valeur sont celles de registre6_controle(), qui les refuse si elles sont
# contredites (concurrences > vivants, vivants notes > vivants). Un
# nb_plants_concurrences sans vivants reste lisible : il est garde brut au
# payload, sans niveau deduit ni compare ; c'est registre6_controle() qui le
# signale (un seul message, relaye au bilan).
comptages_concurrence <- function(x) {
  prendre <- function(nom) {
    if (!nom %in% names(x)) return(NULL)
    nombre_ou_null(x[[nom]][1L])
  }
  viv <- prendre("nb_plants_vivants")
  con <- prendre("nb_plants_concurrences")
  list(nb_plants_vivants = viv, nb_plants_concurrences = con)
}

payload_travaux <- function(t, geometrie, photos) {
  visite <- if (!is.na(t$visite_le)) as.POSIXct(t$visite_le)
  annee <- if (!is.na(t$annee)) t$annee else
    as.integer(format(visite %||% Sys.Date(), "%Y"))
  registre6_travaux(
    annee = annee,
    nature_travaux = texte_ou_null(t$nature_travaux) %||% t$code_travaux,
    quantite = nombre_ou_null(t$quantite),
    unite = texte_ou_null(t$unite),
    nb_plants = nombre_ou_null(t$nb_plants),
    montant_eur = nombre_ou_null(t$montant_eur),
    observations = texte_ou_null(t$observations),
    code_travaux = t$code_travaux,
    modalite = texte_ou_null(t$modalite),
    essence_objectif = texte_ou_null(t$essence_objectif),
    execution = texte_ou_null(t$execution),
    intervenant = texte_ou_null(t$intervenant),
    prevu = texte_ou_null(t$prevu),
    motif_ecart = texte_ou_null(t$motif_ecart),
    date_reception = if (!is.na(t$date_reception)) as.Date(t$date_reception),
    geometrie = geometrie,
    precision_m = nombre_ou_null(t$precision_m),
    source_gnss = texte_ou_null(t$source_gnss),
    photos = photos,
    action_id = texte_ou_null(t$action_id)
  )
}

# La liste des actions du programme au champ `action_id` des trois couches de
# travaux : un ValueMap (libelle affiche, identifiant stocke), pour ne pas
# recopier un identifiant de 23 caracteres.
poser_liste_actions <- function(qgs, ids, libelles) {
  xml <- paste(readLines(qgs, warn = FALSE, encoding = "UTF-8"),
               collapse = "\n")
  entrees <- paste0(
    '<Option type="Map"><Option name="', echapper_xml(libelles),
    '" value="', echapper_xml(ids), '" type="QString"/></Option>',
    collapse = "")
  champ <- paste0(
    '<field name="action_id" configurationFlags="NoFlag">',
    '<editWidget type="ValueMap"><config><Option type="Map">',
    '<Option name="map" type="List">', entrees, '</Option>',
    '</Option></config></editWidget></field>\n      ')
  for (couche in names(COUCHES_TRAVAUX)) {
    debut <- regexpr(paste0("<id>travaux_", couche, "</id>"), xml, fixed = TRUE)
    if (debut < 0L) stop("Couche ", couche, " absente du modele.", call. = FALSE)
    fin <- regexpr("</fieldConfiguration>",
                   substr(xml, debut, nchar(xml)), fixed = TRUE)
    pos <- debut + fin - 1L
    xml <- paste0(substr(xml, 1L, pos - 1L), champ,
                  substr(xml, pos, nchar(xml)))
  }
  writeLines(enc2utf8(strsplit(xml, "\n", fixed = TRUE)[[1L]]), qgs,
             useBytes = TRUE)
}

# L'unite qui contient le point interieur de chaque geometrie ; NULL hors de
# toute unite.
ug_des_geometries <- function(x, ug) {
  if (nrow(ug) == 0L) return(vector("list", nrow(x)))
  formes <- sf::st_as_sfc(ug$wkt, crs = 2154)
  points <- sf::st_point_on_surface(sf::st_geometry(x))
  dedans <- sf::st_intersects(points, formes)
  lapply(dedans, function(i) if (length(i) == 0L) NULL else ug$uuid[[i[[1L]]]])
}

# Une geometrie de saisie, en WGS84 comme toute geometrie de payload.
geometries_wgs84 <- function(x) {
  g <- sf::st_transform(sf::st_geometry(x), 4326)
  lapply(seq_along(g), function(i) {
    if (sf::st_is_empty(g[[i]])) return(NULL)
    m <- sf::st_coordinates(g[[i]])[, 1:2, drop = FALSE]
    switch(
      as.character(sf::st_geometry_type(g[[i]])),
      POINT = geom_point(m[1L, 1L], m[1L, 2L]),
      LINESTRING = geom_ligne(m),
      POLYGON = geom_polygone(m[-nrow(m), , drop = FALSE]),
      NULL
    )
  })
}

# ---------------------------------------------------------------------------
# photos_terrain : ce que la tournee dit de la prise de vue. La couche est
# celle de Surculus (docs/spec.md § 5, amendee le 2026-10-28) : POINT, une
# ligne par photo ; sommieR la lit au retour et ne l'ecrit jamais a l'aller.

# Les colonnes que sommieR exige : sans elles, la ligne ne dit pas de quelle
# photo elle parle ni si le fichier est celui que l'appareil a ecrit.
COLONNES_PHOTOS_TERRAIN_EXIGEES <- c("photo_uuid", "sujet", "sha256")

# Les colonnes du fichier qui ne sont pas des champs (cle, geometrie).
COLONNES_GPKG <- c("fid", "geom", "geometry")

# Les colonnes que sommieR ajoute a la lecture : la position du fix.
COLONNES_FIX <- c("fix_x", "fix_y", "fix_scr")

# La couche `positions_controles` de Surculus (brief du 2026-10-22, complete le
# 2026-11-02) : une ligne par controle, cle `controle_uuid`, un POINT de la
# position mesuree, ou une geometrie NULL quand le controle a ete ouvert sans
# aucun fix. NULL si la couche est absente ; sinon `par_controle` (liste
# nommee par uuid, chaque element avec `geometrie` WGS 84, `precision_m`,
# `rattache_par_identite`, `sans_position_mesuree`, les champs inconnus
# restant NULL) et `fautes`. Une geometrie vide (NULL, POINT EMPTY, NaN) donne
# `sans_position_mesuree = TRUE` et aucune geometrie : jamais un point (0, 0).
lire_positions_controles <- function(gpkg) {
  if (!"positions_controles" %in% sf::st_layers(gpkg)$name) {
    return(NULL)
  }
  x <- suppressWarnings(sf::read_sf(gpkg, layer = "positions_controles"))
  n <- nrow(x)
  par_controle <- list()
  fautes <- character(0)
  if (n == 0L) {
    return(list(par_controle = par_controle, fautes = fautes, uuids = character(0)))
  }
  if (!"controle_uuid" %in% names(x)) {
    return(list(par_controle = par_controle, uuids = character(0),
                fautes = "positions_controles : colonne controle_uuid absente"))
  }
  g <- if (inherits(x, "sf")) sf::st_geometry(x) else NULL
  # Un GeoPackage sans SCR relit un repere « Undefined Cartesian SRS » : il
  # ne se transforme pas, il ne dit rien du lieu.
  crs_connu <- !is.null(g) && !is.na(sf::st_crs(g)) &&
    !grepl("Undefined", sf::st_crs(g)$wkt, fixed = TRUE)
  colonne <- function(nom, i) {
    if (!nom %in% names(x)) return(NA)
    x[[nom]][[i]]
  }
  uuids <- tolower(as.character(x$controle_uuid))
  for (i in seq_len(n)) {
    u <- uuids[[i]]
    nom <- paste0("positions_controles ligne ", i)
    if (is.na(u) || !grepl(MOTIF_UUID, u)) {
      fautes <- c(fautes, paste0(nom, " : controle_uuid absent ou invalide"))
      next
    }
    if (!is.null(par_controle[[u]])) {
      fautes <- c(fautes, paste0(nom, " : deux positions pour le controle ", u))
      next
    }
    vide <- is.null(g) || sf::st_is_empty(g[[i]]) ||
      any(!is.finite(sf::st_coordinates(g[[i]])[, 1:2]))
    point <- NULL
    if (!vide) {
      if (!crs_connu) {
        fautes <- c(fautes, paste0(nom, " : la couche n'a pas de systeme de ",
                                   "coordonnees, la position ne se place pas"))
        next
      }
      point <- tryCatch({
        m <- sf::st_coordinates(sf::st_transform(g[i], 4326))[1L, 1:2]
        geom_point(m[[1L]], m[[2L]])
      }, error = function(e) {
        fautes <<- c(fautes, paste0(nom, " : position hors des bornes WGS 84 (",
                                    conditionMessage(e), ")"))
        NULL
      })
      if (is.null(point)) next
    }
    booleen <- function(nom) {
      v <- colonne(nom, i)
      if (length(v) == 0L || is.na(v)) NULL else as.logical(v)
    }
    sans <- if (vide) TRUE else booleen("sans_position_mesuree")
    par_controle[[u]] <- list(
      geometrie = point,
      precision_m = nombre_ou_null(colonne("precision_m", i)),
      rattache_par_identite = booleen("rattache_par_identite"),
      sans_position_mesuree = sans)
  }
  list(par_controle = par_controle, fautes = fautes, uuids = unique(uuids))
}

# Ce que la couche dit d'un controle ; NULL (aucun champ) s'il n'y figure pas :
# le controle s'ecrit alors comme avant, sans position ni drapeau.
position_du_controle <- function(positions, uuid) {
  if (is.null(positions) || is.na(uuid)) return(NULL)
  positions$par_controle[[tolower(uuid)]]
}

# Une ligne de la couche pour un controle absent de la tournee : gardee nulle
# part, donc dite.
avertir_positions_orphelines <- function(positions, uuids_controles) {
  if (is.null(positions)) return(character(0))
  orphelines <- setdiff(positions$uuids, tolower(uuids_controles))
  if (length(orphelines) == 0L) return(character(0))
  paste0("positions_controles : ", length(orphelines), " ligne(s) pour un ",
         "controle absent de la tournee, ignoree(s) : ",
         paste(orphelines, collapse = ", "))
}

# La couche, lue telle que Surculus l'ecrit. NULL si elle est absente (un
# projet d'avant le brief) ; sinon une table sans geometrie.
lire_photos_terrain <- function(gpkg) {
  couches <- sf::st_layers(gpkg)$name
  if (!"photos_terrain" %in% couches) {
    return(NULL)
  }
  pt <- suppressWarnings(sf::read_sf(gpkg, layer = "photos_terrain"))
  fix <- NULL
  if (inherits(pt, "sf")) {
    fix <- position_du_fix(pt)
    pt <- sf::st_drop_geometry(pt)
  }
  pt <- as.data.frame(pt)
  if (!is.null(fix)) {
    pt$fix_x <- fix$x
    pt$fix_y <- fix$y
    pt$fix_scr <- fix$scr
  }
  pt
}

# La position du fix : la geometrie POINT de chaque ligne, telle que la couche
# l'ecrit, avec le SCR de la couche (code EPSG). Aucune conversion de repere :
# comme `exif_position`, c'est une declaration de l'appareil. Une ligne sans
# point (Surculus n'ecrit aucune position si le fix a plus de 5 s ou est
# simule) ou une couche sans SCR connu n'a pas de position.
position_du_fix <- function(pt) {
  n <- nrow(pt)
  vide <- list(x = rep(NA_real_, n), y = rep(NA_real_, n),
               scr = rep(NA_character_, n))
  g <- sf::st_geometry(pt)
  if (n == 0L || !inherits(g, "sfc_POINT")) {
    return(vide)
  }
  epsg <- sf::st_crs(pt)$epsg
  if (is.null(epsg) || is.na(epsg)) {
    return(vide)
  }
  xy <- sf::st_coordinates(g)[, 1:2, drop = FALSE]
  vivant <- !sf::st_is_empty(g) & stats::complete.cases(xy)
  list(x = ifelse(vivant, xy[, 1L], NA_real_),
       y = ifelse(vivant, xy[, 2L], NA_real_),
       scr = ifelse(vivant, paste0("EPSG:", epsg), NA_character_))
}

# Les fautes qui refusent la tournee, en clair : une couche aux colonnes
# obligatoires manquantes, une ligne qui ne decrit aucune photo, un sujet
# inconnu, une empreinte qui n'est pas celle du fichier rapporte.
controler_photos_terrain <- function(pt, photos, dossier) {
  if (is.null(pt)) {
    return(character(0))
  }
  manquantes <- setdiff(COLONNES_PHOTOS_TERRAIN_EXIGEES, names(pt))
  fautes <- character(0)
  if (length(manquantes) > 0L) {
    fautes <- c(fautes, paste0(
      "photos_terrain : colonne(s) manquante(s) : ",
      paste(manquantes, collapse = ", ")))
  }
  if (length(manquantes) > 0L || nrow(pt) == 0L) {
    return(fautes)
  }
  for (i in seq_len(nrow(pt))) {
    x <- pt[i, ]
    nom <- paste0("photos_terrain ", i)
    cible <- which(tolower(photos$uuid) == tolower(x$photo_uuid))
    if (is.na(x$photo_uuid) || length(cible) == 0L) {
      fautes <- c(fautes, paste0(nom, " : aucune photo de la couche photos ",
                                 "ne porte cet identifiant"))
      next
    }
    if (is.na(x$sujet) || !x$sujet %in% c("placette", "plant")) {
      fautes <- c(fautes, paste0(nom, " : sujet inconnu (",
                                 if (is.na(x$sujet)) "vide" else x$sujet,
                                 "), attendu placette ou plant"))
    }
    f <- file.path(dossier, photos$fichier[[cible[[1L]]]])
    # Une empreinte vide n'est pas verifiable : avertissement, pas faute.
    if (!est_vide_vec(x$sha256) && file.exists(f) &&
        !identical(empreinte_fichier(f), tolower(x$sha256))) {
      fautes <- c(fautes, paste0(nom, " : le sha256 declare n'est pas ",
                                 "celui du fichier (", basename(f), ")"))
    }
  }
  fautes
}

# Les ecarts de forme qui n'empechent pas la lecture : la tournee s'importe, le
# compte rendu les nomme (un lecteur ignore les champs en plus, spec de
# Surculus). Colonnes en trop (ignorees), empreinte vide (non verifiee), deux
# lignes pour la meme photo (la premiere est gardee).
avertir_photos_terrain <- function(pt) {
  if (is.null(pt)) {
    return(character(0))
  }
  avertissements <- character(0)
  en_trop <- setdiff(names(pt), c(CHAMPS_PHOTO_TERRAIN, "photo_uuid",
                                  COLONNES_GPKG, COLONNES_FIX))
  if (length(en_trop) > 0L) {
    avertissements <- c(avertissements, paste0(
      "photos_terrain : colonne(s) inconnue(s) ignoree(s) : ",
      paste(en_trop, collapse = ", ")))
  }
  if (all(c("photo_uuid", "sha256") %in% names(pt))) {
    vides <- which(est_vide_vec(pt$sha256))
    if (length(vides) > 0L) {
      avertissements <- c(avertissements, paste0(
        "photos_terrain : sha256 vide, empreinte non verifiee (ligne(s) ",
        paste(vides, collapse = ", "), ")"))
    }
    id <- tolower(pt$photo_uuid)
    doubles <- unique(id[!is.na(id) & duplicated(id)])
    if (length(doubles) > 0L) {
      avertissements <- c(avertissements, paste0(
        "photos_terrain : plusieurs lignes pour la meme photo (",
        paste(doubles, collapse = ", "), ") : la premiere est gardee"))
    }
  }
  avertissements
}

est_vide_vec <- function(x) is.na(x) | !nzchar(trimws(as.character(x)))

# Les photos d'un constat, deposees, avec leur identifiant et ce que la
# tournee dit de leur prise de vue.
deposer_photos_travaux <- function(uuid, photos, photos_terrain, dossier,
                                   depot) {
  siennes <- photos[tolower(photos$constat_uuid) == uuid, , drop = FALSE]
  lapply(seq_len(nrow(siennes)), function(i) {
    p <- sommier_deposer_photo(file.path(dossier, siennes$fichier[[i]]), depot)
    if (!is.na(siennes$uuid[[i]])) {
      p$uuid <- tolower(siennes$uuid[[i]])
    }
    if (!is.null(photos_terrain) && nrow(photos_terrain) > 0L) {
      t <- photos_terrain[tolower(photos_terrain$photo_uuid) ==
                            tolower(siennes$uuid[[i]]), , drop = FALSE]
      if (nrow(t) > 0L) {
        t <- as.list(t[1L, intersect(names(t), c(CHAMPS_PHOTO_TERRAIN,
                                                 COLONNES_FIX)),
                       drop = FALSE])
        # Une valeur vide (empreinte "") n'est pas une declaration.
        t <- t[!vapply(t, function(v) is.character(v) && !nzchar(trimws(v)),
                       logical(1))]
        p$terrain <- t
      }
    }
    p
  })
}

# Verse a l'aller les photos du dernier controle de chaque placette, par le
# canal existant : la couche `photos`, dont le schema ne change pas. La couche
# `photos_terrain` n'est pas ecrite : c'est Surculus qui la cree, en POINT.
verser_photos_aller <- function(con, foret_id, dossier, gpkg, depot) {
  if (is.null(depot)) {
    return(invisible(0L))
  }
  photos <- data.frame(uuid = character(0), constat_uuid = character(0),
                       fichier = character(0),
                       prise_le = as.POSIXct(character(0), tz = "UTC"),
                       stringsAsFactors = FALSE)
  depot <- valider_texte(depot, "depot")
  derniers <- DBI::dbGetQuery(
    con,
    "SELECT DISTINCT ON (c.payload ->> 'placette_id')
            c.id::text AS id, (c.payload -> 'photos')::text AS photos
       FROM entree_sommier c
       JOIN v_placette p ON p.id = (c.payload ->> 'placette_id')::uuid
      WHERE c.foret_id = $1 AND c.registre = 6
        AND c.payload ->> 'type_entree' = 'controle' AND p.geom IS NOT NULL
      ORDER BY c.payload ->> 'placette_id', c.date_evenement DESC, c.seq DESC",
    params = list(foret_id))
  for (k in seq_len(nrow(derniers))) {
    if (is.na(derniers$photos[[k]])) next
    for (p in jsonlite::fromJSON(derniers$photos[[k]],
                                 simplifyVector = FALSE)) {
      source <- tryCatch(chemin_photo(depot, p$sha256, p$type),
                         error = function(e) NA_character_)
      if (is.na(source) || !file.exists(source) ||
          !identical(empreinte_fichier(source), p$sha256)) {
        warning("Photo du controle ", derniers$id[[k]], " non versee a ",
                "l'aller : absente du depot ou alteree (", p$sha256, ").",
                call. = FALSE)
        next
      }
      uuid <- if (is.null(p$uuid)) uuid_v4() else p$uuid
      fichier <- paste0("DCIM/", uuid, ".", tools::file_ext(source))
      file.copy(source, file.path(dossier, fichier), copy.date = TRUE)
      photos[nrow(photos) + 1L, ] <- list(
        uuid, derniers$id[[k]], fichier,
        if (is.null(p$exif_date_utc)) as.POSIXct(NA, tz = "UTC") else
          as.POSIXct(p$exif_date_utc, format = "%Y-%m-%dT%H:%M:%SZ",
                     tz = "UTC"))
    }
  }
  if (nrow(photos) > 0L) {
    ecrire_table(photos, gpkg, "photos")
  }
  invisible(nrow(photos))
}
