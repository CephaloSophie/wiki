# Quickstart — Premiers appels en 5 minutes

Ce guide te fait passer de zéro à ton premier appel API authentifié réussi.

## Prérequis

- Époptès tourne en local (gateway sur `http://localhost:3000`)
- Le seed a été exécuté (`npm run seed:base`)
- Un client HTTP : `curl`, Postman, ou ton terminal

## Étape 1 — Vérifier que tout tourne

```bash
curl http://localhost:3000/health
```

Réponse attendue :
```json
{ "status": "ok", "service": "api-gateway" }
```

Si tu ne reçois rien : le gateway n'est pas démarré. Lance `npm run dev` à la racine du projet.

## Étape 2 — Se connecter

```bash
curl -X POST http://localhost:3000/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email":    "superadmin@cephalosophie.com",
    "password": "SuperAdmin2026!"
  }'
```

Réponse :
```json
{
  "access_token":  "eyJhbGciOi...",
  "refresh_token": "eyJhbGciOi...",
  "expires_in":    3600,
  "user": {
    "id":    "user_abc123",
    "email": "superadmin@cephalosophie.com",
    "role":  "super_admin"
  }
}
```

Sauvegarde l'`access_token` dans une variable :

```bash
TOKEN=$(curl -s -X POST http://localhost:3000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"superadmin@cephalosophie.com","password":"SuperAdmin2026!"}' \
  | jq -r '.access_token')
```

## Étape 3 — Récupérer ton profil

```bash
curl http://localhost:3000/auth/me \
  -H "Authorization: Bearer $TOKEN"
```

## Étape 4 — Lister les plans existants

```bash
curl http://localhost:3000/plans \
  -H "Authorization: Bearer $TOKEN"
```

## Étape 5 — Créer ton premier plan

```bash
curl -X POST http://localhost:3000/plans \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name":        "Mon Premier Plan",
    "description": "Plan de test",
    "editors": {
      "tekton": {
        "enabled": true,
        "quotas": {
          "max_pages": { "limit": 50, "period": "monthly", "on_exceed": "hard_block" }
        }
      },
      "mantis": {
        "enabled": true,
        "quotas": {
          "max_requests": { "limit": 100000, "period": "monthly", "on_exceed": "overage" }
        }
      }
    }
  }'
```

Réponse :
```json
{
  "_id":        "plan_xyz789",
  "name":       "Mon Premier Plan",
  "status":     "draft",
  "created_by": "user_abc123",
  "created_at": "2026-05-01T10:00:00Z"
}
```

## Étape 6 — Cycle de vie complet

```bash
PLAN_ID="plan_xyz789"  # ID retourné à l'étape 5

# Soumettre
curl -X PATCH http://localhost:3000/plans/$PLAN_ID/submit \
  -H "Authorization: Bearer $TOKEN"
# → status: "pending"

# Valider (super_admin)
curl -X PATCH http://localhost:3000/plans/$PLAN_ID/validate \
  -H "Authorization: Bearer $TOKEN"
# → status: "ready"
```

## Et après ?

- [Authentification détaillée](./02-authentication.md)
- [Cycle de vie complet](./06-cycle-de-vie.md)
- [Gestion des erreurs](./04-errors.md)
- Explore l'API interactive ci-dessus avec le bouton "Try it out"

## Exemple complet en JavaScript

```javascript
const API = 'http://localhost:3000'

async function main() {
  // 1. Login
  const login = await fetch(`${API}/auth/login`, {
    method:  'POST',
    headers: { 'Content-Type': 'application/json' },
    body:    JSON.stringify({
      email:    'superadmin@cephalosophie.com',
      password: 'SuperAdmin2026!'
    })
  }).then(r => r.json())

  const token = login.access_token
  const headers = {
    'Authorization': `Bearer ${token}`,
    'Content-Type':  'application/json'
  }

  // 2. Créer un plan
  const plan = await fetch(`${API}/plans`, {
    method:  'POST',
    headers,
    body:    JSON.stringify({
      name: 'Plan via JS',
      editors: { tekton: { enabled: true, quotas: {} } }
    })
  }).then(r => r.json())

  console.log('Plan créé :', plan._id)

  // 3. Soumettre puis valider
  await fetch(`${API}/plans/${plan._id}/submit`,   { method: 'PATCH', headers })
  await fetch(`${API}/plans/${plan._id}/validate`, { method: 'PATCH', headers })

  // 4. Lister les plans ready
  const list = await fetch(`${API}/plans?status=ready`, { headers }).then(r => r.json())
  console.log('Plans ready :', list.total)
}

main().catch(console.error)
```
