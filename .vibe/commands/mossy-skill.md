---
name: mossy-skill
description: Optimize skill frontmatter descriptions for better Vibe activation
argument-hint: "[pattern]"
axis: 1
---

# IMPORTANT: This command MUST invoke the skill `mossy-skill`

Pass $ARGUMENTS to the skill. The skill handles all logic.

## Usage

```
/mossy:skill mossy-*                    # Optimize all mossy skills
/mossy:skill mossy-skill               # Optimize just the mossy-skill  
/mossy:skill                           # Optimize all skills in .vibe/skills/
/mossy:skill "*-analyze"               # Optimize all analyze-related skills
```

## What it does

1. **Skill Selection**: Accepts glob patterns to select which skills to optimize
2. **Analysis**: Reads existing skill frontmatter descriptions
3. **Prompt Generation**: Creates sample prompts to test activation
4. **Vibe Simulation**: Tests if prompts would activate the skill based on current description
5. **Optimization**: Improves descriptions using specificity, action-oriented language, and length optimization
6. **Validation**: Ensures no false activations while improving activation rate
7. **Modification**: Directly updates skill frontmatter with optimized descriptions

## Key Features

- **Pattern Matching**: Supports glob patterns (`mossy-*`, `*-analyze`, etc.)
- **Vibe Simulation**: Predicts skill activation based on description matching
- **Direct Modification**: Automatically updates skill frontmatter files
- **Error Recording**: Logs all errors to `.flow/issues/`
- **Safe Optimization**: Validates improvements before applying changes

## Examples

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
- Applies optimization criteria from the spec
- Records errors to `.flow/issues/`
- Respects the mossy workflow conventions

## Next Steps

After optimization, verify results with:
- Check modified skill frontmatter descriptions
- Test skill activation with relevant prompts
- Review `.flow/issues/` for any recorded errors