---
name: mossy-interview
description: Technical interview to refine specs and clarify requirements before planning. Asks targeted questions to extract implementation details, similar to flow-next interview but technical mode only.
user-invocable: false
allowed-tools: read_file,grep,bash,ask_user_question
---

# mossy-interview

**CRITICAL: ONLY writes spec files to `.flow/specs/`. No other work.**

**IMPORTANT**: Always read local AGENTS.md in the subdirectories you are investigating.

Technical interview skill for mossy code flow. Extracts implementation details via targeted questions, then creates or refines a spec.

**Inspiration**: flow-next interview skill (technical mode only, no business mode overhead).

**Focus**: The code is the single source of truth. Inline comments provide documentation. Human retains full control and responsibility.

**Token efficiency**: Ask only non-obvious questions. Investigate codebase before asking. Speed and token conservation valued higher than exhaustive questioning.

## Purpose

**ONLY produces a spec file.** Extract complete technical implementation details before planning:
- Clarify requirements that need human judgment
- Investigate codebase for answerable questions (don't ask about what grep can find)
- Surface contradictions between user statements and existing code
- Produce a refined spec ready for `/mossy:plan`

## Input

Full request: $ARGUMENTS

Accepts:
- **Flow spec ID**: `fn-N-slug` (e.g., `fn-1-add-oauth`) or legacy `fn-N`/`fn-N-xxx`
- **Flow task ID**: `fn-N-slug.M` (e.g., `fn-1-add-oauth.2`) or legacy `fn-N.M`
- **File path**: `docs/spec.md` or similar
- **Idea text**: `Add OAuth2 support` (creates minimal spec first)
- **Empty**: Prompt for target

Examples:
- `/mossy:interview fn-1-add-oauth`
- `/mossy:interview fn-1-add-oauth.3`
- `/mossy:interview docs/oauth-spec.md`
- `/mossy:interview Add OAuth2 support`

## Role

Technical interviewer, spec refiner. No implementation. No files outside `.flow/specs/`.

## Guardrails

- **CRITICAL: NO actual work. ONLY output: spec file to `.flow/specs/<id>.md`**
- **Never use markdown TODOs**
- **Never use TodoWrite**
- **All state in `.flow/`**
- **Spec IDs immutable once created**
- **R-IDs frozen at interview time**
- **Do NOT create tasks** - that's plan's job
- **Technical mode ONLY** - no business questions

## Flow

### Phase 0: Setup

```bash
# Source required utilities
source ../mossy-scripts/ensure-flow-dir.sh 2>/dev/null || true
source ../mossy-scripts/load-mossy-config.sh 2>/dev/null || true
source ../mossy-scripts/record-issue.sh 2>/dev/null || true

# Setup directories
ensure_flow_dir || true

# Load config
load_mossy_config || true

# Use mossy-flowctl for all .flow/ operations
```

### Phase 1: Parse Input

Detect input type:

1. **Flow spec ID pattern**: `fn-\d+(-[a-z0-9-]+)?`
   - Read: `read_file path=".flow/specs/<id>.md"`
   - If not exists: create minimal spec

2. **Flow task ID pattern**: `fn-\d+(-[a-z0-9-]+)?\.\d+`
   - Extract spec ID, read parent spec
   - Read task file if exists

3. **File path**: contains `/` or ends with `.md`
   - Read file
   - If not exists: ask user to confirm creation

4. **Idea text**: everything else
   - Create minimal spec with goal = text

### Phase 1a: Parse Config Overrides

If input is idea text, scan for config overrides in format `key=value`:
- `commit-policy=manual|auto-per-change|auto-per-spec|batch`
- `new-branch-per-spec=true|false`
- `auto-push=true|false`
- `co-authored-by=<string>` (freeform, supports spaces if quoted)

Override global config defaults with parsed values, then apply R3 logic.
For co-authored-by, extract value after `=` (handles quoted strings for spaces).

### Phase 2: Pre-Question Codebase Investigation

**CRITICAL**: Before every question, classify it:

| Category | Action | Examples |
|----------|--------|----------|
| **Codebase-answerable** | Agent investigates (Read/Grep/Glob) | "What DB is used?" / "Where do routes live?" / "What test framework?" |
| **User-judgment-required** | Ask via `ask_user_question` | "Should we add caching?" / "What priority for offline?" / "Performance or simplicity?" |

**Rule**: If you find yourself answering a "should" question via grep, STOP and ask the user.

**Audit trail**: Codebase-resolved items go to `## Resolved via Codebase` section with file:line evidence.

Investigation order:
1. Grep for existing implementations of similar features
2. Check project conventions (naming, file structure, patterns)
3. Identify existing dependencies and integrations
4. Surface contradictions with user statements

### Phase 3: Technical Interview

**CRITICAL REQUIREMENT**: You MUST use the `ask_user_question` tool for every question that requires user judgment.

- DO NOT output questions as text
- DO NOT list questions in your response
- ONLY ask questions via ask_user_question tool calls
- Group 2-4 related questions per tool call when they share context
- Expect 5-20 questions for typical specs

**Question Format: Lead with Recommendation**

Every `ask_user_question` call must include the agent's recommended option AND a confidence tier.

Pattern:
```
<options summary>. Recommended: <X> — <one-sentence rationale>. Confidence: [high | judgment-call | your-call].
```

Confidence tiers (mandatory):
- `[high]` — strong codebase signal or convention match. User can usually accept.
- `[judgment-call]` — slight lean but reasonable people disagree. User's call carries weight.
- `[your-call]` — agent has no signal. Defer to user.

The `[your-call]` tier is **mandatory** when the agent has no basis for a recommendation.

Options should be neutral labels (no "(recommended)" markers).

**ask_user_question Tool Usage:**

Use the `ask_user_question` tool with proper JSON structure:
- **Tool name**: `ask_user_question` (lowercase, with underscores)
- **Required parameter**: `questions` array (1-4 questions)
- **Each question must have**: `question` (string) and `options` (array of 2-4 choice objects)
- **Each option must have**: `label` (string), optionally `description` (string)
- **Optional parameters**: `header` (1-11 chars max), `multi_select` (boolean), `hide_other` (boolean), `footer_note` (string)

Example tool call:
```json
{
  "questions": [
    {
      "question": "What database should we use for this feature?",
      "header": "Database",
      "options": [
        {"label": "PostgreSQL", "description": "Relational, ACID compliant"},
        {"label": "MongoDB", "description": "Document store, flexible schema"},
        {"label": "SQLite", "description": "File-based, lightweight"}
      ]
    }
  ]
}
```

### Phase 4: Question Tree Navigation

Concrete rules:

1. **Cap branch depth at 4** - don't go deeper than 4 levels of follow-up
2. **Discover-as-you-go** - adapt next question based on prior answers
3. **Surface abandoned branches** - explicitly state when pruning sub-trees
4. **One `ask_user_question` call per turn** - never queue multiple tool calls back-to-back

Example:
```
Q: "Does this feature need persistence?"
A: "No, ephemeral state is fine."
[agent prunes {DB choice, schema design, migration plan}]
Q: "Skipped DB questions — you said ephemeral. Next: how should state survive page reloads?"
```

### Phase 5: Code-versus-assertion Contradiction

When grep/Read reveals code disagrees with user assertion:

Surface as `ask_user_question`:
- **header**: `Mismatch?` (max 11 chars)
- **body**: `Code shows <X> at <file:line>; you said <Y>. Recommended: <treat-code-as-source-of-truth | update-spec-to-match-code | revisit-the-area>. Confidence: [<tier>].`
- **options**: `match-code` (revise spec to align), `update-code` (treat assertion as goal), `clarify` (user explains)

Confidence tier:
- `[high]` when grep evidence is unambiguous
- `[judgment-call]` when interpretation is at play
- Never silently pick a side

### Phase 6: Write Refined Spec

After interview completes, write refined spec back using the **canonical spec template** defined in the [Spec Format](#spec-format) section below. Use `echo "$content" | mossy-flowctl write "specs/<id>.md"` to write to `.flow/specs/`.

**For new specs**: Create `.flow/specs/<id>.md` with the canonical structure.

**For existing specs**: Preserve existing content byte-for-byte except for:
- Append new R-IDs to Acceptance Criteria (never renumber existing)
- Write/refine technical sections (Architecture, API Contracts, Edge Cases)
- Append to Resolved via Codebase
- Add/update Mossy-Config section with effective settings

**Never overwrite**:
- Existing R-IDs (append only)
- Business sections if they exist
- User's explicit decisions

### Phase 7: Handoff to Plan

Output summary:
```
Interview complete for <spec-id>.

Spec written to .flow/specs/<id>.md

Next: /mossy:plan <spec-id> to create execution plan
```

## Question Bank: Technical

Load questions from `skills/mossy-interview/questions-technical.md`.

### Categories (in dependency order):

1. **Scope & Boundaries** - What's in/out of scope, component boundaries
2. **Architecture** - Components, dependencies, integration points, parallel work potential
3. **Data Models** - Structures, persistence needs, state management
4. **API Contracts** - Interfaces, endpoints, data shapes
5. **Edge Cases** - What can go wrong, failure modes
6. **Performance** - Scale expectations, latency, memory
7. **Security** - Auth, validation, data sensitivity
8. **Testing Strategy** - Unit/integration/E2E focus areas
9. **Migration** - Breaking changes, rollback, feature flags
10. **Acceptance Criteria** - What does "done" look like?

### Question Selection

Ask only **non-obvious** questions. Skip questions that:
- Can be answered by codebase investigation
- Are obvious given the context
- Would produce boilerplate answers

## Spec Format

Canonical spec template follows mossy convention (simplified from flow-next):

```markdown
# <Title>

## Goal
<1-2 sentences describing the objective>

## Mossy-Config
- commit-policy: <manual|auto-per-change|auto-per-spec|batch>
- new-branch-per-spec: <true|false>
- auto-push: <true|false>
- co-authored-by: <string>

## Acceptance Criteria
- R1: <verifiable criterion>
- R2: <verifiable criterion>
...

## Architecture & Data Models
- Component boundaries
- Key data structures
- State management approach

## API Contracts
- Public interfaces
- Data shapes
- Integration points

## Edge Cases & Constraints
- Error conditions
- Boundary cases
- External dependencies

## Decision Context
<Key decisions made during interview>

## Resolved via Codebase
- <item> — <file:line>
```

## Error Recording

This skill records errors to `.flow/issues/` following the [Issue Recording Guide](../ISSUE_RECORDING.md).

### Error Types Recorded

| Error Type | Trigger | Example |
|------------|---------|---------|
| tool-error | Vibe tool calls fail | mossy-flowctl write on non-writable .flow/specs/ |
| validation-error | Input format invalid | Invalid Flow ID pattern, missing required sections |
| logic-error | Internal logic fails | Circular question dependency, invalid spec state |
| resource-error | Required resources missing | .flow/specs/ directory not writable |
| configuration-error | Environment issue | Required scripts not found |

### Integration Code

```bash
# At skill start, source required utilities
source ../mossy-scripts/ensure-flow-dir.sh 2>/dev/null || true
source ../mossy-scripts/load-mossy-config.sh 2>/dev/null || true
source ../mossy-scripts/record-issue.sh 2>/dev/null || true

# Setup and load config
ensure_flow_dir || true
load_mossy_config || true

# When a tool fails during spec reading
if ! read_file path="$spec_path" 2>/dev/null; then
    record_issue "mossy-interview" "tool-error" "read_file" "$spec_path" \
        "read_file failed: file not found or permission denied" \
        "Phase: parsing, Attempting to read spec file $spec_path" || true
fi

# When mossy-flowctl write fails during spec writing
if ! echo "$spec_content" | mossy-flowctl write "specs/$(basename "$spec_path")" 2>/dev/null; then
    record_issue "mossy-interview" "tool-error" "mossy-flowctl write" "$spec_path" \
        "mossy-flowctl write failed: permission denied or path invalid" \
        "Phase: writing, Attempting to write spec file $spec_path" || true
fi

# When input format is invalid
if [[ ! "$input" =~ ^fn-[0-9]+ ]]; then
    record_issue "mossy-interview" "validation-error" "N/A" "$input" \
        "Invalid input format: expected fn-N or file path or idea text" \
        "Phase: input parsing, Input: $input" || true
fi
```

**Note**: Always use `|| true` to prevent recording failures from breaking skill execution.

## Not in Scope

- Business questions (user personas, success metrics, MVP boundaries)
- Task creation (that's `/mossy:plan`'s job)
- Implementation details (that's `/mossy:work`'s job)
- Multi-pass interview (business + technical)
- Project docs investigation (glossary, decisions, strategy)
- Decision record writing

## Key Differences from flow-next interview

| Feature | flow-next | mossy-interview |
|---------|-----------|-----------------|
| Business mode | Yes | No (technical only) |
| Question count | 40+ | 10-30 (leaner) |
| Doc-aware mode | Yes | No |
| Decision records | Yes | No |
| Glossary integration | Yes | No |
| Strategy integration | Yes | No |
| Both mode | Yes | No |
| Pre-question taxonomy | Yes | Yes (simplified) |
| Lead-with-recommendation | Yes | Yes |
| Codebase investigation | Yes | Yes |
| Contradiction surfacing | Yes | Yes |
