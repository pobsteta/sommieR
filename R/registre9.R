#' Types de fiche du patrimoine remarquable (serie A50 r/*)
#'
#' @description
#' Les six imprimes de la serie : arbre remarquable (r/a), peuplement
#' remarquable (r/p), vestige ou element culturel (r/c), espece protegee
#' (r/e et r/s), habitat remarquable (r/h).
#'
#' @export
SOMMIER_TYPES_REMARQUABLE <- c("arbre", "peuplement", "vestige", "espece",
                               "habitat")

#' Payload du registre 9 - arbre remarquable (imprime A50 r/a)
#'
#' @description
#' Une fiche d'arbre remarquable et, le cas echeant, une mesure datee.
#'
#' @details
#' L'imprime r/a est fait de deux parties : une identite qui ne bouge pas
#' (appellation, essence, interet) et des mesures datees qui s'ajoutent au fil
#' des visites. En append-only, chaque visite est une entree de plus portant
#' la meme `appellation` : la serie de mesures se reconstitue par requete,
#' comme la matrice du tableau de chasse. Rien n'est ecrase, et l'evolution du
#' sujet reste lisible.
#'
#' @param appellation Nom sous lequel l'arbre est connu.
#' @param essence Essence.
#' @param interet Ce qui fonde le caractere remarquable : age, dimensions,
#'   port, histoire.
#' @param age_ans,circonference_cm,hauteur_m Mesures du releve (facultatif).
#' @param etat_sanitaire `"bon"`, `"moyen"`, `"degrade"`, `"deperissant"`,
#'   `"mort"` (facultatif). Un arbre mort sur pied reste remarquable : c'est
#'   meme un facteur de l'IBP.
#' @param observations Observations libres (facultatif).
#'
#' @return Une liste nommee, prete a etre passee a [sommier_entree()].
#'
#' @examples
#' registre9_arbre(
#'   appellation = "Chene des Trois Bornes", essence = "CHS",
#'   interet = "Age estime a 350 ans, port en candelabre",
#'   circonference_cm = 540, hauteur_m = 28, etat_sanitaire = "moyen"
#' )
#'
#' @export
registre9_arbre <- function(appellation,
                            essence,
                            interet,
                            age_ans = NULL,
                            circonference_cm = NULL,
                            hauteur_m = NULL,
                            etat_sanitaire = NULL,
                            observations = NULL) {
  compacter(list(
    type_fiche       = "arbre",
    appellation      = valider_texte(appellation, "appellation"),
    essence          = valider_texte(essence, "essence"),
    interet          = valider_texte(interet, "interet"),
    age_ans          = si_present(age_ans, valider_entier, "age_ans", min = 0),
    circonference_cm = si_present(circonference_cm, valider_nombre,
                                  "circonference_cm", min = 0),
    hauteur_m        = si_present(hauteur_m, valider_nombre, "hauteur_m", min = 0),
    etat_sanitaire   = si_present(etat_sanitaire, valider_choix, "etat_sanitaire",
                                  choix = SOMMIER_ETATS_SANITAIRES),
    observations     = si_present(observations, valider_texte, "observations")
  ))
}

#' Etats sanitaires releves sur un sujet remarquable
#' @export
SOMMIER_ETATS_SANITAIRES <- c("bon", "moyen", "degrade", "deperissant", "mort")

#' Payload du registre 9 - peuplement remarquable (imprime A50 r/p)
#'
#' @param appellation Nom du peuplement.
#' @param interet Ce qui fonde le caractere remarquable.
#' @param composition Composition en essences, en dixiemes : liste nommee dont
#'   les valeurs somment a 10 (facultatif).
#' @param age_ans,surface_ha,hauteur_dominante_m,surface_terriere_m2ha Mesures
#'   du releve (facultatif).
#' @param observations Observations libres (facultatif).
#'
#' @return Une liste nommee, prete a etre passee a [sommier_entree()].
#'
#' @examples
#' registre9_peuplement(
#'   appellation = "Futaie de la Combe", interet = "Hetraie-sapiniere agee",
#'   composition = list(HET = 6, SAP = 4), surface_ha = 12.4,
#'   hauteur_dominante_m = 34
#' )
#'
#' @export
registre9_peuplement <- function(appellation,
                                 interet,
                                 composition = NULL,
                                 age_ans = NULL,
                                 surface_ha = NULL,
                                 hauteur_dominante_m = NULL,
                                 surface_terriere_m2ha = NULL,
                                 observations = NULL) {
  if (!est_vide(composition)) {
    if (!is.list(composition) || is.null(names(composition)) ||
        any(!nzchar(names(composition)))) {
      stop("`composition` doit etre une liste nommee par essence.", call. = FALSE)
    }
    parts <- vapply(composition, function(v) valider_nombre(v, "composition", min = 0),
                    numeric(1))
    # L'imprime r/p exprime la composition en dixiemes : elle somme a 10 par
    # construction, et une somme differente signale une saisie incomplete.
    if (abs(sum(parts) - 10) > 0.01) {
      stop("`composition` est exprimee en dixiemes et doit sommer a 10 ; ",
           "recu ", sum(parts), ".", call. = FALSE)
    }
  }
  compacter(list(
    type_fiche            = "peuplement",
    appellation           = valider_texte(appellation, "appellation"),
    interet               = valider_texte(interet, "interet"),
    composition           = if (est_vide(composition)) NULL else composition,
    age_ans               = si_present(age_ans, valider_entier, "age_ans", min = 0),
    surface_ha            = si_present(surface_ha, valider_nombre,
                                       "surface_ha", min = 0),
    hauteur_dominante_m   = si_present(hauteur_dominante_m, valider_nombre,
                                       "hauteur_dominante_m", min = 0),
    surface_terriere_m2ha = si_present(surface_terriere_m2ha, valider_nombre,
                                       "surface_terriere_m2ha", min = 0),
    observations          = si_present(observations, valider_texte, "observations")
  ))
}

#' Payload du registre 9 - vestige ou element culturel (imprime A50 r/c)
#'
#' @param appellation Nom du vestige.
#' @param nature Nature : charbonniere, muret, borne armoriee, vestige
#'   archeologique.
#' @param remarques Description et interet.
#' @param travaux_effectues Travaux de degagement ou de conservation
#'   (facultatif).
#' @param bibliographie References bibliographiques (facultatif).
#' @param observations Observations libres (facultatif).
#'
#' @return Une liste nommee, prete a etre passee a [sommier_entree()].
#' @export
registre9_vestige <- function(appellation,
                              nature,
                              remarques,
                              travaux_effectues = NULL,
                              bibliographie = NULL,
                              observations = NULL) {
  compacter(list(
    type_fiche        = "vestige",
    appellation       = valider_texte(appellation, "appellation"),
    nature            = valider_texte(nature, "nature"),
    remarques         = valider_texte(remarques, "remarques"),
    travaux_effectues = si_present(travaux_effectues, valider_texte,
                                   "travaux_effectues"),
    bibliographie     = valider_liste_texte(bibliographie, "bibliographie"),
    observations      = si_present(observations, valider_texte, "observations")
  ))
}

#' Payload du registre 9 - espece protegee (imprimes A50 r/e et r/s)
#'
#' @param nom_francais Nom francais.
#' @param nom_latin Nom scientifique.
#' @param statut_protection Statut : protection nationale, regionale,
#'   directive Habitats, liste rouge (facultatif).
#' @param effectif Effectif ou nombre de stations observees (facultatif).
#' @param localisation Localisation en clair (facultatif).
#' @param bibliographie References bibliographiques (facultatif).
#' @param observations Observations libres (facultatif).
#'
#' @return Une liste nommee, prete a etre passee a [sommier_entree()].
#'
#' @examples
#' registre9_espece(
#'   nom_francais = "Sabot de Venus", nom_latin = "Cypripedium calceolus",
#'   statut_protection = "Directive Habitats, annexe II", effectif = 34
#' )
#'
#' @export
registre9_espece <- function(nom_francais,
                             nom_latin,
                             statut_protection = NULL,
                             effectif = NULL,
                             localisation = NULL,
                             bibliographie = NULL,
                             observations = NULL) {
  compacter(list(
    type_fiche        = "espece",
    nom_francais      = valider_texte(nom_francais, "nom_francais"),
    nom_latin         = valider_texte(nom_latin, "nom_latin"),
    statut_protection = si_present(statut_protection, valider_texte,
                                   "statut_protection"),
    effectif          = si_present(effectif, valider_entier, "effectif", min = 0),
    localisation      = si_present(localisation, valider_texte, "localisation"),
    bibliographie     = valider_liste_texte(bibliographie, "bibliographie"),
    observations      = si_present(observations, valider_texte, "observations")
  ))
}

#' Payload du registre 9 - habitat remarquable (imprime A50 r/h)
#'
#' @param type_habitat Type d'habitat naturel.
#' @param surface_ha Surface en hectares.
#' @param code_natura2000 Code Natura 2000 (facultatif).
#' @param etat_conservation `"favorable"`, `"degrade"`, `"defavorable"`
#'   (facultatif).
#' @param localisation Localisation en clair (facultatif).
#' @param observations Observations libres (facultatif).
#'
#' @return Une liste nommee, prete a etre passee a [sommier_entree()].
#' @export
registre9_habitat <- function(type_habitat,
                              surface_ha,
                              code_natura2000 = NULL,
                              etat_conservation = NULL,
                              localisation = NULL,
                              observations = NULL) {
  compacter(list(
    type_fiche        = "habitat",
    type_habitat      = valider_texte(type_habitat, "type_habitat"),
    surface_ha        = valider_nombre(surface_ha, "surface_ha", min = 0),
    code_natura2000   = si_present(code_natura2000, valider_texte,
                                   "code_natura2000"),
    etat_conservation = si_present(etat_conservation, valider_choix,
                                   "etat_conservation",
                                   choix = c("favorable", "degrade", "defavorable")),
    localisation      = si_present(localisation, valider_texte, "localisation"),
    observations      = si_present(observations, valider_texte, "observations")
  ))
}

registre9_depuis_payload <- function(payload) {
  if (!is.list(payload) || est_vide(payload$type_fiche)) {
    stop("Le payload du registre 9 doit porter `type_fiche`, l'un de : ",
         paste(SOMMIER_TYPES_REMARQUABLE, collapse = ", "), ".", call. = FALSE)
  }
  type <- valider_choix(payload$type_fiche, "type_fiche", SOMMIER_TYPES_REMARQUABLE)
  arguments <- payload[setdiff(names(payload), "type_fiche")]
  do.call(switch(
    type,
    arbre      = registre9_arbre,
    peuplement = registre9_peuplement,
    vestige    = registre9_vestige,
    espece     = registre9_espece,
    habitat    = registre9_habitat
  ), arguments)
}
