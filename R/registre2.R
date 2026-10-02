#' Types d'entree du registre 2 (foncier et limites)
#'
#' @description
#' * `delimitation` et `bornage` : operations de limite, avec leurs elements
#'   de calcul et leur repartition (imprime A40).
#' * `application_regime` et `distraction_regime` : entree ou sortie du regime
#'   forestier, sans objet en foret privee.
#' * `acquisition` et `cession` : mouvements de propriete.
#' * `servitude` : servitude constituee ou subie.
#' * `reconnaissance_limite` : constat, sur le terrain, de l'etat d'un element
#'   de limite - une borne, un mur, un fosse -, photo a l'appui (voir
#'   [sommier_importer_qfield()]).
#'
#' @export
SOMMIER_TYPES_FONCIER <- c(
  "delimitation", "bornage", "application_regime", "distraction_regime",
  "acquisition", "cession", "servitude", "reconnaissance_limite"
)

#' Etats constates d'un element de limite
#'
#' @description
#' Tous les etats qu'un constat peut porter. Ils dependent de la forme de
#' l'element (voir [SOMMIER_ETATS_PAR_FORME]).
#'
#' Un point - une borne, un signe, un detail ponctuel :
#' * `en_place` : l'element est la, en etat ;
#' * `endommage` : il est la, abime (borne penchee, mur en partie effondre) ;
#' * `non_retrouve` : cherche sans succes ;
#' * `detruit` : ses vestiges sont constates.
#'
#' Une ligne - une voie, un fosse, un detail lineaire -, par sa visibilite :
#' * `visible` : elle se suit sans peine ;
#' * `partiellement_visible` : elle se suit par endroits ;
#' * `peu_visible` : quelques traces seulement ;
#' * `non_visible` : aucune trace sur le terrain.
#'
#' Une surface - un batiment, un cours d'eau, un detail surfacique :
#' * `conforme` : presente, conforme au plan ;
#' * `modifiee` : presente, d'emprise ou de forme differente du plan ;
#' * `degradee` : en ruine, comblee, envahie ;
#' * `disparue` : plus rien sur le terrain.
#'
#' Pour toutes : `inaccessible`, on n'a pas pu l'approcher. Et `hors_plan` :
#' trouve sur le terrain, absent du plan cadastral.
#'
#' @details
#' Des etats constates, pas des verdicts. Il n'y a pas d'etat « deplace » :
#' un ecart de quelques metres entre un GNSS et un plan au 1/5000 ne prouve
#' rien, et juger qu'une borne a bouge revient au geometre. L'ecart se
#' calcule a la lecture, a la lumiere de la precision declaree du releve.
#'
#' @export
SOMMIER_ETATS_LIMITE <- c("en_place", "endommage", "non_retrouve", "detruit",
                          "inaccessible", "hors_plan", "visible",
                          "partiellement_visible", "peu_visible",
                          "non_visible", "conforme", "modifiee", "degradee",
                          "disparue")

#' Etats d'un element de limite, selon sa forme
#'
#' @description
#' Une liste nommee : `point`, `ligne`, `surface`, `hors_plan`. Chacune donne
#' les etats qu'un constat peut porter pour un element de cette forme, dans
#' l'ordre ou le formulaire de terrain les propose. La forme est celle de
#' l'objet du plan, non sa categorie : un cours d'eau est une ligne sur une
#' feuille, une surface sur une autre. Voir [SOMMIER_ETATS_LIMITE].
#'
#' @export
SOMMIER_ETATS_PAR_FORME <- list(
  point = c("en_place", "endommage", "non_retrouve", "detruit",
            "inaccessible"),
  ligne = c("visible", "partiellement_visible", "peu_visible", "non_visible",
            "inaccessible"),
  surface = c("conforme", "modifiee", "degradee", "disparue", "inaccessible"),
  hors_plan = "hors_plan"
)

#' Payload du registre 2 - foncier et limites (imprime A40)
#'
#' @description
#' Une operation foncière : limite, mouvement de propriete, servitude, ou
#' application du regime forestier.
#'
#' @details
#' L'imprime A40 detaille les elements de calcul des frais de delimitation
#' (heures d'ingenieur et de technicien, arpentage, fourniture et pose des
#' bornes) et leur repartition entre le proprietaire et les riverains. Ces
#' champs ne sont exiges que pour les operations de limite : une acquisition
#' n'a pas d'heures d'arpentage.
#'
#' La coherence de la repartition est verifiee lorsque les deux parts et le
#' cout total sont renseignes : une repartition qui ne totalise pas le cout
#' est une erreur de saisie, pas une subtilite comptable.
#'
#' @param type_entree L'un de [SOMMIER_TYPES_FONCIER].
#' @param description Description de l'operation.
#' @param heures_ingenieur,heures_technicien Temps passe (facultatif).
#' @param arpentage_eur Frais d'arpentage (facultatif).
#' @param nb_bornes Nombre de bornes fournies et posees (facultatif).
#' @param cout_total_eur Cout total de l'operation (facultatif).
#' @param charge_proprietaire_eur,charge_riverains_eur Repartition du cout
#'   (facultatif).
#' @param surface_ha Surface concernee (facultatif).
#' @param reference_acte Reference de l'acte, de l'arrete ou du proces-verbal
#'   (facultatif).
#' @param references_cadastrales References cadastrales, en un ou plusieurs
#'   elements (facultatif).
#' @param beneficiaire Beneficiaire d'une servitude (facultatif).
#' @param observations Observations libres (facultatif).
#'
#' @param geometrie Position ou trace, en WGS84 : une borne est un point (voir
#'   [geom_point()]), une limite une ligne (voir [geom_ligne()]).
#'   Facultative — un gestionnaire sans releve continue de saisir sans, et son
#'   sommier reste conforme.
#' @param etat Pour une `reconnaissance_limite`, l'un de
#'   [SOMMIER_ETATS_LIMITE]. Obligatoire pour ce type, refuse pour les autres.
#' @param element_pci Pour une `reconnaissance_limite`, l'element du plan
#'   cadastral tel que l'agent l'a vu : liste nommee portant au moins `id`
#'   (`feuille:OBJECT_RID`, voir [sommier_elements_pci()]), et facultativement
#'   `numero`, `categorie`, `nature`, `texte`, `millesime`, `x`, `y`, et
#'   `forme` (`point`, `ligne`, `surface`). Quand la forme est donnee, l'etat
#'   doit etre de sa liste (voir [SOMMIER_ETATS_PAR_FORME]). Obligatoire sauf
#'   a l'etat `hors_plan`, ou il est refuse.
#' @param visite_le Instant de la visite, tel que l'appareil l'a note
#'   (facultatif).
#' @param operateur Agent qui a constate (facultatif).
#' @param precision_m Precision horizontale declaree par le recepteur GNSS,
#'   en metres (facultatif).
#' @param source_gnss Recepteur ou mode de positionnement declare
#'   (facultatif).
#' @param releve_uuid Identifiant du releve dans l'outil de terrain
#'   (facultatif).
#' @param photos Liste de photos, chacune liste nommee : `sha256`
#'   (64 caracteres hexadecimaux), `octets`, `type`, et facultativement
#'   `fichier`, `exif_date`, `exif_position`. Voir [sommier_deposer_photo()].
#'
#' @return Une liste nommee, prete a etre passee a [sommier_entree()].
#'
#' @examples
#' registre2_foncier(
#'   type_entree = "bornage", description = "Limite nord, canton des Vernes",
#'   heures_technicien = 14, nb_bornes = 8, cout_total_eur = 1200,
#'   charge_proprietaire_eur = 600, charge_riverains_eur = 600
#' )
#'
#' @export
registre2_foncier <- function(type_entree,
                              description,
                              heures_ingenieur = NULL,
                              heures_technicien = NULL,
                              arpentage_eur = NULL,
                              nb_bornes = NULL,
                              cout_total_eur = NULL,
                              charge_proprietaire_eur = NULL,
                              charge_riverains_eur = NULL,
                              surface_ha = NULL,
                              reference_acte = NULL,
                              references_cadastrales = NULL,
                              beneficiaire = NULL,
                              observations = NULL,
                              geometrie = NULL,
                              etat = NULL,
                              element_pci = NULL,
                              visite_le = NULL,
                              operateur = NULL,
                              precision_m = NULL,
                              source_gnss = NULL,
                              releve_uuid = NULL,
                              photos = NULL) {
  type_entree <- valider_choix(type_entree, "type_entree", SOMMIER_TYPES_FONCIER)
  reconnaissance <- identical(type_entree, "reconnaissance_limite")
  propres <- list(etat = etat, element_pci = element_pci,
                  visite_le = visite_le, operateur = operateur,
                  precision_m = precision_m, source_gnss = source_gnss,
                  releve_uuid = releve_uuid, photos = photos)
  if (!reconnaissance) {
    presents <- names(propres)[!vapply(propres, est_vide, logical(1))]
    if (length(presents) > 0L) {
      stop("Champ(s) propre(s) a une reconnaissance de limite : ",
           paste(presents, collapse = ", "), ".", call. = FALSE)
    }
  } else {
    etat <- valider_choix(etat, "etat", SOMMIER_ETATS_LIMITE)
    if (identical(etat, "hors_plan") && !est_vide(element_pci)) {
      stop("Un element `hors_plan` n'est pas au plan : `element_pci` doit ",
           "rester vide.", call. = FALSE)
    }
    if (!identical(etat, "hors_plan") && est_vide(element_pci)) {
      stop("`element_pci` est obligatoire : un constat repond a un element ",
           "du plan, sauf a l'etat `hors_plan`.", call. = FALSE)
    }
    # Un constat recopie la forme de l'element depuis la v0.26.0 ; l'etat doit
    # alors etre de sa liste. Les constats anterieurs n'en portent pas, et
    # n'avaient que les etats d'un point.
    forme <- if (is.list(element_pci)) element_pci$forme
    if (!est_vide(forme)) {
      forme <- valider_choix(forme, "element_pci$forme",
                             c("point", "ligne", "surface"))
      if (!etat %in% SOMMIER_ETATS_PAR_FORME[[forme]]) {
        stop("Etat `", etat, "` impossible pour un element de forme ", forme,
             " : ", paste(SOMMIER_ETATS_PAR_FORME[[forme]], collapse = ", "),
             ".", call. = FALSE)
      }
    }
  }

  # Une repartition qui ne totalise pas le cout est une erreur de saisie.
  if (!est_vide(cout_total_eur) && !est_vide(charge_proprietaire_eur) &&
      !est_vide(charge_riverains_eur)) {
    total <- charge_proprietaire_eur + charge_riverains_eur
    if (abs(total - cout_total_eur) > 0.01) {
      stop("La repartition ne totalise pas le cout : ",
           charge_proprietaire_eur, " + ", charge_riverains_eur, " = ", total,
           ", attendu ", cout_total_eur, ".", call. = FALSE)
    }
  }

  compacter(list(
    type_entree             = type_entree,
    description             = valider_texte(description, "description"),
    heures_ingenieur        = si_present(heures_ingenieur, valider_nombre,
                                         "heures_ingenieur", min = 0),
    heures_technicien       = si_present(heures_technicien, valider_nombre,
                                         "heures_technicien", min = 0),
    arpentage_eur           = si_present(arpentage_eur, valider_nombre,
                                         "arpentage_eur", min = 0),
    nb_bornes               = si_present(nb_bornes, valider_entier,
                                         "nb_bornes", min = 0),
    cout_total_eur          = si_present(cout_total_eur, valider_nombre,
                                         "cout_total_eur", min = 0),
    charge_proprietaire_eur = si_present(charge_proprietaire_eur, valider_nombre,
                                         "charge_proprietaire_eur", min = 0),
    charge_riverains_eur    = si_present(charge_riverains_eur, valider_nombre,
                                         "charge_riverains_eur", min = 0),
    surface_ha              = si_present(surface_ha, valider_nombre,
                                         "surface_ha", min = 0),
    reference_acte          = si_present(reference_acte, valider_texte,
                                         "reference_acte"),
    references_cadastrales  = valider_liste_texte(references_cadastrales,
                                                 "references_cadastrales"),
    beneficiaire            = si_present(beneficiaire, valider_texte,
                                         "beneficiaire"),
    geometrie        = geometrie_si_presente(geometrie, c("Point", "LineString")),
    observations            = si_present(observations, valider_texte,
                                         "observations"),
    etat                    = if (reconnaissance) etat,
    element_pci             = valider_element_pci(element_pci),
    visite_le               = si_present(visite_le, format_instant,
                                         "visite_le"),
    operateur               = si_present(operateur, valider_texte, "operateur"),
    precision_m             = si_present(precision_m, valider_nombre,
                                         "precision_m", min = 0),
    source_gnss             = si_present(source_gnss, valider_texte,
                                         "source_gnss"),
    releve_uuid             = si_present(releve_uuid, valider_uuid,
                                         "releve_uuid"),
    photos                  = valider_photos(photos)
  ))
}

# L'element du plan tel que l'agent l'a vu. Le constat le recopie : au
# millesime suivant, le PCI aura peut-etre change, et l'on doit encore savoir a
# quoi le constat repondait.
valider_element_pci <- function(element) {
  if (est_vide(element)) {
    return(NULL)
  }
  if (!is.list(element) || is.null(names(element))) {
    stop("`element_pci` doit etre une liste nommee.", call. = FALSE)
  }
  inconnus <- setdiff(names(element), c("id", "numero", "categorie", "nature",
                                        "texte", "millesime", "x", "y",
                                        "forme"))
  if (length(inconnus) > 0L) {
    stop("`element_pci` : champ(s) inconnu(s) : ",
         paste(inconnus, collapse = ", "), ".", call. = FALSE)
  }
  id <- valider_texte(element$id, "element_pci$id")
  if (!grepl("^[0-9A-Z]{12}:.+$", id)) {
    stop("`element_pci$id` doit s'ecrire `feuille:OBJECT_RID`, recu : ", id,
         ".", call. = FALSE)
  }
  compacter(list(
    id        = id,
    numero    = si_present(element$numero, valider_texte, "element_pci$numero"),
    categorie = si_present(element$categorie, valider_texte,
                           "element_pci$categorie"),
    nature    = si_present(element$nature, valider_texte, "element_pci$nature"),
    texte     = si_present(element$texte, valider_texte, "element_pci$texte"),
    millesime = si_present(element$millesime, format_date,
                           "element_pci$millesime"),
    x         = si_present(element$x, valider_nombre, "element_pci$x"),
    y         = si_present(element$y, valider_nombre, "element_pci$y"),
    forme     = si_present(element$forme, valider_choix, "element_pci$forme",
                           c("point", "ligne", "surface"))
  ))
}

# Une photo n'entre dans la chaine que par son empreinte : les octets vivent
# dans le depot, sous ce nom. L'empreinte est donc la seule chose exigee ; le
# reste la decrit.
valider_photos <- function(photos) {
  if (est_vide(photos)) {
    return(NULL)
  }
  if (!is.list(photos) || !is.null(names(photos))) {
    stop("`photos` doit etre une liste de photos, chacune liste nommee.",
         call. = FALSE)
  }
  lapply(seq_along(photos), function(i) {
    p <- photos[[i]]
    nom <- paste0("photos[[", i, "]]")
    if (!is.list(p) || is.null(names(p))) {
      stop("`", nom, "` doit etre une liste nommee.", call. = FALSE)
    }
    empreinte <- tolower(valider_texte(p$sha256, paste0(nom, "$sha256")))
    if (!grepl("^[0-9a-f]{64}$", empreinte)) {
      stop("`", nom, "$sha256` doit compter 64 caracteres hexadecimaux.",
           call. = FALSE)
    }
    compacter(list(
      sha256        = empreinte,
      octets        = valider_entier(p$octets, paste0(nom, "$octets"), min = 1),
      type          = valider_texte(p$type, paste0(nom, "$type")),
      fichier       = si_present(p$fichier, valider_texte,
                                 paste0(nom, "$fichier")),
      exif_date     = si_present(p$exif_date, valider_texte,
                                 paste0(nom, "$exif_date")),
      exif_position = si_present(p$exif_position, valider_texte,
                                 paste0(nom, "$exif_position"))
    ))
  })
}

# Un champ qui peut porter plusieurs valeurs : rendu en tableau JSON meme a un
# seul element, sans quoi la forme du payload changerait avec le nombre de
# valeurs et compliquerait la relecture.
valider_liste_texte <- function(x, nom) {
  if (est_vide(x)) {
    return(NULL)
  }
  valeurs <- vapply(as.character(x), valider_texte, character(1), nom = nom,
                    USE.NAMES = FALSE)
  I(valeurs)
}
