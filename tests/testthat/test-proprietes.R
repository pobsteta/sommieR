# Les treize cas de `test-jcs.R` disent que l'auteur a pense a treize choses.
# Ce qui porte la chaine est une propriete universelle : l'empreinte ne doit
# pas dependre de l'ordre dans lequel les cles du payload ont ete ecrites. Un
# destinataire qui reconstruit un payload champ par champ, dans un autre ordre,
# doit retrouver la meme empreinte - sinon la verification par un tiers est une
# promesse creuse.
# Voir specs/brief_noyau-1_eprouver-ce-qui-tient.md.
#
# Les valeurs sont engendrees a graine fixe : un test qui change de verdict
# d'une execution a l'autre ne se corrige pas, il se subit.

set.seed(20260828L)

# --- Engendrement -----------------------------------------------------------

# Des caracteres choisis pour ce qu'ils cassent : les controles passent en
# \u00xx, l'accentue occupe deux octets UTF-8, le CJK trois, et l'emoji sort du
# plan multilingue de base - il compte donc pour deux unites de code UTF-16,
# ce dont depend l'ordre des cles.
ALPHABET <- c(letters, LETTERS, 0:9, " ", "\"", "\\", "\n", "\t", "",
              "é", "ü", "中", "\U0001F332", "/", "-", "_")

texte_tire <- function(n = sample(0:12, 1L)) {
  if (n == 0L) return("")
  paste0(sample(ALPHABET, n, replace = TRUE), collapse = "")
}

# Des nombres repartis sur toute l'etendue ou `Number::toString` change de
# regime : entiers, decimaux, bascule exponentielle a 1e21 et 1e-7, subnormaux.
nombre_tire <- function() {
  switch(
    sample(6L, 1L),
    sample(-1000:1000, 1L),
    stats::runif(1L, -1e6, 1e6),
    stats::runif(1L, -1, 1),
    stats::runif(1L, 1e18, 1e24),
    stats::runif(1L, 0, 1) * 10^sample(-12:-4, 1L),
    .Machine$double.xmin * stats::runif(1L, 1, 100)
  )
}

scalaire_tire <- function() {
  switch(
    sample(4L, 1L),
    nombre_tire(),
    texte_tire(),
    sample(c(TRUE, FALSE), 1L),
    NULL
  )
}

# Une valeur arborescente : objets, tableaux et scalaires melanges. La
# profondeur est bornee pour que la suite reste rapide, pas parce que la
# propriete cesserait de tenir plus bas.
valeur_tiree <- function(profondeur = 0L) {
  if (profondeur >= 3L || stats::runif(1L) < 0.45) {
    return(scalaire_tire())
  }
  n <- sample(0:4, 1L)
  if (n == 0L) {
    return(if (stats::runif(1L) < 0.5) list() else
             structure(list(), names = character(0)))
  }
  enfants <- lapply(seq_len(n), function(i) valeur_tiree(profondeur + 1L))
  if (stats::runif(1L) < 0.5) {
    return(enfants)
  }
  cles <- unique(vapply(seq_len(n * 3L), function(i) texte_tire(sample(1:8, 1L)),
                        character(1)))
  cles <- cles[nzchar(cles)][seq_len(n)]
  if (anyNA(cles)) {
    return(enfants)
  }
  stats::setNames(enfants, cles)
}

# Permute les cles de chaque objet, a toute profondeur, sans toucher a l'ordre
# des tableaux - que JCS preserve, lui.
permuter_cles <- function(x) {
  if (!is.list(x)) {
    return(x)
  }
  x <- lapply(x, permuter_cles)
  nms <- names(x)
  if (is.null(nms) || length(x) < 2L) {
    return(x)
  }
  x[sample(length(x))]
}

echantillon <- function(n = 200L) lapply(seq_len(n), function(i) valeur_tiree())

# --- Canonisation -----------------------------------------------------------

test_that("la canonisation est invariante par permutation des cles", {
  # C'est la propriete dont tout le reste depend : deux ecritures d'un meme
  # contenu, dans deux ordres, doivent rendre les memes octets.
  for (x in echantillon()) {
    expect_identical(jcs(permuter_cles(x)), jcs(x))
  }
})

test_that("recanoniser une forme canonique ne la change pas", {
  # Un export relu puis reserialise doit rendre exactement ce qui a ete hache,
  # sinon la verification chez le destinataire echouerait sur du bruit.
  for (x in echantillon()) {
    canonique <- jcs(x)
    expect_identical(jcs_depuis_json(canonique), canonique)
  }
})

test_that("la canonisation ne depend pas de l'ordre ni de la casse de la locale", {
  # Le tri se fait sur les unites de code UTF-16, jamais sur l'ordre de
  # collation de la session : un poste en `fr_FR` et un poste en `C` doivent
  # produire le meme fichier.
  valeurs <- echantillon(60L)
  reference <- vapply(valeurs, jcs, character(1))
  initiale <- Sys.getlocale("LC_COLLATE")
  withr::defer(suppressWarnings(Sys.setlocale("LC_COLLATE", initiale)))

  eprouvees <- 0L
  for (locale in c("C", "en_US.UTF-8", "fr_FR.UTF-8", "de_DE.UTF-8")) {
    # `Sys.setlocale()` previent par un avertissement plutot que par une
    # erreur quand le systeme ne connait pas la locale : on lit son retour,
    # qui est vide dans ce cas, plutot que d'attendre une condition.
    obtenue <- suppressWarnings(Sys.setlocale("LC_COLLATE", locale))
    if (!nzchar(obtenue)) next               # locale absente de cette machine
    eprouvees <- eprouvees + 1L
    expect_identical(vapply(valeurs, jcs, character(1)), reference)
  }
  # `C` est garantie partout : si rien n'a ete eprouve, le test se tait a tort.
  expect_gte(eprouvees, 1L)
})

test_that("tout nombre engendre se relit exactement", {
  # `jcs_nombre()` suit `Number::toString` : la representation doit etre la
  # plus courte qui se relise sans perte. Un arrondi silencieux ferait diverger
  # deux verificateurs sur un volume de bois.
  for (i in seq_len(500L)) {
    v <- nombre_tire()
    expect_identical(as.numeric(jcs_nombre(v)), as.numeric(v))
  }
})

test_that("la forme canonique est du JSON qu'un tiers sait relire", {
  # Le destinataire n'est pas suppose posseder sommieR : il doit pouvoir
  # relire ce qui a ete hache avec un analyseur JSON quelconque. Une
  # canonisation qui ne produirait pas du JSON valide fermerait la chaine sur
  # elle-meme.
  for (x in echantillon()) {
    canonique <- jcs(x)
    relu <- jsonlite::fromJSON(canonique, simplifyVector = FALSE,
                               simplifyDataFrame = FALSE,
                               simplifyMatrix = FALSE)
    expect_identical(jcs(normaliser_json_lu(relu)), canonique)
  }
})

# --- Empreinte --------------------------------------------------------------

entree_tiree <- function(payload) {
  list(
    foret_id       = uuid_v4(),
    seq            = sample(1:10000, 1L),
    registre       = sample(1:9, 1L),
    ug_uuid        = if (stats::runif(1L) < 0.5) NULL else uuid_v4(),
    date_evenement = "2026-03-12",
    date_saisie    = "2026-03-12T09:14:00Z",
    auteur         = "agent-01",
    ndp            = sample(0:4, 1L),
    corrige_id     = NULL,
    schema_version = "r5-1",
    payload        = payload
  )
}

test_that("l'empreinte est invariante par permutation des cles du payload", {
  # La promesse faite au destinataire : reconstruire le payload champ par
  # champ, dans son ordre a lui, et retrouver la meme empreinte.
  precedente <- sommier_empreinte_genese(uuid_v4())
  for (i in seq_len(150L)) {
    payload <- valeur_tiree()
    if (!is.list(payload) || is.null(names(payload))) next
    entree <- entree_tiree(payload)
    remaniee <- entree
    remaniee$payload <- permuter_cles(payload)
    expect_identical(
      sommier_empreinte(remaniee, precedente),
      sommier_empreinte(entree, precedente)
    )
  }
})

test_that("l'empreinte est invariante par permutation des champs de l'entree", {
  # L'enregistrement canonique remet les champs dans son ordre a lui : l'ordre
  # de la liste que l'appelant a construite ne doit pas transparaitre.
  precedente <- sommier_empreinte_genese(uuid_v4())
  for (i in seq_len(100L)) {
    entree <- entree_tiree(list(volume_m3 = nombre_tire(), essence = texte_tire()))
    expect_identical(
      sommier_empreinte(entree[sample(length(entree))], precedente),
      sommier_empreinte(entree, precedente)
    )
  }
})

test_that("l'empreinte change des qu'un champ couvert change", {
  # L'ecart assume par rapport au brief - hacher l'enregistrement complet et
  # pas le seul payload - n'a de valeur que si chaque champ annonce pese
  # vraiment sur l'empreinte.
  precedente <- sommier_empreinte_genese(uuid_v4())
  autres <- list(
    foret_id = uuid_v4(), seq = 999L, registre = 7L, ug_uuid = uuid_v4(),
    date_evenement = "2019-11-02", date_saisie = "2019-11-02T23:59:59Z",
    auteur = "agent-99", ndp = 3L, corrige_id = uuid_v4(),
    schema_version = "r5-9",
    payload = list(volume_m3 = 1, essence = "CHE")
  )
  for (i in seq_len(40L)) {
    entree <- entree_tiree(list(volume_m3 = 12.5, essence = "HET"))
    entree$ug_uuid <- uuid_v4()
    entree$corrige_id <- uuid_v4()
    origine <- sommier_empreinte(entree, precedente)
    for (champ in SOMMIER_CHAMPS_EMPREINTE) {
      modifiee <- entree
      modifiee[[champ]] <- autres[[champ]]
      if (identical(modifiee[[champ]], entree[[champ]])) next
      expect_false(identical(sommier_empreinte(modifiee, precedente), origine),
                   label = paste("le champ", champ, "ne pese pas sur l'empreinte"))
    }
  }
})

test_that("l'empreinte change des que l'empreinte precedente change", {
  # Sans cela, la chaine ne serait qu'une suite d'empreintes independantes :
  # on pourrait retirer un maillon du milieu sans que rien ne le signale.
  for (i in seq_len(100L)) {
    entree <- entree_tiree(list(volume_m3 = nombre_tire()))
    a <- sommier_empreinte_genese(uuid_v4())
    b <- sommier_empreinte_genese(uuid_v4())
    expect_false(identical(sommier_empreinte(entree, a),
                           sommier_empreinte(entree, b)))
  }
})
