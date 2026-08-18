#' sommieR : le sommier forestier unifie, a valeur probante
#'
#' @description
#' Le sommier n'est pas un document mais un systeme de registres permanents,
#' complementaire du document de gestion : l'amenagement dit ce qui est prevu,
#' le sommier enregistre ce qui advient. `sommieR` en implemente les trois
#' invariants :
#'
#' 1. **Append-only** - on n'ecrase jamais, on ajoute. Une correction est une
#'    nouvelle entree portant `corrige_id`, comme la mention rectificative du
#'    classeur papier ou la rature est interdite.
#' 2. **Trois echelles d'ancrage** - la foret, l'unite de gestion, l'objet
#'    remarquable. Chaque entree se rattache a exactement une echelle.
#' 3. **Controle par visa** - la validation annuelle est ce qui rend le
#'    sommier opposable.
#'
#' L'append-only y est une propriete **verifiable**, pas une convention
#' applicative : les entrees forment un journal a chainage de hachages
#' SHA-256 calcules sur une serialisation JSON canonique (RFC 8785), que
#' n'importe quel tiers peut recalculer a partir d'un export.
#'
#' @section Perimetre de la version 0.1.0:
#' Priorite 1 du brief - le noyau append-only verifiable :
#' forets, unites de gestion a identifiant stable et filiation,
#' entrees chainees, verification de chaine, registres 5 (coupes et recoltes)
#' et 6 (travaux), balance de possibilite A50E, export verifiable.
#'
#' Les registres 1, 2, 3, 4, 7, 8 et 9 sont declares dans
#' [SOMMIER_REGISTRES] mais fermes a l'ecriture ; le flux de visa signe
#' (AgentConnect, JWS, horodatage RFC 3161) releve de la v0.2.0, ses tables
#' etant deja posees par le schema.
#'
#' @keywords internal
"_PACKAGE"

## usethis namespace: start
## usethis namespace: end
NULL
