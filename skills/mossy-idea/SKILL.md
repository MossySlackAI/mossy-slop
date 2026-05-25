---
name: mossy-idea
description: Write a minimal spec file draft into .flow/specs/ for later refinement with mossy-interview.
user-invocable: true
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

1. **Phase 1: Validate Input**
   - If $ARGUMENTS is empty or whitespace-only, prompt user for idea text using ask_user_question
   - Strip leading/trailing whitespace from idea text

2. **Phase 2: Generate Spec ID**
   - List existing spec files in `.flow/specs/fn-*.md`
   - Extract all N values from filenames matching pattern `fn-(\d+)-`
   - Find maximum N, increment by 1
   - If no existing specs, start from N=1
   - Slugify idea text:
     - Convert to lowercase
     - Replace spaces and underscores with hyphens
     - Remove all characters except alphanumeric and hyphens
     - Remove leading/trailing hyphens
   - Format: `fn-<N>-<slug>.md`

3. **Phase 3: Create Spec File**
   - Ensure `.flow/specs/` directory exists (mkdir -p)
   - Create `.flow/specs/fn-<N>-<slug>.md`
   - Title: Capitalize first letter of each word in idea text
   - Goal: The idea text as provided

4. **Phase 4: Output Result**
   - Print: `Spec written to .flow/specs/fn-<N>-<slug>.md`
   - Print: `Next: /mossy-interview fn-<N>-<slug>`

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
# At skill start, source the recording utility
source scripts/record-issue.sh 2>/dev/null || true

# When write_file fails
if ! write_file path="$spec_path" content="$content" 2>/dev/null; then
    record_issue "mossy-idea" "tool-error" "write_file" "$spec_path" \
        "write_file failed: permission denied or path invalid" \
        "Phase: spec creation, Attempting to write spec file" || true
fi

# When no valid spec ID can be generated
if [ -z "$next_n" ]; then
    record_issue "mossy-idea" "logic-error" "N/A" "$idea" \
        "Could not determine next spec number from existing files" \
        "Phase: ID generation, No existing specs found and N=1 failed" || true
fi
```

**Note:** Use `|| true` to prevent recording failures from breaking skill execution.
