#' Colonnes d'un sommier de travaux tenu sous tableur
#'
#' @description
#' Le format que lit [sommier_reprendre_travaux()] : une ligne par
#' intervention, une colonne par champ du payload `travaux` du registre 6
#' (voir [registre6_travaux()]), plus l'unite de gestion, la date et la
#' geometrie. C'est le tableau metier du suivi sylvicole, tel qu'un
#' gestionnaire le tient avant d'entrer dans le sommier.
#'
#' @details
#' Les en-tetes se lisent sans egard a la casse, aux accents, aux espaces ni
#' a la ponctuation : `Annee` (accentue ou non), `annee` et `ANNEE` designent
#' la meme colonne, `Montant (EUR)` vaut `montant_eur`. Quelques synonymes
#' usuels sont admis (colonne `alias`). Une colonne qui n'est pas dans ce
#' tableau fait refuser le fichier : une donnee ecartee sans le dire serait
#' perdue sans trace.
#'
#' Seule `annee` est obligatoire, et encore : elle se deduit de `date` quand
#' celle-ci est remplie. `nature_travaux` prend, a defaut, le libelle du code.
#'
#' @format Un `data.frame` : `colonne`, `alias` (synonymes admis, separes par
#'   une virgule), `description`.
#'
#' @seealso [sommier_reprendre_travaux()]
#'
#' @export
SOMMIER_COLONNES_TABLEUR_TRAVAUX <- data.frame(
  colonne = c("ug", "date", "annee", "code_travaux", "nature_travaux",
              "modalite", "essence_objectif", "localisation", "repere_plan",
              "quantite", "unite", "nb_plants", "provenance_plants",
              "montant_eur", "taux_reprise_pct", "execution", "intervenant",
              "prevu", "motif_ecart", "date_reception", "geometrie",
              "observations"),
  alias = c("unite_de_gestion, unite_gestion, parcelle", "date_realisation",
            "", "code", "nature, nature_des_travaux, libelle", "", "essence",
            "lieu", "repere", "surface, longueur", "", "plants",
            "provenance", "montant, cout, cout_eur, montant_ht",
            "reprise, taux_reprise, reprise_pct", "mode_execution",
            "entreprise", "prevu_au_document", "motif, motif_ecart_au_prevu",
            "reception", "wkt, geom", "remarques, commentaire, commentaires"),
  description = c(
    "Numero de l'unite de gestion ; vide hors unite (A50H).",
    "Date de realisation (AAAA-MM-JJ ou JJ/MM/AAAA).",
    "Annee de realisation ; deduite de `date` si vide.",
    "Code de SOMMIER_CODES_TRAVAUX.",
    "Libelle libre de l'A50J ; a defaut, celui du code.",
    "Modalite d'execution.",
    "Code de l'essence objectif.",
    "Localisation en clair, pour des travaux hors unite.",
    "Repere sur le plan.",
    "Quantite realisee.",
    "Unite de la quantite, l'une de celles du code.",
    "Nombre de plants.",
    "Provenance des plants.",
    "Montant en euros.",
    "Taux de reprise de l'A50J, en %.",
    "regie, entreprise ou autre.",
    "Entreprise ou equipe.",
    "prevu, reporte ou non prevu.",
    "Motif d'un ecart au prevu ; obligatoire hors prevu.",
    "Date de reception.",
    "Emprise en WKT (POINT, LINESTRING, POLYGON), dans le CRS `crs`.",
    "Observations libres."
  ),
  stringsAsFactors = FALSE
)

#' Reprise d'un sommier de travaux tenu sous tableur
#'
#' @description
#' Transcrit au registre 6 les interventions d'un tableur (CSV ou XLSX) au
#' format de [SOMMIER_COLONNES_TABLEUR_TRAVAUX] : une ligne, une entree
#' `travaux`, construite par [sommier_reprise()] et ecrite par
#' [sommier_reprendre()]. Code et geometrie entrent quand le tableur les
#' porte ; une intervention sans code reste une intervention, rangee "non
#' codee" au bilan.
#'
#' @details
#' **Une transcription, pas un constat.** Chaque entree porte la piece dont
#' elle sort, sans valeur par defaut : un nom de fichier ne dit ni qui tenait
#' le tableur ni sur quelle periode. Elle porte aussi un NDP d'au moins 1 (3
#' pour un `tableur`), et pour `date_saisie` l'instant de l'import. La date de
#' l'evenement est `date`, a defaut `date_reception`, a defaut le 1er janvier
#' de l'annee : un A50J ne donne souvent que l'annee.
#'
#' **L'unite de gestion** est celle dont le numero est en colonne `ug`, et
#' qui existait a la date de l'evenement. Sans numero, c'est celle qui
#' contient la geometrie ; sans l'une ni l'autre, l'intervention s'inscrit a
#' l'echelle de la foret (A50H), et `localisation` devrait le dire.
#'
#' **La geometrie** est un WKT simple : `POINT`, `LINESTRING` ou `POLYGON`
#' sans trou, de la forme que le code admet. Les multi-geometries sont
#' refusees, faute d'etre admises au registre : une plantation en trois
#' placeaux s'ecrit en trois lignes. Lire une geometrie demande `sf`.
#'
#' **Tout ou rien.** Chaque ligne est controlee avant toute ecriture : colonnes
#' connues, nombres et dates lisibles, code connu, unite du code, motif d'un
#' ecart au prevu, forme de la geometrie, unite de gestion connue. Une faute
#' fait refuser le fichier entier, avec la liste de toutes, ligne par ligne
#' (la ligne d'en-tete est la ligne 1).
#'
#' **Rejouable.** L'identifiant d'une entree se deduit de son contenu (foret,
#' unite, date, payload) : reimporter le meme tableur n'ecrit rien de plus,
#' et un tableur complete n'ecrit que ses lignes nouvelles. Deux lignes
#' identiques sont refusees comme un doublon. Une ligne corrigee dans le
#' tableur entre comme une ligne nouvelle : la rectification d'une entree
#' deja transcrite se fait par `corrige_id`, pas par reimport.
#'
#' Les nombres admettent la virgule decimale et les espaces de milliers ; les
#' valeurs fermees (`execution`, `prevu`) se lisent sans casse ni accents
#' (`Non prevu`, `Regie`, accentues ou non).
#'
#' @param con Connexion DBI.
#' @param foret_id UUID de la foret.
#' @param fichier Chemin du tableur : `.csv` (separateur `;`, `,` ou
#'   tabulation, UTF-8) ou `.xlsx` (paquet `readxl`).
#' @param auteur Compte qui transcrit.
#' @param source Piece dont la reprise est tiree ([reprise_source()]),
#'   obligatoire : d'ordinaire `tableur`, ou `base_gestionnaire` pour un
#'   extrait date d'une base tenue.
#' @param ndp NDP des entrees (>= 1) ; par defaut, celui de la source.
#' @param crs CRS des WKT de la colonne `geometrie` (EPSG) ; WGS84 par
#'   defaut.
#' @param feuille Feuille a lire d'un `.xlsx` (numero ou nom).
#'
#' @return Invisiblement, le compte rendu de [sommier_reprendre()], qui
#'   compte aussi `deja_presents`, les lignes deja transcrites.
#'
#' @examples
#' \dontrun{
#' sommier_reprendre_travaux(
#'   con, foret, "suivi_travaux.csv", auteur = "agent-01",
#'   source = reprise_source("tableur", "Suivi des travaux 2015-2025, CRPF")
#' )
#' }
#'
#' @seealso [SOMMIER_COLONNES_TABLEUR_TRAVAUX], [sommier_reprise()],
#'   [sommier_provenance()]
#'
#' @export
sommier_reprendre_travaux <- function(con, foret_id, fichier, auteur,
                                      source, ndp = NULL,
                                      crs = 4326, feuille = 1L) {
  foret_id <- valider_uuid(foret_id, "foret_id")
  fichier <- valider_texte(fichier, "fichier")
  auteur <- valider_texte(auteur, "auteur")
  if (!file.exists(fichier)) {
    stop("Fichier introuvable : ", fichier, call. = FALSE)
  }
  if (missing(source) || is.null(source)) {
    stop("`source` est obligatoire : une reprise cite la piece dont elle est ",
         "tiree (voir reprise_source()), sans quoi elle ne se distingue pas ",
         "d'une invention.", call. = FALSE)
  }
  source <- valider_reprise(source)
  t <- lire_tableur_travaux(fichier, feuille)
  if (nrow(t) == 0L) {
    stop("Le tableur ", basename(fichier), " ne porte aucune intervention.",
         call. = FALSE)
  }
  lignes <- as.integer(rownames(t))

  fautes <- character(0)
  faute <- function(i, msg) {
    fautes <<- c(fautes, paste0("ligne ", lignes[[i]], " : ", msg))
  }

  geometries <- geometries_tableur(t$geometrie, crs, faute)
  ug <- ug_lire(con, foret_id = foret_id)
  ug_geom <- if (any(!vapply(geometries$l93, is.null, logical(1)))) {
    DBI::dbGetQuery(
      con, "SELECT u.uuid::text AS uuid, ST_AsText(g.geom) AS wkt
              FROM ug u JOIN ug_geometrie g ON g.ug_uuid = u.uuid
             WHERE u.foret_id = $1 AND g.date_fin IS NULL",
      params = list(foret_id))
  }

  entrees <- vector("list", nrow(t))
  for (i in seq_len(nrow(t))) {
    x <- lapply(as.list(t[i, , drop = FALSE]),
                function(v) if (is.na(v)) NULL else v)
    entrees[i] <- list(tryCatch({
      date <- date_tableur(x$date, "date")
      reception <- date_tableur(x$date_reception, "date_reception")
      annee <- x$annee %||% (if (!is.null(date)) substr(date, 1L, 4L))
      if (is.null(annee)) {
        stop("ni annee ni date", call. = FALSE)
      }
      code <- if (!is.null(x$code_travaux)) toupper(x$code_travaux)
      date_evenement <- date %||% reception %||% paste0(annee, "-01-01")
      unite <- ug_du_tableur(x$ug, date_evenement, ug, geometries$l93[[i]],
                             ug_geom)
      payload <- registre6_travaux(
        annee = nombre_tableur(annee, "annee"),
        nature_travaux = x$nature_travaux %||% (if (!is.null(code))
          SOMMIER_CODES_TRAVAUX$libelle[SOMMIER_CODES_TRAVAUX$code == code]),
        localisation = x$localisation,
        repere_plan = x$repere_plan,
        quantite = nombre_tableur(x$quantite, "quantite"),
        unite = x$unite,
        nb_plants = nombre_tableur(x$nb_plants, "nb_plants"),
        provenance_plants = x$provenance_plants,
        montant_eur = nombre_tableur(x$montant_eur, "montant_eur"),
        taux_reprise_pct = nombre_tableur(x$taux_reprise_pct,
                                          "taux_reprise_pct"),
        observations = x$observations,
        type_entree = "travaux",
        code_travaux = code,
        modalite = x$modalite,
        essence_objectif = x$essence_objectif,
        execution = choix_tableur(x$execution),
        intervenant = x$intervenant,
        prevu = choix_tableur(x$prevu),
        motif_ecart = x$motif_ecart,
        date_reception = reception,
        geometrie = geometries$wgs84[[i]]
      )
      sommier_reprise(
        foret_id = foret_id, registre = 6L, date_evenement = date_evenement,
        auteur = auteur, payload = payload, source = source,
        ug_uuid = unite, ndp = ndp,
        id = uuid_de_contenu(list(foret_id, unite %||% "", date_evenement,
                                  payload))
      )
    }, error = function(e) {
      faute(i, conditionMessage(e))
      NULL
    }))
  }
  ids <- vapply(entrees, function(e) if (is.null(e)) NA_character_ else e$id,
                character(1))
  for (i in which(duplicated(ids) & !is.na(ids))) {
    faute(i, paste0("doublon de la ligne ", lignes[[match(ids[[i]], ids)]],
                    " (une observation les distinguerait)"))
  }
  if (length(fautes) > 0L) {
    stop("Reprise refusee, rien n'est ecrit :\n",
         paste0("- ", fautes, collapse = "\n"), call. = FALSE)
  }

  presents <- DBI::dbGetQuery(
    con, "SELECT id::text AS id FROM entree_sommier WHERE id = ANY($1::uuid[])",
    params = list(paste0("{", paste(ids, collapse = ","), "}"))
  )$id
  nouvelles <- entrees[!ids %in% presents]
  if (length(nouvelles) == 0L) {
    return(invisible(structure(
      list(foret_id = foret_id, n = 0L, deja_presents = length(presents)),
      class = "sommier_compte_rendu_reprise"
    )))
  }
  compte_rendu <- sommier_reprendre(con, nouvelles)
  compte_rendu$deja_presents <- length(presents)
  invisible(compte_rendu)
}

# ---------------------------------------------------------------------------

# Lit le tableur en texte, colonnes renommees sur le format. Les numeros de
# ligne (rownames) sont ceux du tableur, en-tete comprise : c'est ce que voit
# celui qui le corrige.
lire_tableur_travaux <- function(fichier, feuille = 1L) {
  extension <- tolower(sub("^.*\\.", "", basename(fichier)))
  brut <- if (extension %in% c("xlsx", "xls")) {
    if (!requireNamespace("readxl", quietly = TRUE)) {
      stop("Le paquet `readxl` est requis pour lire un tableur ", extension,
           " ; a defaut, l'enregistrer en CSV.", call. = FALSE)
    }
    as.data.frame(readxl::read_excel(fichier, sheet = feuille,
                                     col_types = "text", .name_repair = "minimal"),
                  stringsAsFactors = FALSE)
  } else if (extension %in% c("csv", "txt", "tsv")) {
    lire_csv_tableur(fichier)
  } else {
    stop("Format non reconnu (", extension, ") : CSV ou XLSX.", call. = FALSE)
  }
  noms <- nom_colonne_tableur(names(brut))
  inconnues <- names(brut)[is.na(noms)]
  if (length(inconnues) > 0L) {
    stop("Colonne(s) inconnue(s) dans ", basename(fichier), " : ",
         paste(inconnues, collapse = ", "), ". Les colonnes admises sont ",
         paste(SOMMIER_COLONNES_TABLEUR_TRAVAUX$colonne, collapse = ", "),
         " (voir SOMMIER_COLONNES_TABLEUR_TRAVAUX).", call. = FALSE)
  }
  doubles <- unique(noms[duplicated(noms)])
  if (length(doubles) > 0L) {
    stop("Colonne(s) en double dans ", basename(fichier), " : ",
         paste(doubles, collapse = ", "), ".", call. = FALSE)
  }
  names(brut) <- noms
  brut[] <- lapply(brut, function(v) {
    v <- trimws(gsub("\u00a0", " ", as.character(v)))
    v[!is.na(v) & !nzchar(v)] <- NA_character_
    v
  })
  rownames(brut) <- seq_len(nrow(brut)) + 1L
  # Les lignes vides d'un tableur ne sont pas des interventions.
  pleines <- rowSums(!is.na(brut)) > 0L
  brut[pleines, , drop = FALSE]
}

lire_csv_tableur <- function(fichier) {
  entete <- readLines(fichier, n = 1L, warn = FALSE, encoding = "UTF-8")
  comptes <- vapply(c(";", ",", "\t"), function(s) {
    lengths(regmatches(entete, gregexpr(s, entete, fixed = TRUE)))
  }, numeric(1))
  utils::read.table(
    fichier, sep = names(which.max(comptes)), header = TRUE,
    colClasses = "character", quote = "\"", fileEncoding = "UTF-8-BOM",
    check.names = FALSE, na.strings = character(0), comment.char = "",
    blank.lines.skip = FALSE, strip.white = TRUE
  )
}

# "Montant (EUR)" -> "montant" -> "montant_eur" ; NA si inconnue.
nom_colonne_tableur <- function(x) {
  x <- normaliser_tableur(x)
  admis <- SOMMIER_COLONNES_TABLEUR_TRAVAUX
  table <- c(stats::setNames(admis$colonne, admis$colonne),
             unlist(lapply(seq_len(nrow(admis)), function(i) {
               a <- alternatives(admis$alias[[i]])
               stats::setNames(rep(admis$colonne[[i]], length(a)), a)
             })))
  unname(table[x])
}

# Sans casse, sans accents, ponctuation et espaces reduits a "_".
normaliser_tableur <- function(x) {
  x <- chartr(
    paste0("\u00e0\u00e2\u00e4\u00e9\u00e8\u00ea\u00eb\u00ee\u00ef\u00f4",
           "\u00f6\u00f9\u00fb\u00fc\u00e7\u00c0\u00c2\u00c4\u00c9\u00c8",
           "\u00ca\u00cb\u00ce\u00cf\u00d4\u00d6\u00d9\u00db\u00dc\u00c7"),
    "aaaeeeeiioouuucAAAEEEEIIOOUUUC", enc2utf8(as.character(x)))
  x <- tolower(gsub("\u0153", "oe", x))
  x <- gsub("[^a-z0-9]+", "_", x)
  gsub("^_+|_+$", "", x)
}

choix_tableur <- function(x) {
  if (is.null(x)) NULL else normaliser_tableur(x)
}

# "1 050,5" -> 1050.5 ; NULL si vide, erreur si illisible.
nombre_tableur <- function(x, nom) {
  if (is.null(x)) return(NULL)
  propre <- gsub("[ \u202f]", "", sub(",", ".", x, fixed = TRUE))
  propre <- sub("\\s*(\u20ac|%)$", "", propre)
  valeur <- suppressWarnings(as.numeric(propre))
  if (is.na(valeur)) {
    stop("`", nom, "` n'est pas un nombre (", x, ")", call. = FALSE)
  }
  valeur
}

# AAAA-MM-JJ, JJ/MM/AAAA, ou le numero de serie d'Excel lu en texte.
date_tableur <- function(x, nom) {
  if (is.null(x)) return(NULL)
  if (grepl("^\\d{4}-\\d{2}-\\d{2}", x)) {
    d <- as.Date(substr(x, 1L, 10L), format = "%Y-%m-%d")
  } else if (grepl("^\\d{1,2}/\\d{1,2}/\\d{4}$", x)) {
    d <- as.Date(x, format = "%d/%m/%Y")
  } else if (grepl("^\\d{5}(\\.0+)?$", x)) {
    d <- as.Date(as.numeric(x), origin = "1899-12-30")
  } else {
    d <- NA
  }
  if (is.na(d)) {
    stop("`", nom, "` n'est pas une date lisible (", x, ")", call. = FALSE)
  }
  format(d, "%Y-%m-%d")
}

# L'unite d'une ligne : son numero, a la date de l'evenement ; a defaut, celle
# qui contient sa geometrie ; a defaut, aucune.
ug_du_tableur <- function(numero, date, ug, geom_l93, ug_geom) {
  if (!is.null(numero)) {
    numero <- sub("\\.0+$", "", numero)
    ok <- ug$numero_affichage == numero &
      as.character(ug$date_debut) <= date &
      (is.na(ug$date_fin) | as.character(ug$date_fin) > date)
    if (!any(ok)) {
      stop("unite de gestion ", numero, " inconnue de la foret au ", date,
           call. = FALSE)
    }
    return(ug$uuid[ok][[1L]])
  }
  if (is.null(geom_l93) || is.null(ug_geom) || nrow(ug_geom) == 0L) {
    return(NULL)
  }
  ug_des_geometries(sf::st_sf(geometry = geom_l93), ug_geom)[[1L]]
}

# Les WKT d'une colonne : en WGS84 pour le payload, en Lambert-93 pour trouver
# l'unite. Les fautes sont rapportees a leur ligne.
geometries_tableur <- function(wkt, crs, faute) {
  n <- length(wkt)
  res <- list(wgs84 = vector("list", n), l93 = vector("list", n))
  if (is.null(wkt) || all(is.na(wkt))) return(res)
  if (!requireNamespace("sf", quietly = TRUE)) {
    stop("Le paquet `sf` est requis pour lire la colonne `geometrie`.",
         call. = FALSE)
  }
  for (i in which(!is.na(wkt))) {
    g <- tryCatch(sf::st_as_sfc(wkt[[i]], crs = crs),
                  error = function(e) NULL)
    if (is.null(g) || length(g) != 1L || sf::st_is_empty(g)) {
      faute(i, paste0("geometrie illisible (", substr(wkt[[i]], 1L, 40L), ")"))
      next
    }
    type <- as.character(sf::st_geometry_type(g))
    if (!type %in% c("POINT", "LINESTRING", "POLYGON")) {
      faute(i, paste0("geometrie ", type, " non admise : une partie par ligne"))
      next
    }
    if (type == "POLYGON" && length(g[[1L]]) > 1L) {
      faute(i, "polygone a trou non admis")
      next
    }
    res$wgs84[i] <- geometries_wgs84(g)
    res$l93[i] <- list(sf::st_transform(g, 2154))
  }
  res
}

# Un UUID tire du contenu : la meme ligne donne la meme entree, et la
# reimporter n'ecrit rien. Version 5 (nom), variante RFC 4122.
uuid_de_contenu <- function(x) {
  octets <- as.integer(openssl::sha256(charToRaw(jcs(x))))[1:16]
  octets[7L] <- bitwOr(bitwAnd(octets[7L], 0x0f), 0x50)
  octets[9L] <- bitwOr(bitwAnd(octets[9L], 0x3f), 0x80)
  hex <- sprintf("%02x", octets)
  paste0(paste0(hex[1:4], collapse = ""), "-", paste0(hex[5:6], collapse = ""),
         "-", paste0(hex[7:8], collapse = ""), "-",
         paste0(hex[9:10], collapse = ""), "-",
         paste0(hex[11:16], collapse = ""))
}
