# La reprise d'un sommier de travaux tenu sous tableur : le format lu, la
# transcription (NDP, source, date de saisie), le tout ou rien et le rejeu.

fixture <- function(nom) test_path("fixtures", nom)

# La piece : un tableur, cite par ce qui permet de le retrouver.
crpf <- reprise_source("tableur", "Suivi des travaux 2015-2021, tableur du CRPF",
                       detenteur = "CRPF")

# Un tableur ecrit pour le test, en CSV a points-virgules.
tableur <- function(lignes, entete = paste(
  "UG;Ann\u00e9e;Code;Nature;Quantit\u00e9;Unit\u00e9;Pr\u00e9vu;",
  "Motif \u00e9cart;G\u00e9om\u00e9trie", sep = "")) {
  chemin <- withr::local_tempfile(fileext = ".csv", .local_envir = parent.frame())
  writeLines(enc2utf8(c(entete, lignes)), chemin, useBytes = TRUE)
  chemin
}

test_that("les en-tetes se lisent sans casse, accents ni ponctuation", {
  expect_equal(
    nom_colonne_tableur(c("Ann\u00e9e", "ANNEE", "Montant (\u20ac)",
                          "Taux reprise (%)", "Nature des travaux",
                          "G\u00e9om\u00e9trie", "Unit\u00e9",
                          "Unit\u00e9 de gestion", "N\u00b0 ligne")),
    c("annee", "annee", "montant_eur", "taux_reprise_pct", "nature_travaux",
      "geometrie", "unite", "ug", NA)
  )
  # Chaque alias designe une seule colonne : sinon le renommage dependrait
  # de l'ordre du tableau.
  alias <- unlist(lapply(SOMMIER_COLONNES_TABLEUR_TRAVAUX$alias, alternatives))
  expect_false(any(duplicated(c(SOMMIER_COLONNES_TABLEUR_TRAVAUX$colonne,
                                alias))))
})

test_that("nombres et dates se lisent comme un tableur francais les ecrit", {
  expect_equal(nombre_tableur("4 800,50", "x"), 4800.5)
  expect_equal(nombre_tableur("1\u202f050", "x"), 1050)
  expect_null(nombre_tableur(NULL, "x"))
  expect_error(nombre_tableur("environ 3", "quantite"), "quantite")
  expect_equal(date_tableur("15/11/2018", "d"), "2018-11-15")
  expect_equal(date_tableur("2018-11-15", "d"), "2018-11-15")
  expect_equal(date_tableur("43419", "d"), "2018-11-15")
  expect_error(date_tableur("novembre 2018", "date"), "date")
  expect_equal(choix_tableur("Non pr\u00e9vu"), "non_prevu")
  expect_equal(choix_tableur("R\u00e9gie"), "regie")
})

test_that("l'identifiant d'une ligne se tire de son contenu", {
  a <- uuid_de_contenu(list("x", 1, list(b = "c")))
  expect_match(a, MOTIF_UUID)
  expect_equal(substr(a, 15L, 15L), "5")
  expect_identical(a, uuid_de_contenu(list("x", 1, list(b = "c"))))
  expect_false(identical(a, uuid_de_contenu(list("x", 2, list(b = "c")))))
})

test_that("une colonne inconnue fait refuser le tableur", {
  chemin <- tableur("12;2019;DG;D\u00e9gagement;1;ha;;;",
                    entete = paste0("UG;Ann\u00e9e;Code;Nature;Quantit\u00e9;",
                                    "Unit\u00e9;N\u00b0;Visa;Geom"))
  expect_error(lire_tableur_travaux(chemin), "inconnue.*Visa")
})

# ---------------------------------------------------------------------------

base_reprise_travaux <- function(env = parent.frame()) {
  con <- sauter_sans_base()
  withr::defer(DBI::dbDisconnect(con), envir = env)
  sommier_init_schema(con)
  con
}

# Les unites 12 et 13 de la fixture, 300 x 200 m cote a cote.
foret_reprise_travaux <- function(con) {
  foret <- foret_creer(con, paste0("Foret reprise travaux-",
                                   substr(uuid_v4(), 1L, 8L)), "communal")
  ug <- c("12" = ug_creer(con, foret, "12", "2010-01-01"),
          "13" = ug_creer(con, foret, "13", "2010-01-01"))
  for (k in seq_along(ug)) {
    x0 <- 600000 + 300 * (k - 1L)
    DBI::dbExecute(con, sprintf(
      "INSERT INTO ug_geometrie (ug_uuid, version, geom, source, date_debut)
       VALUES ($1, 1, ST_Multi(ST_GeomFromText('POLYGON((%1$d 6700000,
         %2$d 6700000, %2$d 6700200, %1$d 6700200, %1$d 6700000))', 2154)),
         'test', '2010-01-01')", x0, x0 + 300L), params = list(ug[[k]]))
  }
  list(foret = foret, ug = ug)
}

entrees_r6 <- function(con, foret) {
  DBI::dbGetQuery(
    con, "SELECT id::text AS id, ug_uuid::text AS ug_uuid, ndp,
                 date_evenement::text AS date_evenement, date_saisie, payload
            FROM entree_sommier WHERE foret_id = $1 AND registre = 6
           ORDER BY seq", params = list(foret))
}

test_that("le tableau metier entre en transcription, code et geometrie compris", {
  skip_if_not_installed("sf")
  con <- base_reprise_travaux()
  f <- foret_reprise_travaux(con)
  avant <- Sys.time() - 1

  cr <- sommier_reprendre_travaux(con, f$foret, fixture("travaux-tableur.csv"),
                                  auteur = "agent-01", source = crpf)
  expect_s3_class(cr, "sommier_compte_rendu_reprise")
  expect_equal(cr$n, 6L)
  expect_equal(cr$deja_presents, 0L)
  expect_equal(cr$pieces$source, "tableur")
  expect_equal(cr$pieces$ndp, 3)
  expect_match(cr$pieces$reference, "tableur du CRPF")

  e <- entrees_r6(con, f$foret)
  expect_equal(nrow(e), 6L)
  expect_true(all(e$ndp == 3))
  # Une transcription n'est jamais antidatee : saisie a l'instant de l'import,
  # evenement dans le passe.
  expect_true(all(as.POSIXct(e$date_saisie) >= avant))
  expect_equal(e$date_evenement,
               c("2018-11-15", "2019-01-01", "2018-01-01", "2020-01-01",
                 "2015-01-01", "2021-01-01"))
  p <- lapply(e$payload, jsonlite::fromJSON, simplifyVector = FALSE)
  # Chaque payload se relit par le registre, bloc de reprise compris.
  for (x in p) expect_silent(valider_payload(6L, x))

  # Le numero d'unite fait foi ; a defaut, la geometrie ; a defaut, la foret.
  expect_equal(e$ug_uuid, unname(c(f$ug[["12"]], f$ug[["12"]], f$ug[["12"]],
                                   f$ug[["12"]], f$ug[["13"]], NA)))
  expect_equal(vapply(p, function(x) x$code_travaux %||% NA_character_,
                      character(1)),
               c("PL", "DG", "PG", "RG", NA, "DS"))
  expect_equal(p[[1L]]$geometrie$type, "Polygon")
  expect_equal(p[[3L]]$geometrie$type, "LineString")
  expect_equal(p[[4L]]$geometrie$type, "Point")
  expect_equal(p[[1L]]$montant_eur, 4800)
  expect_equal(p[[1L]]$nb_plants, 1050)
  expect_equal(p[[1L]]$quantite, 1.75)
  expect_equal(p[[1L]]$taux_reprise_pct, 85)
  expect_equal(p[[1L]]$execution, "entreprise")
  expect_equal(p[[1L]]$date_reception, "2018-12-01")
  expect_equal(p[[3L]]$prevu, "non_prevu")
  expect_equal(p[[4L]]$prevu, "reporte")
  expect_equal(p[[6L]]$localisation, "Route foresti\u00e8re de la Combe")

  # Les vues et la provenance le disent.
  prov <- sommier_provenance(con, f$foret)
  expect_equal(prov$n_transcrit[prov$registre == 6], 6)
  bilan <- sommier_bilan_travaux(con, f$foret)
  expect_true(nrow(bilan$cout) > 0L)
})

test_that("reimporter le meme tableur, en CSV ou en XLSX, n'ecrit rien", {
  skip_if_not_installed("sf")
  con <- base_reprise_travaux()
  f <- foret_reprise_travaux(con)
  sommier_reprendre_travaux(con, f$foret, fixture("travaux-tableur.csv"),
                            auteur = "agent-01", source = crpf)
  cr <- sommier_reprendre_travaux(con, f$foret,
                                  fixture("travaux-tableur.csv"),
                                  auteur = "agent-01", source = crpf)
  expect_equal(cr$n, 0L)
  expect_equal(cr$deja_presents, 6L)
  expect_output(print(cr), "deja la")

  skip_if_not_installed("readxl")
  # Le meme tableau enregistre en XLSX : dates en numero de serie, nombres
  # en nombres. Les lignes sont les memes, donc les entrees aussi.
  cr <- sommier_reprendre_travaux(con, f$foret,
                                  fixture("travaux-tableur.xlsx"),
                                  auteur = "agent-01", source = crpf)
  expect_equal(cr$deja_presents, 6L)
  expect_equal(nrow(entrees_r6(con, f$foret)), 6L)

  # Une ligne ajoutee au tableur entre seule.
  lignes <- readLines(fixture("travaux-tableur.csv"), encoding = "UTF-8")
  chemin <- withr::local_tempfile(fileext = ".csv")
  writeLines(c(lignes[lignes != ""],
               "13;;2024;DG;D\u00e9gagement;;;;2;ha;;;800;;R\u00e9gie;;Pr\u00e9vu;;;;"),
             chemin, useBytes = TRUE)
  cr <- sommier_reprendre_travaux(con, f$foret, chemin, auteur = "agent-01",
                                  source = crpf)
  expect_equal(cr$n, 1L)
  expect_equal(cr$deja_presents, 6L)
})

test_that("une ligne fautive fait refuser tout le tableur, fautes listees", {
  skip_if_not_installed("sf")
  con <- base_reprise_travaux()
  f <- foret_reprise_travaux(con)
  chemin <- tableur(c(
    "12;2019;DG;D\u00e9gagement;1;ha;Pr\u00e9vu;;",
    "12;2019;XX;Inconnu;1;ha;;;",
    "12;2019;DG;D\u00e9gagement;1;ha;Non pr\u00e9vu;;",
    "12;2018;PG;Cl\u00f4ture;300;m;;;POLYGON((1.6749 47.3932, 1.6775 47.3932, 1.6775 47.3941, 1.6749 47.3932))",
    "99;2019;DG;D\u00e9gagement;1;ha;;;",
    "12;2019;PL;Plantation;1;ha;;;MULTIPOINT((1.67 47.39), (1.68 47.39))",
    "12;2019;DG;D\u00e9gagement;1;m;;;",
    "12;2019;DG;D\u00e9gagement;1;ha;Pr\u00e9vu;;"
  ))
  err <- tryCatch(sommier_reprendre_travaux(con, f$foret, chemin,
                                            auteur = "agent-01", source = crpf),
                  error = conditionMessage)
  expect_match(err, "rien n'est ecrit")
  expect_match(err, "ligne 3 : .*code_travaux")
  expect_match(err, "ligne 4 : .*motif_ecart")
  expect_match(err, "ligne 5 : ")
  expect_match(err, "ligne 6 : unite de gestion 99")
  expect_match(err, "ligne 7 : geometrie MULTIPOINT")
  expect_match(err, "ligne 8 : .*en m")
  expect_match(err, "ligne 9 : doublon de la ligne 2")
  expect_false(grepl("ligne 2 :", err))
  expect_equal(nrow(entrees_r6(con, f$foret)), 0L)
})

test_that("la source se cite, et le NDP ne descend pas a 0", {
  con <- base_reprise_travaux()
  f <- foret_reprise_travaux(con)
  chemin <- tableur("12;2019;DG;D\u00e9gagement;1;ha;Pr\u00e9vu;;")
  piece <- reprise_source("base_gestionnaire", "Export ONF des travaux, 2025")
  # Un nom de fichier ne cite pas une piece : pas de source par defaut.
  expect_error(sommier_reprendre_travaux(con, f$foret, chemin, "agent-01"),
               "source")
  expect_error(sommier_reprendre_travaux(con, f$foret, chemin, "agent-01",
                                         source = piece, ndp = 0),
               "NDP 0")
  cr <- sommier_reprendre_travaux(con, f$foret, chemin, "agent-01",
                                  source = piece)
  expect_equal(cr$pieces$ndp, 2)
  expect_equal(cr$pieces$reference, "Export ONF des travaux, 2025")
  expect_error(sommier_reprendre_travaux(con, f$foret, chemin, "agent-01",
                                         source = list(source = "tableur")),
               "reference")
})
