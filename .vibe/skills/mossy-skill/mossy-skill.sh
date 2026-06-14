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
# Usage: calculate_scores "description" "pos_count" "positive_prompts..." "neg_count" "negative_prompts..."
#   OR the old way (for backward compatibility): calculate_scores "description" "positive_prompts_array" "negative_prompts_array"
#   But the old way doesn't work due to bash array flattening.
# Outputs: SENSITIVITY SPECIFICITY
calculate_scores() {
    local description="$1"
    local pos_count="$2"
    shift 2
    
    # Extract positive prompts (first $pos_count arguments)
    local positive_prompts=()
    local idx=0
    while [ $idx -lt $pos_count ]; do
        positive_prompts+=("$1")
        shift
        idx=$((idx + 1))
    done
    
    # Extract negative prompts (remaining arguments)
    local negative_prompts=("$@")
    
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
                
                local scores=$(calculate_scores "$test_desc" "${#positive_triggers[@]}" "${positive_triggers[@]}" "${#negative_triggers[@]}" "${negative_triggers[@]}")
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
    local scores=$(calculate_scores "$current_description" "${#positive_triggers[@]}" "${positive_triggers[@]}" "${#negative_triggers[@]}" "${negative_triggers[@]}")
    local sensitivity=$(echo "$scores" | awk '{print $1}')
    local specificity=$(echo "$scores" | awk '{print $2}')
    local baseline_score=$(calculate_total_score "$sensitivity" "$specificity")
    echo "  Baseline - Sensitivity: $sensitivity, Specificity: $specificity, Score: $baseline_score"
    
    # Step 4: Generate optimized description
    echo "  🔧 Optimizing description..."
    local skill_content=$(cat "$skill_file")
    local optimized_description=$(optimize_description "$current_description" "$skill_content" "$skill_name" "$skill_dir" "${positive_triggers[@]}")
    
    if [ "$optimized_description" = "$current_description" ]; then
        echo "  ℹ️  No improvement possible for $skill_name"
        return 0
    fi
    
    echo "  Optimized: $optimized_description"
    
    # Step 5: Validation using new scoring function
    echo "  🛡️  Validating optimization with scoring function..."
    
    # Test optimized description
    local opt_scores=$(calculate_scores "$optimized_description" "${#positive_triggers[@]}" "${positive_triggers[@]}" "${#negative_triggers[@]}" "${negative_triggers[@]}")
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

# ============================================================================
# SUBAGENT-BASED ACTIVATION ORACLE (fn-44)
# ============================================================================

# Subagent-based oracle for predicting skill activation using LLM semantic understanding
# Uses task tool to invoke subagent with explore profile
# Returns 0 (success) if activation is predicted, 1 otherwise
# Timeout: configurable via VIBE_SIMULATE_ACTIVATION_TIMEOUT (default: 10 seconds)
vibe_simulate_activation_llm() {
    local prompt="$1"
    local description="$2"
    local timeout=${VIBE_SIMULATE_ACTIVATION_TIMEOUT:-10}
    local result
    local start_time
    local elapsed
    local exit_code

    start_time=$(date +%s)
    
    # Build subagent question for activation prediction
    # Use a clear, structured prompt for the LLM
    local question="Determine if the following user prompt would trigger a skill with this description.

User Prompt: ${prompt}
Skill Description: ${description}

Respond with ONLY one of these exact words:
- 'yes' if the prompt would trigger the skill
- 'no' if the prompt would NOT trigger the skill

Do not provide any explanation, reasoning, or additional text. Just 'yes' or 'no'."
    
    # Execute subagent with timeout
    # Use a subshell with timeout to prevent hanging
    result=$(timeout $timeout bash -c "task '\''$question'\''" 2>/dev/null) || exit_code=$?
    
    elapsed=$(( $(date +%s) - start_time ))
    
    # Check if we timed out
    if [ $exit_code -eq 124 ]; then
        echo "activation: timeout, elapsed: ${elapsed}s, threshold: ${timeout}s" >&2
        record_issue "mossy-skill" "tool-error" "task" "vibe_simulate_activation_llm" \
            "Timeout after ${elapsed}s (threshold: ${timeout}s)" \
            "Prompt: ${prompt:0:50}... Description: ${description:0:50}..." || true
        return 1
    fi
    
    # Check for empty result (subagent unavailable)
    if [ -z "$result" ]; then
        echo "activation: subagent_unavailable" >&2
        record_issue "mossy-skill" "configuration-error" "task" "vibe_simulate_activation_llm" \
            "Subagent returned empty result" \
            "Prompt: ${prompt:0:50}... Description: ${description:0:50}..." || true
        return 1
    fi
    
    # Parse result: check for yes/no (case-insensitive, allow some whitespace)
    local normalized_result=$(echo "$result" | tr '[:upper:]' '[:lower:]' | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
    
    if [ "$normalized_result" = "yes" ]; then
        echo "activation: true, confidence: high, source: llm_oracle, elapsed: ${elapsed}s"
        return 0
    elif [ "$normalized_result" = "no" ]; then
        echo "activation: false, confidence: high, source: llm_oracle, elapsed: ${elapsed}s"
        return 1
    else
        # Invalid response from subagent
        echo "activation: invalid_response, result: '${result}'" >&2
        record_issue "mossy-skill" "logic-error" "task" "vibe_simulate_activation_llm" \
            "Invalid response from subagent: ${result}" \
            "Prompt: ${prompt:0:50}... Description: ${description:0:50}..." || true
        return 1
    fi
}

# Word-matching fallback implementation (original vibe_simulate_activation)
# Renamed to avoid conflict with the new fallback wrapper
vibe_simulate_activation_word_match() {
    local prompt="$1"
    local description="$2"
    local confidence="low"
    
    # Normalize both to lowercase for case-insensitive matching
    local prompt_lower=$(echo "$prompt" | tr '[:upper:]' '[:lower:]')
    local description_lower=$(echo "$description" | tr '[:upper:]' '[:lower:]')
    
    # 1. Exact substring match (highest confidence)
    if [[ "$prompt_lower" == *"$description_lower"* || "$description_lower" == *"$prompt_lower"* ]]; then
        echo "activation: true, confidence: high, reason: exact_substring_match, source: word_match"
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
        echo "activation: true, confidence: medium, reason: keyword_match_${word_matches}_of_${desc_word_count}, source: word_match"
        return 0
    fi
    
    # 3. Key action verb matching
    local action_verbs=("optimize" "analyze" "create" "modify" "test" "validate" "review" "improve" "generate" "execute" "plan" "work" "finish" "scan" "refactor")
    
    for verb in "${action_verbs[@]}"; do
        if [[ "$description_lower" == *"$verb"* ]] && [[ "$prompt_lower" == *"$verb"* ]]; then
            echo "activation: true, confidence: medium, reason: action_verb_match_${verb}, source: word_match"
            return 0
        fi
    done
    
    # No match found
    echo "activation: false, confidence: low, reason: no_match_found, source: word_match"
    return 1
}

# Vibe activation simulation - tests if a prompt would activate a skill based on description
# Returns 0 (success) if activation is predicted, 1 otherwise
# Uses fallback chain: try LLM oracle first, then word matching
vibe_simulate_activation() {
    local prompt="$1"
    local description="$2"
    
    # 1. Try LLM oracle first (fn-44)
    if vibe_simulate_activation_llm "$prompt" "$description"; then
        return 0
    fi
    
    # 2. Fall back to word matching if subagent fails/times out
    vibe_simulate_activation_word_match "$prompt" "$description"
    return $?
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
# fn-31 implementation: Use task tool for subagent-based candidate generation
# See: .flow/specs/fn-31-implement-subagent-candidate-generation.md
#
# Generate 5-10 diverse candidate descriptions using subagent with explore profile
# Returns JSON array of candidate strings via stdout, or empty if subagent unavailable
generate_candidates_subagent() {
    local skill_name="$1"
    local current_description="$2"
    local skill_content="$3"
    
    # Build subagent prompt (full SKILL.md content as context, per user preference)
    # fn-46: Explicitly require grammatical correctness
    local subagent_prompt="Generate 5-10 diverse, improved descriptions for a Vibe CLI skill.

Skill: ${skill_name}
Current Description: ${current_description}
Skill Content Preview:
${skill_content}

Requirements:
- Preserve the meaning and intent of the original
- MUST be grammatically correct English (fn-46)
- First word MUST be capitalized (A-Z)
- Use proper punctuation
- NO redundant or repeated phrases (fn-46)
- Target length: 10-15 words
- Include action-oriented language
- Avoid redundancy
- Each candidate must be distinct from others
- Focus on natural language that matches user prompts
- Reject any candidate that violates grammar requirements

Output format: JSON array of candidate strings"
    
    # Invoke subagent via task tool with explore profile
    local result
    if result=$(task "$subagent_prompt" 2>/dev/null); then
        # Parse JSON response - try to extract array
        # Handle both raw JSON and markdown-formatted JSON
        echo "$result" | grep -o '\[[^]]*\]' | head -1
        return 0
    else
        # Subagent unavailable
        echo ""
        return 1
    fi
}

# Deduplicate candidates (exact duplicates only, per user preference)
deduplicate_candidates() {
    local -n candidates_ref="$1"
    local unique_candidates=()
    declare -A seen
    
    for candidate in "${candidates_ref[@]}"; do
        if [[ -z "${seen[$candidate]+x}" ]]; then
            seen["$candidate"]=1
            unique_candidates+=("$candidate")
        fi
    done
    
    # Return via name reference (bash can't return arrays directly)
    # Caller must handle the unique_candidates array
    # For now, print and let caller parse - but this won't work for arrays
    # Instead, modify the input array in place using name reference
    # This requires bash 4.3+ nameref
    if [[ ${#unique_candidates[@]} -gt 0 ]]; then
        # Rebuild the original array
        candidates_ref=("${unique_candidates[@]}")
    fi
}

# Validate that a description is grammatically correct and human-readable
# Usage: validate_description_grammar "description"
# Returns: 0 if valid, 1 if invalid
# Output: Error messages to stdout if invalid
validate_description_grammar() {
    local description="$1"
    local errors=()
    
    # Check not empty
    if [ -z "$description" ] || [ -z "$(echo "$description" | tr -d '[:space:]')" ]; then
        errors+=("Description is empty")
        printf '%s\n' "${errors[@]}"
        return 1
    fi
    
    # Check capitalization - first character must be uppercase letter
    local first_char=$(echo "$description" | cut -c1)
    if ! [[ "$first_char" =~ [A-Z] ]]; then
        errors+=("First word not capitalized")
    fi
    
    # Check for double spaces
    if echo "$description" | grep -q '  '; then
        errors+=("Contains double spaces")
    fi
    
    # Check for unmatched quotes
    local double_quotes=$(echo "$description" | grep -o '"' | wc -l)
    local single_quotes=$(echo "$description" | grep -o "'" | wc -l)
    if [ $((double_quotes % 2)) -ne 0 ]; then
        errors+=("Unmatched double quotation marks")
    fi
    if [ $((single_quotes % 2)) -ne 0 ]; then
        errors+=("Unmatched single quotation marks")
    fi
    
    # Check for redundancy (repeated 4-word phrases)
    # Convert to lowercase for case-insensitive comparison
    local desc_lower=$(echo "$description" | tr '[:upper:]' '[:lower:]')
    local words=($desc_lower)
    local word_count=${#words[@]}
    
    for ((i=0; i<word_count-3; i++)); do
        local phrase="${words[$i]} ${words[$i+1]} ${words[$i+2]} ${words[$i+3]}"
        # Count occurrences of this phrase
        local count=0
        for ((j=0; j<word_count-3; j++)); do
            local test_phrase="${words[$j]} ${words[$j+1]} ${words[$j+2]} ${words[$j+3]}"
            if [ "$test_phrase" = "$phrase" ]; then
                count=$((count + 1))
            fi
        done
        if [ $count -gt 1 ]; then
            errors+=("Redundant phrase detected: '$phrase'")
        fi
    done
    
    # Check punctuation for long descriptions
    local desc_length=$(echo "$description" | wc -w)
    if [ $desc_length -gt 10 ]; then
        # Long descriptions should end with punctuation
        local last_char=$(echo "$description" | tail -c 1)
        if ! [[ "$last_char" =~ [".""!""?"] ]]; then
            errors+=("Long description (${desc_length} words) should end with punctuation")
        fi
    fi
    
    # Report errors and return status
    if [ ${#errors[@]} -gt 0 ]; then
        printf '%s\n' "${errors[@]}"
        return 1
    fi
    
    return 0
}

# Future: SKILL.md will use task tool to invoke subagent for description generation.
# This bash script will call SKILL.md logic for candidate generation.
# 
# See: .flow/specs/fn-31-implement-subagent-candidate-generation.md (replaces fn-28)
#
# Apply optimization criteria to improve a description
# Returns optimized description
# 
# fn-31 implementation: Uses task tool with explore profile for subagent-based generation
# Falls back to conservative algorithm if subagent unavailable
#
# fn-31 implementation: Updated to use subagent-based candidate generation
optimize_description() {
    local original_description="$1"
    local skill_content="$2"
    local skill_name="$3"
    local skill_dir="$4"
    shift 4
    local positive_triggers=("$@")
    
    # First, ensure original description preserves capitalization
    local first_char=$(echo "$original_description" | cut -c1)
    local rest_desc=$(echo "$original_description" | cut -c2-)
    
    if [[ "$first_char" =~ [a-z] ]]; then
        first_char=$(echo "$first_char" | tr '[:lower:]' '[:upper:]')
        original_description="${first_char}${rest_desc}"
    fi
    
    # Generate candidate descriptions
    local candidates=()
    local subagent_available=true
    
    # Try subagent-based candidate generation first (fn-31)
    echo "  🤖 Attempting subagent-based candidate generation..."
    local subagent_result
    if subagent_result=$(generate_candidates_subagent "$skill_name" "$original_description" "$skill_content" 2>/dev/null); then
        if [ -n "$subagent_result" ]; then
            # Parse JSON array manually
            # Remove brackets and split by comma, handling quotes
            local json_candidates=$(echo "$subagent_result" | sed 's/^\[//' | sed 's/\]$//')
            
            # Split by comma, but respect quoted strings
            # Simple approach: split by comma and clean up
            IFS=',' read -ra candidate_items <<< "$json_candidates"
            for item in "${candidate_items[@]}"; do
                # Clean up the item: remove quotes, trim whitespace
                item=$(echo "$item" | sed 's/^["'\'']//' | sed 's/["'\'']$//' | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
                if [ -n "$item" ]; then
                    candidates+=("$item")
                fi
            done
            echo "  ✅ Subagent generated ${#candidates[@]} candidates"
        else
            subagent_available=false
            echo "  ⚠️  Subagent returned empty result"
        fi
    else
        subagent_available=false
        echo "  ⚠️  Subagent unavailable, falling back to conservative algorithm"
        record_issue --skill "mossy-skill" --error-type "configuration-error" --context "subagent_fallback" \
            --error "task tool or explore profile not available" "Skill: ${skill_name}" || true
    fi
    
    # If subagent failed or returned no candidates, use fallback
    if [ "$subagent_available" = false ] || [ ${#candidates[@]} -eq 0 ]; then
        echo "  🔄 Using conservative fallback algorithm"
        candidates+=("$original_description")
        
        # Check if description already mentions Vibe or activation
        local desc_lower=$(echo "$original_description" | tr '[:upper:]' '[:lower:]')
        if ! echo "$desc_lower" | grep -qi "vibe\|activation\|auto-trigger"; then
            candidates+=("${original_description} for better Vibe auto-activation")
        fi
        
        # Remove trailing periods for consistency
        local no_period=$(echo "$original_description" | sed 's/\.$//')
        if [ "$no_period" != "$original_description" ]; then
            candidates+=("$no_period")
        fi
    fi
    
    # Deduplicate candidates (exact duplicates only, per user preference)
    local unique_candidates=()
    declare -A seen
    for candidate in "${candidates[@]}"; do
        if [[ -z "${seen[$candidate]+x}" ]]; then
            seen["$candidate"]=1
            unique_candidates+=("$candidate")
        fi
    done
    candidates=("${unique_candidates[@]}")
    
    # Validate candidates for grammatical correctness (fn-46)
    # Filter out grammatically incorrect candidates
    local valid_candidates=()
    local validation_errors=0
    for candidate in "${candidates[@]}"; do
        if validate_description_grammar "$candidate" >/dev/null 2>&1; then
            valid_candidates+=("$candidate")
        else
            validation_errors=$((validation_errors + 1))
            echo "  ❌ Candidate rejected (grammar): $candidate"
        fi
    done
    
    if [ ${#valid_candidates[@]} -eq 0 ]; then
        echo "  ⚠️  No valid candidates after grammar validation, keeping original"
        candidates=("$original_description")
    else
        echo "  ✅ ${#valid_candidates[@]} candidates passed grammar validation"
        candidates=("${valid_candidates[@]}")
    fi
    
    echo "  📊 Testing ${#candidates[@]} unique candidates"
    
    # Test each candidate and select the best using scoring
    local best_candidate="$original_description"
    local best_score=-1
    local best_sensitivity=0
    local best_specificity=0
    
    # Get negative triggers for proper scoring
    local negative_triggers=()
    read_triggers_into_globals "$skill_dir"
    negative_triggers=("${G_NEGATIVE_TRIGGERS[@]}")
    
    for candidate in "${candidates[@]}"; do
        # Ensure candidate is properly capitalized
        local cap_candidate=$(echo "$candidate" | awk '{print toupper(substr($0,1,1)) substr($0,2)}')
        
        # Use calculate_scores with proper positive and negative arrays
        # But calculate_scores has a bug - it doesn't properly separate arrays
        # Workaround: manually calculate sensitivity and specificity
        
        # Test against positive triggers (should activate)
        local tp=0
        local fn=0
        for prompt in "${positive_triggers[@]}"; do
            if vibe_simulate_activation "$prompt" "$cap_candidate" >/dev/null 2>&1; then
                tp=$((tp + 1))
            else
                fn=$((fn + 1))
            fi
        done
        
        # Test against negative triggers (should NOT activate)
        local tn=0
        local fp=0
        for prompt in "${negative_triggers[@]}"; do
            if vibe_simulate_activation "$prompt" "$cap_candidate" >/dev/null 2>&1; then
                fp=$((fp + 1))
            else
                tn=$((tn + 1))
            fi
        done
        
        # Calculate Sensitivity = TP / (TP + FN)
        local sensitivity=0
        if [ $((tp + fn)) -gt 0 ]; then
            sensitivity=$(awk "BEGIN {printf \"%.4f\", $tp / ($tp + $fn)}")
        fi
        
        # Calculate Specificity = TN / (TN + FP)
        local specificity=0
        if [ $((tn + fp)) -gt 0 ]; then
            specificity=$(awk "BEGIN {printf \"%.4f\", $tn / ($tn + $fp)}")
        fi
        
        # Calculate score: sensitivity * max(0, specificity - 0.75)
        local specificity_adjusted=$(awk "BEGIN {diff = $specificity - 0.75; if (diff < 0) diff = 0; printf \"%.4f\", diff}")
        local candidate_score=$(awk "BEGIN {printf \"%.4f\", $sensitivity * $specificity_adjusted}")
        
        if [ $(awk "BEGIN {print ($candidate_score > $best_score)}") -eq 1 ] 2>/dev/null; then
            best_score=$candidate_score
            best_candidate="$cap_candidate"
            best_sensitivity=$sensitivity
            best_specificity=$specificity
        fi
    done
    
    echo "  🎯 Best candidate score: $best_score (sensitivity: $best_sensitivity, specificity: $best_specificity)"
    echo "$best_candidate"
}

# Call main if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
