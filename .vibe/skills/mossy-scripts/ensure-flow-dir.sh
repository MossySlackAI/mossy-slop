#!/bin/bash
# ensure-flow-dir.sh - Ensure .flow/ directory structure exists
# Usage: Call directly: ./ensure-flow-dir.sh
# Output: Success message on stdout, errors on stderr

# Sourcing guard - must be called directly, not sourced
if [ "${BASH_SOURCE[0]}" != "${0}" ]; then
    echo "Error: This script must be called directly, not sourced" >&2
    exit 1
fi

FLOW_DIR=".flow"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Create all required subdirectories
if mkdir -v -p "$FLOW_DIR/specs" "$FLOW_DIR/tasks" "$FLOW_DIR/issues" "$FLOW_DIR/work" "$FLOW_DIR/reviews" 2>/dev/null; then
    if ! test -r $FLOW_DIR/mossy-config; then
        if cp ${SCRIPT_DIR}/mossy-config.default $FLOW_DIR/mossy-config; then
            echo "Default configuration $FLOW_DIR/mossy-config created"
        else
            exit 1
        fi
    fi
    test -r "$FLOW_DIR/meta.json" || "$SCRIPT_DIR/flowctl.sh" init
    exit 0
else
    echo "Error: Failed to create .flow/ directory structure" >&2
    exit 1
fi
