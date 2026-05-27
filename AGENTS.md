# Mossy Slop

**Lean, token-efficient skills for planning and executing code changes.**

This repository provides alternative skills to flow-next, designed for Mistral Vibe. They are intentionally minimal — **every word costs tokens; eliminate all that are not strictly necessary.**

The original plugin source can be found at git@github.com:gmickel/flow-next.git. To reference it, clone it here into .upstream.
The ID of the last seen commit is 98372214c773ff00c0af9f73c575164c2724e093.

## Mission Statement

This is supposed to become a leaner alternative, compatible with Mistral.

The project identifier is **mossy-slop**.

The focus should be the code; the code is the single source of truth, it should be able to speak for itself. Inline comments should provide the documentation.

The human should retain full control and responsibility. They should be able to verify the quality of individual steps of the process if they want to, or later when everything is done.

It should be the user's choice whether individual steps are committed to git, and whether auto-generated plan metadata gets committed or not.

When questions arise during processing, they should be logged to the human readable output right away, but processing should continue with other parts of the job for as long as reasonably possible; the open questions should then be asked in bulk.

A reasonable effort should be made in the planning phase to discover open questions, but speed and token conservation are valued higher.

## Purpose

Aid in planning and executing code changes across:
- C++
- C#
- VB.NET
- JavaScript
- TypeScript
- GDScript
- Python

## Skill Prefix

All skills use the `mossy-` prefix.

> **Note:** The skills in `.vibe/skills/` and commands in `.vibe/commands/` are **executable** — they are invoked via slash commands and run as skills, not merely read as documentation or rough instructions.

## Architecture

### Skill Structure

Each skill lives in `.vibe/skills/mossy-<name>/` with:

```
.vibe/skills/mossy-<name>/
├── SKILL.md          # Frontmatter + high-level description
└── workflow.md       # Optional: phase-by-phase execution (if complex)
```

### Skill Frontmatter

Required fields:
```yaml
---
name: mossy-<name>
description: <concise description>
user-invocable: false
allowed-tools: <comma-separated tool list>
---
```

### Invocation

Via slash commands defined in `.vibe/commands/mossy-<name>.md`:
```yaml
---
name: mossy-<name>
description: <command description>
argument-hint: "[args]"
---
```

## Core Skills

| Skill | Command | Purpose |
|-------|---------|---------|
| `mossy-flowctl` | N/A (internal) | Wrapper for flowctl.py operations |
| `mossy-plan` | `/mossy-plan` | Create execution plan from spec |
| `mossy-interview` | `/mossy-interview` | Technical interview to refine specs before planning |
| `mossy-work` | `/mossy-work` | Execute plan tasks |
| `mossy-review` | `/mossy-review` | Review changes before commit |
| `mossy-refactor` | `/mossy-refactor` | Language-aware refactoring |
| `mossy-analyze` | `/mossy-analyze` | Static analysis across languages |

## Language-Specific Skills

| Skill | Command | Languages |
|-------|---------|-----------|
| `mossy-cpp` | `/mossy-cpp` | C++ |
| `mossy-csharp` | `/mossy-csharp` | C# |
| `mossy-vbnet` | `/mossy-vbnet` | VB.NET |
| `mossy-js` | `/mossy-js` | JavaScript |
| `mossy-ts` | `/mossy-ts` | TypeScript |
| `mossy-gdscript` | `/mossy-gdscript` | GDScript |
| `mossy-py` | `/mossy-py` | Python |

## Directory Structure

```
.
├── AGENTS.md              # This file
├── README.md             # Repository overview
├── .gitlab-ci.yml        # CI configuration
├── .vibe/                # Executable skills and commands
│   ├── skills/           # All skills
│   │   ├── mossy-flowctl/
│   │   │   └── SKILL.md
│   │   ├── mossy-plan/
│   │   │   └── SKILL.md
│   │   ├── mossy-interview/
│   │   │   ├── SKILL.md
│   │   │   └── questions-technical.md
│   │   ├── mossy-work/
│   │   │   ├── SKILL.md
│   │   │   └── workflow.md
│   │   ├── mossy-review/
│   │   │   └── SKILL.md
│   │   ├── mossy-refactor/
│   │   │   └── SKILL.md
│   │   ├── mossy-analyze/
│   │   │   └── SKILL.md
│   │   ├── mossy-cpp/
│   │   │   └── SKILL.md
│   │   ├── mossy-csharp/
│   │   │   └── SKILL.md
│   │   ├── mossy-vbnet/
│   │   │   └── SKILL.md
│   │   ├── mossy-js/
│   │   │   └── SKILL.md
│   │   ├── mossy-ts/
│   │   │   └── SKILL.md
│   │   ├── mossy-gdscript/
│   │   │   └── SKILL.md
│   │   └── mossy-py/
│   │       └── SKILL.md
│   └── commands/         # Slash command definitions
│       ├── mossy-plan.md
│       ├── mossy-interview.md
│       ├── mossy-work.md
│       ├── mossy-review.md
│       ├── mossy-refactor.md
│       ├── mossy-analyze.md
│       ├── mossy-cpp.md
│       ├── mossy-csharp.md
│       ├── mossy-vbnet.md
│       ├── mossy-js.md
│       ├── mossy-ts.md
│       ├── mossy-gdscript.md
│       └── mossy-py.md
└── scripts/             # Utility scripts
```

## Design Principles

### 1. Token Efficiency
- **Every word costs tokens. Eliminate all that are not strictly necessary.**
- No markdown fluff (emojis, gratuitous formatting)
- Direct, imperative language
- Minimal context in prompts

### 2. Language Awareness
Each language-specific skill knows:
- File extensions
- Build systems
- Common patterns
- Pitfalls
- Tooling conventions

### 3. Mistral Compatibility
- Use Mistral Vibe tool names (`ask_user_question`, `read_file`, `grep`, etc.)
- No Claude-specific assumptions
- No external dependencies

### 4. Composable
Skills can chain:
```
/mossy-plan fn-1-add-feature
/mossy-work fn-1-add-feature.1
/mossy-review
/mossy-cpp --check-style
```

## Tool Usage

All skills use the Vibe CLI tool set. Reference by canonical name:
- `read_file` - read files
- `write_file` - write files
- `search_replace` - edit files
- `grep` - search files
- `bash` - run shell commands
- `ask_user_question` - blocking user input
- `task` - dispatch subagents

## Utility Scripts

| Script | Purpose |
|--------|---------|
| `.vibe/skills/mossy-scripts/record-issue.sh` | Record tool errors and problems for mossy skills |
| `scripts/watch_specs.py` | Watch for file changes in `.flow/specs/` directory, waiting until a change occurs plus an additional second for stability |

## Registering with Vibe

Add to `~/.config/vibe/agents.toml`:

```toml
[[agents]]
name = "mossy-slop"
path = "<mossy-slop-path>"
```

**Note:** Replace `<mossy-slop-path>` with the actual path where you checked out this repository.

Or symlink into Vibe's agents directory.

## Inspiration from flow-next

We take from flow-next (MIT licensed):
- Spec-first approach
- `.flow/` task tracking concept
- Worker subagent pattern
- Review gates

We leave out:
- Ralph autonomous mode (too heavy)
- Multi-model review complexity
- Excessive metadata
- Verbose prompts
- Cross-platform sync scripts
- Plugin marketplace infrastructure

## Adding a New Skill

1. Create `.vibe/skills/mossy-<name>/SKILL.md` with frontmatter
2. Create `.vibe/commands/mossy-<name>.md` for the slash command
3. Add to the tables above
4. Test locally

Frontmatter template:
```yaml
---
name: mossy-<name>
description: <1 line description>
user-invocable: false
allowed-tools: read_file,write_file,search_replace,grep,bash,ask_user_question,task
---
```

Command template:
```yaml
---
name: mossy-<name>
description: <1 line description>
argument-hint: "[args]"
---

# IMPORTANT: This command MUST invoke the skill `mossy-<name>`

Pass $ARGUMENTS to the skill.
```

## flowctl Integration

flow-next provides `flowctl.py` at `../flow-next/plugins/flow-next/scripts/flowctl.py`. It is MIT licensed.

**Rule**: If `.flow/flowctl` or `.flow/flowctl.py` exists in the repo, use it. Otherwise, ignore.

**Never modify flowctl.py** — it is maintained by flow-next. Treat it as a read-only dependency.

### flowctl Usage Pattern

```bash
# Check if flowctl exists
FLOWCTL="${FLOW_DIR:-.flow}/flowctl"
if [[ -x "$FLOWCTL" ]]; then
  $FLOWCTL <command> [args]
fi
```

### flowctl Core Commands (used by mossy skills)

| Command | Purpose |
|---------|---------|
| `flowctl list` | List all specs + tasks |
| `flowctl show <id>` | Show spec or task details |
| `flowctl specs` | List all specs |
| `flowctl tasks` | List all tasks |
| `flowctl ready` | Show ready tasks |
| `flowctl start <task-id>` | Claim a task |
| `flowctl done <task-id> --summary-file <path>` | Mark task complete |
| `flowctl spec create --title <title>` | Create new spec |
| `flowctl task create --spec <spec-id> --title <title>` | Create new task |

### mossy-flowctl Skill

A dedicated internal skill that wraps flowctl for other mossy skills to use. Other skills should delegate to `mossy-flowctl` rather than calling flowctl directly.

## Error Recording Requirements

**ALL mossy skills MUST implement error recording** to track tool errors and other problems that cost time and tokens to resolve.

### Quick Reference

| Component | Location | Purpose |
|-----------|----------|---------|
| Issue files | `.flow/issues/` | Individual error records |
| Recording script | `.vibe/skills/mossy-scripts/record-issue.sh` | Shared recording utility |
| Full guide | `.vibe/skills/mossy-scripts/ISSUE_RECORDING.md` | Complete documentation |
| Template | `.vibe/skills/mossy-scripts/ISSUE_TEMPLATE.md` | Issue file format |

### When to Record

Record errors **immediately** for:

1. **Tool Errors**: Any Vibe tool call failure (read_file, write_file, search_replace, grep, bash, etc.)
2. **Validation Errors**: Invalid input, missing required arguments, format mismatches
3. **Logic Errors**: Internal skill logic failures, unexpected state
4. **Resource Errors**: Missing files, directories, or external resources
5. **Configuration Errors**: Environment issues, missing dependencies, version incompatibilities

### Minimum Requirements for Each Skill

Every skill's SKILL.md MUST include:

1. **Error Recording Section**: `## Error Recording` with:
   - Reference to `.vibe/skills/mossy-scripts/ISSUE_RECORDING.md` guide
   - Table of skill-specific error types with examples
   - Bash integration examples using `.vibe/skills/mossy-scripts/record-issue.sh`

2. **Integration Code**: Show how to use `record_issue` function:
   ```bash
   source ../mossy-scripts/record-issue.sh 2>/dev/null || true
   record_issue "SKILL_NAME" "ERROR_TYPE" "TOOL" "TARGET" "ERROR_MSG" "CONTEXT" || true
   ```

3. **Error Types Table**: Document skill-specific error categories:
   - tool-error
   - validation-error
   - logic-error
   - resource-error
   - configuration-error

### Pattern for Error Handling

```bash
# Wrap tool calls with error recording
if ! read_file path="$target" 2>/dev/null; then
    record_issue "mossy-SKILL" "tool-error" "read_file" "$target" \
        "read_file failed: $?" \
        "Phase: analysis, Task: $task_id" || true
    # Handle error or continue
fi
```

**Note**: Always use `|| true` to prevent recording failures from breaking skill execution.

### Existing Implementations

All 14 skills currently implement error recording:
- Core: mossy-plan, mossy-interview, mossy-work, mossy-review, mossy-refactor, mossy-analyze, mossy-flowctl
- Language: mossy-cpp, mossy-csharp, mossy-vbnet, mossy-js, mossy-ts, mossy-gdscript, mossy-py

### For New Skills

When adding a new skill:
1. Add `## Error Recording` section to SKILL.md
2. Document skill-specific error types
3. Include integration examples
4. Test error recording works
5. Reference `.vibe/skills/mossy-scripts/ISSUE_RECORDING.md` for details

## Constraints

- **Token efficiency first**
- Keep skills < 500 lines each
- Prefer single-file skills over multi-file
- No external API calls
- No global state
- All state in `.flow/` directory

## Post-Mortem Analysis

Do not blame the LLM. Look for reasons in input files first.
