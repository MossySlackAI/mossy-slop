#!/bin/bash
# write-flow-file.sh - Write content from stdin to a file in .flow/
# Usage: echo "content" | ./write-flow-file.sh <path-relative-to-flow>
# Output: Success message on stdout, errors on stderr

# Sourcing guard - must be called directly, not sourced
if [ "${BASH_SOURCE[0]}" != "${0}" ]; then
    echo "Error: This script must be called directly, not sourced" >&2
    exit 1
fi

# Validate argument
if [ $# -lt 1 ]; then
    echo "Usage: write-flow-file.sh <path-relative-to-flow>" >&2
    exit 1
fi

target_path="$1"
FLOW_DIR=".flow"
full_path="$FLOW_DIR/$target_path"

# Validate target path
if [ -z "$target_path" ]; then
    echo "Error: No target path provided" >&2
    exit 1
fi

# Create parent directories (including .flow/ if needed)
parent_dir="$(dirname "$full_path")"
if [ "$parent_dir" != "." ]; then
    if ! mkdir -p "$parent_dir" 2>/dev/null; then
        echo "Error: Failed to create parent directories for $full_path" >&2
        exit 1
    fi
else
    # If parent is ".", need to create .flow/ itself
    if [ ! -d "$FLOW_DIR" ] && ! mkdir -p "$FLOW_DIR" 2>/dev/null; then
        echo "Error: Failed to create .flow/ directory" >&2
        exit 1
    fi
fi

# Write stdin to file
if ! cat > "$full_path" 2>/dev/null; then
    echo "Error: Failed to write to $full_path" >&2
    exit 1
fi

# Set permissions to 644
if ! chmod 644 "$full_path" 2>/dev/null; then
    echo "Error: Failed to set permissions on $full_path" >&2
    exit 1
fi

echo "Success: Written to $full_path"
exit 0
