# Fond cadastral : ce qui se verifie sans reseau, et ce qui l'exige.

test_that("le code INSEE est controle avant tout appel", {
  # Un code errone doit echouer ici, pas apres un telechargement inutile.
  expect_error(sommier_fond_cadastral("212"), "cinq caracteres")
  expect_error(sommier_fond_cadastral("Couchey"), "cinq caracteres")
  expect_error(sommier_fond_cadastral("21200", couche = "bornes"),
               "couche")
})

test_that("la Corse passe, ses codes commencant par 2A ou 2B", {
  expect_silent(valider_code_insee("2A004"))
  expect_silent(valider_code_insee("2B033"))
})

test_that("les couches annoncees sont celles que la source publie", {
  # Verifie le 20 aout 2026 sur cadastre.data.gouv.fr : ni bornes ni fosses
  # dans ces livraisons simplifiees. Ils sont dans le PCI vecteur EDIGEO, que
  # `sommier_fond_pci()` va chercher ailleurs - et une borne DGFiP reste de
  # toute facon la donnee d'un tiers, le constat du gestionnaire etant au
  # registre 2.
  expect_setequal(SOMMIER_COUCHES_CADASTRE,
                  c("parcelles", "sections", "batiments", "lieux_dits",
                    "feuilles"))
  expect_false("bornes" %in% SOMMIER_COUCHES_CADASTRE)
  expect_false("fosses" %in% SOMMIER_COUCHES_CADASTRE)
})

test_that("un fond absent du cache se dit plutot que de se deviner", {
  fond <- structure(
    list(chemin = file.path(tempdir(), "absent.json.gz"),
         code_insee = "21200", couche = "parcelles",
         millesime = NA_character_, source = "test"),
    class = "sommier_fond"
  )
  skip_if_not_installed("sf")
  expect_error(sommier_fond_lire(fond), "absent du cache")
})

test_that("sommier_fond_lire refuse ce qui ne vient pas du telechargement", {
  expect_error(sommier_fond_lire(data.frame(x = 1)),
               "sommier_fond_cadastral")
})

test_that("le millesime absent ne se remplace pas par une date inventee", {
  # Un fond date a tort vaut moins qu'un fond non date.
  expect_true(is.na(millesime_publie("file:///introuvable/")))
})

test_that("le fond se telecharge, se met en cache et porte son millesime", {
  skip_on_cran()
  testthat::skip_if_offline()
  skip_if_not_installed("sf")
  cache <- withr::local_tempdir()

  # Une panne du serveur d'Etalab saute ce test ; un 404 le fait echouer.
  fond <- sauter_si_source_indisponible(
    sommier_fond_cadastral("21200", cache = cache)
  )
  expect_true(file.exists(fond$chemin))
  expect_equal(fond$code_insee, "21200")
  expect_match(fond$millesime, "^[0-9]{4}-[0-9]{2}-[0-9]{2}$")

  # Deuxieme appel : le cache sert, et le millesime survit au redemarrage.
  horodatage <- file.info(fond$chemin)$mtime
  encore <- sommier_fond_cadastral("21200", cache = cache)
  expect_equal(file.info(encore$chemin)$mtime, horodatage)
  expect_equal(encore$millesime, fond$millesime)

  # L'emprise restreint : Couchey compte des milliers de parcelles, une foret
  # n'en couvre qu'une poignee.
  emprise <- data.frame(wkt = paste0(
    "POLYGON((847000 6687000, 848000 6687000, 848000 6688000, ",
    "847000 6688000, 847000 6687000))"
  ))
  commune <- sommier_fond_lire(fond)
  autour <- sommier_fond_lire(fond, emprise = emprise)
  expect_gt(nrow(commune), nrow(autour))
  expect_gt(nrow(autour), 0L)
  expect_equal(attr(autour, "millesime"), fond$millesime)
  expect_match(autour$wkt[[1L]], "POLYGON")
})

# Fixture locale : une livraison cadastrale miniature, ecrite puis compressee
# comme celles du serveur. Elle permet d'exercer la lecture, le decoupage et
# les attributs sans reseau — l'essentiel de ce que fait le paquet une fois le
# fichier obtenu.
fond_fixture <- function(env = parent.frame()) {
  skip_if_not_installed("sf")
  dossier <- withr::local_tempdir(.local_envir = env)
  chemin <- file.path(dossier, "cadastre-21200-parcelles.json.gz")

  carre <- function(x, y, cote = 0.001) {
    sf::st_polygon(list(rbind(
      c(x, y), c(x + cote, y), c(x + cote, y + cote), c(x, y + cote), c(x, y)
    )))
  }
  couche <- sf::st_sf(
    id = c("212000000A0054", "212000000A0999"),
    commune = "21200", section = "A", numero = c("54", "999"),
    contenance = c(25000L, 18000L),
    geometry = sf::st_sfc(carre(4.951, 47.271), carre(4.990, 47.250),
                          crs = 4326)
  )
  brut <- sub("\\.gz$", "", chemin)
  sf::st_write(couche, brut, driver = "GeoJSON", quiet = TRUE)
  contenu <- readLines(brut, warn = FALSE)
  connexion <- gzfile(chemin, "w")
  writeLines(contenu, connexion)
  close(connexion)
  unlink(brut)

  structure(
    list(chemin = chemin, code_insee = "21200", couche = "parcelles",
         millesime = "2026-06-01", source = "fixture locale",
         telecharge_le = "20/08/2026"),
    class = "sommier_fond"
  )
}

test_that("un fond se lit depuis son archive, sans la decompresser", {
  fond <- fond_fixture()
  parcelles <- sommier_fond_lire(fond)

  expect_equal(nrow(parcelles), 2L)
  expect_equal(parcelles$reference[[1L]], "212000000A0054")
  expect_equal(parcelles$contenance_m2[[1L]], 25000)
  # La sortie est en Lambert-93, comme les couches du sommier : melanger deux
  # systemes sur le meme dessin les decalerait.
  expect_match(parcelles$wkt[[1L]], "^POLYGON")
  expect_gt(as.numeric(sub(".*\\(\\(([0-9.]+) .*", "\\1", parcelles$wkt[[1L]])),
            100000)
})

test_that("l'emprise restreint le fond a ce qui entoure la foret", {
  # Couchey compte pres de trois mille parcelles, une foret n'en couvre qu'une
  # poignee : un fond illisible ne renseigne personne.
  fond <- fond_fixture()
  emprise <- data.frame(wkt = paste0(
    "POLYGON((847400 6687300, 847600 6687300, 847600 6687500, ",
    "847400 6687500, 847400 6687300))"
  ))
  autour <- sommier_fond_lire(fond, emprise = emprise, marge_m = 200)
  expect_equal(nrow(autour), 1L)
  expect_equal(autour$reference, "212000000A0054")
})

test_that("le fond porte sa source et son millesime jusqu'au lecteur", {
  # Un fond sans millesime induit en erreur des l'annee suivante.
  fond <- fond_fixture()
  parcelles <- sommier_fond_lire(fond)
  expect_equal(attr(parcelles, "millesime"), "2026-06-01")
  expect_equal(attr(parcelles, "source"), "fixture locale")
})

test_that("une marge negative est refusee", {
  fond <- fond_fixture()
  expect_error(sommier_fond_lire(fond, marge_m = -10), "marge_m")
})

test_that("un telechargement qui echoue ne laisse pas de fichier a moitie ecrit", {
  # Un cache silencieusement corrompu serait pire qu'un cache vide : il se
  # relirait sans erreur, en rendant moins de parcelles qu'il n'en existe.
  destination <- withr::local_tempfile(fileext = ".json.gz")
  expect_error(
    suppressWarnings(telecharger("file:///introuvable/cadastre.json.gz",
                                 destination)),
    "Telechargement du fond cadastral impossible"
  )
  expect_false(file.exists(destination))
})

test_that("un hote injoignable et un fichier absent ne se confondent pas", {
  # Les confondre ferait passer une regression pour une panne, et l'inverse.
  # C'est ce qui a fait echouer la CI de `main` le 27 aout 2026 : le
  # garde-fou `skip_if_offline()` demande s'il y a un internet, pas si cet
  # hote-la repond.
  skip_if_not_installed("curl")
  destination <- withr::local_tempfile(fileext = ".gz")

  injoignable <- tryCatch(
    telecharger("https://hote-qui-n-existe-pas.invalid/x.gz", destination),
    error = function(e) e
  )
  expect_s3_class(injoignable, "sommier_reseau_indisponible")
  expect_s3_class(injoignable, "sommier_erreur_telechargement")

  # Un serveur qui repond 404 dit que le fichier n'est pas la ou on le
  # cherche : l'URL est fausse, ou la source a bouge.
  skip_on_cran()
  testthat::skip_if_offline()
  absente <- tryCatch(
    telecharger(paste0(SOMMIER_SOURCE_CADASTRE,
                       "/latest/geojson/communes/21/21200/introuvable.json.gz"),
                destination),
    error = function(e) e
  )
  skip_if(inherits(absente, "sommier_reseau_indisponible"),
          "source distante injoignable")
  expect_s3_class(absente, "sommier_ressource_absente")
  expect_false(file.exists(destination))
})

test_that("le garde-fou saute sur une panne et laisse passer un 404", {
  saute <- tryCatch(
    sauter_si_source_indisponible(stop(structure(
      class = c("sommier_reseau_indisponible", "sommier_erreur_telechargement",
                "error", "condition"),
      list(message = "hote injoignable", call = NULL)
    ))),
    condition = function(c) class(c)[[1L]]
  )
  expect_equal(saute, "skip")

  # Une ressource absente n'est pas rattrapee : elle doit faire echouer.
  expect_error(
    sauter_si_source_indisponible(stop(structure(
      class = c("sommier_ressource_absente", "sommier_erreur_telechargement",
                "error", "condition"),
      list(message = "statut HTTP 404", call = NULL)
    ))),
    "404"
  )
})

test_that("le cache se cree a la demande", {
  racine <- withr::local_tempdir()
  cible <- file.path(racine, "cadastre", "2026")
  expect_false(dir.exists(cible))
  expect_equal(repertoire_cache(cible), cible)
  expect_true(dir.exists(cible))
})

test_that("un fond deja en cache ne se retelecharge pas", {
  # C'est le chemin ordinaire en production : on telecharge une fois par
  # millesime, on relit ensuite. Il doit donc marcher hors ligne.
  cache <- withr::local_tempdir()
  chemin <- file.path(cache, "cadastre-21200-parcelles.json.gz")
  writeLines("fixture", chemin)
  writeLines("2026-06-01", paste0(chemin, ".millesime"))

  fond <- sommier_fond_cadastral("21200", cache = cache)
  expect_equal(fond$chemin, chemin)
  expect_equal(fond$millesime, "2026-06-01")
  expect_equal(fond$code_insee, "21200")
  expect_equal(readLines(chemin, warn = FALSE), "fixture")
})

test_that("le millesime se lit sur l'index publie", {
  # Le millesime n'est pas dans le fichier : il est dans le chemin vers lequel
  # `latest` redirige, que le serveur affiche sur l'index du dossier.
  index <- withr::local_tempfile(fileext = ".html")
  writeLines(c(
    "<html><head><title>Index</title></head><body>",
    "<h1>Index of /etalab-cadastre/2026-06-01/geojson/communes/21/21200/</h1>",
    "<a href=\"cadastre-21200-parcelles.json.gz\">parcelles</a>",
    "</body></html>"
  ), index)

  expect_equal(millesime_publie(paste0("file://", index)), "2026-06-01")
})

test_that("un index sans millesime ne s'invente pas de date", {
  index <- withr::local_tempfile(fileext = ".html")
  writeLines("<html><body>Index of /quelque/part/</body></html>", index)
  expect_true(is.na(millesime_publie(paste0("file://", index))))
})

test_that("un fond en cache sans millesime enregistre le dit inconnu", {
  cache <- withr::local_tempdir()
  writeLines("fixture", file.path(cache, "cadastre-21200-sections.json.gz"))
  fond <- sommier_fond_cadastral("21200", couche = "sections", cache = cache)
  expect_true(is.na(fond$millesime))
  # Et l'affichage le dit plutot que de laisser un `NA` nu.
  expect_output(print(fond), "millesime : inconnu")
})
