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
