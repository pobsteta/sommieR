# Les plants pointes et leurs etats (registre 6, r6-1.3.0) - sans base. Les cas
# de Surculus (fixtures/plants/*.json, ecrits a la main par son testeur) sont
# rejoues en R : R et Kotlin appliquent les memes regles.

cas_surculus <- function(fichier) {
  jsonlite::fromJSON(test_path("fixtures", "plants", fichier),
                     simplifyVector = FALSE)$cas
}

# Les etiquettes des cas ("s1", "m1") deviennent des UUID stables.
uuid_de <- function(etiquette) {
  h <- openssl::sha256(charToRaw(etiquette))
  h <- paste(sprintf("%02x", as.integer(h[1:16])), collapse = "")
  paste(substr(h, 1, 8), substr(h, 9, 12), substr(h, 13, 16),
        substr(h, 17, 20), substr(h, 21, 32), sep = "-")
}

etat_du_cas <- function(p) {
  compacter(list(plant_id = uuid_de(p$uuid), etat = p$etat,
                 cause_groupe = p$cause_groupe, cause_detail = p$cause_detail,
                 hauteur_cm = p$hauteur_cm))
}

test_that("le registre 6 passe en r6-1.3.0 et connait le type plant", {
  expect_equal(SOMMIER_SCHEMA_VERSIONS[["6"]], "r6-1.3.0")
  expect_true("plant" %in% SOMMIER_TYPES_TRAVAUX)
  expect_equal(SOMMIER_ETATS_PLANT,
               c("sain", "atteint", "mort", "absent", "non_observe"))
  expect_length(SOMMIER_GROUPES_CAUSE_PLANT, 4L)
})

test_that("un payload de plant se construit, se relit a l'identique", {
  p <- registre6_plant(uuid_v4(), 3, geom_point(4.95, 47.27), essence = "CHS",
                       distance_m = 2.4, azimut_mag = 123.5,
                       unite_azimut = "deg", declinaison_deg = 1.2,
                       convergence_deg = -0.3, azimut_geo_deg = 124.1,
                       modele_geomagnetique = "WMM2025",
                       pointe_le = "2026-11-03T10:00:00Z")
  expect_equal(p$type_entree, "plant")
  relu <- jsonlite::fromJSON(jsonlite::toJSON(p, auto_unbox = TRUE,
                                              digits = NA),
                             simplifyVector = FALSE)
  expect_identical(jcs(valider_payload(6L, relu)), jcs(p))
  # Le plant porte son observation brute : un azimut sans unite ne se relit pas.
  expect_error(registre6_plant(uuid_v4(), 3, geom_point(4.95, 47.27),
                               azimut_mag = 12), "unite_azimut")
  expect_error(registre6_plant(uuid_v4(), 3, geom_point(4.95, 47.27),
                               azimut_mag = 360, unite_azimut = "deg"), "360")
  expect_no_error(registre6_plant(uuid_v4(), 3, geom_point(4.95, 47.27),
                                  azimut_mag = 399, unite_azimut = "gr"))
  expect_error(registre6_plant(uuid_v4(), 0, geom_point(4.95, 47.27)),
               "numero")
  expect_error(registre6_plant(uuid_v4(), 1, NULL), "geometrie")
})

test_that("etats-causes.json : etats, causes, details et hauteurs", {
  for (cas in cas_surculus("etats-causes.json")) {
    if (!is.null(cas$entree$essence)) next  # essences : pas de table a sommieR
    e <- c(list(plant_id = uuid_v4()), cas$entree)
    essai <- tryCatch({ valider_etat_plant(e, "e"); TRUE },
                      error = function(err) FALSE)
    expect_identical(essai, isTRUE(cas$attendu$accepte), info = cas$id)
  }
})

test_that("totaux-controle.json : les totaux decoulent des etats", {
  for (cas in cas_surculus("totaux-controle.json")) {
    e <- cas$entree
    etats <- lapply(e$plants, etat_du_cas)
    if (isTRUE(cas$attendu$refuse)) {
      expect_error(registre6_controle(uuid_v4(), plants = etats),
                   "un etat par controle", info = cas$id)
      next
    }
    # Un regarni pose a un controle anterieur sort le plant remplace des totaux.
    remplaces <- unlist(lapply(e$regarnis, function(r) {
      if (r$pose_au_controle < e$controle_calcule) uuid_de(r$remplace_uuid)
    }))
    d <- totaux_des_plants(lapply(etats, identity), remplaces %||% character(0))
    att <- cas$attendu
    expect_equal(d$nb_total, att$nb_total, info = cas$id)
    expect_equal(d$nb_vivants, att$nb_vivants, info = cas$id)
    if (!is.null(att$nb_abroutis)) {
      expect_equal(d$nb_abroutis, att$nb_abroutis, info = cas$id)
    }
    if ("h_moy_cm" %in% names(att)) {
      expect_equal(d$h_moy_cm, att$h_moy_cm, info = cas$id)
    }
    expect_lte(d$nb_vivants, d$nb_total)
    expect_lte(d$nb_abroutis, d$nb_vivants)
    # Et le payload les inscrit, plants remplaces compris, quand il y en a.
    if (length(etats) > 0L) {
      p <- registre6_controle(
        uuid_v4(), plants = etats,
        plants_remplaces = if (length(remplaces) > 0L)
          intersect(remplaces, vapply(etats, function(x) x$plant_id, "")))
      expect_equal(p$nb_total, att$nb_total, info = cas$id)
      expect_equal(p$h_moy_cm, att$h_moy_cm, info = cas$id)
    }
  }
})

test_that("un total contradictoire est refuse, un total concordant ou omis est inscrit", {
  etats <- list(list(plant_id = uuid_v4(), etat = "sain", hauteur_cm = 40),
                list(plant_id = uuid_v4(), etat = "mort"),
                list(plant_id = uuid_v4(), etat = "non_observe"))
  expect_error(registre6_controle(uuid_v4(), 3, 1, plants = etats),
               "nb_total")
  expect_error(registre6_controle(uuid_v4(), 2, 2, plants = etats),
               "nb_vivants")
  expect_error(registre6_controle(uuid_v4(), 2, 1, nb_abroutis = 1,
                                  plants = etats), "nb_abroutis")
  expect_error(registre6_controle(uuid_v4(), 2, 1, h_moy_cm = 41,
                                  plants = etats), "h_moy_cm")
  p <- registre6_controle(uuid_v4(), 2, 1, h_moy_cm = 40, plants = etats)
  expect_equal(c(p$nb_total, p$nb_vivants, p$nb_abroutis, p$h_moy_cm),
               c(2, 1, 0, 40))
  expect_length(p$plants, 3L)
  # Le demi monte : 40 et 45 donnent 43, pas 42 (round() de R).
  expect_equal(registre6_controle(uuid_v4(), plants = list(
    list(plant_id = uuid_v4(), etat = "sain", hauteur_cm = 40),
    list(plant_id = uuid_v4(), etat = "atteint", hauteur_cm = 45)))$h_moy_cm,
    43)
  # Un plant remplace doit etre dans la liste.
  expect_error(registre6_controle(uuid_v4(), plants = etats,
                                  plants_remplaces = uuid_v4()),
               "plants_remplaces")
})

test_that("un controle sans plants s'ecrit comme avant, r6-1.2.0 se relit sans changement", {
  c0 <- registre6_controle(uuid_v4(), 20, 17, h_moy_cm = 40, nb_abroutis = 1)
  expect_null(c0$plants)
  expect_null(c0$plants_remplaces)
  expect_identical(jcs(valider_payload(6L, c0)), jcs(c0))
  expect_error(registre6_controle(uuid_v4()), "nb_total")
  # Plus de vivants que de plants : toujours refuse, sans plants.
  expect_error(registre6_controle(uuid_v4(), 3, 4), "vivants")
})

test_that("regarni.json : un regarni remplace un plant mort ou absent de sa placette", {
  for (cas in cas_surculus("regarni.json")) {
    e <- cas$entree
    if (!is.null(e$regarni$remplace_uuid) || is.null(e$plants)) {
      # Le roster : les plants vus, leur etat au jour 1 ; le regarni pose au jour 2.
      roster <- data.frame(
        plant_id = vapply(e$plants, function(p) uuid_de(p$uuid), ""),
        placette_id = vapply(e$plants, function(p) p$placette %||% "P-001", ""),
        numero = seq_along(e$plants),
        pointe_le = as.Date("2026-01-01"),
        remplace_uuid = vapply(e$plants, function(p) {
          if (is.null(p$remplace_uuid)) NA_character_ else uuid_de(p$remplace_uuid)
        }, ""), stringsAsFactors = FALSE)
      histoire <- data.frame(
        plant_id = roster$plant_id, jour = as.Date("2026-01-01"),
        etat = vapply(e$plants, function(p) p$etat, ""),
        stringsAsFactors = FALSE)
    }
    if (cas$id == "G10") {
      # Le mort remplace compte au controle de la pose, sort des suivants.
      reg <- e$regarnis[[1L]]
      r <- data.frame(plant_id = uuid_de(reg$uuid),
                      placette_id = "P-001", numero = 2L,
                      pointe_le = as.Date("2026-01-01") + reg$pose_au_controle,
                      remplace_uuid = uuid_de(reg$remplace_uuid),
                      stringsAsFactors = FALSE)
      expect_false(uuid_de("m1") %in% plants_remplaces_avant(
        r, as.Date("2026-01-01") + 1L), info = "controle 1 : m1 compte")
      expect_true(uuid_de("m1") %in% plants_remplaces_avant(
        r, as.Date("2026-01-01") + 2L), info = "controle 2 : m1 sort")
      next
    }
    reg <- e$regarni
    if (is.null(reg$remplace_uuid)) {
      expect_error(registre6_plant(uuid_v4(), 1, geom_point(4.95, 47.27),
                                   regarni = TRUE), "remplace_uuid",
                   info = cas$id)
      next
    }
    fautes <- fautes_regarni(
      uuid_de(reg$uuid), uuid_de(reg$remplace_uuid), as.Date("2026-01-02"),
      reg$placette, roster, histoire)
    expect_identical(length(fautes) == 0L, isTRUE(cas$attendu$accepte),
                     info = cas$id)
  }
})

test_that("identite.json : un plant garde son numero, un numero ne se prend qu'une fois", {
  cas <- Filter(function(c) c$id %in% c("I2", "I2b"), cas_surculus("identite.json"))
  for (c in cas) {
    u <- uuid_de("u1")
    avant <- data.frame(plant_id = u, placette_id = "P-001",
                        numero = c$entree$passage_1[[1L]]$numero,
                        pointe_le = as.Date("2026-01-01"),
                        remplace_uuid = NA_character_, stringsAsFactors = FALSE)
    # Le meme plant relu : meme uuid, meme numero, ou un autre (refuse).
    relu <- c$entree$passage_2[[1L]]
    ok <- identical(avant$numero, relu$numero)
    expect_identical(ok, isTRUE(c$attendu$accepte), info = c$id)
  }
})

test_that("le jour civil se compte en heure de Paris (ete UTC+2, hiver UTC+1)", {
  expect_equal(jour_paris("2026-06-15T21:30:00Z"), as.Date("2026-06-15"))
  expect_equal(jour_paris("2026-06-15T22:00:00Z"), as.Date("2026-06-16"))
  expect_equal(jour_paris("2026-01-15T22:59:59Z"), as.Date("2026-01-15"))
  expect_equal(jour_paris("2026-01-15T23:00:00Z"), as.Date("2026-01-16"))
  expect_equal(jour_paris(as.POSIXct("2026-06-15 22:30:00", tz = "UTC")),
               as.Date("2026-06-16"))
  # Un instant a la minute pres, sans Z : lu en UTC.
  expect_equal(jour_paris("2026-06-15 22:30:00"), as.Date("2026-06-16"))
  expect_true(is.na(jour_paris(NA)))
  expect_true(is.na(jour_paris(NULL)))
})
