---
name: mossy-skill
description: "Optimize skill frontmatter descriptions for better Vibe auto-activation"
user-invocable: false
allowed-tools: read_file, write_file, grep, bash, ask_user_question, task
---

# mossy-skill

Optimize skill frontmatter descriptions to improve Vibe auto-activation. This skill systematically analyzes existing skill frontmatter and modifies the description field to ensure skills are activated when user prompts demand functionality that the skill can provide.

> **Note**: Current implementation uses conservative algorithm. For better results, see [fn-28](.flow/specs/fn-28-improve-mossy-skill-with-subagent-generated-rewordings.md) which proposes using subagent-generated high-temperature rewordings.

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
