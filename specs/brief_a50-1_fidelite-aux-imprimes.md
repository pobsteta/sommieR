# Brief — A50, lot 1 : la fidélité aux imprimés

*Ouvert le 24 octobre 2026, après la confrontation du paquet aux imprimés
originaux fournis par Pascal (`specs/A50/`, non versionnés), rapportée dans
`specs/a50_confrontation-aux-originaux.md`.*

*Cadrage donné par Pascal : traiter les écarts 2 à 8 de la confrontation,
un à la fois.*

## Ma réponse d'abord

*24 octobre 2026, Pascal :*

> j'attends de ce lot une cohérence avec les fiches A50 quand on est sur un
> filtre ONF.
>
> je veux la cohérence pour les utilisateures ONF retrouvent leurs habitudes

## Ce que la vérification a établi

*Établi à la lecture des imprimés à l'image et du code (24 octobre 2026) ;
la base n'a pas été interrogée. Les renvois (a1, b1…) sont ceux de la
confrontation.*

- **Jusqu'ici, le contenu des imprimés n'était connu que par la synthèse**
  (`specs/brief_sommier-unifie-synthese.md`). Elle est confirmée pour A10,
  A50C, A50D, A50H, A50F, A50J, A50J bis, r/e et r/h ; elle omet ou
  contredit le reste (b1 à b16).
- **L'A50F est le relevé des coupes martelées**, par unité : corrigé en
  0.37.1 (documentation seule). Reste à dire ce qu'est `coupe_realisee`,
  qu'aucun imprimé ne porte.
- **Il n'y a pas de schéma JSON** : les constructeurs `registreN_*()` font
  schéma, versionnés par `SOMMIER_SCHEMA_VERSIONS`. Ajouter une rubrique,
  c'est une nouvelle version de schéma ; les écritures anciennes restent
  valides.

Les écarts à trancher, dans l'ordre de la confrontation :

| # | Imprimé | Ce que l'original porte et que le sommier n'a pas | Renvois |
|---|---|---|---|
| 2 | A50E | Le cartouche « Volumes comptabilisés », « Tarifs employés », « Groupe(s) concerné(s) » ; la balance tenue par série, quand le sommier la tient par aménagement et que les écritures ne portent pas la série | a1, a2, b13 |
| 3 | A50G | Un 4e poste de travaux neufs, « Chasse - Pêche » ; le total « (Frais de personnel exclus) » | b1 |
| 4 | A40 | Le verso, « État de répartition » riverain par riverain (article du PV, nom, adresse, développement de limite, frais) ; la rubrique 5, frais d'actes ; le technicien privé payé en montant, non en heures | a3, a4, b3 |
| 5 | A50D bis | Le verso « Travaux effectués » de la route, sans lien au registre 6 ; la date de la structure de chaussée, qui est celle du 1er établissement de la fiche ; l'usage en cases cumulables | a5, a6, b4, b5 |
| 6 | A50L | Le verso, tableaux de repeuplement (Office, locataire) et renseignements ; les espèces et catégories, liste fermée sur l'imprimé, texte libre dans le sommier | a8, a9, b12 |
| 7 | r/a, r/p | Numéro, remarques, travaux effectués, bibliographie ; au r/p, l'état sanitaire et le relevé des martelages au verso | a10, a11, b8, b9 |
| 8 | A50J bis | La grille de suivi des jeunes peuplements (groupe d'aménagement, région IFN, surfaces, Norme × Classe × Année), remplacée par les placettes sans voie de reprise | a7 |

## Ce que le contradicteur a objecté

*Contre-lecture du 24 octobre 2026, classée de la plus grave à la moins
grave ; les constats sur le code ont été vérifiés.*

1. **Le « filtre ONF » n'a pas de point d'ancrage.** `foret.regime` est
   modifiable et n'entre pas dans l'empreinte (`R/empreinte.R:35-57`) ; une
   forêt change de régime en cours de chaîne (registre 2,
   `application_regime`) ; l'autorité de visa `onf` qualifie un exercice, pas
   une forêt. Les imprimés eux-mêmes varient selon le régime (verso de
   l'A50L « en forêt domaniale », rubrique 1 de l'A40 « uniquement en forêt
   non domaniale »).
2. **Les écarts 2 à 8 sont presque tous de la donnée chaînée**, pas du
   rendu : un filtre d'affichage ne montre pas ce que le sommier ne contient
   pas, et chaque ajout est une version de schéma irréversible.
3. **Ce qui sert les habitudes est la présentation** (a16 à a18 : mise en
   page des imprimés, libellés, unités), que le brief excluait.
4. **La règle ONF est dans les notes de service**, pas dans le formulaire :
   NDS-10-T-320 du 16/12/2010 (origine des MFR, n° de certificat maître),
   NDS 94-G-554 du 24/01/1994 (non trouvée en ligne) ; l'ONF annonce la
   « modernisation » du sommier ; rien n'atteste le classeur A50 en 2026.
5. **Le verso de l'A40 mettrait noms et adresses de riverains dans une
   chaîne qui ne s'efface pas** (cf. `R/registre3.R:16-19`, CNIL « Blockchain
   et RGPD »).
6. **L'ordre 2 à 8 ignore les dépendances** : la série portée par l'entrée
   et le sens de `coupe_realisee` d'abord.
7. **Reproduire la mise en page suppose d'en connaître les droits.**

## Décisions de conception

*Arbitrages de Pascal, 24 octobre 2026, après la contre-lecture.*

1. **Ce lot sert les habitudes de l'agent ONF.** C'est une fidélité de
   présentation : le document se lit comme le classeur A50. La fidélité de
   contenu (les écarts 2 à 8 dans la chaîne, pour la reprise et la preuve)
   n'est pas l'objet de ce lot.

2. **Le « filtre ONF » est une option d'édition.** Choisie au rendu, inscrite
   au manifeste de l'édition, jamais déduite du régime de la forêt ni de
   l'autorité de visa. Aucune règle de validation, aucune version de schéma
   n'en dépend.

3. **L'édition donne l'équivalent des renseignements des imprimés, pas les
   imprimés.** *Validation de Pascal, 24 octobre 2026 :* « je valide qu'on
   doit retrouver l'équivalent des renseignements des fiches A50 mais pas
   les fiches A50 comme elles existent déjà, ça doit être plus moderne ».
   Les rubriques, leurs libellés, les unités et les regroupements (par
   exercice, par saison) se retrouvent ; la mise en page est celle d'un
   document d'aujourd'hui. Ni cadre, ni numéro d'édition, ni logo : les
   droits des imprimés ne sont pas connus.

4. **Une rubrique que le sommier ne tient pas figure, vide et dite.** La
   colonne est à sa place, marquée « non tenu au sommier » : l'agent
   retrouve ses renseignements et voit ce qui manque. La donnée viendra, si elle
   doit venir, d'un lot de contenu.

5. **Tous les imprimés, une section par imprimé.** A10, A40, A50C à A50L
   (D bis, J bis compris), r/a, r/c, r/e, r/h, r/p, r/s : chaque imprimé a
   sa section, nommée par lui, qui en donne tous les renseignements sous
   leur libellé imprimé.

6. **Ces sections s'ajoutent au registre imprimé.** Le journal par
   registre, la fiche A10, les croquis et les empreintes restent ; les
   sections A50 viennent en plus. Chaque ligne porte le numéro de son
   écriture, pour remonter à la chaîne.

## Livrables

**Lot 1 : l'édition A50**

- **L'option.** `sommier_registre_quarto()` gagne une option d'édition
  (nom à fixer, p. ex. `imprimes = "a50"`), inscrite au manifeste de
  l'édition. Sans elle, le document est inchangé.
- **Les sections.** Une partie « Le sommier selon les imprimés A50 » : une
  section par imprimé, dans l'ordre du classeur, qui en donne les
  renseignements sous leur libellé, avec les regroupements qui les rendent
  lisibles (bloc par exercice et balance de l'A50E, matrice par saison de
  l'A50L, totaux par poste de l'A50G, longueurs en km et densités de
  l'A50D, une fiche par objet des r/*). La forme est moderne, pas un
  fac-similé. Chaque ligne porte son n° d'écriture.
- **Les rubriques non tenues** figurent, vides, marquées « non tenu au
  sommier ».
- **Rien d'autre ne change** : ni schéma, ni écriture, ni le reste du
  document.

## Critères d'acceptation

*Arbitrages de Pascal, 24 octobre 2026.*

- **Recette :** Pascal relit l'édition A50 de la démo de Couchey et dit si
  un agent ONF y retrouve ses habitudes. Aucun agent en poste n'est nommé ;
  que le classeur A50 soit encore tenu en 2026 n'est pas vérifié.
- **Le schéma ne bouge pas :** aucune version de `SOMMIER_SCHEMA_VERSIONS`
  ne change, la chaîne de Couchey est identique avant et après l'édition.

## Questions ouvertes

- **Les droits des imprimés** : ni versionnés ni diffusés tant que leurs
  droits ne sont pas connus ; l'édition n'en reprend que les rubriques
  (décision 3).
- **Le lot de contenu** (écarts 2 à 8, hors de ce lot), quand il viendra,
  part des objections du contradicteur :
  - trancher d'abord la série figée dans l'écriture et le sens de
    `coupe_realisee` ;
  - prendre les notes de service ONF (94-G-554, NDS-10-T-320) comme
    référentiel du contenu, dont l'origine des MFR et le n° de certificat
    maître ;
  - ne chaîner du verso de l'A40 que l'empreinte de la pièce et des données
    non nominatives ;
  - ne pas redéfinir `date_structure`, mais ajouter un champ dans une
    nouvelle version ;
  - une liste fermée (espèces de l'A50L) vaut pour tous les régimes ou pour
    aucun.
- **Les régimes que le schéma ne représente pas** (autres collectivités,
  indivision public-privé, forêt communale non soumise) : hors de ce lot.
- **Les rubriques propres à un régime** (verso de l'A50L « en forêt
  domaniale », rubrique 1 de l'A40) : l'édition les montre comme
  l'imprimé ; leur pertinence n'est pas déduite du régime.
- **Les pièces secondaires** (CD7, D01, D1.12, D1.23, D11, catalogue) :
  hors de ce lot.
