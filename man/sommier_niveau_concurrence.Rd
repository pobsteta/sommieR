% Please edit documentation in R/registre6.R
\name{sommier_niveau_concurrence}
\alias{sommier_niveau_concurrence}
\title{Niveau de concurrence d'une placette, depuis les plants}
\usage{
sommier_niveau_concurrence(nb_concurrences, nb_vivants)
}
\arguments{
\item{nb_concurrences}{Plants vivants concurrences par la vegetation.}

\item{nb_vivants}{Plants vivants comptes.}
}
\value{
Un element de \link{SOMMIER_CONCURRENCES}, ou \code{NA_character_}.
}
\description{
Regle de passage du critere binaire par plant (concurrence ou non, guide 2014
p. 52) au niveau de placette : on compte la part des plants vivants concurrences
par la vegetation, puis on la lit dans
\link{SOMMIER_DEFINITIONS_CONCURRENCE}. Un seul niveau couvre l'herbacee et la
ligneuse (fougere aigle, ronce) : on note le plus eleve des deux, et la
nature se dit en \code{observations}.

Sans plant vivant compte, le resultat est \code{NA} : jamais un niveau devine.
}
\seealso{
\code{\link[=registre6_controle]{registre6_controle()}}
}
