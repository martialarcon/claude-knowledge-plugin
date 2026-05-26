#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# doctor.sh — Health-check de una instalación del plugin.
#
# Sustituye al antiguo validate.sh con soporte para --json y --fix.
#
# Uso:
#   doctor.sh <target>                # texto humano
#   doctor.sh <target> --json         # salida estructurada
#   doctor.sh <target> --fix          # repara lo trivial y vuelve a chequear
# ═══════════════════════════════════════════════════════════════════════════════

set -euo pipefail

JSON=0
FIX=0
TARGET=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --json) JSON=1; shift ;;
    --fix)  FIX=1; shift ;;
    -h|--help) sed -n '2,12p' "$0"; exit 0 ;;
    *) TARGET="$1"; shift ;;
  esac
done

[[ -n "$TARGET" ]] || { echo "Uso: doctor.sh <target> [--json] [--fix]" >&2; exit 2; }
TARGET="$(cd "$TARGET" && pwd)"

# checks: array de "status|category|message"
checks=()
fixes=()
record() { checks+=("$1|$2|$3"); }

# ─── 1. placeholders ──────────────────────────────────────────────────────────
if grep -rE '\{\{[A-Z_]+\}\}' "$TARGET/.claude" "$TARGET/CLAUDE.md" >/dev/null 2>&1; then
  record fail placeholders "Quedan placeholders {{...}} sin sustituir"
else
  record ok placeholders "sin placeholders pendientes"
fi

# ─── 2. archivos obligatorios ─────────────────────────────────────────────────
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
miss=0
for f in "${required[@]}"; do
  [[ -f "$TARGET/$f" ]] || { record fail required_files "Falta $f"; miss=$((miss+1)); }
done
[[ $miss -eq 0 ]] && record ok required_files "todos los archivos obligatorios presentes"

# ─── 3. hooks ejecutables ─────────────────────────────────────────────────────
non_exec=()
for h in "$TARGET/.claude/hooks/"*.sh; do
  [[ -x "$h" ]] || non_exec+=("$h")
done
if [[ ${#non_exec[@]} -eq 0 ]]; then
  record ok hooks_exec "hooks ejecutables"
else
  for h in "${non_exec[@]}"; do record fail hooks_exec "no ejecutable: $h"; done
  if [[ $FIX -eq 1 ]]; then
    chmod +x "${non_exec[@]}"
    fixes+=("chmod +x hooks: ${#non_exec[@]}")
  fi
fi

# ─── 4. tracker activo ────────────────────────────────────────────────────────
tracker_file=$(grep -oE 'trackers/[a-z]+\.md' "$TARGET/.claude/skills/planner/SKILL.md" 2>/dev/null | head -1 || true)
if [[ -z "$tracker_file" ]]; then
  record fail tracker "no se detecta tracker activo en planner/SKILL.md"
elif [[ ! -f "$TARGET/.claude/skills/planner/references/$tracker_file" ]]; then
  record fail tracker "tracker referenciado no existe: $tracker_file"
else
  record ok tracker "$tracker_file"
fi

# ─── 5. JSON válido ───────────────────────────────────────────────────────────
for j in "$TARGET/.claude/settings.json" "$TARGET/.claude/skill-rules.json"; do
  [[ -f "$j" ]] || continue
  if jq empty "$j" >/dev/null 2>&1; then
    record ok json "$(basename "$j") válido"
  else
    record fail json "JSON inválido: $j"
  fi
done

# ─── 6. KB integrity ──────────────────────────────────────────────────────────
KB_PATH=""
if [[ -f "$TARGET/CLAUDE.md" ]]; then
  KB_PATH=$(grep -oE 'KB.*[~/][^ ]+' "$TARGET/CLAUDE.md" | head -1 | grep -oE '[~/][^ ]+' || true)
fi

# handoffs sin plan correspondiente
if [[ -d "$TARGET/handoff" ]]; then
  orphans=0
  while IFS= read -r -d '' hf; do
    id="$(basename "$hf" .yaml)"
    [[ -f "$TARGET/plans/$id.md" ]] || orphans=$((orphans+1))
  done < <(find "$TARGET/handoff" -maxdepth 1 -name '*.yaml' -print0 2>/dev/null)
  if [[ $orphans -eq 0 ]]; then
    record ok kb_handoffs "ningún handoff huérfano"
  else
    record warn kb_handoffs "$orphans handoff(s) sin plan asociado"
  fi
fi

# index/keywords.json válido y no vacío
if [[ -f "$TARGET/index/keywords.json" ]]; then
  if ! jq empty "$TARGET/index/keywords.json" >/dev/null 2>&1; then
    record fail kb_index "index/keywords.json inválido"
    if [[ $FIX -eq 1 ]]; then
      echo '{}' > "$TARGET/index/keywords.json"
      fixes+=("reset index/keywords.json a {}")
    fi
  else
    record ok kb_index "index/keywords.json válido"
  fi
fi

# directorios L0–L7
if [[ -d "$TARGET" ]]; then
  missing_layers=()
  for layer in L0-system L1-modules L2-domain L3-flows L4-integrations L5-issues L6-decisions L7-functional; do
    [[ -d "$TARGET/$layer" ]] || missing_layers+=("$layer")
  done
  if [[ ${#missing_layers[@]} -gt 0 ]]; then
    record warn kb_layers "capas KB ausentes: ${missing_layers[*]}"
    if [[ $FIX -eq 1 ]]; then
      for l in "${missing_layers[@]}"; do mkdir -p "$TARGET/$l" && touch "$TARGET/$l/.gitkeep"; done
      fixes+=("creadas ${#missing_layers[@]} capas KB")
    fi
  else
    record ok kb_layers "capas L0–L7 presentes"
  fi
fi

# ─── 7. versión instalada ─────────────────────────────────────────────────────
if [[ -f "$TARGET/.claude/.plugin-version" ]]; then
  record ok plugin_version "instalado: $(cat "$TARGET/.claude/.plugin-version")"
else
  record warn plugin_version "sin .claude/.plugin-version (instalación anterior a 0.2.0)"
fi

# ─── Salida ───────────────────────────────────────────────────────────────────
fails=0; warns=0
for c in "${checks[@]}"; do
  s="${c%%|*}"
  [[ "$s" == fail ]] && fails=$((fails+1))
  [[ "$s" == warn ]] && warns=$((warns+1))
done

if [[ $JSON -eq 1 ]]; then
  printf '{\n  "target": "%s",\n  "fixes_applied": [' "$TARGET"
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
  echo "🔍 Doctor — $TARGET"
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
  fi
fi

exit $(( fails > 0 ? 1 : 0 ))
