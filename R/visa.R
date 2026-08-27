#' Pose d'un visa signe sur la tete de chaine
#'
#' @description
#' Cloture un exercice : enregistre l'acte de visa au registre 1, signe la
#' tete de chaine, l'horodate si une autorite est configuree, et inscrit le
#' visa. C'est le flux de la section 6.3 du brief.
#'
#' @details
#' L'ordre des operations n'est pas indifferent.
#'
#' 1. L'entree de registre 1 est ecrite **d'abord**, de sorte que la tete
#'    signee la couvre : le visa atteste un sommier qui contient la trace de
#'    sa propre delivrance.
#' 2. La tete est lue **ensuite**, dans la meme transaction.
#' 3. La signature et l'horodatage portent sur cette tete.
#'
#' Signer avant d'ecrire l'acte laisserait au contraire une entree hors
#' couverture du visa.
#'
#' Si `tsa_url` est laisse a `NULL`, le visa est pose sans jeton
#' d'horodatage : c'est un visa valide, mais dont la date ne repose que sur
#' l'horloge du serveur. [sommier_verifier_visas()] le signale.
#'
#' @param con Connexion DBI.
#' @param foret_id UUID de la foret.
#' @param exercice Exercice vise (entier).
#' @param autorite Autorite de validation : `"onf"`, `"commune"`, `"crpf"` ou
#'   `"proprietaire"`.
#' @param signataire Objet [sommier_signataire()].
#' @param nom_qualite Nom et qualite portes au registre 1. Par defaut, le
#'   claim `name` du signataire, a defaut son `sub`.
#' @param tsa_url URL de l'autorite d'horodatage (facultatif).
#' @param transport Transport HTTP, voir [tsa_transport_curl()].
#' @param enregistrer_acte Ecrire l'entree de registre 1 (defaut `TRUE`).
#'
#' @return Invisiblement, une liste : `id`, `seq_tete`, `hash_tete`
#'   (hexadecimal), `horodate` (booleen) et `date_attestee` - la date que
#'   l'autorite a certifiee, `NA` sans horodatage.
#'
#' @seealso [sommier_verifier_visas()]
#' @export
sommier_viser <- function(con, foret_id, exercice, autorite, signataire,
                          nom_qualite = NULL, tsa_url = NULL,
                          transport = tsa_transport_curl(),
                          enregistrer_acte = TRUE) {
  foret_id <- valider_uuid(foret_id, "foret_id")
  exercice <- valider_entier(exercice, "exercice", min = 1500, max = 2999)
  autorite <- valider_choix(autorite, "autorite",
                            c("onf", "commune", "crpf", "proprietaire"))
  if (!inherits(signataire, "sommier_signataire")) {
    stop("`signataire` doit venir de sommier_signataire().", call. = FALSE)
  }
  nom_qualite <- if (est_vide(nom_qualite)) {
    as.character(signataire$claims$name %||% signataire$claims$sub)
  } else {
    valider_texte(nom_qualite, "nom_qualite")
  }

  transaction(con, {
    if (isTRUE(enregistrer_acte)) {
      sommier_ajouter(con, sommier_entree(
        foret_id = foret_id, registre = 1L,
        date_evenement = format(Sys.Date(), "%Y-%m-%d"),
        auteur = as.character(signataire$claims$sub),
        payload = registre1_validation(
          type_validation = "visa_annuel", autorite = autorite,
          nom_qualite = nom_qualite, exercice = exercice, portee = "sommier"
        )
      ))
    }

    tete <- DBI::dbGetQuery(
      con,
      "SELECT seq, encode(hash, 'hex') AS hash
         FROM entree_sommier WHERE foret_id = $1 ORDER BY seq DESC LIMIT 1",
      params = list(foret_id)
    )
    if (nrow(tete) == 0L) {
      stop("Sommier vide : il n'y a aucune tete de chaine a viser.",
           call. = FALSE)
    }
    seq_tete <- as.numeric(tete$seq[[1L]])
    hash_tete <- empreinte_depuis_hex(tete$hash[[1L]])

    signature <- jws_signer_detache(hash_tete, signataire)

    jeton <- NULL
    if (!est_vide(tsa_url)) {
      jeton <- tsa_horodater(hash_tete, tsa_url, transport = transport)
    }

    id <- uuid_v4()
    DBI::dbExecute(
      con,
      "INSERT INTO visa (id, foret_id, exercice, seq_tete, hash_tete,
                         autorite, signataire, signature_jws, tst_rfc3161,
                         certificat)
       VALUES ($1, $2, $3, $4, decode($5, 'hex'), $6, $7::jsonb, $8,
               NULLIF($9, '')::bytea, NULLIF($10, '')::bytea)",
      params = list(
        id, foret_id, exercice, seq_tete, empreinte_hex(hash_tete),
        autorite, jcs(signataire$claims), signature,
        if (is.null(jeton)) "" else paste0("\\x", empreinte_hex(jeton)),
        if (is.null(signataire$certificat)) "" else
          paste0("\\x", empreinte_hex(signataire$certificat))
      )
    )

    invisible(list(id = id, seq_tete = seq_tete,
                   hash_tete = empreinte_hex(hash_tete),
                   horodate = !is.null(jeton),
                   date_attestee = if (is.null(jeton)) {
                     NA_character_
                   } else {
                     format(tsa_lire_jeton(jeton)$date, "%Y-%m-%dT%H:%M:%SZ",
                            tz = "UTC")
                   }))
  })
}

#' Ancrage periodique de la tete de chaine
#'
#' @description
#' Horodate la tete de chaine independamment de tout visa. Le brief
#' (section 6.3) en fait une tache periodique : elle garantit qu'un exercice
#' non vise ne peut pas non plus etre reecrit discretement.
#'
#' @param con Connexion DBI.
#' @param foret_id UUID de la foret.
#' @param tsa_url URL de l'autorite d'horodatage.
#' @param transport Transport HTTP, voir [tsa_transport_curl()].
#' @return Invisiblement, une liste : `id`, `seq_tete`, `hash_tete` et
#'   `date_attestee`.
#'
#' @export
sommier_ancrer <- function(con, foret_id, tsa_url,
                           transport = tsa_transport_curl()) {
  foret_id <- valider_uuid(foret_id, "foret_id")
  tete <- DBI::dbGetQuery(
    con,
    "SELECT seq, encode(hash, 'hex') AS hash
       FROM entree_sommier WHERE foret_id = $1 ORDER BY seq DESC LIMIT 1",
    params = list(foret_id)
  )
  if (nrow(tete) == 0L) {
    stop("Sommier vide : il n'y a aucune tete de chaine a ancrer.",
         call. = FALSE)
  }
  seq_tete <- as.numeric(tete$seq[[1L]])
  hash_tete <- empreinte_depuis_hex(tete$hash[[1L]])
  jeton <- tsa_horodater(hash_tete, tsa_url, transport = transport)

  id <- uuid_v4()
  DBI::dbExecute(
    con,
    "INSERT INTO ancrage (id, foret_id, seq_tete, hash_tete, tst_rfc3161)
     VALUES ($1, $2, $3, decode($4, 'hex'), decode($5, 'hex'))",
    params = list(id, foret_id, seq_tete, empreinte_hex(hash_tete),
                  empreinte_hex(jeton))
  )
  invisible(list(id = id, seq_tete = seq_tete,
                 hash_tete = empreinte_hex(hash_tete),
                 date_attestee = format(tsa_lire_jeton(jeton)$date,
                                        "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")))
}

#' Verification des visas d'une foret
#'
#' @description
#' Confronte chaque visa a la chaine : l'empreinte attestee correspond-elle
#' bien a l'entree de la sequence visee, et la signature est-elle valide sous
#' la cle fournie ?
#'
#' @details
#' Les cles publiques sont passees par l'appelant, indexees par `kid` ou par
#' `sub`. Le paquet ne va pas les chercher au JWKS du fournisseur : cela
#' ferait dependre une verification a valeur probante de la disponibilite d'un
#' service tiers au moment du controle, alors qu'un visa doit rester
#' verifiable des annees plus tard, hors ligne.
#'
#' Un visa sans jeton d'horodatage est signale mais n'invalide rien : sa date
#' repose sur l'horloge du serveur, ce que l'appelant doit savoir sans que
#' cela constitue une fraude.
#'
#' Depuis la v0.10.0, un visa peut porter le certificat de son signataire.
#' Quand il en porte un, la cle en est tiree et `cles_publiques` devient
#' inutile : le visa se verifie seul. Les visas anterieurs gardent le
#' comportement precedent.
#'
#' `date_attestee` est lue **dans le jeton**, non dans la base : c'est la date
#' que l'autorite a certifiee. La colonne `date_visa`, elle, est celle que le
#' registre s'est donnee a lui-meme, et ne prouve rien contre celui qui tient
#' la base.
#'
#' `horodatage` porte quatre etats plutot qu'un booleen, parce qu'un jeton se
#' juge sur plus que sa presence : `"absent"`, `"valide"` (signature de
#' l'autorite verifiee et chaine rattachee a une ancre), `"non_rattache"` (le
#' jeton est intact, mais aucune ancre ne le couvre) et `"invalide"`.
#'
#' La revocation des certificats n'est jamais verifiee : CRL et OCSP demandent
#' le reseau. Voir [tsa_verifier_jeton()].
#'
#' @param con Connexion DBI.
#' @param foret_id UUID de la foret.
#' @param cles_publiques Liste nommee de cles publiques, indexee par `kid` ou
#'   par `sub` du signataire. Inutile pour les visas portant leur certificat.
#' @param ancres Ancres de confiance pour les jetons d'horodatage, lues par
#'   [certificat_lire()]. Sans elles, un jeton intact est dit
#'   `"non_rattache"` plutot que valide.
#' @return Un `data.frame` : `exercice`, `autorite`, `seq_tete`, `concorde`,
#'   `signature_valide`, `horodatage`, `date_attestee`, `remarque`.
#'
#' @export
sommier_verifier_visas <- function(con, foret_id, cles_publiques = list(),
                                   ancres = list()) {
  foret_id <- valider_uuid(foret_id, "foret_id")
  visas <- DBI::dbGetQuery(
    con,
    "SELECT v.id, v.exercice, v.autorite, v.seq_tete,
            encode(v.hash_tete, 'hex') AS hash_tete,
            v.signataire::text AS signataire, v.signature_jws,
            encode(v.certificat, 'hex') AS certificat,
            encode(v.tst_rfc3161, 'hex') AS tst,
            encode(e.hash, 'hex') AS hash_chaine
       FROM visa v
       LEFT JOIN entree_sommier e
         ON e.foret_id = v.foret_id AND e.seq = v.seq_tete
      WHERE v.foret_id = $1
      ORDER BY v.exercice, v.autorite",
    params = list(foret_id)
  )
  if (nrow(visas) == 0L) {
    return(data.frame(
      exercice = integer(0), autorite = character(0), seq_tete = numeric(0),
      concorde = logical(0), signature_valide = logical(0),
      horodatage = character(0), date_attestee = character(0),
      remarque = character(0),
      stringsAsFactors = FALSE
    ))
  }

  resultat <- lapply(seq_len(nrow(visas)), function(i) {
    v <- visas[i, ]
    concorde <- !is.na(v$hash_chaine) &&
      identical(tolower(v$hash_chaine), tolower(v$hash_tete))

    claims <- jsonlite::fromJSON(v$signataire, simplifyVector = FALSE)
    porteur <- cle_du_certificat(v$certificat)
    cle <- porteur$cle %||% cle_du_signataire(cles_publiques, v$signature_jws, claims)
    valide <- if (is.null(cle)) {
      NA
    } else {
      jws_verifier_detache(v$signature_jws, empreinte_depuis_hex(v$hash_tete), cle)
    }

    horodatage <- horodatage_atteste(v$tst, v$hash_tete, ancres)

    remarques <- character(0)
    if (is.na(v$hash_chaine)) {
      remarques <- c(remarques, "sequence visee absente de la chaine")
    } else if (!concorde) {
      remarques <- c(remarques, "empreinte visee differente de celle de la chaine")
    }
    remarques <- c(remarques, porteur$remarques)
    if (is.null(cle)) {
      remarques <- c(remarques, "aucune cle publique fournie pour ce signataire")
    } else if (isFALSE(valide)) {
      remarques <- c(remarques, "signature invalide")
    }
    remarques <- c(remarques, horodatage$remarques)

    data.frame(
      exercice = as.integer(v$exercice), autorite = v$autorite,
      seq_tete = as.numeric(v$seq_tete), concorde = concorde,
      signature_valide = valide, horodatage = horodatage$etat,
      date_attestee = horodatage$date,
      remarque = if (length(remarques)) paste(remarques, collapse = " ; ") else NA_character_,
      stringsAsFactors = FALSE
    )
  })
  do.call(rbind, resultat)
}

# Ce qu'un jeton apprend d'une attestation : la date que l'autorite a
# certifiee, l'empreinte qu'elle couvre, et ce que vaut sa signature. Quatre
# etats, la ou le booleen `horodate` n'en distinguait que deux - pas de jeton,
# ou un jeton dont on ne savait rien.
horodatage_atteste <- function(tst_hex, hash_attendu, ancres = list()) {
  if (est_vide(tst_hex)) {
    return(list(etat = "absent", date = NA_character_,
                remarques = "sans jeton d'horodatage : date non opposable"))
  }
  jeton <- try(octets_depuis_hex(tst_hex, "tst_rfc3161"), silent = TRUE)
  if (inherits(jeton, "try-error")) {
    return(list(etat = "invalide", date = NA_character_,
                remarques = "jeton d'horodatage illisible"))
  }
  verdict <- tsa_verifier_jeton(jeton, empreinte_depuis_hex(hash_attendu), ancres)
  list(
    etat = verdict$etat,
    date = if (is.null(verdict$jeton)) NA_character_ else
      format(verdict$jeton$date, "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
    remarques = verdict$motifs
  )
}

# La cle publique que porte le visa lui-meme. C'est ce qui le rend
# autoporteur : le destinataire d'un export n'a plus a se procurer la cle par
# un canal que le manifeste n'organise pas.
cle_du_certificat <- function(certificat_hex) {
  if (est_vide(certificat_hex)) {
    return(list(cle = NULL, remarques = character(0)))
  }
  cert <- try(certificat_lire(octets_depuis_hex(certificat_hex, "certificat")),
              silent = TRUE)
  if (inherits(cert, "try-error")) {
    return(list(cle = NULL, remarques = "certificat du visa illisible"))
  }
  cle <- try(openssl::read_pubkey(cert$cle_publique, der = TRUE), silent = TRUE)
  if (inherits(cle, "try-error")) {
    return(list(cle = NULL,
                remarques = "cle publique illisible dans le certificat du visa"))
  }
  list(cle = cle, remarques = character(0))
}

# Retrouve la cle a employer : d'abord par le `kid` de l'en-tete JWS, qui est
# la designation explicite, puis par le `sub` du signataire.
cle_du_signataire <- function(cles, jws, claims) {
  if (length(cles) == 0L) {
    return(NULL)
  }
  entete <- try(
    jsonlite::fromJSON(
      rawToChar(base64url_decoder(strsplit(jws, "..", fixed = TRUE)[[1]][[1]])),
      simplifyVector = FALSE
    ),
    silent = TRUE
  )
  if (!inherits(entete, "try-error") && !est_vide(entete$kid) &&
      !is.null(cles[[entete$kid]])) {
    return(cles[[entete$kid]])
  }
  if (!est_vide(claims$sub) && !is.null(cles[[claims$sub]])) {
    return(cles[[claims$sub]])
  }
  NULL
}
