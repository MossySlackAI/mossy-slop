---
name: mossy-idea
description: "Create minimal spec from idea, note, or record for later implementation"
user-invocable: false
allowed-tools: bash, ask_user_question
---

# mossy-idea

Write a minimal spec file draft into `.flow/specs/` for later refinement with `mossy-interview`. This skill is intentionally minimal — it only creates the initial Title and Goal sections, leaving all other details to the interview process.

## Input

$ARGUMENTS

Accepts:
- Idea text: `Add dark mode` (creates minimal spec)

## Flow

1. **Phase 2: Validate Input**
   - If $ARGUMENTS is empty or whitespace-only, prompt user for idea text using ask_user_question (header max: 11 chars)
   - Strip leading/trailing whitespace from idea text

2. **Phase 3: Create Spec File**
   - Use `flowctl.sh spec create --title "<title>"` to create new spec with skeleton
   - Capture spec_id from output (format: `Spec fn-N-<slug> created: <title>`)
   - Or scan `.flow/specs/` for newest spec matching pattern `fn-*-<slug>.md`
   - Read generated skeleton from `.flow/specs/<spec-id>.md`
   - Replace "## Overview\nTBD" with "## Overview\n<goal-content>" where goal-content is the idea text
   - Write back using `echo "$content" | flowctl.sh spec set-plan --file - <spec-id>`
   - Title: Capitalize first letter of each word in idea text (passed to spec create)

3. **Phase 4: Output Result**
   - Print: `Spec written to .flow/specs/<spec-id>`
   - Print: `Next: /mossy-slop:interview <spec-id-without-.md>`

**Note:** Use `|| true` to prevent script failures from breaking skill execution.

## GUARDRAILS

- **CRITICAL: NO actual work, no thinking, no planning, no reading. ONLY output: spec file to `.flow/specs/<id>.md` via flowctl.sh**
- Use `flowctl.sh`
- Only modify files in `.flow/specs/`
- You MUST use the `ask_user_question` tool for every question that requires user judgment.
- When committing work done here, even later, sign off with coauthor given by `load-mossy-config.sh CO_AUTHORED_BY <spec-id>`
