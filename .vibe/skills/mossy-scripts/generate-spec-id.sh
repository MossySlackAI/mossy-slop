#!/bin/bash
# generate-spec-id.sh - Generate next spec ID from existing specs
# Usage: Call directly: ./generate-spec-id.sh <idea-text>
# Output: JSON object with {next_n, slug, spec_id} on stdout, errors on stderr

# Sourcing guard - must be called directly, not sourced
if [ "${BASH_SOURCE[0]}" != "${0}" ]; then
    echo "Error: This script must be called directly, not sourced" >&2
    exit 1
fi

# Validate argument
if [ $# -lt 1 ]; then
    echo "Usage: generate-spec-id.sh <idea-text>" >&2
    exit 1
fi

idea_text="$1"
FLOW_DIR=".flow"
SPECS_DIR="$FLOW_DIR/specs"

# Find maximum N from existing spec files matching pattern fn-(\d+)-*
max_n=0

if [ -d "$SPECS_DIR" ]; then
    # Extract all N values from filenames matching pattern fn-<number>-
    while IFS= read -r -d '' file; do
        basename=$(basename "$file")
        if [[ "$basename" =~ ^fn-([0-9]+)- ]]; then
            n=${BASH_REMATCH[1]}
            if [ "$n" -gt "$max_n" ] 2>/dev/null; then
                max_n=$n
            fi
        fi
    done < <(find "$SPECS_DIR" -name 'fn-*.md' -type f -print0 2>/dev/null)
fi

next_n=$((max_n + 1))

# Slugify idea text
slug=$(echo "$idea_text" | tr '[:upper:]' '[:lower:]' | tr ' _' '-' | tr -dc 'a-z0-9\n-' | sed 's/^-\+//;s/-\+$//')

# Construct spec ID
spec_id="fn-${next_n}-${slug}.md"

# Output JSON
echo "{\"next_n\": $next_n, \"slug\": \"$slug\", \"spec_id\": \"$spec_id\"}"
exit 0
