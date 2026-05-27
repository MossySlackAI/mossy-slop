#!/bin/bash
# write-flow-file.sh - Write content from stdin to a file in .flow/
# Usage: write-flow-file.sh <path-relative-to-flow>
#   or: source write-flow-file.sh; write_flow_file <path>
# 
# Writes stdin content to .flow/<path>, creating parent directories as needed.
# Sets file permissions to 644.
# Returns 0 on success, non-zero on failure.
# Silent on success, errors to stderr.

write_flow_file() {
    local target_path="$1"
    local FLOW_DIR=".flow"
    local full_path="$FLOW_DIR/$target_path"

    # Validate argument
    if [ -z "$target_path" ]; then
        echo "Error: No target path provided" >&2
        return 1
    fi

    # Create parent directories (including .flow/ if needed)
    local parent_dir
    parent_dir="$(dirname "$full_path")"
    if [ "$parent_dir" != "." ]; then
        if ! mkdir -p "$parent_dir" 2>/dev/null; then
            echo "Error: Failed to create parent directories for $full_path" >&2
            return 1
        fi
    else
        # If parent is ".", need to create .flow/ itself
        if [ ! -d "$FLOW_DIR" ] && ! mkdir -p "$FLOW_DIR" 2>/dev/null; then
            echo "Error: Failed to create .flow/ directory" >&2
            return 1
        fi
    fi

    # Write stdin to file
    if ! cat > "$full_path" 2>/dev/null; then
        echo "Error: Failed to write to $full_path" >&2
        return 1
    fi

    # Set permissions to 644
    if ! chmod 644 "$full_path" 2>/dev/null; then
        echo "Error: Failed to set permissions on $full_path" >&2
        return 1
    fi

    return 0
}

# If script is executed directly (not sourced), run the function
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    if [ $# -lt 1 ]; then
        echo "Usage: write-flow-file.sh <path-relative-to-flow>" >&2
        exit 1
    fi
    write_flow_file "$1"
    exit $?
fi
