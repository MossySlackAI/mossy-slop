# Contributing to Mossy Slop

Thank you for your interest in contributing to Mossy Slop! This project follows a **dogfooding** philosophy: we use the skills themselves to develop and maintain the project.
Manual edits by real people are explicitly welcome!

## Dogfooding Principle

**All contributions to this project are encouraged use the mossy skills themselves.** This ensures:
1. We eat our own dog food
2. The skills are continuously tested and improved
3. We discover issues early
4. The development process is documented and reproducible

## Before You Start

1. **Note from the human in the loop** This entire thing is 99.9% slopped. I have not done what is demanded here myself. Have your AI tool do it for you.
2. **Setup your development environment** (see below)
3. **Read the AGENTS.md** to understand the mossy-slop project structure
4. **Read the existing skills** to understand the patterns and conventions

## Development Environment Setup

### Quick Setup

```bash
# Clone the repository
git clone https://github.com/manuel/mossy-slop.git
cd mossy-slop

# Open in VS code
code .
```

There is a Dev Container setup, you can use it. It contains only the bare minimum; python, Mistral Vibe, PyYAML (optional dependency of flowctl.py). The container allows you to switch to 'auto approve' without too much worry.

Of course, you can use any other editor, or just make changes via `vibe` from the command line.

## Contribution Workflow

All contributions follow this workflow using the mossy skills:

```
1. Identify the change/feature/fix needed
2. Refine the feature with /mossy-slop:interview
3. Plan it using /mossy-slop:plan
4. Implement it using /mossy-slop:work
5. Review it using /mossy-slop:review
6. Commit and push
7. Record any issues to .flow/issues/
```

For details, see [README.md](README.md#workflow).

## Adding a New Skill

To add a new skill (e.g., `mossy-rust`):

### Using the Skills (Recommended)

```
# Plan the new skill
/mossy-slop:plan "Add mossy-rust skill for mossy-slop"

# Work through the tasks
/mossy-slop:work <task-id>

# Review
/mossy-slop:review
```

### Manual Process

If you must do it manually (e.g., the skills aren't working yet):

1. **Create the skill directory**:
   ```bash
   mkdir -p skills/mossy-rust
   ```

2. **Create SKILL.md** with proper frontmatter:
   ```markdown
   ---
   name: mossy-rust
   description: Rust language-specific skill with file extensions, build systems, patterns, and pitfalls
   user-invocable: false
   allowed-tools: read_file,write_file,search_replace,grep,bash,ask_user_question,task
   ---

   # mossy-rust

   Rust language awareness for the mossy-slop framework.
   ```

3. **Create the command file** in `commands/mossy-rust.md`:
   ```markdown
   ---
   name: mossy:rust
   description: Rust language-specific commands
   axis: 1
   argument-hint: "[args]"
   ---

   # IMPORTANT: Invoke skill `mossy-rust`

   Pass $ARGUMENTS to the skill.
   ```

4. **Update documentation**:
   - Add to the tables in AGENTS.md
   - Add to INSTALL.md if needed

5. **Test the skill**:
   ```bash
   # From the repo root with dev setup
   /mossy-slop:rust --help
   ```

## Adding a New Command

Commands are defined in the `commands/` directory as `.md` files with YAML frontmatter.

### Required Frontmatter

```yaml
---
name: mossy:<name>      # The command name (e.g., mossy:rust)
description: <desc>    # Brief description
argument-hint: "[args]" # Optional: argument hint
axis: 1                # Optional: axis for slash commands
---

# IMPORTANT: Invoke skill `mossy-<name>`

Pass $ARGUMENTS to the skill.
```

## Skill Structure

Each skill lives in its own directory under `skills/`:

```
skills/mossy-<name>/
└── SKILL.md          # Main skill file with frontmatter
```

### SKILL.md Frontmatter

Required fields:
- `name`: The skill name (e.g., `mossy-rust`)
- `description`: Brief description
- `user-invocable`: `false` (skills are invoked by commands, not directly)
- `allowed-tools`: Comma-separated list of tools the skill can use

Optional fields:
- `version`: Skill version
- `author`: Author name
- Other metadata as needed

### Required Sections in SKILL.md

1. **Purpose**: What the skill does
2. **Input**: What the skill accepts
3. **Flow**: Step-by-step execution logic
4. **Commands**: Related commands
5. **Error Recording**: How errors are recorded (see `.vibe/skills/mossy-scripts/ISSUE_RECORDING.md`)
6. **Guardrails**: Constraints and rules

## Testing

### Testing a Skill

```bash
# From the repo root with dev setup
/mossy-slop:<command> <args>
```

### Validating All Skills

```bash
# Check all SKILL.md files have valid frontmatter
for skill in skills/mossy-*/SKILL.md; do
    echo "Checking $skill..."
    head -5 "$skill"
done
```

### Validating Manifests

```bash
# Validate JSON files
python3 -m json.tool .github/plugin/marketplace.json
python3 -m json.tool .claude-plugin/marketplace.json

# Validate TOML files
python3 -c "import tomllib; tomllib.load(open('.vibe/agents.toml', 'rb'))"
```

## Code Style

### Markdown
- Use consistent heading levels
- Use fenced code blocks with language specification
- Keep lines under 100 characters when possible

### YAML
- Use consistent indentation (2 spaces)
- Quote strings that contain special characters
- Use lists for multiple items

### Bash Scripts
- Use `set -e` for error handling
- Quote all variables (`"$VAR"`)
- Use `#!/bin/bash` shebang
- Make scripts executable (`chmod +x`)

## Pull Request Process

1. **Create a branch**:
   ```bash
   git checkout -b feat/my-feature
   ```

2. **Make your changes** following the workflow above

3. **Run the dev setup**:
   ```bash
   ./scripts/dev-setup.sh
   ```

4. **Test your changes**:
   - Use the skills to verify they work
   - Check all manifests are valid
   - Verify installation instructions

5. **Commit your changes**:
   ```bash
   git commit -m "feat: description of changes"
   ```

6. **Push and create PR**:
   ```bash
   git push origin feat/my-feature
   ```

7. **PR will be reviewed** using `/mossy-slop:review`

## Versioning

This project uses semantic versioning for releases:
- `MAJOR`: Breaking changes to skill interfaces
- `MINOR`: New features, backwards-compatible
- `PATCH`: Bug fixes, documentation updates

### Creating a Release

1. Update version in all manifest files:
   - `.github/plugin/marketplace.json`
   - `.claude-plugin/marketplace.json`
   - `.vibe/agents.toml`

2. Update CHANGELOG.md (if exists) or commit message

3. Tag the release:
   ```bash
   git tag -a v1.0.0 -m "Release v1.0.0"
   git push origin v1.0.0
   ```

4. Create GitHub Release with notes

## Reporting Issues

1. **For bugs in skills**: Record via the error recording system (automatic in skills)
2. **For feature requests**: File a GitHub issue with the `/mossy-slop:plan` output
3. **For questions**: File a GitHub issue or discussion

All issues in `.flow/issues/` are tracked and should be addressed.

## License

By contributing, you agree that your contributions will be licensed under the MIT License. See LICENSE for details.
