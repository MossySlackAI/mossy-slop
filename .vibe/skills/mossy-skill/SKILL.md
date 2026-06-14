---
name: mossy-skill
description: "Improve skill descriptions in frontmatter to enhance Vibe auto-trigger matching"
user-invocable: false
allowed-tools: read_file, write_file, grep, bash, ask_user_question, task
---

# mossy-skill

Optimize skill frontmatter descriptions to improve Vibe auto-activation. This skill systematically analyzes existing skill frontmatter and modifies the description field to ensure skills are activated when user prompts demand functionality that the skill can provide.

Vibe auto-triggers skills based on description matching (confirmed via upstream changelog:2573). This skill provides data-driven optimization of the description field to maximize relevant activations while avoiding false positives.

## Architecture (fn-28 Split)

**Component Separation:**

### mossy-skill.sh (Bash Script)
Responsible for:
- File I/O operations (reading/writing SKILL.md files)
- Pattern matching and skill discovery in `.vibe/skills/`
- Backup/restore logic for rollback capability
- Activation testing via `vibe_test_prompts()` and `vibe_simulate_activation()`
- Orchestration of the optimization workflow

### SKILL.md (LLM Skill Definition)
Responsible for:
- Subagent orchestration via `task` tool
- Candidate generation coordination
- Fallback logic when subagents are unavailable
- Result selection and application
- Description optimization logic (moving from .sh)

**Communication Flow:**
```
User Command (/mossy:skill)
    ↓
SKILL.md (mossy-skill skill invoked)
    ↓
mossy-skill.sh (bash execution)
    ↓
For each skill to optimize:
    1. Extract description from SKILL.md frontmatter
    2. Generate prompts from skill content
    3. Call SKILL.md subagent orchestration (via task tool)
       → Subagent generates 5-10 candidate descriptions
    4. SKILL.md logic: deduplicate, test, select best
    5. mossy-skill.sh applies optimized description
```

**Status:** Architecture split in progress (fn-28 tasks 1-10). Currently, all logic is in mossy-skill.sh with TODO markers for future migration.

## Subagent Orchestration

### Context Assembly
For each skill to optimize, the following context is assembled:
- **skill_name**: Extracted from the skill directory name
- **current_description**: Extracted from the skill's SKILL.md frontmatter
- **skill_content_preview**: First 50 lines of the SKILL.md file

### Subagent Task Structure
The subagent receives a structured task with the following prompt:

```
Generate 5-10 diverse, improved descriptions for a Vibe CLI skill.

Skill: {{skill_name}}
Current Description: {{current_description}}
Skill Content Preview:
{{skill_content_preview}}

Requirements:
- Preserve the meaning and intent of the original
- Use proper capitalization (first word capitalized)
- Target length: 10-15 words
- Include action-oriented language
- Avoid redundancy
- Each candidate must be distinct from others

Output format: JSON array of candidate strings
```

### Invocation
Uses the `task` tool with the `explore` profile:

```json
{
  "task": "Generate 5-10 diverse, improved descriptions for a Vibe CLI skill.\n\nSkill: {{skill_name}}\nCurrent Description: {{current_description}}\nSkill Content Preview: {{skill_content_preview}}\n\nRequirements:\n- Preserve meaning and intent\n- Proper capitalization\n- Target: 10-15 words\n- Action-oriented\n- Avoid redundancy\n- Distinct candidates\n\nOutput: JSON array of strings",
  "agent": "explore"
}
```

### Temperature Setting
Uses literal temperature parameter in subagent prompt:
- "Use high creativity (temperature: 0.9) to generate diverse rewordings"

## Input

$ARGUMENTS

Accepts:
- **Skill pattern**: `mossy-*` or `mossy-skill` or `*-analyze` (glob pattern to match skills)
- **Empty**: Optimize all mossy skills by default
- **Single skill name**: `mossy-skill` (optimize specific skill)
- **`--regenerate-triggers`**: Regenerate TRIGGERS.md files using LLM
- **`--generate-triggers <skill_dir>`**: Generate TRIGGERS.md for a specific skill using LLM

## Entry Point

When invoked via `/mossy:skill` command:

```python
# Parse arguments
import re

args = $ARGUMENTS if $ARGUMENTS else ""

# Check for trigger generation flags
generate_triggers_only = "--generate-triggers" in args
regenerate_all_triggers = "--regenerate-triggers" in args

if generate_triggers_only or regenerate_all_triggers:
    # Handle TRIGGERS.md generation
    if generate_triggers_only:
        # Extract skill_dir from args
        skill_dir = extract_skill_dir_from_args(args)
        generate_triggers_file(skill_dir)
    elif regenerate_all_triggers:
        # Regenerate all TRIGGERS.md files
        skill_dirs = find_skill_directories()
        for skill_dir in skill_dirs:
            generate_triggers_file(skill_dir)
    return

# Normal workflow: generate TRIGGERS.md + optimize descriptions
pattern = args if args else "*"
skill_dirs = find_skills_matching_pattern(pattern)

# Step 1: Generate TRIGGERS.md for all skills
for skill_dir in skill_dirs:
    triggers_file = os.path.join(skill_dir, "TRIGGERS.md")
    if not os.path.exists(triggers_file):
        generate_triggers_file(skill_dir)
    else:
        # Validate existing TRIGGERS.md
        if not validate_triggers_file(skill_dir):
            generate_triggers_file(skill_dir)

# Step 2: Call mossy-skill.sh for description optimization
# Use bash tool to invoke the bash script with --skip-triggers flag
# since SKILL.md already generated TRIGGERS.md
bash_command = f"bash {SCRIPT_DIR}/mossy-skill.sh --skip-triggers {pattern}"
bash(command=bash_command)
```

Examples:
- `/mossy:skill mossy-*` - Optimize all mossy skills
- `/mossy:skill mossy-skill` - Optimize just the mossy-skill
- `/mossy:skill` - Optimize all skills in .vibe/skills/

## Candidate Generation Logic

### Generation Function
Coordinates subagent invocation and candidate processing:

```python
def generate_candidates(skill_name, current_description, skill_content):
    """
    Generate 5-10 diverse candidate descriptions using subagent.
    
    Returns:
        List of 5-10 candidate description strings
    """
    # Build subagent prompt
    prompt = build_subagent_prompt(skill_name, current_description, skill_content)
    
    # Invoke subagent
    result = task(task=prompt, agent="explore")
    
    # Parse JSON response
    try:
        candidates = json.loads(result)
    except:
        candidates = []
    
    # Validate candidates
    valid_candidates = [c for c in candidates if is_valid_candidate(c)]
    
    return valid_candidates[:10]  # Return max 10
```

## Deduplication

### Auto-Deduplication Logic
```python
def deduplicate_candidates(candidates):
    """Remove exact and near-duplicates, keep first occurrence."""
    unique = []
    seen = set()
    
    for c in candidates:
        normalized = normalize_candidate(c)
        if normalized not in seen and not any(
            similarity(normalize_candidate(ex), normalized) > 0.9 
            for ex in unique
        ):
            seen.add(normalized)
            unique.append(c)
    
    return unique
```

## Activation Testing

### Testing Function
```python
def test_candidate_activations(candidates, prompts):
    """Test each candidate against activation prompts."""
    return {c: vibe_test_prompts(c, prompts) for c in candidates}
```

## Best Candidate Selection

### Selection Logic
```python
def select_best_candidate(results, current_description, current_rate):
    """Select candidate with highest activation rate."""
    best = (current_description, current_rate)
    for c, rate in results.items():
        if rate > best[1]:
            best = (c, rate)
    return best
```

## False Activation Validation

### Validation Function
```python
FALSE_PROMPTS = ["create a spec draft", "plan the workflow", "review the changes"]

def validate_no_false_activations(candidate, original):
    """Ensure no increase in false activations."""
    orig_rate = vibe_test_prompts(original, FALSE_PROMPTS)
    cand_rate = vibe_test_prompts(candidate, FALSE_PROMPTS)
    return cand_rate <= orig_rate
```

## Fallback Logic

### Fallback Implementation
```python
def generate_candidates_with_fallback(...):
    """Generate candidates with fallback to conservative algorithm."""
    try:
        return generate_candidates(...) or fallback_candidates()
    except:
        return fallback_candidates()


def fallback_candidates(desc):
    """Conservative: minor variations only."""
    return [desc, desc + " for better Vibe activation", desc.rstrip('.'), desc.capitalize()]
```

## Improved vibe_simulate_activation

### Enhanced Version
```bash
# Improved with verb weighting and position awareness
vibe_simulate_activation() {
    # ... (enhanced implementation with better matching)
    return 0  # or 1
}
```

## Automated Tests

### Test Structure
- mossy-skill_test.sh with 5 test cases
- Test fixtures: mossy-test-simple, mossy-test-complex, mossy-test-optimal

## Main Execution Flow

```bash
See [mossy-skill.sh](./mossy-skill.sh) for implementation
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
See [mossy-skill.sh](./mossy-skill.sh) for implementation
```

### Prompt Generation Implementation

```bash
See [mossy-skill.sh](./mossy-skill.sh) for implementation
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
See [mossy-skill.sh](./mossy-skill.sh) for implementation
```

## TRIGGERS.md Generation

Generate TRIGGERS.md files using LLM-based trigger phrase generation. This replaces the deterministic `generate_positive_triggers()` and `generate_negative_triggers()` functions in mossy-skill.sh.

### Generation Process

1. **Read Skill Content**: Use `read_file` tool to read the target skill's SKILL.md
2. **Generate Triggers**: Use `task` tool to spawn a subagent that:
   - Reads the full SKILL.md content
   - Understands what the skill does
   - Generates natural, diverse trigger phrases that users would actually type
   - Generates both "Should Trigger" and "Should Not Trigger" sections
   - Ensures at least 10 phrases per category
3. **Write File**: Use `write_file` tool to write TRIGGERS.md directly

### Subagent Prompt

```
You are an expert at generating trigger phrases for Vibe CLI skills.

**Skill to analyze**: {skill_name}
**Skill directory**: {skill_dir}

**Task**: Generate trigger phrases for this skill's TRIGGERS.md file.

**Requirements**:
- Read the skill's SKILL.md file carefully
- Understand the skill's purpose, functionality, and use cases
- Generate natural trigger phrases that users would actually type
- Avoid robotic/ formulaic variations (e.g., "use skill", "run skill")
- Focus on what the skill actually DOES

**Output Format**:
Generate TWO sections with at least 10 phrases each:

## Should Trigger
- <natural phrase users would type when they want this skill>
- <another natural phrase>
...

## Should Not Trigger
- <phrase that should NOT trigger this skill>
- <another negative phrase>
...

**Quality Criteria**:
- Natural, user-like language
- Diverse and specific
- Context-aware (understands skill functionality)
- Mix of lengths (short phrases and full sentences)
- No deterministic variations of the skill name
```

### Implementation Function

```python
def generate_triggers_file(skill_dir):
    """
    Generate TRIGGERS.md for a skill using LLM-based generation.
    
    Args:
        skill_dir: Path to the skill directory containing SKILL.md
    
    Returns:
        Path to the generated TRIGGERS.md file
    """
    skill_name = os.path.basename(skill_dir)
    skill_file = os.path.join(skill_dir, "SKILL.md")
    triggers_file = os.path.join(skill_dir, "TRIGGERS.md")
    
    # Read skill content
    skill_content = read_file(path=skill_file)
    
    # Build subagent task
    task_prompt = f"""
You are an expert at generating trigger phrases for Vibe CLI skills.

**Skill to analyze**: {skill_name}
**Skill directory**: {skill_dir}

**Skill Content**:
{skill_content[:4000]}  # First 4000 chars for context

**Task**: Generate trigger phrases for this skill's TRIGGERS.md file.

**Requirements**:
- Understand the skill's purpose from its content
- Generate at least 10 natural trigger phrases for "Should Trigger"
- Generate at least 10 natural trigger phrases for "Should Not Trigger"
- Phrases should be what users would actually type
- Avoid formulaic variations ("use X", "run X", "execute X")
- Focus on the skill's actual functionality

**Output Format**:
# TRIGGERS.md - {skill_name}

## Should Trigger
- <phrase 1>
- <phrase 2>
...

## Should Not Trigger
- <phrase 1>
- <phrase 2>
...
    """
    
    # Invoke subagent to generate triggers
    result = task(
        task=task_prompt,
        agent="explore"
    )
    
    # Parse result (expecting markdown format)
    triggers_content = result
    
    # Write TRIGGERS.md
    write_file(
        path=triggers_file,
        content=triggers_content,
        overwrite=True
    )
    
    return triggers_file
```

### Validation Function

```python
def validate_triggers_file(skill_dir):
    """
    Validate that TRIGGERS.md has enough phrases.
    
    Args:
        skill_dir: Path to the skill directory
    
    Returns:
        True if valid, False if needs regeneration
    """
    MIN_PHRASES = 10
    triggers_file = os.path.join(skill_dir, "TRIGGERS.md")
    
    if not os.path.exists(triggers_file):
        return False
    
    content = read_file(path=triggers_file)
    
    # Count positive triggers
    positive_section = content.split("## Should Trigger")[1].split("## Should Not Trigger")[0] if "## Should Trigger" in content else ""
    positive_count = len([line for line in positive_section.split('\n') if line.strip().startswith('- ') and line.strip() != '-'])
    
    # Count negative triggers
    negative_section = content.split("## Should Not Trigger")[1] if "## Should Not Trigger" in content else ""
    negative_count = len([line for line in negative_section.split('\n') if line.strip().startswith('- ') and line.strip() != '-'])
    
    return positive_count >= MIN_PHRASES and negative_count >= MIN_PHRASES

def find_skill_directories():
    """Find all skill directories with SKILL.md files."""
    # Use bash tool to find skills
    result = bash(command="find .vibe/skills/ -type d -name 'mossy-*' | sort")
    skill_dirs = result.strip().split('\n')
    # Filter to only directories with SKILL.md
    valid_dirs = [d for d in skill_dirs if os.path.exists(os.path.join(d, "SKILL.md"))]
    return valid_dirs

def extract_skill_dir_from_args(args):
    """Extract skill directory from --generate-triggers argument."""
    # Simple parsing: find the argument after --generate-triggers
    parts = args.split()
    if "--generate-triggers" in parts:
        idx = parts.index("--generate-triggers")
        if idx + 1 < len(parts):
            return parts[idx + 1]
    return None
```

### Integration with ensure_triggers

When ensuring TRIGGERS.md exists and is valid:
1. Check if TRIGGERS.md exists
2. If not, or if it has insufficient phrases, call `generate_triggers_file()`
3. Validate the generated file has at least 10 phrases per category
4. If validation fails, regenerate or supplement

## Quick commands
- `cd /workspaces/mossy-slop && find .vibe/skills/ -name "SKILL.md" | wc -l`
- `cd /workspaces/mossy-slop && grep -r "description:" .vibe/skills/ --include="SKILL.md" | head -10`
- `cd /workspaces/mossy-slop && bash .vibe/skills/mossy-skill/SKILL.md --test` (smoke test)
- `cd /workspaces/mossy-slop && .vibe/skills/mossy-scripts/flowctl.sh validate` (validate all specs)

### Smoke Tests

```bash
See [mossy-skill.sh](./mossy-skill.sh) for implementation
```

### Description Optimization Implementation

```bash
See [mossy-skill.sh](./mossy-skill.sh) for implementation
```

## GUARDRAILS

- **CRITICAL: ONLY modify skill frontmatter description fields**
- **IMPORTANT**: Always preserve original description in backup
- **DO NOT modify skill implementation logic**
- **DO NOT create new skills** - only optimize existing ones
- **DO NOT change skill activation mechanism** - only improve descriptions
- **ALL modifications tracked with error recording**
- **User retains full control** - can review and revert any changes
- You MUST use the `ask_user_question` tool for every question that requires user judgment.
- When committing work done here, even later, sign off with coauthor given by `load-mossy-config.sh CO_AUTHORED_BY <spec-id>`
