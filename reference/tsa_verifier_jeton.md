# Verification d'un jeton d'horodatage

Verifie qui atteste, et non plus seulement ce qui est atteste : la
signature de l'autorite sur le contenu du jeton, l'usage que son
certificat declare, sa validite a la date attestee, et la chaine qui le
rattache a une ancre de confiance.

## Usage

``` r
tsa_verifier_jeton(jeton, empreinte = NULL, ancres = list())
```

## Arguments

- jeton:

  Vecteur `raw` : le `TimeStampToken`.

- empreinte:

  Empreinte attendue (`raw` de 32 octets), ou `NULL` pour ne pas la
  confronter.

- ancres:

  Liste de certificats de confiance, lus par
  [`certificat_lire()`](https://pobsteta.github.io/sommieR/reference/certificat_lire.md).
  Aucune n'est embarquee dans le paquet : ce serait faire dependre du
  rythme de publication de sommieR la question de savoir qui est digne
  de confiance, et une racine retiree resterait attestee par toute
  version installee.

## Value

Un objet `sommier_verdict_tsa`.

## Details

**Trois etats, pas deux.**

- `"valide"` : tout est verifie, et la chaine remonte a une ancre
  fournie.

- `"non_rattache"` : le jeton est intact - signature de l'autorite
  verifiee, empreinte concordante, usages et dates bons - mais aucune
  ancre ne le couvre, soit qu'aucune n'ait ete fournie, soit qu'aucune
  ne convienne.

- `"invalide"` : quelque chose cloche dans le jeton lui-meme.

La distinction n'est pas cosmetique. Dire « invalide » a une commune
dont le jeton est parfait mais emis par une autorite qu'on n'a pas
listee serait faux, et lui faire croire a une garantie qu'on n'a pas
verifiee le serait tout autant.

**Ce qui est verifie**, dans cet ordre :

1.  le contenu se lit, et l'empreinte attestee est celle attendue ;

2.  le jeton porte un signataire et un seul (RFC 3161 section 2.4.2) ;

3.  l'attribut `contentType` annonce bien un `TSTInfo` ;

4.  l'attribut `messageDigest` correspond au condensat du contenu - sans
    quoi la signature porterait sur autre chose que ce qu'on a lu ;

5.  l'attribut `signingCertificate` designe le certificat employe, par
    son empreinte : sans lui, un certificat substitue dans le champ
    `certificates` passerait pour celui qui a signe ;

6.  la signature porte sur les attributs signes, reencodes en `SET OF`
    (RFC 5652 section 5.4) ;

7.  le certificat porte l'usage `id-kp-timeStamping` et lui seul ;

8.  il etait valide **a la date attestee**, non aujourd'hui ;

9.  la chaine remonte a une ancre, chaque lien verifie a cette meme
    date.

**Ce qui n'est pas verifie : la revocation.** CRL et OCSP demandent le
reseau, ce que la verification hors ligne exclut par construction. Un
certificat revoque mais non expire passe donc. La limite est reelle ;
elle est ecrite ici et rendue dans le verdict plutot que passee sous
silence.

## See also

[`tsa_lire_jeton()`](https://pobsteta.github.io/sommieR/reference/tsa_lire_jeton.md),
[`certificat_lire()`](https://pobsteta.github.io/sommieR/reference/certificat_lire.md)
