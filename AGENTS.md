# Mossy Code Flow Skills

**Lean, token-efficient skills for planning and executing code changes.**

This repository provides alternative skills to flow-next, designed for Mistral Vibe. They are intentionally minimal — no unnecessary verbosity, no token-wasting patterns.

## Mission Statement

The focus should be the code; the code is the single source of truth. Inline comments should provide the documentation.

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

## Architecture

### Skill Structure

Each skill lives in `skills/mossy-<name>/` with:

```
skills/mossy-<name>/
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

Via slash commands defined in `commands/mossy-<name>.md`:
```yaml
---
name: mossy:<name>
description: <command description>
argument-hint: "[args]"
---
```

## Core Skills

| Skill | Command | Purpose |
|-------|---------|---------|
| `mossy-flowctl` | N/A (internal) | Wrapper for flowctl.py operations |
| `mossy-plan` | `/mossy:plan` | Create execution plan from spec |
| `mossy-work` | `/mossy:work` | Execute plan tasks |
| `mossy-review` | `/mossy:review` | Review changes before commit |
| `mossy-refactor` | `/mossy:refactor` | Language-aware refactoring |
| `mossy-analyze` | `/mossy:analyze` | Static analysis across languages |

## Language-Specific Skills

| Skill | Command | Languages |
|-------|---------|-----------|
| `mossy-cpp` | `/mossy:cpp` | C++ |
| `mossy-csharp` | `/mossy:csharp` | C# |
| `mossy-vbnet` | `/mossy:vbnet` | VB.NET |
| `mossy-js` | `/mossy:js` | JavaScript |
| `mossy-ts` | `/mossy:ts` | TypeScript |
| `mossy-gdscript` | `/mossy:gdscript` | GDScript |
| `mossy-py` | `/mossy:py` | Python |

## Directory Structure

```
.
├── AGENTS.md              # This file
├── README.md             # Repository overview
├── .gitlab-ci.yml        # CI configuration
├── skills/               # All skills
│   ├── mossy-flowctl/
│   │   └── SKILL.md
│   ├── mossy-plan/
│   │   ├── SKILL.md
│   │   └── workflow.md
│   ├── mossy-work/
│   │   ├── SKILL.md
│   │   └── workflow.md
│   ├── mossy-review/
│   │   └── SKILL.md
│   ├── mossy-refactor/
│   │   └── SKILL.md
│   ├── mossy-analyze/
│   │   └── SKILL.md
│   ├── mossy-cpp/
│   │   └── SKILL.md
│   ├── mossy-csharp/
│   │   └── SKILL.md
│   ├── mossy-vbnet/
│   │   └── SKILL.md
│   ├── mossy-js/
│   │   └── SKILL.md
│   ├── mossy-ts/
│   │   └── SKILL.md
│   ├── mossy-gdscript/
│   │   └── SKILL.md
│   └── mossy-py/
│       └── SKILL.md
└── commands/             # Slash command definitions
    ├── mossy-plan.md
    ├── mossy-work.md
    ├── mossy-review.md
    ├── mossy-refactor.md
    ├── mossy-analyze.md
    ├── mossy-cpp.md
    ├── mossy-csharp.md
    ├── mossy-vbnet.md
    ├── mossy-js.md
    ├── mossy-ts.md
    ├── mossy-gdscript.md
    └── mossy-py.md
```

## Design Principles

### 1. Token Efficiency
- No unnecessary words
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
/mossy:plan fn-1-add-feature
/mossy:work fn-1-add-feature.1
/mossy:review
/mossy:cpp --check-style
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

## Registering with Vibe

Add to `~/.config/vibe/agents.toml`:

```toml
[[agents]]
name = "mossy-skills"
path = "~/.dotfiles/vibe/flow-skills"
```

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

1. Create `skills/mossy-<name>/SKILL.md` with frontmatter
2. Create `commands/mossy-<name>.md` for the slash command
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
name: mossy:<name>
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

## Constraints

- Keep skills < 500 lines each
- Prefer single-file skills over multi-file
- No external API calls
- No global state
- All state in `.flow/` directory
