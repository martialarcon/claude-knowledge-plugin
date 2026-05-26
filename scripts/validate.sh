#!/usr/bin/env bash
# Alias de retrocompatibilidad: validate.sh → doctor.sh (sin flags).
# Uso: validate.sh <target>
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "$SCRIPT_DIR/doctor.sh" "$@"
