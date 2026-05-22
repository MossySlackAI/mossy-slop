#!/bin/bash
# ensure_issues_dir - Create .flow/issues/ if it doesn't exist
# =============================================================================
ensure_issues_dir() {
    if [ ! -d "$ISSUES_DIR" ]; then
        mkdir -p "$ISSUES_DIR"
        # Create a README to explain the directory
        cat > "$ISSUES_DIR/README.md" << 'EOF'
# Recorded Issues

This directory contains automatically recorded issues from mossy skill execution.
Each file represents a problem encountered during tool use or skill operation.

## Issue File Format

Each issue file follows this structure:
- **Naming**: `<date>-<time>-<skill>-<error-type>-<sequence>.md`
- **Content**: Tool invocation, error log, problem description, context

## Index

EOF
        chmod 644 "$ISSUES_DIR/README.md"
    fi
}
=======
# =============================================================================
# ensure_issues_dir - Create .flow/issues/ if it doesn't exist
# =============================================================================
ensure_issues_dir() {
    if [ ! -d "$ISSUES_DIR" ]; then
        mkdir -p "$ISSUES_DIR"
    fi
    
    # Ensure README.md exists with Index section
    if [ ! -f "$ISSUES_DIR/README.md" ] || ! grep -q "## Index" "$ISSUES_DIR/README.md"; then
        cat > "$ISSUES_DIR/README.md" << 'EOF'
# Recorded Issues

This directory contains automatically recorded issues from mossy skill execution.
Each file represents a problem encountered during tool use or skill operation.

## Issue File Format

Each issue file follows this structure:
- **Naming**: `<date>-<time>-<skill>-<error-type>-<sequence>.md`
- **Content**: Tool invocation, error log, problem description, context

## Index

EOF
        chmod 644 "$ISSUES_DIR/README.md"
    fi
}record-issue.sh - Record tool errors and problems for mossy skills
# Usage: source this file, then call record_issue function
# Or run directly: ./record-issue.sh --skill X --error-type Y ...

set -o pipefail

# =============================================================================
# CONFIGURATION
# =============================================================================
ISSUES_DIR=".flow/issues"
MAX_ISSUES=1000  # Prevent runaway issue creation
SEVERITY_DEFAULT="medium"

# =============================================================================
# ensure_issues_dir - Create .flow/issues/ if it doesn't exist
# =============================================================================
ensure_issues_dir() {
    if [ ! -d "$ISSUES_DIR" ]; then
        mkdir -p "$ISSUES_DIR"
        # Create a README to explain the directory
        cat > "$ISSUES_DIR/README.md" << 'EOF'
# Recorded Issues

This directory contains automatically recorded issues from mossy skill execution.
Each file represents a problem encountered during tool use or skill operation.

## Issue File Format

Each issue file follows this structure:
- **Naming**: `<date>-<time>-<skill>-<error-type>-<sequence>.md`
- **Content**: Tool invocation, error log, problem description, context

## Index

EOF
        chmod 644 "$ISSUES_DIR/README.md"
    fi
}

# =============================================================================
# generate_issue_id - Create unique issue identifier
# =============================================================================
generate_issue_id() {
    local skill="$1"
    local error_type="$2"
    local timestamp
    timestamp=$(date +"%Y%m%d-%H%M%S")
    
    # Count existing issues for this skill+type today
    local pattern="${timestamp%%-*}-*-${skill}-${error_type}-*.md"
    local count
    count=$(find "$ISSUES_DIR" -name "$pattern" -type f 2>/dev/null | wc -l)
    
    # Zero-pad count to 3 digits
    printf "%s-%s-%s-%s-%03d" "$timestamp" "$skill" "$error_type" "${timestamp##*-}" "$count"
}

# =============================================================================
# record_issue - Main function to record an issue
# Arguments:
#   $1 - skill name (e.g., mossy-work)
#   $2 - error type (tool-error, validation-error, logic-error, resource-error)
#   $3 - tool invoked (optional, e.g., read_file, grep)
#   $4 - target/path (optional, e.g., src/module.py)
#   $5 - error message (the actual error)
#   $6 - context (what was being attempted)
# =============================================================================
record_issue() {
    local skill="$1"
    local error_type="$2"
    local tool="$3"
    local target="$4"
    local error_msg="$5"
    local context="$6"
    
    # Validate required arguments
    if [ -z "$skill" ] || [ -z "$error_type" ] || [ -z "$error_msg" ]; then
        echo "ERROR: record_issue requires skill, error_type, and error_msg" >&2
        echo "Usage: record_issue SKILL ERROR_TYPE [TOOL] [TARGET] ERROR_MSG CONTEXT" >&2
        return 1
    fi
    
    ensure_issues_dir
    
    # Check if we have too many issues
    local issue_count
    issue_count=$(find "$ISSUES_DIR" -name "*.md" -type f 2>/dev/null | grep -v README | wc -l)
    if [ "$issue_count" -ge "$MAX_ISSUES" ]; then
        echo "WARNING: Maximum issue count ($MAX_ISSUES) reached. Not recording issue." >&2
        return 1
    fi
    
    # Generate unique ID
    local issue_id
    issue_id=$(generate_issue_id "$skill" "$error_type")
    local filename="$ISSUES_DIR/${issue_id}.md"
    
    # Escape newlines for here-doc (replace with literal \n)
    error_msg=$(echo "$error_msg" | sed 's/$/\\n/g')
    context=$(echo "$context" | sed 's/$/\\n/g')
    
    # Get current timestamp in ISO format
    local iso_timestamp
    iso_timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    # Create the issue file
    cat > "$filename" << EOF
# Issue: ${error_msg%%\\n*}

**ID:** ${issue_id}
**Skill:** ${skill}
**Timestamp:** ${iso_timestamp}
**Severity:** ${SEVERITY_DEFAULT}
**Status:** open
**Error Type:** ${error_type}

## Tool Invocation

timestamp: ${iso_timestamp}
EOF
    
    # Add tool information if provided
    if [ -n "$tool" ]; then
        cat >> "$filename" << EOF
tool: ${tool}
EOF
        if [ -n "$target" ]; then
            cat >> "$filename" << EOF
target: ${target}
EOF
        fi
    else
        cat >> "$filename" << EOF
tool: N/A
EOF
    fi
    
    cat >> "$filename" << EOF

## Error Log

${error_msg}

## Problem Description

${error_msg%%\\n*}

## Context

${context}

## Reproduction Steps

1. Skill: ${skill}
2. Error Type: ${error_type}
EOF
    
    if [ -n "$tool" ]; then
        cat >> "$filename" << EOF
3. Tool: ${tool}
EOF
        if [ -n "$target" ]; then
            cat >> "$filename" << EOF
4. Target: ${target}
EOF
        fi
    fi
    
    cat >> "$filename" << EOF

## Impact

- Skill execution may have been interrupted
- Task may require manual intervention

## Resolution Notes

[TBD - To be filled when issue is resolved]

## Related Issues

- None known
EOF
    
    # Make file readable
    chmod 644 "$filename"
    
    # Update README index
    update_issues_index "$issue_id" "${error_msg%%\\n*}" "$skill" "$error_type" "$filename"
    
    echo "Issue recorded: $filename"
    return 0
}

# =============================================================================
# update_issues_index - Add entry to README.md
# =============================================================================
update_issues_index() {
    local issue_id="$1"
    local description="$2"
    local skill="$3"
    local error_type="$4"
    local filename="$5"
    
    local readme="$ISSUES_DIR/README.md"
    
    # Check if README exists and has the Index section
    if [ -f "$readme" ] && grep -q "## Index" "$readme"; then
        # Insert before the first empty line after ## Index
        local temp_file
        temp_file=$(mktemp)
        
        awk -v issue="- [$issue_id]($filename): $description ($skill/$error_type)" '
        /^## Index/ { print; in_index=1; next }
        in_index && /^$/ && !done { print issue; print ""; done=1 }
        { print }
        ' "$readme" > "$temp_file"
        
        mv "$temp_file" "$readme"
    fi
}

# =============================================================================
# Main - Handle direct script execution
# =============================================================================
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    # Script is being executed directly, not sourced
    
    # Parse command line arguments
    SKILL=""
    ERROR_TYPE=""
    TOOL=""
    TARGET=""
    ERROR_MSG=""
    CONTEXT=""
    
    while [ $# -gt 0 ]; do
        case "$1" in
            --skill)
                SKILL="$2"
                shift 2
                ;;
            --error-type)
                ERROR_TYPE="$2"
                shift 2
                ;;
            --tool)
                TOOL="$2"
                shift 2
                ;;
            --target)
                TARGET="$2"
                shift 2
                ;;
            --error|-e)
                # Collect remaining args as error message
                ERROR_MSG="$2"
                shift 2
                while [ $# -gt 0 ]; do
                    ERROR_MSG="$ERROR_MSG $1"
                    shift
                done
                ;;
            --context|-c)
                CONTEXT="$2"
                shift 2
                ;;
            --help|-h)
                cat << 'HELP'
Usage: record-issue.sh [OPTIONS]

Record a tool error or problem for mossy skills.

Options:
  --skill SKILL          Skill name (e.g., mossy-work)
  --error-type TYPE     Error type: tool-error, validation-error, logic-error, resource-error
  --tool TOOL           Tool that failed (e.g., read_file, grep)
  --target TARGET       Target path or resource
  --error ERROR         Error message or log
  --context CONTEXT     Context/what was being attempted
  --help, -h            Show this help

Example:
  ./record-issue.sh --skill mossy-work --error-type tool-error \
    --tool read_file --target src/module.py \
    --error "File not found: No such file or directory" \
    --context "Attempting to read file during analysis phase"
HELP
                exit 0
                ;;
            *)
                echo "ERROR: Unknown option: $1" >&2
                echo "Use --help for usage information" >&2
                exit 1
                ;;
        esac
    done
    
    if [ -z "$SKILL" ] || [ -z "$ERROR_TYPE" ] || [ -z "$ERROR_MSG" ]; then
        echo "ERROR: Missing required arguments" >&2
        echo "Use --help for usage information" >&2
        exit 1
    fi
    
    record_issue "$SKILL" "$ERROR_TYPE" "$TOOL" "$TARGET" "$ERROR_MSG" "$CONTEXT"
fi
