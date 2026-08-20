test_that("une entree se construit et n'est pas chainee d'emblee", {
  # La position dans la chaine est une propriete du registre au moment de
  # l'ecriture, pas une propriete de l'entree.
  e <- entree_test(1L)
  expect_s3_class(e, "sommier_entree")
  expect_true(is.na(e$seq))
  expect_null(e$hash)
  expect_null(e$hash_prev)
  expect_equal(e$ndp, 0)              # saisie terrain = NDP 0 par defaut
  # La version vient de la table, non d'une constante recopiee : la relever
  # ici obligerait a modifier le test a chaque evolution de schema, ce qui en
  # ferait un miroir plutot qu'un controle.
  expect_equal(e$schema_version, SOMMIER_SCHEMA_VERSIONS[["5"]])
  expect_match(e$schema_version, "^r5-")
})

test_that("l'echelle d'ancrage du registre est imposee", {
  # Le registre 6 est mixte : les deux ancrages sont admis.
  expect_silent(entree_test(1L, registre = 6L))
  expect_silent(entree_test(1L, registre = 6L, ug_uuid = UG_TEST))

  # Le registre 7 est a l'echelle de la foret : une comptabilite ne se
  # rattache pas a une parcelle.
  compta <- registre7_ecriture("bois_sur_pied", 2026, 100)
  expect_silent(sommier_entree(FORET_TEST, 7L, "2026-03-01", "a1", compta))
  expect_error(
    sommier_entree(FORET_TEST, 7L, "2026-03-01", "a1", compta, ug_uuid = UG_TEST),
    "echelle de la foret"
  )
})

test_that("chaque registre declare une echelle connue", {
  # La contrainte de `sommier_entree()` se lit dans SOMMIER_REGISTRES : les
  # deux doivent rester d'accord.
  expect_true(all(SOMMIER_REGISTRES$echelle %in% c("foret", "ug", "mixte")))
  for (r in SOMMIER_REGISTRES$registre[SOMMIER_REGISTRES$echelle == "foret"]) {
    expect_equal(sommieR:::echelle_registre(r), "foret")
  }
})

test_that("les identifiants et dates malformes sont refuses", {
  expect_error(entree_test(1L, foret_id = "pas-un-uuid"), "UUID")
  expect_error(
    sommier_entree(FORET_TEST, 5L, "01/03/2026", "a1",
                   registre5_coupe("martelage", 2026, "x", 1)),
    "ISO-8601"
  )
  expect_error(
    sommier_entree(FORET_TEST, 5L, "2026-02-30", "a1",
                   registre5_coupe("martelage", 2026, "x", 1)),
    "pas une date valide"
  )
  expect_error(entree_test(1L, ug_uuid = "abc"), "UUID")
})

test_that("le chainage part de la genese et progresse d'un en un", {
  ch <- chaine_test(5L)
  expect_equal(vapply(ch, function(e) e$seq, numeric(1)), 1:5)
  expect_identical(ch[[1]]$hash_prev, sommier_empreinte_genese(FORET_TEST))
  for (i in 2:5) {
    expect_identical(ch[[i]]$hash_prev, ch[[i - 1]]$hash)
  }
})

test_that("le chainage est reproductible", {
  # Deux executions sur les memes entrees doivent donner les memes empreintes,
  # sinon deux verificateurs ne s'accorderaient jamais.
  a <- chaine_test(5L)
  b <- chaine_test(5L)
  expect_identical(
    vapply(a, function(e) empreinte_hex(e$hash), character(1)),
    vapply(b, function(e) empreinte_hex(e$hash), character(1))
  )
})

test_that("une chaine peut etre prolongee depuis une tete existante", {
  debut <- chaine_test(3L)
  tete <- debut[[3]]
  suite <- sommier_chainer(list(entree_test(4L)), seq_depart = tete$seq + 1,
                           hash_prev = tete$hash)
  expect_equal(suite[[1]]$seq, 4)
  expect_identical(suite[[1]]$hash_prev, tete$hash)
  expect_true(sommier_verifier_chaine(c(debut, suite))$valide)
})

test_that("le chainage refuse de melanger deux forets", {
  entrees <- list(entree_test(1L),
                  entree_test(2L, foret_id = "99999999-8888-4777-8666-555555555555"))
  expect_error(sommier_chainer(entrees), "monotone par foret")
})

test_that("la mise a plat rend le payload en forme canonique", {
  df <- entrees_en_data_frame(chaine_test(2L))
  expect_equal(nrow(df), 2L)
  expect_equal(df$payload[[1]], jcs(chaine_test(2L)[[1]]$payload))
  expect_true(all(grepl("^[0-9a-f]{64}$", df$hash)))
  expect_true(all(is.na(df$ug_uuid)))       # entrees a l'echelle foret
})

test_that("une chaine vide reste une chaine", {
  expect_equal(sommier_chainer(list()), list())
  expect_true(sommier_verifier_chaine(list())$valide)
})
