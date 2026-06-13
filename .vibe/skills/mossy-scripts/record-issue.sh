#!/bin/bash
# record-issue.sh - Record tool errors and problems for mossy skills
# Usage: Call directly: ./record-issue.sh --skill X --error-type Y ...
# Output: Success message on stdout, errors on stderr

set -o pipefail

# Sourcing guard - must be called directly, not sourced
if [ "${BASH_SOURCE[0]}" != "${0}" ]; then
    echo "Error: This script must be called directly, not sourced" >&2
    exit 1
fi

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
# Main - Handle direct script execution with argument parsing
# =============================================================================
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

# Validate required arguments
if [ -z "$SKILL" ] || [ -z "$ERROR_TYPE" ] || [ -z "$ERROR_MSG" ]; then
    echo "ERROR: Missing required arguments" >&2
    echo "Use --help for usage information" >&2
    exit 1
fi

# Ensure issues directory exists
ensure_issues_dir

# Check if we have too many issues
issue_count=$(find "$ISSUES_DIR" -name "*.md" -type f 2>/dev/null | grep -v README | wc -l)
if [ "$issue_count" -ge "$MAX_ISSUES" ]; then
    echo "WARNING: Maximum issue count ($MAX_ISSUES) reached. Not recording issue." >&2
    exit 1
fi

# Generate unique ID
issue_id=$(generate_issue_id "$SKILL" "$ERROR_TYPE")
filename="$ISSUES_DIR/${issue_id}.md"

# Get current timestamp in ISO format
iso_timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Create the issue file
{
echo "# Issue: ${ERROR_MSG%%$'\n'*}"
echo ""
echo "**ID:** ${issue_id}"
echo "**Skill:** ${SKILL}"
echo "**Timestamp:** ${iso_timestamp}"
echo "**Severity:** ${SEVERITY_DEFAULT}"
echo "**Status:** open"
echo "**Error Type:** ${ERROR_TYPE}"
echo ""
echo "## Tool Invocation"
echo ""
echo "timestamp: ${iso_timestamp}"

# Add tool information if provided
if [ -n "$TOOL" ]; then
    echo "tool: ${TOOL}"
    if [ -n "$TARGET" ]; then
        echo "target: ${TARGET}"
    fi
else
    echo "tool: N/A"
fi

echo ""
echo "## Error Log"
echo ""
echo "${ERROR_MSG}"
echo ""
echo "## Problem Description"
echo ""
echo "${ERROR_MSG%%$'\n'*}"
echo ""
echo "## Context"
echo ""
echo "${CONTEXT}"
echo ""
echo "## Reproduction Steps"
echo ""
echo "1. Skill: ${SKILL}"
echo "2. Error Type: ${ERROR_TYPE}"

if [ -n "$TOOL" ]; then
    echo "3. Tool: ${TOOL}"
    if [ -n "$TARGET" ]; then
        echo "4. Target: ${TARGET}"
    fi
fi

echo ""
echo "## Impact"
echo ""
echo "- Skill execution may have been interrupted"
echo "- Task may require manual intervention"
echo ""
echo "## Resolution Notes"
echo ""
echo "[TBD - To be filled when issue is resolved]"
echo ""
echo "## Related Issues"
echo ""
echo "- None known"
} > "$filename"

# Make file readable
chmod 644 "$filename"

# Update README index
update_issues_index "$issue_id" "${ERROR_MSG%%$'\n'*}" "$SKILL" "$ERROR_TYPE" "$filename"

echo "Success: Issue recorded: $filename"
exit 0
