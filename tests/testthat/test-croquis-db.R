# Sommier, lot 3 : les croquis. Une annexe de lecture, hors chaine : chaque
# ecriture localisee, rectifiees comprises, dans la foret de son epoque.

base_croquis <- function() {
  con <- sauter_sans_base()
  withr::defer(DBI::dbDisconnect(con), envir = parent.frame())
  sommier_init_schema(con)
  con
}

# Ce que la base sait localiser, compte sans passer par l'extraction : une
# geometrie propre, une unite qui a un contour, ou la foret entiere pour ce
# qui n'a ni l'une ni l'autre, hors visas et comptes.
compter_localisees <- function(con, foret, jusqu_a = 9e15) {
  DBI::dbGetQuery(
    con,
    "SELECT count(*)::int AS n FROM entree_sommier e
      WHERE e.foret_id = $1 AND e.seq <= $2
        AND (e.geom IS NOT NULL OR EXISTS (
          SELECT 1 FROM ug_geometrie g WHERE g.ug_uuid = e.ug_uuid)
          OR (e.ug_uuid IS NULL AND e.registre NOT IN (1, 7)))",
    params = list(foret, jusqu_a)
  )$n
}

# La demo de Couchey, enrichie de ce qu'elle n'a pas : une rectification
# d'une position, un relevé repete, un visa.
couchey_enrichie <- function(con) {
  demo <- sommier_demo_couchey(
    con, suffixe = paste0("croquis-", substr(uuid_v4(), 1L, 8L))
  )
  lues <- sommier_lire(con, demo$foret_id)
  sabot <- lues[lues$registre == 9L &
                  grepl("Cypripedium", lues$payload), , drop = FALSE]
  corrigee <- sommier_ajouter(con, sommier_entree(
    foret_id = demo$foret_id, registre = 9L, date_evenement = "2021-05-28",
    auteur = "agent-01", ug_uuid = demo$ug[["102"]], corrige_id = sabot$id[[1L]],
    payload = registre9_espece(
      "Sabot de Venus", "Cypripedium calceolus", effectif = 26,
      localisation = "Versant nord, A 102",
      geometrie = geom_point(4.938700, 47.264400)
    )
  ))[[1L]]
  repetee <- sommier_ajouter(con, sommier_entree(
    foret_id = demo$foret_id, registre = 9L, date_evenement = "2025-05-20",
    auteur = "agent-01", ug_uuid = demo$ug[["102"]],
    payload = registre9_espece(
      "Sabot de Venus", "Cypripedium calceolus", effectif = 31,
      localisation = "Versant nord, A 102",
      geometrie = geom_point(4.938720, 47.264410)
    )
  ))[[1L]]
  cle <- openssl::rsa_keygen(2048L)
  visa <- sommier_viser(con, demo$foret_id, 2025, "commune",
                        signataire_cle(cle, claims = list(sub = "maire-01")))
  apres <- sommier_ajouter(con, sommier_entree(
    foret_id = demo$foret_id, registre = 9L, date_evenement = "2026-05-02",
    auteur = "agent-01", ug_uuid = demo$ug[["102"]],
    payload = registre9_espece(
      "Sabot de Venus", "Cypripedium calceolus", effectif = 29,
      geometrie = geom_point(4.938730, 47.264420)
    )
  ))[[1L]]
  c(demo, list(sabot = as.numeric(sabot$seq[[1L]]),
               corrigee = as.numeric(corrigee$seq),
               repetee = as.numeric(repetee$seq), visa = visa,
               apres = as.numeric(apres$seq)))
}

test_that("chaque ecriture localisee a son croquis, rectifiees comprises", {
  con <- base_croquis()
  d <- couchey_enrichie(con)
  s <- sommier_registre(con, d$foret_id)
  o <- s$croquis$objets

  # Comptage : autant d'objets que d'ecritures localisees.
  expect_equal(nrow(o), compter_localisees(con, d$foret_id))
  expect_equal(s$croquis$non_localisees, nrow(s$ecritures) - nrow(o))
  # La rectifiee reste, marquee ; sa rectification et le relevé repete aussi.
  expect_true(all(c(d$sabot, d$corrigee, d$repetee, d$apres) %in% o$seq))
  expect_equal(o$rectifiee_par[o$seq == d$sabot], d$corrigee)
  expect_equal(o$rectifie[o$seq == d$corrigee], d$sabot)
  expect_true(all(o$localisation[o$seq %in% c(d$sabot, d$repetee)] ==
                    "propre"))
  # Un martelage n'a pas de position : il se localise par son unite.
  par_ug <- o[o$localisation == "ug", , drop = FALSE]
  expect_gt(nrow(par_ug), 0L)
  expect_true(all(is.na(par_ug$wkt)))
  expect_true(all(!is.na(par_ug$contour_version)))
  # Les positions propres sont en Lambert-93.
  propres <- o[o$localisation == "propre", , drop = FALSE]
  expect_true(all(grepl("^(POINT|LINESTRING|POLYGON)", propres$wkt)))
  expect_true(all(propres$x_l93 > 800000 & propres$x_l93 < 900000))
  # La provenance suit l'ecriture.
  expect_setequal(unique(o$provenance), c("constat", "transcription"))
  # Les contours sont rendus avec leur source.
  expect_equal(nrow(s$croquis$contours), 3L)
  expect_true(all(grepl("cadastre DGFiP", s$croquis$contours$source)))
  expect_equal(s$croquis$date_situation, format(Sys.Date(), "%Y-%m-%d"))

  # Un registre seul : ses croquis seuls.
  r9 <- sommier_registre(con, d$foret_id, registres = 9)
  expect_true(all(r9$croquis$objets$registre == 9L))

  # Arretee au visa, l'extraction s'arrete a la tete visee.
  arrete <- sommier_registre(con, d$foret_id, jusqu_au_visa = 2025)
  expect_false(d$apres %in% arrete$croquis$objets$seq)
  expect_true(d$repetee %in% arrete$croquis$objets$seq)
  expect_equal(nrow(arrete$croquis$objets),
               compter_localisees(con, d$foret_id, d$visa$seq_tete))
  expect_equal(arrete$croquis$date_situation, arrete$visa$date_visa)
  expect_output(print(s), "croquis")
})

test_that("chaque ecriture se lit dans le contour de son epoque", {
  con <- base_croquis()
  foret <- foret_creer(con, "Foret aux contours changeants", "communal")
  parent <- ug_creer(con, foret, "1", date_debut = "2016-01-01")
  poser <- function(ug, version, wkt, debut, fin = NA, source = "levé GNSS") {
    DBI::dbExecute(
      con,
      "INSERT INTO ug_geometrie (ug_uuid, version, geom, source, date_debut,
                                 date_fin)
       VALUES ($1, $2, ST_Multi(ST_GeomFromText($3, 2154)), $4, $5::date,
               $6::date)",
      params = list(ug, version, wkt, source, debut, fin)
    )
  }
  poser(parent, 1L, "POLYGON((850000 6700000, 850400 6700000, 850400 6700300, 850000 6700300, 850000 6700000))",
        "2016-01-01", "2019-12-31", "plan d'amenagement 2016")
  poser(parent, 2L, "POLYGON((850000 6700000, 850500 6700000, 850500 6700300, 850000 6700300, 850000 6700000))",
        "2020-01-01", "2023-06-30", "plan d'amenagement 2020")
  ecrire <- function(date, ug, payload = registre5_coupe(
    "martelage", as.integer(substr(date, 1L, 4L)), "amelioration", 50)) {
    sommier_ajouter(con, sommier_entree(
      foret_id = foret, registre = 5L, date_evenement = date,
      auteur = "agent-01", ug_uuid = ug, payload = payload
    ))[[1L]]
  }
  ancienne <- ecrire("2010-03-01", parent)
  v1 <- ecrire("2018-03-01", parent)
  v2 <- ecrire("2021-03-01", parent)
  enfants <- ug_scinder(con, parent, list(list(numero_affichage = "1a"),
                                          list(numero_affichage = "1b")),
                        "2023-07-01")
  poser(enfants[[1L]], 1L, "POLYGON((850000 6700000, 850250 6700000, 850250 6700300, 850000 6700300, 850000 6700000))",
        "2023-07-01")
  fille <- ecrire("2024-03-01", enfants[[1L]])
  # Une ecriture sur l'unite fermee, apres sa cloture : son dernier contour.
  tardive <- ecrire("2025-03-01", parent)

  o <- sommier_registre(con, foret)$croquis$objets
  version <- function(e) o$contour_version[o$seq == as.numeric(e$seq)]
  vigueur <- function(e) o$contour_en_vigueur[o$seq == as.numeric(e$seq)]
  expect_equal(version(v1), 1L)
  expect_equal(version(v2), 2L)
  expect_equal(version(fille), 1L)
  expect_equal(o$ug[o$seq == as.numeric(fille$seq)], "1a")
  # Avant tout contour connu, le plus proche, dit non en vigueur.
  expect_equal(version(ancienne), 1L)
  expect_false(vigueur(ancienne))
  expect_equal(version(tardive), 2L)
  expect_false(vigueur(tardive))
  expect_true(vigueur(v1))

  cq <- sommier_registre(con, foret)$croquis
  expect_equal(nrow(cq$contours), 3L)
  expect_setequal(cq$contours$source[cq$contours$ug == "1"],
                  c("plan d'amenagement 2016", "plan d'amenagement 2020"))
  expect_equal(nrow(cq$filiations), 2L)
  expect_true(all(cq$filiations$type_filiation == "scission"))
})

test_that("une ecriture sans geometrie ni unite se rattache a la foret", {
  con <- base_croquis()
  foret <- foret_creer(con, "Foret sans carte", "communal")
  martelage <- sommier_ajouter(con, sommier_entree(
    foret_id = foret, registre = 5L, date_evenement = "2026-03-01",
    auteur = "agent-01",
    payload = registre5_coupe("martelage", 2026, "amelioration", 50)
  ))[[1L]]
  # Une ligne de comptes ne designe rien sur le terrain.
  sommier_ajouter(con, sommier_entree(
    foret_id = foret, registre = 7L, date_evenement = "2026-12-15",
    auteur = "agent-01",
    payload = registre7_ecriture("bois_sur_pied", 2026, montant_eur = 4150)
  ))
  cq <- sommier_registre(con, foret)$croquis
  expect_equal(nrow(cq$objets), 1L)
  expect_equal(cq$objets$seq, as.numeric(martelage$seq))
  expect_equal(cq$objets$localisation, "foret")
  expect_true(is.na(cq$objets$wkt))
  expect_true(is.na(cq$objets$contour_version))
  expect_true(is.na(cq$objets$contour_en_vigueur))
  expect_equal(cq$non_localisees, 1L)
  expect_equal(nrow(cq$objets), compter_localisees(con, foret))
  expect_equal(nrow(cq$contours), 0L)

  # Les comptes seuls : rien a dessiner.
  comptes <- sommier_registre(con, foret, registres = 7)$croquis
  expect_equal(nrow(comptes$objets), 0L)
  expect_equal(comptes$non_localisees, 1L)

  # Sans contour ni position, le document se rend : la liste seule.
  skip_if_not_installed("sf")
  skip_if(!nzchar(Sys.which("quarto")), "Quarto n'est pas installe.")
  sortie <- withr::local_tempfile(fileext = ".html")
  sommier_registre_quarto(con, foret, sortie)
  html <- paste(readLines(sortie, warn = FALSE, encoding = "UTF-8"),
                collapse = "\n")
  expect_match(html, "1 rattachée(s) à la forêt", fixed = TRUE)
  # Pandoc rend l'apostrophe typographique.
  expect_match(html, "plan de situation n.est pas dessiné")
  expect_match(html, "la forêt entière", fixed = TRUE)
})

test_that("a public = TRUE, une espece sensible quitte le croquis", {
  con <- base_croquis()
  d <- couchey_enrichie(con)
  s <- sommier_registre(con, d$foret_id)
  ref <- sommier_sensibilite(test_path("fixtures", "RefSensibilite_99.csv"))
  sabots <- c(d$sabot, d$corrigee, d$repetee, d$apres)

  cote_dor <- flouter_sensibles(s, ref, "21", as.Date("2026-10-24"))
  o <- cote_dor$croquis$objets
  floutees <- o[o$localisation == "floutee", , drop = FALSE]
  expect_setequal(floutees$seq, sabots)
  expect_true(all(is.na(floutees$wkt)))
  expect_true(all(is.na(floutees$ug)))
  expect_true(all(is.na(floutees$x_l93)))
  expect_true(all(grepl("commune", floutees$floutage)))
  # L'unite et le libelle de localisation sont tus au registre aussi.
  e <- cote_dor$ecritures
  expect_true(all(is.na(e$ug[e$seq %in% sabots])))
  expect_false(any(grepl("Versant nord", e$payload[e$seq %in% sabots])))
  expect_false(any(grepl("Versant nord", e$contenu[e$seq %in% sabots])))
  # Le reste ne bouge pas.
  avant <- s$croquis$objets
  expect_equal(o[!o$seq %in% sabots, ], avant[!avant$seq %in% sabots, ])

  # Tous departements : la maille 10 km, nommee comme celle de l'INPN.
  partout <- flouter_sensibles(s, ref, NULL, as.Date("2026-10-24"))
  m <- partout$croquis$objets$floutage[partout$croquis$objets$seq == d$sabot]
  x <- s$croquis$objets$x_l93[s$croquis$objets$seq == d$sabot]
  y <- s$croquis$objets$y_l93[s$croquis$objets$seq == d$sabot]
  expect_match(m, sprintf("10kmL93E%03dN%03d", floor(x / 10000),
                          floor(y / 10000)), fixed = TRUE)
  expect_match(m, "sensibilité SINP 2", fixed = TRUE)

  # Sans referentiel, rien n'est diffuse ; hors de ses departements, tout.
  sans <- flouter_sensibles(s, NULL, NULL, Sys.Date())
  expect_true(all(grepl("non diffus", sans$croquis$objets$floutage[
    sans$croquis$objets$seq %in% sabots])))
  loiret <- flouter_sensibles(s, ref, "45", Sys.Date())
  expect_identical(loiret, s)
})

test_that("le sommier se rend avec ses croquis, et la version publique les floute", {
  skip_if(!nzchar(Sys.which("quarto")), "Quarto n'est pas installe.")
  skip_if_not_installed("sf")
  con <- base_croquis()
  d <- couchey_enrichie(con)
  avant <- sommier_verifier(con, d$foret_id)$hash_tete
  chemin <- withr::local_tempfile(fileext = ".html")
  sommier_registre_quarto(con, d$foret_id, chemin)
  html <- paste(readLines(chemin, warn = FALSE, encoding = "UTF-8"),
                collapse = "\n")
  n <- compter_localisees(con, d$foret_id)
  expect_match(html, "Annexe : croquis", fixed = TRUE)
  expect_match(html, "hors chaîne", fixed = TRUE)
  expect_match(html, "Plan de situation", fixed = TRUE)
  expect_match(html, paste0(n, " écriture(s) localisée(s)"), fixed = TRUE)
  expect_match(html, paste0("rectifiée par le n° ", d$corrigee), fixed = TRUE)
  expect_match(html, "Lambert-93 (EPSG:2154)", fixed = TRUE)
  expect_match(html, "cadastre DGFiP", fixed = TRUE)
  expect_match(html, "Versant nord", fixed = TRUE)
  # Un plan de situation et un croquis par unite, plus les objets hors unite.
  expect_gte(lengths(regmatches(html, gregexpr("<img", html))), 4L)

  ref <- sommier_sensibilite(test_path("fixtures", "RefSensibilite_99.csv"))
  public <- withr::local_tempfile(fileext = ".html")
  sommier_registre_quarto(con, d$foret_id, public, public = TRUE,
                          sensibilite = ref, departement = "21")
  html <- paste(readLines(public, warn = FALSE, encoding = "UTF-8"),
                collapse = "\n")
  expect_match(html, "Localisations floutées", fixed = TRUE)
  expect_match(html, "à la commune", fixed = TRUE)
  expect_match(html, "version 99", fixed = TRUE)
  expect_match(html, attr(ref, "empreinte"), fixed = TRUE)
  expect_match(html, "4 floutée(s)", fixed = TRUE)
  expect_no_match(html, "Versant nord")
  expect_equal(sommier_verifier(con, d$foret_id)$hash_tete, avant)

  expect_error(sommier_registre_quarto(con, d$foret_id, public, public = TRUE,
                                       sensibilite = data.frame()),
               "sommier_sensibilite")
})

test_that("un parcellaire fourni se pose sous les croquis, source et millesime dits", {
  skip_if(!nzchar(Sys.which("quarto")), "Quarto n'est pas installe.")
  skip_if_not_installed("sf")
  con <- base_croquis()
  d <- couchey_enrichie(con)
  # Deux parcelles ecrites a la main autour de l'UG 102, au format de
  # sommier_fond_lire() : le test ne va pas chercher le cadastre.
  boite <- DBI::dbGetQuery(
    con,
    "SELECT ST_XMin(geom) AS x0, ST_YMin(geom) AS y0, ST_XMax(geom) AS x1,
            ST_YMax(geom) AS y1 FROM ug_geometrie WHERE ug_uuid = $1",
    params = list(d$ug[["102"]])
  )
  xm <- (boite$x0 + boite$x1) / 2
  carre <- function(x0, x1) sprintf(
    "POLYGON((%f %f, %f %f, %f %f, %f %f, %f %f))", x0, boite$y0, x1,
    boite$y0, x1, boite$y1, x0, boite$y1, x0, boite$y0)
  fond <- data.frame(
    reference = c("212000000A0901", "212000000A0902"),
    section = "A", numero = c("0901", "0902"),
    contenance_m2 = c(1000, 1000),
    wkt = c(carre(boite$x0, xm), carre(xm, boite$x1)),
    stringsAsFactors = FALSE
  )
  attr(fond, "source") <- "cadastre de test"
  attr(fond, "millesime") <- "2099-01-01"

  chemin <- withr::local_tempfile(fileext = ".html")
  sommier_registre_quarto(con, d$foret_id, chemin, fond = fond)
  html <- paste(readLines(chemin, warn = FALSE, encoding = "UTF-8"),
                collapse = "\n")
  expect_match(html, "parcellaire cadastral en surimpression", fixed = TRUE)
  expect_match(html, "millésime 2099-01-01", fixed = TRUE)
  expect_match(html, "cadastre de test", fixed = TRUE)
  expect_error(sommier_registre_quarto(con, d$foret_id, chemin,
                                       fond = list(a = 1)),
               "sommier_fond_lire")
})

test_that("le PDF du sommier est un PDF/A, croquis compris", {
  skip_on_ci()
  skip_if(!nzchar(Sys.which("quarto")), "Quarto n'est pas installe.")
  skip_if_not_installed("sf")
  skip_if(Sys.which("pdflatex") == "" && Sys.which("lualatex") == "" &&
            !dir.exists(file.path(Sys.getenv("HOME"), ".TinyTeX")),
          "LaTeX n'est pas installe.")
  con <- base_croquis()
  d <- couchey_enrichie(con)
  chemin <- withr::local_tempfile(fileext = ".pdf")
  sommier_registre_quarto(con, d$foret_id, chemin, format = "pdf")
  octets <- readBin(chemin, "raw", file.size(chemin))
  # La declaration PDF/A-2B, dans les metadonnees XMP. La conformite elle-meme
  # se juge avec veraPDF, hors des tests.
  expect_length(grepRaw("<pdfaid:part>2<", octets, fixed = TRUE), 1L)
  expect_length(grepRaw("<pdfaid:conformance>B<", octets, fixed = TRUE), 1L)
})
