#' Version du format de manifeste
#' @export
SOMMIER_VERSION_MANIFESTE <- "sommier-manifeste-1"

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
#' @param con Connexion DBI.
#' @param foret_id UUID de la foret.
#' @param chemin Fichier de destination.
#' @return Invisiblement, `chemin`.
#'
#' @export
sommier_exporter_manifeste <- function(con, foret_id, chemin) {
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
#' Ce qui n'est pas verifie : la signature JWS du visa, faute de clé publique
#' dans le manifeste, et la chaine de certification de l'autorite
#' d'horodatage, qui demande une ancre de confiance. Les deux relevent du lot
#' suivant.
#'
#' @param chemin Fichier JSON produit par [sommier_exporter_manifeste()].
#' @return Un objet `sommier_rapport`, dont les anomalies incluent les types
#'   `visa_orphelin`, `ancrage_orphelin`, `visa_horodatage` et
#'   `ancrage_horodatage`.
#'
#' @export
sommier_verifier_manifeste <- function(chemin) {
  manifeste <- jsonlite::fromJSON(chemin, simplifyVector = TRUE,
                                  simplifyDataFrame = TRUE)

  if (!identical(manifeste$format, SOMMIER_VERSION_MANIFESTE)) {
    stop("Format de manifeste inconnu : ",
         manifeste$format %||% "(absent)",
         " ; attendu ", SOMMIER_VERSION_MANIFESTE, ".", call. = FALSE)
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
  rapport$anomalies <- verifier_attestations(
    rapport$anomalies, manifeste$visas, tetes, "visa_orphelin",
    "visa_horodatage", "Visa"
  )
  rapport$anomalies <- verifier_attestations(
    rapport$anomalies, manifeste$ancrages, tetes, "ancrage_orphelin",
    "ancrage_horodatage", "Ancrage"
  )
  rapport$valide <- nrow(rapport$anomalies) == 0L
  rapport
}

verifier_attestations <- function(anomalies, table, tetes, type,
                                  type_horodatage, libelle) {
  if (is.null(table) || !is.data.frame(table) || nrow(table) == 0L) {
    return(anomalies)
  }
  for (i in seq_len(nrow(table))) {
    seq_tete <- as.character(table$seq_tete[[i]])
    anomalies <- verifier_jeton_atteste(
      anomalies, table, i, seq_tete, type_horodatage, libelle
    )
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
  anomalies
}

# Ce que l'autorite a reellement signe, oppose a ce que la base declare. La
# colonne `hash_tete` et le jeton peuvent differer : c'est precisement le cas
# qu'un booleen « horodate » ne savait pas voir.
verifier_jeton_atteste <- function(anomalies, table, i, seq_tete, type, libelle) {
  tst <- if ("tst_rfc3161" %in% names(table)) table$tst_rfc3161[[i]] else NA
  if (est_vide(tst)) {
    return(anomalies)
  }
  lu <- try(tsa_lire_jeton(octets_depuis_hex(tst, "tst_rfc3161")), silent = TRUE)
  if (inherits(lu, "try-error")) {
    return(ajouter_anomalie(
      anomalies, as.numeric(table$seq_tete[[i]]), table$id[[i]], type,
      paste0(libelle, " porte un jeton d'horodatage illisible : ",
             trimws(conditionMessage(attr(lu, "condition"))))
    ))
  }
  declare <- tolower(as.character(table$hash_tete[[i]]))
  if (!identical(empreinte_hex(lu$empreinte), declare)) {
    return(ajouter_anomalie(
      anomalies, as.numeric(table$seq_tete[[i]]), table$id[[i]], type,
      paste0(libelle, " declare ", declare, " a la sequence ", seq_tete,
             ", mais son jeton atteste ", lu$algorithme, ":",
             empreinte_hex(lu$empreinte), " : l'horodatage a ete obtenu ",
             "pour autre chose.")
    ))
  }
  anomalies
}
