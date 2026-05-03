# WebSockets — Notifications temps réel

Le service `notification-service` expose un canal WebSocket pour recevoir les notifications en temps réel.

## Connexion

Le serveur Socket.io tourne sur le port `3008` :

```javascript
import { io } from 'socket.io-client'

const socket = io('http://localhost:3008', {
  auth: {
    token: 'eyJ...' // access_token
  }
})

socket.on('connect', () => {
  console.log('✅ Connecté')
})

socket.on('disconnect', () => {
  console.log('❌ Déconnecté')
})
```

## Événements

### `notification.new`

Émis chaque fois qu'une nouvelle notification est créée :

```javascript
socket.on('notification.new', (payload) => {
  console.log(payload)
})
```

Payload :
```json
{
  "event": "notification.new",
  "data": {
    "_id":         "notif_abc123",
    "type":        "deprecated_bloc",
    "severity":    "warning",
    "title":       "Bloc obsolète détecté",
    "message":     "Le bloc bloc_xyz789 a été remplacé par bloc_abc123.",
    "entity_type": "bloc",
    "entity_id":   "bloc_xyz789",
    "created_at":  "2026-05-01T10:00:00Z"
  }
}
```

## Types de notifications

| Type | Sévérité | Déclencheur |
|---|---|---|
| `deprecated_bloc` | `warning` | Bloc passé en `duplicated`, templates impactés |
| `plan_expiry` | `info` | Plan d'une org expirant bientôt |
| `pending_validation` | `info` | Entité bloquée en `pending` depuis N jours |
| `org_registered` | `info` | Nouvelle organisation inscrite |
| `org_suspended` | `warning` | Organisation suspendue |
| `bug_report` | `error` | Bug signalé par une organisation |
| `editor_disabled` | `warning` | Éditeur désactivé globalement |

## Bonnes pratiques

**Reconnexion automatique** — Socket.io gère ça nativement, mais vérifie que `reconnection: true` (défaut) :

```javascript
const socket = io('http://localhost:3008', {
  reconnection:        true,
  reconnectionDelay:   1000,
  reconnectionAttempts: 10
})
```

**Combinaison REST + WebSocket** — au démarrage, charge l'historique via REST puis écoute les nouveaux événements :

```javascript
// 1. Historique
const { data } = await fetch('/notifications?read=false', {
  headers: { Authorization: `Bearer ${token}` }
}).then(r => r.json())

setNotifications(data)

// 2. Temps réel
socket.on('notification.new', ({ data: notif }) => {
  setNotifications(prev => [notif, ...prev])
})
```

**Marquer comme lue** — toujours via REST, pas via WebSocket :

```javascript
await fetch(`/notifications/${notifId}/read`, {
  method: 'PATCH',
  headers: { Authorization: `Bearer ${token}` }
})
```
