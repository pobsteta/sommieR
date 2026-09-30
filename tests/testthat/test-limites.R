# Suivi des limites, sans base : le constat au registre 2, les photos et leur
# EXIF, le controle d'un projet rapporte du terrain.

element_test <- list(id = "45188000ZK01:Objet_850076", numero = "B-001",
                     categorie = "borne", millesime = "2026-02-17",
                     x = 633319.56, y = 6767866.55)
photo_test <- list(sha256 = strrep("ab", 32L), octets = 852L,
                   type = "image/jpeg", fichier = "limites_1.jpg")

test_that("une reconnaissance porte un etat et l'element vu", {
  p <- registre2_foncier("reconnaissance_limite", "Reconnaissance de B-001",
                         etat = "en_place", element_pci = element_test,
                         precision_m = 0.02, operateur = "P. O.",
                         visite_le = "2026-10-12T10:31:05Z",
                         photos = list(photo_test))
  expect_equal(p$etat, "en_place")
  expect_equal(p$element_pci$id, "45188000ZK01:Objet_850076")
  expect_equal(p$photos[[1L]]$sha256, strrep("ab", 32L))
  expect_equal(p$visite_le, "2026-10-12T10:31:05Z")
  # Le payload passe la validation generale et se canonise.
  expect_type(jcs(valider_payload(2L, p)), "character")
  expect_equal(SOMMIER_SCHEMA_VERSIONS[["2"]], "r2-1.3.0")
})

test_that("les etats sont des constats, pas des verdicts", {
  expect_false("deplace" %in% SOMMIER_ETATS_LIMITE)
  expect_error(registre2_foncier("reconnaissance_limite", "x",
                                 etat = "deplace", element_pci = element_test),
               "etat")
  expect_error(registre2_foncier("reconnaissance_limite", "x",
                                 element_pci = element_test), "etat")
})

test_that("un constat repond a un element du plan, sauf hors plan", {
  expect_error(registre2_foncier("reconnaissance_limite", "x",
                                 etat = "en_place"), "element_pci")
  expect_error(registre2_foncier("reconnaissance_limite", "x",
                                 etat = "hors_plan",
                                 element_pci = element_test), "hors_plan")
  hors <- registre2_foncier("reconnaissance_limite", "Borne neuve",
                            etat = "hors_plan")
  expect_null(hors$element_pci)
  expect_error(registre2_foncier("reconnaissance_limite", "x",
                                 etat = "en_place",
                                 element_pci = list(id = "Objet_1")),
               "feuille:OBJECT_RID")
  expect_error(registre2_foncier("reconnaissance_limite", "x",
                                 etat = "en_place",
                                 element_pci = c(element_test, couleur = "x")),
               "inconnu")
})

test_that("les champs d'une reconnaissance sont refuses aux autres types", {
  expect_error(registre2_foncier("bornage", "Limite nord", etat = "en_place"),
               "reconnaissance de limite")
  # Un bornage ordinaire n'en est pas affecte.
  expect_equal(registre2_foncier("bornage", "Limite nord")$type_entree,
               "bornage")
})

test_that("une photo n'entre que par une empreinte bien formee", {
  mauvaise <- photo_test
  mauvaise$sha256 <- "abc"
  expect_error(registre2_foncier("reconnaissance_limite", "x",
                                 etat = "en_place", element_pci = element_test,
                                 photos = list(mauvaise)), "64 caracteres")
  expect_error(registre2_foncier("reconnaissance_limite", "x",
                                 etat = "en_place", element_pci = element_test,
                                 photos = photo_test), "liste de photos")
})

test_that("l'EXIF d'un JPEG se lit, dans les deux ordres d'octets", {
  # Photos engendrees par Pillow, un autre producteur que ce lecteur (voir
  # fixtures/PROVENANCE.md) : 47 58' 37,2" N, 2 1' 50,4" E.
  for (ordre in c("ii", "mm")) {
    exif <- lire_exif(testthat::test_path("fixtures",
                                          paste0("photo-exif-", ordre, ".jpg")))
    # La date de prise de vue passe avant la date de modification.
    expect_equal(exif$date, "2026-10-12T10:31:05")
    expect_equal(exif$position, "47.977000,2.030667")
  }
  expect_length(lire_exif(testthat::test_path("fixtures",
                                              "photo-sans-exif.jpg")), 0L)
  # Un fichier qui n'est pas un JPEG ne fait pas echouer la lecture.
  texte <- withr::local_tempfile(fileext = ".jpg")
  writeLines("pas une image", texte)
  expect_length(lire_exif(texte), 0L)
})

test_that("une photo se depose sous son empreinte, sans etre modifiee", {
  depot <- withr::local_tempdir()
  source <- testthat::test_path("fixtures", "photo-exif-ii.jpg")
  p <- sommier_deposer_photo(source, depot)

  expect_match(p$sha256, "^[0-9a-f]{64}$")
  expect_equal(p$type, "image/jpeg")
  expect_equal(p$octets, as.integer(file.size(source)))
  expect_equal(p$exif_date, "2026-10-12T10:31:05")
  cible <- file.path(depot, paste0(p$sha256, ".jpg"))
  expect_true(file.exists(cible))
  # Les octets sont ceux de la source, a l'identique.
  expect_identical(readBin(cible, "raw", 4096L), readBin(source, "raw", 4096L))

  # Deposer deux fois ne copie qu'une fois.
  expect_equal(sommier_deposer_photo(source, depot)$sha256, p$sha256)
  expect_length(list.files(depot), 1L)

  # Un depot altere n'est pas ecrase.
  writeBin(as.raw(0L), cible)
  expect_error(sommier_deposer_photo(source, depot), "altere")

  expect_error(sommier_deposer_photo("absente.jpg", depot), "introuvable")
  gif <- withr::local_tempfile(fileext = ".gif")
  writeLines("x", gif)
  expect_error(sommier_deposer_photo(gif, depot), "non reconnu")
})

test_that("un projet rapporte est controle en entier avant d'ecrire", {
  skip_if_not_installed("sf")
  dossier <- withr::local_tempdir()
  dir.create(file.path(dossier, "DCIM"))
  file.copy(testthat::test_path("fixtures", "photo-sans-exif.jpg"),
            file.path(dossier, "DCIM", "a.jpg"))
  elements <- data.frame(id = "45188000ZK01:Objet_1", stringsAsFactors = FALSE)
  u <- c(uuid_v4(), uuid_v4(), uuid_v4(), uuid_v4(), uuid_v4())
  constats <- data.frame(
    uuid = u,
    element_id = c("45188000ZK01:Objet_1", NA, "45188000ZK01:Objet_9",
                   "45188000ZK01:Objet_1", "45188000ZK01:Objet_1"),
    etat = c("en_place", "en_place", "en_place", "deplace", "hors_plan"),
    visite_le = as.POSIXct("2026-10-12 10:00:00", tz = "UTC"),
    stringsAsFactors = FALSE
  )
  photos <- data.frame(constat_uuid = c(u[[1L]], u[[1L]]),
                       fichier = c("DCIM/a.jpg", "DCIM/absente.jpg"),
                       stringsAsFactors = FALSE)
  fautes <- controler_constats(constats, photos, elements, dossier)
  # Toutes les fautes a la fois : on corrige tout, puis on reimporte.
  expect_length(fautes, 5L)
  expect_match(fautes[[1L]], "photo introuvable")
  expect_true(any(grepl("aucun element du plan choisi", fautes)))
  expect_true(any(grepl("element inconnu du projet", fautes)))
  expect_true(any(grepl("etat inconnu \\(deplace\\)", fautes)))
  expect_true(any(grepl("hors plan", fautes)))
})

test_that("les valeurs du projet sont echappees pour le XML", {
  qgs <- withr::local_tempfile(fileext = ".qgs")
  writeLines('<qgis title="@@TITRE@@"><v x="@@OPERATEUR@@"/></qgis>', qgs)
  poser_valeurs_projet(qgs, c("@@TITRE@@" = "Bois <A> & \"B\"",
                              "@@OPERATEUR@@" = "P. O."))
  xml <- readLines(qgs, encoding = "UTF-8")
  expect_match(xml, "Bois &lt;A&gt; &amp; &quot;B&quot;", fixed = TRUE)
  expect_no_match(xml, "@@")
})

test_that("le modele QGIS est livre, avec ses reperes et ses couches", {
  modele <- system.file("qgis", package = "sommieR")
  expect_true(all(file.exists(file.path(
    modele, c("limites.qgs", "limites_attachments.zip", "terrain.gpkg")
  ))))
  qgs <- paste(readLines(file.path(modele, "limites.qgs"), warn = FALSE,
                         encoding = "UTF-8"), collapse = "\n")
  for (repere in c("@@TITRE@@", "@@OPERATEUR@@", "@@FORET@@",
                   'xmin="111111"', 'ymax="4444444"')) {
    expect_match(qgs, repere, fixed = TRUE)
  }
  # Chemins relatifs : le dossier se deplace d'une machine a un telephone.
  expect_match(qgs, "./terrain.gpkg|layername=constats", fixed = TRUE)
  expect_no_match(qgs, "/home/", fixed = TRUE)
  # Les identifiants prefixes que designent overlay_nearest() et la relation.
  expect_match(qgs, "overlay_nearest('limites_elements_points'", fixed = TRUE)
  expect_match(qgs, 'id="photos_du_constat"', fixed = TRUE)
  expect_match(qgs, "qfield_version_minimale", fixed = TRUE)

  skip_if_not_installed("sf")
  couches <- sf::st_layers(file.path(modele, "terrain.gpkg"))$name
  expect_setequal(couches, c("elements_points", "elements_lignes",
                             "elements_surfaces", "elements", "constats",
                             "photos", "foret", "tampon", "ug", "parcelles"))
})
