#!/bin/bash

# mossy-skill.sh - Optimize skill frontmatter descriptions
# 
# Current implementation: Conservative algorithm that preserves capitalization
# and avoids parsing errors.
# 
# Future improvement: See fn-28 (.flow/specs/fn-28-improve-mossy-skill-with-subagent-generated-rewordings.md)
# which proposes using subagent-generated high-temperature rewordings for better results.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RECORD_ISSUE="$SCRIPT_DIR/../mossy-scripts/record-issue.sh"

record_issue() {
    if [ -f "$RECORD_ISSUE" ]; then
        "$RECORD_ISSUE" $*
    else
        # no-op
        return 0;
    fi
}

if [ ! -f "$RECORD_ISSUE" ]; then
    echo "⚠️  record-issue.sh not found, error recording disabled"
fi
    

# Main entry point - invoked by /mossy:skill command
main() {
    # Validate prerequisites
    if [ ! -d ".vibe/skills/" ]; then
        echo "❌ .vibe/skills/ directory not found"
        record_issue --skill "mossy-skill" --error-type "resource-error" --context "directory_check" \
            --error "Required skills directory not found" "Pattern: ${1:-*}" || true
        return 1
    fi
    
    local pattern="${1:-*}"  # Default: optimize all skills
    
    # Step 1: Skill Selection
    echo "🔍 Finding skills matching pattern: $pattern"
    local skill_dirs=()
    
    if [ "$pattern" = "" ] || [ "$pattern" = "*" ] || [ "$pattern" = "all" ]; then
        # Find all skill directories with SKILL.md files
        while IFS= read -r -d '' dir; do
            if [ -f "$dir/SKILL.md" ]; then
                skill_dirs+=("$dir")
            fi
        done < <(find .vibe/skills/ -type d -print0 | sort -z)
    else
        # Find skills matching the pattern
        while IFS= read -r -d '' dir; do
            local dirname=$(basename "$dir")
            # Support glob patterns
            if [[ "$dirname" == $pattern ]]; then
                # Only include if it has a SKILL.md file
                if [ -f "$dir/SKILL.md" ]; then
                    skill_dirs+=("$dir")
                fi
            fi
        done < <(find .vibe/skills/ -type d -print0 | sort -z)
    fi
    
    if [ ${#skill_dirs[@]} -eq 0 ]; then
        echo "❌ No skills found matching pattern: $pattern"
        record_issue --skill "mossy-skill" --error-type "logic-error" --context "pattern_matching" \
            --error "No skills matched the specified pattern" "Pattern: $pattern" || true
        return 1
    fi
    
    # Validate pattern is reasonable
    if [[ "$pattern" == *".."* ]] || [[ "$pattern" == *"/"* ]]; then
        echo "❌ Invalid pattern: $pattern (contains path separators)"
        record_issue --skill "mossy-skill" --error-type "validation-error" --context "pattern_validation" \
            --error "Pattern contains invalid characters" "Pattern: $pattern" || true
        return 1
    fi
    
    echo "📊 Found ${#skill_dirs[@]} skills to optimize"
    
    # Step 2-6: Process each skill
    for skill_dir in "${skill_dirs[@]}"; do
        optimize_skill_description "$skill_dir"
    done
    
    echo "✅ All skill optimizations complete"
}

# Optimize a single skill's description
optimize_skill_description() {
    local skill_dir="$1"
    local skill_name=$(basename "$skill_dir")
    local skill_file="${skill_dir}/SKILL.md"
    
    echo "🎯 Optimizing skill: $skill_name"
    
    # Validate skill file exists
    if [ ! -f "$skill_file" ]; then
        echo "❌ Skill file not found: $skill_file"
        record_issue --skill "mossy-skill" --error-type "resource-error" record_issue --skill "mossy-skill" --context "file_existence" \
            --error "Skill file not found" "Pattern: $pattern" || true
        return 1
    fi
    
    # Read current description from frontmatter
    local current_description=$(extract_frontmatter_field "$skill_file" "description")
    if [ -z "$current_description" ]; then
        echo "❌ No description found in frontmatter: $skill_file"
        record_issue --skill "mossy-skill" --error-type "validation-error" record_issue --skill "mossy-skill" --context "frontmatter_parsing" \
            --error "No description field in frontmatter" "Pattern: $pattern" || true
        return 1
    fi
    
    echo "  Current description: $current_description"
    
    # Step 2: Generate prompts
    echo "  📝 Generating sample prompts..."
    local prompts=()
    while IFS= read -r prompt; do
        prompts+=("$prompt")
    done < <(generate_prompts_from_skill "$skill_dir")
    
    local prompt_count=${#prompts[@]}
    if [ $prompt_count -eq 0 ]; then
        echo "  ⚠️  No prompts generated for $skill_name"
        prompts=("use $skill_name" "run $skill_name" "help with $skill_name")
        prompt_count=3
    fi
    echo "  Generated $prompt_count sample prompts"
    
    # Step 3: Baseline measurement
    echo "  📊 Measuring baseline activation..."
    local baseline_result=$(vibe_test_prompts "$current_description" "${prompts[@]}")
    echo "  Baseline: $baseline_result"
    
    # Step 4: Generate optimized description
    echo "  🔧 Optimizing description..."
    local skill_content=$(cat "$skill_file")
    local optimized_description=$(optimize_description "$current_description" "$skill_content" "${prompts[@]}")
    
    if [ "$optimized_description" = "$current_description" ]; then
        echo "  ℹ️  No improvement possible for $skill_name"
        return 0
    fi
    
    echo "  Optimized: $optimized_description"
    
    # Step 5: Validation
    echo "  🛡️  Validating optimization..."
    
    # Test improved activation
    local improved_result=$(vibe_test_prompts "$optimized_description" "${prompts[@]}")
    echo "  Improvement: $improved_result"
    
    # Test false activations
    if ! test_false_activations "$optimized_description" "$current_description" "$skill_name" >/dev/null 2>&1; then
        echo "  ❌ Optimization rejected: False activations detected"
        record_issue --skill "mossy-skill" --error-type "logic-error" --context "false_activation" \
            --error "Optimization introduced false activations" "Pattern: $pattern" || true
        return 1
    fi
    
    # Step 6: Apply optimization
    echo "  ✅ Applying optimization..."
    local backup_file="${skill_file}.mossy-skill-backup"
    cp "$skill_file" "$backup_file"
    
    # Modify the description in the frontmatter
    # Use | as delimiter to avoid issues with / in the description
    # Only replace the first occurrence (to avoid modifying body content)
    # Use sed -i to modify in place and preserve file endings
    sed -i "0,/^description: /s|^description: .*|description: \"${optimized_description}\"|" "$skill_file"
    
    echo "  🎉 Successfully optimized $skill_name"
    echo "  Backup saved to: $backup_file"
}

# Extract a frontmatter field from a markdown file
extract_frontmatter_field() {
    local file="$1"
    local field="$2"
    local in_frontmatter=false
    local result=""
    
    while IFS= read -r line; do
        # Check for frontmatter start
        if [ "$line" = "---" ] && [ "$in_frontmatter" = false ]; then
            in_frontmatter=true
            continue
        fi
        
        # Check for frontmatter end
        if [ "$line" = "---" ] && [ "$in_frontmatter" = true ]; then
            break
        fi
        
        # Extract field value
        if [ "$in_frontmatter" = true ] && [[ "$line" == ${field}:* ]]; then
            result=$(echo "$line" | sed "s/^${field}: //" | sed 's/^[\"'\'']//' | sed 's/[\"'\'']$//')
            break
        fi
    done < "$file"
    
    echo "$result"
}

# Pattern matching helper - expand glob patterns
expand_pattern() {
    local pattern="$1"
    local base_dir="$2"
    local results=()
    
    # Use find with pattern matching
    while IFS= read -r -d '' match; do
        results+=("$match")
    done < <(find "$base_dir" -type d -name "$pattern" -print0 2>/dev/null)
    
    # If no matches and pattern doesn't contain wildcards, try exact match
    if [ ${#results[@]} -eq 0 ] && [[ ! "$pattern" == *\** ]] && [[ ! "$pattern" == *\?* ]]; then
        if [ -d "${base_dir}/${pattern}" ]; then
            results+=("${base_dir}/${pattern}")
        fi
    fi
    
    printf '%s\n' "${results[@]}"
}

# Vibe activation simulation - tests if a prompt would activate a skill based on description
# Returns 0 (success) if activation is predicted, 1 otherwise
vibe_simulate_activation() {
    local prompt="$1"
    local description="$2"
    local confidence="low"
    
    # Normalize both to lowercase for case-insensitive matching
    local prompt_lower=$(echo "$prompt" | tr '[:upper:]' '[:lower:]')
    local description_lower=$(echo "$description" | tr '[:upper:]' '[:lower:]')
    
    # 1. Exact substring match (highest confidence)
    if [[ "$prompt_lower" == *"$description_lower"* || "$description_lower" == *"$prompt_lower"* ]]; then
        echo "activation: true, confidence: high, reason: exact_substring_match"
        return 0
    fi
    
    # 2. Word boundary matching - check if description appears as whole words in prompt
    local desc_words=$(echo "$description_lower" | tr ' ' '\n' | grep -E '^.{3,}$')
    local prompt_words=$(echo "$prompt_lower" | tr ' ' '\n' | grep -E '^.{3,}$')
    
    local word_matches=0
    for word in $desc_words; do
        if echo "$prompt_words" | grep -q "^${word}$"; then
            word_matches=$((word_matches + 1))
        fi
    done
    
    # If 50%+ of description words appear in prompt, consider it a match
    local desc_word_count=$(echo "$desc_words" | wc -l)
    if [ $desc_word_count -gt 0 ] && [ $word_matches -ge $((desc_word_count / 2)) ]; then
        echo "activation: true, confidence: medium, reason: keyword_match_${word_matches}_of_${desc_word_count}"
        return 0
    fi
    
    # 3. Key action verb matching
    local action_verbs=("optimize" "analyze" "create" "modify" "test" "validate" "review" "improve" "generate" "execute" "plan" "work" "finish" "scan" "refactor")
    
    for verb in "${action_verbs[@]}"; do
        if [[ "$description_lower" == *"$verb"* ]] && [[ "$prompt_lower" == *"$verb"* ]]; then
            echo "activation: true, confidence: medium, reason: action_verb_match_${verb}"
            return 0
        fi
    done
    
    # No match found
    echo "activation: false, confidence: low, reason: no_match_found"
    return 1
}

# Test a set of prompts against a description and return activation rate
vibe_test_prompts() {
    local description="$1"
    shift
    local prompts=("$@")
    local activated=0
    local total=${#prompts[@]}
    
    for prompt in "${prompts[@]}"; do
        if vibe_simulate_activation "$prompt" "$description" >/dev/null 2>&1; then
            activated=$((activated + 1))
        fi
    done
    
    local rate=$((activated * 100 / total))
    echo "$rate"
    return $((total - activated))  # Return count of failed activations
}

# Generate sample prompts from a skill file
generate_prompts_from_skill() {
    local skill_dir="$1"
    local skill_name=$(basename "$skill_dir")
    local skill_file="${skill_dir}/SKILL.md"
    local prompts=()
    
    # Check if skill file exists
    if [ ! -f "$skill_file" ]; then
        echo "ERROR: Skill file not found: $skill_file" >&2
        return 1
    fi
    
    # Read the skill file
    local skill_content=$(cat "$skill_file")
    
    # Extract current description from frontmatter
    
    # Method 1: From skill name (variations)
    local clean_name=$(echo "$skill_name" | sed 's/^mossy-//')
    prompts+=("${clean_name}")
    prompts+=("use ${clean_name}")
    prompts+=("run ${clean_name}")
    prompts+=("execute ${clean_name}")
    
    # Method 2: From description (extract action + object patterns)
    local desc_lower=$(echo "$description" | tr '[:upper:]' '[:lower:]')
    
    # Extract verbs and objects from description
    local first_word=$(echo "$description" | awk '{print $1}')
    local second_word=$(echo "$description" | awk '{print $2}')
    
    if [ -n "$first_word" ] && [ -n "$second_word" ]; then
        prompts+=("${first_word} ${second_word}")
        prompts+=("please ${first_word} ${second_word}")
        prompts+=("can you ${first_word} ${second_word}")
    fi
    
    # Method 3: From body content - extract ## section headers as potential use cases
    local sections=$(echo "$skill_content" | grep '^## ' | sed 's/^## //')
    while IFS= read -r section; do
        if [ -n "$section" ]; then
            prompts+=("${section}")
            prompts+=("how to ${section}")
        fi
    done <<< "$sections"
    
    # Method 4: Common usage patterns
    prompts+=("help with ${clean_name}")
    prompts+=("${clean_name} help")
    prompts+=("what does ${clean_name} do")
    
    # Remove duplicates and empty entries
    local unique_prompts=()
    for prompt in "${prompts[@]}"; do
        if [ -n "$prompt" ] && ! printf '%s\n' "${unique_prompts[@]}" | grep -q "^${prompt}$"; then
            unique_prompts+=("$prompt")
        fi
    done
    
    # Output prompts (max 20)
    local count=0
    for prompt in "${unique_prompts[@]}"; do
        if [ $count -ge 20 ]; then break; fi
        echo "$prompt"
        count=$((count + 1))
    done
}

# Generate prompts from skill directory
# Usage: generate_sample_prompts_for_skill ".vibe/skills/mossy-analyze"
generate_sample_prompts_for_skill() {
    local skill_dir="$1"
    generate_prompts_from_skill "$skill_dir"
}

# TODO: fn-28 Architecture Split
# ============================
# This function (optimize_description) will be moved to SKILL.md orchestration
# as part of fn-28. For now, keeping the conservative implementation.
# 
# Future: SKILL.md will use task tool to invoke subagent for description generation.
# This bash script will call SKILL.md logic for candidate generation.
# 
# See: .flow/specs/fn-28-improve-mossy-skill-with-subagent-generated-rewordings.md
#
# Apply optimization criteria to improve a description
# Returns optimized description
# 
# Note: For better results, consider using subagent-generated rewordings (see fn-28).
# This implementation is a conservative fallback that preserves capitalization
# and avoids the bugs in the original verb-removal approach.
# 
# Architecture: This function will be replaced by calls to SKILL.md subagent orchestration
# once fn-28 tasks 2-8 are complete.
optimize_description() {
    local original_description="$1"
    local skill_content="$2"
    shift 2
    local prompts=("$@")
    
    # First, ensure original description preserves capitalization
    # Extract first character and capitalize it properly
    local first_char=$(echo "$original_description" | cut -c1)
    local rest_desc=$(echo "$original_description" | cut -c2-)
    
    # If first character is lowercase letter, capitalize it
    if [[ "$first_char" =~ [a-z] ]]; then
        first_char=$(echo "$first_char" | tr '[:lower:]' '[:upper:]')
        original_description="${first_char}${rest_desc}"
    fi
    
    # Check if description already mentions Vibe or activation
    local desc_lower=$(echo "$original_description" | tr '[:upper:]' '[:lower:]')
    local has_vibe=1
    echo "$desc_lower" | grep -qi "vibe\|activation\|auto-trigger" && has_vibe=0
    
    # Generate candidate descriptions
    local candidates=()
    
    # Candidate 1: Original description (baseline)
    candidates+=("$original_description")
    
    # Candidate 2: Add activation context (only if not already present)
    if [ "$has_vibe" -eq 1 ]; then
        candidates+=("${original_description} for better Vibe auto-activation")
    fi
    
    # Candidate 3: Make more imperative/action-oriented
    # Only prepend verb if the description doesn't already start with one
    local first_word=$(echo "$original_description" | awk '{print $1}')
    local action_verbs=("Optimize" "Analyze" "Create" "Modify" "Test" "Validate" "Review" "Improve" "Generate" "Execute" "Plan" "Work" "Finish" "Scan" "Refactor")
    local found_verb=""
    
    for verb in "${action_verbs[@]}"; do
        if [[ "$first_word" == "$verb" ]] || [[ "$first_word" == "${verb,,}" ]]; then
            found_verb="$verb"
            break
        fi
    done
    
    # If first word is NOT already an action verb, try to prepend an appropriate one
    # But only if it makes semantic sense - avoid redundant phrasing
    if [ -z "$found_verb" ]; then
        # Check for common patterns - but be conservative
        # "Static analysis" - first word is "Static" (adjective), contains "scan" or "analysis"
        # In this case, the description is already fine, don't prepend
        if echo "$desc_lower" | grep -qi "analysis\|analyze"; then
            # Already describes analysis, no need to prepend "Analyze"
            :
        elif echo "$desc_lower" | grep -qi "review\|check"; then
            candidates+=("Review ${original_description}")
        elif echo "$desc_lower" | grep -qi "create\|generate\|build\|draft"; then
            candidates+=("Create ${original_description}")
        fi
    fi
    
    # Candidate 4: Remove trailing periods for consistency
    local no_period=$(echo "$original_description" | sed 's/\.$//')
    if [ "$no_period" != "$original_description" ]; then
        candidates+=("$no_period")
    fi
    
    # Step: Test each candidate and select the best
    local best_candidate="$original_description"
    local best_rate=0
    
    for candidate in "${candidates[@]}"; do
        # Ensure candidate is properly capitalized
        local cap_candidate=$(echo "$candidate" | awk '{print toupper(substr($0,1,1)) substr($0,2)}')
        
        # Test this candidate against the prompts
        local test_prompts=("${prompts[@]:0:10}")  # Test with first 10 prompts
        local current_rate=$(vibe_test_prompts "$cap_candidate" "${test_prompts[@]}")
        
        if [ "$current_rate" -gt "$best_rate" ] 2>/dev/null; then
            best_rate=$current_rate
            best_candidate="$cap_candidate"
        fi
    done
    
    echo "$best_candidate"
}

# Test if an optimized description introduces false activations
# Returns 0 if safe (no false activations), 1 if unsafe
test_false_activations() {
    local new_description="$1"
    local original_description="$2"
    local skill_name="$3"
    
    # Generate false activation test prompts (prompts for OTHER skills)
    local false_prompts=(
        "create a spec draft"
        "plan the workflow"  
        "review the changes"
        "analyze code quality"
        "execute the tasks"
        "finish the spec"
    )
    
    # Test original description against false prompts (baseline false activations)
    local original_false_rate=$(vibe_test_prompts "$original_description" "${false_prompts[@]}")
    
    # Test new description against false prompts
    local new_false_rate=$(vibe_test_prompts "$new_description" "${false_prompts[@]}")
    
    # If new false activation rate is higher than original, it's unsafe
    if [ "$new_false_rate" -gt "$original_false_rate" ] 2>/dev/null; then
        echo "FAIL: False activations increased from ${original_false_rate}% to ${new_false_rate}%"
        return 1
    fi
    
    return 0
}

# Call main if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi

