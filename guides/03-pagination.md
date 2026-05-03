# Pagination

Tous les endpoints retournant une liste supportent la pagination.

## Paramètres

| Paramètre | Type | Défaut | Min | Max |
|---|---|---|---|---|
| `page` | integer | 1 | 1 | — |
| `limit` | integer | 20 | 1 | 100 |

## Format de réponse

```json
{
  "data":  [ /* tableau d'items */ ],
  "total": 84,
  "page":  1,
  "limit": 20
}
```

## Exemples

```bash
# Page 1, 20 items par défaut
GET /plans

# Page 2, 50 items
GET /plans?page=2&limit=50

# Combiné avec des filtres
GET /blocs?status=ready&editor_target=tekton&page=1&limit=10
```

## Calcul du nombre de pages

```javascript
const totalPages = Math.ceil(response.total / response.limit)
```

## Pattern d'itération côté client

```javascript
async function fetchAll(endpoint, token) {
  const all = []
  let page = 1
  while (true) {
    const res = await fetch(`${endpoint}?page=${page}&limit=100`, {
      headers: { Authorization: `Bearer ${token}` }
    })
    const { data, total, limit } = await res.json()
    all.push(...data)
    if (page * limit >= total) break
    page++
  }
  return all
}
```
