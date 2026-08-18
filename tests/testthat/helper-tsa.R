# Reponse RFC 3161 simulee : SEQUENCE { PKIStatusInfo { INTEGER statut }, jeton }
# Construite a la main pour que les tests d'analyse tournent hors ligne, sans
# autorite d'horodatage joignable.
reponse_tsa_simulee <- function(statut, jeton = NULL) {
  info <- as.raw(c(0x30, 0x03, 0x02, 0x01, statut))
  contenu <- if (is.null(jeton)) info else c(info, jeton)
  c(as.raw(c(0x30, length(contenu))), contenu)
}
