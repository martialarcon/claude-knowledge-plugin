#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════
# Hook: on-user-prompt.sh  (plugin: ckp)
# Evento: UserPromptSubmit
# 1) Mientras la sesión CKP está activa, recuerda al modelo consultar KB primero.
# 2) Hace keyword-routing contra <KB>/index/keywords.json y emite los paths
#    sugeridos como additionalContext.
#
# Activación:
#   - Existe el flag ${CLAUDE_PLUGIN_DATA}/.ckp-session-active
#   - El prompt no empieza por '/' (los comandos ya re-activan la skill).
#
# Overrides:
#   CKP_ROUTING_TOPN=N        (default 5) máximo de keywords devueltas
#   CKP_ROUTING_PATHS_PER=N   (default 6) máximo de paths por keyword
# ═══════════════════════════════════════════════════════════════════════════════

set -euo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"
DATA_DIR="${CLAUDE_PLUGIN_DATA:-$PROJECT_DIR/.claude}"
FLAG="$DATA_DIR/.ckp-session-active"
[[ -f "$FLAG" ]] || exit 0

payload=$(cat)
prompt=$(printf '%s' "$payload" | jq -r '.user_prompt // .prompt // empty' 2>/dev/null || echo "")

[[ -z "$prompt" ]] && exit 0
case "$prompt" in
  /*) exit 0 ;;
esac

KB_SUB="${CLAUDE_PLUGIN_OPTION_KB_PATH:-}"
if [[ -n "$KB_SUB" ]]; then
    case "$KB_SUB" in
        /*) KB_ROOT="$KB_SUB" ;;
         *) KB_ROOT="$PROJECT_DIR/$KB_SUB" ;;
    esac
else
    KB_ROOT="$PROJECT_DIR"
fi

KEYWORDS="$KB_ROOT/index/keywords.json"
TOPN="${CKP_ROUTING_TOPN:-5}"
PATHS_PER="${CKP_ROUTING_PATHS_PER:-6}"

reminder=$(cat <<'EOF'
[CKP activo] Antes de leer código: identifica nivel KB (L0–L7) que cubre el sub-tema, relee la sección, y abre tu respuesta con `KB consultado: <ruta §sección>` (o `ninguna` + propuesta). Código sólo después, mínimo necesario.
EOF
)

routing=""
if [[ -f "$KEYWORDS" ]]; then
  prompt_lower=$(printf '%s' "$prompt" | tr '[:upper:]' '[:lower:]')
  routing=$(jq -r \
    --arg prompt "$prompt_lower" \
    --argjson topn "$TOPN" \
    --argjson pper "$PATHS_PER" '
    def asarr: . // [] | if type == "array" then [.[] | tostring] elif type == "string" then [.] else [] end;

    .keywords as $kw |
    [ $kw | to_entries[] | . as $e |
      ($e.key | ascii_downcase) as $k |
      (($e.value.aliases // []) | map(ascii_downcase)) as $aliases |
      select(
        ($prompt | contains($k))
        or ($aliases | any(. as $a | $prompt | contains($a)))
      )
      | {
          keyword: $e.key,
          paths: (
              ($e.value.l7           | asarr)
            + ($e.value.locations    | asarr)
            + ($e.value.location     | asarr)
            + ($e.value.files        | asarr)
            + ($e.value.file         | asarr)
            + ($e.value.config       | asarr)
            + ($e.value.analysis     | asarr)
            + ($e.value.adr          | asarr)
            + ($e.value.lookup_paths | asarr)
          ) | unique | .[0:$pper]
        }
    ] | .[0:$topn] |
    if length == 0 then empty
    else (map("- " + .keyword + ": " + (.paths | join(", "))) | join("\n"))
    end
  ' "$KEYWORDS" 2>/dev/null || echo "")
fi

if [[ -n "$routing" ]]; then
  full_context=$(printf '%s\n\n**Keywords detectadas → paths KB sugeridos** (de `index/keywords.json`):\n%s\n\nSi el match no encaja con la intención real, ignorar.' "$reminder" "$routing")
else
  full_context="$reminder"
fi

jq -n --arg ctx "$full_context" '{
  hookSpecificOutput: {
    hookEventName: "UserPromptSubmit",
    additionalContext: $ctx
  }
}'
