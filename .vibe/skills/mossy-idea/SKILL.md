---
name: mossy-idea
description: Write a minimal spec file draft into .flow/specs/ for later refinement with mossy-interview.
user-invocable: false
allowed-tools: bash, ask_user_question
---

# mossy-idea

Write a minimal spec file draft into `.flow/specs/` for later refinement with `mossy-interview`. This skill is intentionally minimal — it only creates the initial Title and Goal sections, leaving all other details to the interview process.

## Purpose

Create a starting point for new features, changes, or ideas. Produces a minimal spec file that `mossy-interview` can then refine into a complete specification.

## Input

$ARGUMENTS

Accepts:
- Idea text: `Add dark mode` (creates minimal spec)

## Flow

1. **Phase 1: Setup**
   - Call `../mossy-scripts/ensure-flow-dir.sh` to create `.flow/specs/`
   
2. **Phase 2: Validate Input**
   - If $ARGUMENTS is empty or whitespace-only, prompt user for idea text using ask_user_question (header max: 11 chars)
   - Strip leading/trailing whitespace from idea text

3. **Phase 3: Create Spec File**
   - Use `../mossy-scripts/flowctl.sh spec create --title "<title>"` to create new spec with skeleton
   - Capture spec_id from output (format: `Spec fn-N-<slug> created: <title>`)
   - Or scan `.flow/specs/` for newest spec matching pattern `fn-*-<slug>.md`
   - Read generated skeleton from `.flow/specs/<spec-id>.md`
   - Replace "## Overview\nTBD" with "## Overview\n<goal-content>" where goal-content is the idea text
   - Write back using `echo "$content" | ../mossy-scripts/flowctl.sh spec set-plan --file - <spec-id>`
   - Title: Capitalize first letter of each word in idea text (passed to spec create)

4. **Phase 4: Output Result**
   - Print: `Spec written to .flow/specs/<spec-id>`
   - Print: `Next: /mossy:interview <spec-id-without-.md>`

### Integration Code

```bash
# At skill start, setup directories
../mossy-scripts/ensure-flow-dir.sh >/dev/null 2>&1 || true
```

**Note:** Use `|| true` to prevent recording failures from breaking skill execution.

## GUARDRAILS

 - No thinking, no planning.
 - No file reading, no file writing by any other means than flowctl.sh.

