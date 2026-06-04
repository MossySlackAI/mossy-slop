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
   - Call scripts: `ensure-flow-dir.sh`, `generate-spec-id.sh`, `record-issue.sh`
   - Use `flowctl.sh` for all `.flow/` operations
   - Call `../mossy-scripts/ensure-flow-dir.sh` to create `.flow/specs/`

2. **Phase 2: Validate Input**
   - If $ARGUMENTS is empty or whitespace-only, prompt user for idea text using ask_user_question (header max: 11 chars)
   - Strip leading/trailing whitespace from idea text

3. **Phase 3: Generate Spec ID**
   - Call `../mossy-scripts/generate-spec-id.sh "<idea-text>"` to get JSON with spec_id field

4. **Phase 4: Create Spec File**
   - Use `echo "$content" | ../mossy-scripts/write-flow-file.sh "specs/<spec-id>"` to write to `.flow/specs/<spec-id>`
   - Title: Capitalize first letter of each word in idea text
   - Goal: The idea text as provided

5. **Phase 5: Output Result**
   - Print: `Spec written to .flow/specs/<spec-id>`
   - Print: `Next: /mossy-interview <spec-id-without-.md>`

## Error Recording

This skill records errors to `.flow/issues/` following the [Issue Recording Guide](../ISSUE_RECORDING.md).

### Error Types Recorded

| Error Type | Trigger | Example |
|------------|---------|---------|
| tool-error | Vibe tool calls fail | write-flow-file.sh write to non-writable .flow/specs/ |
| validation-error | Input format invalid | Empty or whitespace-only idea text (before prompt) |
| resource-error | Required resources missing | .flow/specs/ directory creation fails |

### Integration Code

```bash
# At skill start, setup directories
../mossy-scripts/ensure-flow-dir.sh >/dev/null 2>&1 || true

# When write-flow-file.sh fails
if ! echo "$content" | ../mossy-scripts/write-flow-file.sh "specs/$(basename "$spec_path")" 2>/dev/null; then
    ../mossy-scripts/record-issue.sh --skill "mossy-idea" --error-type "tool-error" \
        --tool "write-flow-file.sh" --target "$spec_path" \
        --error "write-flow-file.sh failed: permission denied or path invalid" \
        --context "Phase: spec creation, Attempting to write spec file" || true
fi

# When spec ID generation fails
spec_json=$(../mossy-scripts/generate-spec-id.sh "$idea" 2>/dev/null) || {
    ../mossy-scripts/record-issue.sh --skill "mossy-idea" --error-type "logic-error" \
        --tool "generate-spec-id.sh" --target "$idea" \
        --error "Could not generate spec ID" \
        --context "Phase: ID generation" || true
}
spec_id=$(echo "$spec_json" | jq -r '.spec_id')
```

**Note:** Use `|| true` to prevent recording failures from breaking skill execution.
