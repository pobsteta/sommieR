# Algorithmes de signature reconnus

`RS256` seulement pour l'instant : RSASSA-PKCS1-v1_5 avec SHA-256, qui
est l'algorithme par defaut de Keycloak et d'AgentConnect.

`ES256` n'est pas encore accepte, et ce n'est pas un oubli : JOSE exige
la signature ECDSA au format brut R\|\|S, alors qu'OpenSSL la produit
encodee en DER. Accepter `ES256` sans faire la conversion produirait des
signatures que rien d'autre ne saurait verifier - mieux vaut refuser
franchement.

## Usage

``` r
SOMMIER_ALGOS_JWS
```

## Format

An object of class `character` of length 1.
