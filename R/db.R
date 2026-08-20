#' Deploiement du schema du sommier
#'
#' Execute `001_schema.sql` puis `002_vues.sql`. Les deux fichiers sont
#' idempotents : les rejouer sur une base deja initialisee ne detruit ni
#' n'altere de donnee.
#'
#' @param con Connexion DBI vers une base PostgreSQL/PostGIS.
#' @param vues Deployer aussi les vues de consultation (defaut `TRUE`).
#' @return Invisiblement, le vecteur des fichiers executes.
#'
#' @export
sommier_init_schema <- function(con, vues = TRUE) {
  # L'ordre compte : 003 ajoute une colonne a une table creee par 001, et
  # 002 comme 003 declarent des vues qui s'appuient dessus.
  fichiers <- c("001_schema.sql", "003_geometrie.sql",
                if (isTRUE(vues)) "002_vues.sql")
  for (f in fichiers) {
    chemin <- system.file("sql", f, package = "sommieR")
    if (chemin == "") {
      stop("Fichier SQL introuvable dans le package : ", f, call. = FALSE)
    }
    # Une instruction a la fois : les pilotes passant par le protocole etendu
    # refusent plusieurs commandes en un seul envoi (voir decouper_sql()).
    for (instruction in decouper_sql(readLines(chemin, warn = FALSE, encoding = "UTF-8"))) {
      DBI::dbExecute(con, instruction)
    }
  }
  invisible(fichiers)
}

#' Revocation des droits de mutation sur le registre
#'
#' @description
#' Complement indispensable aux declencheurs d'immutabilite : le brief
#' (section 6.2) revoque `UPDATE` et `DELETE` a l'utilisateur applicatif.
#' Le declencheur protege du bogue, la revocation protege du role.
#'
#' Le proprietaire de la table et les superutilisateurs ne sont pas concernes
#' par une revocation - ils restent bloques par le declencheur, mais peuvent
#' le desactiver. Faire tourner l'application sous un role distinct du
#' proprietaire des tables n'est donc pas un detail de deploiement.
#'
#' @param con Connexion DBI.
#' @param role Nom du role applicatif (defaut `"nemeton_app"`).
#' @return Invisiblement `TRUE`.
#'
#' @export
sommier_revoquer_mutations <- function(con, role = "nemeton_app") {
  role <- valider_texte(role, "role")
  for (table in c("entree_sommier", "visa", "ancrage")) {
    DBI::dbExecute(con, sprintf(
      "REVOKE UPDATE, DELETE, TRUNCATE ON %s FROM %s",
      DBI::dbQuoteIdentifier(con, table),
      DBI::dbQuoteIdentifier(con, role)
    ))
  }
  invisible(TRUE)
}

#' Creation d'une foret
#'
#' @param con Connexion DBI.
#' @param nom Nom de la foret.
#' @param regime L'un de [SOMMIER_REGIMES].
#' @param proprietaire Proprietaire (facultatif).
#' @param date_application_regime_forestier Date d'application du regime
#'   forestier - sans objet en foret privee.
#' @param surface_ha Surface en hectares (facultatif).
#' @param id UUID a affecter ; genere si absent.
#' @return L'UUID de la foret creee.
#'
#' @export
foret_creer <- function(con, nom, regime,
                        proprietaire = NULL,
                        date_application_regime_forestier = NULL,
                        surface_ha = NULL,
                        id = uuid_v4()) {
  id <- valider_uuid(id, "id")
  regime <- valider_choix(regime, "regime", SOMMIER_REGIMES)
  if (regime == "privee" && !est_vide(date_application_regime_forestier)) {
    stop("Le regime forestier ne s'applique pas en foret privee : ",
         "`date_application_regime_forestier` doit rester NULL.", call. = FALSE)
  }
  DBI::dbExecute(
    con,
    "INSERT INTO foret (id, nom, regime, proprietaire,
                        date_application_regime_forestier, surface_ha)
     VALUES ($1, $2, $3, NULLIF($4, ''), NULLIF($5, '')::date,
             NULLIF($6, '')::numeric)",
    params = list(
      id, valider_texte(nom, "nom"), regime,
      texte_ou_vide(proprietaire),
      if (est_vide(date_application_regime_forestier)) ""
      else format_date(date_application_regime_forestier, "date_application_regime_forestier"),
      if (est_vide(surface_ha)) ""
      else as.character(valider_nombre(surface_ha, "surface_ha", min = 0))
    )
  )
  id
}

#' Creation d'une unite de gestion
#'
#' L'UUID produit est stable a vie : il ne doit jamais etre reattribue, meme
#' apres cloture de l'unite. Le `numero_affichage`, lui, peut changer a chaque
#' revision d'amenagement.
#'
#' @param con Connexion DBI.
#' @param foret_id UUID de la foret.
#' @param numero_affichage Numero de parcelle affiche.
#' @param date_debut Date d'entree en vigueur.
#' @param serie_id UUID de la serie (facultatif).
#' @param parent_uuid UUID de l'unite dont celle-ci procede (facultatif).
#' @param uuid UUID a affecter ; genere si absent.
#' @return L'UUID de l'unite creee.
#'
#' @export
ug_creer <- function(con, foret_id, numero_affichage, date_debut,
                     serie_id = NULL, parent_uuid = NULL, uuid = uuid_v4()) {
  uuid <- valider_uuid(uuid, "uuid")
  DBI::dbExecute(
    con,
    "INSERT INTO ug (uuid, foret_id, serie_id, numero_affichage,
                     date_debut, parent_uuid)
     VALUES ($1, $2, NULLIF($3, '')::uuid, $4, $5::date,
             NULLIF($6, '')::uuid)",
    params = list(
      uuid,
      valider_uuid(foret_id, "foret_id"),
      if (est_vide(serie_id)) "" else valider_uuid(serie_id, "serie_id"),
      valider_texte(numero_affichage, "numero_affichage"),
      format_date(date_debut, "date_debut"),
      if (est_vide(parent_uuid)) "" else valider_uuid(parent_uuid, "parent_uuid")
    )
  )
  uuid
}

#' Scission d'une unite de gestion
#'
#' Clot l'unite d'origine et cree les unites issues du decoupage, en
#' enregistrant la filiation. L'unite d'origine n'est jamais supprimee : les
#' entrees de sommier qui la referencent restent lisibles, ce qui est tout
#' l'interet d'un identifiant stable.
#'
#' @param con Connexion DBI.
#' @param ug_uuid UUID de l'unite a scinder.
#' @param enfants `data.frame` ou liste de listes a colonnes
#'   `numero_affichage` et, facultativement, `serie_id`.
#' @param date_effet Date d'effet de la scission.
#' @return Le vecteur des UUID crees.
#'
#' @export
ug_scinder <- function(con, ug_uuid, enfants, date_effet) {
  ug_uuid <- valider_uuid(ug_uuid, "ug_uuid")
  date_effet <- format_date(date_effet, "date_effet")
  if (is.data.frame(enfants)) {
    enfants <- split(enfants, seq_len(nrow(enfants)))
  }
  if (length(enfants) < 2L) {
    stop("Une scission produit au moins deux unites ; ", length(enfants),
         " fournie(s).", call. = FALSE)
  }
  parent <- ug_lire(con, ug_uuid)
  if (nrow(parent) == 0L) {
    stop("Unite de gestion inconnue : ", ug_uuid, ".", call. = FALSE)
  }

  transaction(con, {
    cloturer_ug(con, ug_uuid, date_effet)
    vapply(enfants, function(enfant) {
      nouveau <- ug_creer(
        con,
        foret_id = parent$foret_id[[1L]],
        numero_affichage = enfant$numero_affichage,
        date_debut = date_effet,
        serie_id = enfant$serie_id %||% parent$serie_id[[1L]],
        parent_uuid = ug_uuid
      )
      lier_filiation(con, nouveau, ug_uuid, "scission", date_effet)
      nouveau
    }, character(1))
  })
}

#' Fusion d'unites de gestion
#'
#' Clot les unites d'origine et cree l'unite resultante. La filiation a
#' plusieurs parents n'etant pas representable par la colonne `parent_uuid`,
#' elle est portee par la table `ug_filiation`.
#'
#' @param con Connexion DBI.
#' @param ug_uuids UUID des unites a fusionner (au moins deux).
#' @param numero_affichage Numero de l'unite resultante.
#' @param date_effet Date d'effet de la fusion.
#' @param serie_id Serie de l'unite resultante (facultatif : celle de la
#'   premiere unite fusionnee par defaut).
#' @return L'UUID de l'unite creee.
#'
#' @export
ug_fusionner <- function(con, ug_uuids, numero_affichage, date_effet,
                         serie_id = NULL) {
  # `USE.NAMES = FALSE` : sur un vecteur de caracteres, vapply nommerait le
  # resultat par ses propres valeurs, et la liste de parametres arriverait
  # nommee au pilote.
  ug_uuids <- vapply(ug_uuids, valider_uuid, character(1), nom = "ug_uuids",
                     USE.NAMES = FALSE)
  if (length(unique(ug_uuids)) < 2L) {
    stop("Une fusion porte sur au moins deux unites distinctes.", call. = FALSE)
  }
  date_effet <- format_date(date_effet, "date_effet")
  parents <- ug_lire(con, ug_uuids)
  if (nrow(parents) != length(ug_uuids)) {
    stop("Unite(s) de gestion inconnue(s) parmi : ",
         paste(ug_uuids, collapse = ", "), ".", call. = FALSE)
  }
  if (length(unique(parents$foret_id)) > 1L) {
    stop("Les unites fusionnees doivent appartenir a la meme foret.",
         call. = FALSE)
  }

  transaction(con, {
    for (u in ug_uuids) cloturer_ug(con, u, date_effet)
    nouveau <- ug_creer(
      con,
      foret_id = parents$foret_id[[1L]],
      numero_affichage = numero_affichage,
      date_debut = date_effet,
      serie_id = serie_id %||% parents$serie_id[[1L]]
    )
    for (u in ug_uuids) lier_filiation(con, nouveau, u, "fusion", date_effet)
    nouveau
  })
}

#' Lecture d'unites de gestion
#'
#' @param con Connexion DBI.
#' @param ug_uuid UUID a lire ; toutes les unites de `foret_id` si absent.
#' @param foret_id UUID de la foret.
#' @param actives_seulement Ne rendre que les unites non cloturees.
#' @return Un `data.frame`.
#'
#' @export
ug_lire <- function(con, ug_uuid = NULL, foret_id = NULL,
                    actives_seulement = FALSE) {
  conditions <- character(0)
  params <- list()
  if (!est_vide(ug_uuid)) {
    uuids <- vapply(ug_uuid, valider_uuid, character(1), nom = "ug_uuid",
                    USE.NAMES = FALSE)
    conditions <- c(conditions, sprintf(
      "uuid IN (%s)",
      paste0("$", seq_along(uuids) + length(params), collapse = ", ")
    ))
    params <- c(params, as.list(uuids))
  }
  if (!est_vide(foret_id)) {
    conditions <- c(conditions, sprintf("foret_id = $%d", length(params) + 1L))
    params <- c(params, list(valider_uuid(foret_id, "foret_id")))
  }
  if (isTRUE(actives_seulement)) {
    conditions <- c(conditions, "date_fin IS NULL")
  }
  requete <- paste0(
    "SELECT uuid, foret_id, serie_id, numero_affichage, date_debut,
            date_fin, parent_uuid FROM ug",
    if (length(conditions) > 0L) paste0(" WHERE ", paste(conditions, collapse = " AND ")) else "",
    " ORDER BY numero_affichage"
  )
  if (length(params) == 0L) {
    DBI::dbGetQuery(con, requete)
  } else {
    DBI::dbGetQuery(con, requete, params = parametres(params))
  }
}

cloturer_ug <- function(con, ug_uuid, date_fin) {
  n <- DBI::dbExecute(
    con,
    "UPDATE ug SET date_fin = $1::date WHERE uuid = $2 AND date_fin IS NULL",
    params = list(date_fin, ug_uuid)
  )
  if (n == 0L) {
    stop("Unite de gestion ", ug_uuid, " inconnue ou deja cloturee.",
         call. = FALSE)
  }
  invisible(n)
}

lier_filiation <- function(con, enfant, parent, type, date_effet) {
  DBI::dbExecute(
    con,
    "INSERT INTO ug_filiation (enfant_uuid, parent_uuid, type_filiation, date_effet)
     VALUES ($1, $2, $3, $4::date)",
    params = list(enfant, parent, type, date_effet)
  )
}

# Les pilotes ne s'accordent pas sur la traduction de NA en NULL : RPostgres
# la fait, RPostgreSQL envoie la chaine "NA". On passe donc la chaine vide et
# on la retraduit en NULL cote SQL avec NULLIF, ce qui est sans ambiguite pour
# un UUID, une date ou un nombre, et sans consequence pour un texte dont la
# valeur vide n'aurait de toute facon pas de sens.
texte_ou_vide <- function(x) if (est_vide(x)) "" else as.character(x)

# Transactions reentrantes.
#
# `DBI::dbWithTransaction` ne s'imbrique pas : un BEGIN dans un BEGIN avertit,
# et surtout le COMMIT interne valide la transaction externe avant l'heure.
# `sommier_viser()` ecrit l'acte de registre 1 par `sommier_ajouter()` puis
# inscrit le visa : sans reentrance, un echec de l'insertion du visa laisserait
# l'acte deja valide en base. On tient donc une profondeur par connexion, et
# les niveaux imbriques passent par des points de reprise.
.pile_transactions <- new.env(parent = emptyenv())

profondeur_transaction <- function(con) {
  entrees <- .pile_transactions$entrees
  if (is.null(entrees)) {
    return(0L)
  }
  for (entree in entrees) {
    if (identical(entree$con, con)) {
      return(entree$profondeur)
    }
  }
  0L
}

regler_profondeur <- function(con, profondeur) {
  entrees <- .pile_transactions$entrees %||% list()
  garde <- list()
  for (entree in entrees) {
    if (!identical(entree$con, con)) {
      garde[[length(garde) + 1L]] <- entree
    }
  }
  if (profondeur > 0L) {
    garde[[length(garde) + 1L]] <- list(con = con, profondeur = profondeur)
  }
  .pile_transactions$entrees <- garde
  invisible(profondeur)
}

nom_point_reprise <- function(profondeur) paste0("sommier_sp_", profondeur)

transaction <- function(con, code) {
  profondeur <- profondeur_transaction(con)
  imbriquee <- profondeur > 0L

  if (imbriquee) {
    DBI::dbExecute(con, paste0("SAVEPOINT ", nom_point_reprise(profondeur)))
  } else {
    DBI::dbBegin(con)
  }
  regler_profondeur(con, profondeur + 1L)

  succes <- FALSE
  on.exit({
    regler_profondeur(con, profondeur)
    if (!succes) {
      if (imbriquee) {
        try(DBI::dbExecute(con, paste0("ROLLBACK TO SAVEPOINT ",
                                       nom_point_reprise(profondeur))),
            silent = TRUE)
      } else {
        try(DBI::dbRollback(con), silent = TRUE)
      }
    }
  }, add = TRUE)

  resultat <- force(code)
  succes <- TRUE

  if (imbriquee) {
    DBI::dbExecute(con, paste0("RELEASE SAVEPOINT ", nom_point_reprise(profondeur)))
  } else {
    DBI::dbCommit(con)
  }
  resultat
}

# Les pilotes ne s'accordent pas sur les listes de parametres nommees :
# RPostgres les refuse (« `params` must not be named »), RPostgreSQL les
# tolere. Un `vapply` sur un vecteur de caracteres suffit a en produire une
# sans qu'on le veuille. On les depouille donc systematiquement, plutot que
# de compter sur chaque site d'appel.
parametres <- function(params) {
  unname(as.list(params))
}
