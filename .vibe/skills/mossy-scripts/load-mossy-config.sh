#!/bin/bash
# load-mossy-config.sh - Load and parse mossy configuration
# Usage: Call directly: ./load-mossy-config.sh
# Output: JSON object with config values on stdout, errors on stderr

# Sourcing guard - must be called directly, not sourced
if [ "${BASH_SOURCE[0]}" != "${0}" ]; then
    echo "Error: This script must be called directly, not sourced" >&2
    exit 1
fi

FLOW_DIR=".flow"
MOSSY_CONFIG="$FLOW_DIR/mossy-config"

# Default values
COMMIT_POLICY="manual"
NEW_BRANCH_PER_SPEC="false"
AUTO_PUSH="false"
CO_AUTHORED_BY="Mistral Vibe with Mossy Slop <vibe@mistral.ai>"

# Try to ensure config exists first
if [ ! -f "$MOSSY_CONFIG" ]; then
    `dirname $0`/ensure-flow-dir.sh 2>/dev/null 1>/dev/null || true
fi

# If config file exists, parse it
if [ -f "$MOSSY_CONFIG" ]; then
    # Parse YAML-like config (simple key: value format)
    COMMIT_POLICY=$(grep -E '^commit-policy:' "$MOSSY_CONFIG" 2>/dev/null | head -1 | awk '{print $2}')
    NEW_BRANCH_PER_SPEC=$(grep -E '^new-branch-per-spec:' "$MOSSY_CONFIG" 2>/dev/null | head -1 | awk '{print $2}')
    AUTO_PUSH=$(grep -E '^auto-push:' "$MOSSY_CONFIG" 2>/dev/null | head -1 | awk '{print $2}')
    
    # For co-authored-by: only use default if key doesn't exist, not if explicitly empty
    CO_AUTHORED_BY_LINE=$(grep -E '^co-authored-by:' "$MOSSY_CONFIG" 2>/dev/null | head -1)
    if [ -n "$CO_AUTHORED_BY_LINE" ]; then
        CO_AUTHORED_BY=$(echo "$CO_AUTHORED_BY_LINE" | sed 's/^co-authored-by: *//')
    fi
    
    # Apply R3 defaults: if new-branch-per-spec=false, force auto-push=false
    if [ "$NEW_BRANCH_PER_SPEC" = "false" ] && [ "$AUTO_PUSH" != "false" ]; then
        AUTO_PUSH="false"
    fi
    if [ "$NEW_BRANCH_PER_SPEC" = "true" ] && [ "$AUTO_PUSH" != "true" ]; then
        AUTO_PUSH="true"
    fi
fi

# Output JSON
echo "{\"FLOW_DIR\": \"$FLOW_DIR\", \"MOSSY_CONFIG\": \"$MOSSY_CONFIG\", \"COMMIT_POLICY\": \"$COMMIT_POLICY\", \"NEW_BRANCH_PER_SPEC\": $NEW_BRANCH_PER_SPEC, \"AUTO_PUSH\": $AUTO_PUSH, \"CO_AUTHORED_BY\": \"$CO_AUTHORED_BY\"}"
exit 0
