#' Ecriture d'entrees dans le sommier
#'
#' @description
#' Chaine puis insere une ou plusieurs entrees, en une transaction. La
#' position dans la chaine est determinee au moment de l'ecriture, a partir de
#' la tete courante lue en base : c'est le registre qui decide de la sequence,
#' pas l'appelant.
#'
#' @details
#' **Serialisation des ecritures.** L'insertion prend un
#' `pg_advisory_xact_lock(hashtext(foret_id::text))`, conformement au brief
#' (section 6.3). Sans ce verrou, deux transactions concurrentes liraient la
#' meme tete, calculeraient le meme `hash_prev` et forkeraient la chaine. Le
#' verrou est pris **avant** la lecture de la tete - le prendre apres ne
#' servirait a rien - et il est relache automatiquement a la fin de la
#' transaction.
#'
#' `hashtext()` pouvant entrer en collision, deux forets differentes peuvent
#' partager un verrou : c'est sans consequence sur la correction (elles
#' s'attendent inutilement), et la contrainte `UNIQUE (foret_id, seq)` reste
#' le filet de securite si le verrou venait a manquer.
#'
#' @param con Connexion DBI.
#' @param entrees Un objet `sommier_entree` ou une liste d'objets
#'   `sommier_entree`, tous de la meme foret.
#'
#' @return Invisiblement, la liste des entrees chainees telles qu'inserees
#'   (`seq`, `hash_prev` et `hash` renseignes).
#'
#' @seealso [sommier_entree()], [sommier_verifier()]
#'
#' @export
sommier_ajouter <- function(con, entrees) {
  if (inherits(entrees, "sommier_entree")) {
    entrees <- list(entrees)
  }
  if (length(entrees) == 0L) {
    return(invisible(list()))
  }
  if (!all(vapply(entrees, inherits, logical(1), "sommier_entree"))) {
    stop("sommier_ajouter(): `entrees` doit contenir des objets ",
         "`sommier_entree` (voir sommier_entree()).", call. = FALSE)
  }
  forets <- unique(vapply(entrees, function(e) e$foret_id, character(1)))
  if (length(forets) > 1L) {
    stop("sommier_ajouter(): la sequence est monotone par foret ; ",
         "ecrire une transaction par foret.", call. = FALSE)
  }
  foret_id <- forets[[1L]]

  transaction(con, {
    # Le verrou precede la lecture de la tete : c'est la lecture-puis-ecriture
    # qui doit etre atomique, pas la seule ecriture.
    DBI::dbGetQuery(
      con,
      "SELECT pg_advisory_xact_lock(hashtext($1::text))",
      params = list(foret_id)
    )

    tete <- DBI::dbGetQuery(
      con,
      "SELECT seq, encode(hash, 'hex') AS hash
         FROM entree_sommier
        WHERE foret_id = $1
        ORDER BY seq DESC
        LIMIT 1",
      params = list(foret_id)
    )

    if (nrow(tete) == 0L) {
      seq_depart <- 1
      hash_prev <- sommier_empreinte_genese(foret_id)
    } else {
      seq_depart <- as.numeric(tete$seq[[1L]]) + 1
      hash_prev <- empreinte_depuis_hex(tete$hash[[1L]])
    }

    chainees <- sommier_chainer(entrees, seq_depart = seq_depart,
                                hash_prev = hash_prev)
    df <- entrees_en_data_frame(chainees)

    inserer_entrees(con, df)

    chainees
  })
  invisible(chainees)
}

#' Lecture des entrees d'un sommier
#'
#' @description
#' Rend les entrees sous la forme attendue par [sommier_verifier_chaine()] :
#' les empreintes en hexadecimal, le payload en texte JSON, `date_saisie`
#' reformate en UTC a la seconde.
#'
#' @details
#' `date_saisie` est reserialise en `AAAA-MM-JJTHH:MM:SSZ`, exactement la
#' forme qui a ete hachee a l'ecriture. Laisser le pilote rendre un `POSIXct`
#' ferait dependre l'empreinte du fuseau de la session R, ce qui rendrait la
#' verification non reproductible d'un poste a l'autre.
#'
#' @param con Connexion DBI.
#' @param foret_id UUID de la foret.
#' @param registre Filtre facultatif sur le numero de registre.
#' @param depuis_seq Ne lire qu'a partir de cette sequence (verification d'un
#'   fragment a partir d'une ancre).
#' @return Un `data.frame`.
#'
#' @export
sommier_lire <- function(con, foret_id, registre = NULL, depuis_seq = NULL) {
  foret_id <- valider_uuid(foret_id, "foret_id")
  conditions <- "foret_id = $1"
  params <- list(foret_id)
  if (!est_vide(registre)) {
    params <- c(params, list(valider_entier(registre, "registre", min = 1, max = 9)))
    conditions <- c(conditions, sprintf("registre = $%d", length(params)))
  }
  if (!est_vide(depuis_seq)) {
    params <- c(params, list(valider_entier(depuis_seq, "depuis_seq", min = 1)))
    conditions <- c(conditions, sprintf("seq >= $%d", length(params)))
  }
  DBI::dbGetQuery(
    con,
    paste0(
      "SELECT id, foret_id, ug_uuid, registre, seq, date_evenement::text,
              to_char(date_saisie AT TIME ZONE 'UTC',
                      'YYYY-MM-DD\"T\"HH24:MI:SS\"Z\"') AS date_saisie,
              auteur, ndp, corrige_id, payload::text AS payload,
              schema_version,
              encode(hash_prev, 'hex') AS hash_prev,
              encode(hash, 'hex')      AS hash
         FROM entree_sommier
        WHERE ", paste(conditions, collapse = " AND "), "
        ORDER BY seq"
    ),
    params = parametres(params)
  )
}

#' Verification du sommier d'une foret en base
#'
#' Lit la chaine puis la verifie avec [sommier_verifier_chaine()]. Le nom est
#' celui du brief (section 6.3), qui la veut "exposee dans le package
#' (utilisable par un auditeur tiers sur un export) et executee a chaque
#' ouverture de projet dans nemetonShiny".
#'
#' @param con Connexion DBI.
#' @param foret_id UUID de la foret.
#' @param depuis_seq Verifier a partir de cette sequence. La verification
#'   d'un fragment exige `hash_prev_initial`.
#' @param hash_prev_initial Empreinte precedant `depuis_seq`.
#' @return Un objet `sommier_rapport`.
#'
#' @export
sommier_verifier <- function(con, foret_id, depuis_seq = NULL,
                             hash_prev_initial = NULL) {
  entrees <- sommier_lire(con, foret_id, depuis_seq = depuis_seq)
  sommier_verifier_chaine(
    entrees,
    foret_id = valider_uuid(foret_id, "foret_id"),
    hash_prev_initial = hash_prev_initial
  )
}

#' Balance de possibilite (imprime A50E)
#'
#' @description
#' Vue calculee, jamais saisie : `SUM(volumes marteles de l'exercice)` moins
#' la possibilite, cumulee par foret.
#'
#' @details
#' En foret publique, la balance se lit contre la possibilite de
#' l'amenagement regle. En foret privee, la meme mecanique sert de balance de
#' conformite au programme du PSG, avec une tolerance de plus ou moins quatre
#' ans : `tolerance_ans` ne change pas le calcul, il pose le nombre
#' d'exercices sur lequel la balance cumulee a vocation a se resorber.
#'
#' @param con Connexion DBI.
#' @param foret_id UUID de la foret.
#' @param tolerance_ans Fenetre de resorption admise (defaut `NULL` : aucune
#'   colonne d'appreciation n'est ajoutee).
#' @return Un `data.frame` : `exercice`, `possibilite_m3_an`,
#'   `volume_martele_m3`, `volume_realise_m3`, `balance_exercice_m3`,
#'   `balance_cumulee_m3`.
#'
#' @export
sommier_balance_possibilite <- function(con, foret_id, tolerance_ans = NULL) {
  foret_id <- valider_uuid(foret_id, "foret_id")
  res <- DBI::dbGetQuery(
    con,
    "SELECT exercice, possibilite_m3_an, volume_martele_m3, volume_realise_m3,
            balance_exercice_m3, balance_cumulee_m3
       FROM v_balance_possibilite
      WHERE foret_id = $1
      ORDER BY exercice",
    params = list(foret_id)
  )
  if (!est_vide(tolerance_ans) && nrow(res) > 0L) {
    tolerance_ans <- valider_entier(tolerance_ans, "tolerance_ans", min = 1)
    # Marge admissible : la possibilite moyenne multipliee par la fenetre de
    # resorption. Au-dela, l'ecart n'est plus rattrapable dans les delais.
    moyenne <- mean(res$possibilite_m3_an, na.rm = TRUE)
    marge <- moyenne * tolerance_ans
    res$conforme <- is.na(res$balance_cumulee_m3) |
      abs(res$balance_cumulee_m3) <= marge
  }
  res
}

#' Fixation de la possibilite d'un exercice
#'
#' @param con Connexion DBI.
#' @param foret_id UUID de la foret.
#' @param annee Annee de l'exercice.
#' @param possibilite_m3_an Possibilite annuelle en metres cubes.
#' @return Invisiblement, le nombre de lignes ecrites.
#'
#' @export
exercice_definir <- function(con, foret_id, annee, possibilite_m3_an) {
  invisible(DBI::dbExecute(
    con,
    "INSERT INTO exercice (foret_id, annee, possibilite_m3_an)
     VALUES ($1, $2, $3)
     ON CONFLICT (foret_id, annee)
     DO UPDATE SET possibilite_m3_an = EXCLUDED.possibilite_m3_an",
    params = list(
      valider_uuid(foret_id, "foret_id"),
      valider_entier(annee, "annee", min = 1500, max = 2999),
      valider_nombre(possibilite_m3_an, "possibilite_m3_an", min = 0)
    )
  ))
}

# Insertion en une seule instruction multi-lignes.
#
# On n'utilise pas la liaison vectorisee de DBI (`params` recevant des
# vecteurs) : elle fait partie de la specification mais tous les pilotes ne
# l'implementent pas - RPostgreSQL deparse le vecteur en chaine et produit un
# UUID invalide. Une instruction multi-lignes a parametres scalaires marche
# partout, et coute une seule aller-retour au lieu de N.
#
# PostgreSQL plafonne a 65535 parametres par instruction ; a 14 colonnes on
# decoupe donc par paquets, largement sous la limite.
inserer_entrees <- function(con, df, taille_paquet = 1000L) {
  colonnes <- c(
    "id", "foret_id", "ug_uuid", "registre", "seq", "date_evenement",
    "date_saisie", "auteur", "ndp", "corrige_id", "payload",
    "schema_version", "hash_prev", "hash"
  )
  # Les colonnes facultatives voyagent en chaine vide, retraduite en NULL par
  # NULLIF : voir texte_ou_vide() dans db.R.
  gabarit <- c(
    "$%d", "$%d", "NULLIF($%d, '')::uuid", "$%d", "$%d", "$%d::date",
    "$%d::timestamptz", "$%d", "$%d", "NULLIF($%d, '')::uuid", "$%d::jsonb",
    "$%d", "decode($%d, 'hex')", "decode($%d, 'hex')"
  )

  df$ug_uuid <- texte_ou_vide_vec(df$ug_uuid)
  df$corrige_id <- texte_ou_vide_vec(df$corrige_id)

  for (debut in seq(1L, nrow(df), by = taille_paquet)) {
    fin <- min(debut + taille_paquet - 1L, nrow(df))
    paquet <- df[debut:fin, , drop = FALSE]

    lignes <- vapply(seq_len(nrow(paquet)), function(i) {
      decalage <- (i - 1L) * length(colonnes)
      paste0("(", paste(
        vapply(seq_along(gabarit),
               function(j) sprintf(gabarit[[j]], decalage + j),
               character(1)),
        collapse = ", "), ")")
    }, character(1))

    params <- unlist(
      lapply(seq_len(nrow(paquet)),
             function(i) lapply(colonnes, function(c) as.character(paquet[[c]][[i]]))),
      recursive = FALSE
    )

    DBI::dbExecute(
      con,
      paste0(
        "INSERT INTO entree_sommier (", paste(colonnes, collapse = ", "), ")\n",
        "VALUES ", paste(lignes, collapse = ",\n       ")
      ),
      params = parametres(params)
    )
  }
  invisible(nrow(df))
}

# Variante vectorisee de `texte_ou_vide()` pour l'insertion par lot : les
# colonnes facultatives d'un lot melangent valeurs et absences ligne a ligne,
# on ne peut donc pas se contenter d'omettre la colonne.
texte_ou_vide_vec <- function(x) {
  x <- as.character(x)
  x[is.na(x)] <- ""
  x
}
