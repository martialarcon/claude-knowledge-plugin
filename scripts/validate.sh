#!/usr/bin/env bash
# Alias de retrocompatibilidad: validate.sh → doctor.sh
# Uso: validate.sh [--json] [--fix]
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "$SCRIPT_DIR/doctor.sh" "$@"
