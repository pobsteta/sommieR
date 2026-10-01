# Extracted from test-export-db.R:51

# prequel ----------------------------------------------------------------------
base_export <- function() {
  con <- sauter_sans_base()
  withr::defer(DBI::dbDisconnect(con), envir = parent.frame())
  sommier_init_schema(con)
  con
}
foret_garnie <- function(con) {
  foret <- foret_creer(con, "Foret de Chaux", "communal", surface_ha = 500)
  amenager(con, foret, 2024, 2025, 100)
  ecrire <- function(registre, payload, date) {
    sommier_ajouter(con, sommier_entree(
      foret_id = foret, registre = registre, date_evenement = date,
      auteur = "agent-01", payload = payload
    ))
  }
  ecrire(5L, registre5_coupe("martelage", 2024, "amelioration", 120), "2024-03-01")
  ecrire(5L, registre5_coupe("martelage", 2025, "reguliere", 80), "2025-03-01")
  ecrire(6L, registre6_travaux(2024, "plantation", quantite = 3, unite = "ha",
                               montant_eur = 4800, taux_reprise_pct = 88),
         "2024-04-01")
  ecrire(7L, registre7_ecriture("bois_sur_pied", 2024, 18400), "2024-06-30")
  ecrire(7L, registre7_ecriture("reboisement", 2024, 4800), "2024-06-30")
  ecrire(8L, registre8_phenomene("tempete", "Coup de vent", surface_ha = 8),
         "2024-12-15")
  ecrire(8L, registre8_equilibre_gibier("2024-2025", 42,
                                        taux_abroutissement_pct = 23), "2025-02-01")
  ecrire(9L, registre9_arbre("Chene des Trois Bornes", "CHS", "Age"), "2024-05-01")
  # Hors periode : ne doit pas remonter dans un export borne a 2024-2025.
  ecrire(5L, registre5_coupe("martelage", 2030, "sanitaire", 500), "2030-03-01")
  foret
}

# test -------------------------------------------------------------------------
con <- base_export()
foret <- foret_garnie(con)
psg <- sommier_gestion_anterieure(con, foret, referentiel = "psg")
