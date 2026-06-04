---
name: mossy-idea
description: Write a minimal spec file draft into .flow/specs/ for later refinement with mossy-interview.
user-invocable: false
allowed-tools: read_file,bash,ask_user_question
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
   - Call scripts: `ensure-flow-dir.sh`, `record-issue.sh`
   - Use `flowctl.sh` for all `.flow/` operations
   - Call `../mossy-scripts/ensure-flow-dir.sh` to create `.flow/specs/`

2. **Phase 2: Validate Input**
   - If $ARGUMENTS is empty or whitespace-only, prompt user for idea text using ask_user_question (header max: 11 chars)
   - Strip leading/trailing whitespace from idea text

3. **Phase 3: Create Spec File**
   - Use `flowctl.sh spec create --title "<title>"` to create new spec with skeleton
   - Capture spec_id from output (format: `Spec fn-N-<slug> created: <title>`)
   - Or scan `.flow/specs/` for newest spec matching pattern `fn-*-<slug>.md`
   - Read generated skeleton from `.flow/specs/<spec-id>.md`
   - Replace "## Overview\nTBD" with "## Overview\n<goal-content>" where goal-content is the idea text
   - Write back using `echo "$content" | flowctl.sh spec set-plan --file - <spec-id>`
   - Title: Capitalize first letter of each word in idea text (passed to spec create)

5. **Phase 5: Output Result**
   - Print: `Spec written to .flow/specs/<spec-id>`
   - Print: `Next: /mossy:interview <spec-id-without-.md>`

## Error Recording

This skill records errors to `.flow/issues/` following the [Issue Recording Guide](../mossy-scripts/ISSUE_RECORDING.md).

### Error Types Recorded

| Error Type | Trigger | Example |
|------------|---------|---------|
| tool-error | Vibe tool calls fail | flowctl.sh spec create or spec set-plan fails |
| validation-error | Input format invalid | Empty or whitespace-only idea text (before prompt) |
| resource-error | Required resources missing | .flow/specs/ directory creation fails |

### Integration Code

```bash
# At skill start, setup directories
../mossy-scripts/ensure-flow-dir.sh >/dev/null 2>&1 || true

# When flowctl.sh spec create fails
if ! flowctl.sh spec create --title "$title" >/dev/null 2>&1; then
    ../mossy-scripts/record-issue.sh --skill "mossy-idea" --error-type "tool-error" \
        --tool "flowctl.sh" --target "spec create" \
        --error "flowctl.sh spec create failed" \
        --context "Phase: spec creation, Attempting to create spec with title: $title" || true
fi

# When flowctl.sh spec set-plan fails
if ! echo "$content" | flowctl.sh spec set-plan --file - "$spec_id" 2>/dev/null; then
    ../mossy-scripts/record-issue.sh --skill "mossy-idea" --error-type "tool-error" \
        --tool "flowctl.sh" --target "$spec_id" \
        --error "flowctl.sh spec set-plan failed: permission denied or path invalid" \
        --context "Phase: spec update, Attempting to update spec Overview section" || true
fi


```

**Note:** Use `|| true` to prevent recording failures from breaking skill execution.
