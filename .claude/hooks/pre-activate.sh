#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════
# Hook: pre-activate.sh
# Se ejecuta antes de activar la skill Knowledge Agent o Planner.
# - Hace pull --ff-only de los repos listados en .claude/repos.list (throttle).
# - Inyecta estado del KB y warnings de entornos como systemMessage.
#
# Overrides:
#   KA_FORCE_PULL=1                 fuerza el pull aunque no haya expirado el TTL.
#   KA_PULL_TTL_MIN=N               cambia la ventana del throttle (default 30 min).
#   {{REPOS_ROOT_ENV}}=/path        raíz donde buscar los repos compañeros.
# ═══════════════════════════════════════════════════════════════════════════════

set -euo pipefail
trap 'exit 0' ERR

# ─── CONFIG ───
if [[ -n "${CLAUDE_PROJECT_DIR:-}" ]]; then
    KB_ROOT="$CLAUDE_PROJECT_DIR"
else
    KB_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
fi

REPOS_ROOT="${{{REPOS_ROOT_ENV}}:-$(dirname "$KB_ROOT")}"
REPOS_LIST="$KB_ROOT/.claude/repos.list"
PULL_STAMP="$KB_ROOT/.claude/.last-pull"
PULL_TTL_MIN="${KA_PULL_TTL_MIN:-30}"

SUMMARY=""
add() { SUMMARY+="$*"$'\n'; }

check_kb_state() {
    [[ -d "$KB_ROOT/L0-system" ]] && add "KB_EXISTS=true" || add "KB_EXISTS=false"
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
    [[ "${KA_FORCE_PULL:-0}" = "1" ]] && return 0
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
        add "📥 Pull omitido (último a las $last_human, TTL ${PULL_TTL_MIN}min). Forzar: KA_FORCE_PULL=1"
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

    mkdir -p "$(dirname "$PULL_STAMP")"
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
