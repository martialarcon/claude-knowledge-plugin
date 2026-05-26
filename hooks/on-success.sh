#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════
# Hook: on-success.sh  (plugin: ckp)
# Tras `/ckp capture` exitoso, mergea las keywords nuevas en
# <KB>/index/keywords.json sin sobrescribir entradas existentes.
#
# INVOCACIÓN MANUAL: el SKILL.md instruye al modelo para invocarlo al final
# de una captura aprobada:
#
#   bash "${CLAUDE_PLUGIN_ROOT}/hooks/on-success.sh" capture
#
# Solo actúa cuando $1 contiene "capture|learn|save".
#
# Estado mutable (captures.jsonl) vive en ${CLAUDE_PLUGIN_DATA}/learning/.
# El índice keywords.json se escribe dentro del KB del proyecto.
# ═══════════════════════════════════════════════════════════════════════════════

set -e

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"
DATA_DIR="${CLAUDE_PLUGIN_DATA:-$PROJECT_DIR/.claude}"

KB_SUB="${CLAUDE_PLUGIN_OPTION_KB_PATH:-}"
if [[ -n "$KB_SUB" ]]; then
    case "$KB_SUB" in
        /*) KB_ROOT="$KB_SUB" ;;
         *) KB_ROOT="$PROJECT_DIR/$KB_SUB" ;;
    esac
else
    KB_ROOT="$PROJECT_DIR"
fi

LEARNING_DIR="$DATA_DIR/learning"
CAPTURES_FILE="$LEARNING_DIR/captures.jsonl"
KEYWORDS_INDEX="$KB_ROOT/index/keywords.json"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

trigger="${1:-}"

if [[ "$trigger" != *capture* && "$trigger" != *learn* && "$trigger" != *save* ]]; then
    exit 0
fi

if [[ ! -f "$CAPTURES_FILE" ]]; then
    echo "ℹ️  on-success: no hay $CAPTURES_FILE, nada que indexar"
    exit 0
fi

mkdir -p "$(dirname "$KEYWORDS_INDEX")"

python3 - "$CAPTURES_FILE" "$KEYWORDS_INDEX" "$TIMESTAMP" << 'PYTHON'
import json, sys, os
from datetime import datetime, timedelta

captures_path, index_path, now_iso = sys.argv[1], sys.argv[2], sys.argv[3]
now = datetime.fromisoformat(now_iso.replace('Z', '+00:00'))
cutoff = now - timedelta(seconds=60)

if os.path.exists(index_path):
    with open(index_path) as f:
        try:
            idx = json.load(f)
        except json.JSONDecodeError:
            idx = {}
else:
    idx = {}

idx.setdefault('keywords', {})

added = 0
with open(captures_path) as f:
    for line in f:
        line = line.strip()
        if not line:
            continue
        try:
            entry = json.loads(line)
        except json.JSONDecodeError:
            continue
        ts = datetime.fromisoformat(entry['timestamp'].replace('Z', '+00:00'))
        if ts < cutoff:
            continue

        for kw in entry.get('keywords', []):
            kw_norm = kw.lower().strip()
            if not kw_norm:
                continue
            paths = idx['keywords'].setdefault(kw_norm, [])
            ref = {
                'path': entry['kb_path'],
                'capture_id': entry['id'],
                'issue': entry.get('issue'),
            }
            if not any(p.get('capture_id') == ref['capture_id'] and p.get('path') == ref['path'] for p in paths):
                paths.append(ref)
                added += 1

idx['updated'] = now_iso

with open(index_path, 'w') as f:
    json.dump(idx, f, indent=2, ensure_ascii=False)

print(f"✅ on-success: {added} referencias añadidas a {index_path}")
PYTHON
