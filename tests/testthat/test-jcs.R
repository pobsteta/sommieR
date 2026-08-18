test_that("les nombres suivent ECMAScript Number::toString", {
  # Vecteurs de la specification ECMAScript, a laquelle RFC 8785 renvoie.
  expect_equal(jcs_nombre(0), "0")
  expect_equal(jcs_nombre(-0), "0")           # String(-0) vaut "0"
  expect_equal(jcs_nombre(1), "1")
  expect_equal(jcs_nombre(-1), "-1")
  expect_equal(jcs_nombre(100), "100")
  expect_equal(jcs_nombre(1.5), "1.5")
  expect_equal(jcs_nombre(0.1), "0.1")
  expect_equal(jcs_nombre(1 / 3), "0.3333333333333333")
  expect_equal(jcs_nombre(2^53), "9007199254740992")
})

test_that("la bascule en notation exponentielle respecte les bornes 1e-7 / 1e21", {
  # Dernier entier rendu en clair, et premier rendu en exponentielle.
  expect_equal(jcs_nombre(1e20), "100000000000000000000")
  expect_equal(jcs_nombre(1e21), "1e+21")
  # Derniere decimale rendue en clair, et premiere rendue en exponentielle.
  expect_equal(jcs_nombre(1e-6), "0.000001")
  expect_equal(jcs_nombre(1e-7), "1e-7")
})

test_that("les extremes IEEE 754 restent representables", {
  expect_equal(jcs_nombre(5e-324), "5e-324")   # denormal minimal
  expect_equal(jcs_nombre(1.7976931348623157e308), "1.7976931348623157e+308")
})

test_that("les nombres se relisent exactement", {
  # La propriete qui compte : la forme canonique doit etre un aller-retour
  # sans perte, sinon deux verificateurs n'obtiendraient pas la meme empreinte.
  set.seed(42)
  valeurs <- c(
    0.1, 1 / 3, 1e-7, 1e21, 2^53, pi, exp(1),
    rnorm(200) * 10^sample(-12:12, 200, replace = TRUE)
  )
  for (v in valeurs) {
    expect_identical(as.numeric(jcs_nombre(v)), v, label = format(v, digits = 22))
  }
})

test_that("NaN et les infinis sont refuses", {
  expect_error(jcs_nombre(NaN), "JSON")
  expect_error(jcs_nombre(Inf), "infinis")
  expect_error(jcs_nombre(-Inf), "infinis")
})

test_that("les cles d'objet sont triees par unites de code UTF-16", {
  expect_equal(jcs(list(b = 1, a = 2)), '{"a":2,"b":1}')

  # Le cas ou l'ordre UTF-16 s'ecarte de l'ordre des points de code :
  # U+1F600 s'encode en substituts D83D DE00, qui se classent AVANT U+FB33,
  # alors que son point de code lui est superieur. Un tri par points de code
  # donnerait l'ordre inverse.
  emoji <- intToUtf8(0x1F600)
  dalet <- intToUtf8(0xFB33)
  obj <- structure(list(1, 2), names = c(emoji, dalet))
  attendu <- paste0('{"', emoji, '":1,"', dalet, '":2}')
  expect_equal(jcs(obj), attendu)
})

test_that("le tri des cles ne depend pas de la locale", {
  obj <- structure(list(1, 2, 3), names = c("B", "a", "A"))
  attendu <- '{"A":3,"B":1,"a":2}'   # ordre par octets, pas ordre alphabetique
  expect_equal(jcs(obj), attendu)
  withr::with_locale(c(LC_COLLATE = "C"), expect_equal(jcs(obj), attendu))
})

test_that("les chaines sont echappees au minimum", {
  expect_equal(jcs("a\"b"), '"a\\"b"')
  expect_equal(jcs("a\\b"), '"a\\\\b"')
  expect_equal(jcs("\n\r\t\b\f"), '"\\n\\r\\t\\b\\f"')
  # Les caracteres de controle sans echappement court passent en \u00xx.
  expect_equal(jcs(intToUtf8(1L)), '"\\u0001"')
  expect_equal(jcs(intToUtf8(31L)), '"\\u001f"')
  expect_equal(jcs(""), '""')
  # Les caracteres non ASCII restent litteraux, jamais echappes en \u.
  expect_equal(jcs("hêtre"), '"hêtre"')
})

test_that("les structures R se transposent selon les conventions annoncees", {
  expect_equal(jcs(NULL), "null")
  expect_equal(jcs(list()), "[]")
  expect_equal(jcs(structure(list(), names = character(0))), "{}")
  expect_equal(jcs(TRUE), "true")
  expect_equal(jcs(c(1, 2, 3)), "[1,2,3]")
  expect_equal(jcs(I(1)), "[1]")               # scalaire force en tableau
  expect_equal(jcs(list(a = list(b = 1))), '{"a":{"b":1}}')
  expect_equal(jcs(list(a = list(1, "x", TRUE))), '{"a":[1,"x",true]}')
})

test_that("NA est refuse plutot que confondu avec null", {
  # JSON ne distingue pas les deux ; les confondre dans un registre opposable
  # ferait passer une valeur manquante pour une absence deliberee.
  expect_error(jcs(NA), "NA")
  expect_error(jcs(list(a = NA_character_)), "NA")
})

test_that("les listes partiellement nommees et les cles dupliquees sont refusees", {
  expect_error(jcs(list(a = 1, 2)), "partiellement nommee")
  expect_error(jcs(structure(list(1, 2), names = c("a", "a"))), "dupliquees")
})

test_that("la recanonisation est idempotente", {
  expect_equal(jcs_depuis_json('{"b":1,"a":2}'), '{"a":2,"b":1}')
  expect_equal(jcs_depuis_json('{"a":2,"b":1}'), '{"a":2,"b":1}')
  expect_equal(jcs_depuis_json('{"a":1.0,"b":1e2}'), '{"a":1,"b":100}')
  expect_equal(jcs_depuis_json("{}"), "{}")
  expect_equal(jcs_depuis_json("[]"), "[]")
  expect_equal(jcs_depuis_json('{"a":{},"b":[]}'), '{"a":{},"b":[]}')
})

test_that("les dates sont serialisees en ISO-8601", {
  expect_equal(jcs(as.Date("2026-03-01")), '"2026-03-01"')
  expect_equal(
    jcs(as.POSIXct("2026-03-01 10:00:00", tz = "UTC")),
    '"2026-03-01T10:00:00Z"'
  )
})
