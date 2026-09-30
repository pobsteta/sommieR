#' Version du format de manifeste
#' @export
SOMMIER_VERSION_MANIFESTE <- "sommier-manifeste-2"

#' Formats de manifeste que la verification accepte
#'
#' @description
#' Le format ecrit est [SOMMIER_VERSION_MANIFESTE] ; ceux qui se **lisent**
#' sont plus nombreux.
#'
#' @details
#' Un manifeste est un export destine a etre verifie par un tiers, des annees
#' plus tard. Refuser de verifier un manifeste ancien sous pretexte qu'une
#' version posterieure du paquet ecrit autrement reviendrait a annuler cela
#' meme qu'il promet. Les evolutions du format sont additives : la v2 ajoute
#' le certificat du signataire, elle ne retire rien.
#'
#' @export
SOMMIER_FORMATS_MANIFESTE_LUS <- c("sommier-manifeste-1", "sommier-manifeste-2")

#' Export d'un manifeste verifiable
#'
#' @description
#' Ecrit la chaine d'une foret dans un fichier JSON autoportant : les entrees,
#' leurs empreintes, les visas et les ancrages. Le destinataire verifie
#' l'integrite hors ligne avec [sommier_verifier_manifeste()], sans acces a la
#' base et sans avoir a faire confiance a l'expediteur - c'est le "partage
#' sans confiance" du brief (section 6.3).
#'
#' @details
#' Le brief prevoit a terme un GeoPackage accompagne de ce manifeste
#' (priorite 5). La v0.1.0 n'exporte que le manifeste : la chaine y est
#' complete et verifiable, la couche geographique viendra avec l'export
#' cartographique.
#'
#' Le manifeste porte les payloads en JSON tel que stocke, pas en forme
#' canonique : c'est la verification qui recanonise. Un manifeste dont les
#' payloads seraient deja canoniques masquerait un bogue de canonisation chez
#' l'expediteur.
#'
#' **Les photos voyagent a cote.** Une reconnaissance de limite ne porte ses
#' photos que par leur empreinte (voir [sommier_deposer_photo()]). Avec
#' `depot`, les photos que la chaine reference sont copiees dans un dossier
#' `photos/` voisin du manifeste, sous leur nom d'empreinte ; le destinataire
#' les confronte aux empreintes chainees avec [sommier_verifier_manifeste()].
#' Le format du manifeste n'en change pas : les empreintes y sont deja.
#'
#' @param con Connexion DBI.
#' @param foret_id UUID de la foret.
#' @param chemin Fichier de destination.
#' @param depot Depot de photos a joindre (facultatif).
#' @return Invisiblement, `chemin`.
#'
#' @export
sommier_exporter_manifeste <- function(con, foret_id, chemin, depot = NULL) {
  foret_id <- valider_uuid(foret_id, "foret_id")
  entrees <- sommier_lire(con, foret_id)

  foret <- DBI::dbGetQuery(
    con,
    "SELECT id, nom, regime, proprietaire, surface_ha FROM foret WHERE id = $1",
    params = list(foret_id)
  )
  if (nrow(foret) == 0L) {
    stop("Foret inconnue : ", foret_id, ".", call. = FALSE)
  }

  visas <- DBI::dbGetQuery(
    con,
    "SELECT id, exercice, seq_tete, encode(hash_tete, 'hex') AS hash_tete,
            autorite, signataire::text AS signataire, signature_jws,
            encode(certificat, 'hex') AS certificat,
            encode(tst_rfc3161, 'hex') AS tst_rfc3161,
            to_char(date_visa AT TIME ZONE 'UTC',
                    'YYYY-MM-DD\"T\"HH24:MI:SS\"Z\"') AS date_visa
       FROM visa WHERE foret_id = $1 ORDER BY exercice",
    params = list(foret_id)
  )
  ancrages <- DBI::dbGetQuery(
    con,
    "SELECT id, seq_tete, encode(hash_tete, 'hex') AS hash_tete,
            encode(tst_rfc3161, 'hex') AS tst_rfc3161,
            to_char(date_ancrage AT TIME ZONE 'UTC',
                    'YYYY-MM-DD\"T\"HH24:MI:SS\"Z\"') AS date_ancrage
       FROM ancrage WHERE foret_id = $1 ORDER BY seq_tete",
    params = list(foret_id)
  )

  manifeste <- list(
    format         = SOMMIER_VERSION_MANIFESTE,
    version_chaine = SOMMIER_VERSION_CHAINE,
    genere_le      = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
    foret          = as.list(foret[1L, , drop = FALSE]),
    hash_genese    = empreinte_hex(sommier_empreinte_genese(foret_id)),
    entrees        = entrees,
    visas          = visas,
    ancrages       = ancrages
  )

  writeLines(
    jsonlite::toJSON(manifeste, auto_unbox = TRUE, null = "null",
                     na = "null", pretty = TRUE, dataframe = "rows"),
    chemin, useBytes = TRUE
  )

  if (!est_vide(depot)) {
    joindre_photos(photos_referencees(entrees), valider_texte(depot, "depot"),
                   file.path(dirname(chemin), "photos"))
  }
  invisible(chemin)
}

#' Verification d'un manifeste exporte
#'
#' @description
#' Verifie hors ligne la chaine d'un manifeste produit par
#' [sommier_exporter_manifeste()], et confronte chaque visa et chaque ancrage
#' a l'empreinte qu'il pretend attester.
#'
#' @details
#' Deux confrontations sont faites, sans reseau ni magasin de confiance.
#'
#' 1. Le `hash_tete` que l'attestation declare correspond a l'etat de la chaine
#'    a la sequence annoncee. Un visa dont l'empreinte ne correspond a aucune
#'    entree est signale : c'est ce qui detecte une attestation rapportee d'une
#'    autre chaine.
#' 2. **Le jeton d'horodatage atteste bien cette empreinte-la.** Le point 1
#'    porte sur ce que la base declare ; celui-ci sur ce que l'autorite a
#'    reellement signe. Sans lui, un jeton obtenu pour une autre tete de chaine
#'    accompagnerait le manifeste sans que rien ne le distingue du bon.
#'
#' 3. **La signature JWS du visa se verifie**, quand le visa porte le
#'    certificat de son signataire (format `sommier-manifeste-2`). C'est ce
#'    qui rend l'export verifiable par un tiers sans qu'il ait a se procurer
#'    la cle par un canal que le manifeste n'organise pas.
#'
#' 4. **Les photos jointes sont celles que la chaine atteste**, quand
#'    `photos` designe leur dossier. Une photo dont l'empreinte differe est
#'    une anomalie (`photo_alteree`) ; une photo absente, une reserve : elle
#'    est perdue pour la lecture, mais la chaine n'en est pas moins intacte.
#'
#' **Anomalies et reserves ne se confondent pas.** Une anomalie dit que
#' quelque chose est faux ; une reserve, que quelque chose n'a pas pu etre
#' verifie sans que rien n'indique pour autant que ce soit faux - un jeton
#' intact dont aucune ancre fournie ne couvre l'autorite, un visa sans
#' certificat. Compter les secondes comme les premieres declarerait invalide
#' un manifeste parfait verifie sans ancres.
#'
#' La revocation n'est jamais verifiee : CRL et OCSP demandent le reseau, ce
#' que la verification hors ligne exclut par construction. Le rapport le dit
#' en reserve plutot que de laisser croire le contraire.
#'
#' @param chemin Fichier JSON produit par [sommier_exporter_manifeste()].
#' @param ancres Ancres de confiance, lues par [certificat_lire()]. Aucune
#'   n'est embarquee : ce serait faire dependre du rythme de publication de
#'   sommieR la question de savoir qui est digne de confiance.
#' @param photos Dossier des photos jointes au manifeste (facultatif).
#' @return Un objet `sommier_rapport`, dont les anomalies incluent les types
#'   `visa_orphelin`, `ancrage_orphelin`, `visa_horodatage`,
#'   `ancrage_horodatage`, `visa_signature` et `photo_alteree`.
#'
#' @export
sommier_verifier_manifeste <- function(chemin, ancres = list(),
                                       photos = NULL) {
  manifeste <- jsonlite::fromJSON(chemin, simplifyVector = TRUE,
                                  simplifyDataFrame = TRUE)

  if (!isTRUE(manifeste$format %in% SOMMIER_FORMATS_MANIFESTE_LUS)) {
    stop("Format de manifeste inconnu : ",
         manifeste$format %||% "(absent)",
         " ; connus : ", paste(SOMMIER_FORMATS_MANIFESTE_LUS, collapse = ", "),
         ".", call. = FALSE)
  }
  if (!identical(manifeste$version_chaine, SOMMIER_VERSION_CHAINE)) {
    stop("Manifeste chaine avec ", manifeste$version_chaine %||% "(absent)",
         ", incompatible avec ", SOMMIER_VERSION_CHAINE,
         " : utiliser la version de sommieR correspondante.", call. = FALSE)
  }

  foret_id <- valider_uuid(manifeste$foret$id, "foret.id")
  rapport <- sommier_verifier_chaine(manifeste$entrees, foret_id = foret_id)

  # Une attestation qui ne correspond a aucune tete de la chaine a ete
  # produite ailleurs, ou la chaine a ete tronquee apres coup.
  tetes <- stats::setNames(
    as.character(manifeste$entrees$hash),
    as.character(manifeste$entrees$seq)
  )
  reserves <- character(0)
  for (attestations in list(
    list(table = manifeste$visas, tetes = tetes, type = "visa_orphelin",
         type_horodatage = "visa_horodatage", libelle = "Visa"),
    list(table = manifeste$ancrages, tetes = tetes, type = "ancrage_orphelin",
         type_horodatage = "ancrage_horodatage", libelle = "Ancrage")
  )) {
    controle <- verifier_attestations(
      rapport$anomalies, attestations$table, attestations$tetes,
      attestations$type, attestations$type_horodatage, attestations$libelle,
      ancres
    )
    rapport$anomalies <- controle$anomalies
    reserves <- c(reserves, controle$reserves)
  }

  controle <- verifier_signatures_visas(rapport$anomalies, manifeste$visas)
  rapport$anomalies <- controle$anomalies
  reserves <- c(reserves, controle$reserves)

  if (!est_vide(photos)) {
    controle <- verifier_photos_jointes(
      rapport$anomalies, photos_referencees(manifeste$entrees),
      valider_texte(photos, "photos")
    )
    rapport$anomalies <- controle$anomalies
    reserves <- c(reserves, controle$reserves)
  }

  rapport$reserves <- c(reserves,
                        "revocation des certificats non verifiee : CRL et OCSP demandent le reseau")
  rapport$valide <- nrow(rapport$anomalies) == 0L
  rapport
}

# La signature detachee du visa, confrontee au certificat que le visa porte.
verifier_signatures_visas <- function(anomalies, visas) {
  reserves <- character(0)
  if (is.null(visas) || !is.data.frame(visas) || nrow(visas) == 0L) {
    return(list(anomalies = anomalies, reserves = reserves))
  }
  sans_certificat <- 0L
  for (i in seq_len(nrow(visas))) {
    cert_hex <- if ("certificat" %in% names(visas)) visas$certificat[[i]] else NA
    if (est_vide(cert_hex)) {
      sans_certificat <- sans_certificat + 1L
      next
    }
    porteur <- cle_du_certificat(cert_hex)
    if (is.null(porteur$cle)) {
      anomalies <- ajouter_anomalie(
        anomalies, as.numeric(visas$seq_tete[[i]]), visas$id[[i]],
        "visa_signature",
        paste0("Visa portant un certificat inexploitable : ",
               paste(porteur$remarques, collapse = " ; "), ".")
      )
      next
    }
    valide <- try(jws_verifier_detache(
      visas$signature_jws[[i]],
      empreinte_depuis_hex(visas$hash_tete[[i]]), porteur$cle
    ), silent = TRUE)
    if (inherits(valide, "try-error") || !isTRUE(valide)) {
      anomalies <- ajouter_anomalie(
        anomalies, as.numeric(visas$seq_tete[[i]]), visas$id[[i]],
        "visa_signature",
        "Visa dont la signature ne se verifie pas sous le certificat qu'il porte."
      )
    }
  }
  if (sans_certificat > 0L) {
    reserves <- c(reserves, paste0(
      sans_certificat, " visa(s) sans certificat : signature non verifiee, ",
      "la cle doit etre fournie autrement"
    ))
  }
  list(anomalies = anomalies, reserves = reserves)
}

verifier_attestations <- function(anomalies, table, tetes, type,
                                  type_horodatage, libelle, ancres = list()) {
  reserves <- character(0)
  if (is.null(table) || !is.data.frame(table) || nrow(table) == 0L) {
    return(list(anomalies = anomalies, reserves = reserves))
  }
  non_rattaches <- 0L
  for (i in seq_len(nrow(table))) {
    seq_tete <- as.character(table$seq_tete[[i]])
    controle <- verifier_jeton_atteste(
      anomalies, table, i, seq_tete, type_horodatage, libelle, ancres
    )
    anomalies <- controle$anomalies
    non_rattaches <- non_rattaches + controle$non_rattache
    # `tetes[[seq_tete]]` leverait une erreur sur une sequence absente, alors
    # que c'est precisement l'anomalie a signaler : on passe par match().
    position <- match(seq_tete, names(tetes))
    attendu <- if (is.na(position)) NA_character_ else tetes[[position]]
    if (is.na(attendu)) {
      anomalies <- ajouter_anomalie(
        anomalies, as.numeric(table$seq_tete[[i]]), table$id[[i]], type,
        paste0(libelle, " atteste la sequence ", seq_tete,
               ", absente de la chaine exportee.")
      )
    } else if (!identical(tolower(attendu), tolower(as.character(table$hash_tete[[i]])))) {
      anomalies <- ajouter_anomalie(
        anomalies, as.numeric(table$seq_tete[[i]]), table$id[[i]], type,
        paste0(libelle, " atteste ", table$hash_tete[[i]],
               " a la sequence ", seq_tete, ", alors que la chaine y porte ",
               attendu, ".")
      )
    }
  }
  if (non_rattaches > 0L) {
    reserves <- c(reserves, paste0(
      non_rattaches, " jeton(s) d'horodatage lus et intacts, mais rattaches a ",
      "aucune ancre de confiance fournie"
    ))
  }
  list(anomalies = anomalies, reserves = reserves)
}

# Ce que l'autorite a reellement signe, oppose a ce que la base declare. La
# colonne `hash_tete` et le jeton peuvent differer : c'est precisement le cas
# qu'un booleen « horodate » ne savait pas voir.
verifier_jeton_atteste <- function(anomalies, table, i, seq_tete, type, libelle,
                                   ancres = list()) {
  tst <- if ("tst_rfc3161" %in% names(table)) table$tst_rfc3161[[i]] else NA
  if (est_vide(tst)) {
    return(list(anomalies = anomalies, non_rattache = 0L))
  }
  jeton <- try(octets_depuis_hex(tst, "tst_rfc3161"), silent = TRUE)
  if (inherits(jeton, "try-error")) {
    return(list(non_rattache = 0L, anomalies = ajouter_anomalie(
      anomalies, as.numeric(table$seq_tete[[i]]), table$id[[i]], type,
      paste0(libelle, " porte un jeton d'horodatage illisible.")
    )))
  }
  declare <- tolower(as.character(table$hash_tete[[i]]))
  verdict <- tsa_verifier_jeton(jeton, empreinte_depuis_hex(declare), ancres)
  if (identical(verdict$etat, "invalide")) {
    return(list(non_rattache = 0L, anomalies = ajouter_anomalie(
      anomalies, as.numeric(table$seq_tete[[i]]), table$id[[i]], type,
      paste0(libelle, " a la sequence ", seq_tete, " : ",
             paste(verdict$motifs, collapse = " ; "), ".")
    )))
  }
  list(anomalies = anomalies,
       non_rattache = if (identical(verdict$etat, "non_rattache")) 1L else 0L)
}

# Les photos que la chaine reference : une ligne par photo, avec l'entree qui
# la porte. Les payloads sont relus tels qu'ils ont ete chaines.
photos_referencees <- function(entrees) {
  vide <- data.frame(seq = numeric(0), id = character(0),
                     sha256 = character(0), type = character(0),
                     stringsAsFactors = FALSE)
  if (is.null(entrees) || nrow(entrees) == 0L) {
    return(vide)
  }
  garde <- which(as.integer(entrees$registre) == 2L &
                   grepl('"photos"', entrees$payload, fixed = TRUE))
  lignes <- lapply(garde, function(i) {
    payload <- jsonlite::fromJSON(entrees$payload[[i]], simplifyVector = FALSE)
    if (is.null(payload$photos)) return(NULL)
    data.frame(seq = as.numeric(entrees$seq[[i]]), id = entrees$id[[i]],
               sha256 = vapply(payload$photos, function(p) p$sha256, ""),
               type = vapply(payload$photos, function(p) p$type, ""),
               stringsAsFactors = FALSE)
  })
  lignes <- lignes[!vapply(lignes, is.null, logical(1))]
  if (length(lignes) == 0L) vide else do.call(rbind, lignes)
}

joindre_photos <- function(photos, depot, destination) {
  if (nrow(photos) == 0L) {
    return(invisible(0L))
  }
  if (!dir.exists(destination)) {
    dir.create(destination, recursive = TRUE)
  }
  sources <- unique(chemin_photo_vec(depot, photos))
  presentes <- sources[file.exists(sources)]
  file.copy(presentes, destination, overwrite = TRUE, copy.date = TRUE)
  invisible(length(presentes))
}

verifier_photos_jointes <- function(anomalies, photos, dossier) {
  manquantes <- 0L
  for (i in seq_len(nrow(photos))) {
    cible <- chemin_photo(dossier, photos$sha256[[i]], photos$type[[i]])
    if (!file.exists(cible)) {
      manquantes <- manquantes + 1L
    } else if (!identical(empreinte_fichier(cible), photos$sha256[[i]])) {
      anomalies <- ajouter_anomalie(
        anomalies, photos$seq[[i]], photos$id[[i]], "photo_alteree",
        paste0("Photo ", basename(cible), " : son contenu n'est plus celui ",
               "que la chaine atteste.")
      )
    }
  }
  reserves <- if (manquantes > 0L) {
    paste0(manquantes, " photo(s) referencee(s) absente(s) du dossier joint : ",
           "non verifiee(s), la chaine reste intacte")
  } else {
    character(0)
  }
  list(anomalies = anomalies, reserves = reserves)
}

chemin_photo_vec <- function(depot, photos) {
  vapply(seq_len(nrow(photos)), function(i) {
    chemin_photo(depot, photos$sha256[[i]], photos$type[[i]])
  }, character(1))
}
