#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# upgrade.sh — Actualiza una instalación del plugin en <target> aplicando
# las migraciones necesarias entre la versión instalada y la versión actual
# del plugin (VERSION en la raíz).
#
# Uso:  upgrade.sh <target> [--dry-run]
# ═══════════════════════════════════════════════════════════════════════════════

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

DRY_RUN=0
TARGET=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=1; shift ;;
    -h|--help) sed -n '2,11p' "$0"; exit 0 ;;
    *) TARGET="$1"; shift ;;
  esac
done

[[ -n "$TARGET" ]] || { echo "Uso: upgrade.sh <target> [--dry-run]" >&2; exit 2; }
TARGET="$(cd "$TARGET" && pwd)"
[[ -d "$TARGET/.claude" ]] || { echo "❌ $TARGET no es un target válido (falta .claude/)" >&2; exit 2; }

PLUGIN_VERSION="$(cat "$PLUGIN_ROOT/VERSION")"
INSTALLED_FILE="$TARGET/.claude/.plugin-version"
INSTALLED_VERSION="$(cat "$INSTALLED_FILE" 2>/dev/null || echo "0.1.0")"

echo "Plugin version:    $PLUGIN_VERSION"
echo "Installed version: $INSTALLED_VERSION"

if [[ "$INSTALLED_VERSION" == "$PLUGIN_VERSION" ]]; then
  echo "✅ Ya está al día."
  exit 0
fi

# semver-aware sort: lista versiones de migrations/ > instalada, <= plugin
mapfile -t pending < <(
  ls "$PLUGIN_ROOT/migrations" 2>/dev/null \
    | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' \
    | sed 's/^v//' \
    | awk -v inst="$INSTALLED_VERSION" -v cur="$PLUGIN_VERSION" '
        function vlt(a,b,  na,nb,i){ split(a,na,"."); split(b,nb,"."); for(i=1;i<=3;i++){if(na[i]+0<nb[i]+0)return 1; if(na[i]+0>nb[i]+0)return 0} return 0 }
        { if (vlt(inst,$0) && (vlt($0,cur) || $0==cur)) print $0 }
      ' \
    | sort -V
)

if [[ ${#pending[@]} -eq 0 ]]; then
  echo "⚠️  No hay migraciones aplicables (¿plugin más antiguo que target?)."
  exit 1
fi

echo "Migraciones a aplicar: ${pending[*]}"

for v in "${pending[@]}"; do
  script="$PLUGIN_ROOT/migrations/v$v/upgrade.sh"
  if [[ ! -x "$script" ]]; then
    echo "❌ Falta o no es ejecutable: $script" >&2
    exit 1
  fi
  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "[dry-run] aplicaría v$v"
  else
    echo "▶ Aplicando v$v"
    "$script" "$TARGET"
    echo "$v" > "$INSTALLED_FILE"
  fi
done

[[ "$DRY_RUN" -eq 1 ]] || echo "$PLUGIN_VERSION" > "$INSTALLED_FILE"
echo "✅ Upgrade a $PLUGIN_VERSION completado."
