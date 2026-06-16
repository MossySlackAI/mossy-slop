---
name: mossy-skill
description: Optimize skill frontmatter descriptions for better Vibe activation
argument-hint: "[pattern|--regenerate-triggers|--generate-triggers]"
axis: 1
---

# IMPORTANT: This command MUST invoke the skill `mossy-skill`

Pass $ARGUMENTS to the skill. The skill handles all logic.

## Usage

```
/mossy:skill mossy-*                    # Optimize all mossy skills
/mossy:skill mossy-skill               # Optimize just mossy-skill
/mossy:skill                           # Optimize all skills in .vibe/skills/
/mossy:skill "*-analyze"               # Optimize all analyze-related skills
/mossy:skill --regenerate-triggers     # Regenerate TRIGGERS.md for all skills
/mossy:skill --generate-triggers mossy-review  # Generate TRIGGERS.md for specific skill

    Optional switches: -v for verbose mode, --v for very verbose mode
```

## What it does

1. **Description Optimization**: Optimizes skill frontmatter descriptions for better Vibe auto-activation
2. **TRIGGERS.md Generation**: Generates LLM-based natural trigger phrases for skill activation testing
3. **Skill Selection**: Accepts glob patterns to select which skills to process
4. **Prompt Generation**: Creates sample prompts to test activation
5. **Vibe Simulation**: Tests if prompts would activate the skill based on description
6. **Validation**: Ensures no false activations while improving activation rate
7. **Modification**: Directly updates skill frontmatter with optimized descriptions

## Key Features

- **Pattern Matching**: Supports glob patterns (`mossy-*`, `*-analyze`, etc.)
- **LLM-based TRIGGERS.md**: Generates natural, diverse trigger phrases using subagents
- **Vibe Simulation**: Predicts skill activation based on description matching
- **Direct Modification**: Automatically updates skill frontmatter files
- **Error Recording**: Logs all errors to `.flow/issues/`
- **Safe Optimization**: Validates improvements before applying changes

## Flags

| Flag | Description |
|------|-------------|
| `--regenerate-triggers` | Regenerate TRIGGERS.md files for all mossy skills using LLM-based generation |
| `--generate-triggers <skill>` | Generate TRIGGERS.md for a specific skill directory |

## Examples

### Description Optimization

Optimize all mossy skills:
```bash
/mossy:skill mossy-*
```

Optimize a specific skill:
```bash
/mossy:skill mossy-review
```

Optimize all skills (default):
```bash
/mossy:skill
```

### TRIGGERS.md Generation

Regenerate TRIGGERS.md for all skills:
```bash
/mossy:skill --regenerate-triggers
```

Generate TRIGGERS.md for a specific skill:
```bash
/mossy:skill --generate-triggers mossy-skill
```

## Pattern Examples

| Pattern | Matches |
|---------|---------|
| `mossy-*` | All mossy skills |
| `mossy-skill` | Only the mossy-skill |
| `*-analyze` | All skills ending with -analyze |
| `mossy-?` | Single character mossy skills |

## Integration

The command automatically:
- Finds matching skills in `.vibe/skills/` directory
- Creates backup of original descriptions
- Generates TRIGGERS.md files using LLM-based natural trigger phrases
- Applies optimization criteria from the spec
- Records errors to `.flow/issues/`
- Respects the mossy workflow conventions

## Next Steps

After optimization, verify results with:
- Check modified skill frontmatter descriptions
- Review generated TRIGGERS.md files for natural, diverse phrases
- Test skill activation with relevant prompts
- Review `.flow/issues/` for any recorded errors
