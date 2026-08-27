# PCI vecteur : ce qui se verifie sans reseau, et ce qui l'exige.

test_that("les couches annoncees sont celles du modele EDIGEO", {
  expect_equal(SOMMIER_COUCHES_PCI[["bornes"]], "BORNE_id")
  expect_equal(SOMMIER_COUCHES_PCI[["details"]], "TLINE_id")
  expect_setequal(names(SOMMIER_COUCHES_PCI),
                  c("bornes", "details", "parcelles", "voies"))
})

test_that("sommier_fond_pci_lire refuse ce qui ne vient pas du telechargement", {
  expect_error(sommier_fond_pci_lire(data.frame(x = 1)), "sommier_fond_pci")
})

test_that("une couche inconnue est refusee avant toute lecture", {
  fond <- structure(
    list(feuilles = data.frame(feuille = "212000000A01", thf = "absent.THF"),
         code_insee = "21200", source = "test"),
    class = "sommier_fond_pci"
  )
  skip_if_not_installed("sf")
  expect_error(sommier_fond_pci_lire(fond, couche = "fosses"), "couche")
})

# Un lot EDIGEO reduit a sa declaration de referentiel : de quoi verifier ce
# que le paquet en fait, sans telecharger une feuille.
lot_declarant <- function(reference, env = parent.frame()) {
  dossier <- withr::local_tempdir(.local_envir = env)
  thf <- file.path(dossier, "E0000A01.THF")
  writeLines("BOMT 12:E0000A01.THF", thf)
  if (!is.null(reference)) {
    writeLines(c("RTYSA03:GEO", paste0("RELSA06:", reference), "UNHST01:m"),
               file.path(dossier, "ED0A01SE.GEO"))
  }
  thf
}

test_that("le referentiel se lit dans la declaration du lot", {
  # EDIGEO est auto-descripteur : le `.GEO` porte le referentiel employe. Le
  # lire vaut mieux que reconnaitre une chaine proj4 - la declaration est
  # l'intention du producteur, le proj4 une traduction du pilote, rendue sans
  # code EPSG.
  expect_equal(projection_declaree(lot_declarant("LAMB93")), "LAMB93")
  expect_equal(projection_declaree(lot_declarant("CC47")), "CC47")
  expect_true(is.na(projection_declaree(lot_declarant(NULL))))
})

test_that("une conique conforme declaree est ramenee en Lambert-93", {
  # Les livraisons `edigeo-cc` sont en CC42 a CC50 : elles ne sont plus
  # refusees, elles sont reprojetees d'apres ce qu'elles declarent.
  skip_if_not_installed("sf")
  ramene <- poser_projection(sf::st_sfc(sf::st_point(c(1700000, 5300000))),
                             lot_declarant("CC47"))
  expect_equal(sf::st_crs(ramene)$epsg, 2154L)
})

test_that("un referentiel absent ou inconnu est signale, jamais devine", {
  # Reprojeter au hasard poserait la feuille a cote de la foret sans que rien
  # ne l'annonce - c'est le defaut du GeoJSON corrige en v0.6.0.
  skip_if_not_installed("sf")
  nu <- sf::st_sfc(sf::st_point(c(847500, 6687400)))
  expect_error(poser_projection(nu, lot_declarant(NULL)), "aucune declaration")
  expect_error(poser_projection(nu, lot_declarant("UTM31")),
               "referentiel declare")
})

test_that("une geometrie deja etiquetee n'est pas retouchee", {
  skip_if_not_installed("sf")
  l93 <- sf::st_sfc(sf::st_point(c(847500, 6687400)), crs = 2154)
  expect_equal(sf::st_crs(poser_projection(l93, lot_declarant("LAMB93")))$epsg,
               2154L)
})

test_that("la nature d'un detail n'est pas devinee", {
  # `SYM` distingue mur, fosse et haie, mais sa nomenclature ne figure ni dans
  # le .DIC ni dans le .SCD de l'archive. Sans table fournie, la nature reste
  # inconnue plutot qu'inventee.
  details <- data.frame(sym = c("21", "22", "31"), stringsAsFactors = FALSE)
  sans <- appliquer_symboles(details, NULL)
  expect_true(all(is.na(sans)))

  avec <- appliquer_symboles(details, c("21" = "mur", "22" = "fosse"))
  expect_equal(avec, c("mur", "fosse", NA))
})

test_that("le PCI se telecharge feuille par feuille, et seulement les utiles", {
  skip_on_cran()
  testthat::skip_if_offline()
  skip_if_not_installed("sf")
  cache <- withr::local_tempdir()

  # Couchey compte dix-sept feuilles ; une foret en touche une ou deux.
  emprise <- data.frame(wkt = paste0(
    "POLYGON((847400 6687300, 847900 6687300, 847900 6687600, ",
    "847400 6687600, 847400 6687300))"
  ))
  # Une panne du serveur de la DGFiP saute ce test ; un 404 le fait echouer.
  toutes <- sauter_si_source_indisponible(
    sommier_feuilles_pci("21200", cache = cache)
  )
  # Le cache est chaud : cet appel-ci ne touche plus au reseau.
  autour <- sommier_feuilles_pci("21200", emprise = emprise, cache = cache)
  expect_gt(nrow(toutes), nrow(autour))
  expect_gt(nrow(autour), 0L)

  fond <- sauter_si_source_indisponible(
    sommier_fond_pci("21200", autour$feuille, cache = cache)
  )
  expect_equal(nrow(fond$feuilles), nrow(autour))
  expect_true(all(file.exists(fond$feuilles$thf)))

  bornes <- sommier_fond_pci_lire(fond, "bornes")
  expect_gt(nrow(bornes), 0L)
  expect_match(bornes$wkt[[1L]], "^POINT")
  # Ce que les livraisons GeoJSON n'exposent pas, et qui motive ce lot.
  details <- sommier_fond_pci_lire(fond, "details")
  expect_gt(nrow(details), 0L)
  expect_false(all(is.na(details$sym)))

  # Deuxieme appel : l'archive deja decompressee ne se retelecharge pas.
  horodatage <- file.info(fond$feuilles$thf[[1L]])$mtime
  encore <- sommier_fond_pci("21200", autour$feuille, cache = cache)
  expect_equal(file.info(encore$feuilles$thf[[1L]])$mtime, horodatage)
})

# --- Assemblage et decoupe, sans EDIGEO -------------------------------------
# Ces regles decident de ce que la carte montre. Les eprouver ne demande pas
# une archive : elles portent sur des tableaux, pas sur un format.

objets_test <- function(x = c(847500, 848500), feuille = "212000000A01") {
  data.frame(
    feuille = feuille,
    objet = paste0("Objet_", seq_along(x)),
    sym = as.character(seq_along(x) + 20L),
    wkt = sprintf("POINT (%f 6687400)", x),
    stringsAsFactors = FALSE
  )
}

emprise_test <- function() {
  data.frame(wkt = paste0(
    "POLYGON((847400 6687300, 847600 6687300, 847600 6687500, ",
    "847400 6687500, 847400 6687300))"
  ), stringsAsFactors = FALSE)
}

test_that("un tableau vide a les memes colonnes qu'un tableau plein", {
  # Une foret peut n'avoir aucune borne sur ses feuilles : l'appelant ne doit
  # pas avoir deux formes a traiter selon que la couche est garnie ou non.
  vide <- assembler_objets(list(NULL, NULL))
  plein <- assembler_objets(list(objets_test()))
  expect_equal(nrow(vide), 0L)
  expect_equal(names(vide), names(plein))
})

test_that("les feuilles se recollent, celles qui n'ont rien exceptees", {
  assemble <- assembler_objets(list(
    objets_test(847500, "212000000A01"), NULL,
    objets_test(848500, "212000000A02")
  ))
  expect_equal(nrow(assemble), 2L)
  expect_setequal(assemble$feuille, c("212000000A01", "212000000A02"))
})

test_that("l'emprise ecarte ce qui est loin et garde ce qui borde", {
  skip_if_not_installed("sf")
  retenus <- restreindre_emprise(objets_test(), emprise_test(), marge_m = 100)
  expect_equal(nrow(retenus), 1L)
  expect_match(retenus$wkt, "847500")

  # La marge compte : un objet a 900 m entre si on la porte a un kilometre.
  large <- restreindre_emprise(objets_test(), emprise_test(), marge_m = 1000)
  expect_equal(nrow(large), 2L)
})

test_that("sans emprise, rien n'est ecarte", {
  expect_equal(nrow(restreindre_emprise(objets_test(), NULL, 100)), 2L)
  expect_equal(
    nrow(restreindre_emprise(objets_test(), data.frame(), 100)), 2L
  )
})

test_that("une emprise appliquee a un tableau vide ne le casse pas", {
  vide <- assembler_objets(list())
  expect_equal(nrow(restreindre_emprise(vide, emprise_test(), 100)), 0L)
})

test_that("l'emprise est la boite englobante, tamponnee", {
  # Decouper au contour exact retirerait les objets qui bordent la foret, et
  # ceux-la interessent justement le gestionnaire.
  skip_if_not_installed("sf")
  boite <- boite_emprise(emprise_test(), marge_m = 100)
  limites <- sf::st_bbox(boite)
  expect_equal(as.numeric(limites["xmin"]), 847300)
  expect_equal(as.numeric(limites["xmax"]), 847700)
  expect_equal(sf::st_crs(boite)$epsg, 2154L)
})

test_that("un dossier sans .THF se dit, plutot que de rendre un chemin faux", {
  expect_true(is.na(fichier_thf(withr::local_tempdir())))
})

test_that("un .GEO sans declaration de referentiel ne s'invente pas de code", {
  dossier <- withr::local_tempdir()
  writeLines("BOMT 12:E0000A01.THF", file.path(dossier, "E0000A01.THF"))
  writeLines(c("RTYSA03:GEO", "UNHST01:m"), file.path(dossier, "ED0A01SE.GEO"))
  expect_true(is.na(projection_declaree(file.path(dossier, "E0000A01.THF"))))
})

# --- Lecture d'un lot EDIGEO reel, hors ligne -------------------------------
# La feuille A01 de Couchey est jointe au depot (voir fixtures/PROVENANCE.md) :
# le format est multi-fichiers et auto-descripteur, le reconstituer a la main
# produirait une imitation dont la conformite ne prouverait rien.

fond_edigeo <- function(env = parent.frame()) {
  skip_if_not_installed("sf")
  archive <- testthat::test_path("fixtures", "edigeo-212000000A01.tar.bz2")
  skip_if_not(file.exists(archive), "Fixture EDIGEO absente.")
  dossier <- withr::local_tempdir(.local_envir = env)
  utils::untar(archive, exdir = dossier, tar = "internal")

  structure(
    list(
      feuilles = data.frame(feuille = "212000000A01",
                            thf = fichier_thf(dossier),
                            stringsAsFactors = FALSE),
      code_insee = "21200", source = "fixture locale"
    ),
    class = "sommier_fond_pci"
  )
}

test_that("les bornes se lisent, projetees d'apres la declaration du lot", {
  fond <- fond_edigeo()
  bornes <- sommier_fond_pci_lire(fond, "bornes")

  expect_equal(nrow(bornes), 12L)
  expect_match(bornes$wkt[[1L]], "^POINT")
  expect_equal(unique(bornes$feuille), "212000000A01")
  # Le lot declare LAMB93 : les coordonnees sont donc metriques et situees en
  # Bourgogne, non des degres ni un autre plan.
  x <- as.numeric(sub("^POINT \\(([0-9.]+) .*", "\\1", bornes$wkt[[1L]]))
  expect_gt(x, 800000)
  expect_lt(x, 900000)
  # Une borne ne porte pas de symbole : sa nature tient a sa couche.
  expect_true(all(is.na(bornes$sym)))
})

test_that("les details portent leur symbole, et rien de plus", {
  fond <- fond_edigeo()
  details <- sommier_fond_pci_lire(fond, "details")

  expect_equal(nrow(details), 50L)
  expect_match(details$wkt[[1L]], "^LINESTRING")
  expect_setequal(unique(details$sym), c("19", "21", "22", "23", "31"))
  # Sans table fournie, la nature reste inconnue plutot qu'inventee.
  expect_true(all(is.na(details$nature)))
})

test_that("une table de symboles fournie nomme ce qu'elle couvre, et rien d'autre", {
  fond <- fond_edigeo()
  details <- sommier_fond_pci_lire(fond, "details",
                                   symboles = c("21" = "mur", "22" = "fosse"))
  expect_setequal(unique(details$nature[details$sym == "21"]), "mur")
  expect_setequal(unique(details$nature[details$sym == "22"]), "fosse")
  # Les codes hors table restent sans nom : on ne comble pas les trous.
  expect_true(all(is.na(details$nature[details$sym == "19"])))
})

test_that("l'emprise s'applique aussi aux objets d'un lot", {
  fond <- fond_edigeo()
  toutes <- sommier_fond_pci_lire(fond, "bornes")
  # Emprise prise autour de la premiere borne du lot.
  premiere <- as.numeric(regmatches(
    toutes$wkt[[1L]],
    regexec("^POINT \\(([0-9.]+) ([0-9.]+)\\)", toutes$wkt[[1L]])
  )[[1L]][2:3])
  emprise <- data.frame(wkt = sprintf(
    "POLYGON((%1$f %2$f, %3$f %2$f, %3$f %4$f, %1$f %4$f, %1$f %2$f))",
    premiere[[1L]] - 10, premiere[[2L]] - 10,
    premiere[[1L]] + 10, premiere[[2L]] + 10
  ), stringsAsFactors = FALSE)

  autour <- sommier_fond_pci_lire(fond, "bornes", emprise = emprise,
                                  marge_m = 20)
  expect_lt(nrow(autour), nrow(toutes))
  expect_gte(nrow(autour), 1L)
})

test_that("une couche absente du lot rend un tableau vide, pas une erreur", {
  # Toutes les feuilles ne portent pas toutes les couches : une feuille sans
  # voirie est un cas ordinaire, pas une anomalie.
  fond <- fond_edigeo()
  fond$feuilles$thf <- fond$feuilles$thf   # lot reel, couche `parcelles` presente
  parcelles <- sommier_fond_pci_lire(fond, "parcelles")
  expect_gt(nrow(parcelles), 0L)
  expect_match(parcelles$wkt[[1L]], "^POLYGON|^MULTIPOLYGON")
})

test_that("un lot deja decompresse n'est pas retelecharge", {
  # Le chemin ordinaire des executions suivantes, et il doit valoir hors ligne.
  skip_if_not_installed("sf")
  archive <- testthat::test_path("fixtures", "edigeo-212000000A01.tar.bz2")
  skip_if_not(file.exists(archive), "Fixture EDIGEO absente.")
  cache <- withr::local_tempdir()
  dossier <- file.path(cache, "pci", "212000000A01")
  dir.create(dossier, recursive = TRUE)
  utils::untar(archive, exdir = dossier, tar = "internal")

  fond <- sommier_fond_pci("21200", "212000000A01", cache = cache)
  expect_equal(nrow(fond$feuilles), 1L)
  expect_true(file.exists(fond$feuilles$thf))
  expect_output(print(fond), "212000000A01")
})

test_that("les feuilles se listent et se restreignent a l'emprise", {
  # Le cache pre-rempli evite le reseau : c'est aussi le chemin suivi des la
  # deuxieme execution en production.
  skip_if_not_installed("sf")
  cache <- withr::local_tempdir()
  chemin <- file.path(cache, "cadastre-21200-feuilles.json.gz")

  carre <- function(x, y, cote = 0.004) {
    sf::st_polygon(list(rbind(c(x, y), c(x + cote, y), c(x + cote, y + cote),
                              c(x, y + cote), c(x, y))))
  }
  feuilles <- sf::st_sf(
    id = c("212000000A01", "212000000A02", "21200000AB01"),
    section = c("A", "A", "AB"), echelle = c("5000", "2500", "1000"),
    geometry = sf::st_sfc(carre(4.949, 47.269), carre(4.953, 47.269),
                          carre(5.010, 47.245), crs = 4326)
  )
  brut <- sub("\\.gz$", "", chemin)
  sf::st_write(feuilles, brut, driver = "GeoJSON", quiet = TRUE)
  connexion <- gzfile(chemin, "w")
  writeLines(readLines(brut, warn = FALSE), connexion)
  close(connexion)
  unlink(brut)
  writeLines("2026-06-01", paste0(chemin, ".millesime"))

  toutes <- sommier_feuilles_pci("21200", cache = cache)
  expect_equal(nrow(toutes), 3L)
  expect_setequal(names(toutes), c("feuille", "section", "echelle", "wkt"))
  expect_equal(toutes$echelle[[1L]], 5000)

  # L'emprise de la foret ne retient que les feuilles qui la touchent : on ne
  # telecharge pas dix-sept archives pour regarder trois parcelles.
  emprise <- data.frame(wkt = paste0(
    "POLYGON((847400 6687300, 847600 6687300, 847600 6687500, ",
    "847400 6687500, 847400 6687300))"
  ), stringsAsFactors = FALSE)
  autour <- sommier_feuilles_pci("21200", emprise = emprise, cache = cache)
  expect_lt(nrow(autour), nrow(toutes))
  expect_true("212000000A01" %in% autour$feuille)
  expect_false("21200000AB01" %in% autour$feuille)
})
