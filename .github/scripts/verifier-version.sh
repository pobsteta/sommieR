#!/usr/bin/env bash
# Garde-fou de version : DESCRIPTION = NEWS.md = CITATION.cff, et, en
# versionnage calendaire AAAA.M.N, AAAA.M = année et mois de la date de
# l'entrée NEWS. Repris du job `version-consistency` de nemeton (r.yml),
# sorti en script pour que la CI et le test (tests/testthat/test-version.R)
# exécutent le même code.
# Usage : verifier-version.sh [DESCRIPTION [NEWS.md [CITATION.cff]]]
set -u
description=${1:-DESCRIPTION}
news_file=${2:-NEWS.md}
cff_file=${3:-CITATION.cff}

desc=$(awk '/^Version:/{print $2; exit}' "$description")
if ! [[ "$desc" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Cycle dev ($desc) — garde-fou de cohérence sauté."
  exit 0
fi
# En-tête « # sommieR X.Y.Z », pas le premier numéro venu du fichier.
news=$(grep -m1 -E '^# sommieR ' "$news_file" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
cff=$(grep -m1 -E '^version:' "$cff_file" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
echo "DESCRIPTION=$desc  NEWS=$news  CITATION=$cff"
if [ -z "$desc" ] || [ "$desc" != "$news" ] || [ "$desc" != "$cff" ]; then
  echo "::error::Versions désalignées (DESCRIPTION=$desc, NEWS=$news, CITATION=$cff)"
  exit 1
fi
echo "✅ versions alignées : $desc"
# Versionnage calendaire AAAA.M.N : mois sans zéro en tête, N >= 1, et AAAA.M
# = année et mois de la date de NEWS. Les versions 0.x (avant 2026.11.1)
# n'ont que l'alignement à vérifier.
annee=${desc%%.*}
if [ "$annee" -ge 1000 ]; then
  if ! [[ "$desc" =~ ^[0-9]{4}\.([1-9]|1[0-2])\.[1-9][0-9]*$ ]]; then
    echo "::error::Version calendaire mal formée : $desc (attendu AAAA.M.N, mois sans zéro en tête, N >= 1)"
    exit 1
  fi
  date_news=$(grep -m1 -E '^# sommieR ' "$news_file" | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}' | head -1)
  if [ -z "$date_news" ]; then
    echo "::error::Entrée NEWS sans date AAAA-MM-JJ (attendu « # sommieR $desc (AAAA-MM-JJ) »)"
    exit 1
  fi
  attendu="$(echo "$date_news" | cut -d- -f1).$((10#$(echo "$date_news" | cut -d- -f2)))"
  mois=$(echo "$desc" | cut -d. -f1-2)
  if [ "$mois" != "$attendu" ]; then
    echo "::error::Version $desc, mais l'entrée NEWS est datée du $date_news (attendu $attendu.N)"
    exit 1
  fi
  echo "✅ version calendaire cohérente avec la date NEWS ($date_news)"
fi
