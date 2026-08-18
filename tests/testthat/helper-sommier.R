# Foret de reference des tests. Fixe, pour que les empreintes attendues le
# soient aussi.
FORET_TEST <- "3f2b1c4d-5e6f-4a7b-8c9d-0e1f2a3b4c5d"
UG_TEST <- "11111111-2222-4333-8444-555555555555"

# Entree deterministe : ni horloge ni alea, sinon les empreintes changeraient
# a chaque execution et les tests ne prouveraient rien.
entree_test <- function(i = 1L,
                        registre = 5L,
                        payload = NULL,
                        foret_id = FORET_TEST,
                        ug_uuid = NULL,
                        ...) {
  if (is.null(payload)) {
    payload <- if (registre == 5L) {
      registre5_coupe("martelage", 2026, "amelioration", volume_m3 = 100 * i)
    } else {
      registre6_travaux(2026, "degagement")
    }
  }
  sommier_entree(
    foret_id = foret_id,
    registre = registre,
    date_evenement = "2026-03-01",
    auteur = "agent-01",
    payload = payload,
    ug_uuid = ug_uuid,
    date_saisie = "2026-08-18T10:00:00Z",
    id = sprintf("aaaaaaaa-bbbb-4ccc-8ddd-%012d", i),
    ...
  )
}

chaine_test <- function(n = 5L, ...) {
  sommier_chainer(lapply(seq_len(n), function(i) entree_test(i, ...)))
}

# Connexion PostgreSQL de test, ou NULL. Les tests de base sont ignores plutot
# qu'echoues lorsqu'aucune base n'est joignable : le noyau du package, lui, se
# teste entierement hors base.
connexion_test <- function() {
  dbname <- Sys.getenv("SOMMIER_TEST_DB", "")
  if (dbname == "") {
    return(NULL)
  }
  # RPostgres est le pilote de reference ; RPostgreSQL sert de repli, ce qui
  # verifie au passage que la couche d'acces ne depend d'aucune extension
  # propre a un pilote.
  pilote <- if (requireNamespace("RPostgres", quietly = TRUE)) {
    RPostgres::Postgres()
  } else if (requireNamespace("RPostgreSQL", quietly = TRUE)) {
    RPostgreSQL::PostgreSQL()
  } else {
    return(NULL)
  }
  con <- try(
    DBI::dbConnect(
      pilote,
      dbname = dbname,
      host   = Sys.getenv("SOMMIER_TEST_HOST", "localhost"),
      port   = as.integer(Sys.getenv("SOMMIER_TEST_PORT", "5432")),
      user   = Sys.getenv("SOMMIER_TEST_USER", "postgres"),
      password = Sys.getenv("SOMMIER_TEST_PASSWORD", "")
    ),
    silent = TRUE
  )
  if (inherits(con, "try-error")) NULL else con
}

sauter_sans_base <- function() {
  con <- connexion_test()
  if (is.null(con)) {
    testthat::skip("Aucune base PostgreSQL de test (definir SOMMIER_TEST_DB).")
  }
  con
}
