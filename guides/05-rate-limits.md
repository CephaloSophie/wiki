# Rate Limiting

Le gateway Époptès applique un rate limit pour protéger les services internes contre la surcharge.

## Limites par défaut

| Environnement | Limite | Fenêtre |
|---|---|---|
| Development | 1000 requêtes | 60 secondes |
| Production | 100 requêtes | 60 secondes |

Ces limites sont appliquées **par IP cliente**.

## Headers de rate limit

Chaque réponse inclut des headers indiquant l'état actuel :

```
X-RateLimit-Limit:     100
X-RateLimit-Remaining: 87
X-RateLimit-Reset:     1746003600
```

| Header | Description |
|---|---|
| `X-RateLimit-Limit` | Limite totale dans la fenêtre |
| `X-RateLimit-Remaining` | Requêtes restantes |
| `X-RateLimit-Reset` | Timestamp Unix du reset |

## Comportement quand la limite est atteinte

```http
HTTP/1.1 429 Too Many Requests
Retry-After: 42

{
  "error":      "TOO_MANY_REQUESTS",
  "message":    "Rate limit exceeded",
  "statusCode": 429
}
```

Le header `Retry-After` indique le nombre de secondes avant de pouvoir réessayer.

## Pattern de retry côté client

```javascript
async function fetchWithRetry(url, options, maxRetries = 3) {
  for (let i = 0; i < maxRetries; i++) {
    const res = await fetch(url, options)
    if (res.status !== 429) return res

    const retryAfter = parseInt(res.headers.get('Retry-After') || '1') * 1000
    await new Promise(r => setTimeout(r, retryAfter))
  }
  throw new Error('Rate limit retry exhausted')
}
```

## Bonnes pratiques

- **Cache** les réponses peu volatiles (`/plans`, `/blocs/catalog`)
- **Pagine** correctement au lieu de demander de gros volumes en une fois
- **Évite les polling agressifs** — utilise les WebSocket pour les notifications temps réel
- **Batch** les opérations quand possible
