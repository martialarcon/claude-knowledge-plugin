#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# doctor.sh — Health-check del plugin (sobre su propio repo fuente).
#
# Uso:
#   doctor.sh                # texto humano (sobre el repo del plugin)
#   doctor.sh --json         # salida estructurada
#   doctor.sh --fix          # repara lo trivial (permisos hooks)
#
# Verifica:
#   - .claude-plugin/plugin.json existe y es JSON válido con campos clave
#   - hooks/hooks.json existe y es JSON válido
#   - Todos los scripts en hooks/ son ejecutables
#   - skills/{knowledge-agent,planner,setup}/SKILL.md presentes
#   - Sin placeholders {{...}} residuales
#   - Tracker referenciado existe en planner/references/trackers/
# ═══════════════════════════════════════════════════════════════════════════════

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

JSON=0
FIX=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --json) JSON=1; shift ;;
    --fix)  FIX=1; shift ;;
    -h|--help) sed -n '2,16p' "$0"; exit 0 ;;
    *) echo "Flag desconocido: $1" >&2; exit 2 ;;
  esac
done

checks=()
fixes=()
record() { checks+=("$1|$2|$3"); }

# ─── 1. manifest ──────────────────────────────────────────────────────────────
MANIFEST="$PLUGIN_ROOT/.claude-plugin/plugin.json"
if [[ ! -f "$MANIFEST" ]]; then
  record fail manifest "falta .claude-plugin/plugin.json"
elif ! jq empty "$MANIFEST" >/dev/null 2>&1; then
  record fail manifest "JSON inválido en plugin.json"
else
  for k in name version description; do
    jq -e --arg k "$k" '.[$k]' "$MANIFEST" >/dev/null 2>&1 \
      && record ok manifest "campo $k presente" \
      || record fail manifest "campo $k ausente"
  done
fi

# ─── 2. hooks.json ────────────────────────────────────────────────────────────
HOOKS_JSON="$PLUGIN_ROOT/hooks/hooks.json"
if [[ ! -f "$HOOKS_JSON" ]]; then
  record fail hooks "falta hooks/hooks.json"
elif ! jq empty "$HOOKS_JSON" >/dev/null 2>&1; then
  record fail hooks "JSON inválido en hooks/hooks.json"
else
  record ok hooks "hooks/hooks.json válido"
fi

# ─── 3. hooks ejecutables ─────────────────────────────────────────────────────
non_exec=()
shopt -s nullglob
for h in "$PLUGIN_ROOT/hooks/"*.sh; do
  [[ -x "$h" ]] || non_exec+=("$h")
done
shopt -u nullglob
if [[ ${#non_exec[@]} -eq 0 ]]; then
  record ok hooks_exec "todos los hooks ejecutables"
else
  for h in "${non_exec[@]}"; do record fail hooks_exec "no ejecutable: ${h#$PLUGIN_ROOT/}"; done
  if [[ $FIX -eq 1 ]]; then
    chmod +x "${non_exec[@]}"
    fixes+=("chmod +x ${#non_exec[@]} hook(s)")
  fi
fi

# ─── 4. skills obligatorias ───────────────────────────────────────────────────
required_skills=(
  "skills/knowledge-agent/SKILL.md"
  "skills/knowledge-agent/references/domain.md"
  "skills/knowledge-agent/references/principles.md"
  "skills/knowledge-agent/references/handoff-format.md"
  "skills/planner/SKILL.md"
  "skills/planner/references/issue-tracker.md"
  "skills/setup/SKILL.md"
  "skills/RESOLVER.md"
)
miss=0
for f in "${required_skills[@]}"; do
  [[ -f "$PLUGIN_ROOT/$f" ]] || { record fail skills "falta $f"; miss=$((miss+1)); }
done
[[ $miss -eq 0 ]] && record ok skills "todas las skills presentes"

# ─── 5. placeholders ──────────────────────────────────────────────────────────
if grep -rE '\{\{[A-Z_]+\}\}' "$PLUGIN_ROOT/skills" "$PLUGIN_ROOT/hooks" >/dev/null 2>&1; then
  record fail placeholders "quedan placeholders {{...}} en skills/ o hooks/"
else
  record ok placeholders "sin placeholders residuales"
fi

# ─── 6. trackers ──────────────────────────────────────────────────────────────
trackers_dir="$PLUGIN_ROOT/skills/planner/references/trackers"
if [[ -d "$trackers_dir" ]]; then
  for t in jira linear github; do
    [[ -f "$trackers_dir/$t.md" ]] \
      && record ok trackers "$t.md presente" \
      || record warn trackers "stub $t.md ausente"
  done
fi

# ─── 7. kb-skeleton ───────────────────────────────────────────────────────────
if [[ -d "$PLUGIN_ROOT/kb-skeleton" ]]; then
  miss=0
  for l in L0-system L1-modules L2-domain L3-flows L4-integrations L5-issues L6-decisions L7-functional analysis handoff plans index; do
    [[ -d "$PLUGIN_ROOT/kb-skeleton/$l" ]] || { record warn kb_skeleton "falta capa $l"; miss=$((miss+1)); }
  done
  [[ $miss -eq 0 ]] && record ok kb_skeleton "esqueleto KB completo"
fi

# ─── Salida ───────────────────────────────────────────────────────────────────
fails=0; warns=0
for c in "${checks[@]}"; do
  s="${c%%|*}"
  [[ "$s" == fail ]] && fails=$((fails+1))
  [[ "$s" == warn ]] && warns=$((warns+1))
done

if [[ $JSON -eq 1 ]]; then
  printf '{\n  "plugin_root": "%s",\n  "fixes_applied": [' "$PLUGIN_ROOT"
  for i in "${!fixes[@]}"; do
    [[ $i -gt 0 ]] && printf ', '
    printf '"%s"' "${fixes[$i]}"
  done
  printf '],\n  "summary": {"fail": %d, "warn": %d, "ok": %d},\n  "checks": [' \
    "$fails" "$warns" $(( ${#checks[@]} - fails - warns ))
  for i in "${!checks[@]}"; do
    IFS='|' read -r s cat msg <<<"${checks[$i]}"
    [[ $i -gt 0 ]] && printf ','
    printf '\n    {"status":"%s","category":"%s","message":"%s"}' "$s" "$cat" "${msg//\"/\\\"}"
  done
  printf '\n  ]\n}\n'
else
  echo "🔍 Doctor — $PLUGIN_ROOT"
  for c in "${checks[@]}"; do
    IFS='|' read -r s cat msg <<<"$c"
    case "$s" in
      ok)   echo "  ✓ [$cat] $msg" ;;
      warn) echo "  ! [$cat] $msg" ;;
      fail) echo "  ✗ [$cat] $msg" ;;
    esac
  done
  if [[ ${#fixes[@]} -gt 0 ]]; then
    echo
    echo "Reparaciones aplicadas:"
    for f in "${fixes[@]}"; do echo "  - $f"; done
  fi
  echo
  if [[ $fails -eq 0 ]]; then
    echo "✅ OK ($warns avisos)"
  else
    echo "❌ $fails fallo(s), $warns aviso(s)"
    exit 1
  fi
fi
