# Journal de sommieR

> **Règle du sommier : on n'efface pas, on ajoute.**
> Chaque inscription est datée et signée (agent ou personne). Une correction est une
> nouvelle ligne qui renvoie à l'ancienne. Un hook refuse toute modification qui
> supprimerait ou réécrirait une inscription existante.
>
> Format : `AAAA-MM-JJ · auteur · mission · ce qui a été fait / décidé / bloqué`
>
> **Le carnet des écarts** (fiche n° 3), en une ligne marquée `écart` :
> `AAAA-MM-JJ · auteur · mission · écart · attendu : … · vu : … · vérifié : comment (ou « non ») · décision : …`
> La décision est l'une des trois : **garder** (vérifié : on adopte), **creuser** (prochain
> essai, daté), **abandonner** (vrai hasard : on le note).
> Règle : on ne sanctionne pas un écart signalé ; on regarde d'abord, on corrige ensuite,
> s'il le faut.
>
> **Les changements de cap** (fiche n° 13), en une ligne marquée `cap`, signée par qui l'a
> décidé : `AAAA-MM-JJ · auteur · mission · cap · ancien → nouveau · pourquoi : … · fait : …`
>
> **La délégation**, en une ligne marquée `délégation`, signée de Pascal :
> `AAAA-MM-JJ · Pascal · — · délégation · portée : … · jusqu'à : … · réservé : …`
> Chaque décision prise par délégation :
> `AAAA-MM-JJ · Claude (orchestrateur, par délégation) · mission · décidé : … · pourquoi : … · ce que Pascal peut défaire : …`

2026-11-17 · Claude (orchestrateur) · 011 · méthode installée (`CLAUDE.md`, `docs/brief.md`, `pilotage/`, `docs/adr/`, `.claude/settings.json`, `.claude/test-command`) avec les réponses de Pascal validées le 2026-11-17 ; reste à remplir : les rubriques de `docs/brief.md` (`/brief`), l'équipe et les missions (`/mission`).
2026-11-17 · hook tests_obligatoires · — · arrêt accepté au second essai sans tests verts (délai de 630 s dépassé, `Rscript -e 'res <- devtools::test(reporter = "summary", stop_on_failure = FALSE); plat <- as.data.frame(res); ech <- sum(plat$failed) + sum(plat$error); mot <- unlist(lapply(res, function(f) vapply(f$results, function(r) if (inherits(r, "expectation_skip")) conditionMessage(r) else "", character(1)))); sb <- grep("Aucune base PostgreSQL", mot, value = TRUE); cat("echecs:", ech, " sauts pour base injoignable:", length(sb), "\n"); if (length(sb)) { cat("La base de test (SOMMIER_TEST_DB) n est pas jointe : un vert obtenu en sautant les tests de base est trompeur.\n"); quit(status = 1) }; if (ech > 0) quit(status = 1)'`) : mission non vérifiée, à reprendre.
2026-11-17 · hook tests_obligatoires · — · arrêt accepté au second essai sans tests verts (délai de 630 s dépassé, `Rscript -e 'res <- devtools::test(reporter = "summary", stop_on_failure = FALSE); plat <- as.data.frame(res); ech <- sum(plat$failed) + sum(plat$error); mot <- unlist(lapply(res, function(f) vapply(f$results, function(r) if (inherits(r, "expectation_skip")) conditionMessage(r) else "", character(1)))); sb <- grep("Aucune base PostgreSQL", mot, value = TRUE); cat("echecs:", ech, " sauts pour base injoignable:", length(sb), "\n"); if (length(sb)) { cat("La base de test (SOMMIER_TEST_DB) n est pas jointe : un vert obtenu en sautant les tests de base est trompeur.\n"); quit(status = 1) }; if (ech > 0) quit(status = 1)'`) : mission non vérifiée, à reprendre.
2026-11-17 · Claude (orchestrateur, par délégation) · 011 · décidé : le brief et les ADR vont dans `pilotage/brief.md` et `pilotage/adr/` (et non `docs/brief.md`, `docs/adr/` cités à la ligne du 2026-11-17 ci-dessus), `docs/` étant la sortie pkgdown ignorée par `.gitignore` ; `^pilotage$` et `^\.claude$` ajoutés à `.Rbuildignore` ; `.claude/test-command` ramenée à un niveau rapide sous 600 s (ADR 0001 amendée le 2026-11-16), suite complète en CI · pourquoi : précédent nemetonshiny, règle des deux niveaux · ce que Pascal peut défaire : rétablir `docs/` ou la suite complète dans la commande.
2026-11-17 · hook tests_obligatoires · — · arrêt accepté au second essai sans tests verts (délai de 630 s dépassé, `Rscript -e 'res <- devtools::test(reporter = "summary", stop_on_failure = FALSE); plat <- as.data.frame(res); ech <- sum(plat$failed) + sum(plat$error); mot <- unlist(lapply(res, function(f) vapply(f$results, function(r) if (inherits(r, "expectation_skip")) conditionMessage(r) else "", character(1)))); sb <- grep("Aucune base PostgreSQL", mot, value = TRUE); cat("echecs:", ech, " sauts pour base injoignable:", length(sb), "\n"); if (length(sb)) { cat("La base de test (SOMMIER_TEST_DB) n est pas jointe : un vert obtenu en sautant les tests de base est trompeur.\n"); quit(status = 1) }; if (ech > 0) quit(status = 1)'`) : mission non vérifiée, à reprendre.
2026-11-18 · Claude (orchestrateur de la plateforme) · — · décision de Pascal (2026-11-18, « Aligne claude.md sur la délégation que je t'ai donnée ») : la porte n° 3 de sommieR suit la délégation de la plateforme du 2026-11-16 ; `CLAUDE.md` (« Le déroulé ») et `pilotage/equipe.md` (§ Délégation) mis à jour · ce que Pascal peut défaire : vider la délégation de `pilotage/equipe.md`.
