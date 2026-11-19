# Un JPEG minimal (un en-tete EXIF, pas d'image) pour tester la lecture des
# balises : fabrique a la main plutot que gardee en fixture, pour que chaque
# test dise ce que le fichier contient.

exif_u16 <- function(x) as.raw(c(x %% 256L, x %/% 256L))
exif_u32 <- function(x) as.raw(c(x %% 256, (x %/% 256) %% 256,
                                 (x %/% 65536) %% 256, x %/% 16777216))
exif_ascii <- function(txt) c(charToRaw(txt), as.raw(0))
exif_rat <- function(num, den) c(exif_u32(num), exif_u32(den))

# entrees : liste de list(tag, type, nombre, donnees : raw). Une valeur de plus
# de quatre octets est rangee apres la table, a l'adresse que porte l'entree.
exif_ifd <- function(entrees, debut) {
  taille <- 2L + 12L * length(entrees) + 4L
  curseur <- debut + taille
  table <- list(exif_u16(length(entrees)))
  zone <- raw(0)
  for (e in entrees) {
    d <- e$donnees
    if (length(d) > 4L) {
      valeur <- exif_u32(curseur)
      zone <- c(zone, d)
      curseur <- curseur + length(d)
    } else {
      valeur <- c(d, raw(4L - length(d)))
    }
    table[[length(table) + 1L]] <- c(exif_u16(e$tag), exif_u16(e$type),
                                     exif_u32(e$nombre), valeur)
  }
  list(octets = c(unlist(table), exif_u32(0), zone), fin = curseur)
}

# `gps` : NULL ou list(lat, lon, datum, erreur_m) ; `date`, `decalage` : texte.
photo_exif <- function(chemin, date = "2026:11:18 10:31:05", decalage = NULL,
                       gps = NULL) {
  exif <- list(list(tag = 36867L, type = 2L, nombre = 20L,
                    donnees = exif_ascii(date)))
  if (!is.null(decalage)) {
    exif <- c(exif, list(list(tag = 36881L, type = 2L, nombre = 7L,
                              donnees = exif_ascii(decalage))))
  }
  ifd0_taille <- 2L + 12L * (1L + !is.null(gps)) + 4L
  exif_debut <- 8L + ifd0_taille
  b_exif <- exif_ifd(exif, exif_debut)
  entrees0 <- list(list(tag = 34665L, type = 4L, nombre = 1L,
                        donnees = exif_u32(exif_debut)))
  b_gps <- list(octets = raw(0), fin = b_exif$fin)
  if (!is.null(gps)) {
    deg <- function(v) {
      d <- floor(abs(v))
      m <- floor((abs(v) - d) * 60)
      s <- round(((abs(v) - d) * 60 - m) * 60 * 1000)
      c(exif_rat(d, 1L), exif_rat(m, 1L), exif_rat(s, 1000L))
    }
    g <- list(
      list(tag = 1L, type = 2L, nombre = 2L,
           donnees = exif_ascii(if (gps$lat < 0) "S" else "N")),
      list(tag = 2L, type = 5L, nombre = 3L, donnees = deg(gps$lat)),
      list(tag = 3L, type = 2L, nombre = 2L,
           donnees = exif_ascii(if (gps$lon < 0) "W" else "E")),
      list(tag = 4L, type = 5L, nombre = 3L, donnees = deg(gps$lon)))
    if (!is.null(gps$datum)) {
      g <- c(g, list(list(tag = 18L, type = 2L, nombre = nchar(gps$datum) + 1L,
                          donnees = exif_ascii(gps$datum))))
    }
    if (!is.null(gps$erreur_m)) {
      g <- c(g, list(list(tag = 31L, type = 5L, nombre = 1L,
                          donnees = exif_rat(round(gps$erreur_m * 100), 100L))))
    }
    b_gps <- exif_ifd(g, b_exif$fin)
    entrees0 <- c(entrees0, list(list(tag = 34853L, type = 4L, nombre = 1L,
                                      donnees = exif_u32(b_exif$fin))))
  }
  b0 <- exif_ifd(entrees0, 8L)
  tiff <- c(charToRaw("II"), exif_u16(42L), exif_u32(8L), b0$octets,
            b_exif$octets, b_gps$octets)
  app1 <- c(charToRaw("Exif"), raw(2), tiff)
  longueur <- length(app1) + 2L
  writeBin(c(as.raw(c(0xFF, 0xD8, 0xFF, 0xE1)),
             as.raw(c(longueur %/% 256L, longueur %% 256L)), app1,
             as.raw(c(0xFF, 0xD9))), chemin)
  invisible(chemin)
}
