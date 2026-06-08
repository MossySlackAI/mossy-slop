#!/bin/bash
# test-issue-recording.sh - Test script to validate error recording across all mossy skills
#
# This script verifies that:
# 1. All skills have Error Recording sections in their SKILL.md files
# 2. The record-issue.sh script works correctly
# 3. Issue files are created with the correct format
#
# Usage: ./scripts/test-issue-recording.sh [--cleanup]
#   --cleanup: Remove test issue files after testing

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
ISSUES_DIR="$REPO_ROOT/.flow/issues"
TEST_SKILL="mossy-test-recording"
CLEANUP=false

# Parse arguments
while [ $# -gt 0 ]; do
    case "$1" in
        --cleanup)
            CLEANUP=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

echo "==================================="
echo "Testing Issue Recording System"
echo "==================================="
echo ""

# Test 1: Verify all skills have Error Recording sections
echo "Test 1: Checking all skills have Error Recording sections..."
COUNT=0
for skill_dir in "$REPO_ROOT/.vibe/skills/mossy-"* ; do
    if [ -d "$skill_dir" ]; then
        skill_file="$skill_dir/SKILL.md"
        if [ -f "$skill_file" ] && grep -q "## Error Recording" "$skill_file"; then
            COUNT=$((COUNT + 1))
            echo "  ✓ $(basename "$skill_dir")/SKILL.md"
        fi
    fi
done


echo ""
if [ $COUNT -ge 7 ]; then
    echo "✅ PASS: Found Error Recording in $COUNT files (expected >= 7)"
else
    echo "❌ FAIL: Only found Error Recording in $COUNT files (expected >= 7)"
    exit 1
fi

# Test 2: Verify record-issue.sh script exists and is executable
echo ""
echo "Test 2: Checking record-issue.sh script..."
if [ -x "$REPO_ROOT/.vibe/skills/mossy-scripts/record-issue.sh" ]; then
    echo "  ✓ record-issue.sh exists and is executable"
    echo "✅ PASS"
else
    echo "  ✗ record-issue.sh not found or not executable"
    echo "❌ FAIL"
    exit 1
fi

# Test 3: Test recording an issue
echo ""
echo "Test 3: Testing issue recording..."
cd "$REPO_ROOT"

# Capture the output to get the filename
OUTPUT=$($REPO_ROOT/.vibe/skills/mossy-scripts/record-issue.sh \
    --skill "$TEST_SKILL" \
    --error-type "tool-error" \
    --tool "read_file" \
    --target "nonexistent.txt" \
    --error "Test: File not found" \
    --context "Testing issue recording script" 2>&1)

# Extract filename from output
TEST_ISSUE_FILE=$(echo "$OUTPUT" | grep "Issue recorded:" | sed "s/Issue recorded: //" | tr -d '[:space:]')

if [ -n "$TEST_ISSUE_FILE" ] && [ -f "$TEST_ISSUE_FILE" ]; then
    echo "  ✓ Issue file created: $(basename "$TEST_ISSUE_FILE")"
    
    # Verify issue file contents
    if grep -q "Skill: $TEST_SKILL" "$TEST_ISSUE_FILE" && \
       grep -q "Error Type: tool-error" "$TEST_ISSUE_FILE" && \
       grep -q "tool: read_file" "$TEST_ISSUE_FILE" && \
       grep -q "target: nonexistent.txt" "$TEST_ISSUE_FILE" && \
       grep -q "Test: File not found" "$TEST_ISSUE_FILE"; then
        echo "  ✓ Issue file contains all required fields"
        echo "✅ PASS"
    else
        echo "  ✗ Issue file missing required fields"
        echo "❌ FAIL"
        exit 1
    fi
else
    echo "  ✗ Issue file not created"
    echo "❌ FAIL"
    exit 1
fi

# Test 4: Verify README.md is updated
echo ""
echo "Test 4: Checking README.md index..."
# Ensure README exists by running record-issue.sh again if needed
if [ ! -f "$ISSUES_DIR/README.md" ]; then
    $REPO_ROOT/.vibe/skills/mossy-scripts/record-issue.sh \
        --skill "$TEST_SKILL" \
        --error-type "tool-error" \
        --tool "read_file" \
        --target "nonexistent2.txt" \
        --error "Test: Second file not found" \
        --context "Creating README" >/dev/null 2>&1
    
    TEST_ISSUE_FILE2=$(ls -t "$ISSUES_DIR"/*.md | head -1)
fi

if [ -f "$ISSUES_DIR/README.md" ] && grep -q "## Index" "$ISSUES_DIR/README.md"; then
    echo "  ✓ README.md exists with Index section"
    echo "✅ PASS"
else
    echo "  ✗ README.md not properly configured"
    echo "❌ FAIL"
    exit 1
fi

# Test 5: Count total issues
echo ""
echo "Test 5: Counting total issues..."
ISSUE_COUNT=$(find "$ISSUES_DIR" -name "*.md" -not -name "README.md" -not -name "ISSUE_TEMPLATE.md" | wc -l)
echo "  ✓ Total issues in .flow/issues/: $ISSUE_COUNT"
if [ $ISSUE_COUNT -gt 0 ]; then
    echo "✅ PASS"
else
    echo "❌ FAIL: No issues found"
    exit 1
fi

# Summary
echo ""
echo "==================================="
echo "✅ All tests passed!"
echo "==================================="
echo ""
echo "Summary:"
echo "  - Error Recording sections: $COUNT files"
echo "  - record-issue.sh: Working"
echo "  - Issue creation: Working"
echo "  - README.md index: Working"
echo "  - Total issues: $ISSUE_COUNT"
echo ""

# Cleanup test files if requested
if [ "$CLEANUP" = true ]; then
    echo "Cleaning up test issue files..."
    find "$ISSUES_DIR" -name "*${TEST_SKILL}*" -type f -delete 2>/dev/null || true
    echo "✓ Test files cleaned up"
fi

echo ""
echo "Test script completed successfully!"
