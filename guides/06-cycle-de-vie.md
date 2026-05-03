# Cycle de vie des entités

Toutes les entités Époptès suivent un cycle de vie strict avec des transitions contrôlées.

## Principe d'immuabilité

Une fois publiée (`ready`), une entité **ne peut plus être modifiée**. Pour faire évoluer une entité publiée :

- Pour les **plans** : créer un nouveau plan (clone)
- Pour les **blocs et templates** : dupliquer pour créer une nouvelle version

## Plans

```
DRAFT → PENDING → READY → FINISHED
```

| Statut | Éditable | Visible | Souscriptible | Qui peut agir |
|---|---|---|---|---|
| `draft` | ✅ | ❌ | ❌ | admin |
| `pending` | ❌ | ❌ | ❌ | admin (soumet) |
| `ready` | ❌ | ✅ | ✅ | super_admin (valide) |
| `finished` | ❌ | ✅ existants | ❌ | super_admin (archive) |

**Transitions :**
- `draft → pending` : `PATCH /plans/{id}/submit` (admin)
- `pending → ready` : `PATCH /plans/{id}/validate` (super_admin)
- `pending → draft` : `PATCH /plans/{id}/reject` avec `reason` (super_admin)
- `ready → finished` : `PATCH /plans/{id}/finish` (super_admin)

**Snapshot** : à chaque souscription d'une organisation, un **snapshot immuable** du plan est créé. Même si le plan passe `finished`, le snapshot reste intact pour la durée de la souscription.

## Blocs et Templates

```
DRAFT → PENDING → READY → DUPLICATED
```

| Statut | Éditable | Utilisable | Qui peut agir |
|---|---|---|---|
| `draft` | ✅ | ❌ | admin |
| `pending` | ❌ | ❌ | admin (soumet) |
| `ready` | ❌ | ✅ | super_admin (valide) |
| `duplicated` | ❌ | ⚠️ legacy uniquement | système |

**Règle de duplication** : un bloc `ready` ne se supprime jamais. Si une nouvelle version est publiée :

1. La nouvelle version est créée en `draft` via `POST /blocs/{id}/duplicate`
2. Elle suit le cycle normal : `draft → pending → ready`
3. **Au moment où la nouvelle version passe `ready`**, l'ancienne passe automatiquement `duplicated`
4. Les références existantes vers l'ancienne version continuent de fonctionner

**Traçabilité de lignée** :
```json
// Nouvelle version (ready)
{
  "_id":             "bloc_v2",
  "status":          "ready",
  "duplicated_from": "bloc_v1"
}

// Ancienne version (duplicated)
{
  "_id":         "bloc_v1",
  "status":      "duplicated",
  "replaced_by": "bloc_v2"
}
```

Récupère toute la lignée :
```
GET /blocs/{id}/lineage
```

## Organisations

```
PENDING → ACTIVE → SUSPENDED → CLOSED
```

| Statut | Signification |
|---|---|
| `pending` | Inscription reçue, en attente de validation |
| `active` | Accès complet à la plateforme |
| `suspended` | Accès bloqué temporairement (impayé, violation) |
| `closed` | Fin de vie, données archivées |
| `rejected` | Inscription refusée (terminal) |

**Transitions** :
- `pending → active` : `PATCH /orgs/{id}/validate` (super_admin)
- `pending → rejected` : `PATCH /orgs/{id}/reject` avec `reason` (super_admin)
- `active → suspended` : `PATCH /orgs/{id}/suspend` avec `reason` (super_admin)
- `suspended → active` : `PATCH /orgs/{id}/reactivate` (super_admin)
- `* → closed` : `PATCH /orgs/{id}/close` avec `confirm: true` (super_admin)

⚠️ **Fermer une organisation est irréversible** — le `confirm: true` est obligatoire dans le payload.

## Workflow type — Création complète d'un plan

```javascript
// 1. Admin crée le plan en draft
const plan = await POST('/plans', { name: 'Pro', editors: {...} })
// → { _id: 'plan_abc', status: 'draft' }

// 2. Admin modifie le plan pendant qu'il est en draft
await PUT(`/plans/${plan._id}`, { description: 'Plan pro pour équipes' })

// 3. Admin soumet pour validation
await PATCH(`/plans/${plan._id}/submit`)
// → status: 'pending'

// 4. Super_admin valide (ou rejette)
await PATCH(`/plans/${plan._id}/validate`)
// → status: 'ready' — visible et souscriptible

// 5. Plus tard, super_admin archive
await PATCH(`/plans/${plan._id}/finish`)
// → status: 'finished' — orgs existantes en grandfathering
```

## Workflow type — Duplication d'un bloc

```javascript
// Bloc existant en ready
// { _id: 'bloc_v1', status: 'ready', version: 1 }

// 1. Admin duplique le bloc
const v2 = await POST('/blocs/bloc_v1/duplicate', { name: 'Form Contact V2' })
// → { _id: 'bloc_v2', status: 'draft', version: 2, duplicated_from: 'bloc_v1' }

// 2. Cycle classique
await PATCH('/blocs/bloc_v2/submit')
await PATCH('/blocs/bloc_v2/validate')

// 3. Automatiquement, bloc_v1 passe duplicated
// { _id: 'bloc_v1', status: 'duplicated', replaced_by: 'bloc_v2' }
// { _id: 'bloc_v2', status: 'ready', duplicated_from: 'bloc_v1' }
```
