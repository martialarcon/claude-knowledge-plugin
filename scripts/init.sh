#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# init.sh — Bootstrap del claude-knowledge-plugin en un proyecto destino.
#
# Sustituye placeholders {{...}} en todos los archivos del plugin y los copia
# a <target>/.claude/. Opcionalmente bootstrappea el árbol kb-skeleton/.
#
# Uso:
#   init.sh --target <path> [--name NAME] [--slug SLUG] [--kb-path PATH]
#           [--tracker {jira|linear|github}] [--issue-prefix PREFIX]
#           [--tracker-url URL] [--repos-root-env VAR] [--bootstrap-kb]
#
# Sin flags, modo interactivo.
# ═══════════════════════════════════════════════════════════════════════════════

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

TARGET=""
PROJECT_NAME=""
PROJECT_SLUG=""
KB_PATH=""
ISSUE_TRACKER=""
ISSUE_PREFIX=""
ISSUE_TRACKER_URL=""
REPOS_ROOT_ENV=""
BOOTSTRAP_KB=0

usage() {
  sed -n '2,15p' "$0"
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target)          TARGET="$2"; shift 2 ;;
    --name)            PROJECT_NAME="$2"; shift 2 ;;
    --slug)            PROJECT_SLUG="$2"; shift 2 ;;
    --kb-path)         KB_PATH="$2"; shift 2 ;;
    --tracker)         ISSUE_TRACKER="$2"; shift 2 ;;
    --issue-prefix)    ISSUE_PREFIX="$2"; shift 2 ;;
    --tracker-url)     ISSUE_TRACKER_URL="$2"; shift 2 ;;
    --repos-root-env)  REPOS_ROOT_ENV="$2"; shift 2 ;;
    --bootstrap-kb)    BOOTSTRAP_KB=1; shift ;;
    -h|--help)         usage ;;
    *) echo "Flag desconocido: $1" >&2; usage ;;
  esac
done

prompt() {
  local var_name="$1" message="$2" default="${3:-}"
  local current="${!var_name}"
  if [[ -n "$current" ]]; then return; fi
  if [[ -n "$default" ]]; then
    read -r -p "$message [$default]: " value
    value="${value:-$default}"
  else
    read -r -p "$message: " value
  fi
  printf -v "$var_name" '%s' "$value"
}

prompt TARGET            "Ruta del proyecto destino"
prompt PROJECT_NAME      "Nombre del proyecto (ej. aecoc)"        "$(basename "$TARGET")"
prompt PROJECT_SLUG      "Slug de comandos (ej. ka)"              "ka"
prompt KB_PATH           "Ruta del KB"                            "$TARGET"
prompt ISSUE_TRACKER     "Tracker (jira|linear|github)"           "jira"
prompt ISSUE_PREFIX      "Prefijo del ID (ej. ATP)"               "PRJ"
prompt ISSUE_TRACKER_URL "Base URL del tracker"                   "https://example.atlassian.net"
prompt REPOS_ROOT_ENV    "Variable de entorno para raíz de repos" "$(echo "$PROJECT_NAME" | tr '[:lower:]' '[:upper:]')_REPOS_ROOT"

case "$ISSUE_TRACKER" in
  jira|linear|github) ;;
  *) echo "Tracker inválido: $ISSUE_TRACKER (debe ser jira|linear|github)" >&2; exit 2 ;;
esac

if [[ ! "$ISSUE_PREFIX" =~ ^[A-Z][A-Z0-9]+$ ]]; then
  echo "Prefijo inválido: $ISSUE_PREFIX (debe ser MAYÚSCULAS, ej. ATP)" >&2; exit 2
fi

mkdir -p "$TARGET"
TARGET="$(cd "$TARGET" && pwd)"

echo
echo "Configuración:"
echo "  TARGET             = $TARGET"
echo "  PROJECT_NAME       = $PROJECT_NAME"
echo "  PROJECT_SLUG       = $PROJECT_SLUG"
echo "  KB_PATH            = $KB_PATH"
echo "  ISSUE_TRACKER      = $ISSUE_TRACKER"
echo "  ISSUE_PREFIX       = $ISSUE_PREFIX"
echo "  ISSUE_TRACKER_URL  = $ISSUE_TRACKER_URL"
echo "  REPOS_ROOT_ENV     = $REPOS_ROOT_ENV"
echo "  BOOTSTRAP_KB       = $BOOTSTRAP_KB"
echo
read -r -p "¿Continuar? [y/N] " ok
[[ "$ok" =~ ^[yY] ]] || { echo "Abortado."; exit 0; }

# ─── Copia ─────────────────────────────────────────────────────────────────────
mkdir -p "$TARGET/.claude"
cp -R "$PLUGIN_ROOT/.claude/." "$TARGET/.claude/"
cp "$PLUGIN_ROOT/CLAUDE.md.template" "$TARGET/CLAUDE.md"
mv "$TARGET/.claude/repos.list.template" "$TARGET/.claude/repos.list"

if [[ "$BOOTSTRAP_KB" -eq 1 ]]; then
  echo "→ Copiando kb-skeleton/"
  cp -R "$PLUGIN_ROOT/kb-skeleton/." "$TARGET/"
fi

# ─── Sustitución de placeholders ──────────────────────────────────────────────
ESC_URL="${ISSUE_TRACKER_URL//\//\\/}"

substitute() {
  local file="$1"
  sed -i \
    -e "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" \
    -e "s/{{PROJECT_SLUG}}/$PROJECT_SLUG/g" \
    -e "s|{{KB_PATH}}|$KB_PATH|g" \
    -e "s/{{ISSUE_TRACKER}}/$ISSUE_TRACKER/g" \
    -e "s/{{ISSUE_PREFIX}}/$ISSUE_PREFIX/g" \
    -e "s|{{ISSUE_TRACKER_URL}}|$ISSUE_TRACKER_URL|g" \
    -e "s/{{REPOS_ROOT_ENV}}/$REPOS_ROOT_ENV/g" \
    "$file"
}

while IFS= read -r -d '' f; do substitute "$f"; done < <(
  find "$TARGET/.claude" "$TARGET/CLAUDE.md" -type f \
    \( -name '*.md' -o -name '*.json' -o -name '*.sh' -o -name '*.yaml' -o -name 'repos.list' \) -print0
)

chmod +x "$TARGET/.claude/hooks/"*.sh

# Stamp de versión instalada (lo usa scripts/upgrade.sh)
if [[ -f "$PLUGIN_ROOT/VERSION" ]]; then
  cp "$PLUGIN_ROOT/VERSION" "$TARGET/.claude/.plugin-version"
fi

# ─── Stubs de trackers no usados (los borra para no confundir) ────────────────
for t in jira linear github; do
  if [[ "$t" != "$ISSUE_TRACKER" ]]; then
    : # se dejan como referencia; el SKILL.md solo apunta al activo.
  fi
done

echo
echo "✅ Plugin instalado en $TARGET"
echo
echo "Próximos pasos:"
echo "  1. Edita $TARGET/.claude/skills/knowledge-agent/references/domain.md"
echo "  2. Edita $TARGET/.claude/repos.list con los repos compañeros"
echo "  3. Si usas Jira: crea ~/secrets/${ISSUE_TRACKER}_token.txt"
echo "  4. Valida:  $PLUGIN_ROOT/scripts/validate.sh $TARGET"
