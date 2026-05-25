#!/bin/bash
# generate-spec-id.sh - Generate next spec ID from existing specs
# Usage: source this file, then call generate_spec_id <idea-text>
# Returns: fn-<N>-<slug>.md
# Sets: next_n, slug, spec_id

generate_spec_id() {
    local idea_text="$1"
    local FLOW_DIR=".flow"
    local SPECS_DIR="$FLOW_DIR/specs"
    
    # Find maximum N from existing spec files matching pattern fn-(\d+)-*
    local max_n=0
    
    if [ -d "$SPECS_DIR" ]; then
        # Extract all N values from filenames matching pattern fn-<number>-
        while IFS= read -r -d '' file; do
            local basename
            basename=$(basename "$file")
            if [[ "$basename" =~ ^fn-([0-9]+)- ]]; then
                local n=${BASH_REMATCH[1]}
                if [ "$n" -gt "$max_n" ] 2>/dev/null; then
                    max_n=$n
                fi
            fi
        done < <(find "$SPECS_DIR" -name 'fn-*.md' -type f -print0 2>/dev/null)
    fi
    
    local next_n=$((max_n + 1))
    
    # Slugify idea text
    local slug=$(echo "$idea_text" | tr '[:upper:]' '[:lower:]' | tr ' _' '-' | tr -dc 'a-z0-9\n-' | sed 's/^-\+//;s/-\+$//')
    
    # Construct spec ID
    local spec_id="fn-${next_n}-${slug}.md"
    
    # Output result
    echo "$spec_id"
    
    # Also set variables for caller
    export next_n="$next_n"
    export slug="$slug"
    export spec_id="$spec_id"
}

# If script is executed directly (not sourced), run the function
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    if [ $# -gt 0 ]; then
        generate_spec_id "$1"
    else
        echo "Usage: generate-spec-id.sh <idea-text>" >&2
        exit 1
    fi
fi
