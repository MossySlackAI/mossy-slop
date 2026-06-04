#!/bin/bash
# load-mossy-config.sh - Load and parse mossy configuration
# Usage:
#   ./load-mossy-config.sh                       # Output full JSON object
#   ./load-mossy-config.sh <config-item>         # Output value of config item from .flow/mossy-config
#   ./load-mossy-config.sh <config-item> <spec> # Output value of config item from spec file starting with <spec>
#
# Config items: FLOW_DIR, MOSSY_CONFIG, COMMIT_POLICY, NEW_BRANCH_PER_SPEC, AUTO_PUSH, CO_AUTHORED_BY
#
# Output: Value on stdout, errors on stderr

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

# Function to parse a config file and set variables
parse_config_file() {
    local config_file="$1"
    if [ -f "$config_file" ]; then
        # Parse YAML-like config (simple key: value format)
        COMMIT_POLICY=$(grep -E '^commit-policy:' "$config_file" 2>/dev/null | head -1 | awk '{print $2}')
        NEW_BRANCH_PER_SPEC=$(grep -E '^new-branch-per-spec:' "$config_file" 2>/dev/null | head -1 | awk '{print $2}')
        AUTO_PUSH=$(grep -E '^auto-push:' "$config_file" 2>/dev/null | head -1 | awk '{print $2}')
        
        # For co-authored-by: only use default if key doesn't exist, not if explicitly empty
        CO_AUTHORED_BY_LINE=$(grep -E '^co-authored-by:' "$config_file" 2>/dev/null | head -1)
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
}

# Try to ensure config exists first
if [ ! -f "$MOSSY_CONFIG" ]; then
    `dirname $0`/ensure-flow-dir.sh 2>/dev/null 1>/dev/null || true
fi

# Parse global config
parse_config_file "$MOSSY_CONFIG"

# If arguments provided, output specific config item
if [ $# -ge 1 ]; then
    CONFIG_ITEM="$1"
    
    # If second argument provided, look for matching spec file
    if [ $# -ge 2 ]; then
        SPEC_START="$2"
        SPEC_DIR="$FLOW_DIR/specs"
        
        # First try exact match (SPEC_START.md)
        SPEC_FILE="$SPEC_DIR/${SPEC_START}.md"
        if [ ! -f "$SPEC_FILE" ]; then
            # Then try prefix match
            SPEC_FILE=$(find "$SPEC_DIR" -name "${SPEC_START}*.md" -type f | head -1)
        fi
        
        if [ -n "$SPEC_FILE" ] && [ -f "$SPEC_FILE" ]; then
            # Parse Mossy-Config section from spec file
            # Look for ## Mossy-Config section and parse the list items
            SPEC_COMMIT_POLICY="$COMMIT_POLICY"
            SPEC_NEW_BRANCH_PER_SPEC="$NEW_BRANCH_PER_SPEC"
            SPEC_AUTO_PUSH="$AUTO_PUSH"
            SPEC_CO_AUTHORED_BY="$CO_AUTHORED_BY"
            
            # Extract Mossy-Config section
            in_mossy_config=0
            while IFS= read -r line; do
                # Detect start of Mossy-Config section
                if echo "$line" | grep -qE '^##\s+Mossy-Config\s*$'; then
                    in_mossy_config=1
                    continue
                fi
                
                # Detect end of Mossy-Config section (next ## heading)
                if [ $in_mossy_config -eq 1 ] && echo "$line" | grep -qE '^##\s'; then
                    break
                fi
                
                # Parse config items from Mossy-Config section
                if [ $in_mossy_config -eq 1 ]; then
                    if echo "$line" | grep -qE '^-\s*commit-policy:\s*(.*)'; then
                        SPEC_COMMIT_POLICY=$(echo "$line" | sed -E 's/^-\s*commit-policy:\s*//')
                    elif echo "$line" | grep -qE '^-\s*new-branch-per-spec:\s*(.*)'; then
                        SPEC_NEW_BRANCH_PER_SPEC=$(echo "$line" | sed -E 's/^-\s*new-branch-per-spec:\s*//')
                    elif echo "$line" | grep -qE '^-\s*auto-push:\s*(.*)'; then
                        SPEC_AUTO_PUSH=$(echo "$line" | sed -E 's/^-\s*auto-push:\s*//')
                    elif echo "$line" | grep -qE '^-\s*co-authored-by:\s*(.*)'; then
                        SPEC_CO_AUTHORED_BY=$(echo "$line" | sed -E 's/^-\s*co-authored-by:\s*//')
                    fi
                fi
            done < "$SPEC_FILE"
            
            # Override global config with spec-specific values
            COMMIT_POLICY="$SPEC_COMMIT_POLICY"
            NEW_BRANCH_PER_SPEC="$SPEC_NEW_BRANCH_PER_SPEC"
            AUTO_PUSH="$SPEC_AUTO_PUSH"
            CO_AUTHORED_BY="$SPEC_CO_AUTHORED_BY"
            
            # Apply R3 defaults to spec-specific values
            if [ "$NEW_BRANCH_PER_SPEC" = "false" ] && [ "$AUTO_PUSH" != "false" ]; then
                AUTO_PUSH="false"
            fi
            if [ "$NEW_BRANCH_PER_SPEC" = "true" ] && [ "$AUTO_PUSH" != "true" ]; then
                AUTO_PUSH="true"
            fi
        fi
    fi
    
    # Output the requested config item
    case "$CONFIG_ITEM" in
        FLOW_DIR)
            echo "$FLOW_DIR"
            ;;
        MOSSY_CONFIG)
            echo "$MOSSY_CONFIG"
            ;;
        COMMIT_POLICY)
            echo "$COMMIT_POLICY"
            ;;
        NEW_BRANCH_PER_SPEC)
            echo "$NEW_BRANCH_PER_SPEC"
            ;;
        AUTO_PUSH)
            echo "$AUTO_PUSH"
            ;;
        CO_AUTHORED_BY)
            echo "$CO_AUTHORED_BY"
            ;;
        *)
            echo "Error: Unknown config item '$CONFIG_ITEM'" >&2
            echo "Valid items: FLOW_DIR, MOSSY_CONFIG, COMMIT_POLICY, NEW_BRANCH_PER_SPEC, AUTO_PUSH, CO_AUTHORED_BY" >&2
            exit 1
            ;;
    esac
    exit 0
fi

# No arguments - output full JSON (backward compatible)
echo "{\"FLOW_DIR\": \"$FLOW_DIR\", \"MOSSY_CONFIG\": \"$MOSSY_CONFIG\", \"COMMIT_POLICY\": \"$COMMIT_POLICY\", \"NEW_BRANCH_PER_SPEC\": $NEW_BRANCH_PER_SPEC, \"AUTO_PUSH\": $AUTO_PUSH, \"CO_AUTHORED_BY\": \"$CO_AUTHORED_BY\"}"
exit 0
