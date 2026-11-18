#!/bin/bash
# Resout des motifs de bibliotheques (ex. libgdal[0-9]+(t64)?) en noms de paquets apt
# existants sur le runner : les noms changent d'une version d'Ubuntu a l'autre
# (libgdal34t64 introuvable sur 26.04, le 2026-11-18). A lancer apres apt-get update.
for motif in "$@"; do
  nom=$(apt-cache search --names-only "^${motif}$" | awk '{print $1}' | sort -V | tail -1)
  if [ -n "$nom" ]; then echo "$nom"; else echo "syslibs: aucun paquet pour ${motif}" >&2; fi
done
