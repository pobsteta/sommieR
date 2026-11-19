# Lecture EXIF des photos de terrain : GPSMapDatum, GPSHPositioningError,
# OffsetTimeOriginal (brief surculus du 2026-10-28).

test_that("l'EXIF dit le repere, la precision et le fuseau", {
  f <- withr::local_tempfile(fileext = ".jpg")
  photo_exif(f, date = "2026:11:18 10:31:05", decalage = "+01:00",
             gps = list(lat = 47.977, lon = 2.030667, datum = "ETRS89",
                        erreur_m = 0.03))
  e <- lire_exif(f)
  expect_equal(e$date, "2026-11-18T10:31:05")
  expect_equal(e$decalage, "+01:00")
  expect_equal(e$date_utc, "2026-11-18T09:31:05Z")
  expect_equal(e$position, "47.977000,2.030667")
  expect_equal(e$datum, "ETRS89")
  expect_equal(e$erreur_m, 0.03)
})

test_that("une position sans repere declare reste sans repere", {
  f <- withr::local_tempfile(fileext = ".jpg")
  photo_exif(f, gps = list(lat = 47.977, lon = 2.030667))
  e <- lire_exif(f)
  expect_equal(e$position, "47.977000,2.030667")
  expect_null(e$datum)
  expect_null(e$erreur_m)
  expect_null(e$decalage)
  expect_null(e$date_utc)
})

test_that("un decalage negatif ou une date sans GPS se lisent aussi", {
  f <- withr::local_tempfile(fileext = ".jpg")
  photo_exif(f, date = "2026:07:01 23:30:00", decalage = "-05:30")
  e <- lire_exif(f)
  expect_equal(e$date_utc, "2026-07-02T05:00:00Z")
  expect_null(e$position)
})

test_that("le depot recopie ces declarations, le fichier reste intact", {
  f <- withr::local_tempfile(fileext = ".jpg")
  photo_exif(f, decalage = "+01:00",
             gps = list(lat = 47.977, lon = 2.030667, datum = "WGS-84",
                        erreur_m = 1.5))
  avant <- empreinte_fichier(f)
  p <- sommier_deposer_photo(f, withr::local_tempdir())
  expect_equal(p$sha256, avant)
  expect_equal(p$exif_datum, "WGS-84")
  expect_equal(p$exif_erreur_m, 1.5)
  expect_equal(p$exif_decalage, "+01:00")
  expect_equal(p$exif_date_utc, "2026-11-18T09:31:05Z")
  expect_equal(empreinte_fichier(f), avant)
})

test_that("le payload d'un controle accepte ces champs et refuse un champ inconnu", {
  p <- list(sha256 = strrep("a", 64), octets = 10L, type = "image/jpeg",
            exif_datum = "ETRS89", exif_erreur_m = 0.02,
            uuid = "11111111-2222-4333-8444-555555555555",
            terrain = list(sujet = "plant", azimut_magnetique = 187.5,
                           simule = 0L, plant = NA))
  v <- valider_photos(list(p))[[1L]]
  expect_equal(v$exif_datum, "ETRS89")
  expect_equal(v$terrain$sujet, "plant")
  expect_null(v$terrain$plant)
  p$terrain$bidon <- 1
  expect_error(valider_photos(list(p)), "champ\\(s\\) inconnu")
})
