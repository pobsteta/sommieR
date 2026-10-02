# Le sommier imprime : le registre ecriture par ecriture, rectifiees
# comprises, contre une base reelle.

base_registre <- function() {
  con <- sauter_sans_base()
  withr::defer(DBI::dbDisconnect(con), envir = parent.frame())
  sommier_init_schema(con)
  con
}

# La demo ne s'efface pas : un suffixe aleatoire la rend rejouable.
suffixe_registre <- function(prefixe) {
  paste0(prefixe, "-", substr(uuid_v4(), 1L, 8L))
}

ecrire_r <- function(con, foret, registre, payload, date = "2026-03-01",
                     corrige_id = NULL) {
  sommier_ajouter(con, sommier_entree(
    foret_id = foret, registre = registre, date_evenement = date,
    auteur = "agent-01", payload = payload, corrige_id = corrige_id
  ))[[1L]]
}

test_that("le sommier imprime chaque ecriture, transcriptions comprises", {
  con <- base_registre()
  demo <- sommier_demo_couchey(con, suffixe = suffixe_registre("registre"))
  s <- sommier_registre(con, demo$foret_id)

  expect_s3_class(s, "sommier_registre")
  n <- DBI::dbGetQuery(con, "SELECT count(*)::int AS n FROM entree_sommier
                              WHERE foret_id = $1",
                       params = list(demo$foret_id))$n
  expect_equal(nrow(s$ecritures), n)
  # Dans chaque registre, l'ordre de la chaine.
  for (r in unique(s$ecritures$registre)) {
    expect_false(is.unsorted(s$ecritures$seq[s$ecritures$registre == r]))
  }
  # Une transcription porte sa piece ; un constat n'en porte pas.
  transcrites <- s$ecritures[s$ecritures$provenance == "transcription", ]
  expect_gt(nrow(transcrites), 0L)
  expect_true(all(grepl("registre_signe|base_gestionnaire|temoignage",
                        transcrites$piece)))
  expect_true(all(is.na(s$ecritures$piece[s$ecritures$provenance ==
                                            "constat"])))
  # Les empreintes sont celles de la chaine, et la derniere est la tete.
  lues <- sommier_lire(con, demo$foret_id)
  ordre <- order(s$ecritures$seq)
  expect_equal(s$ecritures$hash[ordre], lues$hash)
  expect_equal(s$ecritures$hash[ordre][[n]], s$verification$hash_tete)
  expect_true(s$verification$valide)
  # La fiche A10 porte les actes de visa de la demo, non signes.
  expect_true(all(2021:2024 %in% s$tenue$exercice))
  expect_false(any(s$tenue$signe, na.rm = TRUE))

  # Un registre seul.
  r5 <- sommier_registre(con, demo$foret_id, registres = 5)
  expect_true(all(r5$ecritures$registre == 5L))
})

test_that("une ecriture rectifiee reste, avec les mentions croisees", {
  con <- base_registre()
  foret <- foret_creer(con, "Foret rectifiee", "communal")
  cible <- ecrire_r(con, foret, 5L,
                    registre5_coupe("martelage", 2026, "amelioration", 120))
  ecrire_r(con, foret, 5L,
           registre5_coupe("martelage", 2026, "amelioration", 102),
           corrige_id = cible$id)
  s <- sommier_registre(con, foret)
  e <- s$ecritures
  expect_equal(nrow(e), 2L)
  expect_equal(e$rectifiee_par[e$seq == 1], 2)
  expect_equal(e$rectifie[e$seq == 2], 1)
  expect_true(is.na(e$rectifie[e$seq == 1]))
})

test_that("une edition s'arrete au visa, et pas a un exercice non vise", {
  con <- base_registre()
  foret <- foret_creer(con, "Foret visee", "communal")
  ecrire_r(con, foret, 5L,
           registre5_coupe("martelage", 2026, "amelioration", 120))
  cle <- openssl::rsa_keygen(2048L)
  visa <- sommier_viser(con, foret, 2026, "commune",
                        signataire_cle(cle, claims = list(sub = "maire-01")))
  ecrire_r(con, foret, 5L,
           registre5_coupe("martelage", 2027, "reguliere", 80), "2027-03-01")

  tout <- sommier_registre(con, foret)
  arrete <- sommier_registre(con, foret, jusqu_au_visa = 2026)
  expect_gt(nrow(tout$ecritures), nrow(arrete$ecritures))
  expect_equal(max(arrete$ecritures$seq), as.numeric(visa$seq_tete))
  expect_true(arrete$visa$concorde)
  expect_true(arrete$tenue$signe[arrete$tenue$exercice == 2026])
  expect_error(sommier_registre(con, foret, jusqu_au_visa = 2025),
               "pas de visa")
})

test_that("un sommier a transmettre masque les tiers, sans perdre de ligne", {
  con <- base_registre()
  foret <- foret_creer(con, "Foret transmise", "communal")
  ecrire_r(con, foret, 3L, registre3_droit(
    "bail_chasse", "Location de chasse", titulaire = "Jean Dupont",
    date_debut = "2026-04-01", date_expiration = "2035-03-31"
  ))
  ecrire_r(con, foret, 7L, registre7_ecriture(
    "bois_sur_pied", 2026, montant_eur = 4200, tiers = "SARL Bois du Nord"
  ))
  s <- sommier_registre(con, foret)
  masque <- masquer_tiers(s$ecritures)
  expect_equal(nrow(masque), nrow(s$ecritures))
  expect_false(any(grepl("Dupont|Bois du Nord", masque$payload)))
  expect_false(any(grepl("Dupont|Bois du Nord", masque$contenu)))
  expect_true(any(grepl("4200", masque$payload)))

  skip_if(!nzchar(Sys.which("quarto")), "Quarto n'est pas installe.")
  avant <- sommier_verifier(con, foret)$hash_tete
  chemin <- withr::local_tempfile(fileext = ".html")
  sommier_registre_quarto(con, foret, chemin, public = TRUE)
  html <- paste(readLines(chemin, warn = FALSE, encoding = "UTF-8"),
                collapse = "\n")
  expect_no_match(html, "Dupont")
  expect_no_match(html, "Bois du Nord")
  expect_match(html, "Version à transmettre", fixed = TRUE)
  expect_equal(sommier_verifier(con, foret)$hash_tete, avant)
})

test_that("le sommier de la demo se rend, et ne touche pas la chaine", {
  skip_if(!nzchar(Sys.which("quarto")), "Quarto n'est pas installe.")
  con <- base_registre()
  demo <- sommier_demo_couchey(con, suffixe = suffixe_registre("registre-rendu"))
  avant <- sommier_verifier(con, demo$foret_id)$hash_tete
  chemin <- withr::local_tempfile(fileext = ".html")
  sommier_registre_quarto(con, demo$foret_id, chemin)
  html <- paste(readLines(chemin, warn = FALSE, encoding = "UTF-8"),
                collapse = "\n")
  expect_match(html, "<title>Sommier de la forêt", fixed = TRUE)
  expect_match(html, "Tenue du sommier (A10)", fixed = TRUE)
  expect_match(html, "Ce document n’est pas la preuve|Ce document n'est pas la preuve")
  expect_match(html, "transcrite", fixed = TRUE)
  expect_match(html, avant, fixed = TRUE)
  expect_equal(sommier_verifier(con, demo$foret_id)$hash_tete, avant)
  expect_error(sommier_registre_quarto(con, demo$foret_id, "s.pdf",
                                       format = "html"),
               "ne correspond pas")
})
