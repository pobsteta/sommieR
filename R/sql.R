#' Decoupage d'un script SQL en instructions
#'
#' @description
#' Separe un script sur les points-virgules de premier niveau. Necessaire
#' parce que les pilotes qui passent par le protocole etendu de PostgreSQL
#' (RPostgres, via une instruction preparee) refusent plusieurs commandes en
#' un seul envoi : « cannot insert multiple commands into a prepared
#' statement ». Les pilotes en protocole simple l'acceptent, ce qui rend le
#' defaut invisible tant qu'on ne change pas de pilote.
#'
#' @details
#' Un simple `strsplit(sql, ";")` ne convient pas : le schema du sommier
#' contient des corps de fonction plpgsql delimites par `$$`, qui portent
#' leurs propres points-virgules. Le decoupage suit donc l'etat lexical du
#' script :
#'
#' * chaines `'...'`, ou `''` designe une apostrophe litterale et ne ferme
#'   pas la chaine ;
#' * identifiants entre guillemets `"..."` ;
#' * blocs delimites par le dollar, `$$...$$` ou `$tag$...$tag$`, ou seul le
#'   meme tag ferme le bloc ;
#' * commentaires de ligne `-- ...` ;
#' * commentaires de bloc, imbricables en PostgreSQL.
#'
#' @param sql Le script, en une chaine de caracteres.
#' @return Un vecteur de caracteres : une instruction par element, sans le
#'   point-virgule final, les instructions vides ecartees.
#'
#' @examples
#' decouper_sql("SELECT 1; SELECT 2;")
#'
#' @export
decouper_sql <- function(sql) {
  caracteres <- strsplit(paste(sql, collapse = "\n"), "", fixed = TRUE)[[1]]
  n <- length(caracteres)

  instructions <- character(0)
  debut <- 1L
  i <- 1L
  profondeur_bloc <- 0L

  suivant <- function(k) if (k <= n) caracteres[[k]] else ""

  while (i <= n) {
    c1 <- caracteres[[i]]
    c2 <- suivant(i + 1L)

    if (profondeur_bloc > 0L) {
      # Les commentaires de bloc s'imbriquent en PostgreSQL.
      if (c1 == "/" && c2 == "*") {
        profondeur_bloc <- profondeur_bloc + 1L
        i <- i + 2L
        next
      }
      if (c1 == "*" && c2 == "/") {
        profondeur_bloc <- profondeur_bloc - 1L
        i <- i + 2L
        next
      }
      i <- i + 1L
      next
    }

    if (c1 == "-" && c2 == "-") {
      while (i <= n && caracteres[[i]] != "\n") i <- i + 1L
      next
    }

    if (c1 == "/" && c2 == "*") {
      profondeur_bloc <- 1L
      i <- i + 2L
      next
    }

    if (c1 == "'") {
      i <- i + 1L
      while (i <= n) {
        if (caracteres[[i]] == "'") {
          # Une apostrophe doublee reste dans la chaine.
          if (suivant(i + 1L) == "'") {
            i <- i + 2L
            next
          }
          i <- i + 1L
          break
        }
        i <- i + 1L
      }
      next
    }

    if (c1 == "\"") {
      i <- i + 1L
      while (i <= n && caracteres[[i]] != "\"") i <- i + 1L
      i <- i + 1L
      next
    }

    if (c1 == "$") {
      tag <- lire_tag_dollar(caracteres, i, n)
      if (!is.null(tag)) {
        fin_ouverture <- i + nchar(tag)
        ferme <- trouver_tag_dollar(caracteres, fin_ouverture + 1L, n, tag)
        # Un bloc non ferme : on laisse le serveur produire l'erreur de
        # syntaxe, plutot que de decouper au milieu d'un corps de fonction.
        i <- if (is.null(ferme)) n + 1L else ferme + nchar(tag)
        next
      }
    }

    if (c1 == ";") {
      # `debut > i - 1` sur un point-virgule vide : l'intervalle
      # `debut:(i - 1)` compterait a rebours et produirait du texte inverse.
      if (i > debut) {
        instructions <- c(instructions, paste0(caracteres[debut:(i - 1L)], collapse = ""))
      }
      debut <- i + 1L
      i <- i + 1L
      next
    }

    i <- i + 1L
  }

  if (debut <= n) {
    instructions <- c(instructions, paste0(caracteres[debut:n], collapse = ""))
  }

  instructions <- trimws(instructions)
  # Une queue de script faite de commentaires seuls n'est pas une instruction.
  instructions[nzchar(instructions) & !instruction_vide(instructions)]
}

# Un fragment reduit a des commentaires et des blancs n'a rien a executer.
instruction_vide <- function(x) {
  sans_commentaire <- gsub("--[^\n]*", "", x)
  sans_commentaire <- gsub("/\\*.*?\\*/", "", sans_commentaire)
  !nzchar(trimws(sans_commentaire))
}

# Lit `$$` ou `$tag$` a la position i, ou NULL si le dollar n'ouvre pas de
# bloc (il peut appartenir a un identifiant, ou a `$1` dans une requete
# parametree).
lire_tag_dollar <- function(caracteres, i, n) {
  j <- i + 1L
  while (j <= n && grepl("^[A-Za-z0-9_]$", caracteres[[j]])) j <- j + 1L
  if (j > n || caracteres[[j]] != "$") {
    return(NULL)
  }
  paste0(caracteres[i:j], collapse = "")
}

trouver_tag_dollar <- function(caracteres, depuis, n, tag) {
  longueur <- nchar(tag)
  motif <- strsplit(tag, "", fixed = TRUE)[[1]]
  i <- depuis
  while (i + longueur - 1L <= n) {
    if (identical(caracteres[i:(i + longueur - 1L)], motif)) {
      return(i)
    }
    i <- i + 1L
  }
  NULL
}
