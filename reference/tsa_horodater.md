# Obtention d'un jeton d'horodatage

Interroge l'autorite, et confronte le jeton rendu a ce qui a ete
demande.

## Usage

``` r
tsa_horodater(empreinte, url, transport = tsa_transport_curl(), nonce = NULL)
```

## Arguments

- empreinte:

  Vecteur `raw` de 32 octets a horodater.

- url:

  URL de l'autorite d'horodatage.

- transport:

  Fonction de transport, voir
  [`tsa_transport_curl()`](https://pobsteta.github.io/sommieR/reference/tsa_transport_curl.md).

- nonce:

  Nonce a employer. Par defaut, six octets d'alea.

## Value

Un vecteur `raw` : le jeton d'horodatage.

## Details

Deux confrontations, que la RFC 3161 rend obligatoires et que le jeton
seul permet :

- **L'empreinte attestee est celle qui a ete envoyee.** Sans quoi le
  registre archiverait un jeton portant sur autre chose que sa tete de
  chaine.

- **Le nonce rendu est celui qui a ete envoye** (section 2.4.2 : present
  dans la requete, il doit l'etre dans la reponse, avec la meme valeur).
  C'est ce qui distingue une reponse fraiche du rejeu d'une reponse
  anterieure. Le nonce etait pose depuis la v0.2.0, mais personne ne le
  relisait : la detection annoncee n'avait jamais lieu.

## See also

[`tsa_lire_jeton()`](https://pobsteta.github.io/sommieR/reference/tsa_lire_jeton.md)
