# Flux de visa et de detections contre une base reelle.

base_visa <- function() {
  con <- sauter_sans_base()
  withr::defer(DBI::dbDisconnect(con), envir = parent.frame())
  sommier_init_schema(con)
  con
}

# L'autorite d'horodatage vient de helper-tsa.R : depuis que tsa_horodater()
# confronte l'empreinte et le nonce du jeton, un jeton bricole ne passe plus,
# et il faut une autorite qui reponde vraiment. Elle est montee localement -
# les tests ne dependent toujours d'aucun service externe.

foret_avec_entree <- function(con) {
  foret <- foret_creer(con, "Foret test", "communal")
  sommier_ajouter(con, sommier_entree(
    foret_id = foret, registre = 5L, date_evenement = "2026-03-01",
    auteur = "agent-01",
    payload = registre5_coupe("martelage", 2026, "amelioration", 120)
  ))
  foret
}

test_that("un visa signe couvre la tete de chaine et se verifie", {
  con <- base_visa()
  foret <- foret_avec_entree(con)
  cle <- openssl::rsa_keygen(2048L)
  s <- signataire_cle(cle, claims = list(sub = "maire-01", name = "Maire"),
                      kid = "cle-2026")

  visa <- sommier_viser(con, foret, 2026, "commune", s)
  expect_true(visa$horodate == FALSE)          # aucune TSA configuree

  rapport <- sommier_verifier_visas(con, foret, list(`cle-2026` = cle$pubkey))
  expect_equal(nrow(rapport), 1L)
  expect_true(rapport$concorde)
  expect_true(rapport$signature_valide)
  expect_false(rapport$horodate)
  expect_match(rapport$remarque, "sans jeton d'horodatage")
})

test_that("le visa couvre l'entree qui trace sa propre delivrance", {
  # L'acte de registre 1 est ecrit avant la lecture de la tete : le visa doit
  # donc porter sur une chaine qui le contient deja.
  con <- base_visa()
  foret <- foret_avec_entree(con)
  cle <- openssl::rsa_keygen(2048L)
  s <- signataire_cle(cle, claims = list(sub = "maire-01"))

  visa <- sommier_viser(con, foret, 2026, "commune", s)
  entrees <- sommier_lire(con, foret)
  derniere <- entrees[which.max(entrees$seq), ]

  expect_equal(derniere$registre, 1)
  expect_equal(visa$seq_tete, derniere$seq)
  expect_equal(visa$hash_tete, derniere$hash)
  expect_true(sommier_verifier(con, foret)$valide)
})

test_that("un visa horodate porte son jeton", {
  con <- base_visa()
  foret <- foret_avec_entree(con)
  cle <- openssl::rsa_keygen(2048L)
  s <- signataire_cle(cle, claims = list(sub = "maire-01"))

  visa <- sommier_viser(con, foret, 2026, "commune", s,
                        tsa_url = "https://tsa.example",
                        transport = tsa_simulee())
  expect_true(visa$horodate)
  rapport <- sommier_verifier_visas(con, foret, list(`maire-01` = cle$pubkey))
  expect_true(rapport$horodate)
  expect_true(is.na(rapport$remarque))
})

test_that("une signature posee par une autre cle est detectee", {
  con <- base_visa()
  foret <- foret_avec_entree(con)
  cle <- openssl::rsa_keygen(2048L)
  s <- signataire_cle(cle, claims = list(sub = "maire-01"))
  sommier_viser(con, foret, 2026, "commune", s)

  rapport <- sommier_verifier_visas(
    con, foret, list(`maire-01` = openssl::rsa_keygen(2048L)$pubkey)
  )
  expect_false(rapport$signature_valide)
  expect_match(rapport$remarque, "signature invalide")
})

test_that("sans cle fournie, la signature est indeterminee et non validee", {
  con <- base_visa()
  foret <- foret_avec_entree(con)
  cle <- openssl::rsa_keygen(2048L)
  sommier_viser(con, foret, 2026, "commune",
                signataire_cle(cle, claims = list(sub = "maire-01")))

  rapport <- sommier_verifier_visas(con, foret)
  expect_true(is.na(rapport$signature_valide))
  expect_match(rapport$remarque, "aucune cle publique")
})

test_that("viser un sommier vide est refuse", {
  con <- base_visa()
  foret <- foret_creer(con, "Foret vide", "domanial")
  cle <- openssl::rsa_keygen(2048L)
  expect_error(
    sommier_viser(con, foret, 2026, "commune",
                  signataire_cle(cle, claims = list(sub = "x")),
                  enregistrer_acte = FALSE),
    "Sommier vide"
  )
})

test_that("le visa est immuable une fois pose", {
  con <- base_visa()
  foret <- foret_avec_entree(con)
  cle <- openssl::rsa_keygen(2048L)
  sommier_viser(con, foret, 2026, "commune",
                signataire_cle(cle, claims = list(sub = "maire-01")))
  expect_error(
    DBI::dbExecute(con, "UPDATE visa SET autorite = 'onf'"), "append-only"
  )
})

test_that("un ancrage horodate la tete sans visa", {
  con <- base_visa()
  foret <- foret_avec_entree(con)
  ancrage <- sommier_ancrer(con, foret, "https://tsa.example",
                            transport = tsa_simulee())
  pose <- DBI::dbGetQuery(
    con, "SELECT seq_tete, encode(hash_tete,'hex') AS h FROM ancrage WHERE foret_id = $1",
    params = list(foret)
  )
  expect_equal(nrow(pose), 1L)
  expect_equal(pose$h, ancrage$hash_tete)
})

test_that("les detections arrivent avec le NDP de leur source", {
  con <- base_visa()
  foret <- foret_creer(con, "Foret test", "domanial")
  ug <- ug_creer(con, foret, "12", "2010-01-01")

  sommier_importer_detections(
    con, foret,
    detections = data.frame(
      nature = c("crise_sanitaire", "secheresse"),
      description = c("Deperissement pessiere", "Stress hydrique"),
      date_evenement = c("2026-06-01", "2026-07-01"),
      ug_uuid = c(ug, ug),
      surface_ha = c(3.2, 1.1),
      stringsAsFactors = FALSE
    ),
    source = "fordead", ndp = 3L, auteur = "chaine-fordead"
  )

  entrees <- sommier_lire(con, foret, registre = 8L)
  expect_equal(nrow(entrees), 2L)
  # Une detection n'est pas un constat : jamais NDP 0.
  expect_true(all(entrees$ndp == 3))
  expect_true(sommier_verifier(con, foret)$valide)

  attente <- DBI::dbGetQuery(
    con, "SELECT * FROM v_detection_en_attente WHERE foret_id = $1",
    params = list(foret)
  )
  expect_equal(nrow(attente), 2L)
})

test_that("une detection ne peut pas etre importee en NDP 0", {
  con <- base_visa()
  foret <- foret_creer(con, "Foret test", "domanial")
  expect_error(
    sommier_importer_detections(
      con, foret,
      list(list(nature = "gel", description = "x", date_evenement = "2026-01-01")),
      source = "fast", ndp = 0L, auteur = "chaine"
    ),
    "ndp"
  )
})

test_that("la validation terrain inscrit un constat NDP 0 qui rectifie", {
  con <- base_visa()
  foret <- foret_creer(con, "Foret test", "domanial")
  detections <- sommier_importer_detections(
    con, foret,
    list(list(nature = "crise_sanitaire", description = "Deperissement",
              date_evenement = "2026-06-01")),
    source = "fordead", ndp = 3L, auteur = "chaine-fordead"
  )
  id <- detections[[1]]$id

  sommier_valider_detection(
    con, id, auteur = "agent-01", statut = "confirme",
    description = "Deperissement confirme sur le terrain",
    date_evenement = "2026-07-15", surface_ha = 2.8
  )

  constat <- DBI::dbGetQuery(
    con,
    "SELECT ndp, payload->>'statut_detection' AS statut
       FROM entree_sommier WHERE foret_id = $1 AND corrige_id = $2",
    params = list(foret, id)
  )
  expect_equal(nrow(constat), 1L)
  expect_equal(constat$ndp, 0)
  expect_equal(constat$statut, "confirme")

  # La detection sort de la liste de travail sans sortir de la chaine.
  attente <- DBI::dbGetQuery(
    con, "SELECT * FROM v_detection_en_attente WHERE foret_id = $1",
    params = list(foret)
  )
  expect_equal(nrow(attente), 0L)
  expect_equal(nrow(sommier_lire(con, foret)), 2L)
  expect_true(sommier_verifier(con, foret)$valide)
})

test_that("ecarter une detection la rectifie aussi", {
  con <- base_visa()
  foret <- foret_creer(con, "Foret test", "domanial")
  detections <- sommier_importer_detections(
    con, foret,
    list(list(nature = "tempete", description = "Trouee suspecte",
              date_evenement = "2026-06-01")),
    source = "fast", ndp = 5L, auteur = "chaine-fast"
  )
  sommier_valider_detection(
    con, detections[[1]]$id, auteur = "agent-01", statut = "ecarte",
    description = "Trouee preexistante, aucun degat recent"
  )
  attente <- DBI::dbGetQuery(
    con, "SELECT * FROM v_detection_en_attente WHERE foret_id = $1",
    params = list(foret)
  )
  expect_equal(nrow(attente), 0L)
})

test_that("valider une entree qui n'est pas une detection est refuse", {
  con <- base_visa()
  foret <- foret_avec_entree(con)
  coupe <- sommier_lire(con, foret)$id[[1L]]
  expect_error(
    sommier_valider_detection(con, coupe, "agent-01", "confirme", "x"),
    "registre 8"
  )
  expect_error(
    sommier_valider_detection(con, uuid_v4(), "agent-01", "confirme", "x"),
    "inconnue"
  )
})

test_that("la tenue du sommier montre les exercices vises et signes", {
  con <- base_visa()
  foret <- foret_avec_entree(con)
  cle <- openssl::rsa_keygen(2048L)
  sommier_viser(con, foret, 2026, "commune",
                signataire_cle(cle, claims = list(sub = "maire-01")),
                tsa_url = "https://tsa.example", transport = tsa_simulee())

  tenue <- DBI::dbGetQuery(
    con, "SELECT * FROM v_tenue_sommier WHERE foret_id = $1", params = list(foret)
  )
  expect_equal(nrow(tenue), 1L)
  expect_equal(tenue$exercice, 2026L)
  expect_true(tenue$signe)
  expect_true(tenue$horodate)
})

test_that("un visa qui echoue ne laisse pas son acte derriere lui", {
  # Le defaut que la reentrance des transactions corrige : sans elle, le
  # `sommier_ajouter()` interne validait sa propre transaction, et l'acte de
  # registre 1 survivait a l'echec de l'insertion du visa.
  con <- base_visa()
  foret <- foret_avec_entree(con)
  cle <- openssl::rsa_keygen(2048L)
  s <- signataire_cle(cle, claims = list(sub = "maire-01"))

  avant <- nrow(sommier_lire(con, foret))
  sommier_viser(con, foret, 2026, "commune", s)
  apres_premier <- nrow(sommier_lire(con, foret))
  expect_equal(apres_premier, avant + 1L)

  # Le second visa viole UNIQUE (foret_id, exercice, autorite).
  expect_error(sommier_viser(con, foret, 2026, "commune", s))

  # L'acte du visa refuse ne doit pas subsister.
  expect_equal(nrow(sommier_lire(con, foret)), apres_premier)
  expect_true(sommier_verifier(con, foret)$valide)
  expect_equal(
    DBI::dbGetQuery(con, "SELECT count(*) AS n FROM visa WHERE foret_id = $1",
                    params = list(foret))$n,
    1
  )
})

test_that("la sequence reste sans trou apres un visa refuse", {
  # Un rollback qui laisserait un `seq` consomme creerait un trou, et la
  # verification signalerait une entree manquante.
  con <- base_visa()
  foret <- foret_avec_entree(con)
  cle <- openssl::rsa_keygen(2048L)
  s <- signataire_cle(cle, claims = list(sub = "maire-01"))
  sommier_viser(con, foret, 2026, "commune", s)
  try(sommier_viser(con, foret, 2026, "commune", s), silent = TRUE)

  sommier_ajouter(con, sommier_entree(
    foret_id = foret, registre = 5L, date_evenement = "2026-04-01",
    auteur = "agent-01",
    payload = registre5_coupe("martelage", 2026, "amelioration", 10)
  ))
  entrees <- sommier_lire(con, foret)
  expect_equal(entrees$seq, seq_len(nrow(entrees)))
  expect_true(sommier_verifier(con, foret)$valide)
})
