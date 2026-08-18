test_that("une chaine intacte est declaree valide", {
  r <- sommier_verifier_chaine(chaine_test(5L))
  expect_true(r$valide)
  expect_equal(r$n_entrees, 5L)
  expect_equal(r$seq_tete, 5)
  expect_equal(nrow(r$anomalies), 0L)
  expect_match(r$hash_tete, "^[0-9a-f]{64}$")
})

test_that("la verification passe par un export data.frame et JSON", {
  # Le cas d'usage annonce : un auditeur tiers verifie a partir d'un export,
  # sans acces a la base et sans faire confiance a l'expediteur.
  df <- entrees_en_data_frame(chaine_test(5L))
  expect_true(sommier_verifier_chaine(df)$valide)
})

test_that("une alteration du payload est detectee", {
  df <- entrees_en_data_frame(chaine_test(5L))
  df$payload[[3]] <- sub('"volume_m3":300', '"volume_m3":999', df$payload[[3]],
                         fixed = TRUE)
  r <- sommier_verifier_chaine(df)
  expect_false(r$valide)
  expect_equal(r$anomalies$type, "empreinte_invalide")
  expect_equal(r$anomalies$seq, 3)
})

test_that("un simple reordonnancement des cles ne casse pas la chaine", {
  # C'est toute la raison d'etre de la canonisation : JSONB reordonne les
  # cles au stockage, la chaine ne doit pas s'en trouver invalidee.
  df <- entrees_en_data_frame(chaine_test(3L))
  df$payload[[2]] <- jsonlite::toJSON(
    list(volume_m3 = 200, type_entree = "martelage",
         nature_coupe = "amelioration", exercice = 2026),
    auto_unbox = TRUE
  )
  expect_true(sommier_verifier_chaine(df)$valide)
})

test_that("une alteration de metadonnee est detectee", {
  df <- entrees_en_data_frame(chaine_test(5L))
  df$date_evenement[[2]] <- "2020-01-01"
  r <- sommier_verifier_chaine(df)
  expect_false(r$valide)
  expect_true("empreinte_invalide" %in% r$anomalies$type)
})

test_that("une entree retiree est detectee", {
  df <- entrees_en_data_frame(chaine_test(5L))
  r <- sommier_verifier_chaine(df[-3L, ])
  expect_false(r$valide)
  expect_true("sequence_manquante" %in% r$anomalies$type)
  expect_true("chainage_rompu" %in% r$anomalies$type)
})

test_that("une entree inseree est detectee", {
  df <- entrees_en_data_frame(chaine_test(5L))
  intruse <- df[3L, ]
  intruse$seq <- 6
  r <- sommier_verifier_chaine(rbind(df, intruse))
  expect_false(r$valide)
  expect_true("chainage_rompu" %in% r$anomalies$type)
})

test_that("une sequence dupliquee est detectee", {
  df <- entrees_en_data_frame(chaine_test(3L))
  df$seq[[3]] <- 2
  r <- sommier_verifier_chaine(df)
  expect_false(r$valide)
  expect_true("sequence_dupliquee" %in% r$anomalies$type)
})

test_that("une chaine tronquee par le debut est detectee", {
  df <- entrees_en_data_frame(chaine_test(5L))
  r <- sommier_verifier_chaine(df[-1L, ])
  expect_false(r$valide)
  expect_true("genese_invalide" %in% r$anomalies$type)
})

test_that("un fragment se verifie depuis une ancre connue", {
  ch <- chaine_test(5L)
  df <- entrees_en_data_frame(ch)
  r <- sommier_verifier_chaine(df[3:5, ], hash_prev_initial = ch[[2]]$hash)
  expect_true(r$valide)
})

test_that("l'ordre de livraison n'influe pas sur la verification", {
  df <- entrees_en_data_frame(chaine_test(5L))
  expect_true(sommier_verifier_chaine(df[c(4, 1, 5, 2, 3), ])$valide)
})

test_that("une anomalie isolee ne cascade pas sur toute la suite", {
  # Une seule alteration doit produire une seule anomalie : sinon le rapport
  # noierait l'entree fautive dans le bruit.
  df <- entrees_en_data_frame(chaine_test(6L))
  df$auteur[[3]] <- "pirate"
  r <- sommier_verifier_chaine(df)
  expect_equal(nrow(r$anomalies), 1L)
  expect_equal(r$anomalies$seq, 3)
})

test_that("melanger deux forets est refuse", {
  a <- entrees_en_data_frame(chaine_test(2L))
  b <- entrees_en_data_frame(
    sommier_chainer(list(entree_test(1L, foret_id = "99999999-8888-4777-8666-555555555555")))
  )
  expect_error(sommier_verifier_chaine(rbind(a, b)), "plusieurs forets")
})

test_that("le rapport s'imprime lisiblement", {
  expect_output(print(sommier_verifier_chaine(chaine_test(2L))), "chaine intacte")
  df <- entrees_en_data_frame(chaine_test(2L))
  df$auteur[[2]] <- "pirate"
  expect_output(print(sommier_verifier_chaine(df)), "anomalie")
})
