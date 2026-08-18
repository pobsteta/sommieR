#' Types d'entree du registre 3 (droits et concessions)
#' @export
SOMMIER_TYPES_DROIT <- c(
  "concession", "bail_chasse", "bail_peche", "droit_usage", "affouage",
  "convention"
)

#' Payload du registre 3 - droits et concessions (imprime A50C)
#'
#' @description
#' Une concession, un bail, un droit d'usage ou une convention. L'imprime
#' A50C releve le numero, la nature, le titulaire, les dates de depart et
#' d'expiration.
#'
#' @details
#' **Donnees personnelles.** `titulaire` designe souvent une personne
#' physique. Comme au registre 7, le champ est facultatif et ne doit etre
#' renseigne que lorsqu'il est necessaire : une entree de sommier ne s'efface
#' pas. `v_droit` ne l'expose pas.
#'
#' L'affouage, propre a la foret communale, se saisit avec
#' [registre3_affouage()], qui porte les champs qui lui sont propres.
#'
#' @param type_entree L'un de [SOMMIER_TYPES_DROIT].
#' @param nature Nature du droit ou de la concession.
#' @param date_debut Date de prise d'effet.
#' @param numero Numero d'ordre porte sur l'imprime (facultatif).
#' @param titulaire Titulaire (facultatif). Voir la note sur les donnees
#'   personnelles.
#' @param date_expiration Date d'expiration (facultatif : un droit d'usage
#'   peut etre perpetuel).
#' @param redevance_eur Redevance annuelle (facultatif).
#' @param surface_ha Surface concernee (facultatif).
#' @param observations Observations libres (facultatif).
#'
#' @return Une liste nommee, prete a etre passee a [sommier_entree()].
#'
#' @examples
#' registre3_droit(
#'   type_entree = "bail_chasse", nature = "Location de chasse",
#'   numero = "12", date_debut = "2024-04-01", date_expiration = "2033-03-31",
#'   redevance_eur = 3200
#' )
#'
#' @export
registre3_droit <- function(type_entree,
                            nature,
                            date_debut,
                            numero = NULL,
                            titulaire = NULL,
                            date_expiration = NULL,
                            redevance_eur = NULL,
                            surface_ha = NULL,
                            observations = NULL) {
  type_entree <- valider_choix(type_entree, "type_entree", SOMMIER_TYPES_DROIT)
  if (identical(type_entree, "affouage")) {
    stop("L'affouage se saisit avec registre3_affouage(), qui porte le role, ",
         "les garants et la taxe.", call. = FALSE)
  }
  date_debut <- format_date(date_debut, "date_debut")
  date_expiration <- if (est_vide(date_expiration)) {
    NULL
  } else {
    format_date(date_expiration, "date_expiration")
  }
  # Une expiration anterieure au depart rendrait le droit inexistant des sa
  # constitution : c'est une inversion de saisie.
  if (!is.null(date_expiration) && date_expiration < date_debut) {
    stop("`date_expiration` (", date_expiration, ") precede `date_debut` (",
         date_debut, ").", call. = FALSE)
  }

  compacter(list(
    type_entree     = type_entree,
    nature          = valider_texte(nature, "nature"),
    numero          = si_present(numero, valider_texte, "numero"),
    titulaire       = si_present(titulaire, valider_texte, "titulaire"),
    date_debut      = date_debut,
    date_expiration = date_expiration,
    redevance_eur   = si_present(redevance_eur, valider_nombre,
                                 "redevance_eur", min = 0),
    surface_ha      = si_present(surface_ha, valider_nombre, "surface_ha", min = 0),
    observations    = si_present(observations, valider_texte, "observations")
  ))
}

#' Payload du registre 3 - affouage
#'
#' @description
#' Une campagne d'affouage, propre a la foret communale. Le brief en fait un
#' sous-registre du registre 3 : role des affouagistes, garants, taxe.
#'
#' @details
#' Les garants sont les trois habitants qui repondent de la bonne execution
#' de l'affouage devant la commune ; l'article L243-2 du code forestier en
#' prevoit trois, mais le champ n'en impose pas le nombre - un role incomplet
#' se constate, il ne se refuse pas.
#'
#' @param campagne Campagne d'affouage, au format `"AAAA-AAAA"`.
#' @param nb_affouagistes Nombre d'affouagistes inscrits au role.
#' @param volume_m3 Volume delivre (facultatif).
#' @param taxe_eur Taxe d'affouage par part (facultatif).
#' @param garants Noms des garants (facultatif). Donnee personnelle.
#' @param mode_partage `"par_feu"`, `"par_habitant"` ou `"par_part"`
#'   (facultatif).
#' @param observations Observations libres (facultatif).
#'
#' @return Une liste nommee, prete a etre passee a [sommier_entree()].
#'
#' @examples
#' registre3_affouage(
#'   campagne = "2025-2026", nb_affouagistes = 42, volume_m3 = 310,
#'   taxe_eur = 45, mode_partage = "par_feu"
#' )
#'
#' @export
registre3_affouage <- function(campagne,
                               nb_affouagistes,
                               volume_m3 = NULL,
                               taxe_eur = NULL,
                               garants = NULL,
                               mode_partage = NULL,
                               observations = NULL) {
  compacter(list(
    type_entree     = "affouage",
    nature          = "Affouage",
    campagne        = valider_saison(campagne),
    nb_affouagistes = valider_entier(nb_affouagistes, "nb_affouagistes", min = 0),
    volume_m3       = si_present(volume_m3, valider_nombre, "volume_m3", min = 0),
    taxe_eur        = si_present(taxe_eur, valider_nombre, "taxe_eur", min = 0),
    garants         = valider_liste_texte(garants, "garants"),
    mode_partage    = si_present(mode_partage, valider_choix, "mode_partage",
                                 choix = c("par_feu", "par_habitant", "par_part")),
    observations    = si_present(observations, valider_texte, "observations")
  ))
}

# Le registre 3 couvre deux constructeurs : la discriminante voyage dans le
# payload, comme au registre 8.
registre3_depuis_payload <- function(payload) {
  if (!is.list(payload) || est_vide(payload$type_entree)) {
    stop("Le payload du registre 3 doit porter `type_entree`, l'un de : ",
         paste(SOMMIER_TYPES_DROIT, collapse = ", "), ".", call. = FALSE)
  }
  type <- valider_choix(payload$type_entree, "type_entree", SOMMIER_TYPES_DROIT)
  arguments <- payload[setdiff(names(payload), "type_entree")]
  if (type == "affouage") {
    arguments$nature <- NULL      # impose par le constructeur
    return(do.call(registre3_affouage, arguments))
  }
  arguments$type_entree <- type
  do.call(registre3_droit, arguments)
}
