# Authentification

Toutes les requêtes Époptès (sauf `/auth/login`, `/auth/refresh`, `/health`) requièrent un **JWT** dans le header `Authorization`.

## Vue d'ensemble du flux

```
1. Client → POST /auth/login → reçoit access_token + refresh_token
2. Client → toute requête avec Authorization: Bearer {access_token}
3. Gateway → valide le token via auth-service
4. Gateway → injecte les headers internes vers le service cible
5. Service → exécute la requête, retourne la réponse
```

## Login

```http
POST /auth/login
Content-Type: application/json

{
  "email":    "superadmin@cephalosophie.com",
  "password": "VotreMotDePasseSecret"
}
```

**Réponse 200 :**
```json
{
  "access_token":  "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "expires_in":    3600,
  "user": {
    "id":    "user_abc123",
    "email": "superadmin@cephalosophie.com",
    "role":  "super_admin"
  }
}
```

L'`access_token` est valide pendant **3600 secondes (1 heure)**.
Le `refresh_token` est valide pendant **7 jours**.

## Utilisation du token

Toutes les requêtes suivantes doivent inclure le token :

```http
GET /plans
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

## Renouveler un token expiré

Quand l'`access_token` expire, utilise le `refresh_token` :

```http
POST /auth/refresh
Content-Type: application/json

{ "refresh_token": "eyJ..." }
```

**Réponse 200 :**
```json
{
  "access_token": "eyJ...",
  "expires_in":   3600
}
```

## Codes d'erreur d'authentification

| Code | Cause |
|---|---|
| `401 UNAUTHORIZED` | Token absent, expiré ou invalide |
| `401 UNAUTHORIZED` | Compte avec statut `invited` (non activé) ou `disabled` |
| `403 FORBIDDEN` | Token valide mais rôle insuffisant pour l'opération |

## Exemple JavaScript / Fetch

```javascript
// 1. Login
const loginRes = await fetch('http://localhost:3000/auth/login', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    email:    'superadmin@cephalosophie.com',
    password: 'VotreMotDePasse'
  })
})
const { access_token } = await loginRes.json()

// 2. Appel authentifié
const plansRes = await fetch('http://localhost:3000/plans', {
  headers: { 'Authorization': `Bearer ${access_token}` }
})
const plans = await plansRes.json()
```

## Exemple cURL

```bash
# Login
TOKEN=$(curl -s -X POST http://localhost:3000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"superadmin@cephalosophie.com","password":"x"}' \
  | jq -r '.access_token')

# Appel authentifié
curl http://localhost:3000/plans \
  -H "Authorization: Bearer $TOKEN"
```

## Rôles

| Rôle | Périmètre |
|---|---|
| `super_admin` | Valide, publie, archive, supervise |
| `admin` | Crée, édite, soumet pour validation |

**Règle fondamentale** : l'admin crée. Le super_admin publie. Personne ne s'auto-valide.
