# Le registre est append-only : un jeu de demonstration pose une fois ne peut
# pas etre efface, et la base de test est partagee entre les executions. Un
# suffixe fixe rendrait donc ces tests rejouables une seule fois. Le
# discriminant aleatoire les rend independants de l'historique.
suffixe_test <- function(prefixe) {
  paste0(prefixe, "-", substr(uuid_v4(), 1L, 8L))
}

base_demo <- function() {
  con <- sauter_sans_base()
  withr::defer(DBI::dbDisconnect(con), envir = parent.frame())
  sommier_init_schema(con)
  con
}

test_that("les parcelles de demonstration sont celles du cadastre", {
  p <- SOMMIER_PARCELLES_COUCHEY
  expect_equal(nrow(p), 3L)
  # Quatorze caracteres, et non treize : la fixture « mock » d'origine portait
  # `21200000A0054`, une reference mal formee designant qui plus est une
  # parcelle inexistante. Le format est ce qui se verifie sans acces au
  # cadastre - on le verifie donc ici.
  expect_true(all(nchar(p$geo_parcelle) == 14L))
  expect_equal(p$geo_parcelle,
               c("212000000A0015", "212000000A0035", "212000000A0102"))
  # La surface en hectares doit s'accorder avec la contenance en metres
  # carres : deux facons de dire la meme chose ne doivent pas diverger.
  expect_equal(p$surface_ha, p$contenance_m2 / 10000)
  expect_true(all(startsWith(p$wkt_4326, "POLYGON((")))
})

test_that("le nom de la foret annonce qu'il s'agit d'un jeu d'essai", {
  # Le seul garde-fou qui survive a la lecture d'une base par un tiers.
  expect_match(NOM_FORET_DEMO, "demonstration")
})

test_that("le jeu de demonstration ecrit les neuf registres et se verifie", {
  con <- base_demo()
  demo <- sommier_demo_couchey(con, suffixe = suffixe_test("neuf-registres"))

  expect_length(demo$ug, 3L)
  expect_setequal(names(demo$ug), c("15", "35", "102"))
  expect_gt(demo$n_entrees, 50L)

  entrees <- sommier_lire(con, demo$foret_id)
  expect_setequal(unique(entrees$registre), 1:9)
  expect_equal(entrees$seq, seq_len(nrow(entrees)))
  expect_true(sommier_verifier(con, demo$foret_id)$valide)
})

test_that("le jeu de demonstration refuse de s'ajouter a lui-meme", {
  # Le registre etant append-only, un jeu d'essai pose deux fois ne peut pas
  # etre defait : mieux vaut refuser que laisser un doublon indelebile.
  con <- base_demo()
  suffixe <- suffixe_test("doublon")
  sommier_demo_couchey(con, suffixe = suffixe)
  expect_error(sommier_demo_couchey(con, suffixe = suffixe), "existe deja")
})

test_that("les geometries sont posees et reprojetees en Lambert-93", {
  con <- base_demo()
  demo <- sommier_demo_couchey(con, suffixe = suffixe_test("geometries"))
  geo <- DBI::dbGetQuery(
    con,
    "SELECT ST_SRID(g.geom) AS srid, ST_Area(g.geom) AS aire_m2
       FROM ug_geometrie g JOIN ug u ON u.uuid = g.ug_uuid
      WHERE u.foret_id = $1 ORDER BY u.numero_affichage",
    params = list(demo$foret_id)
  )
  expect_equal(nrow(geo), 3L)
  expect_true(all(geo$srid == 2154))
  # Les trois parcelles font 4,3 a 7,2 hectares au cadastre. On borne
  # largement : ce test porte sur la reprojection, pas sur la contenance.
  expect_true(all(geo$aire_m2 > 10000 & geo$aire_m2 < 1e7))
  # Le dessin ne doit pas s'ecarter de la contenance cadastrale de plus de
  # 1 % - la simplification a 1 metre coute 0,03 %, un decalage plus grand
  # signalerait une reprojection fautive et non un arrondi.
  attendu <- sort(SOMMIER_PARCELLES_COUCHEY$contenance_m2)
  expect_equal(sort(geo$aire_m2), attendu, tolerance = 0.01)
})

test_that("le jeu de demonstration alimente les vues metier", {
  con <- base_demo()
  demo <- sommier_demo_couchey(con, suffixe = suffixe_test("vues"))
  foret <- demo$foret_id

  expect_gt(nrow(sommier_balance_possibilite(con, foret)), 5L)
  expect_gt(nrow(sommier_bilan_financier(con, foret)), 3L)
  expect_gt(nrow(sommier_execution_budgetaire(con, foret)), 5L)
  expect_gt(nrow(sommier_densite_voirie(con, foret)), 1L)

  ibp <- sommier_elements_ibp(con, foret)
  # Une chandelle morte, deux arbres vivants dont un seul depasse le seuil des
  # tres gros bois : le jeu d'essai doit faire trancher le seuil, sinon le
  # facteur E se confondrait avec le facteur F.
  expect_equal(ibp$valeur[startsWith(ibp$facteur_ibp, "C")], 1)
  expect_equal(ibp$valeur[startsWith(ibp$facteur_ibp, "F")], 2)
  expect_equal(ibp$valeur[startsWith(ibp$facteur_ibp, "E")], 1)
})

test_that("l'export SIG du jeu de demonstration rend trois entites", {
  con <- base_demo()
  demo <- sommier_demo_couchey(con, suffixe = suffixe_test("sig"))
  chemin <- withr::local_tempfile(fileext = ".geojson")
  resultat <- sommier_exporter_sig(con, demo$foret_id, chemin)
  expect_equal(resultat$n_unites, 3L)
  expect_length(resultat$unites_sans_geometrie, 0L)
})

test_that("le rapport Quarto exige un format et une extension accordes", {
  con <- base_demo()
  demo <- sommier_demo_couchey(con, suffixe = suffixe_test("formats"))
  expect_error(
    sommier_rapport_quarto(con, demo$foret_id, "rapport.pdf", format = "html"),
    "ne correspond pas"
  )
  expect_error(
    sommier_rapport_quarto(con, demo$foret_id, "rapport.docx", format = "docx"),
    "format"
  )
})

test_that("l'absence de Quarto est dite clairement", {
  con <- base_demo()
  demo <- sommier_demo_couchey(con, suffixe = suffixe_test("sans-quarto"))
  expect_error(
    sommier_rapport_quarto(con, demo$foret_id, "r.html", quarto = ""),
    "introuvable dans le PATH"
  )
})

test_that("le rapport Quarto se rend et porte l'empreinte de tete", {
  skip_if(!nzchar(Sys.which("quarto")), "Quarto n'est pas installe.")
  con <- base_demo()
  demo <- sommier_demo_couchey(con, suffixe = suffixe_test("rapport"))
  chemin <- withr::local_tempfile(fileext = ".html")

  sommier_rapport_quarto(con, demo$foret_id, chemin, format = "html",
                         referentiel = "amenagement")
  expect_true(file.exists(chemin))
  html <- paste(readLines(chemin, warn = FALSE, encoding = "UTF-8"),
                collapse = "\n")

  # L'empreinte de tete doit figurer dans le document : c'est ce qui relie le
  # rapport a un etat precis du registre.
  tete <- sommier_verifier(con, demo$foret_id)$hash_tete
  expect_match(html, tete, fixed = TRUE)
  expect_match(html, "intacte", fixed = TRUE)

  # La bannière de donnees fictives doit y etre : un rapport de demonstration
  # qui ne se signale pas est exactement ce qu'on veut eviter.
  expect_match(html, "monstration", fixed = TRUE)

  # Aucun caractere ne doit sortir echappe : sous une locale non UTF-8, R
  # rendrait les accents en <U+00E9> sans echouer, et le defaut passerait
  # inapercu.
  expect_no_match(html, "&lt;U\\+[0-9A-F]{4}&gt;")
})

test_that("le rapport Quarto d'une foret reelle montre ses detections", {
  skip_if(!nzchar(Sys.which("quarto")), "Quarto n'est pas installe.")
  con <- base_demo()
  foret <- foret_creer(con, suffixe_test("Foret de Loury"), "communal",
                       surface_ha = 554.9321)
  ug <- ug_creer(con, foret, "B 12", "2010-01-01")
  sommier_importer_detections(
    con, foret,
    detections = data.frame(
      nature = "crise_sanitaire", description = "Deperissement du chene",
      date_evenement = "2026-07-14", ug_uuid = ug, surface_ha = 24.93,
      indice = 51.61, observations = "Modele calibre en Centre-Val de Loire.",
      stringsAsFactors = FALSE
    ),
    source = "reconfort", ndp = 1L, auteur = "chaine-reconfort"
  )
  chemin <- withr::local_tempfile(fileext = ".html")
  sommier_rapport_quarto(con, foret, chemin, format = "html")
  html <- paste(readLines(chemin, warn = FALSE, encoding = "UTF-8"),
                collapse = "\n")

  expect_match(html, "Détections à vérifier sur le terrain", fixed = TRUE)
  expect_match(html, "B 12", fixed = TRUE)
  expect_match(html, "Centre-Val de Loire", fixed = TRUE)
  # Le bandeau de demonstration est reserve au jeu d'essai.
  expect_no_match(html, "Données de démonstration", fixed = TRUE)
  # Les bornes par defaut ne s'impriment pas comme des dates.
  expect_no_match(html, "0001-01-01", fixed = TRUE)
  expect_match(html, "554,93 ha", fixed = TRUE)
  # La sequence de tete est un bigint : relue sans bit64, elle sortait en
  # 5e-324 au lieu de 1.
  expect_no_match(html, "e-32[0-9]")
  expect_match(html, sommier_verifier(con, foret)$hash_tete, fixed = TRUE)
})

test_that("un document qui ne peut etre ecrit fait echouer le rendu", {
  skip_if(!nzchar(Sys.which("quarto")), "Quarto n'est pas installe.")
  con <- base_demo()
  foret <- foret_creer(con, suffixe_test("Foret non ecrite"), "communal")
  dossier <- withr::local_tempdir()
  Sys.chmod(dossier, "0555")
  withr::defer(Sys.chmod(dossier, "0755"))
  skip_if(file.access(dossier, 2L) == 0L, "Le dossier reste inscriptible.")
  # `file.copy()` avertit en plus d'echouer : seul l'echec nous interesse.
  expect_error(
    suppressWarnings(
      sommier_rapport_quarto(con, foret, file.path(dossier, "r.html"))
    ),
    "Impossible d'ecrire"
  )
})
