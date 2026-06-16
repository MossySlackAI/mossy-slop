---
name: mossy-interview
description: Technical interview to refine specs before planning
user-invocable: false
allowed-tools: read_file,grep,bash,ask_user_question
---

# mossy-interview

**CRITICAL: ONLY writes to `.flow/specs/`**

Technical interview skill. Extracts implementation details via targeted questions, then refines spec.

## Input

Full request: $ARGUMENTS

| Type | Example | Action |
|------|---------|--------|
| Flow spec ID | `fn-1-add-oauth` | Read or create |
| Flow task ID | `fn-1-add-oauth.2` | Read parent spec |
| File path | `docs/spec.md` | Read or confirm creation |
| Idea text | `Add OAuth2 support` | Create minimal spec |
| Empty | - | Prompt for target |

## Role

Technical interviewer. ONLY writes to `.flow/specs/`.

## Flow

### Phase 0: Parse Input

Detect input type:

1. **Flow spec ID pattern**: `fn-\d+(-[a-z0-9-]+)?`
   - Read: `read_file path=".flow/specs/<id>.md"`
   - If not exists: create minimal spec

2. **File path**: contains `/` or ends with `.md`
   - Read file
   - If not exists: ask user to confirm creation

3. **Idea text**: everything else
   - Create minimal spec with goal = text

### Phase 1a: Parse Config Overrides

If input is idea text, scan for config overrides in format `key=value`:
- `commit-policy=manual|auto-per-change|auto-per-spec|batch`
- `new-branch-per-spec=true|false`
- `auto-push=true|false`
- `co-authored-by=<string>` (freeform, supports spaces if quoted)

Override global config defaults with parsed values.
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
1. Grep for similar features
2. Check conventions (naming, structure, patterns)
3. Identify dependencies
4. Surface contradictions with user statements

### Phase 3: Technical Interview

**CRITICAL REQUIREMENT**: You MUST use the `ask_user_question` tool for every question that requires user judgment.

- ONLY ask questions via ask_user_question tool calls
- Group 2-4 related questions per tool call when they share context
- Expect 5-20 questions for typical specs

**Question Format: Lead with Recommendation**

Every `ask_user_question` call must include recommended option AND confidence tier.

Pattern:
```
<options summary>. Recommended: <X> — <rationale>. Confidence: [high|judgment-call|your-call].
```

Confidence tiers:
- `[high]` — strong codebase signal
- `[judgment-call]` — reasonable disagreement possible
- `[your-call]` — no signal, defer to user (mandatory when applicable)

Options: neutral labels only.

**ask_user_question Tool Usage:**

JSON structure:
- `questions`: array (1-4 questions)
- Each question: `question` (string), `options` (array of 2-4 choice objects)
- Each option: `label` (string), `header` (1-11 chars max)
- Optional: `description`, `multi_select`, `hide_other`, `footer_note`

Example:
```json
{"questions": [{"question": "What DB?", "header": "DB", "options": [{"label": "PostgreSQL"}, {"label": "MongoDB"}, {"label": "SQLite"}]}]}
```

### Phase 4: Question Tree Navigation

Rules:
1. Cap branch depth at 4
2. Adapt based on prior answers
3. Surface pruned branches explicitly
4. One `ask_user_question` call per turn

Example:
```
Q: "Need persistence?"
A: "No"
[prune DB questions]
Q: "Skipped DB. Next: state across reloads?"
```

### Phase 5: Code-versus-assertion Contradiction

When code disagrees with user assertion:

Surface as `ask_user_question`:
- **header**: `Mismatch?`
- **body**: `Code: <X> at <file:line>; you: <Y>. Recommended: <option>. Confidence: [<tier>].`
- **options**: `match-code`, `update-code`, `clarify`

Confidence: `[high]` for unambiguous evidence, `[judgment-call]` for interpretation. Never pick silently.

### Phase 6: Write Refined Spec

Write refined spec using flowctl skeleton format (Overview, Scope, Approach, Quick commands, Acceptance, References, Resolved via Codebase).

Use `echo "$content" | flowctl.sh spec set-plan --file - <id>`.

**Format**:
- Acceptance: `- [ ] criterion text`
- Quick commands: populated
- Preserve user decisions

### Phase 7: Handoff to Plan

Output:
```
Interview complete for <spec-id>. Spec: .flow/specs/<id>.md
Next: /mossy:finish <spec-id> or /mossy:plan <spec-id>
```

## Question Bank: Technical

Load questions from `skills/mossy-interview/questions-technical.md`.

### Categories (dependency order):

1. **Scope** - In/out of scope, boundaries
2. **Architecture** - Components, dependencies, integration
3. **Data Models** - Structures, persistence, state
4. **API Contracts** - Interfaces, endpoints, shapes
5. **Edge Cases** - Failures, boundaries
6. **Performance** - Scale, latency, memory
7. **Security** - Auth, validation, sensitivity
8. **Testing** - Unit/integration/E2E
9. **Migration** - Breaking changes, rollback, flags
10. **Acceptance** - "Done" criteria

### Standard Acceptance Criteria

- [ ] Automated tests written (TDD for new features, fail-first for bugs, pass-first for refactoring)
- [ ] All automated tests pass
- [ ] Documentation updated
- [ ] AGENTS.md files updated for structural changes

### Question Selection

Ask only **non-obvious** questions. Skip questions that:
- Can be answered by codebase investigation
- Are obvious given the context
- Would produce boilerplate answers

## Spec Format

Specs use **flowctl canonical skeleton format** (call `flowctl.sh spec skeleton`)

## Error Recording

This skill records errors to `.flow/issues/` following the [Issue Recording Guide](mossy-scripts/ISSUE_RECORDING.md).

### Error Types Recorded

| Error Type | Trigger | Example |
|------------|---------|---------|
| tool-error | Vibe tool calls fail | flowctl.sh spec set-plan fails |
| validation-error | Input format invalid | Invalid Flow ID pattern, missing required sections |
| logic-error | Internal logic fails | Circular question dependency, invalid spec state |
| resource-error | Required resources missing | .flow/specs/ directory not writable |
| configuration-error | Environment issue | flowctl.sh not found |

**Note**: Always use `|| true` to prevent recording failures from breaking skill execution.

## Not in Scope

- Business questions
- Task creation (`/mossy:plan`)
- Implementation (`/mossy:work`)

## GUARDRAILS

- ONLY writes to `.flow/specs/<id>.md`
- Read local AGENTS.md
- Use flowctl.sh (never flowctl.py)
- No task/plan creation
