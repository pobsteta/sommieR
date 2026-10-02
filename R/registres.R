#' Les neuf registres du sommier unifie
#'
#' @description
#' Table de correspondance entre les registres de `sommieR`, les imprimes de
#' la serie A50 de l'ONF dont ils derivent, et l'echelle a laquelle ils
#' s'ancrent. Elle materialise la section 3 du brief.
#'
#' @details
#' `echelle` vaut `"foret"` (l'entree porte `ug_uuid = NULL`), `"ug"`
#' (`ug_uuid` obligatoire) ou `"mixte"` (les deux sont admis - le registre 6
#' couvre a la fois les travaux par unite de gestion, imprime A50J, et les
#' travaux hors unite de gestion, imprime A50H).
#'
#' Seuls les registres 5 et 6 sont ouverts a l'ecriture en v0.1.0,
#' conformement a la priorite 1 du brief : ce sont eux qu'exigent la
#' certification PEFC et le bilan du document de gestion precedent.
#'
#' @format `data.frame` de 9 lignes et 5 colonnes : `registre`, `nom`,
#'   `source_a50`, `echelle`, `implemente`.
#'
#' @examples
#' SOMMIER_REGISTRES
#'
#' @export
SOMMIER_REGISTRES <- data.frame(
  registre = 1:9,
  # Les libelles se lisent dans le rapport et les messages : accentues, en
  # echappements \u pour garder le code en ASCII.
  nom = c(
    "Validations", "Foncier & limites", "Droits & concessions",
    "Infrastructures", "Coupes & r\u00e9coltes", "Travaux",
    "Comptabilit\u00e9", "\u00c9v\u00e8nements & faune",
    "Patrimoine remarquable"
  ),
  source_a50 = c(
    "A10", "A40", "A50C", "A50D/Dbis", "A50E/F/I",
    "A50J/Jbis/H", "A50G", "A50K/L", "A50 r/*"
  ),
  # `mixte` la ou l'imprime lui-meme montre les deux ancrages : l'A50C porte
  # une colonne « unites de gestion / series », une servitude ou une
  # acquisition vise des parcelles identifiees, et une liste d'especes
  # protegees peut couvrir la foret entiere comme une seule unite. Le
  # registre 4 reste a l'echelle de la foret : une route traverse plusieurs
  # unites, l'y rattacher serait arbitraire.
  echelle = c(
    "foret", "mixte", "mixte", "foret", "mixte",
    "mixte", "foret", "mixte", "mixte"
  ),
  implemente = rep(TRUE, 9L),
  stringsAsFactors = FALSE
)

#' Regimes de propriete forestiere
#' @export
SOMMIER_REGIMES <- c("domanial", "communal", "privee")

#' Registres ouverts a l'ecriture dans cette version
#' @export
SOMMIER_REGISTRES_OUVERTS <- 1:9

#' Types d'entree du registre 5 (coupes et recoltes)
#'
#' @description
#' * `martelage` : volume martele en coupe reglee ou non reglee (imprime A50E).
#' * `produit_accidentel` : chablis, bois sanitaires, volumes marteles hors
#'   coupe prevue (imprime A50E, colonne "produits accidentels").
#' * `bois_delivre` : delivrance, principalement l'affouage en foret communale
#'   (imprime A50G, colonne "bois delivres") - bois martele, donc imputable.
#' * `coupe_realisee` : releve de la coupe effectivement exploitee
#'   (imprime A50F).
#'
#' @export
SOMMIER_TYPES_COUPE <- c(
  "martelage", "produit_accidentel", "bois_delivre", "coupe_realisee"
)

#' Types d'entree imputables a la balance de possibilite
#'
#' @description
#' La balance A50E confronte a la possibilite les **volumes marteles**, soit
#' les coupes et les produits accidentels. `coupe_realisee` en est exclu a
#' dessein : la meme coupe est d'abord martelee (imprime A50E) puis exploitee
#' (imprime A50F), l'imputer deux fois doublerait le prelevement constate.
#'
#' @seealso [sommier_balance_possibilite()]
#' @export
SOMMIER_TYPES_MARTELES <- c("martelage", "produit_accidentel", "bois_delivre")

#' Versions de schema des payloads
#'
#' @description
#' Le payload est du JSONB versionne par type de registre (brief, section 4).
#' La version est hachee avec l'entree : une evolution de schema ne peut donc
#' pas se faire passer pour l'ancienne.
#'
#' @details
#' Les registres 2, 4, 5, 8 et 9 sont passes en `1.1.0` lorsque la geometrie
#' est entree dans leurs payloads. Les neuf sont passes a la version suivante
#' lorsque le bloc `reprise` est devenu admissible dans tous les payloads
#' (voir [sommier_reprise()]) : la provenance concerne chaque registre, la
#' version le dit pour chacun. Les entrees anterieures gardent la version
#' sous laquelle elles ont ete ecrites, et restent valides : le registre est
#' append-only, un changement de schema ne se retrofitte pas sur ce qui est
#' deja chaine. C'est precisement ce que la version hachee permet de dire -
#' cette entree a ete ecrite sous ce schema-la.
#'
#' Le registre 2 est passe en `1.3.0` avec la reconnaissance de limite : un
#' etat constate, l'element du plan recopie, et les photos par leur empreinte.
#' Il est passe en `1.4.0` quand l'etat s'est mis a dependre de la forme de
#' l'element - point, ligne, surface -, que le constat recopie.
#' Le registre 5 est passe en `1.3.0` quand un produit accidentel a pu
#' renvoyer au constat de terrain dont il procede (`constat_id`).
#' Le registre 8 est passe en `1.3.0` quand la suite d'une detection est
#' devenue un constat complet : position, precision, operateur, photos.
#' Le registre 1 est passe en `1.2.0` avec l'amenagement : la periode et la
#' possibilite que l'arrete ou l'agrement fixe entrent dans la chaine.
#'
#' @export
SOMMIER_SCHEMA_VERSIONS <- c(
  "1" = "r1-1.2.0", "2" = "r2-1.4.0", "3" = "r3-1.1.0",
  "4" = "r4-1.2.0", "5" = "r5-1.3.0", "6" = "r6-1.2.0",
  "7" = "r7-1.1.0", "8" = "r8-1.3.0", "9" = "r9-1.2.0"
)

#' Payload du registre 5 - coupes et recoltes
#'
#' @description
#' Construit et valide le payload d'une entree du registre 5 (imprimes A50E,
#' A50F et A50I). Les champs facultatifs laisses a `NULL` sont absents du JSON
#' : ils ne sont pas ecrits comme `null`, afin qu'ajouter une precision plus
#' tard ne ressemble pas a une correction de valeur.
#'
#' @param type_entree L'un de [SOMMIER_TYPES_COUPE].
#' @param exercice Annee de l'exercice budgetaire (entier).
#' @param nature_coupe Nature de la coupe (texte libre normalise par le
#'   gestionnaire : amelioration, reguliere, sanitaire, emprise...).
#' @param volume_m3 Volume en metres cubes (positif ou nul).
#' @param surface_ha Surface parcourue en hectares (facultatif). Sans elle,
#'   un martelage rattache a une unite de gestion parcourt, a la lecture,
#'   toute la surface de l'unite (voir la colonne `surface_source` de
#'   `v_coupe`) : la surface deduite n'entre pas dans le payload.
#' @param essence Essence ou groupe d'essences (facultatif).
#' @param coupon Identifiant du coupon ou de la subdivision (facultatif).
#' @param observations Observations libres (facultatif).
#' @param constat_id UUID du constat de terrain dont la coupe procede - la
#'   suite d'une detection, au registre 8 (facultatif). Voir
#'   [sommier_produit_accidentel()].
#'
#' @param geometrie Emprise de la coupe, en WGS84 : voir [geom_polygone()].
#'   Facultative — un gestionnaire sans releve continue de saisir sans, et son
#'   sommier reste conforme.
#'
#' @return Une liste nommee, prete a etre passee a [sommier_entree()].
#'
#' @examples
#' registre5_coupe(
#'   type_entree = "martelage", exercice = 2026,
#'   nature_coupe = "amelioration", volume_m3 = 342.5,
#'   surface_ha = 12.4, essence = "HET"
#' )
#'
#' @export
registre5_coupe <- function(type_entree,
                            exercice,
                            nature_coupe,
                            volume_m3,
                            surface_ha = NULL,
                            essence = NULL,
                            coupon = NULL,
                            observations = NULL,
                            geometrie = NULL,
                            constat_id = NULL) {
  compacter(list(
    type_entree  = valider_choix(type_entree, "type_entree", SOMMIER_TYPES_COUPE),
    exercice     = valider_entier(exercice, "exercice", min = 1500, max = 2999),
    nature_coupe = valider_texte(nature_coupe, "nature_coupe"),
    volume_m3    = valider_nombre(volume_m3, "volume_m3", min = 0),
    surface_ha   = si_present(surface_ha, valider_nombre, "surface_ha", min = 0),
    essence      = si_present(essence, valider_texte, "essence"),
    coupon       = si_present(coupon, valider_texte, "coupon"),
    geometrie    = geometrie_si_presente(geometrie, "Polygon"),
    observations = si_present(observations, valider_texte, "observations"),
    constat_id   = si_present(constat_id, valider_uuid, "constat_id")
  ))
}

#' Payload du registre 6 - travaux
#'
#' @description
#' Construit et valide le payload d'une intervention du registre 6 (imprimes
#' A50J, A50J bis pour les travaux par unite de gestion, A50H pour les travaux
#' hors unite de gestion).
#'
#' @details
#' **Le libelle et le code.** `nature_travaux` reste le libelle libre de
#' l'A50J ; `code_travaux`, dans [SOMMIER_CODES_TRAVAUX], est ce qu'on
#' agrege. Le code fixe l'unite de la quantite et la forme de la geometrie :
#' une cloture se trace en ligne, une plantation en surface.
#'
#' **Prevu, ou non.** `prevu` est un fait constate a la reception : l'amenagement
#' ou le PSG prevoyait-il l'intervention ? Hors `prevu`, `motif_ecart` est
#' obligatoire. Aucun statut "programme" n'entre au registre, qui n'inscrit que
#' ce qui a ete fait.
#'
#' **Le resultat quitte l'intervention.** La reprise se mesure sur des
#' placettes, a des dates ([registre6_placette()], [registre6_controle()]).
#' `taux_reprise_pct` reste admis pour transcrire la colonne "% de reprise" de
#' l'A50J papier.
#'
#' **Le type d'entree.** Une intervention n'ecrit `type_entree` que s'il est
#' passe : les interventions inscrites avant la v0.28.0 n'en portent pas, et
#' doivent se relire a l'identique.
#'
#' @param annee Annee de realisation (entier).
#' @param nature_travaux Nature des travaux, en clair.
#' @param localisation Localisation en clair - a renseigner pour les travaux
#'   hors unite de gestion (imprime A50H), ou l'entree n'est ancree sur aucune
#'   unite de gestion.
#' @param repere_plan Repere sur le plan (facultatif).
#' @param quantite,unite Quantite realisee et son unite (facultatif). Avec un
#'   `code_travaux`, l'unite est celle du code.
#' @param nb_plants,provenance_plants Nombre de plants et provenance,
#'   pour les travaux de reboisement (facultatif).
#' @param montant_eur Montant en euros (facultatif).
#' @param taux_reprise_pct Taux de reprise en pourcentage, 0 a 100
#'   (facultatif) : la colonne de l'A50J, pour la reprise de l'existant.
#' @param observations Observations libres (facultatif).
#' @param type_entree `"travaux"`, ou `NULL` (le defaut, qui vaut travaux).
#' @param code_travaux L'un des codes de [SOMMIER_CODES_TRAVAUX] (facultatif).
#' @param modalite Modalite d'execution, courte ("mecanique en ligne").
#' @param essence_objectif Code de l'essence objectif.
#' @param execution L'un de [SOMMIER_EXECUTIONS_TRAVAUX].
#' @param intervenant Entreprise ou equipe.
#' @param prevu L'un de [SOMMIER_PREVUS_TRAVAUX].
#' @param motif_ecart Raison d'un ecart au prevu ; obligatoire hors `prevu`.
#' @param date_reception Date de reception des travaux.
#' @param geometrie Emprise, en WGS84 : surface, ligne ou point selon le code
#'   (voir [geom_polygone()]).
#' @param precision_m,source_gnss Precision et source de la position relevee.
#' @param photos Photos, par leur empreinte (voir [sommier_deposer_photo()]).
#'
#' @return Une liste nommee, prete a etre passee a [sommier_entree()].
#'
#' @seealso [registre6_placette()], [registre6_controle()],
#'   [SOMMIER_CODES_TRAVAUX]
#'
#' @examples
#' registre6_travaux(
#'   annee = 2026, nature_travaux = "plantation",
#'   nb_plants = 1200, provenance_plants = "CHS - Bourgogne",
#'   montant_eur = 4800, code_travaux = "PL", quantite = 1.2, unite = "ha",
#'   prevu = "prevu"
#' )
#'
#' @export
registre6_travaux <- function(annee,
                              nature_travaux,
                              localisation = NULL,
                              repere_plan = NULL,
                              quantite = NULL,
                              unite = NULL,
                              nb_plants = NULL,
                              provenance_plants = NULL,
                              montant_eur = NULL,
                              taux_reprise_pct = NULL,
                              observations = NULL,
                              type_entree = NULL,
                              code_travaux = NULL,
                              modalite = NULL,
                              essence_objectif = NULL,
                              execution = NULL,
                              intervenant = NULL,
                              prevu = NULL,
                              motif_ecart = NULL,
                              date_reception = NULL,
                              geometrie = NULL,
                              precision_m = NULL,
                              source_gnss = NULL,
                              photos = NULL) {
  if (!est_vide(quantite) && est_vide(unite)) {
    stop("`unite` est obligatoire des lors que `quantite` est renseignee : ",
         "un nombre sans unite n'est pas exploitable dans un registre.",
         call. = FALSE)
  }
  type_entree <- si_present(type_entree, valider_choix, "type_entree",
                            "travaux")
  code <- si_present(code_travaux, valider_choix, "code_travaux",
                     SOMMIER_CODES_TRAVAUX$code)
  formes <- c("Point", "LineString", "Polygon")
  if (!is.null(code)) {
    attendu <- SOMMIER_CODES_TRAVAUX[SOMMIER_CODES_TRAVAUX$code == code, ]
    if (!est_vide(unite) && !identical(unite, attendu$unite)) {
      stop("Les travaux ", code, " (", attendu$libelle, ") se mesurent en ",
           attendu$unite, ", pas en ", unite, ".", call. = FALSE)
    }
    formes <- FORMES_GEOJSON[[attendu$forme]]
  }
  prevu <- si_present(prevu, valider_choix, "prevu", SOMMIER_PREVUS_TRAVAUX)
  if (!is.null(prevu) && prevu != "prevu" && est_vide(motif_ecart)) {
    stop("Des travaux `", prevu, "` doivent dire pourquoi : `motif_ecart` ",
         "est obligatoire hors `prevu`.", call. = FALSE)
  }
  compacter(list(
    annee             = valider_entier(annee, "annee", min = 1500, max = 2999),
    nature_travaux    = valider_texte(nature_travaux, "nature_travaux"),
    localisation      = si_present(localisation, valider_texte, "localisation"),
    repere_plan       = si_present(repere_plan, valider_texte, "repere_plan"),
    quantite          = si_present(quantite, valider_nombre, "quantite", min = 0),
    unite             = si_present(unite, valider_texte, "unite"),
    nb_plants         = si_present(nb_plants, valider_entier, "nb_plants", min = 0),
    provenance_plants = si_present(provenance_plants, valider_texte, "provenance_plants"),
    montant_eur       = si_present(montant_eur, valider_nombre, "montant_eur"),
    taux_reprise_pct  = si_present(taux_reprise_pct, valider_nombre,
                                   "taux_reprise_pct", min = 0, max = 100),
    observations      = si_present(observations, valider_texte, "observations"),
    type_entree       = type_entree,
    code_travaux      = code,
    modalite          = si_present(modalite, valider_texte, "modalite"),
    essence_objectif  = si_present(essence_objectif, valider_texte,
                                   "essence_objectif"),
    execution         = si_present(execution, valider_choix, "execution",
                                   SOMMIER_EXECUTIONS_TRAVAUX),
    intervenant       = si_present(intervenant, valider_texte, "intervenant"),
    prevu             = prevu,
    motif_ecart       = si_present(motif_ecart, valider_texte, "motif_ecart"),
    date_reception    = si_present(date_reception, format_date,
                                   "date_reception"),
    geometrie         = geometrie_si_presente(geometrie, formes),
    precision_m       = si_present(precision_m, valider_nombre, "precision_m",
                                   min = 0),
    source_gnss       = si_present(source_gnss, valider_texte, "source_gnss"),
    photos            = valider_photos(photos)
  ))
}

#' Validation d'un payload selon son registre
#'
#' Revalide un payload deja construit - utile a la relecture d'un export, ou
#' les payloads arrivent en JSON sans etre passes par les constructeurs.
#'
#' @details
#' La cle `reprise` est admise dans le payload de n'importe quel registre :
#' elle porte la provenance d'une entree transcrite (voir [sommier_reprise()]).
#' Elle est detachee avant l'appel au constructeur du registre - qui n'a pas a
#' la connaitre - validee par [valider_reprise()], puis rattachee. C'est le
#' seul champ commun aux neuf payloads, parce que la question a laquelle il
#' repond, celle de savoir d'ou vient cette ecriture, se pose partout de la
#' meme facon.
#'
#' @param registre Numero de registre (1 a 9).
#' @param payload Liste nommee.
#' @return Le payload valide, normalise.
#' @export
valider_payload <- function(registre, payload) {
  registre <- valider_entier(registre, "registre", min = 1, max = 9)
  if (!registre %in% SOMMIER_REGISTRES_OUVERTS) {
    stop(
      "Registre ", registre, " (",
      SOMMIER_REGISTRES$nom[[registre]],
      ") non ouvert a l'ecriture dans sommieR ", utils::packageVersion("sommieR"),
      " ; registres disponibles : ",
      paste(SOMMIER_REGISTRES_OUVERTS, collapse = ", "), ".",
      call. = FALSE
    )
  }
  if (!is.list(payload) || is.null(names(payload))) {
    stop("`payload` doit etre une liste nommee.", call. = FALSE)
  }
  reprise <- payload$reprise
  payload <- payload[setdiff(names(payload), "reprise")]
  # Les registres a plusieurs imprimes se redirigent sur le constructeur du
  # type declare : le payload porte sa propre discriminante.
  valide <- switch(
    as.character(registre),
    "1" = do.call(registre1_validation, payload),
    "2" = do.call(registre2_foncier, payload),
    "3" = do.call(registre3_depuis_payload, list(payload)),
    "4" = do.call(registre4_depuis_payload, list(payload)),
    "5" = do.call(registre5_coupe, payload),
    "6" = do.call(registre6_depuis_payload, list(payload)),
    "7" = do.call(registre7_ecriture, payload_r7(payload)),
    "8" = do.call(registre8_depuis_payload, list(payload)),
    "9" = do.call(registre9_depuis_payload, list(payload))
  )
  if (!is.null(reprise)) {
    valide$reprise <- valider_reprise(reprise)
  }
  valide
}

#' Echelle d'ancrage attendue pour un registre
#' @param registre Numero de registre.
#' @return `"foret"`, `"ug"` ou `"mixte"`.
#' @noRd
echelle_registre <- function(registre) {
  SOMMIER_REGISTRES$echelle[SOMMIER_REGISTRES$registre == registre]
}

# Retire les champs absents : ils ne doivent pas apparaitre dans le JSON
# canonique, sans quoi l'ajout ulterieur d'une precision serait indistinguable
# d'une correction de valeur.
compacter <- function(x) {
  x[!vapply(x, is.null, logical(1))]
}

si_present <- function(valeur, validateur, nom, ...) {
  if (est_vide(valeur)) NULL else validateur(valeur, nom, ...)
}

# `sens` et `rubrique` sont deduits du poste et non des arguments de
# `registre7_ecriture()` : a la relecture d'un export il faut donc les ecarter
# avant de rappeler le constructeur, qui les recalculera.
payload_r7 <- function(payload) {
  payload[setdiff(names(payload), c("sens", "rubrique"))]
}
