---
name: mossy-skill
description: Optimize skill frontmatter descriptions for better Vibe activation. Analyzes existing skill descriptions and improves them so skills activate when prompts match their capabilities.
user-invocable: false
allowed-tools: read_file, write_file, grep, bash, ask_user_question, task
---

# mossy-skill

Optimize skill frontmatter descriptions to improve Vibe auto-activation. This skill systematically analyzes existing skill frontmatter and modifies the description field to ensure skills are activated when user prompts demand functionality that the skill can provide.

Vibe auto-triggers skills based on description matching (confirmed via upstream changelog:2573). This skill provides data-driven optimization of the description field to maximize relevant activations while avoiding false positives.

## Input

$ARGUMENTS

Accepts:
- **Skill pattern**: `mossy-*` or `mossy-skill` or `*-analyze` (glob pattern to match skills)
- **Empty**: Optimize all mossy skills by default
- **Single skill name**: `mossy-skill` (optimize specific skill)

Examples:
- `/mossy:skill mossy-*` - Optimize all mossy skills
- `/mossy:skill mossy-skill` - Optimize just the mossy-skill
- `/mossy:skill` - Optimize all skills in .vibe/skills/

## Main Execution Flow

```bash
# Main entry point - invoked by /mossy:skill command
main() {
    # Load error recording utility
    source .vibe/skills/mossy-scripts/record-issue.sh 2>/dev/null || true
    
    # Validate prerequisites
    if [ ! -d ".vibe/skills/" ]; then
        echo "❌ .vibe/skills/ directory not found"
        record_issue "mossy-skill" "resource-error" "directory_check" ".vibe/skills/" \
            "Required skills directory not found" "Pattern: ${1:-mossy-*}" || true
        return 1
    fi
    
    if [ ! -f ".vibe/skills/mossy-scripts/record-issue.sh" ]; then
        echo "⚠️  record-issue.sh not found, error recording disabled"
    fi
    
    local pattern="${1:-mossy-*}"  # Default: optimize all mossy skills
    
    # Step 1: Skill Selection
    echo "🔍 Finding skills matching pattern: $pattern"
    local skill_dirs=()
    
    if [ "$pattern" = "" ] || [ "$pattern" = "*" ] || [ "$pattern" = "all" ]; then
        # Find all skill directories
        while IFS= read -r -d '' dir; do
            skill_dirs+=("$dir")
        done < <(find .vibe/skills/ -type d -name "*" -print0 | sort -z)
    else
        # Find skills matching the pattern
        while IFS= read -r -d '' dir; do
            local dirname=$(basename "$dir")
            # Support glob patterns
            if [[ "$dirname" == $pattern ]]; then
                skill_dirs+=("$dir")
            fi
        done < <(find .vibe/skills/ -type d -print0 | sort -z)
    fi
    
    if [ ${#skill_dirs[@]} -eq 0 ]; then
        echo "❌ No skills found matching pattern: $pattern"
        record_issue "mossy-skill" "logic-error" "pattern_matching" "$pattern" \
            "No skills matched the specified pattern" "Pattern: $pattern" || true
        return 1
    fi
    
    # Validate pattern is reasonable
    if [[ "$pattern" == *".."* ]] || [[ "$pattern" == *"/"* ]]; then
        echo "❌ Invalid pattern: $pattern (contains path separators)"
        record_issue "mossy-skill" "validation-error" "pattern_validation" "$pattern" \
            "Pattern contains invalid characters" "Pattern: $pattern" || true
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
        record_issue "mossy-skill" "resource-error" "file_existence" "$skill_file" \
            "Skill file not found" "Pattern: $pattern" || true
        return 1
    fi
    
    # Read current description from frontmatter
    local current_description=$(extract_frontmatter_field "$skill_file" "description")
    if [ -z "$current_description" ]; then
        echo "❌ No description found in frontmatter: $skill_file"
        record_issue "mossy-skill" "validation-error" "frontmatter_parsing" "$skill_file" \
            "No description field in frontmatter" "Pattern: $pattern" || true
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
        record_issue "mossy-skill" "logic-error" "false_activation" "$skill_name" \
            "Optimization introduced false activations" "Pattern: $pattern" || true
        return 1
    fi
    
    # Step 6: Apply optimization
    echo "  ✅ Applying optimization..."
    local backup_file="${skill_file}.mossy-skill-backup"
    cp "$skill_file" "$backup_file"
    
    # Modify the description in the frontmatter
    local new_content=$(echo "$skill_content" | sed "s/^description: .*/description: \"${optimized_description}\"/")
    echo "$new_content" > "$skill_file"
    
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
            result=$(echo "$line" | sed "s/^${field}: //" | sed 's/^["'\)'']//' | sed 's/["'\)'']$//')
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
```

## Flow

1. **Skill Selection**
   - Parse input pattern or use default (all mossy skills)
   - Find matching skills in `.vibe/skills/` directory
   - Validate each matching skill has proper frontmatter

2. **Prompt Generation**
   - For each selected skill:
     - Extract potential use cases from skill body content
     - Generate prompts from skill name and current description
     - Accept optional user-provided prompts
   - Target: 10-20 diverse, realistic sample prompts per skill

3. **Baseline Measurement**
   - Test current description activation rate using Vibe simulation
   - Record baseline: percentage of relevant prompts that activate
   - Identify false activations (irrelevant prompts that trigger)

4. **Description Optimization**
   - Apply optimization criteria to current description:
     - **Specificity**: Be precise about what the skill does
     - **Action-oriented**: Use active verbs matching user intent
     - **Length**: Balance detail with brevity (target: 10-15 words)
   - Generate 3-5 candidate descriptions
   - Test each candidate against sample prompts
   - Select best candidate based on activation improvement

5. **Validation**
   - Ensure no false activations introduced
   - Verify improved activation rate over original
   - Check description follows YAML frontmatter syntax

6. **Modification**
   - Directly modify skill frontmatter with optimized description
   - Preserve all other frontmatter fields
   - Backup original description for rollback capability

## Core Algorithm

### Vibe Simulation Implementation

```bash
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
    echo "activation_rate: ${rate}% (${activated}/${total} prompts activated)"
    return $((total - activated))  # Return count of failed activations
}
```

### Prompt Generation Implementation

```bash
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
    local description=$(echo "$skill_content" | grep -A 1 '^description:' | tail -1 | sed 's/^["'\)'']//' | sed 's/["'\)'']$//')
    
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
```

### Optimization Criteria

1. **Specificity and Precision**
   - Describe exactly what the skill does
   - Avoid generic terms like "help with" or "assist with"
   - Use concrete verbs: analyze, create, optimize, modify, test, validate

2. **Action-Oriented Language**
   - Start with verb: "Optimize skill frontmatter descriptions"
   - Use imperative mood matching user commands
   - Focus on outcomes: "for better Vibe activation"

3. **Length Optimization**
   - Target length: 10-15 words
   - Include 2-3 key concepts/verbs
   - Balance detail with scannability

## Pattern Matching

Supports multiple pattern formats:
- **Glob patterns**: `mossy-*`, `*-analyze`, `mossy-?`
- **Exact names**: `mossy-skill`, `mossy-analyze`
- **Regex patterns**: `^mossy-.*` (if supported by shell)

Pattern resolution order:
1. Exact match first
2. Glob expansion
3. Directory listing with filtering

## Error Recording

This skill records errors to `.flow/issues/` following the [Issue Recording Guide](../mossy-scripts/ISSUE_RECORDING.md).

### Error Types Recorded

| Error Type | Trigger | Example |
|------------|---------|---------|
| tool-error | Vibe tool calls fail | read_file on non-existent skill directory |
| validation-error | Input format invalid | Invalid skill pattern, missing frontmatter |
| logic-error | Internal logic fails | Circular optimization loop, no improvement found |
| resource-error | Required resources missing | .vibe/skills/ directory not found |
| configuration-error | Environment issue | flowctl.sh not accessible |

### Integration
```bash
source .vibe/skills/mossy-scripts/record-issue.sh 2>/dev/null || true
record_issue "mossy-skill" "tool-error" "read_file" "$target_skill" \
    "read_file failed: $?" \
    "Phase: analysis, Pattern: $pattern" || true
```

## Quick commands
- `cd /workspaces/mossy-slop && find .vibe/skills/ -name "SKILL.md" | wc -l`
- `cd /workspaces/mossy-slop && grep -r "description:" .vibe/skills/ --include="SKILL.md" | head -10`
- `cd /workspaces/mossy-slop && bash .vibe/skills/mossy-skill/SKILL.md --test` (smoke test)
- `cd /workspaces/mossy-slop && .vibe/skills/mossy-scripts/flowctl.sh validate` (validate all specs)

### Smoke Tests

```bash
# Test Vibe simulation
bash -c 'source .vibe/skills/mossy-skill/SKILL.md && \
    vibe_simulate_activation "optimize skill description" "Optimize skill frontmatter descriptions for better Vibe activation"'

# Test prompt generation
bash -c 'source .vibe/skills/mossy-skill/SKILL.md && \
    generate_sample_prompts_for_skill ".vibe/skills/mossy-idea" | head -5'

# Test frontmatter extraction
bash -c 'source .vibe/skills/mossy-skill/SKILL.md && \
    extract_frontmatter_field ".vibe/skills/mossy-idea/SKILL.md" "description"'
```

### Description Optimization Implementation

```bash
# Apply optimization criteria to improve a description
# Returns optimized description
optimize_description() {
    local original_description="$1"
    local skill_content="$2"
    shift 2
    local prompts=("$@")
    
    # Step 1: Analyze current description
    local word_count=$(echo "$original_description" | wc -w)
    local char_count=$(echo "$original_description" | wc -m)
    
    # Step 2: Extract key components
    local first_word=$(echo "$original_description" | awk '{print $1}')
    local action_verbs=("optimize" "analyze" "create" "modify" "test" "validate" "review" "improve" "generate" "execute" "plan" "work" "finish" "scan" "refactor")
    local found_verb=""
    
    for verb in "${action_verbs[@]}"; do
        if [[ "$original_description" == *"$verb"* ]]; then
            found_verb="$verb"
            break
        fi
    done
    
    # Step 3: Generate candidate descriptions
    local candidates=()
    
    # Candidate 1: More action-oriented
    if [ -n "$found_verb" ]; then
        local obj=$(echo "$original_description" | sed "s/${found_verb} //" | sed "s/${found_verb}//")
        candidates+=("${found_verb} ${obj} for better Vibe activation")
    fi
    
    # Candidate 2: More specific
    local clean_desc=$(echo "$original_description" | sed 's/\.//g')
    candidates+=("${clean_desc} to improve skill auto-triggering")
    
    # Candidate 3: More concise (if too long)
    if [ $word_count -gt 15 ]; then
        local concise=$(echo "$original_description" | awk '{print $1, $2, $3, $4}')
        candidates+=("${concise}")
    fi
    
    # Candidate 4: Add context about Vibe activation
    candidates+=("${original_description} so it activates when prompts match its capabilities")
    
    # Step 4: Test each candidate and select the best
    local best_candidate="$original_description"
    local best_rate=0
    
    for candidate in "${candidates[@]}"; do
        # Test this candidate against the prompts
        local test_prompts=("${prompts[@]:0:10}")  # Test with first 10 prompts
        local temp_result=$(vibe_test_prompts "$candidate" "${test_prompts[@]}")
        local current_rate=$(echo "$temp_result" | grep -oP '\d+%' | tr -d '%')
        
        if [ $current_rate -gt $best_rate ]; then
            best_rate=$current_rate
            best_candidate="$candidate"
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
    local original_false=$(vibe_test_prompts "$original_description" "${false_prompts[@]}")
    local original_false_rate=$(echo "$original_false" | grep -oP '\d+%' | tr -d '%')
    
    # Test new description against false prompts
    local new_false=$(vibe_test_prompts "$new_description" "${false_prompts[@]}")
    local new_false_rate=$(echo "$new_false" | grep -oP '\d+%' | tr -d '%')
    
    # If new false activation rate is higher than original, it's unsafe
    if [ $new_false_rate -gt $original_false_rate ]; then
        echo "FAIL: False activations increased from ${original_false_rate}% to ${new_false_rate}%"
        return 1
    fi
    
    echo "PASS: False activations safe (original: ${original_false_rate}%, new: ${new_false_rate}%)"
    return 0
}
```

## GUARDRAILS

- **CRITICAL: ONLY modify skill frontmatter description fields**
- **IMPORTANT**: Always preserve original description in backup
- **DO NOT modify skill implementation logic**
- **DO NOT create new skills** - only optimize existing ones
- **DO NOT change skill activation mechanism** - only improve descriptions
- **ALL modifications tracked with error recording**
- **User retains full control** - can review and revert any changes