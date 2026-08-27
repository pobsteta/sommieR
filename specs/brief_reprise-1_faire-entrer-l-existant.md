# Brief — Reprise, lot 1 : faire entrer l'existant sans faire mentir la chaîne

*Établi le 27 août 2026, après lecture du modèle d'entrée et de ce que la
v0.2.0 a déjà tranché pour les détections.*

## Pourquoi ce lot existe

sommieR ne sait démarrer qu'à vide. Une forêt qui entre dans le dispositif a
pourtant trente ans d'histoire : registres A50 sur papier, base ONF, tableurs
tenus par un CRPF, arrêtés de la commune. Aujourd'hui, deux issues, mauvaises
toutes les deux.

* **La laisser dehors.** Mais l'un des trois exports que le paquet produit est
  le *bilan de l'aménagement précédent* — un document qui porte sur la période
  écoulée. Un sommier ouvert en 2027 ne peut rien en dire avant 2047.
* **La saisir comme si elle arrivait aujourd'hui.** Une coupe de 1998 entrerait
  avec la date d'événement de 1998 mais serait, pour tout le reste,
  indiscernable d'un constat de terrain. Le sommier dirait qu'il sait, alors
  qu'il a recopié.

Le brief de synthèse a vu le problème sans le traiter : « le chaînage ne se
rétrofitte pas sur un registre existant sans en réécrire la genèse ». C'est
vrai, et ce n'est pas une raison de renoncer — c'est une contrainte de
conception.

## Ce que la lecture du modèle a établi

| Constat | Où |
|---|---|
| `date_evenement` (DATE) et `date_saisie` (TIMESTAMPTZ) sont **deux champs distincts**, tous deux couverts par l'empreinte | `inst/sql/001_schema.sql:118` et le commentaire ligne 133 |
| `sommier_entree()` accepte `date_saisie` en paramètre, **et rien ne l'empêche d'être dans le passé** | `R/entree.R:57` |
| `ndp` porte déjà la bonne sémantique : « une entrée saisie sur le terrain est NDP 0 par définition, une entrée déduite porte le NDP de sa source » | `R/entree.R:11` |
| La v0.2.0 a appliqué cette règle aux détections FORDEAD : elles entrent **comme propositions, jamais NDP 0** | NEWS 0.2.0 |
| Une correction est une entrée de plus, jamais une réécriture | `inst/sql/001_schema.sql:139` |
| `sommier_ajouter()` accepte une liste et insère par lot | `R/ajouter.R:33` |

Deux conclusions en découlent.

**Le modèle sait déjà dire ce qu'il faut.** Il distingue *quand la chose est
arrivée* de *quand on l'a écrite*, et il sait qualifier la valeur d'une
entrée. Rien à ajouter au schéma : ce lot est une discipline d'emploi, pas une
extension.

**Et il sait déjà mentir.** `date_saisie` est librement fixable. Une reprise
naïve — ou pressée — l'antidaterait pour « faire propre », et la chaîne
attesterait alors qu'elle savait depuis 1998. C'est le seul endroit du paquet
où l'on peut faire dire au registre une chose fausse sans rien casser.

## Décisions de conception

1. **Une reprise est une transcription, pas un constat.** Elle porte
   `date_evenement` dans le passé, `date_saisie` **à l'instant réel de la
   transcription**, et un NDP strictement supérieur à 0. C'est exactement la
   règle des détections, appliquée à une autre source : le sommier dit « le
   3 mars 2027, l'agent X a transcrit une coupe de 1998 », il ne dit pas
   « une coupe a été enregistrée en 1998 ».

2. **Antidater `date_saisie` doit devenir impossible pour une reprise.** C'est
   la décision centrale du lot. Le champ reste libre ailleurs — les tests en
   ont besoin pour être déterministes — mais le constructeur de reprise le
   pose lui-même et refuse qu'on le lui dicte. Une chaîne qui peut être
   convaincue d'avoir su plus tôt qu'elle n'a su ne vaut rien.

3. **La source se cite, ou la reprise n'a pas lieu.** Chaque entrée reprise
   porte la référence de la pièce dont elle est tirée : imprimé A50E de tel
   exercice, délibération du conseil municipal, extrait de base daté. Sans
   elle, une reprise est indiscernable d'une invention. C'est la règle du lot 4
   cartographique — aucune table `SYM` embarquée tant qu'une source n'est pas
   citable — appliquée à ce qui entre dans le registre plutôt qu'au décor.

4. **La chaîne ne rejoue pas l'histoire, elle la date.** Les entrées reprises
   ne s'insèrent pas « à leur place » dans la séquence : la séquence est celle
   de l'écriture, et elle le reste. Une reprise de trente ans produit un bloc
   d'entrées contiguës, dont les dates d'événement remontent le temps.

5. **La genèse reste la genèse.** Aucune réécriture, aucun recalcul. Une forêt
   reprise a une chaîne qui commence à sa mise en service ; ce qui la précède y
   entre comme contenu, jamais comme antériorité.

6. **Le repris ne se confond pas avec le constaté dans les documents.** Le
   bilan d'aménagement engendré depuis un sommier repris doit dire lesquels de
   ses chiffres viennent d'une transcription. Un tableau qui mêle les deux sans
   le dire ferait passer la recopie pour de la mesure.

## Livrables

* Un constructeur de reprise, qui impose la source, impose un NDP > 0 et pose
  `date_saisie` lui-même.
* La reprise par lot, adossée à `sommier_ajouter()`, avec le compte-rendu de ce
  qui est entré : combien d'entrées, par registre, sur quelle période, depuis
  quelles pièces.
* Une échelle de NDP documentée pour les provenances usuelles — registre
  papier signé, base d'un gestionnaire, tableur sans visa — plutôt qu'un
  entier laissé au jugement de l'appelant.
* La marque du repris dans les vues de consultation et dans le rapport de
  gestion antérieure.

## Critères d'acceptation

* Une entrée reprise ne peut pas être NDP 0, et une reprise sans source citée
  est refusée.
* `date_saisie` d'une reprise est l'instant réel de l'écriture ; toute
  tentative de la dicter est refusée, et un test le démontre.
* La séquence d'une forêt reprise est celle de l'écriture : les dates
  d'événement remontent le temps, la séquence non.
* La chaîne d'une forêt reprise se vérifie comme une autre, et son manifeste
  aussi.
* Le rapport de gestion antérieure distingue ce qui a été constaté de ce qui a
  été transcrit.
* Une reprise de plusieurs milliers d'entrées passe en un lot, sans que
  l'empreinte cesse d'être calculée côté R — la canonisation ne se délègue pas
  à la base.

## Ce que ce lot ne fait pas

Il ne lit aucun format en particulier. Transformer un tableur communal ou un
export ONF en entrées de sommier est un travail de terrain, propre à chaque
source, et l'y enfermer maintenant figerait une supposition sur des données
qu'on n'a pas vues. Ce lot pose la **discipline** de la reprise et le contrat
qu'elle doit tenir ; les convertisseurs viendront ensuite, un par source réelle
et documentée.
