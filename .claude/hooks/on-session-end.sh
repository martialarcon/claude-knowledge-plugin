#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════
# Hook: on-session-end.sh
# Limpia el flag de sesión KA activa.
# ═══════════════════════════════════════════════════════════════════════════════

rm -f "$CLAUDE_PROJECT_DIR/.claude/.ka-session-active"
exit 0
