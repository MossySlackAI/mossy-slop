#!/bin/bash
# ensure-mossy-config.sh - Ensure .flow/mossy-config exists
# Usage: Call directly: ./ensure-mossy-config.sh
# Output: Success message on stdout, errors on stderr

# Sourcing guard - must be called directly, not sourced
if [ "${BASH_SOURCE[0]}" != "${0}" ]; then
    echo "Error: This script must be called directly, not sourced" >&2
    exit 1
fi

FLOW_DIR=".flow"
CONFIG_FILE="$FLOW_DIR/mossy-config"

# Do not overwrite existing config
if [ -f "$CONFIG_FILE" ]; then
    echo "Success: mossy-config already exists"
    exit 0
fi

# Search upward for config/mossy-config.default
CURRENT_DIR=$(pwd)
TEMPLATE=""

while [ "$CURRENT_DIR" != "/" ]; do
    if [ -f "$CURRENT_DIR/config/mossy-config.default" ]; then
        TEMPLATE="$CURRENT_DIR/config/mossy-config.default"
        break
    fi
    # Also check if we're in a mossy-slop directory structure
    if [ -d "$CURRENT_DIR/skills" ] && [ -d "$CURRENT_DIR/commands" ]; then
        if [ -f "$CURRENT_DIR/config/mossy-config.default" ]; then
            TEMPLATE="$CURRENT_DIR/config/mossy-config.default"
            break
        fi
    fi
    CURRENT_DIR=$(dirname "$CURRENT_DIR")
done

if [ -n "$TEMPLATE" ] && [ -f "$TEMPLATE" ]; then
    if mkdir -p "$FLOW_DIR" 2>/dev/null; then
        if cp "$TEMPLATE" "$CONFIG_FILE" 2>/dev/null; then
            echo "Success: mossy-config created from template"
            exit 0
        else
            echo "Error: Failed to copy mossy-config.default to $CONFIG_FILE (read-only filesystem?)" >&2
            exit 1
        fi
    else
        echo "Error: Failed to create .flow/ directory" >&2
        exit 1
    fi
else
    echo "Warning: mossy-config.default not found in current directory or parents" >&2
    exit 1
fi
