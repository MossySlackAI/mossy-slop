#!/bin/bash
# ensure-mossy-config.sh - Ensure .flow/mossy-config exists
# Usage: source this file, then call ensure_mossy_config
# Or run directly: ./ensure-mossy-config.sh

ensure_mossy_config() {
    local FLOW_DIR=".flow"
    local CONFIG_FILE="$FLOW_DIR/mossy-config"
    
    # Do not overwrite existing config
    if [ -f "$CONFIG_FILE" ]; then
        return 0
    fi
    
    # Search upward for config/mossy-config.default
    local CURRENT_DIR
    CURRENT_DIR=$(pwd)
    local TEMPLATE=""
    
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
        mkdir -p "$FLOW_DIR"
        if cp "$TEMPLATE" "$CONFIG_FILE" 2>/dev/null; then
            return 0
        else
            echo "Warning: Failed to copy mossy-config.default to $CONFIG_FILE (read-only filesystem?)" >&2
            return 1
        fi
    else
        echo "Warning: mossy-config.default not found in current directory or parents" >&2
        return 1
    fi
}

# If script is executed directly (not sourced), run the function
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    ensure_mossy_config
fi
