#' Provenances usuelles d'une reprise, et le NDP qu'elles portent
#'
#' @description
#' L'echelle de precision applicable a ce qui entre dans le sommier par
#' transcription. Elle evite que le NDP d'une reprise soit laisse au jugement
#' de l'appelant : deux communes qui transcrivent le meme genre de piece
#' doivent porter le meme niveau, sans quoi le champ ne dit plus rien.
#'
#' @details
#' Le NDP croit avec la distance entre l'ecriture et un fait attestable.
#' NDP 0 n'y figure pas : il est reserve au constat de terrain, et une
#' transcription n'en est jamais un - voir [sommier_reprise()].
#'
#' | Provenance | NDP | Ce qui la distingue |
#' | --- | :-: | --- |
#' | `registre_signe` | 1 | une piece datee et signee, opposable telle quelle |
#' | `base_gestionnaire` | 2 | une base tenue, mais sans visa piece a piece |
#' | `tableur` | 3 | un fichier sans tenue verifiable ni signature |
#' | `temoignage` | 4 | une declaration recueillie, sans piece qui la porte |
#'
#' L'echelle est volontairement courte. Une provenance qui n'y figure pas se
#' rattache a la ligne la plus proche par le bas - une piece dont on ne sait
#' pas dire qui la tenait ne vaut pas mieux qu'un tableur.
#'
#' @format `data.frame` de 4 lignes et 3 colonnes : `source`, `ndp`,
#'   `description`.
#'
#' @examples
#' SOMMIER_SOURCES_REPRISE
#'
#' @seealso [reprise_source()], [sommier_reprise()]
#' @export
SOMMIER_SOURCES_REPRISE <- data.frame(
  source = c("registre_signe", "base_gestionnaire", "tableur", "temoignage"),
  ndp = c(1, 2, 3, 4),
  description = c(
    paste("Registre ou imprime de la serie A50 tenu et vise, arrete,",
          "deliberation, proces-verbal : une piece datee et signee."),
    paste("Extrait date d'une base tenue par un gestionnaire - ONF,",
          "cooperative, expert - sans visa attache a chaque ligne."),
    paste("Tableur ou fichier bureautique sans visa ni tenue verifiable :",
          "le contenu est plausible, sa tenue n'est pas attestee."),
    paste("Declaration recueillie, note non datee, piece sans auteur",
          "identifiable : ce qui reste quand aucun ecrit ne porte le fait.")
  ),
  stringsAsFactors = FALSE
)

#' Piece dont une reprise est tiree
#'
#' @description
#' Construit et valide le bloc de provenance d'une entree transcrite. Sans
#' lui, une reprise est indiscernable d'une invention : c'est la reference de
#' la piece qui permet a un tiers d'aller voir.
#'
#' @details
#' Le bloc voyage dans le payload de l'entree, sous la cle `reprise`. Il est
#' donc couvert par l'empreinte au meme titre que le volume d'une coupe :
#' rectifier apres coup la piece citee n'est pas plus possible que rectifier
#' le volume.
#'
#' @param source Provenance, l'une de `SOMMIER_SOURCES_REPRISE$source`.
#' @param reference Reference de la piece, assez precise pour qu'on la
#'   retrouve : imprime et exercice, numero de deliberation, intitule et date
#'   de l'extrait.
#' @param date_piece Date de la piece elle-meme, si elle en porte une
#'   (facultatif) - elle ne se confond ni avec la date de l'evenement, ni avec
#'   celle de la transcription.
#' @param detenteur Qui detient l'original (facultatif).
#' @param observations Observations libres (facultatif) : etat de la piece,
#'   lacunes, passages illisibles.
#'
#' @return Une liste nommee, a passer a [sommier_reprise()].
#'
#' @examples
#' reprise_source(
#'   source = "registre_signe",
#'   reference = "Sommier papier, imprime A50E, exercice 1998, folio 12",
#'   date_piece = "1999-01-15",
#'   detenteur = "Commune de Couchey"
#' )
#'
#' @seealso [sommier_reprise()], [SOMMIER_SOURCES_REPRISE]
#' @export
reprise_source <- function(source,
                           reference,
                           date_piece = NULL,
                           detenteur = NULL,
                           observations = NULL) {
  compacter(list(
    source       = valider_choix(source, "source", SOMMIER_SOURCES_REPRISE$source),
    reference    = valider_texte(reference, "reference"),
    date_piece   = if (est_vide(date_piece)) NULL else format_date(date_piece, "date_piece"),
    detenteur    = si_present(detenteur, valider_texte, "detenteur"),
    observations = si_present(observations, valider_texte, "observations")
  ))
}

#' Validation d'un bloc de reprise
#'
#' Revalide un bloc de provenance deja construit - utile a la relecture d'un
#' export, ou les payloads arrivent en JSON sans etre passes par
#' [reprise_source()].
#'
#' @param reprise Liste nommee.
#' @return Le bloc valide, normalise.
#'
#' @examples
#' valider_reprise(list(source = "tableur", reference = "Suivi coupes.xlsx"))
#'
#' @export
valider_reprise <- function(reprise) {
  if (!is.list(reprise) || is.null(names(reprise))) {
    stop("`reprise` doit etre une liste nommee (voir reprise_source()).",
         call. = FALSE)
  }
  connus <- names(formals(reprise_source))
  inconnus <- setdiff(names(reprise), connus)
  if (length(inconnus) > 0L) {
    stop("Champ(s) inconnu(s) dans le bloc `reprise` : ",
         paste(inconnus, collapse = ", "), " ; attendus : ",
         paste(connus, collapse = ", "), ".", call. = FALSE)
  }
  do.call(reprise_source, reprise)
}

#' Construction d'une entree transcrite depuis l'existant
#'
#' @description
#' Prepare une entree qui **transcrit** un fait anterieur au sommier - une
#' coupe de 1998 lue dans le registre papier, un arrete retrouve aux archives
#' de la commune - au lieu de le constater. Comme [sommier_entree()], elle
#' rend une entree non encore chainee ; elle s'ecrit par [sommier_reprendre()].
#'
#' @details
#' Une reprise se distingue d'un constat sur trois points, et ces trois points
#' sont imposes ici plutot que laisses a la discipline de l'appelant :
#'
#' * **`date_saisie` est l'instant reel de la transcription.** Le champ est
#'   pose par la fonction et ne peut pas lui etre dicte : le lui permettre
#'   laisserait antidater une reprise, et une chaine qui peut etre convaincue
#'   d'avoir su plus tot qu'elle n'a su ne vaut rien. La date du fait, elle,
#'   se porte par `date_evenement`, qui remonte aussi loin qu'il le faut.
#' * **Le NDP est strictement superieur a 0.** NDP 0 designe le constat de
#'   terrain ; une recopie n'en est pas un. C'est la regle deja appliquee aux
#'   detections par [sommier_importer_detections()], transposee a une autre
#'   provenance.
#' * **La source est citee.** Sans reference de piece, une reprise ne se
#'   distingue pas d'une invention. Il n'y a donc pas de defaut a `source`.
#'
#' La sequence, elle, n'est pas rejouee : les entrees reprises s'ajoutent a la
#' suite de ce qui est deja ecrit. Le sommier date l'histoire, il ne la
#' reordonne pas - une reprise de trente ans forme un bloc d'entrees contigues
#' dont les dates d'evenement remontent le temps.
#'
#' @param foret_id UUID de la foret.
#' @param registre Numero de registre, parmi [SOMMIER_REGISTRES_OUVERTS].
#' @param date_evenement Date du fait transcrit (`Date` ou `"AAAA-MM-JJ"`).
#' @param auteur Identifiant de qui transcrit - pas de qui a constate a
#'   l'epoque : c'est bien une ecriture d'aujourd'hui.
#' @param payload Liste nommee produite par un constructeur de registre.
#' @param source Bloc de provenance produit par [reprise_source()].
#' @param ug_uuid UUID de l'unite de gestion, ou `NULL`.
#' @param ndp Niveau de precision (entier >= 1). Par defaut, celui que
#'   [SOMMIER_SOURCES_REPRISE] attache a la provenance.
#' @param corrige_id UUID de l'entree que celle-ci rectifie, le cas echeant -
#'   une transcription fautive se rectifie comme le reste, par une entree de
#'   plus.
#' @param id UUID de l'entree ; genere si absent.
#' @param ... Aucun autre argument n'est admis. `date_saisie` en particulier
#'   est refuse, avec un message qui dit pourquoi.
#'
#' @return Un objet de classe `sommier_reprise`, qui herite de
#'   `sommier_entree`.
#'
#' @examples
#' sommier_reprise(
#'   foret_id = "3f2b1c4d-5e6f-4a7b-8c9d-0e1f2a3b4c5d",
#'   registre = 5L,
#'   date_evenement = "1998-03-12",
#'   auteur = "agent-01",
#'   payload = registre5_coupe(
#'     type_entree = "martelage", exercice = 1998,
#'     nature_coupe = "amelioration", volume_m3 = 210
#'   ),
#'   source = reprise_source(
#'     "registre_signe",
#'     "Sommier papier, imprime A50E, exercice 1998, folio 12"
#'   )
#' )
#'
#' @seealso [sommier_reprendre()], [reprise_source()], [sommier_entree()]
#' @export
sommier_reprise <- function(foret_id,
                            registre,
                            date_evenement,
                            auteur,
                            payload,
                            source,
                            ug_uuid = NULL,
                            ndp = NULL,
                            corrige_id = NULL,
                            id = uuid_v4(),
                            ...) {
  refuser_arguments_reprise(...)

  source <- valider_reprise(source)

  # Le zero se refuse a part : dire « ndp doit etre >= 1 » ne dirait pas ce
  # que NDP 0 signifie, et c'est le sens qui est en cause.
  if (!est_vide(ndp) && is.numeric(ndp) && length(ndp) == 1L && ndp == 0) {
    stop("Une reprise ne peut pas porter NDP 0 : ce niveau designe le constat ",
         "de terrain, et transcrire n'est pas constater. La provenance '",
         source$source, "' porte NDP ", ndp_de_source(source$source), ".",
         call. = FALSE)
  }
  ndp <- if (est_vide(ndp)) {
    ndp_de_source(source$source)
  } else {
    valider_entier(ndp, "ndp", min = 1)
  }

  date_evenement <- format_date(date_evenement, "date_evenement")
  aujourd_hui <- format(Sys.Date(), "%Y-%m-%d")
  if (date_evenement > aujourd_hui) {
    stop("`date_evenement` (", date_evenement, ") est dans l'avenir : une ",
         "reprise transcrit ce qui a eu lieu, elle ne l'annonce pas.",
         call. = FALSE)
  }

  if (!is.list(payload) || is.null(names(payload))) {
    stop("`payload` doit etre une liste nommee.", call. = FALSE)
  }
  if (!is.null(payload$reprise)) {
    stop("Le payload porte deja un bloc `reprise` : une entree est transcrite ",
         "d'une piece, pas de deux. Une transcription fautive se rectifie par ",
         "une entree nouvelle portant `corrige_id`.", call. = FALSE)
  }
  payload$reprise <- source

  entree <- sommier_entree(
    foret_id = foret_id,
    registre = registre,
    date_evenement = date_evenement,
    auteur = auteur,
    payload = payload,
    ug_uuid = ug_uuid,
    ndp = ndp,
    corrige_id = corrige_id,
    # L'instant de l'ecriture, et lui seul : c'est la decision centrale de ce
    # constructeur, elle ne passe par aucun argument.
    date_saisie = Sys.time(),
    id = id
  )
  class(entree) <- c("sommier_reprise", class(entree))
  entree
}

#' @export
print.sommier_reprise <- function(x, ...) {
  reprise <- x$payload$reprise
  NextMethod()
  cat("  transcrit : ", reprise$source, " (NDP ", x$ndp, ") - ",
      reprise$reference, "\n", sep = "")
  invisible(x)
}

#' Ecriture d'une reprise dans le sommier
#'
#' @description
#' Ecrit un lot d'entrees transcrites, en une transaction, et rend le
#' compte-rendu de ce qui est entre : combien d'entrees, par registre, sur
#' quelle periode, depuis quelles pieces.
#'
#' @details
#' La fonction n'accepte que des entrees construites par [sommier_reprise()].
#' Ce n'est pas une precaution de typage : une transcription passee par
#' [sommier_entree()] pourrait etre antidatee et se donner pour un constat,
#' et c'est exactement ce que ce lot interdit.
#'
#' L'empreinte reste calculee cote R, entree par entree, y compris pour un lot
#' de plusieurs milliers : la canonisation ne se delegue pas a la base, sans
#' quoi la chaine ne serait plus verifiable hors serveur.
#'
#' @param con Connexion DBI.
#' @param entrees Un objet `sommier_reprise` ou une liste d'objets
#'   `sommier_reprise`, tous de la meme foret.
#'
#' @return Invisiblement, un objet de classe `sommier_compte_rendu_reprise`.
#'
#' @seealso [sommier_reprise()], [sommier_provenance()]
#' @export
sommier_reprendre <- function(con, entrees) {
  if (inherits(entrees, "sommier_reprise")) {
    entrees <- list(entrees)
  }
  if (!is.list(entrees) || length(entrees) == 0L) {
    stop("`entrees` doit etre une liste non vide d'objets `sommier_reprise`.",
         call. = FALSE)
  }
  if (!all(vapply(entrees, inherits, logical(1), "sommier_reprise"))) {
    stop("sommier_reprendre() n'ecrit que des entrees construites par ",
         "sommier_reprise() : une transcription entree par sommier_entree() ",
         "pourrait etre antidatee et passer pour un constat.", call. = FALSE)
  }

  chainees <- sommier_ajouter(con, entrees)
  invisible(compte_rendu_reprise(chainees))
}

# Compte-rendu d'un lot transcrit. Il se calcule sur les entrees telles
# qu'ecrites - donc apres chainage - pour dire aussi ou le bloc se situe dans
# la sequence : c'est ce qui permet de le retrouver plus tard.
compte_rendu_reprise <- function(entrees) {
  champ <- function(f) vapply(entrees, f, character(1))
  registres <- vapply(entrees, function(e) e$registre, numeric(1))
  dates <- champ(function(e) e$date_evenement)
  sources <- champ(function(e) e$payload$reprise$source)
  references <- champ(function(e) e$payload$reprise$reference)
  seqs <- vapply(entrees, function(e) e$seq, numeric(1))

  par_registre <- do.call(rbind, lapply(sort(unique(registres)), function(r) {
    i <- registres == r
    data.frame(
      registre = r,
      nom = SOMMIER_REGISTRES$nom[[r]],
      n = sum(i),
      date_min = min(dates[i]),
      date_max = max(dates[i]),
      stringsAsFactors = FALSE
    )
  }))

  cles <- paste(sources, references, sep = "\r")
  pieces <- do.call(rbind, lapply(unique(cles), function(cle) {
    i <- cles == cle
    data.frame(
      source = sources[i][[1L]],
      reference = references[i][[1L]],
      ndp = entrees[[which(i)[[1L]]]]$ndp,
      n = sum(i),
      stringsAsFactors = FALSE
    )
  }))
  pieces <- pieces[order(pieces$source, pieces$reference), , drop = FALSE]
  rownames(pieces) <- NULL

  structure(
    list(
      foret_id = entrees[[1L]]$foret_id,
      n = length(entrees),
      seq_debut = min(seqs),
      seq_fin = max(seqs),
      date_min = min(dates),
      date_max = max(dates),
      ecrit_le = entrees[[1L]]$date_saisie,
      registres = par_registre,
      pieces = pieces
    ),
    class = "sommier_compte_rendu_reprise"
  )
}

#' @export
print.sommier_compte_rendu_reprise <- function(x, ...) {
  cat("<reprise - ", x$n, " entree(s) transcrite(s)>\n", sep = "")
  cat("  foret     : ", x$foret_id, "\n", sep = "")
  cat("  ecrit le  : ", x$ecrit_le, "\n", sep = "")
  cat("  evenement : ", x$date_min, " a ", x$date_max, "\n", sep = "")
  cat("  sequence  : ", format(x$seq_debut, scientific = FALSE), " a ",
      format(x$seq_fin, scientific = FALSE), "\n", sep = "")
  for (i in seq_len(nrow(x$registres))) {
    cat("  registre ", x$registres$registre[[i]], " - ", x$registres$nom[[i]],
        " : ", x$registres$n[[i]], " entree(s), ",
        x$registres$date_min[[i]], " a ", x$registres$date_max[[i]], "\n",
        sep = "")
  }
  cat("  pieces    : ", nrow(x$pieces), "\n", sep = "")
  for (i in seq_len(nrow(x$pieces))) {
    cat("    ", x$pieces$source[[i]], " (NDP ", x$pieces$ndp[[i]], ") - ",
        x$pieces$reference[[i]], " : ", x$pieces$n[[i]], " entree(s)\n",
        sep = "")
  }
  invisible(x)
}

#' Ce qui a ete constate, ce qui a ete transcrit
#'
#' @description
#' Compte par registre les entrees en vigueur selon leur provenance. C'est la
#' vue qui permet a un document engendre depuis le sommier de dire lesquels de
#' ses chiffres viennent d'une transcription - un tableau qui melerait les deux
#' sans le dire ferait passer la recopie pour de la mesure.
#'
#' @details
#' Le comptage porte sur les entrees en vigueur (`v_entree_courante`) et non
#' sur la chaine entiere : ce sont elles qui alimentent les tableaux, et une
#' transcription rectifiee ne doit pas etre comptee deux fois.
#'
#' @param con Connexion DBI.
#' @param foret_id UUID de la foret.
#' @param debut,fin Bornes sur la date d'evenement (facultatif).
#'
#' @return Un `data.frame` : `registre`, `nom`, `n_constate`, `n_transcrit`,
#'   `n_pieces`, `transcrit_du`, `transcrit_au`.
#'
#' @seealso [sommier_reprendre()], [sommier_gestion_anterieure()]
#' @export
sommier_provenance <- function(con, foret_id, debut = NULL, fin = NULL) {
  foret_id <- valider_uuid(foret_id, "foret_id")
  debut <- if (est_vide(debut)) "0001-01-01" else format_date(debut, "debut")
  fin <- if (est_vide(fin)) "9999-12-31" else format_date(fin, "fin")

  res <- DBI::dbGetQuery(
    con,
    "SELECT e.registre,
            count(*) FILTER (WHERE NOT jsonb_exists(e.payload, 'reprise'))
              AS n_constate,
            count(*) FILTER (WHERE jsonb_exists(e.payload, 'reprise'))
              AS n_transcrit,
            count(DISTINCT e.payload -> 'reprise' ->> 'reference')
              AS n_pieces,
            min(e.date_evenement) FILTER (
              WHERE jsonb_exists(e.payload, 'reprise'))::text AS transcrit_du,
            max(e.date_evenement) FILTER (
              WHERE jsonb_exists(e.payload, 'reprise'))::text AS transcrit_au
       FROM v_entree_courante e
      WHERE e.foret_id = $1
        AND e.date_evenement BETWEEN $2::date AND $3::date
      GROUP BY e.registre
      ORDER BY e.registre",
    params = parametres(list(foret_id, debut, fin))
  )
  # Les comptages remontent en entier 64 bits selon le pilote ; ramenes en
  # numeric, ils se comparent et se mettent en forme partout de la meme facon.
  for (colonne in c("registre", "n_constate", "n_transcrit", "n_pieces")) {
    res[[colonne]] <- as.numeric(res[[colonne]])
  }
  res$nom <- SOMMIER_REGISTRES$nom[as.integer(res$registre)]
  res[, c("registre", "nom", "n_constate", "n_transcrit", "n_pieces",
          "transcrit_du", "transcrit_au")]
}

# NDP attache a une provenance. Le tableau est la reference, pas une constante
# recopiee : une echelle qui vivrait a deux endroits divergerait.
ndp_de_source <- function(source) {
  SOMMIER_SOURCES_REPRISE$ndp[SOMMIER_SOURCES_REPRISE$source == source]
}

# `date_saisie` n'est pas simplement absent de la signature : il est refuse
# avec son motif. Un utilisateur qui l'essaie tient un raisonnement - « je
# veux que le sommier montre l'histoire a sa place » - auquel un « argument
# inconnu » ne repondrait pas.
refuser_arguments_reprise <- function(...) {
  autres <- list(...)
  if (length(autres) == 0L) {
    return(invisible(NULL))
  }
  noms <- names(autres)
  if (is.null(noms)) {
    noms <- rep("", length(autres))
  }
  if ("date_saisie" %in% noms) {
    stop("`date_saisie` ne se dicte pas a une reprise : elle vaut l'instant ",
         "reel de la transcription. Antidater ferait dire a la chaine qu'elle ",
         "savait avant d'avoir su ; la date du fait se porte par ",
         "`date_evenement`.", call. = FALSE)
  }
  stop("sommier_reprise(): argument(s) inconnu(s) : ",
       paste(ifelse(nzchar(noms), noms, "sans nom"), collapse = ", "), ".",
       call. = FALSE)
}
