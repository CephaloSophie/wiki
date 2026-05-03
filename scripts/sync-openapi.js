import fs from 'fs'
import path from 'path'
import { fileURLToPath } from 'url'

const __filename = fileURLToPath(import.meta.url)
const __dirname  = path.dirname(__filename)

const SRC  = path.join(__dirname, '..', 'openapi', 'epoptes-openapi.json')
const DEST_DIR = path.join(__dirname, '..', 'public', 'openapi')
const DEST = path.join(DEST_DIR, 'epoptes-openapi.json')

if (!fs.existsSync(DEST_DIR)) fs.mkdirSync(DEST_DIR, { recursive: true })
fs.copyFileSync(SRC, DEST)
console.log(`  ✅ openapi/epoptes-openapi.json copié dans public/`)
