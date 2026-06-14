#!/bin/bash

# test_grammar_validation.sh - Automated tests for grammar validation (fn-46)
# Tests the validate_description_grammar function in mossy-skill.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source the mossy-skill.sh to get the validate_description_grammar function
source "$SCRIPT_DIR/mossy-skill.sh" 2>/dev/null

# Track test results
PASSED=0
FAILED=0
TOTAL=0

print_section() {
    echo ""
    echo "=== $1 ==="
    echo ""
}

test_validation() {
    local description="$1"
    local expected_result="$2"
    local test_name="$3"
    
    TOTAL=$((TOTAL + 1))
    
    if [ "$expected_result" = "PASS" ]; then
        if validate_description_grammar "$description" >/dev/null 2>&1; then
            echo "✅ PASS: $test_name"
            PASSED=$((PASSED + 1))
            return 0
        else
            echo "❌ FAIL: $test_name"
            echo "   Expected: PASS, Got: FAIL"
            validate_description_grammar "$description" 2>&1 | sed 's/^/   Error: /'
            FAILED=$((FAILED + 1))
            return 1
        fi
    else
        if ! validate_description_grammar "$description" >/dev/null 2>&1; then
            echo "✅ PASS: $test_name"
            PASSED=$((PASSED + 1))
            return 0
        else
            echo "❌ FAIL: $test_name"
            echo "   Expected: FAIL, Got: PASS"
            FAILED=$((FAILED + 1))
            return 1
        fi
    fi
}

print_section "Grammar Validation Tests (fn-46)"

# Test Suite 1: Valid Descriptions
print_section "Test Suite 1: Valid Descriptions"

test_validation "Optimize skill frontmatter descriptions" "PASS" "Simple description"
test_validation "Create and write draft spec" "PASS" "Short without period"
test_validation "Analyze repository for project insights." "PASS" "With period"
test_validation "Generate trigger phrases for skill activation" "PASS" "Longer description"
test_validation "Improve skill frontmatter for better Vibe activation" "PASS" "Action-oriented"
test_validation "A test description" "PASS" "Starts with 'A'"
test_validation "Test" "PASS" "Single word"

# Test Suite 2: Capitalization Errors
print_section "Test Suite 2: Capitalization Errors"

test_validation "optimize skill frontmatter descriptions" "FAIL" "lowercase first letter"
test_validation "create and write draft spec" "FAIL" "lowercase 'c'"
test_validation "123 test description" "FAIL" "starts with number"

# Test Suite 3: Empty/Whitespace
print_section "Test Suite 3: Empty and Whitespace"

test_validation "" "FAIL" "empty string"
test_validation "   " "FAIL" "only spaces"

# Test Suite 4: Double Spaces
print_section "Test Suite 4: Double Spaces"

test_validation "Optimize  skill frontmatter" "FAIL" "between words"
test_validation "Test   description" "FAIL" "multiple spaces"

# Test Suite 5: Unmatched Quotes
print_section "Test Suite 5: Unmatched Quotes"

test_validation 'Optimize "skill frontmatter' "FAIL" "unclosed double quote"
test_validation "Optimize 'skill frontmatter" "FAIL" "unclosed single quote"
test_validation 'Optimize "skill" frontmatter' "PASS" "matched quotes"

# Test Suite 6: Redundancy
print_section "Test Suite 6: Redundancy Detection"

test_validation "for better activation for better activation" "FAIL" "repeated phrase"
test_validation "Test Test" "PASS" "repeated word capitalized"

# Test Suite 7: Long Description Punctuation
print_section "Test Suite 7: Long Description Punctuation"

test_validation "This is a very long description that has more than ten words and no punctuation at the end" "FAIL" "10+ words no punctuation"
test_validation "Short description here" "PASS" "short no punctuation OK"
test_validation "This is a long description with proper punctuation." "PASS" "10+ words with punctuation"

# Test Suite 8: Existing Skill Descriptions
print_section "Test Suite 8: Existing Skill Descriptions"

test_validation "Create and write draft spec" "PASS" "mossy-idea description"

# Summary
echo ""
echo "=========================================="
echo "Test Summary"
echo "=========================================="
echo "Total:  $TOTAL"
echo "Passed: $PASSED"
echo "Failed: $FAILED"
echo ""

if [ $FAILED -eq 0 ]; then
    echo "🎉 All tests passed!"
    exit 0
else
    echo "⚠️  Some tests failed"
    exit 1
fi
