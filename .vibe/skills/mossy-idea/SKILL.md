---
name: mossy-idea
description: Write a minimal spec file draft into .flow/specs/ for later refinement with mossy-interview.
user-invocable: false
allowed-tools: read_file,write_file,bash,ask_user_question
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
   - Source scripts: `ensure-flow-dir.sh`, `generate-spec-id.sh`, `record-issue.sh`
   - Call `ensure_flow_dir` to create `.flow/specs/`

2. **Phase 2: Validate Input**
   - If $ARGUMENTS is empty or whitespace-only, prompt user for idea text using ask_user_question (header max: 11 chars)
   - Strip leading/trailing whitespace from idea text

3. **Phase 3: Generate Spec ID**
   - Call `generate_spec_id "<idea-text>"` to get fn-<N>-<slug>.md

4. **Phase 4: Create Spec File**
   - Create `.flow/specs/<spec-id>`
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
| tool-error | Vibe tool calls fail | write_file to non-writable .flow/specs/ |
| validation-error | Input format invalid | Empty or whitespace-only idea text (before prompt) |
| resource-error | Required resources missing | .flow/specs/ directory creation fails |

### Integration Code

```bash
# At skill start, source required utilities
source ../mossy-scripts/ensure-flow-dir.sh 2>/dev/null || true
source ../mossy-scripts/generate-spec-id.sh 2>/dev/null || true
source ../mossy-scripts/record-issue.sh 2>/dev/null || true

# Setup directories
ensure_flow_dir || true

# When write_file fails
if ! write_file path="$spec_path" content="$content" 2>/dev/null; then
    record_issue "mossy-idea" "tool-error" "write_file" "$spec_path" \
        "write_file failed: permission denied or path invalid" \
        "Phase: spec creation, Attempting to write spec file" || true
fi

# When spec ID generation fails
spec_id=$(generate_spec_id "$idea" 2>/dev/null) || {
    record_issue "mossy-idea" "logic-error" "generate-spec-id.sh" "$idea" \
        "Could not generate spec ID" \
        "Phase: ID generation" || true
}
```

**Note:** Use `|| true` to prevent recording failures from breaking skill execution.
