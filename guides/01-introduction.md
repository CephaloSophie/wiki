# Introduction à Époptès

> *Du grec ancien — celui qui voit tout. Ni dans la mêlée, ni aveugle.*

## Qu'est-ce qu'Époptès ?

Époptès (ἘΠΌΠΤΗΣ) est le **back-office de pilotage** de la plateforme **KANTO APLO**, conçu et opéré par **Cephalo Sophie**.

Il est strictement séparé de KANTO APLO :

| Dimension | Époptès | KANTO APLO (côté client) |
|---|---|---|
| Utilisateurs | Équipe Cephalo Sophie | Organisations clientes (Scripteurs) |
| Rôle | Superviser, valider, configurer | Créer, déployer, analyser |
| Accès aux données | Vue macro, jamais le contenu métier | Contenu propre uniquement |

## Périmètre fonctionnel

Époptès gère :

- La création et publication des **plans tarifaires**
- La forge et publication des **blocs Blockly** (via Héphaïstos)
- La forge et publication des **templates structurels** (via Typοs)
- La supervision des **organisations clientes**
- La validation des inscriptions
- La configuration globale de la plateforme

Époptès **ne gère jamais** :

- Le contenu créé par les organisations (pages, APIs, surveys, données)
- Les données personnelles des membres au-delà du nécessaire
- Les opérations internes aux organisations

## Architecture en bref

8 microservices Node.js indépendants, chacun avec sa propre base MongoDB :

```
┌──────────────────────────────────────────────────────────┐
│                     API Gateway                           │
│                  (Fastify, port 3000)                     │
└────────────────────────┬─────────────────────────────────┘
                         │
   ┌─────────┬───────────┼───────────┬─────────┬─────────┐
   ▼         ▼           ▼           ▼         ▼         ▼
  Auth     Plan        Bloc      Template    Org    Settings
  3001     3002        3003        3004      3005    3006
                                                ▼         ▼
                                            Support  Notification
                                              3007       3008
```

Tous les appels passent par le **Gateway**. Aucun service interne n'est accessible directement de l'extérieur.

## Conventions

**Identifiants** — strings préfixés par type :
- `user_abc123`, `plan_def456`, `bloc_xyz789`, `tpl_qrs012`, `org_mno345`

**Dates** — format ISO 8601 :
- `2026-05-01T10:00:00Z`

**Pagination** — uniforme sur toutes les listes :
```
GET /plans?page=1&limit=20
```

Réponse :
```json
{
  "data":  [...],
  "total": 84,
  "page":  1,
  "limit": 20
}
```

**Erreurs** — structure cohérente :
```json
{
  "error":      "VALIDATION_ERROR",
  "message":    "Plan must have at least one enabled editor",
  "statusCode": 422
}
```

## Pour commencer

- [Démarrer en 5 minutes](./07-quickstart.md) — premiers appels concrets
- [Authentification](./02-authentication.md) — comment obtenir et utiliser un token
- [Cycle de vie des entités](./06-cycle-de-vie.md) — comprendre les statuts
