# Gestion des erreurs

Toutes les erreurs Époptès suivent un format unique et prédictible.

## Format de l'erreur

```json
{
  "error":      "VALIDATION_ERROR",
  "message":    "Plan must have at least one enabled editor",
  "statusCode": 422
}
```

| Champ | Type | Description |
|---|---|---|
| `error` | string | Code machine-readable |
| `message` | string | Message lisible par humain |
| `statusCode` | integer | Code HTTP |

## Codes d'erreur HTTP

### 400 — `BAD_REQUEST`

Payload invalide ou champ obligatoire manquant.

```json
{ "error": "BAD_REQUEST", "message": "email and password are required", "statusCode": 400 }
```

### 401 — `UNAUTHORIZED`

Token absent, expiré, invalide ou compte inactif.

```json
{ "error": "UNAUTHORIZED", "message": "Invalid or expired token", "statusCode": 401 }
```

### 403 — `FORBIDDEN`

Action interdite pour le rôle ou l'état actuel.

```json
{ "error": "FORBIDDEN", "message": "Only draft plans can be modified", "statusCode": 403 }
{ "error": "FORBIDDEN", "message": "super_admin role required", "statusCode": 403 }
```

### 404 — `NOT_FOUND`

Ressource introuvable.

```json
{ "error": "NOT_FOUND", "message": "Plan not found", "statusCode": 404 }
```

### 409 — `CONFLICT`

Conflit métier — typiquement une contrainte d'unicité violée.

```json
{ "error": "CONFLICT", "message": "Email already in use", "statusCode": 409 }
```

### 422 — `VALIDATION_ERROR`

Règle métier violée (le payload est valide structurellement mais incohérent métier).

```json
{ "error": "VALIDATION_ERROR", "message": "Plan must have at least one enabled editor", "statusCode": 422 }
{ "error": "VALIDATION_ERROR", "message": "blockly_definition is required before submitting", "statusCode": 422 }
```

### 429 — `TOO_MANY_REQUESTS`

Rate limit dépassé. Le gateway limite à **100 requêtes par minute** par défaut en développement.

### 500 — `INTERNAL_ERROR`

Erreur serveur. À reporter à l'équipe Cephalo Sophie avec le `request_id` du log.

## Pattern de gestion côté client

```javascript
async function apiCall(endpoint, options) {
  const res = await fetch(endpoint, options)

  if (res.status === 401) {
    // Token expiré → tenter un refresh ou rediriger vers login
    await refreshToken()
    return apiCall(endpoint, options)
  }

  if (!res.ok) {
    const err = await res.json()
    throw new ApiError(err.error, err.message, err.statusCode)
  }

  return res.json()
}

class ApiError extends Error {
  constructor(code, message, statusCode) {
    super(message)
    this.code = code
    this.statusCode = statusCode
  }
}
```

## Erreurs spécifiques au cycle de vie

| Action | Erreur typique |
|---|---|
| `PUT /plans/{id}` sur un plan non-`draft` | 403 — Only draft plans can be modified |
| `PATCH /plans/{id}/submit` sans éditeur activé | 422 — Plan must have at least one enabled editor |
| `PATCH /plans/{id}/validate` sur un plan non-`pending` | 403 — Transition not allowed |
| `PATCH /blocs/{id}/submit` sans `blockly_definition` | 422 — blockly_definition is required |
| `PATCH /orgs/{id}/suspend` sur une org non-`active` | 403 — Only active organisations can be suspended |
| `PATCH /orgs/{id}/close` sans `confirm: true` | 403 — Closing an organisation requires explicit confirm |
