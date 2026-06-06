#!/bin/bash
# watch-specs.sh - wait for changes in specs folder

# fallback location: here.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

exec python3 "$SCRIPT_DIR/watch-specs.py" "$@"
