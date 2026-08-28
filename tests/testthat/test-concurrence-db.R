# Ce que le noyau affirme sans l'avoir jamais montre : le verrou consultatif
# de `sommier_ajouter()` empeche deux ecritures concurrentes de forker la
# chaine, et `UNIQUE (foret_id, seq)` rattrape le verrou s'il venait a manquer.
# Voir specs/brief_noyau-1_eprouver-ce-qui-tient.md.
#
# Ces tests n'engendrent aucun parallelisme : forker un processus R qui detient
# une connexion libpq est instable, et un test de concurrence intermittent ne
# demontre rien. La propriete qui porte la correction n'est pas « N processus
# ecrivent » mais « le verrou est exclusif, et tenu pendant toute la
# transaction » - et celle-la s'observe depuis une seconde connexion.

base_concurrence <- function() {
  con <- sauter_sans_base()
  withr::defer(DBI::dbDisconnect(con), envir = parent.frame())
  suppressMessages(sommier_init_schema(con))
  con
}

foret_ecrivable <- function(con) {
  foret <- foret_creer(con, paste0("Concurrence ", uuid_v4()), "communal",
                       surface_ha = 100)
  ug_creer(con, foret, "1", "2020-01-01")
  foret
}

coupe <- function(foret, volume) {
  sommier_entree(
    foret_id = foret, registre = 5L, date_evenement = "2026-01-01",
    auteur = "agent-01",
    payload = registre5_coupe("martelage", 2026, "amelioration", volume)
  )
}

test_that("le verrou de la foret est exclusif, et tenu jusqu'a la fin", {
  # La connexion B prend le verrou et le garde ; A borne son attente et ecrit.
  # A doit expirer sur le verrou - donc l'attendre au lieu de lire la tete -
  # puis reussir des que B relache. Retirer le `pg_advisory_xact_lock` de
  # `sommier_ajouter()` fait passer la premiere ecriture, et ce test echoue.
  a <- base_concurrence()
  b <- sauter_sans_base()
  withr::defer(DBI::dbDisconnect(b))
  foret <- foret_ecrivable(a)

  DBI::dbBegin(b)
  DBI::dbGetQuery(b, "SELECT pg_advisory_xact_lock(hashtext($1::text))",
                  params = list(foret))

  DBI::dbExecute(a, "SET lock_timeout = '800ms'")
  bloquee <- try(sommier_ajouter(a, coupe(foret, 10)), silent = TRUE)

  expect_s3_class(bloquee, "try-error")
  expect_match(conditionMessage(attr(bloquee, "condition")), "lock timeout")
  # Rien n'est passe : une ecriture refusee ne consomme pas de sequence.
  expect_equal(nrow(sommier_lire(a, foret)), 0L)

  # Le verrou est `xact` : il tombe avec la transaction de B, sans appel dedie.
  DBI::dbRollback(b)
  DBI::dbExecute(a, "SET lock_timeout = 0")

  expect_no_error(sommier_ajouter(a, coupe(foret, 10)))
  expect_equal(nrow(sommier_lire(a, foret)), 1L)
  expect_true(sommier_verifier(a, foret)$valide)
})

test_that("le verrou est relache des la transaction terminee", {
  # Un verrou qui survivrait a l'ecriture bloquerait la suivante : la
  # serialisation deviendrait un interblocage.
  a <- base_concurrence()
  b <- sauter_sans_base()
  withr::defer(DBI::dbDisconnect(b))
  foret <- foret_ecrivable(a)

  sommier_ajouter(a, coupe(foret, 10))

  pris <- DBI::dbGetQuery(
    b, "SELECT pg_try_advisory_lock(hashtext($1::text)) AS libre",
    params = list(foret)
  )$libre
  expect_true(pris)
  DBI::dbGetQuery(b, "SELECT pg_advisory_unlock(hashtext($1::text))",
                  params = list(foret))
})

test_that("deux forets differentes ne s'attendent pas", {
  # `hashtext()` peut entrer en collision, et deux forets partageraient alors
  # un verrou - sans consequence sur la correction. Encore faut-il que le cas
  # courant, lui, ne serialise pas tout le monde derriere une seule foret.
  a <- base_concurrence()
  b <- sauter_sans_base()
  withr::defer(DBI::dbDisconnect(b))
  une <- foret_ecrivable(a)
  autre <- foret_ecrivable(a)
  skip_if(
    DBI::dbGetQuery(a, "SELECT hashtext($1::text) = hashtext($2::text) AS pareil",
                    params = list(une, autre))$pareil,
    "Collision de hashtext entre les deux forets tirees."
  )

  DBI::dbBegin(b)
  DBI::dbGetQuery(b, "SELECT pg_advisory_xact_lock(hashtext($1::text))",
                  params = list(une))

  DBI::dbExecute(a, "SET lock_timeout = '800ms'")
  expect_no_error(sommier_ajouter(a, coupe(autre, 10)))

  DBI::dbRollback(b)
  DBI::dbExecute(a, "SET lock_timeout = 0")
})

test_that("la contrainte d'unicite rattrape un verrou manquant", {
  # Deux branches chainees depuis la meme tete : c'est exactement la fourche
  # qu'un verrou absent produirait. `UNIQUE (foret_id, seq)` est annonce comme
  # le filet de securite ; cette phrase n'engage a rien tant qu'on ne l'a pas
  # provoquee.
  con <- base_concurrence()
  foret <- foret_ecrivable(con)
  sommier_ajouter(con, coupe(foret, 10))

  tete <- DBI::dbGetQuery(
    con,
    "SELECT seq, encode(hash, 'hex') AS hash FROM entree_sommier
      WHERE foret_id = $1 ORDER BY seq DESC LIMIT 1",
    params = list(foret)
  )
  depuis <- as.numeric(tete$seq[[1L]]) + 1
  precedente <- empreinte_depuis_hex(tete$hash[[1L]])

  branche <- function(volume) {
    entrees_en_data_frame(
      sommier_chainer(list(coupe(foret, volume)), seq_depart = depuis,
                      hash_prev = precedente)
    )
  }

  expect_no_error(inserer_entrees(con, branche(20)))
  # La seconde branche passe par `transaction()`, comme le fait
  # `sommier_ajouter()` : un ordre qui echoue hors transaction laisse son
  # resultat ouvert cote pilote, et c'est l'appel suivant - quel qu'il soit -
  # qui herite du message de menage.
  refus <- try(transaction(con, inserer_entrees(con, branche(30))),
               silent = TRUE)

  expect_s3_class(refus, "try-error")
  expect_match(conditionMessage(attr(refus, "condition")),
               "entree_sommier_foret_id_seq_key")
  # La fourche n'a pas eu lieu : une seule branche est en base, et la chaine
  # se verifie encore.
  expect_equal(nrow(sommier_lire(con, foret)), 2L)
  expect_true(sommier_verifier(con, foret)$valide)
})

test_that("une transaction avortee ne laisse ni trou ni bruit de pilote", {
  # Le retour arriere tait le seul message de menage du pilote. Ce test veille
  # sur les deux moitiees de la promesse : plus d'avertissement, et la sequence
  # intacte - un `seq` consomme par un echec creerait un trou que la
  # verification signalerait comme une entree manquante.
  con <- base_concurrence()
  foret <- foret_ecrivable(con)
  sommier_ajouter(con, coupe(foret, 10))

  tete <- DBI::dbGetQuery(
    con,
    "SELECT seq, encode(hash, 'hex') AS hash FROM entree_sommier
      WHERE foret_id = $1 ORDER BY seq DESC LIMIT 1",
    params = list(foret)
  )
  doublon <- entrees_en_data_frame(
    sommier_chainer(list(coupe(foret, 20)),
                    seq_depart = as.numeric(tete$seq[[1L]]),
                    hash_prev = empreinte_depuis_hex(tete$hash[[1L]]))
  )

  expect_silent(
    expect_error(transaction(con, inserer_entrees(con, doublon)))
  )

  expect_no_error(sommier_ajouter(con, coupe(foret, 30)))
  entrees <- sommier_lire(con, foret)
  expect_equal(entrees$seq, seq_len(nrow(entrees)))
  expect_true(sommier_verifier(con, foret)$valide)
})

test_that("un argument refuse ne laisse pas la connexion sale", {
  # R evalue les arguments paresseusement : une validation ecrite DANS la liste
  # `params` d'un `dbExecute()` s'execute apres que le pilote a ouvert son
  # objet de resultat. L'appel echouait donc en laissant une requete morte
  # derriere lui, et c'est l'ordre suivant - quel qu'il fut, ailleurs dans le
  # programme - qui heritait de l'avertissement. Les validations precedent
  # desormais l'appel ; ce test veille a ce qu'elles y restent.
  con <- base_concurrence()
  foret <- foret_ecrivable(con)

  refus <- list(
    function() budget_definir(con, foret, 2026, "caisse_noire", 100),
    function() budget_definir(con, foret, 2026, "reboisement", -1),
    function() exercice_definir(con, foret, 1200, 10),
    function() ug_creer(con, foret, "2", "pas-une-date"),
    function() sommier_bilan_financier(con, "pas-un-uuid")
  )

  for (appel in refus) {
    expect_error(appel())
    # Le temoin est un ordre quelconque : s'il avertit, c'est que l'appel
    # precedent a laisse son resultat ouvert.
    expect_silent(DBI::dbGetQuery(con, "SELECT 1 AS temoin"))
  }
})

test_that("le retour arriere ne tait que le menage du pilote", {
  # Taire le bloc entier supprimerait le symptome et le signal ensemble : un
  # avertissement d'une autre nature, emis au meme endroit, doit passer.
  con <- base_concurrence()

  expect_warning(
    try(transaction(con, {
      warning("une alerte qui, elle, doit s'entendre")
      stop("echec provoque")
    }), silent = TRUE),
    "doit s'entendre"
  )
})
