#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# validate.sh — Verifica que un proyecto ya inicializado no tiene placeholders
# sin sustituir y que las rutas referenciadas existen.
#
# Uso: validate.sh <target-dir>
# ═══════════════════════════════════════════════════════════════════════════════

set -euo pipefail

TARGET="${1:?Uso: validate.sh <target-dir>}"
TARGET="$(cd "$TARGET" && pwd)"

errors=0

echo "🔍 Validando $TARGET"

# 1. Placeholders sin sustituir
echo "→ Buscando placeholders {{...}}..."
if grep -rE '\{\{[A-Z_]+\}\}' "$TARGET/.claude" "$TARGET/CLAUDE.md" 2>/dev/null; then
  echo "❌ Hay placeholders sin sustituir."
  errors=$((errors + 1))
else
  echo "  ok"
fi

# 2. Archivos obligatorios
echo "→ Comprobando archivos obligatorios..."
required=(
  ".claude/settings.json"
  ".claude/skill-rules.json"
  ".claude/repos.list"
  ".claude/hooks/pre-activate.sh"
  ".claude/hooks/post-activate.sh"
  ".claude/hooks/on-success.sh"
  ".claude/hooks/on-user-prompt.sh"
  ".claude/hooks/on-session-end.sh"
  ".claude/skills/knowledge-agent/SKILL.md"
  ".claude/skills/knowledge-agent/references/domain.md"
  ".claude/skills/planner/SKILL.md"
  ".claude/skills/planner/references/issue-tracker.md"
  "CLAUDE.md"
)
for f in "${required[@]}"; do
  if [[ ! -f "$TARGET/$f" ]]; then
    echo "❌ Falta: $f"
    errors=$((errors + 1))
  fi
done
[[ $errors -eq 0 ]] && echo "  ok"

# 3. Hooks ejecutables
echo "→ Comprobando permisos de ejecución de hooks..."
for h in "$TARGET/.claude/hooks/"*.sh; do
  if [[ ! -x "$h" ]]; then
    echo "❌ No ejecutable: $h"
    errors=$((errors + 1))
  fi
done
[[ $errors -eq 0 ]] && echo "  ok"

# 4. Tracker activo coherente
echo "→ Comprobando tracker activo..."
tracker_file=$(grep -oE 'trackers/[a-z]+\.md' "$TARGET/.claude/skills/planner/SKILL.md" | head -1 || true)
if [[ -z "$tracker_file" ]]; then
  echo "❌ No se detecta tracker activo en planner/SKILL.md"
  errors=$((errors + 1))
elif [[ ! -f "$TARGET/.claude/skills/planner/references/$tracker_file" ]]; then
  echo "❌ Tracker referenciado no existe: $tracker_file"
  errors=$((errors + 1))
else
  echo "  ok ($tracker_file)"
fi

# 5. JSON válidos
echo "→ Validando JSON..."
for j in "$TARGET/.claude/settings.json" "$TARGET/.claude/skill-rules.json"; do
  if ! jq empty "$j" 2>/dev/null; then
    echo "❌ JSON inválido: $j"
    errors=$((errors + 1))
  fi
done
[[ $errors -eq 0 ]] && echo "  ok"

echo
if [[ $errors -eq 0 ]]; then
  echo "✅ Validación OK"
  exit 0
else
  echo "❌ Validación fallida con $errors error(es)"
  exit 1
fi
