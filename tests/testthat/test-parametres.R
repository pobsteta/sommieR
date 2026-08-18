test_that("les listes de parametres sont depouillees de leurs noms", {
  # RPostgres refuse les parametres nommes (« `params` must not be named ») la
  # ou RPostgreSQL les tolere. Un vapply sur un vecteur de caracteres suffit a
  # en produire sans qu'on le veuille : le filet est teste ici.
  depouiller <- sommieR:::parametres
  expect_null(names(depouiller(list(a = 1, b = 2))))
  expect_null(names(depouiller(c(x = "1", y = "2"))))
  expect_equal(depouiller(list(a = 1, b = 2)), list(1, 2))
  expect_equal(depouiller(list()), list())
})

test_that("la validation d'une liste d'UUID ne nomme pas son resultat", {
  # C'est la source du defaut : vapply(USE.NAMES = TRUE par defaut sur du
  # caractere) nommait le vecteur par ses propres valeurs.
  uuids <- c(uuid_v4(), uuid_v4())
  valides <- vapply(uuids, sommieR:::valider_uuid, character(1),
                    nom = "ug_uuids", USE.NAMES = FALSE)
  expect_null(names(valides))
  expect_null(names(sommieR:::parametres(as.list(valides))))
})

test_that("ug_lire n'envoie jamais de parametres nommes au pilote", {
  # Regression : `vapply` sur un vecteur d'UUID nommait le resultat, et
  # RPostgres refusait la requete la ou RPostgreSQL passait. Le test simule
  # ici la stricte des pilotes, de sorte qu'il echoue meme sous un pilote
  # permissif - ou sans base du tout.
  vus <- list()
  testthat::local_mocked_bindings(
    dbGetQuery = function(conn, statement, ...) {
      args <- list(...)
      if (!is.null(args$params)) {
        vus[[length(vus) + 1L]] <<- args$params
        if (!is.null(names(args$params))) {
          stop("`params` must not be named.", call. = FALSE)
        }
      }
      data.frame()
    },
    .package = "DBI"
  )

  faux_con <- structure(list(), class = "DBIConnection")
  expect_silent(ug_lire(faux_con, ug_uuid = c(uuid_v4(), uuid_v4())))
  expect_silent(ug_lire(faux_con, foret_id = uuid_v4()))
  expect_silent(ug_lire(faux_con, ug_uuid = uuid_v4(), foret_id = uuid_v4()))

  expect_gt(length(vus), 0L)
  for (params in vus) {
    expect_null(names(params))
  }
})
