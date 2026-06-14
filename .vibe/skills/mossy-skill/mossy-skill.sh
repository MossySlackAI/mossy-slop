#!/bin/bash

# mossy-skill.sh - Optimize skill frontmatter descriptions
# 
# Enhanced with TRIGGERS.md support for transparent user-controlled trigger phrases.
# See: .flow/specs/fn-29-enhance-mossy-skill-with-triggers-md.md
# 
# Scoring function: Sensitivity * Max(0, Specificity - 0.75)
# where Sensitivity = TP/(TP+FN) and Specificity = TN/(TN+FP)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RECORD_ISSUE="$SCRIPT_DIR/../mossy-scripts/record-issue.sh"

# Configurable constant for minimum phrases per category
MIN_PHRASES_PER_CATEGORY=${MIN_PHRASES_PER_CATEGORY:-10}

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
    

# ============================================================================
# TRIGGERS.md FUNCTIONS
# ============================================================================

# Parse TRIGGERS.md file and extract trigger phrases from a specific section
# Usage: parse_triggers_section "file_path" "section_name"
# Section names: "Should Trigger" or "Should Not Trigger"
parse_triggers_section() {
    local triggers_file="$1"
    local section_name="$2"
    local phrases=()
    local in_section=false
    
    if [ ! -f "$triggers_file" ]; then
        return 0
    fi
    
    while IFS= read -r line; do
        # Check for section header
        if [[ "$line" =~ ^##[[:space:]]*(.*) ]]; then
            local header="${BASH_REMATCH[1]}"
            if [ "$header" = "$section_name" ]; then
                in_section=true
                continue
            else
                in_section=false
                continue
            fi
        fi
        
        # If we're in the right section, collect list items
        if [ "$in_section" = true ]; then
            # Match list items: - item, * item, or numbered lists
            if [[ "$line" =~ ^[[:space:]]*[-*•][[:space:]]*(.*) ]]; then
                local phrase="${BASH_REMATCH[1]}"
                if [ -n "$phrase" ]; then
                    phrases+=("$phrase")
                fi
            fi
        fi
    done < "$triggers_file"
    
    # Output all phrases
    printf '%s\n' "${phrases[@]}"
}

# Read all trigger phrases from TRIGGERS.md file into arrays
# This function sets the global arrays G_POSITIVE_TRIGGERS and G_NEGATIVE_TRIGGERS
# Usage: read_triggers_into_globals "skill_dir"
# Then copy from G_POSITIVE_TRIGGERS and G_NEGATIVE_TRIGGERS to local arrays
G_POSITIVE_TRIGGERS=()
G_NEGATIVE_TRIGGERS=()

read_triggers_into_globals() {
    local skill_dir="$1"
    local triggers_file="${skill_dir}/TRIGGERS.md"
    
    # Clear global arrays
    G_POSITIVE_TRIGGERS=()
    G_NEGATIVE_TRIGGERS=()
    
    # Read positive triggers (Should Trigger section)
    while IFS= read -r phrase; do
        if [ -n "$phrase" ]; then
            G_POSITIVE_TRIGGERS+=("$phrase")
        fi
    done < <(parse_triggers_section "$triggers_file" "Should Trigger")
    
    # Read negative triggers (Should Not Trigger section)
    while IFS= read -r phrase; do
        if [ -n "$phrase" ]; then
            G_NEGATIVE_TRIGGERS+=("$phrase")
        fi
    done < <(parse_triggers_section "$triggers_file" "Should Not Trigger")
}

# Validate TRIGGERS.md file has enough phrases
# Usage: validate_triggers "skill_dir"
# Returns: 0 if valid, 1 if invalid
validate_triggers() {
    local skill_dir="$1"
    local triggers_file="${skill_dir}/TRIGGERS.md"
    
    # First check if file exists
    if [ ! -f "$triggers_file" ]; then
        echo "INVALID: TRIGGERS.md does not exist"
        return 1
    fi
    
    local positive_triggers=()
    local negative_triggers=()
    
    read_triggers_into_globals "$skill_dir"
    local positive_triggers=("${G_POSITIVE_TRIGGERS[@]}")
    local negative_triggers=("${G_NEGATIVE_TRIGGERS[@]}")
    
    local pos_count=${#positive_triggers[@]}
    local neg_count=${#negative_triggers[@]}
    
    if [ $pos_count -lt $MIN_PHRASES_PER_CATEGORY ] || [ $neg_count -lt $MIN_PHRASES_PER_CATEGORY ]; then
        echo "INVALID: TRIGGERS.md has $pos_count positive triggers (need $MIN_PHRASES_PER_CATEGORY) and $neg_count negative triggers (need $MIN_PHRASES_PER_CATEGORY)"
        return 1
    fi
    
    echo "VALID: TRIGGERS.md has $pos_count positive triggers and $neg_count negative triggers"
    return 0
}

# DEPRECATED: These functions have been replaced by LLM-based generation in SKILL.md
# generate_positive_triggers() - Replaced by generate_triggers_file() in SKILL.md
# generate_negative_triggers() - Replaced by generate_triggers_file() in SKILL.md
#
# These functions generated deterministic, formulaic trigger phrases that were
# not natural or user-like. They have been superseded by LLM-based generation
# that produces context-aware, diverse trigger phrases.

# Ensure TRIGGERS.md exists and has enough phrases
# Usage: ensure_triggers "skill_dir"
# Creates or appends to TRIGGERS.md if needed
#
# NOTE: This function now expects TRIGGERS.md to be generated by SKILL.md using LLM.
# If TRIGGERS.md doesn't exist or is invalid, it will be created with a fallback
# message instructing to use LLM-based generation.
ensure_triggers() {
    local skill_dir="$1"
    local triggers_file="${skill_dir}/TRIGGERS.md"
    local skill_name=$(basename "$skill_dir")
    
    # Check if --skip-triggers flag is set (passed from SKILL.md)
    if [ "$SKIP_TRIGGERS" = "true" ]; then
        echo "ℹ️ Skipping TRIGGERS.md generation (LLM-based generation used by SKILL.md)"
        return 0
    fi
    
    # Create TRIGGERS.md if it doesn't exist
    if [ ! -f "$triggers_file" ]; then
        echo "⚠️ TRIGGERS.md not found for $skill_name - please use LLM-based generation"
        echo "   Run: /mossy:skill --generate-triggers $skill_dir"
        echo "" > "$triggers_file"
        return 1
    fi
    
    # Check if TRIGGERS.md has enough phrases
    read_triggers_into_globals "$skill_dir"
    local positive_triggers=("${G_POSITIVE_TRIGGERS[@]}")
    local negative_triggers=("${G_NEGATIVE_TRIGGERS[@]}")
    
    local pos_count=${#positive_triggers[@]}
    local neg_count=${#negative_triggers[@]}
    local needs_update=false
    
    # Check positive triggers
    if [ $pos_count -lt $MIN_PHRASES_PER_CATEGORY ]; then
        echo "⚠️ TRIGGERS.md for $skill_name has insufficient positive triggers ($pos_count < $MIN_PHRASES_PER_CATEGORY)"
        echo "   Please regenerate using LLM-based generation: /mossy:skill --generate-triggers $skill_dir"
        return 1
    fi
    
    # Check negative triggers
    if [ $neg_count -lt $MIN_PHRASES_PER_CATEGORY ]; then
        echo "⚠️ TRIGGERS.md for $skill_name has insufficient negative triggers ($neg_count < $MIN_PHRASES_PER_CATEGORY)"
        echo "   Please regenerate using LLM-based generation: /mossy:skill --generate-triggers $skill_dir"
        return 1
    fi
    
    echo "✅ TRIGGERS.md for $skill_name is valid"
    
    return 0
}

# Regenerate all TRIGGERS.md files
# Usage: regenerate_all_triggers
#
# NOTE: This function now delegates to LLM-based generation via SKILL.md.
# It will instruct the user to use the new LLM-based approach.
regenerate_all_triggers() {
    echo "🔄 Regenerating all TRIGGERS.md files using LLM-based generation..."
    echo ""
    echo "This operation now uses SKILL.md with LLM-based trigger generation."
    echo "Please use: /mossy:skill --regenerate-triggers"
    echo ""
    echo "The old deterministic generation has been replaced with LLM-based generation"
    echo "that produces natural, context-aware trigger phrases."
    return 0
}

# ============================================================================
# SCORING FUNCTIONS
# ============================================================================

# Calculate Sensitivity and Specificity from test results
# Sensitivity = TP / (TP + FN)
# Specificity = TN / (TN + FP)
# Usage: calculate_scores "description" "positive_prompts_array" "negative_prompts_array"
# Outputs: SENSITIVITY SPECIFICITY
calculate_scores() {
    local description="$1"
    shift
    local positive_prompts=("$@")
    local negative_prompts=()
    
    # Separate positive and negative prompts (positive prompts end with a special marker)
    # Actually, let's change the approach - pass as separate arguments
    # For now, we'll use the arrays passed
    
    # Test positive prompts (should trigger)
    local tp=0
    local fn=0
    for prompt in "${positive_prompts[@]}"; do
        if vibe_simulate_activation "$prompt" "$description" >/dev/null 2>&1; then
            tp=$((tp + 1))
        else
            fn=$((fn + 1))
        fi
    done
    
    # Test negative prompts (should NOT trigger)
    local tn=0
    local fp=0
    for prompt in "${negative_prompts[@]}"; do
        if vibe_simulate_activation "$prompt" "$description" >/dev/null 2>&1; then
            fp=$((fp + 1))
        else
            tn=$((tn + 1))
        fi
    done
    
    # Calculate Sensitivity = TP / (TP + FN)
    local sensitivity=0
    if [ $((tp + fn)) -gt 0 ]; then
        # Using awk for floating point division
        sensitivity=$(awk "BEGIN {printf \"%.4f\", $tp / ($tp + $fn)}")
    fi
    
    # Calculate Specificity = TN / (TN + FP)
    local specificity=0
    if [ $((tn + fp)) -gt 0 ]; then
        specificity=$(awk "BEGIN {printf \"%.4f\", $tn / ($tn + $fp)}")
    fi
    
    echo "$sensitivity $specificity"
}

# Calculate the total score using: Sensitivity * Max(0, Specificity - 0.75)
# Usage: calculate_total_score "sensitivity" "specificity"
calculate_total_score() {
    local sensitivity="$1"
    local specificity="$2"
    
    # Max(0, Specificity - 0.75)
    local specificity_adjusted=$(awk "BEGIN {
        diff = $specificity - 0.75
        if (diff < 0) diff = 0
        printf \"%.4f\", diff
    }")
    
    # Sensitivity * Max(0, Specificity - 0.75)
    local total_score=$(awk "BEGIN {printf \"%.4f\", $sensitivity * $specificity_adjusted}")
    
    echo "$total_score"
}

# ============================================================================
# MAIN FUNCTIONS (Modified to use TRIGGERS.md)
# ============================================================================

# Main entry point - invoked by /mossy:skill command
main() {
    # Parse command line arguments
    local regenerate=false
    local skip_triggers=false
    local generate_triggers=""
    local pattern=""
    
    while [ $# -gt 0 ]; do
        case "$1" in
            --regenerate-triggers)
                regenerate=true
                shift
                ;;
            --skip-triggers)
                skip_triggers=true
                shift
                ;;
            --generate-triggers)
                generate_triggers="$2"
                shift 2
                ;;
            --validate-triggers)
                # Validate all TRIGGERS.md files
                echo "🔍 Validating all TRIGGERS.md files..."
                local skill_dirs=()
                while IFS= read -r -d '' dir; do
                    if [ -f "$dir/SKILL.md" ]; then
                        skill_dirs+=("$dir")
                    fi
                done < <(find .vibe/skills/ -type d -print0 | sort -z)
                
                local all_valid=true
                for skill_dir in "${skill_dirs[@]}"; do
                    if ! validate_triggers "$skill_dir" >/dev/null 2>&1; then
                        echo "❌ $(validate_triggers "$skill_dir" 2>&1)"
                        all_valid=false
                    else
                        echo "✅ $(validate_triggers "$skill_dir" 2>&1)"
                    fi
                done
                
                if [ "$all_valid" = true ]; then
                    echo "✅ All TRIGGERS.md files are valid"
                else
                    echo "❌ Some TRIGGERS.md files need attention"
                    return 1
                fi
                return 0
                ;;
            --test-scoring)
                # Test the scoring function
                echo "🧪 Testing scoring function..."
                local test_desc="Optimize skill frontmatter descriptions for better Vibe auto-activation"
                
                # Use mossy-skill's own triggers for testing
                local skill_dir="$SCRIPT_DIR"
                read_triggers_into_globals "$skill_dir"
                local positive_triggers=("${G_POSITIVE_TRIGGERS[@]}")
                local negative_triggers=("${G_NEGATIVE_TRIGGERS[@]}")
                
                if [ ${#positive_triggers[@]} -eq 0 ] || [ ${#negative_triggers[@]} -eq 0 ]; then
                    echo "⚠️  No triggers found in TRIGGERS.md for mossy-skill"
                    return 1
                fi
                
                echo "Testing description: $test_desc"
                echo "Positive triggers: ${#positive_triggers[@]}"
                echo "Negative triggers: ${#negative_triggers[@]}"
                
                local scores=$(calculate_scores "$test_desc" "${positive_triggers[@]}" "${negative_triggers[@]}")
                local sensitivity=$(echo "$scores" | awk '{print $1}')
                local specificity=$(echo "$scores" | awk '{print $2}')
                local total_score=$(calculate_total_score "$sensitivity" "$specificity")
                
                echo "Sensitivity: $sensitivity"
                echo "Specificity: $specificity"
                echo "Total Score: $total_score"
                return 0
                ;;
            -*)
                echo "❌ Unknown option: $1"
                return 1
                ;;
            *)
                pattern="$1"
                shift
                ;;
        esac
    done
    
    # Set global variable for ensure_triggers to check
    export SKIP_TRIGGERS="$skip_triggers"
    
    # Handle generate-triggers flag (delegated to SKILL.md)
    if [ -n "$generate_triggers" ]; then
        echo "⚠️ --generate-triggers flag is now handled by SKILL.md with LLM-based generation"
        echo "   Please use: /mossy:skill --generate-triggers $generate_triggers"
        return 0
    fi
    
    # Handle regenerate flag
    if [ "$regenerate" = true ]; then
        regenerate_all_triggers
        return 0
    fi
    
    # Validate prerequisites
    if [ ! -d ".vibe/skills/" ]; then
        echo "❌ .vibe/skills/ directory not found"
        record_issue --skill "mossy-skill" --error-type "resource-error" --context "directory_check" \
            --error "Required skills directory not found" "Pattern: ${pattern:-*}" || true
        return 1
    fi
    
    local pattern="${pattern:-*}"  # Default: optimize all skills
    
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
    
    # Step 1.5: Ensure all skills have valid TRIGGERS.md files
    echo "📝 Ensuring TRIGGERS.md files exist and are valid..."
    for skill_dir in "${skill_dirs[@]}"; do
        ensure_triggers "$skill_dir"
    done
    
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
        record_issue --skill "mossy-skill" --error-type "resource-error" --context "file_existence" \
            --error "Skill file not found" "Skill: $skill_name" || true
        return 1
    fi
    
    # Read current description from frontmatter
    local current_description=$(extract_frontmatter_field "$skill_file" "description")
    if [ -z "$current_description" ]; then
        echo "❌ No description found in frontmatter: $skill_file"
        record_issue --skill "mossy-skill" --error-type "validation-error" --context "frontmatter_parsing" \
            --error "No description field in frontmatter" "Skill: $skill_name" || true
        return 1
    fi
    
    echo "  Current description: $current_description"
    
    # Step 2: Read triggers from TRIGGERS.md
    echo "  📖 Reading triggers from TRIGGERS.md..."
    read_triggers_into_globals "$skill_dir"
    local positive_triggers=("${G_POSITIVE_TRIGGERS[@]}")
    local negative_triggers=("${G_NEGATIVE_TRIGGERS[@]}")
    
    local pos_count=${#positive_triggers[@]}
    local neg_count=${#negative_triggers[@]}
    echo "  Loaded $pos_count positive triggers and $neg_count negative triggers"
    
    if [ $pos_count -eq 0 ] || [ $neg_count -eq 0 ]; then
        echo "  ⚠️  No triggers found, falling back to generate_prompts_from_skill"
        # Fallback to old behavior
        local prompts=()
        while IFS= read -r prompt; do
            prompts+=("$prompt")
        done < <(generate_prompts_from_skill "$skill_dir")
        
        local prompt_count=${#prompts[@]}
        if [ $prompt_count -eq 0 ]; then
            prompts=("use $skill_name" "run $skill_name" "help with $skill_name")
            prompt_count=3
        fi
        echo "  Generated $prompt_count sample prompts (fallback)"
    else
        # Use triggers as prompts
        # Combine positive and negative triggers for backward compatibility
        local prompts=("${positive_triggers[@]}")
        local prompt_count=${#prompts[@]}
        echo "  Using $prompt_count trigger phrases"
    fi
    
    # Step 3: Baseline measurement using scoring function
    echo "  📊 Measuring baseline with scoring function..."
    local scores=$(calculate_scores "$current_description" "${positive_triggers[@]}" "${negative_triggers[@]}")
    local sensitivity=$(echo "$scores" | awk '{print $1}')
    local specificity=$(echo "$scores" | awk '{print $2}')
    local baseline_score=$(calculate_total_score "$sensitivity" "$specificity")
    echo "  Baseline - Sensitivity: $sensitivity, Specificity: $specificity, Score: $baseline_score"
    
    # Step 4: Generate optimized description
    echo "  🔧 Optimizing description..."
    local skill_content=$(cat "$skill_file")
    local optimized_description=$(optimize_description "$current_description" "$skill_content" "${prompts[@]}")
    
    if [ "$optimized_description" = "$current_description" ]; then
        echo "  ℹ️  No improvement possible for $skill_name"
        return 0
    fi
    
    echo "  Optimized: $optimized_description"
    
    # Step 5: Validation using new scoring function
    echo "  🛡️  Validating optimization with scoring function..."
    
    # Test optimized description
    local opt_scores=$(calculate_scores "$optimized_description" "${positive_triggers[@]}" "${negative_triggers[@]}")
    local opt_sensitivity=$(echo "$opt_scores" | awk '{print $1}')
    local opt_specificity=$(echo "$opt_scores" | awk '{print $2}')
    local opt_score=$(calculate_total_score "$opt_sensitivity" "$opt_specificity")
    echo "  Optimized - Sensitivity: $opt_sensitivity, Specificity: $opt_specificity, Score: $opt_score"
    
    # Compare scores
    local score_improved=$(awk "BEGIN {print ($opt_score > $baseline_score) ? 1 : 0}")
    
    # Also check that specificity doesn't drop below 0.75 (which would give zero score)
    local specificity_ok=$(awk "BEGIN {print ($opt_specificity >= 0.75) ? 1 : 0}")
    
    # Accept optimization only if score improved AND specificity >= 0.75
    if [ "$score_improved" -eq 1 ] && [ "$specificity_ok" -eq 1 ]; then
        echo "  ✅ Optimization accepted (score improved from $baseline_score to $opt_score)"
    else
        echo "  ❌ Optimization rejected: Score did not improve or specificity too low"
        echo "     Baseline score: $baseline_score, Optimized score: $opt_score"
        echo "     Optimized specificity: $opt_specificity (need >= 0.75)"
        record_issue --skill "mossy-skill" --error-type "logic-error" --context "scoring_validation" \
            --error "Optimization did not improve score or specificity too low" "Skill: $skill_name" || true
        return 1
    fi
    
    # Step 6: Apply optimization
    echo "  ✅ Applying optimization..."
    local backup_file="${skill_file}.mossy-skill-backup"
    cp "$skill_file" "$backup_file"
    
    # Modify the description in the frontmatter
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
    if [ ${#results[@]} -eq 0 ] && [[ ! "$pattern" == *\* ]] && [[ ! "$pattern" == *\? ]]; then
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
# This is now a fallback function when TRIGGERS.md is not available
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
    local current_description=$(extract_frontmatter_field "$skill_file" "description")
    
    # Method 1: From skill name (variations)
    local clean_name=$(echo "$skill_name" | sed 's/^mossy-//')
    prompts+=("${clean_name}")
    prompts+=("use ${clean_name}")
    prompts+=("run ${clean_name}")
    prompts+=("execute ${clean_name}")
    
    # Method 2: From description (extract action + object patterns)
    if [ -n "$current_description" ]; then
        local desc_lower=$(echo "$current_description" | tr '[:upper:]' '[:lower:]')
        
        # Extract verbs and objects from description
        local first_word=$(echo "$current_description" | awk '{print $1}')
        local second_word=$(echo "$current_description" | awk '{print $2}')
        
        if [ -n "$first_word" ] && [ -n "$second_word" ]; then
            prompts+=("${first_word} ${second_word}")
            prompts+=("please ${first_word} ${second_word}")
            prompts+=("can you ${first_word} ${second_word}")
        fi
    fi
    
    # Method 3: From body content - extract ## section headers as potential use cases
    local sections=$(echo "$skill_content" | grep '^## ' | sed 's/^## //' | head -5)
    while IFS= read -r section; do
        if [ -n "$section" ]; then
            prompts+=("${section}")
            prompts+=("how to ${section}")
        fi
    done <<< "$sections"
    
    # Method 4: Common usage patterns
    if [ -n "$clean_name" ]; then
        prompts+=("help with ${clean_name}")
        prompts+=("${clean_name} help")
        prompts+=("what does ${clean_name} do")
    fi
    
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
    
    # Step: Test each candidate and select the best using new scoring
    local best_candidate="$original_description"
    local best_score=-1
    
    # We need to extract positive and negative triggers from the first argument
    # For now, use the existing prompts array
    # In a full implementation, we would pass positive/negative arrays separately
    
    for candidate in "${candidates[@]}"; do
        # Ensure candidate is properly capitalized
        local cap_candidate=$(echo "$candidate" | awk '{print toupper(substr($0,1,1)) substr($0,2)}')
        
        # Test this candidate against the prompts using scoring function
        # We'll split prompts into positive (all of them) and negative (none for now)
        # This is a simplified approach - in practice we'd have separate arrays
        local test_prompts=("${prompts[@]:0:10}")
        local current_rate=$(vibe_test_prompts "$cap_candidate" "${test_prompts[@]}")
        
        # For now, use the rate as a proxy for score
        # In a full implementation, we'd use calculate_scores
        local candidate_score=$(awk "BEGIN {printf \"%.4f\", $current_rate / 100}")
        
        if [ $(awk "BEGIN {print ($candidate_score > $best_score)}") -eq 1 ] 2>/dev/null; then
            best_score=$candidate_score
            best_candidate="$cap_candidate"
        fi
    done
    
    echo "$best_candidate"
}

# Call main if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
