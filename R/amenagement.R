#' Amenagement : la periode et la possibilite, dans la chaine
#'
#' @description
#' Ecrit l'acte d'un amenagement - l'arrete, en foret publique, ou l'agrement
#' du PSG, en foret privee - avec la periode qu'il couvre et la possibilite
#' qu'il fixe. La balance de possibilite (imprime A50E) se calcule ensuite
#' contre lui : voir [sommier_balance_possibilite()].
#'
#' @details
#' **La possibilite est une ecriture.** Elle entre au registre 1 avec l'acte
#' qui la fixe, et elle est couverte par l'empreinte au meme titre qu'un
#' volume martele. La changer suppose un avenant
#' ([sommier_avenant_possibilite()]), qui s'ajoute a la chaine : l'ancienne
#' valeur reste lisible pour les exercices qu'elle a couverts.
#'
#' **Deux amenagements ne se chevauchent pas.** Un exercice appartient a un
#' seul amenagement, sans quoi il aurait deux possibilites. Une revision
#' anticipee clot d'abord l'ancien par avenant, en avancant sa fin.
#'
#' **Possibilite ou recolte prevue.** Un PSG, ou un amenagement ancien, fixe
#' une possibilite en volume. Les amenagements recents de l'ONF ne le font
#' plus : l'arrete fixe des surfaces par groupe (a regenerer, a ameliorer), et
#' le volume n'apparait qu'au document, comme recolte previsible pilotee en
#' surface terriere - l'arrete du 9 aout 2019 du massif de Lorris-Les Bordes
#' (foret domaniale d'Orleans) n'en porte aucun, son document en prevoit
#' 37 215 m3/an. `nature_volume` le dit, et le rapport ne presente pas une
#' prevision comme une possibilite. Les surfaces que l'arrete fixe se
#' gardent dans `groupes` et `surface_regeneration_ha`.
#'
#' **Le controle de vraisemblance avertit, il ne refuse pas.** Une
#' possibilite ramenee a l'hectare peut etre confrontee a un prelevement de
#' reference - celui que l'IFN observe dans la sylvoecoregion, que nemeton
#' calcule. Au-dela d'un facteur `facteur_vraisemblance`, un avertissement
#' signale une possible faute de frappe (un zero de trop). L'acte s'ecrit
#' quand meme : la possibilite est un acte d'autorite, pas une estimation, et
#' un amenagement de conversion ou de rattrapage s'ecarte legitimement de la
#' moyenne regionale.
#'
#' @param con Connexion DBI.
#' @param foret_id UUID de la foret.
#' @param id Identifiant de l'amenagement, stable, repris par ses avenants
#'   (par exemple `"FD-ORLEANS-2026"`).
#' @param annee_debut,annee_fin Premier et dernier exercice couverts.
#' @param possibilite_m3_an Volume annuel, en m3 : la possibilite fixee par
#'   l'acte, ou la recolte prevue au document (voir `nature_volume`).
#' @param autorite L'un de [SOMMIER_AUTORITES].
#' @param nom_qualite Nom et qualite du signataire de l'acte.
#' @param date_acte Date de l'acte.
#' @param auteur Compte qui ecrit.
#' @param type_validation `"arrete"` (foret publique) ou `"agrement"` (PSG).
#' @param reference Reference de l'arrete ou de l'agrement.
#' @param libelle Libelle lisible (facultatif).
#' @param ventilation Possibilite ventilee par nature de coupe, en m3/an,
#'   vecteur nomme - par exemple `c(regeneration = 1200, amelioration = 3400)`.
#'   Sa somme doit egaler `possibilite_m3_an` (facultatif).
#' @param surface_ha Surface a laquelle la possibilite s'applique (facultatif).
#' @param serie Serie concernee, si la foret en compte plusieurs (facultatif).
#' @param tolerance_ans Ecart admis a la balance cumulee, en annees de
#'   possibilite (facultatif) : quatre ans pour un PSG.
#' @param source Page ou tableau du document ou la possibilite est fixee
#'   (facultatif).
#' @param nature_volume `"possibilite"` (volume fixe par l'acte) ou
#'   `"recolte_prevue"` (recolte previsible du document d'amenagement).
#' @param groupes Surfaces par groupe d'amenagement, en ha, vecteur nomme -
#'   par exemple `c(regeneration = 2648.31, amelioration = 3016.81)`
#'   (facultatif).
#' @param surface_regeneration_ha Surface a ouvrir en regeneration sur la
#'   periode, en ha (facultatif).
#' @param reference_m3_ha_an Prelevement de reference a l'hectare, pour le
#'   controle de vraisemblance (facultatif).
#' @param facteur_vraisemblance Ecart, en facteur, au-dela duquel le controle
#'   avertit.
#'
#' @return Invisiblement, l'entree chainee.
#'
#' @seealso [sommier_avenant_possibilite()], [sommier_balance_possibilite()],
#'   [sommier_reprendre_exercices()]
#'
#' @examples
#' # sommier_amenagement(con, foret, "FD-ORLEANS-2026", 2026, 2045,
#' #   possibilite_m3_an = 2400, autorite = "ministre",
#' #   nom_qualite = "Ministre de l'agriculture", date_acte = "2026-02-01",
#' #   auteur = "gestionnaire", reference = "Arrete du 1er fevrier 2026")
#'
#' @export
sommier_amenagement <- function(con, foret_id, id, annee_debut, annee_fin,
                                possibilite_m3_an, autorite, nom_qualite,
                                date_acte, auteur,
                                type_validation = "arrete",
                                reference = NULL, libelle = NULL,
                                ventilation = NULL, surface_ha = NULL,
                                serie = NULL, tolerance_ans = NULL,
                                source = NULL,
                                nature_volume = "possibilite",
                                groupes = NULL,
                                surface_regeneration_ha = NULL,
                                reference_m3_ha_an = NULL,
                                facteur_vraisemblance = 3) {
  foret_id <- valider_uuid(foret_id, "foret_id")
  type_validation <- valider_choix(type_validation, "type_validation",
                                   c("arrete", "agrement"))
  bloc <- valider_amenagement(compacter(list(
    id = id, libelle = libelle, annee_debut = annee_debut,
    annee_fin = annee_fin, possibilite_m3_an = possibilite_m3_an,
    ventilation = ventilation, surface_ha = surface_ha, serie = serie,
    tolerance_ans = tolerance_ans, source = source,
    nature_volume = nature_volume, groupes = groupes,
    surface_regeneration_ha = surface_regeneration_ha
  )), type_validation)

  existants <- lire_amenagements(con, foret_id)
  if (bloc$id %in% existants$amenagement_id) {
    stop("L'amenagement `", bloc$id, "` existe deja dans ce sommier. Pour ",
         "changer sa possibilite ou sa fin, ecrire un avenant ",
         "(sommier_avenant_possibilite()).", call. = FALSE)
  }
  controler_chevauchement(existants, bloc$annee_debut, bloc$annee_fin)
  controler_vraisemblance(bloc, reference_m3_ha_an, facteur_vraisemblance)

  invisible(sommier_ajouter(con, sommier_entree(
    foret_id = foret_id, registre = 1L, date_evenement = date_acte,
    auteur = auteur,
    payload = registre1_validation(
      type_validation = type_validation, autorite = autorite,
      nom_qualite = nom_qualite, reference = reference,
      portee = if (type_validation == "agrement") "psg" else "amenagement",
      amenagement = bloc
    )
  ))[[1L]])
}

#' Avenant a un amenagement : la possibilite ou la fin changent
#'
#' @description
#' Ecrit l'avenant qui change, a partir d'un exercice, la possibilite d'un
#' amenagement, sa fin, ou les deux.
#'
#' @details
#' Les exercices anterieurs a `a_partir_de` gardent la possibilite qu'ils
#' avaient : un avenant ne recrit pas le passe, il dit ce qui vaut desormais.
#' La balance cite, pour chaque exercice, l'acte dont vient sa possibilite.
#'
#' Avancer la fin clot l'amenagement - c'est ce qui permet une revision
#' anticipee. La reculer n'est admis que si aucun autre amenagement ne couvre
#' deja les exercices gagnes.
#'
#' @param con Connexion DBI.
#' @param foret_id UUID de la foret.
#' @param amenagement_id Identifiant de l'amenagement modifie.
#' @param a_partir_de Premier exercice auquel l'avenant s'applique.
#' @param autorite,nom_qualite,date_acte,auteur,reference Comme pour
#'   [sommier_amenagement()].
#' @param possibilite_m3_an Nouvelle possibilite annuelle (facultatif).
#' @param annee_fin Nouvelle fin de l'amenagement (facultatif).
#' @param ventilation Nouvelle ventilation (facultatif).
#' @param source Page ou tableau de l'avenant (facultatif).
#'
#' @return Invisiblement, l'entree chainee.
#'
#' @seealso [sommier_amenagement()]
#'
#' @export
sommier_avenant_possibilite <- function(con, foret_id, amenagement_id,
                                        a_partir_de, autorite, nom_qualite,
                                        date_acte, auteur, reference = NULL,
                                        possibilite_m3_an = NULL,
                                        annee_fin = NULL, ventilation = NULL,
                                        source = NULL) {
  foret_id <- valider_uuid(foret_id, "foret_id")
  bloc <- valider_amenagement(compacter(list(
    id = amenagement_id, a_partir_de = a_partir_de,
    possibilite_m3_an = possibilite_m3_an, annee_fin = annee_fin,
    ventilation = ventilation, source = source
  )), "avenant")

  existants <- lire_amenagements(con, foret_id)
  cible <- existants[existants$amenagement_id == bloc$id, , drop = FALSE]
  if (nrow(cible) == 0L) {
    stop("Amenagement inconnu dans ce sommier : `", bloc$id, "`.",
         call. = FALSE)
  }
  if (bloc$a_partir_de < cible$annee_debut ||
      bloc$a_partir_de > cible$annee_fin + 1L) {
    stop("L'avenant s'applique a partir de ", bloc$a_partir_de, ", hors de ",
         "la periode de `", bloc$id, "` (", cible$annee_debut, "-",
         cible$annee_fin, ").", call. = FALSE)
  }
  if (!is.null(bloc$annee_fin)) {
    if (bloc$annee_fin < bloc$a_partir_de - 1L) {
      stop("La nouvelle fin (", bloc$annee_fin, ") precede l'exercice a ",
           "partir duquel l'avenant s'applique (", bloc$a_partir_de, ").",
           call. = FALSE)
    }
    autres <- existants[existants$amenagement_id != bloc$id, , drop = FALSE]
    controler_chevauchement(autres, cible$annee_debut, bloc$annee_fin)
  }

  invisible(sommier_ajouter(con, sommier_entree(
    foret_id = foret_id, registre = 1L, date_evenement = date_acte,
    auteur = auteur,
    payload = registre1_validation(
      type_validation = "avenant", autorite = autorite,
      nom_qualite = nom_qualite, reference = reference,
      portee = "amenagement", amenagement = bloc
    )
  ))[[1L]])
}

#' Reprise de la table `exercice` en amenagement(s)
#'
#' @description
#' Transcrit la possibilite rangee dans la table `exercice` - hors de la
#' chaine, et reecrivable sans trace - en un ou plusieurs amenagements
#' repris. Les annees consecutives de meme possibilite forment un
#' amenagement.
#'
#' @details
#' La transcription dit qu'elle en est une : chaque amenagement porte un bloc
#' `reprise` (source `base_gestionnaire`, NDP 2), et rien n'est efface de la
#' table. Apres reprise, [exercice_definir()] refuse d'ecrire : une
#' possibilite ne se modifie plus que par avenant.
#'
#' @param con Connexion DBI.
#' @param foret_id UUID de la foret.
#' @param auteur Compte qui transcrit.
#' @param autorite,nom_qualite Autorite et signataire de l'acte d'origine,
#'   s'ils sont connus.
#' @param reference Reference de l'acte d'origine, si elle est connue.
#'
#' @return Invisiblement, le compte rendu de [sommier_reprendre()].
#'
#' @export
sommier_reprendre_exercices <- function(con, foret_id, auteur,
                                        autorite = "onf",
                                        nom_qualite = "Non renseigne",
                                        reference = NULL) {
  foret_id <- valider_uuid(foret_id, "foret_id")
  lignes <- DBI::dbGetQuery(
    con,
    "SELECT annee, possibilite_m3_an FROM exercice
      WHERE foret_id = $1 AND possibilite_m3_an IS NOT NULL ORDER BY annee",
    params = list(foret_id)
  )
  if (nrow(lignes) == 0L) {
    stop("La table `exercice` ne porte aucune possibilite pour cette foret : ",
         "rien a reprendre.", call. = FALSE)
  }
  if (nrow(lire_amenagements(con, foret_id)) > 0L) {
    stop("Ce sommier porte deja un amenagement : la reprise de la table ",
         "`exercice` ne peut que venir en premier.", call. = FALSE)
  }
  lignes$annee <- as.integer(lignes$annee)
  lignes$possibilite_m3_an <- as.numeric(lignes$possibilite_m3_an)
  rupture <- c(TRUE, diff(lignes$annee) != 1L |
                 diff(lignes$possibilite_m3_an) != 0)
  groupes <- split(lignes, cumsum(rupture))

  entrees <- lapply(groupes, function(g) {
    debut <- min(g$annee)
    fin <- max(g$annee)
    sommier_reprise(
      foret_id = foret_id, registre = 1L,
      date_evenement = sprintf("%d-01-01", debut), auteur = auteur,
      payload = registre1_validation(
        type_validation = "arrete", autorite = autorite,
        nom_qualite = nom_qualite, reference = reference,
        portee = "amenagement",
        amenagement = list(
          id = sprintf("REPRISE-EXERCICES-%d-%d", debut, fin),
          libelle = "Possibilite reprise de la table exercice",
          annee_debut = debut, annee_fin = fin,
          possibilite_m3_an = g$possibilite_m3_an[[1L]]
        )
      ),
      source = reprise_source(
        source = "base_gestionnaire",
        reference = paste0("Table `exercice` de la base sommieR, exercices ",
                           debut, " a ", fin, ", relevee le ",
                           format(Sys.Date())),
        observations = paste(
          "Possibilite tenue hors de la chaine avant sommieR 0.19.0 :",
          "rien n'attestait qu'elle n'avait pas ete modifiee."
        )
      )
    )
  })
  invisible(sommier_reprendre(con, unname(entrees)))
}

# ---------------------------------------------------------------------------

# Le bloc `amenagement` d'un acte du registre 1. L'arrete et l'agrement
# fixent un amenagement entier ; l'avenant en modifie un, a partir d'un
# exercice.
valider_amenagement <- function(amenagement, type_validation) {
  if (est_vide(amenagement)) {
    return(NULL)
  }
  if (!type_validation %in% c("arrete", "agrement", "avenant")) {
    stop("Seuls un arrete, un agrement ou un avenant portent un ",
         "amenagement.", call. = FALSE)
  }
  if (!is.list(amenagement) || is.null(names(amenagement))) {
    stop("`amenagement` doit etre une liste nommee.", call. = FALSE)
  }
  avenant <- identical(type_validation, "avenant")
  admis <- if (avenant) {
    c("id", "a_partir_de", "possibilite_m3_an", "annee_fin", "ventilation",
      "source")
  } else {
    c("id", "libelle", "annee_debut", "annee_fin", "possibilite_m3_an",
      "ventilation", "surface_ha", "serie", "tolerance_ans", "source",
      "nature_volume", "groupes", "surface_regeneration_ha")
  }
  inconnus <- setdiff(names(amenagement), admis)
  if (length(inconnus) > 0L) {
    stop("`amenagement` : champ(s) inconnu(s) : ",
         paste(inconnus, collapse = ", "), ".", call. = FALSE)
  }

  a <- amenagement
  annee <- function(x, nom) valider_entier(x, nom, min = 1500, max = 2999)
  bloc <- list(id = valider_texte(a$id, "amenagement$id"))
  if (avenant) {
    bloc$a_partir_de <- annee(a$a_partir_de, "amenagement$a_partir_de")
    if (est_vide(a$possibilite_m3_an) && est_vide(a$annee_fin)) {
      stop("Un avenant change la possibilite, la fin, ou les deux : ",
           "`possibilite_m3_an` et `annee_fin` ne peuvent manquer ensemble.",
           call. = FALSE)
    }
  } else {
    bloc$libelle <- si_present(a$libelle, valider_texte, "amenagement$libelle")
    bloc$annee_debut <- annee(a$annee_debut, "amenagement$annee_debut")
    bloc$annee_fin <- annee(a$annee_fin, "amenagement$annee_fin")
    if (bloc$annee_fin < bloc$annee_debut) {
      stop("L'amenagement finit (", bloc$annee_fin, ") avant de commencer (",
           bloc$annee_debut, ").", call. = FALSE)
    }
    if (est_vide(a$possibilite_m3_an)) {
      stop("`amenagement$possibilite_m3_an` est obligatoire : c'est ce que ",
           "la balance confronte aux martelages.", call. = FALSE)
    }
  }
  if (avenant) {
    bloc$annee_fin <- si_present(a$annee_fin, annee, "amenagement$annee_fin")
  }
  bloc$possibilite_m3_an <- si_present(a$possibilite_m3_an, valider_nombre,
                                       "amenagement$possibilite_m3_an",
                                       min = 0)
  bloc$ventilation <- valider_ventilation(a$ventilation, bloc$possibilite_m3_an)
  if (!avenant) {
    bloc$surface_ha <- si_present(a$surface_ha, valider_nombre,
                                  "amenagement$surface_ha", min = 0)
    bloc$serie <- si_present(a$serie, valider_texte, "amenagement$serie")
    bloc$tolerance_ans <- si_present(a$tolerance_ans, valider_entier,
                                     "amenagement$tolerance_ans", min = 0)
    bloc$nature_volume <- valider_choix(a$nature_volume %||% "possibilite",
                                        "amenagement$nature_volume",
                                        SOMMIER_NATURES_VOLUME)
    bloc$groupes <- valider_surfaces_groupes(a$groupes)
    bloc$surface_regeneration_ha <- si_present(
      a$surface_regeneration_ha, valider_nombre,
      "amenagement$surface_regeneration_ha", min = 0
    )
  }
  bloc$source <- si_present(a$source, valider_texte, "amenagement$source")
  compacter(bloc)
}

#' Natures du volume d'un amenagement
#'
#' @description
#' * `possibilite` : volume annuel fixe par l'acte - un PSG, un amenagement
#'   ancien ;
#' * `recolte_prevue` : recolte previsible du document d'amenagement, quand
#'   l'arrete ne fixe que des surfaces et que la recolte se pilote en surface
#'   terriere.
#'
#' @export
SOMMIER_NATURES_VOLUME <- c("possibilite", "recolte_prevue")

valider_surfaces_groupes <- function(groupes) {
  if (est_vide(groupes)) {
    return(NULL)
  }
  groupes <- unlist(groupes)
  if (is.null(names(groupes)) || any(!nzchar(names(groupes)))) {
    stop("`groupes` doit etre nomme par groupe d'amenagement.", call. = FALSE)
  }
  as.list(vapply(names(groupes), function(n) {
    valider_nombre(groupes[[n]], paste0("groupes$", n), min = 0)
  }, numeric(1)))
}

# Une ventilation par nature de coupe totalise la possibilite, a un demi
# metre cube pres : une ventilation qui ne totalise pas est une erreur de
# saisie, comme la repartition d'un cout au registre 2.
valider_ventilation <- function(ventilation, total) {
  if (est_vide(ventilation)) {
    return(NULL)
  }
  ventilation <- unlist(ventilation)
  if (is.null(names(ventilation)) || any(!nzchar(names(ventilation)))) {
    stop("`ventilation` doit etre nommee par nature de coupe.", call. = FALSE)
  }
  valeurs <- vapply(names(ventilation), function(n) {
    valider_nombre(ventilation[[n]], paste0("ventilation$", n), min = 0)
  }, numeric(1))
  if (is.null(total)) {
    stop("Une ventilation accompagne une possibilite : ",
         "`possibilite_m3_an` manque.", call. = FALSE)
  }
  if (abs(sum(valeurs) - total) > 0.5) {
    stop("La ventilation ne totalise pas la possibilite : ",
         paste(names(valeurs), valeurs, sep = " ", collapse = " + "),
         " = ", sum(valeurs), ", attendu ", total, ".", call. = FALSE)
  }
  as.list(valeurs)
}

lire_amenagements <- function(con, foret_id) {
  res <- DBI::dbGetQuery(
    con,
    "SELECT amenagement_id, libelle, annee_debut, annee_fin
       FROM v_amenagement WHERE foret_id = $1 ORDER BY annee_debut",
    params = list(foret_id)
  )
  res$annee_debut <- as.integer(res$annee_debut)
  res$annee_fin <- as.integer(res$annee_fin)
  res
}

controler_chevauchement <- function(existants, debut, fin) {
  if (nrow(existants) == 0L) {
    return(invisible(NULL))
  }
  recouvre <- existants$annee_debut <= fin & existants$annee_fin >= debut
  if (any(recouvre)) {
    a <- existants[which(recouvre)[[1L]], ]
    stop("La periode ", debut, "-", fin, " recouvre l'amenagement `",
         a$amenagement_id, "` (", a$annee_debut, "-", a$annee_fin, ") : un ",
         "exercice n'a qu'une possibilite. Clore d'abord l'amenagement en ",
         "vigueur par avenant.", call. = FALSE)
  }
  invisible(NULL)
}

controler_vraisemblance <- function(bloc, reference_m3_ha_an, facteur) {
  if (est_vide(reference_m3_ha_an) || est_vide(bloc$surface_ha) ||
      bloc$surface_ha <= 0) {
    return(invisible(NULL))
  }
  reference <- valider_nombre(reference_m3_ha_an, "reference_m3_ha_an", min = 0)
  facteur <- valider_nombre(facteur, "facteur_vraisemblance", min = 1)
  a_l_hectare <- bloc$possibilite_m3_an / bloc$surface_ha
  if (reference > 0 && (a_l_hectare > facteur * reference ||
                        a_l_hectare < reference / facteur)) {
    warning(sprintf(paste0(
      "Possibilite de %.2f m3/ha/an, a plus d'un facteur %g du prelevement ",
      "de reference (%.2f m3/ha/an). Verifier la saisie - un zero de trop ? ",
      "L'acte est ecrit : c'est un avertissement, pas un refus."),
      a_l_hectare, facteur, reference), call. = FALSE)
  }
  invisible(NULL)
}
