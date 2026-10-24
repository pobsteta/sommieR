# Le referentiel de sensibilite de l'INPN, et le niveau qu'il donne a chaque
# fiche espece : sans base.

ref_sensibilite <- function() {
  sommier_sensibilite(test_path("fixtures", "RefSensibilite_99.csv"))
}

fiche_espece <- function(seq, date, ...) {
  data.frame(
    seq = seq, registre = 9L, date_evenement = date,
    payload = as.character(jsonlite::toJSON(
      registre9_espece(...), auto_unbox = TRUE, digits = NA
    )),
    stringsAsFactors = FALSE
  )
}

test_that("le referentiel se lit, date et empreint, du CSV ou de l'archive", {
  ref <- ref_sensibilite()
  expect_equal(nrow(ref), 4L)
  expect_equal(attr(ref, "version"), "99")
  expect_equal(attr(ref, "fichier"), "RefSensibilite_99.csv")
  empreinte <- empreinte_hex(as.raw(openssl::sha256(file(
    test_path("fixtures", "RefSensibilite_99.csv")))))
  expect_equal(attr(ref, "empreinte"), empreinte)
  expect_type(ref$cd_sensibilite, "integer")
  # Le departement reste un texte : la Corse s'ecrit 2A.
  expect_type(ref$cd_dept, "character")

  dossier <- withr::local_tempdir()
  file.copy(test_path("fixtures", "RefSensibilite_99.csv"), dossier)
  archive <- file.path(dossier, "SENSIBILITE.zip")
  withr::with_dir(dossier, utils::zip(archive, "RefSensibilite_99.csv",
                                      flags = "-q"))
  depuis_zip <- sommier_sensibilite(archive)
  expect_equal(attr(depuis_zip, "empreinte"), empreinte)
  expect_equal(nrow(depuis_zip), 4L)
})

test_that("un fichier qui n'est pas le referentiel est refuse", {
  expect_error(sommier_sensibilite(tempfile()), "introuvable")
  autre <- withr::local_tempfile(fileext = ".csv")
  writeLines(c("a,b", "1,2"), autre)
  expect_error(sommier_sensibilite(autre), "colonnes absentes")
  dossier <- withr::local_tempdir()
  writeLines("x", file.path(dossier, "lisez-moi.txt"))
  vide <- file.path(dossier, "vide.zip")
  withr::with_dir(dossier, utils::zip(vide, "lisez-moi.txt", flags = "-q"))
  expect_error(sommier_sensibilite(vide), "un et un seul")
})

test_that("le niveau vient du cd_nom, du binome, du departement et de la duree", {
  ref <- ref_sensibilite()
  e <- rbind(
    fiche_espece(1, "2021-05-28", "Sabot de Venus", "Cypripedium calceolus",
                 cd_nom = 94041),
    # Sans cd_nom, l'espece se reconnait a son binome.
    fiche_espece(2, "2021-05-28", "Sabot de Venus",
                 "Cypripedium calceolus L."),
    fiche_espece(3, "2010-06-01", "Taxon ancien", "Taxon fictif ancien",
                 cd_nom = 900001),
    fiche_espece(4, "2025-06-01", "Taxon ancien", "Taxon fictif ancien",
                 cd_nom = 900001),
    # Saisie sous le nom valide, la fiche retrouve la ligne de son synonyme.
    fiche_espece(5, "2025-06-01", "Taxon valide", "Taxon fictif valide",
                 cd_nom = 900002),
    fiche_espece(6, "2025-06-01", "Chene", "Quercus robur", cd_nom = 116759)
  )
  # Une fiche qui n'est pas une espece n'est pas jugee.
  e <- rbind(e, data.frame(
    seq = 7, registre = 9L, date_evenement = "2025-06-01",
    payload = as.character(jsonlite::toJSON(registre9_arbre(
      "Chene de la Justice", "chene", "historique"
    ), auto_unbox = TRUE, digits = NA)), stringsAsFactors = FALSE
  ))

  cote_dor <- sensibilite_des_ecritures(e, ref, "21", as.Date("2026-10-24"))
  expect_equal(cote_dor$seq, 1:6)
  # Le taxon ancien : 16 ans apres l'observation, sa sensibilite (5 ans) est
  # tombee ; un an apres, elle tient.
  expect_equal(cote_dor$niveau, c(1L, 1L, 0L, 3L, 3L, 0L))

  # Tous departements confondus, la plus forte : le code 2 des Vosges.
  partout <- sensibilite_des_ecritures(e, ref, NULL, as.Date("2026-10-24"))
  expect_equal(partout$niveau[1:2], c(2L, 2L))
  # Hors de leurs departements, rien.
  ailleurs <- sensibilite_des_ecritures(e, ref, "45", as.Date("2026-10-24"))
  expect_true(all(ailleurs$niveau == 0L))
  # Sans referentiel, aucune espece n'est jugee diffusable.
  sans <- sensibilite_des_ecritures(e, NULL, NULL, as.Date("2026-10-24"))
  expect_true(all(sans$niveau == 4L))
  expect_equal(nrow(sensibilite_des_ecritures(e[0, ], ref, NULL,
                                              Sys.Date())), 0L)
  expect_equal(nrow(sensibilite_des_ecritures(e[7, ], ref, NULL,
                                              Sys.Date())), 0L)
})
