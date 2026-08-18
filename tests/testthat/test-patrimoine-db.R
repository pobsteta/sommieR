base_patrimoine <- function() {
  con <- sauter_sans_base()
  withr::defer(DBI::dbDisconnect(con), envir = parent.frame())
  sommier_init_schema(con)
  con
}

ajouter <- function(con, foret, registre, payload, date = "2026-05-01", ...) {
  sommier_ajouter(con, sommier_entree(
    foret_id = foret, registre = registre, date_evenement = date,
    auteur = "agent-01", payload = payload, ...
  ))
}

test_that("la densite de voirie se calcule en km pour 100 ha", {
  con <- base_patrimoine()
  foret <- foret_creer(con, "Foret test", "domanial", surface_ha = 500)
  ajouter(con, foret, 4L, registre4_voirie("R1", "empierree", 4000))
  ajouter(con, foret, 4L, registre4_voirie("R2", "empierree", 2000))
  ajouter(con, foret, 4L, registre4_voirie("P1", "piste", 1500))

  densite <- sommier_densite_voirie(con, foret)
  empierree <- densite[densite$revetement == "empierree", ]
  expect_equal(empierree$longueur_km, 6)
  expect_equal(empierree$densite_km_100ha, 1.2)     # 6 km / 5 centaines d'ha
  total <- densite[densite$revetement == "total", ]
  expect_equal(total$longueur_km, 7.5)
  expect_equal(total$densite_km_100ha, 1.5)
})

test_that("la voirie publique n'entre pas dans la densite", {
  # Une departementale traversant la foret ne dit rien de sa desserte.
  con <- base_patrimoine()
  foret <- foret_creer(con, "Foret test", "domanial", surface_ha = 100)
  ajouter(con, foret, 4L, registre4_voirie("Privee", "empierree", 1000))
  ajouter(con, foret, 4L, registre4_voirie("RD12", "revetue", 5000,
                                           voirie_publique = TRUE))
  densite <- sommier_densite_voirie(con, foret)
  expect_equal(densite[densite$revetement == "total", ]$longueur_km, 1)
})

test_that("sans surface connue, la densite n'est pas inventee", {
  con <- base_patrimoine()
  foret <- foret_creer(con, "Foret sans surface", "privee")
  ajouter(con, foret, 4L, registre4_voirie("R1", "empierree", 2000))
  densite <- sommier_densite_voirie(con, foret)
  expect_equal(densite[densite$revetement == "total", ]$longueur_km, 2)
  expect_true(all(is.na(densite$densite_km_100ha)))
})

test_that("les droits expires sortent de la liste sans sortir du registre", {
  con <- base_patrimoine()
  foret <- foret_creer(con, "Foret test", "communal")
  ajouter(con, foret, 3L, registre3_droit("bail_chasse", "En cours",
                                          "2020-04-01",
                                          date_expiration = "2099-03-31"))
  ajouter(con, foret, 3L, registre3_droit("concession", "Expiree",
                                          "2010-01-01",
                                          date_expiration = "2015-12-31"))

  en_vigueur <- DBI::dbGetQuery(
    con, "SELECT nature FROM v_droit_en_vigueur WHERE foret_id = $1",
    params = list(foret)
  )
  expect_equal(en_vigueur$nature, "En cours")
  expect_equal(nrow(sommier_lire(con, foret, registre = 3L)), 2L)
})

test_that("le titulaire ne fuit pas par la vue des droits", {
  con <- base_patrimoine()
  foret <- foret_creer(con, "Foret test", "communal")
  ajouter(con, foret, 3L, registre3_droit("bail_chasse", "Location",
                                          "2024-04-01",
                                          titulaire = "ACCA de Chaux"))
  vue <- DBI::dbGetQuery(con, "SELECT * FROM v_droit WHERE foret_id = $1",
                         params = list(foret))
  expect_false("titulaire" %in% names(vue))
})

test_that("un sujet remarquable revisite garde ses releves successifs", {
  # Append-only : la serie de mesures se reconstitue, rien n'est ecrase.
  con <- base_patrimoine()
  foret <- foret_creer(con, "Foret test", "domanial")
  ajouter(con, foret, 9L,
          registre9_arbre("Chene des Trois Bornes", "CHS", "Age",
                          circonference_cm = 520, etat_sanitaire = "bon"),
          date = "2016-06-01")
  ajouter(con, foret, 9L,
          registre9_arbre("Chene des Trois Bornes", "CHS", "Age",
                          circonference_cm = 540, etat_sanitaire = "moyen"),
          date = "2026-06-01")

  tous <- DBI::dbGetQuery(
    con, "SELECT circonference_cm FROM v_remarquable WHERE foret_id = $1
          ORDER BY date_evenement", params = list(foret))
  expect_equal(as.numeric(tous$circonference_cm), c(520, 540))

  dernier <- DBI::dbGetQuery(
    con, "SELECT circonference_cm, etat_sanitaire
            FROM v_remarquable_dernier_releve WHERE foret_id = $1",
    params = list(foret))
  expect_equal(nrow(dernier), 1L)
  expect_equal(as.numeric(dernier$circonference_cm), 540)
  expect_equal(dernier$etat_sanitaire, "moyen")
})

test_that("les elements d'IBP comptent le dernier releve de chaque sujet", {
  con <- base_patrimoine()
  foret <- foret_creer(con, "Foret test", "domanial")
  ajouter(con, foret, 9L, registre9_arbre("Gros chene", "CHS", "Dimensions",
                                          circonference_cm = 260))
  ajouter(con, foret, 9L, registre9_arbre("Petit hetre", "HET", "Port",
                                          circonference_cm = 140))
  ajouter(con, foret, 9L, registre9_arbre("Chandelle", "SAP", "Bois mort",
                                          etat_sanitaire = "mort"))
  ajouter(con, foret, 9L, registre9_habitat("Clairiere pastorale", 2.5))
  ajouter(con, foret, 9L, registre9_habitat("Hetraie fraiche", 12))
  ajouter(con, foret, 9L, registre9_espece("Sabot de Venus",
                                           "Cypripedium calceolus"))

  ibp <- sommier_elements_ibp(con, foret)
  valeur <- function(prefixe) ibp$valeur[startsWith(ibp$facteur_ibp, prefixe)]
  expect_equal(valeur("F"), 2)      # deux arbres vivants
  expect_equal(valeur("C"), 1)      # une chandelle
  expect_equal(valeur("E"), 1)      # seul le chene depasse 220 cm
  expect_equal(valeur("G"), 2.5)    # la clairiere, pas la hetraie
  expect_equal(valeur("contexte"), 1)
})

test_that("le seuil des tres gros bois est parametrable", {
  con <- base_patrimoine()
  foret <- foret_creer(con, "Foret test", "domanial")
  ajouter(con, foret, 9L, registre9_arbre("Chene", "CHS", "x",
                                          circonference_cm = 180))
  expect_equal(sommier_elements_ibp(con, foret)$valeur[3], 0)
  expect_equal(sommier_elements_ibp(con, foret, seuil_tgb_cm = 150)$valeur[3], 1)
})

test_that("les neuf registres s'ecrivent dans une meme chaine verifiable", {
  con <- base_patrimoine()
  foret <- foret_creer(con, "Foret complete", "communal", surface_ha = 300)
  ug <- ug_creer(con, foret, "1", "2010-01-01")
  cle <- openssl::rsa_keygen(2048L)

  ajouter(con, foret, 2L, registre2_foncier("bornage", "Limite nord"))
  ajouter(con, foret, 3L, registre3_affouage("2025-2026", 42))
  ajouter(con, foret, 4L, registre4_voirie("R1", "empierree", 1200))
  ajouter(con, foret, 5L, registre5_coupe("martelage", 2026, "amelioration", 120))
  ajouter(con, foret, 6L, registre6_travaux(2026, "plantation"))
  ajouter(con, foret, 7L, registre7_ecriture("bois_sur_pied", 2026, 18400))
  ajouter(con, foret, 8L, registre8_phenomene("tempete", "Coup de vent"))
  ajouter(con, foret, 9L, registre9_arbre("Chene", "CHS", "Age"))
  sommier_viser(con, foret, 2026, "commune",
                signataire_cle(cle, claims = list(sub = "maire-01")))

  entrees <- sommier_lire(con, foret)
  expect_setequal(unique(entrees$registre), c(1, 2, 3, 4, 5, 6, 7, 8, 9))
  expect_equal(entrees$seq, seq_len(nrow(entrees)))
  expect_true(sommier_verifier(con, foret)$valide)
})
