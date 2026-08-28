# Ce que ces tests defendent : une transcription ne doit jamais pouvoir se
# faire passer pour un constat. Trois proprietes le garantissent - la source
# est citee, le NDP est superieur a 0, et `date_saisie` est l'instant reel de
# l'ecriture. Chacune a son test, parce que chacune se perdrait seule.

coupe_1998 <- function(...) {
  registre5_coupe("martelage", 1998, "amelioration", volume_m3 = 210, ...)
}

piece <- function(...) {
  reprise_source(
    "registre_signe",
    "Sommier papier, imprime A50E, exercice 1998, folio 12",
    ...
  )
}

reprise_test <- function(payload = coupe_1998(), source = piece(), ...) {
  sommier_reprise(
    foret_id = FORET_TEST, registre = 5L, date_evenement = "1998-03-12",
    auteur = "agent-01", payload = payload, source = source, ...
  )
}

test_that("l'echelle de NDP couvre les provenances usuelles, et jamais 0", {
  echelle <- SOMMIER_SOURCES_REPRISE
  expect_true(all(echelle$ndp >= 1))
  # Croissante : le NDP s'eloigne a mesure que la piece s'eloigne du fait.
  expect_equal(echelle$ndp, sort(echelle$ndp))
  expect_false(any(duplicated(echelle$source)))
  expect_true(all(nzchar(echelle$description)))
})

test_that("une reprise porte sa source dans le payload, donc dans l'empreinte", {
  e <- reprise_test()
  expect_s3_class(e, "sommier_reprise")
  expect_s3_class(e, "sommier_entree")
  expect_equal(e$payload$reprise$source, "registre_signe")
  expect_match(e$payload$reprise$reference, "A50E")
  # Le payload entre dans l'enregistrement canonique : deux reprises du meme
  # fait depuis deux pieces differentes ne peuvent pas avoir la meme empreinte.
  autre <- reprise_test(source = reprise_source("tableur", "Suivi coupes.xlsx"))
  h <- function(x) {
    x$seq <- 1
    sommier_empreinte(x, sommier_empreinte_genese(FORET_TEST))
  }
  expect_false(identical(h(e), h(autre)))
})

test_that("le NDP suit la provenance, et ne peut pas valoir 0", {
  expect_equal(reprise_test()$ndp, 1)
  expect_equal(
    reprise_test(source = reprise_source("base_gestionnaire", "Export ONF"))$ndp,
    2
  )
  expect_equal(reprise_test(source = reprise_source("tableur", "x.xlsx"))$ndp, 3)
  expect_equal(reprise_test(source = reprise_source("temoignage", "dire"))$ndp, 4)

  # Un appelant peut juger une piece moins bonne que son type ne le suggere ;
  # il ne peut pas la juger meilleure qu'un constat.
  expect_equal(reprise_test(ndp = 3)$ndp, 3)
  expect_error(reprise_test(ndp = 0), "NDP 0")
  expect_error(reprise_test(ndp = -1), "ndp")
})

test_that("`date_saisie` est l'instant de l'ecriture et ne se dicte pas", {
  # La decision centrale du lot : une chaine qui peut etre convaincue d'avoir
  # su plus tot qu'elle n'a su ne vaut rien.
  expect_error(
    reprise_test(date_saisie = "1998-03-12T09:00:00Z"),
    "date_saisie"
  )
  e <- reprise_test()
  ecart <- abs(as.numeric(difftime(
    as.POSIXct(e$date_saisie, format = "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
    Sys.time(), units = "secs"
  )))
  expect_lt(ecart, 120)
  # Et la date du fait, elle, reste libre de remonter aussi loin qu'il faut.
  expect_equal(e$date_evenement, "1998-03-12")
})

test_that("une reprise sans source citee est refusee", {
  expect_error(
    sommier_reprise(
      foret_id = FORET_TEST, registre = 5L, date_evenement = "1998-03-12",
      auteur = "agent-01", payload = coupe_1998()
    ),
    "source"
  )
  expect_error(reprise_test(source = list(source = "registre_signe")),
               "reference")
  expect_error(reprise_test(source = list(reference = "un papier")), "source")
  expect_error(reprise_test(source = reprise_source("archive", "x")), "source")
  expect_error(
    valider_reprise(list(source = "tableur", reference = "x", auteur = "y")),
    "inconnu"
  )
})

test_that("une reprise ne transcrit qu'une piece, et pas l'avenir", {
  deja <- coupe_1998()
  deja$reprise <- piece()
  expect_error(reprise_test(payload = deja), "deja un bloc")

  demain <- format(Sys.Date() + 1L, "%Y-%m-%d")
  expect_error(
    sommier_reprise(
      foret_id = FORET_TEST, registre = 5L, date_evenement = demain,
      auteur = "agent-01", payload = coupe_1998(), source = piece()
    ),
    "avenir"
  )
})

test_that("le bloc de reprise survit a un aller-retour par le JSON", {
  # C'est ce que fait un verificateur tiers sur un export : il relit du JSON,
  # sans passer par les constructeurs.
  e <- reprise_test(source = piece(date_piece = "1999-01-15",
                                   detenteur = "Commune de Couchey"))
  relu <- jsonlite::fromJSON(jcs(e$payload), simplifyVector = FALSE)
  expect_equal(jcs(valider_payload(5L, relu)), jcs(e$payload))
})

test_that("la chaine d'une foret reprise se verifie comme une autre", {
  entrees <- sommier_chainer(list(
    reprise_test(),
    reprise_test(payload = registre5_coupe("martelage", 1995, "reguliere",
                                           volume_m3 = 88)),
    entree_test(1L)
  ))
  rapport <- sommier_verifier_chaine(entrees)
  expect_true(rapport$valide)
  # La sequence est celle de l'ecriture : elle ne suit pas les dates.
  expect_equal(vapply(entrees, function(e) e$seq, numeric(1)), c(1, 2, 3))
})

test_that("sommier_reprendre n'ecrit que des reprises", {
  # Le controle precede tout acces a la base : une entree ordinaire ne doit
  # pas meme etre presentee a la transaction.
  expect_error(sommier_reprendre(NULL, entree_test(1L)), "sommier_reprise")
  expect_error(sommier_reprendre(NULL, list(reprise_test(), entree_test(1L))),
               "sommier_reprise")
  expect_error(sommier_reprendre(NULL, list()), "non vide")
})

test_that("l'affichage d'une reprise dit de quelle piece elle sort", {
  sortie <- paste(utils::capture.output(print(reprise_test())), collapse = "\n")
  expect_match(sortie, "transcrit")
  expect_match(sortie, "A50E")
})

# ---------------------------------------------------------------------
# En base
# ---------------------------------------------------------------------

base_reprise <- function() {
  con <- sauter_sans_base()
  withr::defer(DBI::dbDisconnect(con), envir = parent.frame())
  sommier_init_schema(con)
  con
}

foret_vierge <- function(con) {
  foret_creer(con, paste0("Foret de reprise ", uuid_v4()), "communal")
}

test_that("un lot transcrit s'ecrit en bloc et se rend compte", {
  con <- base_reprise()
  foret <- foret_vierge(con)

  constat <- sommier_entree(
    foret_id = foret, registre = 5L, date_evenement = "2026-03-05",
    auteur = "agent-01",
    payload = registre5_coupe("martelage", 2026, "amelioration", volume_m3 = 40)
  )
  sommier_ajouter(con, constat)

  a50e <- reprise_source("registre_signe", "Imprime A50E, exercices 1996-1999")
  a50j <- reprise_source("base_gestionnaire", "Base travaux du gestionnaire")
  lot <- list(
    sommier_reprise(foret_id = foret, registre = 5L,
                    date_evenement = "1999-02-10", auteur = "agent-01",
                    payload = registre5_coupe("martelage", 1999, "reguliere",
                                              volume_m3 = 120),
                    source = a50e),
    sommier_reprise(foret_id = foret, registre = 5L,
                    date_evenement = "1996-04-02", auteur = "agent-01",
                    payload = registre5_coupe("martelage", 1996, "sanitaire",
                                              volume_m3 = 75),
                    source = a50e),
    sommier_reprise(foret_id = foret, registre = 6L,
                    date_evenement = "1997-11-20", auteur = "agent-01",
                    payload = registre6_travaux(1997, "plantation",
                                                nb_plants = 900),
                    source = a50j)
  )
  cr <- sommier_reprendre(con, lot)

  expect_s3_class(cr, "sommier_compte_rendu_reprise")
  expect_equal(cr$n, 3L)
  expect_equal(cr$date_min, "1996-04-02")
  expect_equal(cr$date_max, "1999-02-10")
  expect_equal(nrow(cr$pieces), 2L)
  expect_setequal(cr$registres$registre, c(5, 6))

  # Le bloc est contigu et vient apres le constat : la chaine date l'histoire,
  # elle ne la rejoue pas.
  expect_equal(cr$seq_debut, 2)
  expect_equal(cr$seq_fin, 4)
  entrees <- sommier_lire(con, foret)
  expect_equal(entrees$date_evenement,
               c("2026-03-05", "1999-02-10", "1996-04-02", "1997-11-20"))
  expect_true(sommier_verifier(con, foret)$valide)
})

test_that("les vues de consultation marquent le repris", {
  con <- base_reprise()
  foret <- foret_vierge(con)
  sommier_ajouter(con, sommier_entree(
    foret_id = foret, registre = 5L, date_evenement = "2026-03-05",
    auteur = "agent-01",
    payload = registre5_coupe("martelage", 2026, "amelioration", volume_m3 = 40)
  ))
  sommier_reprendre(con, sommier_reprise(
    foret_id = foret, registre = 5L, date_evenement = "1999-02-10",
    auteur = "agent-01",
    payload = registre5_coupe("martelage", 1999, "reguliere", volume_m3 = 120),
    source = reprise_source("registre_signe", "Imprime A50E, exercice 1999",
                            date_piece = "2000-01-08")
  ))

  coupes <- DBI::dbGetQuery(
    con,
    "SELECT exercice, repris, reprise_source, reprise_reference
       FROM v_coupe WHERE foret_id = $1 ORDER BY exercice",
    params = list(foret)
  )
  expect_equal(coupes$repris, c(TRUE, FALSE))
  expect_equal(coupes$reprise_source, c("registre_signe", NA_character_))
  expect_match(coupes$reprise_reference[[1L]], "A50E")
})

test_that("la provenance se compte registre par registre", {
  con <- base_reprise()
  foret <- foret_vierge(con)
  sommier_ajouter(con, sommier_entree(
    foret_id = foret, registre = 5L, date_evenement = "2026-03-05",
    auteur = "agent-01",
    payload = registre5_coupe("martelage", 2026, "amelioration", volume_m3 = 40)
  ))
  piece_a50e <- reprise_source("registre_signe", "Imprime A50E, 1996-1999")
  sommier_reprendre(con, list(
    sommier_reprise(foret_id = foret, registre = 5L,
                    date_evenement = "1999-02-10", auteur = "agent-01",
                    payload = registre5_coupe("martelage", 1999, "reguliere",
                                              volume_m3 = 120),
                    source = piece_a50e),
    sommier_reprise(foret_id = foret, registre = 5L,
                    date_evenement = "1996-04-02", auteur = "agent-01",
                    payload = registre5_coupe("martelage", 1996, "sanitaire",
                                              volume_m3 = 75),
                    source = piece_a50e)
  ))

  prov <- sommier_provenance(con, foret)
  expect_equal(nrow(prov), 1L)
  expect_equal(prov$registre, 5)
  expect_equal(prov$n_constate, 1)
  expect_equal(prov$n_transcrit, 2)
  expect_equal(prov$n_pieces, 1)
  expect_equal(prov$transcrit_du, "1996-04-02")
  expect_equal(prov$transcrit_au, "1999-02-10")

  # Bornee sur la periode, elle ne compte que ce que la periode contient.
  recente <- sommier_provenance(con, foret, debut = "2020-01-01")
  expect_equal(recente$n_transcrit, 0)
  expect_true(is.na(recente$transcrit_du))
})

test_that("le rapport de gestion anterieure distingue les deux provenances", {
  con <- base_reprise()
  foret <- foret_vierge(con)
  sommier_ajouter(con, sommier_entree(
    foret_id = foret, registre = 5L, date_evenement = "2024-03-05",
    auteur = "agent-01",
    payload = registre5_coupe("martelage", 2024, "amelioration", volume_m3 = 40)
  ))
  sommier_reprendre(con, sommier_reprise(
    foret_id = foret, registre = 5L, date_evenement = "2018-02-10",
    auteur = "agent-01",
    payload = registre5_coupe("martelage", 2018, "reguliere", volume_m3 = 120),
    source = reprise_source("registre_signe", "Imprime A50E, exercice 2018")
  ))

  ga <- sommier_gestion_anterieure(con, foret, debut = "2016-01-01",
                                   fin = "2025-12-31")
  expect_true("provenance" %in% names(ga$sections))
  expect_equal(sum(ga$sections$provenance$n_transcrit), 1)
  expect_setequal(ga$sections$coupes$provenance, c("constate", "transcrit"))
  # Et le Markdown le porte : un tableau muet ferait passer la recopie pour
  # de la mesure.
  md <- sommier_rapport_markdown(ga)
  expect_match(md, "Provenance des ecritures")
  expect_match(md, "transcrit")
})

test_that("le manifeste d'une foret reprise se verifie chez le destinataire", {
  # Critere du brief : la chaine d'une foret reprise se verifie comme une
  # autre, et son manifeste aussi. Le bloc de provenance voyage donc avec.
  con <- base_reprise()
  foret <- foret_vierge(con)
  sommier_reprendre(con, sommier_reprise(
    foret_id = foret, registre = 5L, date_evenement = "1998-03-12",
    auteur = "agent-01",
    payload = registre5_coupe("martelage", 1998, "amelioration",
                              volume_m3 = 210),
    source = reprise_source("registre_signe", "Imprime A50E, exercice 1998")
  ))

  chemin <- withr::local_tempfile(fileext = ".json")
  sommier_exporter_manifeste(con, foret, chemin)
  rapport <- sommier_verifier_manifeste(chemin)
  expect_true(rapport$valide)
  expect_match(paste(readLines(chemin, warn = FALSE), collapse = ""),
               "A50E, exercice 1998")
})

test_that("un lot de plusieurs milliers d'entrees passe en une fois", {
  # L'insertion decoupe par paquets de 1000 ; le lot traverse donc la borne.
  # L'empreinte reste calculee cote R, entree par entree : la canonisation ne
  # se delegue pas a la base.
  con <- base_reprise()
  foret <- foret_vierge(con)
  piece_lot <- reprise_source("base_gestionnaire", "Export complet 1990-2015")

  lot <- lapply(seq_len(1200L), function(i) {
    sommier_reprise(
      foret_id = foret, registre = 6L,
      date_evenement = sprintf("%04d-%02d-15", 1990 + (i %% 26L), (i %% 12L) + 1L),
      auteur = "agent-01",
      payload = registre6_travaux(1990 + (i %% 26L), "degagement",
                                  quantite = i / 100, unite = "ha"),
      source = piece_lot
    )
  })
  cr <- sommier_reprendre(con, lot)

  expect_equal(cr$n, 1200L)
  expect_equal(cr$seq_fin - cr$seq_debut + 1, 1200)
  expect_equal(nrow(cr$pieces), 1L)
  expect_true(sommier_verifier(con, foret)$valide)
})
