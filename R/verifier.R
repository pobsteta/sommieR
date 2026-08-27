#' Verification d'une chaine d'entrees de sommier
#'
#' @description
#' Recalcule la chaine de la genese a la tete et confronte chaque empreinte
#' stockee a l'empreinte recalculee. C'est la fonction que le brief
#' (section 6.3) designe comme utilisable "par un auditeur tiers sur un
#' export" : elle ne touche pas la base et ne fait confiance a aucun serveur,
#' elle ne travaille que sur les donnees qu'on lui remet.
#'
#' @details
#' Cinq classes d'anomalies sont distinguees, parce qu'elles ne se corrigent
#' pas de la meme facon :
#'
#' * `sequence_manquante` : un trou dans `seq` - une entree a ete retiree de
#'   l'export, ou n'a jamais ete inseree.
#' * `sequence_dupliquee` : deux entrees portant le meme `seq` - signe d'une
#'   fourche d'ecriture concurrente que le verrou consultatif aurait du
#'   empecher.
#' * `chainage_rompu` : le `hash_prev` d'une entree ne correspond pas au
#'   `hash` de la precedente - une entree a ete inseree, retiree ou reordonnee.
#' * `empreinte_invalide` : le `hash` stocke ne correspond pas au recalcul sur
#'   le contenu - le contenu de l'entree a ete modifie apres coup.
#' * `genese_invalide` : la premiere entree ne part pas de
#'   [sommier_empreinte_genese()] - la chaine a ete tronquee par le debut.
#'
#' Une chaine dont la premiere entree n'a pas `seq == 1` est signalee comme
#' tronquee : la verification reste possible a partir d'une ancre connue, mais
#' l'appelant doit alors fournir `hash_prev_initial`.
#'
#' @param entrees `data.frame` ou liste de listes nommees, portant au moins
#'   les colonnes de [SOMMIER_CHAMPS_EMPREINTE] plus `hash` et `hash_prev`.
#'   Les empreintes sont acceptees en `raw` ou en hexadecimal. Le `payload`
#'   peut etre une liste R ou du texte JSON (recanonise via
#'   [jcs_depuis_json()]).
#' @param foret_id Identifiant de la foret ; deduit des entrees si absent.
#' @param hash_prev_initial Empreinte precedant la premiere entree fournie.
#'   Par defaut, la genese de la foret - a renseigner pour verifier un
#'   fragment de chaine a partir d'une ancre.
#'
#' @return Un objet de classe `sommier_rapport` : liste comportant `valide`
#'   (booleen), `n_entrees`, `foret_id`, `seq_tete`, `hash_tete` (hexadecimal)
#'   et `anomalies` (`data.frame` a colonnes `seq`, `id`, `type`, `message`).
#'
#' @examples
#' entrees <- sommier_chainer(list(
#'   sommier_entree(
#'     foret_id = "3f2b1c4d-5e6f-4a7b-8c9d-0e1f2a3b4c5d",
#'     registre = 5L, date_evenement = "2026-03-01", auteur = "agent-01",
#'     payload = registre5_coupe(
#'       type_entree = "martelage", exercice = 2026,
#'       nature_coupe = "amelioration", volume_m3 = 120
#'     )
#'   )
#' ))
#' sommier_verifier_chaine(entrees)
#'
#' @export
sommier_verifier_chaine <- function(entrees,
                                    foret_id = NULL,
                                    hash_prev_initial = NULL) {
  entrees <- normaliser_entrees(entrees)

  if (length(entrees) == 0L) {
    return(rapport(TRUE, 0L, foret_id, NA_real_, NA_character_, anomalies_vides()))
  }

  if (is.null(foret_id)) {
    forets <- unique(vapply(entrees, function(e) as.character(e$foret_id), character(1)))
    if (length(forets) > 1L) {
      stop(
        "sommier_verifier_chaine(): entrees de plusieurs forets ",
        "(la chaine est monotone par foret) : ",
        paste(forets, collapse = ", "), ".",
        call. = FALSE
      )
    }
    foret_id <- forets[[1L]]
  }
  foret_id <- valider_uuid(foret_id, "foret_id")

  # La chaine est definie par l'ordre des `seq`, pas par l'ordre de livraison :
  # un export trie autrement reste verifiable.
  seqs <- vapply(entrees, function(e) valider_entier(e$seq, "seq", min = 1), numeric(1))
  entrees <- entrees[order(seqs)]
  seqs <- sort(seqs)

  anomalies <- anomalies_vides()

  doublons <- unique(seqs[duplicated(seqs)])
  for (s in doublons) {
    anomalies <- ajouter_anomalie(
      anomalies, s, NA_character_, "sequence_dupliquee",
      paste0("Deux entrees ou plus portent seq = ", format(s, scientific = FALSE),
             " : ecritures concurrentes non serialisees.")
    )
  }

  attendu <- seq(from = seqs[[1L]], to = seqs[[length(seqs)]])
  trous <- setdiff(attendu, seqs)
  for (s in trous) {
    anomalies <- ajouter_anomalie(
      anomalies, s, NA_character_, "sequence_manquante",
      paste0("Aucune entree de seq = ", format(s, scientific = FALSE),
             " : entree retiree ou jamais inseree.")
    )
  }

  if (is.null(hash_prev_initial)) {
    hash_prev_initial <- sommier_empreinte_genese(foret_id)
    if (seqs[[1L]] != 1) {
      anomalies <- ajouter_anomalie(
        anomalies, seqs[[1L]], entrees[[1L]]$id, "genese_invalide",
        paste0("La chaine commence a seq = ", format(seqs[[1L]], scientific = FALSE),
               " et non a 1 : fournir `hash_prev_initial` pour verifier ",
               "un fragment a partir d'une ancre.")
      )
    }
  }
  attendu_prev <- valider_empreinte(hash_prev_initial, "hash_prev_initial")

  for (i in seq_along(entrees)) {
    e <- entrees[[i]]
    hash_prev <- valider_empreinte(e$hash_prev, "hash_prev")
    hash_stocke <- valider_empreinte(e$hash, "hash")

    if (!identical(hash_prev, attendu_prev)) {
      type <- if (i == 1L) "genese_invalide" else "chainage_rompu"
      anomalies <- ajouter_anomalie(
        anomalies, e$seq, e$id, type,
        paste0("hash_prev = ", empreinte_hex(hash_prev),
               " alors que le maillon precedent vaut ", empreinte_hex(attendu_prev), ".")
      )
    }

    hash_calcule <- sommier_empreinte(e, hash_prev)
    if (!identical(hash_calcule, hash_stocke)) {
      anomalies <- ajouter_anomalie(
        anomalies, e$seq, e$id, "empreinte_invalide",
        paste0("hash stocke = ", empreinte_hex(hash_stocke),
               ", hash recalcule = ", empreinte_hex(hash_calcule),
               " : le contenu de l'entree a change depuis son insertion.")
      )
    }

    # On poursuit sur l'empreinte stockee : cela isole l'anomalie sur l'entree
    # fautive au lieu de faire cascader une seule alteration sur toute la suite.
    attendu_prev <- hash_stocke
  }

  derniere <- entrees[[length(entrees)]]
  rapport(
    valide = nrow(anomalies) == 0L,
    n_entrees = length(entrees),
    foret_id = foret_id,
    seq_tete = derniere$seq,
    hash_tete = empreinte_hex(valider_empreinte(derniere$hash, "hash")),
    anomalies = anomalies
  )
}

#' @export
print.sommier_rapport <- function(x, ...) {
  cat("Verification de chaine - sommier\n")
  cat("  foret     : ", x$foret_id %||% "(inconnue)", "\n", sep = "")
  cat("  entrees   : ", x$n_entrees, "\n", sep = "")
  if (x$n_entrees > 0L) {
    cat("  seq tete  : ", format(x$seq_tete, scientific = FALSE), "\n", sep = "")
    cat("  hash tete : ", x$hash_tete, "\n", sep = "")
  }
  if (isTRUE(x$valide)) {
    cat("  etat      : chaine intacte\n")
  } else {
    cat("  etat      : ", nrow(x$anomalies), " anomalie(s)\n", sep = "")
    for (i in seq_len(nrow(x$anomalies))) {
      cat("    - seq ", format(x$anomalies$seq[[i]], scientific = FALSE),
          " [", x$anomalies$type[[i]], "] ",
          x$anomalies$message[[i]], "\n", sep = "")
    }
  }
  for (reserve in x$reserves %||% character(0)) {
    cat("  reserve   : ", reserve, "\n", sep = "")
  }
  invisible(x)
}

rapport <- function(valide, n_entrees, foret_id, seq_tete, hash_tete, anomalies,
                    reserves = character(0)) {
  structure(
    list(
      valide = valide, n_entrees = n_entrees, foret_id = foret_id,
      seq_tete = seq_tete, hash_tete = hash_tete, anomalies = anomalies,
      # Une reserve n'est pas une anomalie : elle dit ce qui n'a PAS pu etre
      # verifie, quand rien n'indique pour autant que ce soit faux. Les
      # confondre ferait declarer invalide un manifeste intact dont on n'a
      # simplement pas les ancres de confiance.
      reserves = reserves
    ),
    class = "sommier_rapport"
  )
}

anomalies_vides <- function() {
  data.frame(
    seq = numeric(0), id = character(0),
    type = character(0), message = character(0),
    stringsAsFactors = FALSE
  )
}

ajouter_anomalie <- function(anomalies, seq, id, type, message) {
  rbind(anomalies, data.frame(
    seq = as.numeric(seq),
    id = if (est_vide(id)) NA_character_ else as.character(id),
    type = type, message = message,
    stringsAsFactors = FALSE
  ))
}

# Accepte indifferemment un data.frame (sortie DBI) ou une liste de listes
# (sortie de sommier_chainer / lecture d'un manifeste JSON).
normaliser_entrees <- function(entrees) {
  if (is.data.frame(entrees)) {
    entrees <- lapply(seq_len(nrow(entrees)), function(i) {
      ligne <- lapply(entrees, function(col) col[[i]])
      names(ligne) <- names(entrees)
      ligne
    })
  }
  if (!is.list(entrees)) {
    stop("sommier_verifier_chaine(): `entrees` doit etre un data.frame ou ",
         "une liste de listes nommees.", call. = FALSE)
  }
  lapply(entrees, function(e) {
    if (is.character(e$payload) && length(e$payload) == 1L) {
      # Un payload venant d'un export est du texte JSON : on le relit pour
      # pouvoir le recanoniser, jamais on ne hache le texte tel quel.
      e$payload <- normaliser_json_lu(jsonlite::fromJSON(
        e$payload, simplifyVector = FALSE,
        simplifyDataFrame = FALSE, simplifyMatrix = FALSE
      ))
    }
    e
  })
}

`%||%` <- function(x, y) if (is.null(x)) y else x
