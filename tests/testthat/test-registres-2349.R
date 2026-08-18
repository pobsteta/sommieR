# Registre 2 - foncier -------------------------------------------------------

test_that("une repartition qui ne totalise pas le cout est refusee", {
  # C'est une erreur de saisie, pas une subtilite comptable.
  expect_error(
    registre2_foncier("bornage", "Limite nord", cout_total_eur = 1200,
                      charge_proprietaire_eur = 600,
                      charge_riverains_eur = 500),
    "ne totalise pas le cout"
  )
  expect_silent(
    registre2_foncier("bornage", "Limite nord", cout_total_eur = 1200,
                      charge_proprietaire_eur = 600,
                      charge_riverains_eur = 600)
  )
  # Une repartition partielle ne se verifie pas : rien a contredire.
  expect_silent(
    registre2_foncier("bornage", "Limite nord", cout_total_eur = 1200,
                      charge_proprietaire_eur = 600)
  )
})

test_that("les references cadastrales restent un tableau meme a un element", {
  # Sinon la forme du payload changerait avec le nombre de valeurs.
  une <- registre2_foncier("acquisition", "Achat parcelle",
                           references_cadastrales = "AB 42")
  expect_match(jcs(une), '"references_cadastrales":\\["AB 42"\\]')
  deux <- registre2_foncier("acquisition", "Achat",
                            references_cadastrales = c("AB 42", "AB 43"))
  expect_match(jcs(deux), '"references_cadastrales":\\["AB 42","AB 43"\\]')
})

test_that("le registre 2 refuse un type hors nomenclature", {
  expect_error(registre2_foncier("expropriation", "x"), "type_entree")
})

# Registre 3 - droits --------------------------------------------------------

test_that("une expiration anterieure au depart est refusee", {
  # Le droit n'aurait jamais existe : c'est une inversion de saisie.
  expect_error(
    registre3_droit("bail_chasse", "Location", "2024-04-01",
                    date_expiration = "2023-03-31"),
    "precede"
  )
  # Un droit d'usage perpetuel n'a pas d'expiration.
  expect_silent(registre3_droit("droit_usage", "Affouage ancien", "1889-01-01"))
})

test_that("l'affouage passe par son propre constructeur", {
  expect_error(registre3_droit("affouage", "Affouage", "2025-04-01"),
               "registre3_affouage")
  p <- registre3_affouage("2025-2026", 42, volume_m3 = 310, taxe_eur = 45,
                          mode_partage = "par_feu")
  expect_equal(p$type_entree, "affouage")
  expect_equal(p$nb_affouagistes, 42)
})

test_that("la campagne d'affouage suit la saison cynegetique en forme", {
  expect_error(registre3_affouage("2025-2027", 10), "consecutives")
  expect_error(registre3_affouage("2025", 10), "AAAA-AAAA")
})

test_that("le registre 3 redirige sur le bon constructeur", {
  for (p in list(
    registre3_droit("concession", "Ligne electrique", "2020-01-01"),
    registre3_affouage("2025-2026", 12)
  )) {
    expect_equal(valider_payload(3L, p), p)
  }
  expect_error(valider_payload(3L, list(nature = "x")), "type_entree")
})

# Registre 4 - infrastructures -----------------------------------------------

test_that("la voirie porte revetement, longueur et usage", {
  p <- registre4_voirie("Route du Haut-Bois", "empierree", 2400,
                        largeur_chaussee_m = 4, usage = "exploitation",
                        ouverte_public = FALSE)
  expect_equal(p$revetement, "empierree")
  expect_false(p$ouverte_public)
  expect_false(p$voirie_publique)
  expect_error(registre4_voirie("x", "goudron", 100), "revetement")
  expect_error(registre4_voirie("x", "piste", 100, usage = "promenade"), "usage")
})

test_that("un equipement dont la capacite est chiffree porte son unite", {
  expect_error(registre4_equipement("ouvrage_dfci", "Point d'eau", capacite = 120),
               "unite")
  expect_silent(registre4_equipement("ouvrage_dfci", "Point d'eau",
                                     capacite = 120, unite = "m3"))
})

# Registre 9 - patrimoine remarquable ----------------------------------------

test_that("la composition d'un peuplement somme a dix", {
  # L'imprime r/p l'exprime en dixiemes : une autre somme signale une saisie
  # incomplete.
  expect_error(
    registre9_peuplement("Futaie", "Hetraie", composition = list(HET = 6, SAP = 3)),
    "sommer a 10"
  )
  expect_silent(
    registre9_peuplement("Futaie", "Hetraie", composition = list(HET = 6, SAP = 4))
  )
  expect_error(
    registre9_peuplement("Futaie", "Hetraie", composition = list(6, 4)),
    "nommee par essence"
  )
})

test_that("un arbre mort sur pied reste un sujet remarquable", {
  # C'est meme un facteur de l'IBP : le refuser perdrait l'information.
  expect_silent(registre9_arbre("Chandelle du Vallon", "CHS", "Bois mort sur pied",
                                etat_sanitaire = "mort"))
  expect_error(registre9_arbre("x", "CHS", "y", etat_sanitaire = "abattu"),
               "etat_sanitaire")
})

test_that("les cinq types de fiche se revalident depuis un export", {
  fiches <- list(
    registre9_arbre("Chene", "CHS", "Age"),
    registre9_peuplement("Futaie", "Hetraie"),
    registre9_vestige("Charbonniere", "Charbonniere", "Vestige d'exploitation"),
    registre9_espece("Sabot de Venus", "Cypripedium calceolus"),
    registre9_habitat("Tourbiere bombee", 1.4)
  )
  for (p in fiches) expect_equal(valider_payload(9L, p), p)
  expect_error(valider_payload(9L, list(appellation = "x")), "type_fiche")
})
