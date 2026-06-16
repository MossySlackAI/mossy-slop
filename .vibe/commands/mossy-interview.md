---
name: mossy-interview
description: Technical interview to refine specs before planning
argument-hint: "<spec-id|path|idea>"
axis: 1
---

# IMPORTANT: This command MUST invoke the skill `mossy-interview`

Pass $ARGUMENTS to the skill. The skill handles all logic.

## Usage

```
/mossy:interview fn-1-add-oauth      # Interview existing spec
/mossy:interview fn-1-add-oauth.2    # Interview task within spec
/mossy:interview docs/spec.md         # Interview spec file
/mossy:interview "Add OAuth2 support"  # Interview new idea
/mossy:interview                      # Prompt for target
```

## What it does

1. Extracts complete technical implementation details through deep questioning
2. Investigates codebase before asking (doesn't ask about what grep can find)
3. Surfaces contradictions between user statements and existing code
4. Produces a refined spec ready for `/mossy:plan`

## Key Features

- **Technical mode only** - no business questions (leaner than flow-next)
- **Lead-with-recommendation** - every question includes recommended option and confidence tier
- **Codebase investigation** - answers what it can from code, only asks user for judgment calls
- **Contradiction surfacing** - explicitly flags when code and spec disagree
- **Pre-planning** - clarifies requirements before task breakdown

## Next Steps

After interview completes, use `/mossy:plan <spec-id>` to create execution plan, or `/mossy:finish <spec-id>` to plan, execute and review in one go.
