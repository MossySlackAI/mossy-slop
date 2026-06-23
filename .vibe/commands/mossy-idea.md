---
name: mossy-slop:idea
description: Write a minimal spec file draft into .flow/specs/ for later refinement with mossy-interview
argument-hint: "<idea-text>"
axis: 1
---

# IMPORTANT: This command MUST invoke the skill `mossy-idea`

Pass $ARGUMENTS to the skill. The skill handles all logic.

## Usage

```
/mossy:idea Add dark mode                    # Create spec draft for dark mode
/mossy:idea Add OAuth2 authentication       # Create spec draft for OAuth
/mossy-idea Implement caching layer          # Alternative invocation syntax
/mossy-idea "Add user profile feature"      # Idea with spaces (use quotes)
```

## What it does

1. Accepts raw idea text as input
2. Auto-generates a spec ID (fn-N-slug format)
3. Creates a minimal spec file in `.flow/specs/` with Title and Goal sections only
4. Outputs the spec ID for next steps

## Key Features

- **Minimal output**: Only creates Title and Goal, leaving all refinement to `mossy-interview`
- **Auto ID generation**: Finds highest existing fn-N and increments
- **Slug creation**: Converts idea text to URL-friendly slug
- **Directory creation**: Creates `.flow/specs/` if it doesn't exist
- **Empty input handling**: Prompts user if idea text is empty

## Next Steps

After spec draft is created, use `/mossy-interview <spec-id>` to refine the specification.
