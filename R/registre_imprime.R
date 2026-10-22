#' Sommier : le registre, ecriture par ecriture
#'
#' @description
#' Extrait le sommier tel qu'il est chaine : une ligne par ecriture, registre
#' par registre, dans l'ordre de la chaine, rectifiees comprises. C'est
#' l'inverse du bilan de gestion : ni somme, ni carte, ni estimation, rien qui
#' ne soit dans la chaine.
#'
#' @details
#' **Les rectifiees restent.** Le classeur papier interdisait la rature et
#' imposait la mention rectificative : une ecriture rectifiee figure a sa
#' place, avec le numero de celle qui la rectifie (`rectifiee_par`), et la
#' rectification porte le numero de sa cible (`rectifie`).
#'
#' **Chaque ligne dit d'ou elle vient.** Une transcription porte sa piece
#' (`payload$reprise`, voir [sommier_reprise()]) ; un constat n'en porte pas.
#'
#' **La fiche A10 ouvre le sommier.** Pour chaque exercice depuis
#' l'ouverture, les actes de visa du registre 1, signes et horodates ou non ;
#' un exercice sans acte est dit non vise. Les ancrages suivent.
#'
#' **Une edition peut s'arreter a un visa.** `jusqu_au_visa` imprime le
#' sommier tel qu'il etait quand l'exercice a ete vise : les ecritures jusqu'a
#' la tete signee, pas au-dela. La chaine est alors verifiee jusqu'a cette
#' tete, et l'extraction dit si elle concorde avec l'empreinte visee.
#'
#' **Le visa se lit avec ses pieces.** Une edition arretee a un visa porte
#' aussi l'attestation de ce visa, verifiee par [sommier_verifier_visas()] :
#' qui l'a signe (les claims du signataire, et son certificat quand le visa
#' en porte un), si la signature se verifie et sous quelle cle, et ce que
#' vaut le jeton d'horodatage - la date que l'autorite a certifiee, et qui
#' est cette autorite. La signature, le certificat et le jeton eux-memes sont
#' rendus tels quels, pour etre recopies et verifies ailleurs.
#'
#' @param con Connexion DBI.
#' @param foret_id UUID de la foret.
#' @param registres Registres a extraire (1 a 9).
#' @param jusqu_au_visa Exercice dont le visa arrete l'edition ; `NULL` pour
#'   tout le sommier.
#' @param cles_publiques,ancres Transmises a [sommier_verifier_visas()] pour
#'   verifier le visa qui arrete l'edition : cles publiques des signataires
#'   (inutiles quand le visa porte son certificat), ancres de confiance des
#'   autorites d'horodatage. Sans effet sans `jusqu_au_visa`.
#'
#' @return Un objet de classe `sommier_registre` : `foret` (nom, regime),
#'   `ecritures` (`data.frame`, une ligne par ecriture : `seq`, `registre`,
#'   `type_entree`, `date_evenement`, `date_saisie`, `auteur`, `ndp`, `ug`,
#'   `provenance`, `piece`, `rectifie`, `rectifiee_par`, `contenu`,
#'   `payload`, `schema_version`, `hash`), `tenue` (fiche A10, par exercice),
#'   `ancrages`, `verification` (etat de la chaine extraite), `visa` (le visa
#'   qui arrete l'edition, s'il y en a un : `exercice`, `autorite`,
#'   `seq_tete`, `hash_tete`, `date_visa`, `horodate`, `concorde`, et son
#'   attestation - `signataire`, `signature_jws`, `certificat`, `jeton`,
#'   `verifie`), `registres`.
#'
#' @seealso [sommier_registre_quarto()], [sommier_exporter_manifeste()]
#'
#' @export
sommier_registre <- function(con, foret_id, registres = 1:9,
                             jusqu_au_visa = NULL, cles_publiques = list(),
                             ancres = list()) {
  foret_id <- valider_uuid(foret_id, "foret_id")
  registres <- sort(unique(as.integer(vapply(
    registres, valider_entier, numeric(1), "registres", min = 1, max = 9
  ))))
  foret <- DBI::dbGetQuery(
    con, "SELECT nom, regime FROM foret WHERE id = $1",
    params = parametres(list(foret_id))
  )
  if (nrow(foret) == 0L) {
    stop("Foret inconnue : ", foret_id, ".", call. = FALSE)
  }

  visa <- NULL
  limite <- NULL
  if (!est_vide(jusqu_au_visa)) {
    exercice <- valider_entier(jusqu_au_visa, "jusqu_au_visa", min = 1500,
                               max = 2999)
    visa <- DBI::dbGetQuery(
      con,
      "SELECT exercice, autorite, seq_tete::float8 AS seq_tete,
              encode(hash_tete, 'hex') AS hash_tete,
              to_char(date_visa AT TIME ZONE 'UTC', 'YYYY-MM-DD') AS date_visa,
              (tst_rfc3161 IS NOT NULL) AS horodate,
              signataire::text AS signataire, signature_jws,
              encode(certificat, 'hex') AS certificat,
              encode(tst_rfc3161, 'hex') AS tst
         FROM visa WHERE foret_id = $1 AND exercice = $2
        ORDER BY seq_tete DESC",
      params = parametres(list(foret_id, exercice))
    )
    if (nrow(visa) == 0L) {
      stop("L'exercice ", exercice, " n'a pas de visa : l'edition ne peut ",
           "pas s'y arreter.", call. = FALSE)
    }
    visa <- as.list(visa[1L, , drop = FALSE])
    limite <- visa$seq_tete
  }

  toutes <- sommier_lire(con, foret_id)
  toutes$seq <- as.numeric(toutes$seq)
  if (!is.null(limite)) {
    toutes <- toutes[toutes$seq <= limite, , drop = FALSE]
  }
  verification <- sommier_verifier_chaine(toutes, foret_id = foret_id)
  verification$seq_tete <- if (is.null(verification$seq_tete)) NULL else
    as.numeric(verification$seq_tete)
  if (!is.null(visa)) {
    visa$concorde <- identical(tolower(verification$hash_tete),
                               tolower(visa$hash_tete))
    visa <- attestation_du_visa(con, foret_id, visa, cles_publiques, ancres)
  }

  ug <- DBI::dbGetQuery(
    con, "SELECT uuid::text AS uuid, numero_affichage FROM ug WHERE foret_id = $1",
    params = parametres(list(foret_id))
  )
  ecritures <- ecritures_imprimees(toutes, ug)
  ecritures <- ecritures[ecritures$registre %in% registres, , drop = FALSE]
  rownames(ecritures) <- NULL

  structure(
    list(
      foret = list(id = foret_id, nom = foret$nom[[1L]],
                   regime = foret$regime[[1L]]),
      registres = registres,
      ecritures = ecritures,
      tenue = tenue_du_sommier(con, foret_id, toutes,
                               if (is.null(visa)) NULL else visa$exercice),
      ancrages = ancrages_du_sommier(con, foret_id, limite),
      verification = verification,
      visa = visa
    ),
    class = "sommier_registre"
  )
}

#' @export
print.sommier_registre <- function(x, ...) {
  cat("<sommier_registre> ", x$foret$nom, "\n", sep = "")
  cat("  ecritures : ", nrow(x$ecritures), " (registres ",
      paste(x$registres, collapse = ", "), ")\n", sep = "")
  cat("  chaine    : ", if (isTRUE(x$verification$valide)) "intacte" else
    "ALTEREE", "\n", sep = "")
  if (!is.null(x$visa)) {
    cat("  arretee au visa de l'exercice ", x$visa$exercice, "\n", sep = "")
  }
  invisible(x)
}

#' Sommier imprime en Quarto
#'
#' @description
#' Rend le sommier ecriture par ecriture - le document "Sommier de la foret" -
#' en HTML autoportant ou en PDF : la fiche A10 de tenue, puis chaque
#' registre dans l'ordre de la chaine, et en annexe les empreintes completes.
#'
#' @details
#' Meme mecanique que [sommier_rapport_quarto()] : l'extraction
#' ([sommier_registre()]) est deposee dans un RDS que le gabarit lit, et le
#' rendu ne touche pas la base. Le document n'est pas la preuve : la valeur
#' probante reste dans la chaine, que [sommier_exporter_manifeste()]
#' transporte, et le document le dit.
#'
#' Un sommier a transmettre hors du gestionnaire se rend avec `public = TRUE`
#' : les noms de tiers des registres 3 et 7 (titulaires, garants, tiers d'une
#' ecriture) sont remplaces par "(masque)". La ligne, son montant et son
#' empreinte restent : on voit qu'une ecriture existe, pas qui elle nomme. Les
#' photos des constats ne sont jamais reproduites, seulement comptees.
#'
#' Arrete a un visa (`jusqu_au_visa`), le document porte en tete ce visa tel
#' que [sommier_verifier_visas()] le juge : le signataire et son certificat,
#' la signature, le jeton d'horodatage et l'autorite qui l'a emis. Les pieces
#' elles-memes (signature JWS, certificat PEM, jeton en base64) sont en
#' annexe. Le nom du signataire n'est pas masque a `public = TRUE` : il vise
#' en qualite, ce n'est pas un tiers.
#'
#' @inheritParams sommier_registre
#' @param chemin Fichier de destination. Son extension doit s'accorder avec
#'   `format`.
#' @param format `"html"` ou `"pdf"`.
#' @param public `TRUE` pour un sommier a transmettre : les tiers des
#'   registres 3 et 7 sont masques.
#' @param quarto Chemin de l'executable Quarto.
#'
#' @return Invisiblement, le chemin du document produit.
#'
#' @seealso [sommier_registre()], [sommier_rapport_quarto()]
#'
#' @export
sommier_registre_quarto <- function(con, foret_id, chemin, format = "html",
                                    registres = 1:9, jusqu_au_visa = NULL,
                                    public = FALSE, cles_publiques = list(),
                                    ancres = list(),
                                    quarto = Sys.which("quarto")) {
  format <- valider_choix(format, "format", SOMMIER_FORMATS_QUARTO)
  chemin <- valider_texte(chemin, "chemin")
  if (!nzchar(quarto)) {
    stop("Quarto est introuvable dans le PATH. L'installer depuis ",
         "https://quarto.org, ou passer son chemin par `quarto`.",
         call. = FALSE)
  }
  extension <- tolower(tools::file_ext(chemin))
  if (!identical(extension, format)) {
    stop("L'extension de `chemin` (", extension, ") ne correspond pas au ",
         "format demande (", format, ").", call. = FALSE)
  }
  sommier <- sommier_registre(con, foret_id, registres = registres,
                              jusqu_au_visa = jusqu_au_visa,
                              cles_publiques = cles_publiques, ancres = ancres)
  if (isTRUE(public)) {
    sommier$ecritures <- masquer_tiers(sommier$ecritures)
  }
  donnees <- list(
    sommier = sommier,
    public = isTRUE(public),
    version_sommier = as.character(utils::packageVersion("sommieR")),
    edite_le = format(Sys.Date(), "%d/%m/%Y")
  )

  modele <- system.file("quarto", "sommier.qmd", package = "sommieR")
  if (modele == "") {
    stop("Modele Quarto du sommier introuvable dans le paquet.", call. = FALSE)
  }
  atelier <- tempfile("sommier-registre-")
  dir.create(atelier)
  on.exit(unlink(atelier, recursive = TRUE), add = TRUE)
  source_qmd <- file.path(atelier, "sommier.qmd")
  file.copy(modele, source_qmd)
  poser_sous_titre(source_qmd, sommier$foret$nom)
  saveRDS(donnees, file.path(atelier, "donnees.rds"))

  resultat <- system2(
    quarto,
    c("render", shQuote(normalizePath(source_qmd)), "--to", format),
    stdout = TRUE, stderr = TRUE, env = environnement_utf8()
  )
  statut <- attr(resultat, "status")
  produit <- file.path(atelier, paste0("sommier.", format))
  if ((!is.null(statut) && statut != 0L) || !file.exists(produit)) {
    stop("Le rendu Quarto a echoue :\n",
         paste(utils::tail(resultat, 25L), collapse = "\n"), call. = FALSE)
  }
  dossier <- dirname(chemin)
  if (!dir.exists(dossier)) {
    dir.create(dossier, recursive = TRUE)
  }
  if (!isTRUE(file.copy(produit, chemin, overwrite = TRUE))) {
    stop("Impossible d'ecrire le document dans ", chemin, ".", call. = FALSE)
  }
  invisible(chemin)
}

# ---------------------------------------------------------------------------

# Les champs d'un payload qui nomment une personne, par registre : ceux que
# le bilan ecarte deja du PSG, et qu'un sommier transmis doit pouvoir taire.
CHAMPS_TIERS <- list(`3` = c("titulaire", "garants"), `7` = c("tiers"))

ecritures_imprimees <- function(toutes, ug) {
  if (nrow(toutes) == 0L) {
    return(data.frame(
      seq = numeric(0), registre = integer(0), type_entree = character(0),
      date_evenement = character(0), date_saisie = character(0),
      auteur = character(0), ndp = integer(0), ug = character(0),
      provenance = character(0), piece = character(0), rectifie = numeric(0),
      rectifiee_par = numeric(0), contenu = character(0),
      payload = character(0), schema_version = character(0),
      hash = character(0), stringsAsFactors = FALSE
    ))
  }
  payloads <- lapply(toutes$payload, jsonlite::fromJSON,
                     simplifyVector = FALSE)
  seq_par_id <- stats::setNames(toutes$seq, toutes$id)
  rectifie <- unname(seq_par_id[as.character(toutes$corrige_id)])
  rectifiee_par <- vapply(toutes$id, function(id) {
    par <- toutes$seq[!is.na(toutes$corrige_id) & toutes$corrige_id == id]
    if (length(par) == 0L) NA_real_ else max(par)
  }, numeric(1), USE.NAMES = FALSE)
  reprises <- lapply(payloads, function(p) p$reprise)
  piece <- vapply(reprises, function(r) {
    if (is.null(r)) return(NA_character_)
    paste0(r$source, " : ", r$reference,
           if (!is.null(r$date_piece)) paste0(" (", r$date_piece, ")"),
           if (!is.null(r$detenteur)) paste0(", ", r$detenteur))
  }, character(1))
  data.frame(
    seq = toutes$seq,
    registre = as.integer(toutes$registre),
    type_entree = vapply(payloads, function(p) {
      t <- p$type_entree %||% p$type_fiche %||% p$type_validation
      if (is.null(t)) NA_character_ else as.character(t)
    }, character(1)),
    date_evenement = as.character(toutes$date_evenement),
    date_saisie = substr(as.character(toutes$date_saisie), 1L, 10L),
    auteur = as.character(toutes$auteur),
    ndp = as.integer(toutes$ndp),
    ug = unname(stats::setNames(ug$numero_affichage, ug$uuid)[
      as.character(toutes$ug_uuid)]),
    provenance = ifelse(is.na(piece), "constat", "transcription"),
    piece = piece,
    rectifie = rectifie,
    rectifiee_par = rectifiee_par,
    contenu = vapply(payloads, contenu_generique, character(1)),
    payload = as.character(toutes$payload),
    schema_version = as.character(toutes$schema_version),
    hash = as.character(toutes$hash),
    stringsAsFactors = FALSE
  )
}

# Le repli "cle : valeur" : tout champ du payload, sauf ce qui a sa colonne
# (le type, la piece) ou ne se lit pas en ligne (la geometrie, les photos,
# dites par leur forme et leur nombre).
contenu_generique <- function(p) {
  champs <- setdiff(names(p), c("type_entree", "reprise", "geometrie",
                                "photos"))
  morceaux <- vapply(champs, function(n) {
    v <- p[[n]]
    texte <- if (is.list(v)) {
      if (!is.null(names(v)) && all(nzchar(names(v)))) {
        paste0(names(v), " = ", vapply(v, function(x) paste(unlist(x),
                                                            collapse = " "),
                                       character(1)), collapse = ", ")
      } else {
        paste(unlist(v), collapse = ", ")
      }
    } else {
      paste(v, collapse = ", ")
    }
    paste0(n, " : ", texte)
  }, character(1))
  if (!is.null(p$geometrie$type)) {
    morceaux <- c(morceaux, paste0("geometrie : ", p$geometrie$type))
  }
  if (length(p$photos) > 0L) {
    morceaux <- c(morceaux, paste0("photos : ", length(p$photos)))
  }
  paste(morceaux, collapse = " ; ")
}

masquer_tiers <- function(ecritures) {
  masque <- "(masqu\u00e9)"
  for (r in names(CHAMPS_TIERS)) {
    lignes <- which(ecritures$registre == as.integer(r))
    for (i in lignes) {
      p <- jsonlite::fromJSON(ecritures$payload[[i]], simplifyVector = FALSE)
      champs <- intersect(CHAMPS_TIERS[[r]], names(p))
      if (length(champs) == 0L) next
      for (champ in champs) {
        p[[champ]] <- if (length(p[[champ]]) > 1L)
          as.list(rep(masque, length(p[[champ]]))) else masque
      }
      ecritures$payload[[i]] <- as.character(jsonlite::toJSON(
        p, auto_unbox = TRUE, null = "null", digits = NA
      ))
      ecritures$contenu[[i]] <- contenu_generique(p)
    }
  }
  ecritures
}

# La fiche A10 : chaque exercice depuis l'ouverture du sommier, ses actes de
# visa et leur etat. Un exercice sans acte est dit non vise plutot que tu.
tenue_du_sommier <- function(con, foret_id, toutes, exercice_limite) {
  actes <- DBI::dbGetQuery(
    con,
    "SELECT exercice, autorite, nom_qualite, date_acte::text AS date_acte,
            signe, horodate, seq_tete::float8 AS seq_tete
       FROM v_tenue_sommier WHERE foret_id = $1 ORDER BY exercice",
    params = parametres(list(foret_id))
  )
  if (!is.null(exercice_limite)) {
    actes <- actes[actes$exercice <= exercice_limite, , drop = FALSE]
  }
  if (nrow(toutes) == 0L) {
    return(actes)
  }
  # De l'exercice le plus ancien - premier acte ou premiere saisie - au
  # dernier exercice clos : l'exercice en cours n'a pas encore a etre vise.
  premier <- min(c(as.integer(substr(min(as.character(toutes$date_saisie)),
                                     1L, 4L)), actes$exercice))
  dernier <- if (is.null(exercice_limite)) {
    as.integer(format(Sys.Date(), "%Y")) - 1L
  } else {
    exercice_limite
  }
  manquants <- if (dernier < premier) integer(0) else
    setdiff(seq.int(premier, dernier), actes$exercice)
  if (length(manquants) > 0L) {
    actes <- rbind(actes, data.frame(
      exercice = manquants, autorite = NA_character_,
      nom_qualite = NA_character_, date_acte = NA_character_, signe = NA,
      horodate = NA, seq_tete = NA_real_, stringsAsFactors = FALSE
    ))
  }
  actes <- actes[order(actes$exercice), , drop = FALSE]
  rownames(actes) <- NULL
  actes
}

ancrages_du_sommier <- function(con, foret_id, limite) {
  ancrages <- DBI::dbGetQuery(
    con,
    "SELECT seq_tete::float8 AS seq_tete, encode(hash_tete, 'hex') AS hash_tete,
            to_char(date_ancrage AT TIME ZONE 'UTC', 'YYYY-MM-DD') AS date_ancrage
       FROM ancrage WHERE foret_id = $1 ORDER BY seq_tete",
    params = parametres(list(foret_id))
  )
  if (!is.null(limite)) {
    ancrages <- ancrages[ancrages$seq_tete <= limite, , drop = FALSE]
  }
  ancrages
}

# L'attestation du visa qui arrete l'edition : ce que sommier_verifier_visas()
# en juge, et les pieces sur lesquelles porte ce jugement, lues pour etre
# imprimees. Le jeton brut quitte la liste au profit de sa lecture : le RDS
# du rendu n'a pas a le porter deux fois.
attestation_du_visa <- function(con, foret_id, visa, cles_publiques, ancres) {
  verdicts <- sommier_verifier_visas(con, foret_id,
                                     cles_publiques = cles_publiques,
                                     ancres = ancres)
  ligne <- verdicts[verdicts$exercice == visa$exercice &
                      verdicts$autorite == visa$autorite &
                      verdicts$seq_tete == visa$seq_tete, , drop = FALSE]
  verifie <- if (nrow(ligne) == 0L) NULL else as.list(ligne[1L, ])

  claims <- jsonlite::fromJSON(visa$signataire, simplifyVector = FALSE)
  entete <- try(jsonlite::fromJSON(
    rawToChar(base64url_decoder(strsplit(visa$signature_jws, "..",
                                         fixed = TRUE)[[1L]][[1L]])),
    simplifyVector = FALSE
  ), silent = TRUE)
  if (inherits(entete, "try-error")) {
    entete <- list()
  }

  certificat <- certificat_du_visa(visa$certificat)
  jeton <- jeton_du_visa(visa$tst, visa$hash_tete, ancres)
  if (!is.null(verifie)) {
    # La cle sous laquelle la signature a ete jugee : celle du certificat
    # quand le visa en porte un lisible, sinon celle que l'appelant a fournie.
    verifie$cle <- if (is.na(verifie$signature_valide)) NA_character_ else
      if (!is.null(certificat) && is.null(certificat$erreur)) "certificat" else
        "fournie"
  }

  visa$signataire <- list(
    sub = as.character(claims$sub %||% NA_character_),
    nom = as.character(claims$name %||% NA_character_),
    claims = claims,
    alg = as.character(entete$alg %||% NA_character_),
    kid = as.character(entete$kid %||% NA_character_)
  )
  visa$certificat <- certificat
  visa$jeton <- jeton
  visa$tst <- NULL
  visa$verifie <- verifie
  visa
}

# Le certificat du signataire, dit en clair. Les noms sont ceux d'openssl,
# pour etre lus ; la serie et les dates, celles de certificat_lire(), qui
# fondent la verification.
certificat_du_visa <- function(certificat_hex) {
  if (est_vide(certificat_hex)) {
    return(NULL)
  }
  der <- try(octets_depuis_hex(certificat_hex, "certificat"), silent = TRUE)
  lu <- if (inherits(der, "try-error")) der else
    try(certificat_lire(der), silent = TRUE)
  cert <- if (inherits(lu, "try-error")) lu else
    try(openssl::read_cert(der, der = TRUE), silent = TRUE)
  if (inherits(cert, "try-error")) {
    return(list(erreur = "certificat illisible"))
  }
  texte <- as.list(cert)
  list(
    sujet = texte$subject,
    emetteur = texte$issuer,
    auto_signe = isTRUE(texte$self_signed),
    serie = lu$serie,
    debut = format(lu$debut, "%Y-%m-%d", tz = "UTC"),
    fin = format(lu$fin, "%Y-%m-%d", tz = "UTC"),
    empreinte = empreinte_hex(as.raw(openssl::sha256(der))),
    pem = openssl::write_pem(cert)
  )
}

# Le jeton d'horodatage, lu : ce qu'il atteste, quand, et qui l'atteste. Le
# verdict lui-meme vient de sommier_verifier_visas() ; on ne relit ici le
# jeton que pour nommer l'autorite et en rendre la piece.
jeton_du_visa <- function(tst_hex, hash_tete, ancres) {
  if (est_vide(tst_hex)) {
    return(NULL)
  }
  jeton <- try(octets_depuis_hex(tst_hex, "tst_rfc3161"), silent = TRUE)
  if (inherits(jeton, "try-error")) {
    return(list(erreur = "jeton illisible"))
  }
  verdict <- tsa_verifier_jeton(jeton, empreinte_depuis_hex(hash_tete), ancres)
  lu <- verdict$jeton
  autorite <- NA_character_
  if (!is.null(verdict$certificat)) {
    nom <- try(as.list(openssl::read_cert(verdict$certificat$der,
                                          der = TRUE))$subject, silent = TRUE)
    if (!inherits(nom, "try-error")) {
      autorite <- nom
    }
  }
  list(
    date = if (is.null(lu)) NA_character_ else
      format(lu$date, "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
    serie = if (is.null(lu)) NA_character_ else lu$serie,
    politique = if (is.null(lu)) NA_character_ else lu$politique,
    algorithme = if (is.null(lu)) NA_character_ else lu$algorithme,
    empreinte = if (is.null(lu)) NA_character_ else empreinte_hex(lu$empreinte),
    autorite = autorite,
    base64 = as.character(openssl::base64_encode(jeton))
  )
}
