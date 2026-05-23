# Mossy Skills Installation

Mossy Code Flow Skills are lean, token-efficient skills for planning and executing code changes. This document describes how to install them for different AI coding assistants.

## Quick Start

Choose your AI tool below and follow the instructions.

---

## GitHub Copilot CLI

GitHub Copilot CLI uses a marketplace system for plugin discovery.

### Installation

```bash
# Add this repository as a marketplace
/plugin marketplace add manuel/flow-skills

# Install the mossy-skills plugin
/plugin install mossy-skills@github-copilot-plugins
```

### Manual Installation

If the marketplace method doesn't work, you can manually install:

```bash
# Clone the repository
git clone https://github.com/manuel/flow-skills.git
cd flow-skills

# Copy skills to Copilot's skills directory
cp -r skills/* ~/.github/copilot/skills/
cp -r commands/* ~/.github/copilot/commands/
```

### Verification

```bash
# List installed skills
/plugin list

# Check mossy-skills are available
/plugin show mossy-skills
```

---

## Claude Code

Claude Code supports plugins through its marketplace system.

### Installation

```bash
# Add this repository as a marketplace
/plugin marketplace add manuel/flow-skills

# Install the mossy-skills plugin
/plugin install mossy-skills@claude-code-skills
```

### Alternative: Install All Skills Individually

```bash
# Install core skills
/plugin install mossy-core@claude-code-skills

# Install language skills
/plugin install mossy-languages@claude-code-skills
```

### Manual Installation

```bash
# Clone the repository
git clone https://github.com/manuel/flow-skills.git
cd flow-skills

# Copy skills to Claude's skills directory
mkdir -p ~/.claude/skills
cp -r skills/mossy-* ~/.claude/skills/

# Copy commands
mkdir -p ~/.claude/commands
cp -r commands/mossy-* ~/.claude/commands/
```

### Verification

```bash
# List installed skills
/skill list

# Use a mossy skill
/mossy:plan my-feature
```

---

## Mistral Vibe

Mistral Vibe uses an agents system for skill management.

### Option 1: Register as Agent (Recommended)

Add the following to your `~/.config/vibe/agents.toml`:

```toml
[[agents]]
name = "mossy-skills"
path = "~/.dotfiles/vibe/flow-skills"
description = "Mossy Code Flow Skills"
```

Or symlink the agents.toml from this repo:

```bash
mkdir -p ~/.config/vibe/
ln -s ~/.dotfiles/vibe/flow-skills/.vibe/agents.toml ~/.config/vibe/agents.toml
```

### Option 2: Clone and Symlink

```bash
# Clone the repository
git clone https://github.com/manuel/flow-skills.git ~/.vibe/agents/mossy-skills

# Symlink commands (optional - Vibe may auto-discover)
mkdir -p ~/.vibe/commands
ln -s ~/.vibe/agents/mossy-skills/commands/*.md ~/.vibe/commands/
```

### Option 3: Development Setup

If you're developing mossy-skills:

```bash
cd ~/.dotfiles/vibe/flow-skills
./scripts/dev-setup.sh
```

This creates symlinks so you can test changes immediately.

### Verification

Restart Vibe and check that mossy commands are available:

```
/mossy:plan --help
/mossy:work --help
/mossy:review --help
```

---

## Manual Installation (Any Tool)

If your tool isn't listed above or you prefer manual setup:

### Directory Structure

```
flow-skills/
├── skills/                    # Skill definitions
│   ├── mossy-flowctl/
│   │   └── SKILL.md
│   ├── mossy-plan/
│   │   └── SKILL.md
│   ├── mossy-work/
│   │   └── SKILL.md
│   ├── mossy-review/
│   │   └── SKILL.md
│   ├── mossy-refactor/
│   │   └── SKILL.md
│   ├── mossy-analyze/
│   │   └── SKILL.md
│   ├── mossy-interview/
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
└── commands/                   # Slash command definitions
    ├── mossy-plan.md
    ├── mossy-work.md
    ├── mossy-review.md
    ├── mossy-refactor.md
    ├── mossy-analyze.md
    ├── mossy-interview.md
    └── mossy-*.md
```

### Copy to Your Tool

Find your tool's skill directory and copy the files there:

| Tool | Skills Directory | Commands Directory |
|------|-----------------|-------------------|
| Claude Code | `~/.claude/skills/` | `~/.claude/commands/` |
| GitHub Copilot | `~/.github/copilot/skills/` | `~/.github/copilot/commands/` |
| Mistral Vibe | `~/.vibe/skills/` or agent path | `~/.vibe/commands/` |
| Cursor | `~/.cursor/rules/` | N/A |
| Windsurf | `~/.windsurf/skills/` | N/A |

### Example for Custom Setup

```bash
# Clone the repository
git clone https://github.com/manuel/flow-skills.git
cd flow-skills

# Copy to your tool's directory
# Adjust TOOL_DIR to match your tool
TOOL_DIR="$HOME/.your-tool"
mkdir -p "$TOOL_DIR/skills" "$TOOL_DIR/commands"
cp -r skills/* "$TOOL_DIR/skills/"
cp -r commands/* "$TOOL_DIR/commands/"
```

---

## Version Control

To pin to a specific version:

```bash
# Clone a specific version
git clone --branch v1.0.0 https://github.com/manuel/flow-skills.git

# Or checkout a tag after cloning
cd flow-skills
git checkout v1.0.0
```

---

## Updating

To update to the latest version:

```bash
cd ~/.dotfiles/vibe/flow-skills  # or wherever you cloned it
git pull origin main
```

If you installed via marketplace, use:

```bash
/plugin update mossy-skills
```

---

## Uninstalling

### GitHub Copilot

```bash
/plugin uninstall mossy-skills
/plugin marketplace remove manuel/flow-skills
```

### Claude Code

```bash
/plugin uninstall mossy-skills
/plugin marketplace remove manuel/flow-skills
```

### Mistral Vibe

Remove the agent entry from `~/.config/vibe/agents.toml` or delete the symlink.

### Manual Installation

Delete the copied files from your tool's skill directory.

---

## Troubleshooting

### Skills not appearing

- Verify the files are in the correct directory for your tool
- Check file permissions (`chmod -R 755` if needed)
- Restart your AI tool/editor
- Check for syntax errors in SKILL.md files (YAML frontmatter must be valid)

### Commands not working

- Ensure both the skill AND command files are copied
- Commands reference skills by name (e.g., `mossy-plan` skill is invoked by `/mossy:plan`)
- Check the command file has the correct `name` in its frontmatter

### marketplace.json not found

- Ensure you're using a recent version of the tool that supports marketplaces
- GitHub Copilot: v1.0.0+ (check with `/version`)
- Claude Code: v0.1.0+ (check with `/version`)

---

## Repository

- **Homepage**: https://github.com/manuel/flow-skills
- **Issues**: https://github.com/manuel/flow-skills/issues
- **License**: MIT

## Support

For questions or issues, please file an issue on GitHub or check the AGENTS.md file in this repository for detailed skill documentation.
