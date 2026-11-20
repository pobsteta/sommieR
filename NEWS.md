# sommieR 2026.11.1 (2026-11-20)

sommieR passe au versionnage calendaire `AAAA.M.N`, celui de `nemeton`, pour qu'une
seule convention de version vaille sur la plateforme (mission 029). Aucun code
fonctionnel ne change ; l'ordre des versions est gardé
(`package_version("2026.11.1") > package_version("0.44.0")`).

- **Forme** : `AAAA` = année, `M` = mois **sans zéro en tête** (`2026.1.1`, jamais
  `2026.01.1`), `N` = numéro de la release dans le mois, qui repart à 1 chaque
  mois. Entre deux releases, `DESCRIPTION` porte `AAAA.M.N.9000`.
- **Tags et releases** : `release.yml` ne pose le tag `vAAAA.M.N` et la release que
  pour une version stable de cette forme ; les tags `v0.x` déjà posés restent.
- **Garde-fou** : le job `version-consistency` (script
  `.github/scripts/verifier-version.sh`, testé par `test-version.R`) vérifie
  DESCRIPTION = NEWS = CITATION et que `AAAA.M` est l'année et le mois de la date
  de l'entrée NEWS.
- Les entrées 0.x ci-dessous ne sont pas réécrites.

