#' Pointer un plant
#'
#' @description
#' Inscrit au registre 6 un plant d'une placette de suivi, pointe a la
#' position donnee. Il garde son UUID (l'`id` de l'entree) et son numero d'un
#' passage a l'autre ; son etat a chaque passage est porte par le controle
#' ([sommier_controler_placette()], argument `plants`).
#'
#' @details
#' Une placette inconnue, ou qui n'en est pas une, est refusee, de meme qu'un
#' numero deja pris dans la placette : le numero se donne au premier pointage
#' et ne se recalcule jamais (sommieR le recoit de Surculus, numerotation par
#' azimut depuis le nord, sens horaire ; il ne le calcule pas).
#'
#' L'essence, si elle n'est pas donnee, est celle des travaux suivis par la
#' placette (`essence_objectif`) : une plantation melangee se tient en donnant
#' l'essence de chaque plant.
#'
#' Un regarni (`regarni = TRUE`) remplace exactement un plant **mort ou absent
#' de la meme placette**, deja connu de la base (`remplace_uuid`) : un plant
#' sain ou atteint, d'une autre placette, inconnu, ou deja remplace, est
#' refuse. Le plant remplace compte encore au controle ou le regarni est pose,
#' puis sort des totaux des controles suivants.
#'
#' @param con Connexion DBI.
#' @param placette_id UUID de la placette.
#' @param geometrie La position du plant, un point en WGS84 ([geom_point()]).
#' @param numero Numero du plant dans la placette (entier, au moins 1).
#' @param auteur Compte qui ecrit.
#' @param date_evenement Date du pointage (par defaut, celle de `pointe_le`
#'   si elle est donnee, sinon le jour).
#' @param id UUID de l'entree, donc du plant ; un import de terrain y met celui
#'   du releve.
#' @param ... Champs de [registre6_plant()] : `essence`, `regarni`,
#'   `remplace_uuid`, `distance_m`, `azimut_mag`, `unite_azimut`,
#'   `declinaison_deg`, `convergence_deg`, `azimut_geo_deg`,
#'   `modele_geomagnetique`, `pointe_le`, `observations`.
#'
#' @return Invisiblement, l'entree chainee (liste d'une entree).
#'
#' @seealso [registre6_plant()], [sommier_controler_placette()]
#'
#' @export
sommier_pointer_plant <- function(con, placette_id, geometrie, numero, auteur,
                                  date_evenement = NULL, id = uuid_v4(), ...) {
  sommier_ajouter(con, entree_plant(
    con, placette_id, geometrie, numero, auteur,
    date_evenement = date_evenement, id = id, ...
  ))
}

# ---------------------------------------------------------------------------

# L'entree, sans l'ecrire : l'import d'une tournee ecrit tout en une
# transaction. `verifier_regarni = FALSE` : l'import a deja confronte le regarni
# a l'ensemble de la tournee (le plant remplace peut etre mort dans un controle
# de la meme tournee, pas encore ecrit).
entree_plant <- function(con, placette_id, geometrie, numero, auteur,
                         date_evenement = NULL, id = uuid_v4(),
                         verifier_regarni = TRUE, ...) {
  placette_id <- valider_uuid(placette_id, "placette_id")
  placette <- DBI::dbGetQuery(
    con,
    "SELECT p.foret_id::text AS foret_id, p.ug_uuid::text AS ug_uuid,
            t.essence_objectif
       FROM v_placette p LEFT JOIN v_travaux t ON t.id = p.travaux_id
      WHERE p.id = $1",
    params = list(placette_id)
  )
  if (nrow(placette) == 0L) {
    stop("Placette inconnue : ", placette_id, ".", call. = FALSE)
  }
  champs <- list(...)
  if (est_vide(champs$essence) && !est_vide(placette$essence_objectif[[1L]])) {
    champs$essence <- placette$essence_objectif[[1L]]
  }
  payload <- do.call(registre6_plant, c(
    list(placette_id = placette_id, numero = numero, geometrie = geometrie),
    champs))
  pris <- DBI::dbGetQuery(
    con,
    "SELECT id::text AS id FROM v_plant
      WHERE placette_id = $1 AND numero = $2",
    params = list(placette_id, payload$numero)
  )
  if (nrow(pris) > 0L) {
    stop("Le numero ", payload$numero, " est deja pris dans cette placette (",
         pris$id[[1L]], ").", call. = FALSE)
  }
  jour <- if (!est_vide(date_evenement)) {
    format_date(date_evenement, "date_evenement")
  } else if (!is.null(payload$pointe_le)) {
    substr(payload$pointe_le, 1L, 10L)
  } else {
    format(Sys.Date(), "%Y-%m-%d")
  }
  if (isTRUE(verifier_regarni) && !is.null(payload$remplace_uuid)) {
    fautes <- fautes_regarni(
      id, payload$remplace_uuid, as.Date(jour), placette_id,
      plants_de_la_placette(con, placette_id),
      histoire_de_la_placette(con, placette_id))
    if (length(fautes) > 0L) {
      stop(paste(fautes, collapse = " ; "), call. = FALSE)
    }
  }
  sommier_entree(
    foret_id = placette$foret_id[[1L]],
    registre = 6L,
    date_evenement = jour,
    auteur = auteur,
    ug_uuid = placette$ug_uuid[[1L]],
    ndp = 0L,
    id = id,
    payload = payload
  )
}

# ---------------------------------------------------------------------------
# Les regles qui lient les plants et les controles. Elles s'ecrivent sur deux
# tables, lues en base par l'API R et assemblees (base + tournee) par l'import :
#
# * `plants` : plant_id, placette_id, numero, pointe_le (Date), remplace_uuid
#   (NA hors regarni) ;
# * `histoire` : plant_id, jour (Date), etat - les etats deja inscrits, un
#   plant pouvant en avoir un par passage.

plants_de_la_placette <- function(con, placette_id) {
  p <- DBI::dbGetQuery(
    con,
    "SELECT id::text AS plant_id, placette_id::text AS placette_id, numero,
            pointe_le, remplace_uuid::text AS remplace_uuid
       FROM v_plant WHERE placette_id = $1",
    params = list(placette_id))
  p$pointe_le <- as.Date(p$pointe_le)
  p
}

histoire_de_la_placette <- function(con, placette_id) {
  h <- DBI::dbGetQuery(
    con,
    "SELECT plant_id::text AS plant_id, visite_le AS jour, etat
       FROM v_etat_plant WHERE placette_id = $1",
    params = list(placette_id))
  h$jour <- as.Date(h$jour)
  h
}

# Les plants qu'un regarni pose AVANT ce jour a remplaces : ils sortent des
# totaux du controle. Un plant remplace compte encore le jour ou le regarni
# est pose (le controle ou il est vu mort ou absent).
plants_remplaces_avant <- function(plants, jour) {
  r <- plants[!is.na(plants$remplace_uuid) & plants$pointe_le < jour, ,
              drop = FALSE]
  unique(r$remplace_uuid)
}

# Le dernier etat connu de chaque plant strictement avant `jour` (ou jusqu'a
# `jour` compris si `inclus`), NA si aucun.
dernier_etat <- function(histoire, plant_ids, jour, inclus = FALSE) {
  h <- histoire[if (inclus) histoire$jour <= jour else histoire$jour < jour, ,
                drop = FALSE]
  h <- h[order(h$jour), , drop = FALSE]
  vapply(plant_ids, function(id) {
    e <- h$etat[h$plant_id == id]
    if (length(e) == 0L) NA_character_ else e[[length(e)]]
  }, character(1), USE.NAMES = FALSE)
}

# Un regarni remplace exactement un plant mort ou absent de la meme placette
# (spec de Surculus § 6, cas fixtures/regles/plants/regarni.json) : plant
# connu, de la meme placette, mort ou absent au plus tard le jour de la pose,
# et pas deja remplace par un autre regarni. `plants` ne contient pas, ou
# contient deja, le regarni lui-meme : il est ecarte du decompte des
# remplacements.
fautes_regarni <- function(regarni_id, remplace_uuid, jour, placette_id,
                           plants, histoire) {
  nom <- paste0("regarni ", regarni_id, " : ")
  cible <- plants[plants$plant_id == remplace_uuid, , drop = FALSE]
  if (nrow(cible) == 0L) {
    return(paste0(nom, "il remplace un plant inconnu de la placette (",
                  remplace_uuid, ")"))
  }
  if (!identical(cible$placette_id[[1L]], placette_id)) {
    return(paste0(nom, "il remplace un plant d'une autre placette (",
                  remplace_uuid, ")"))
  }
  fautes <- character(0)
  etat <- dernier_etat(histoire, remplace_uuid, jour, inclus = TRUE)
  if (is.na(etat) || !etat %in% c("mort", "absent")) {
    fautes <- c(fautes, paste0(nom, "il ne remplace qu'un plant mort ou ",
                               "absent, le plant ", remplace_uuid, " est ",
                               if (is.na(etat)) "sans etat" else etat))
  }
  deja <- plants$plant_id[!is.na(plants$remplace_uuid) &
                            plants$remplace_uuid == remplace_uuid &
                            plants$plant_id != regarni_id]
  if (length(deja) > 0L) {
    fautes <- c(fautes, paste0(nom, "le plant ", remplace_uuid, " est deja ",
                               "remplace par ", deja[[1L]]))
  }
  fautes
}

# Les fautes d'un controle qui porte l'etat de ses plants, face aux plants de
# sa placette et a ce qui est deja inscrit : un plant inconnu de la placette,
# un plant vivant (ou jamais vu) au passage precedent sans etat, un plant mort
# ou absent redit vivant. Les plants remplaces par un regarni d'un passage
# anterieur n'ont plus d'etat a donner, et leur etat ne compte plus. Rend
# `fautes` et `remplaces` (ceux de la liste, a passer a registre6_controle()).
controler_plants_du_controle <- function(etats, placette_id, jour, plants,
                                         histoire) {
  fautes <- character(0)
  r <- plants[plants$placette_id == placette_id, , drop = FALSE]
  ids <- vapply(etats, function(e) e$plant_id, character(1))
  etat_de <- stats::setNames(vapply(etats, function(e) e$etat, character(1)),
                             ids)
  inconnus <- setdiff(ids, r$plant_id)
  for (u in inconnus) {
    fautes <- c(fautes, paste0("plant ", u, " : inconnu de la placette ",
                               placette_id))
  }
  remplaces <- plants_remplaces_avant(r, jour)
  numero <- stats::setNames(r$numero, r$plant_id)
  avant <- dernier_etat(histoire, r$plant_id, jour)
  names(avant) <- r$plant_id
  actifs <- r$plant_id[r$pointe_le <= jour & !r$plant_id %in% remplaces]
  for (u in actifs) {
    if (!is.na(avant[[u]]) && avant[[u]] %in% c("mort", "absent")) next
    if (!u %in% ids) {
      fautes <- c(fautes, paste0(
        "plant ", numero[[u]], " (", u, ") : ",
        if (is.na(avant[[u]])) "pas encore d'etat" else
          paste0("etait ", avant[[u]], " au passage precedent"),
        ", il en faut un a ce controle (ou non_observe)"))
    }
  }
  for (u in intersect(ids, r$plant_id)) {
    if (u %in% remplaces) next
    if (etat_de[[u]] %in% c("sain", "atteint") && !is.na(avant[[u]]) &&
        avant[[u]] %in% c("mort", "absent")) {
      fautes <- c(fautes, paste0(
        "plant ", numero[[u]], " (", u, ") : ", avant[[u]], " au passage ",
        "precedent, il ne peut pas etre ", etat_de[[u]]))
    }
  }
  list(fautes = fautes, remplaces = intersect(ids, remplaces))
}

# ---------------------------------------------------------------------------
# L'import des plants d'une tournee : couches `plants` (POINT) et
# `etats_plants` (table) de Surculus (docs/spec.md § 5). Absentes d'une tournee
# ancienne : elle s'importe comme avant.

COLONNES_PLANTS_TEXTE <- c("essence", "unite_azimut", "modele_geomagnetique")
COLONNES_PLANTS_NOMBRE <- c("distance_m", "azimut_mag", "declinaison_deg",
                            "convergence_deg", "azimut_geo_deg")

# NULL si ni l'une ni l'autre couche n'est la ; sinon `plants` (data.frame,
# `geometries` : liste de points WGS 84, `fautes_geometrie`) et `etats`.
lire_plants_tournee <- function(gpkg) {
  couches <- sf::st_layers(gpkg)$name
  if (!any(c("plants", "etats_plants") %in% couches)) {
    return(NULL)
  }
  fautes <- character(0)
  plants <- NULL
  geometries <- list()
  if ("plants" %in% couches) {
    x <- suppressWarnings(sf::read_sf(gpkg, layer = "plants"))
    if (nrow(x) > 0L) {
      g <- sf::st_geometry(x)
      crs_connu <- !is.na(sf::st_crs(g)) &&
        !grepl("Undefined", sf::st_crs(g)$wkt, fixed = TRUE)
      vide <- sf::st_is_empty(g)
      geometries <- vector("list", nrow(x))
      if (!crs_connu) {
        fautes <- c(fautes, paste0("plants : la couche n'a pas de systeme de ",
                                   "coordonnees, les plants ne se placent pas"))
      } else if (any(!vide)) {
        geometries <- tryCatch(positions_wgs84(x), error = function(e) {
          fautes <<- c(fautes, paste0("plants : position hors des bornes ",
                                      "WGS 84 (", conditionMessage(e), ")"))
          vector("list", nrow(x))
        })
      }
      plants <- as.data.frame(sf::st_drop_geometry(x))
    }
  }
  etats <- NULL
  if ("etats_plants" %in% couches) {
    e <- suppressWarnings(sf::read_sf(gpkg, layer = "etats_plants"))
    if (nrow(e) > 0L) etats <- as.data.frame(sf::st_drop_geometry(e))
  }
  list(plants = plants, geometries = geometries, etats = etats,
       fautes = fautes)
}

utc_jour <- function(x) {
  if (length(x) == 0L || is.na(x)) return(as.Date(NA))
  as.Date(format(as.POSIXct(x, tz = "UTC"), "%Y-%m-%d", tz = "UTC"))
}

colonne_ou_na <- function(df, nom) {
  if (nom %in% names(df)) df[[nom]] else rep(NA, nrow(df))
}

# Les champs de registre6_plant d'une ligne de la couche `plants`.
champs_plant <- function(x, i) {
  v <- function(nom) {
    y <- colonne_ou_na(x, nom)[[i]]
    if (length(y) == 0L || is.na(y)) NULL else y
  }
  champs <- list()
  for (n in COLONNES_PLANTS_TEXTE) champs[[n]] <- texte_ou_null(
    colonne_ou_na(x, n)[[i]] %||% NA_character_)
  for (n in COLONNES_PLANTS_NOMBRE) champs[[n]] <- {
    y <- v(n); if (is.null(y)) NULL else as.numeric(y)
  }
  regarni <- v("regarni")
  champs$regarni <- if (!is.null(regarni) && isTRUE(as.logical(regarni))) TRUE
  champs$remplace_uuid <- texte_ou_null(
    colonne_ou_na(x, "remplace_uuid")[[i]] %||% NA_character_)
  pointe <- v("pointe_le")
  champs$pointe_le <- if (!is.null(pointe)) format_instant(
    as.POSIXct(pointe, tz = "UTC"), "pointe_le")
  champs
}

# Tout ce que la tournee dit des plants, confronte a la base et a la tournee
# elle-meme. `controles` : les controles encore a ecrire. Rend :
#  * `fautes` : tout ce qui refuse la tournee ;
#  * `nouveaux` : indices des lignes de `plants` a ecrire ;
#  * `par_controle` : pour chaque uuid de controle a ecrire, `plants` (les
#    etats, prets pour registre6_controle) et `remplaces`.
preparer_plants_tournee <- function(pl, controles, placettes_valides,
                                    controles_tournee, plants_db,
                                    histoire_db) {
  vide <- list(fautes = character(0), nouveaux = integer(0),
               par_controle = list())
  if (is.null(pl)) return(vide)
  fautes <- pl$fautes
  p <- pl$plants
  e <- pl$etats
  roster_tournee <- data.frame(plant_id = character(0),
                               placette_id = character(0),
                               numero = integer(0),
                               pointe_le = as.Date(character(0)),
                               remplace_uuid = character(0),
                               stringsAsFactors = FALSE)
  nouveaux <- integer(0)
  if (!is.null(p)) {
    uuid <- tolower(as.character(colonne_ou_na(p, "uuid")))
    placette <- tolower(as.character(colonne_ou_na(p, "placette_uuid")))
    numero <- suppressWarnings(as.numeric(colonne_ou_na(p, "numero")))
    pointe <- as.Date(vapply(seq_len(nrow(p)), function(i) {
      format(utc_jour(colonne_ou_na(p, "pointe_le")[[i]]))
    }, character(1)))
    remplace <- tolower(texte_vec(colonne_ou_na(p, "remplace_uuid")))
    vus <- character(0)
    for (i in seq_len(nrow(p))) {
      nom <- paste0("plant ", i, if (!is.na(uuid[[i]])) paste0(" (", uuid[[i]],
                                                              ")"))
      if (is.na(uuid[[i]]) || !grepl(MOTIF_UUID, uuid[[i]])) {
        fautes <- c(fautes, paste0(nom, " : identifiant absent ou invalide"))
        next
      }
      if (uuid[[i]] %in% vus) {
        fautes <- c(fautes, paste0(nom, " : deux lignes pour le meme plant"))
        next
      }
      vus <- c(vus, uuid[[i]])
      if (is.na(placette[[i]]) || !placette[[i]] %in% placettes_valides) {
        fautes <- c(fautes, paste0(nom, " : plant sans placette (",
                                   if (is.na(placette[[i]])) "vide" else
                                     placette[[i]], " inconnue)"))
        next
      }
      deja <- plants_db[plants_db$plant_id == uuid[[i]], , drop = FALSE]
      if (nrow(deja) > 0L) {
        # Rejeu : le plant est inscrit. Sous une autre identite, c'est une
        # faute (un plant garde son UUID, son numero et sa placette).
        if (!identical(deja$placette_id[[1L]], placette[[i]]) ||
            !isTRUE(deja$numero[[1L]] == numero[[i]])) {
          fautes <- c(fautes, paste0(nom, " : deja inscrit sous la placette ",
                                     deja$placette_id[[1L]], ", numero ",
                                     deja$numero[[1L]], " ; un plant garde son ",
                                     "numero et sa placette"))
        }
        next
      }
      g <- if (i <= length(pl$geometries)) pl$geometries[[i]]
      if (is.null(g)) {
        fautes <- c(fautes, paste0(nom, " : sans position"))
        next
      }
      if (is.na(pointe[[i]])) {
        fautes <- c(fautes, paste0(nom, " : pointe_le absent, la date du ",
                                   "pointage ne se devine pas"))
        next
      }
      essai <- tryCatch({
        do.call(registre6_plant, c(
          list(placette_id = placette[[i]], numero = numero[[i]],
               geometrie = g), champs_plant(p, i)))
        NULL
      }, error = function(err) conditionMessage(err))
      if (!is.null(essai)) {
        fautes <- c(fautes, paste0(nom, " : ", essai))
        next
      }
      nouveaux <- c(nouveaux, i)
      roster_tournee[nrow(roster_tournee) + 1L, ] <- list(
        uuid[[i]], placette[[i]], numero[[i]], pointe[[i]],
        if (is.na(remplace[[i]])) NA_character_ else remplace[[i]])
    }
    # Numeros : uniques dans la placette, base et tournee confondues.
    tous <- rbind(plants_db[, names(roster_tournee)], roster_tournee)
    cle <- paste(tous$placette_id, tous$numero)
    for (d in unique(cle[duplicated(cle)])) {
      fautes <- c(fautes, paste0("plants : le numero ",
                                 sub("^[^ ]+ ", "", d), " est pris deux fois ",
                                 "dans la placette ", sub(" .*$", "", d)))
    }
  }
  roster <- rbind(plants_db[, names(roster_tournee)], roster_tournee)

  # Les etats : chacun a son controle, son plant, une seule fois.
  histoire <- histoire_db
  jour_ctl <- stats::setNames(controles_tournee$jour, controles_tournee$uuid)
  par_ligne <- list()
  if (!is.null(e)) {
    e_ctl <- tolower(as.character(colonne_ou_na(e, "controle_uuid")))
    e_plant <- tolower(as.character(colonne_ou_na(e, "plant_uuid")))
    e_etat <- as.character(colonne_ou_na(e, "etat"))
    cle_vue <- character(0)
    for (i in seq_len(nrow(e))) {
      nom <- paste0("etat ", i, " (plant ", e_plant[[i]], ")")
      if (is.na(e_ctl[[i]]) || !e_ctl[[i]] %in% controles_tournee$uuid) {
        fautes <- c(fautes, paste0(nom, " : controle absent de la tournee"))
        next
      }
      if (is.na(e_plant[[i]]) || !e_plant[[i]] %in% roster$plant_id) {
        fautes <- c(fautes, paste0(nom, " : etat d'un plant inconnu"))
        next
      }
      cle <- paste(e_ctl[[i]], e_plant[[i]])
      if (cle %in% cle_vue) {
        fautes <- c(fautes, paste0(nom, " : deux etats du meme plant dans ",
                                   "le controle ", e_ctl[[i]]))
        next
      }
      cle_vue <- c(cle_vue, cle)
      par_ligne[[length(par_ligne) + 1L]] <- list(
        controle = e_ctl[[i]], i = i)
      histoire[nrow(histoire) + 1L, ] <- list(
        e_plant[[i]], jour_ctl[[e_ctl[[i]]]], e_etat[[i]])
    }
  }

  # Le regarni : mort ou absent, meme placette, jamais remplace deux fois.
  if (!is.null(p)) {
    for (i in nouveaux) {
      r <- champs_plant(p, i)$remplace_uuid
      if (is.null(r)) next
      u <- tolower(as.character(p$uuid[[i]]))
      pose <- roster$pointe_le[roster$plant_id == u]
      fautes <- c(fautes, fautes_regarni(
        u, tolower(r), pose, tolower(as.character(p$placette_uuid[[i]])),
        roster, histoire))
    }
  }

  # Les controles qui portent des etats : confrontes a l'histoire.
  par_controle <- list()
  for (k in seq_len(nrow(controles))) {
    u <- tolower(controles$uuid[[k]])
    mes <- Filter(function(l) l$controle == u, par_ligne)
    if (length(mes) == 0L) next
    etats <- lapply(mes, function(l) {
      champs <- list(
        plant_id = tolower(as.character(e$plant_uuid[[l$i]])),
        etat = as.character(e$etat[[l$i]]),
        cause_groupe = texte_ou_null(colonne_ou_na(e, "cause_groupe")[[l$i]]),
        cause_detail = texte_ou_null(colonne_ou_na(e, "cause_detail")[[l$i]]),
        hauteur_cm = nombre_ou_null(colonne_ou_na(e, "hauteur_cm")[[l$i]]))
      champs[!vapply(champs, is.null, logical(1))]
    })
    nom <- paste0("controle ", u)
    valides <- tryCatch(normaliser_plants_controle(etats, NULL),
                        error = function(err) {
                          fautes <<- c(fautes, paste0(nom, " : ",
                                                      conditionMessage(err)))
                          NULL
                        })
    if (is.null(valides)) next
    placette <- tolower(as.character(controles$placette_uuid[[k]]))
    if (is.na(placette)) next
    verdict <- controler_plants_du_controle(
      valides$plants, placette, jour_ctl[[u]], roster, histoire)
    if (length(verdict$fautes) > 0L) {
      fautes <- c(fautes, paste0(nom, " : ", verdict$fautes))
    }
    par_controle[[u]] <- list(plants = valides$plants,
                              remplaces = verdict$remplaces)
  }
  list(fautes = fautes, nouveaux = nouveaux, par_controle = par_controle)
}

texte_vec <- function(x) {
  x <- as.character(x)
  x[!is.na(x) & !nzchar(trimws(x))] <- NA_character_
  x
}
