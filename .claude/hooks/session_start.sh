#!/bin/bash
# Hook SessionStart: al empezar cada sesión de Claude Code trae el estado más
# nuevo para no trabajar sobre contexto viejo (fue la causa del incidente de
# reservas del 2026-07-01: el repo había divergido del esquema real de prod).
#
# Hace, de forma NO destructiva:
#   1. git fetch del repo cliente + reporta si estás atrasado/adelantado.
#   2. git fetch del repo Admin (carpeta hermana) + reporta.
#   3. regenera docs/db_schema.md (esquema vivo de prod).
# Todo best-effort: si no hay red o token, no rompe la sesión.
#
# La salida (stdout) se inyecta como contexto de la sesión.

CLIENT_DIR="${CLAUDE_PROJECT_DIR:-/Users/thiagoghianni/Kali-Studio-Client}"
ADMIN_DIR="$(cd "$CLIENT_DIR/.." 2>/dev/null && pwd)/Kali-Studio-Admin"

# git fetch acotado en tiempo (macOS no trae `timeout`; usamos background+kill).
# disown evita que bash imprima "Terminated" al matar el watchdog.
timed() {
  "$@" & local pid=$!
  ( sleep 20; kill "$pid" 2>/dev/null ) & local watcher=$!
  disown "$watcher" 2>/dev/null
  wait "$pid" 2>/dev/null; local rc=$?
  kill "$watcher" 2>/dev/null
  return $rc
}

report_git() {
  local dir="$1" label="$2"
  [ -d "$dir/.git" ] || { echo "- $label: (no clonado en $dir)"; return; }
  timed git -C "$dir" fetch --quiet 2>/dev/null
  local branch behind ahead dirty
  branch=$(git -C "$dir" rev-parse --abbrev-ref HEAD 2>/dev/null)
  local counts; counts=$(git -C "$dir" rev-list --left-right --count "HEAD...@{upstream}" 2>/dev/null)
  ahead=$(echo "$counts" | awk '{print $1}'); behind=$(echo "$counts" | awk '{print $2}')
  dirty=$(git -C "$dir" status --porcelain 2>/dev/null | wc -l | tr -d ' ')
  local msg="- $label ($branch)"
  [ "${behind:-0}" -gt 0 ] 2>/dev/null && msg="$msg — ⬇️ $behind commits nuevos en remoto (hacé git pull)"
  [ "${ahead:-0}" -gt 0 ] 2>/dev/null && msg="$msg — ⬆️ $ahead sin pushear"
  [ "${behind:-0}" = 0 ] && [ "${ahead:-0}" = 0 ] && msg="$msg — al día"
  [ "${dirty:-0}" -gt 0 ] 2>/dev/null && msg="$msg — $dirty archivos con cambios locales"
  echo "$msg"
}

echo "## Estado del proyecto (hook SessionStart)"
echo
echo "### Repos"
report_git "$CLIENT_DIR" "Cliente (kali_studio)"
report_git "$ADMIN_DIR" "Admin (argrity)"
echo

echo "### Base de datos (prod)"
if [ -x "$CLIENT_DIR/scripts/dump_db_schema.sh" ]; then
  out=$(timed "$CLIENT_DIR/scripts/dump_db_schema.sh" 2>&1)
  echo "- $(echo "$out" | tail -1)"
else
  echo "- (falta scripts/dump_db_schema.sh)"
fi
echo "- Esquema REAL de prod en \`docs/db_schema.md\` — es la fuente de verdad por"
echo "  encima de \`supabase/migrations/\` (historial divergente). Verificá columnas ahí"
echo "  antes de escribir RPCs/inserts."
