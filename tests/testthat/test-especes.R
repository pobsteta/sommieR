# Les especes observees par d'autres, nommees dans TAXREF - sans reseau, et
# sans rien ecrire dans la chaine.

# Une archive TAXREF d'essai, au format de celle de GBIF France : quelques
# lignes de `taxon.txt` et un `eml.xml` qui dit la version.
archive_taxref <- function(version = "TAXREF v18.0", env = parent.frame()) {
  skip_if(!nzchar(Sys.which("zip")), "zip n'est pas installe.")
  dossier <- withr::local_tempdir(.local_envir = env)
  colonnes <- c("id", "taxonID", "scientificNameID", "acceptedNameUsageID",
                "parentNameUsageID", "originalNameUsageID", "scientificName",
                "acceptedNameUsage", "kingdom", "phylum", "class", "order",
                "superfamily", "family", "subfamily", "tribe", "subtribe",
                "genus", "subgenus", "specificEpithet", "infraspecificEpithet",
                "cultivarEpithet", "taxonRank", "scientificNameAuthorship",
                "vernacularName", "taxonRemarks", "references")
  ligne <- function(cd_nom, cd_ref, nom, auteur, rang = "species",
                    regne = "Animalia", embranchement = "Chordata",
                    classe = "Aves", ordre = "Piciformes",
                    vernaculaire = "") {
    x <- stats::setNames(as.list(rep("", length(colonnes))), colonnes)
    x[c("id", "taxonID", "acceptedNameUsageID", "scientificName",
        "scientificNameAuthorship", "taxonRank", "kingdom", "phylum", "class",
        "order", "vernacularName")] <- list(
      cd_nom, cd_nom, cd_ref, nom, auteur, rang, regne, embranchement, classe,
      ordre, vernaculaire)
    paste(unlist(x), collapse = "\t")
  }
  lignes <- c(
    paste(colonnes, collapse = "\t"),
    # Le pic mar et son synonyme : une seule espece.
    ligne(3619, 3619, "Dendrocopos medius", "(Linnaeus, 1758)",
          vernaculaire = "Pic mar (Le)"),
    ligne(1046450, 3619, "Dendrocoptes medius", "(Linnaeus, 1758)"),
    # Un homonyme : seul l'auteur departage.
    ligne(88766, 88766, "Carex pendula", "Huds., 1762", regne = "Plantae",
          embranchement = "", classe = "Equisetopsida", ordre = "Poales",
          vernaculaire = "Laiche pendante"),
    ligne(88767, 132707, "Carex pendula", "Schreb., 1771", regne = "Plantae",
          embranchement = "", classe = "Equisetopsida", ordre = "Poales"),
    ligne(132707, 132707, "Carex autre", "Schreb., 1771", regne = "Plantae",
          embranchement = "", classe = "Equisetopsida", ordre = "Poales"),
    # Un emploi errone ne rapproche rien.
    ligne(78064, 851674, "Natrix natrix", "auct. non (Linnaeus, 1758)",
          classe = "", ordre = "Squamata"),
    ligne(851674, 851674, "Natrix helvetica", "(Lacepede, 1789)",
          classe = "", ordre = "Squamata", vernaculaire = "Couleuvre helvetique"),
    ligne(4272, 4272, "Phylloscopus sibilatrix", "(Bechstein, 1793)",
          ordre = "Passeriformes", vernaculaire = "Pouillot siffleur (Le)"),
    # Une espece sensible : sa position ne se publie pas.
    ligne(2660, 2660, "Pandion haliaetus", "(Linnaeus, 1758)",
          ordre = "Accipitriformes", vernaculaire = "Balbuzard pecheur (Le)"),
    # Un genre : hors des especes, il n'est pas garde.
    ligne(190000, 190000, "Dendrocopos", "Koch, 1816", rang = "genus")
  )
  writeLines(lignes, file.path(dossier, "taxon.txt"), useBytes = TRUE)
  writeLines(paste0("<eml><title>", version, "</title></eml>"),
             file.path(dossier, "eml.xml"))
  zip <- file.path(dossier, "taxref.zip")
  withr::with_dir(dossier, utils::zip(zip, c("taxon.txt", "eml.xml"),
                                      flags = "-q"))
  zip
}

# Deux unites de 1 km de cote en Lambert-93, et des observations placees par
# leurs coordonnees Lambert-93, rendues en WGS84 comme GBIF les donne.
emprise_essai <- function() {
  carre <- function(x0) sprintf(
    "POLYGON((%1$d 6760000,%2$d 6760000,%2$d 6761000,%1$d 6761000,%1$d 6760000))",
    x0, x0 + 1000L)
  data.frame(numero_affichage = c("A", "B"),
             wkt = c(carre(630000L), carre(631000L)), stringsAsFactors = FALSE)
}

occurrences_essai <- function() {
  o <- data.frame(
    x = c(630500, 630600, 631500, 630500, 631200, 631300, 630100, 640000),
    y = c(6760500, 6760500, 6760500, 6760500, 6760300, 6760300, 6760100,
          6760500),
    species = c("Dendrocopos medius", "Dendrocoptes medius",
                "Dendrocopos medius", "Carex pendula", "Natrix natrix",
                "Phylloscopus sibillatrix", "Dendrocopos medius",
                "Dendrocopos medius"),
    kingdom = c("Animalia", "Animalia", "Animalia", "Plantae", "Animalia",
                "Animalia", "Animalia", "Animalia"),
    scientificName = c("Dendrocopos medius (Linnaeus, 1758)",
                       "Dendrocoptes medius (Linnaeus, 1758)",
                       "Dendrocopos medius (Linnaeus, 1758)",
                       "Carex pendula Huds.", "Natrix natrix (Linnaeus, 1758)",
                       "Phylloscopus sibillatrix (Bechstein, 1792)",
                       "Dendrocopos medius (Linnaeus, 1758)",
                       "Dendrocopos medius (Linnaeus, 1758)"),
    originalNameUsage = c(NA, NA, NA, NA, "Couleuvre a collier",
                          "Phylloscopus sibilatrix", NA, NA),
    # La quatrieme observation du pic est floutee : comptee, pas placee.
    coordinateUncertaintyInMeters = c(10, 30, 50, 20, 10, 10, 5000, 10),
    year = c(2015L, 2021L, 2023L, 2019L, 2018L, 2022L, 2010L, 2020L),
    datasetKey = c("jeu-1", "jeu-1", "jeu-2", "jeu-2", "jeu-1", "jeu-1",
                   "jeu-1", "jeu-1"),
    license = "http://creativecommons.org/licenses/by/4.0/legalcode",
    stringsAsFactors = FALSE
  )
  points <- sf::st_transform(sf::st_as_sf(o, coords = c("x", "y"), crs = 2154),
                             4326)
  xy <- sf::st_coordinates(points)
  o$decimalLongitude <- xy[, 1L]
  o$decimalLatitude <- xy[, 2L]
  o$x <- NULL
  o$y <- NULL
  o
}

test_that("TAXREF se lit dans l'archive, avec sa version, et se garde", {
  zip <- archive_taxref()
  cache <- withr::local_tempdir()
  taxref <- sommier_taxref(cache = cache, source = zip)
  expect_equal(attr(taxref, "version"), "TAXREF v18.0")
  expect_type(taxref$cd_nom, "integer")
  # Les especes seulement : le genre n'est pas garde.
  expect_false(190000L %in% taxref$cd_nom)
  expect_equal(taxref$cd_ref[taxref$cd_nom == 1046450L], 3619L)
  # Le cache sert ensuite, meme si la source a disparu.
  unlink(zip)
  expect_identical(sommier_taxref(cache = cache, source = zip), taxref)
})

test_that("une archive qui ne dit pas sa version est refusee", {
  zip <- archive_taxref(version = "Referentiel")
  expect_error(sommier_taxref(cache = withr::local_tempdir(), source = zip),
               "ne dit pas sa version")
})

test_that("un nom se rapproche de TAXREF, ou reste non rapproche", {
  taxref <- sommier_taxref(cache = withr::local_tempdir(),
                           source = archive_taxref())
  cd <- rapprocher_taxref(
    c("Dendrocoptes medius", "Carex pendula", "Carex pendula",
      "Natrix natrix", "Phylloscopus sibillatrix", "Dendrocopos medius"),
    c("Animalia", "Plantae", "Plantae", "Animalia", "Animalia", "Plantae"),
    taxref,
    noms_complets = c(NA, "Carex pendula Huds.", NA, NA, NA, NA),
    noms_originaux = c(NA, NA, NA, "Couleuvre a collier",
                       "Phylloscopus sibilatrix", NA)
  )
  # Synonyme : le nom valide. Homonyme : l'auteur departage, et sans auteur
  # rien. Emploi errone : rien. Graphie de GBIF : le nom d'origine. Autre
  # regne : rien.
  expect_equal(cd, c(3619L, 88766L, NA, NA, 4272L, NA))
})

test_that("les especes se comptent par nom valide, et se placent si precises", {
  skip_if_not_installed("sf")
  taxref <- sommier_taxref(cache = withr::local_tempdir(),
                           source = archive_taxref())
  e <- sommier_especes_observees(emprise_essai(), taxref, tampon_m = 100,
                                 depuis = 2000, incertitude_max_m = 100,
                                 occurrences = occurrences_essai())
  pic <- e[e$cd_ref == 3619L, ]
  # Quatre observations dans la zone, sous deux noms ; la cinquieme, a 9 km,
  # est hors de la zone. La floutee compte mais ne designe pas d'unite.
  expect_equal(pic$n_observations, 4L)
  expect_equal(pic$ug, "A, B")
  expect_equal(c(pic$premiere_annee, pic$derniere_annee), c(2010L, 2023L))
  expect_equal(pic$n_jeux, 2L)
  expect_equal(pic$nom_vernaculaire, "Pic mar (Le)")
  expect_equal(pic$groupe, "Oiseaux")
  expect_equal(sort(e$cd_ref), c(3619L, 4272L, 88766L))
  expect_equal(e$groupe[e$cd_ref == 88766L], "Plantes")
  expect_equal(attr(e, "non_rapprochees")$nom, "Natrix natrix")
  expect_equal(attr(e, "taxref"), "TAXREF v18.0")
  jeux <- attr(e, "jeux")
  expect_equal(jeux$n_observations[jeux$cle == "jeu-1"], 5L)
  expect_true(is.na(jeux$titre[[1L]]))

  # Sans la precision, l'unite n'est pas dite.
  flou <- sommier_especes_observees(emprise_essai(), taxref, tampon_m = 100,
                                    incertitude_max_m = 1,
                                    occurrences = occurrences_essai())
  expect_true(all(is.na(flou$ug)))
})

test_that("un document public ne rattache aucune espece a une unite", {
  skip_if_not_installed("sf")
  taxref <- sommier_taxref(cache = withr::local_tempdir(),
                           source = archive_taxref())
  e <- sommier_especes_observees(emprise_essai(), taxref, tampon_m = 100,
                                 occurrences = occurrences_essai())
  public <- valider_especes_observees(e, public = TRUE)
  expect_null(public$ug)
  expect_equal(attr(public, "taxref"), "TAXREF v18.0")
  expect_false(is.null(valider_especes_observees(e, public = FALSE)$ug))
  expect_error(valider_especes_observees(data.frame(x = 1), FALSE),
               "sommier_especes_observees")
})

test_that("le groupe se lit dans la classification", {
  expect_equal(
    groupe_taxref(c("Animalia", "Animalia", "Animalia", "Plantae", "Fungi",
                    "Animalia", "Chromista"),
                  c("Chordata", "Chordata", "Arthropoda", "", "Ascomycota",
                    "Mollusca", "Ochrophyta"),
                  c("Aves", "", "Insecta", "Equisetopsida", "Lecanoromycetes",
                    "Gastropoda", ""),
                  c("Piciformes", "Squamata", "Coleoptera", "Poales", "",
                    "", "")),
    c("Oiseaux", "Reptiles", "Insectes", "Plantes", "Champignons et lichens",
      "Mollusques", "Autres")
  )
})

# ---------------------------------------------------------------------------
# Les statuts, lus dans la BDC Statuts par l'API TAXREF - sans reseau : les
# reponses de l'API au lieu de la foret d'Orleans, une par taxon, sont dans
# fixtures/statuts-taxref-orleans.json (voir fixtures/PROVENANCE.md).

# Remplace l'API par ses reponses enregistrees, et compte les appels.
api_enregistree <- function(env = parent.frame()) {
  reponses <- jsonlite::fromJSON(
    testthat::test_path("fixtures", "statuts-taxref-orleans.json"),
    simplifyVector = FALSE
  )
  appels <- new.env()
  appels$taxons <- integer(0)
  testthat::local_mocked_bindings(
    api_taxref = function(source, chemin, requete = list()) {
      if (identical(chemin, "taxrefVersions/current")) {
        return(reponses[["taxrefVersions/current"]])
      }
      appels$taxons <- c(appels$taxons, as.integer(requete$taxrefId))
      # L'API repond 404 d'un taxon qu'elle ne connait pas.
      reponses[[as.character(requete$taxrefId)]]
    },
    .env = env
  )
  appels
}

test_that("les statuts se lisent taxon par taxon, au lieu de la foret, et se gardent", {
  skip_if_not_installed("sf")
  appels <- api_enregistree()
  cache <- withr::local_tempdir()
  s <- sommier_statuts_taxref(c(3619L, 4272L, 999999L), emprise_essai(),
                              cache = cache)
  expect_equal(attr(s, "version"), "BDC Statuts, TAXREF v18.0")
  expect_equal(attr(s, "lieu"), "INSEEC45142")
  expect_equal(sort(attr(s, "consultes")), c(3619L, 4272L, 999999L))
  expect_equal(sort(unique(s$cd_ref)), c(3619L, 4272L))
  # Le pic mar est protege, et a l'annexe I de la directive Oiseaux.
  expect_true(all(c("PN", "DO") %in% s$type[s$cd_ref == 3619L]))
  expect_equal(s$lieu[s$cd_ref == 4272L & s$type == "LRR"], "Centre")
  expect_equal(sort(appels$taxons), c(3619L, 4272L, 999999L))

  # Le second appel ne demande que le taxon nouveau.
  appels$taxons <- integer(0)
  s2 <- sommier_statuts_taxref(c(3619L, 2660L), emprise_essai(), cache = cache)
  expect_equal(appels$taxons, 2660L)
  expect_equal(sort(unique(s2$cd_ref)), c(2660L, 3619L))
  # Et le cache sert sans reseau.
  appels$taxons <- integer(0)
  sommier_statuts_taxref(c(3619L, 2660L), emprise_essai(), cache = cache)
  expect_length(appels$taxons, 0L)
})

test_that("les especes observees gagnent leurs statuts", {
  skip_if_not_installed("sf")
  api_enregistree()
  taxref <- sommier_taxref(cache = withr::local_tempdir(),
                           source = archive_taxref())
  # Un balbuzard, precisement place dans l'unite A.
  o <- occurrences_essai()
  balbuzard <- o[1L, ]
  balbuzard$species <- "Pandion haliaetus"
  balbuzard$scientificName <- "Pandion haliaetus (Linnaeus, 1758)"
  o <- rbind(o, balbuzard)
  e <- sommier_especes_observees(emprise_essai(), taxref, tampon_m = 100,
                                 statuts = TRUE,
                                 cache = withr::local_tempdir(),
                                 occurrences = o)
  expect_equal(attr(e, "statuts"), "BDC Statuts, TAXREF v18.0")
  ligne <- function(cd) e[e$cd_ref == cd, ]
  expect_equal(ligne(3619L)$protection, "nationale")
  expect_equal(ligne(3619L)$directives, "DO I")
  expect_true(ligne(3619L)$protegee)
  expect_false(ligne(3619L)$sensible)
  # Trois evaluations nationales pour le balbuzard : la plus grave compte.
  expect_equal(ligne(2660L)$liste_rouge_nationale, "VU")
  expect_equal(ligne(2660L)$liste_rouge_regionale, "EN")
  expect_true(ligne(2660L)$sensible)
  expect_equal(ligne(4272L)$liste_rouge_regionale, "VU")
  # La laiche n'est pas protegee, et le sait.
  expect_false(ligne(88766L)$protegee)
  expect_true(is.na(ligne(88766L)$protection))
  # Les noms de chaque espece, synonyme compris.
  noms <- attr(e, "noms_taxref")
  expect_equal(noms$cd_ref[noms$cd_nom == 1046450L], 3619L)

  # Document public : le balbuzard, sensible, perd son unite ; le pic mar
  # garde les siennes.
  public <- valider_especes_observees(e, public = TRUE)
  expect_true(is.na(public$ug[public$cd_ref == 2660L]))
  expect_equal(public$ug[public$cd_ref == 3619L], "A, B")
  # Une espece dont on ne connait pas les statuts la perd aussi.
  e$sensible[e$cd_ref == 3619L] <- NA
  expect_true(is.na(valider_especes_observees(e, TRUE)$ug[e$cd_ref == 3619L]))
})

test_that("une table de statuts d'ailleurs est refusee", {
  skip_if_not_installed("sf")
  taxref <- sommier_taxref(cache = withr::local_tempdir(),
                           source = archive_taxref())
  expect_error(
    sommier_especes_observees(emprise_essai(), taxref, tampon_m = 100,
                              statuts = data.frame(cd_ref = 3619L),
                              occurrences = occurrences_essai()),
    "sommier_statuts_taxref"
  )
})

test_that("une fiche d'espece porte son CD_NOM, controle contre TAXREF", {
  taxref <- sommier_taxref(cache = withr::local_tempdir(),
                           source = archive_taxref())
  p <- registre9_espece("Pic mar", "Dendrocopos medius", cd_nom = 3619,
                        taxref = taxref)
  expect_equal(p$cd_nom, 3619)
  expect_null(p$taxref)
  # Le CD_NOM d'un synonyme, sous le nom valide : admis.
  expect_silent(registre9_espece("Pic mar",
                                 "Dendrocopos medius (Linnaeus, 1758)",
                                 cd_nom = 1046450, taxref = taxref))
  expect_error(registre9_espece("Pic mar", "Dendrocopos medius",
                                cd_nom = 123456789, taxref = taxref),
               "n'est pas une espece de TAXREF v18.0")
  expect_error(registre9_espece("Pic mar", "Dendrocopos major",
                                cd_nom = 3619, taxref = taxref),
               "n'est pas le nom du `cd_nom`")
  expect_error(registre9_espece("Pic mar", "Dendrocopos medius", cd_nom = 0),
               "cd_nom")
  # Sans TAXREF, le CD_NOM est seulement un entier.
  expect_equal(registre9_espece("Pic mar", "Dendrocopos medius",
                                cd_nom = 3619)$cd_nom, 3619)

  # Le registre 9 change de version ; une fiche anterieure, sans CD_NOM,
  # se relit a l'identique, et une fiche nouvelle aussi.
  expect_equal(SOMMIER_SCHEMA_VERSIONS[["9"]], "r9-1.3.0")
  ancienne <- list(type_fiche = "espece", nom_francais = "Sabot de Venus",
                   nom_latin = "Cypripedium calceolus", effectif = 34)
  expect_identical(registre9_depuis_payload(ancienne), ancienne)
  relue <- jsonlite::fromJSON(jsonlite::toJSON(p, auto_unbox = TRUE),
                              simplifyVector = FALSE)
  expect_equal(registre9_depuis_payload(relue)$cd_nom, 3619)
})
