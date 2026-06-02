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

# Create all required subdirectories
if mkdir -p "$FLOW_DIR/specs" "$FLOW_DIR/tasks" "$FLOW_DIR/issues" "$FLOW_DIR/work" "$FLOW_DIR/reviews" 2>/dev/null; then
    echo "Success: .flow/ directory structure created"
    exit 0
else
    echo "Error: Failed to create .flow/ directory structure" >&2
    exit 1
fi
