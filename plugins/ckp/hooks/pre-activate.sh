#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════
# Hook: pre-activate.sh  (plugin: ckp)
# Se ejecuta antes de activar la skill knowledge-agent o planner.
# - Hace pull --ff-only de los repos listados en
#   ${CLAUDE_PROJECT_DIR}/.claude/ckp-repos.list (throttle).
# - Inyecta estado del KB y warnings de entornos como systemMessage.
#
# Overrides:
#   CKP_FORCE_PULL=1     fuerza el pull aunque no haya expirado el TTL.
#   CKP_PULL_TTL_MIN=N   cambia la ventana del throttle (default 30 min).
#   CKP_REPOS_ROOT=/path raíz donde buscar los repos compañeros
#                        (default: directorio padre del KB).
#
# Rutas:
#   KB_ROOT   = ${CLAUDE_PROJECT_DIR}/${CLAUDE_PLUGIN_OPTION_KB_PATH}
#               (si KB_PATH vacío → KB_ROOT = CLAUDE_PROJECT_DIR)
#   DATA_DIR  = ${CLAUDE_PLUGIN_DATA}  (estado mutable del plugin)
# ═══════════════════════════════════════════════════════════════════════════════

set -euo pipefail
trap 'exit 0' ERR

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"
KB_SUB="${CLAUDE_PLUGIN_OPTION_KB_PATH:-}"
if [[ -n "$KB_SUB" ]]; then
    case "$KB_SUB" in
        /*) KB_ROOT="$KB_SUB" ;;
         *) KB_ROOT="$PROJECT_DIR/$KB_SUB" ;;
    esac
else
    KB_ROOT="$PROJECT_DIR"
fi

DATA_DIR="${CLAUDE_PLUGIN_DATA:-$PROJECT_DIR/.claude}"
mkdir -p "$DATA_DIR"

REPOS_ROOT="${CKP_REPOS_ROOT:-$(dirname "$KB_ROOT")}"
REPOS_LIST="$PROJECT_DIR/.claude/ckp-repos.list"
PULL_STAMP="$DATA_DIR/.last-pull"
PULL_TTL_MIN="${CKP_PULL_TTL_MIN:-30}"

SUMMARY=""
add() { SUMMARY+="$*"$'\n'; }

check_kb_state() {
    [[ -d "$KB_ROOT/L0-system" ]] && add "KB_EXISTS=true" || add "KB_EXISTS=false (sugerencia: /ckp:setup)"
}

inject_environment_context() {
    local yaml="$KB_ROOT/L0-system/environments.yaml"
    [[ -f "$yaml" ]] || return 0
    if grep -q "warning:" "$yaml" 2>/dev/null; then
        local warnings
        warnings=$(grep -c "warning:" "$yaml" 2>/dev/null || true)
        warnings=${warnings:-0}
        add "⚠️  ENV_WARNINGS=$warnings"
    fi
    return 0
}

should_pull() {
    [[ "${CKP_FORCE_PULL:-0}" = "1" ]] && return 0
    [[ ! -f "$PULL_STAMP" ]] && return 0
    local now last age
    now=$(date +%s)
    last=$(tr -dc '0-9' < "$PULL_STAMP" 2>/dev/null || echo 0)
    last=${last:-0}
    age=$(( (now - last) / 60 ))
    (( age >= PULL_TTL_MIN ))
}

resolve_repos() {
    printf '%s\n' "$KB_ROOT"
    [[ -f "$REPOS_LIST" ]] || return 0

    local line entry expanded
    while IFS= read -r line || [[ -n "$line" ]]; do
        line="${line%%#*}"
        line="${line#"${line%%[![:space:]]*}"}"
        line="${line%"${line##*[![:space:]]}"}"
        [[ -z "$line" ]] && continue

        entry="$REPOS_ROOT/$line"
        shopt -s nullglob
        expanded=( $entry )
        shopt -u nullglob
        for repo in "${expanded[@]}"; do
            printf '%s\n' "$repo"
        done
    done < "$REPOS_LIST"
}

pull_repos() {
    if ! should_pull; then
        local last_human
        last_human=$(date -d "@$(cat "$PULL_STAMP")" '+%H:%M' 2>/dev/null || echo "?")
        add "📥 Pull omitido (último a las $last_human, TTL ${PULL_TTL_MIN}min). Forzar: CKP_FORCE_PULL=1"
        return 0
    fi

    add "📥 Pull de repos (root=$REPOS_ROOT, TTL ${PULL_TTL_MIN}min):"
    local ok=0 skip=0 repo
    while IFS= read -r repo; do
        if [[ -d "$repo/.git" ]]; then
            if git -C "$repo" pull --ff-only -q 2>/dev/null; then
                add "  ✅ $(basename "$repo")"
                ok=$((ok + 1))
            else
                add "  ⚠️  $(basename "$repo") (sin cambios o sin remote)"
                skip=$((skip + 1))
            fi
        fi
    done < <(resolve_repos)
    add "Total: $ok ok, $skip skip"

    date +%s > "$PULL_STAMP"
}

main() {
    local trigger="${1:-unknown}" confidence="${2:-0.8}"
    add "🧠 Skill activada (trigger=$trigger, conf=$confidence)"
    add "   KB_ROOT: $KB_ROOT"

    pull_repos
    check_kb_state
    inject_environment_context

    jq -n --arg msg "$SUMMARY" '{ systemMessage: $msg }'
}

main "$@"
