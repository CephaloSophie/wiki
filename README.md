# Époptès — Documentation

Site de documentation statique pour l'API Époptès.

## Stack

- **OpenAPI 3.1** — spec complète de l'API (73 endpoints, 30 schemas)
- **Scalar** — affichage interactif moderne avec "Try it out"
- **Marked** — conversion des guides Markdown en HTML
- **HTML/CSS pur** — landing page custom aux couleurs KANTO APLO

## Structure

```
epoptes-docs/
├── openapi/
│   └── epoptes-openapi.json     ← Source de vérité OpenAPI 3.1
├── guides/                       ← Guides narratifs (Markdown source)
│   ├── 01-introduction.md
│   ├── 02-authentication.md
│   ├── 03-pagination.md
│   ├── 04-errors.md
│   ├── 05-rate-limits.md
│   ├── 06-cycle-de-vie.md
│   ├── 07-quickstart.md
│   └── 08-websockets.md
├── public/                       ← Site statique généré (à déployer)
│   ├── index.html                ← Landing page
│   ├── api.html                  ← Scalar API Reference
│   ├── guides/                   ← Guides en HTML
│   └── openapi/
│       └── epoptes-openapi.json
└── scripts/
    ├── build-guides.js           ← MD → HTML
    └── sync-openapi.js           ← Copie l'OpenAPI dans public/
```

## Commandes

```bash
# Installer les dépendances
npm install

# Build complet
npm run build

# Servir en local (http://localhost:8080)
npm run serve

# Dev — build + serve
npm run dev
```

## Déploiement

Le dossier `public/` est un site statique pur — déployable n'importe où :

### Netlify / Vercel

```bash
# Build command
npm run build

# Publish directory
public
```

### S3 / CloudFront

```bash
aws s3 sync public/ s3://docs.kantoaplo.com/ --delete
aws cloudfront create-invalidation --distribution-id XXX --paths "/*"
```

### nginx

```nginx
server {
  listen 443 ssl;
  server_name docs.kantoaplo.com;

  root /var/www/epoptes-docs/public;
  index index.html;

  location / {
    try_files $uri $uri/ $uri.html =404;
  }
}
```

### GitHub Pages

```yaml
# .github/workflows/deploy.yml
- name: Build
  run: npm install && npm run build
- name: Deploy
  uses: peaceiris/actions-gh-pages@v3
  with:
    publish_dir: ./public
```

## Mise à jour de la doc

### Modifier les endpoints

1. Éditer `openapi/epoptes-openapi.json`
2. `npm run build`
3. Déployer

### Modifier un guide

1. Éditer `guides/XX-nom-guide.md`
2. `npm run build`
3. Déployer

### Ajouter un guide

1. Créer `guides/09-nouveau-guide.md` (commence par `# Titre`)
2. `npm run build`
3. Le guide apparaîtra automatiquement dans la nav

## Personnalisation

### Couleurs

Définies dans `public/index.html` et `scripts/build-guides.js` :

```css
--gold:   #C9963A;  /* Cephalo Sophie */
--green:  #2DD4A0;  /* Synergos */
--purple: #8B5CF6;  /* Mantis */
```

### Theme Scalar

Édité dans `public/api.html` :

```html
data-configuration='{"theme": "purple", "darkMode": true}'
```

Themes disponibles : `default`, `purple`, `bluePlanet`, `saturn`, `kepler`, `mars`, `deepSpace`, `none`.

---

**Cephalo Sophie** · KANTO APLO · 2026
