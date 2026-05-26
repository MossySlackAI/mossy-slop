#!/bin/bash
# ensure-flow-dir.sh - Ensure .flow/ directory structure exists
# Usage: source this file, then call ensure_flow_dir
# Creates: .flow/specs, .flow/tasks, .flow/issues, .flow/work, .flow/reviews

ensure_flow_dir() {
    local FLOW_DIR=".flow"
    
    # Create all required subdirectories
    mkdir -p "$FLOW_DIR/specs" "$FLOW_DIR/tasks" "$FLOW_DIR/issues" "$FLOW_DIR/work" "$FLOW_DIR/reviews"
    
    # Return success
    return 0
}

# If script is executed directly (not sourced), run the function
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    ensure_flow_dir
fi
