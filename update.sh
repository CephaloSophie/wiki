#!/bin/bash
# ──────────────────────────────────────────────────────────────────
# Époptès Docs — Mise à jour rapide
# ──────────────────────────────────────────────────────────────────
# À utiliser quand tu veux republier après modif :
# 1. Upload le nouveau .zip sur le VPS
# 2. Lance : bash update.sh

set -e

INSTALL_DIR="/var/www/epoptes-docs"
ZIP_FILE="${1:-epoptes-docs.zip}"

if [ ! -f "$ZIP_FILE" ]; then
  echo "❌ Fichier $ZIP_FILE introuvable"
  echo "   Usage : bash update.sh [chemin-vers-zip]"
  exit 1
fi

echo "▶ Backup de l'ancienne version..."
sudo mv "$INSTALL_DIR" "$INSTALL_DIR.backup.$(date +%s)" 2>/dev/null || true

echo "▶ Décompression de la nouvelle version..."
sudo mkdir -p "$INSTALL_DIR"
sudo chown -R $USER:$USER "$INSTALL_DIR"

unzip -q "$ZIP_FILE" -d /tmp/epoptes-update/
mv /tmp/epoptes-update/epoptes-docs/* "$INSTALL_DIR/"
mv /tmp/epoptes-update/epoptes-docs/.[!.]* "$INSTALL_DIR/" 2>/dev/null || true
rm -rf /tmp/epoptes-update

cd "$INSTALL_DIR"
npm install --silent
npm run build

sudo chown -R www-data:www-data "$INSTALL_DIR/public"
sudo systemctl reload nginx

echo ""
echo "✅ Mise à jour déployée"
echo "   https://docs.kantoaplo.com"
