# Mossy Slop Installation

Mossy Slop are lean, token-efficient skills for planning and executing code changes, state compatible with flow-next. 
This document describes how to install them for different AI coding assistants.

Project identifier: **mossy-slop**

**Note:** In the examples below, `<mossy-slop-path>` is a placeholder for the path where you checked out this repository (e.g., `~/.dotfiles/vibe/mossy-slop`, `~/projects/mossy-slop`, etc.). Replace it with your actual installation path.

## Quick Start

Choose your AI tool below and follow the instructions.

---

## Mistral Vibe

Mistral Vibe uses skills and commands directly. There are also agents, but they are less flexible than one wishes... 
For starters, they do not compose. If you get good results with agents, let me know how.

### Option 1: Clone and Install for a Repository

```bash
# Clone the repository
git clone https://github.com/MossySlackAI/mossy-slop.git <mossy-slop-path>

# Install locally
cd <your repository, ideally with git already set up>
<mossy-slop-path>/scripts/local-setup.h
# this creates skill and command links into the local .vibe directory.
```

### Option 1: Clone and Install for a User (and all Repositories)

```bash
# Clone the repository
git clone https://github.com/MossySlackAI/mossy-slop.git <mossy-slop-path>

# Install locally
<mossy-slop-path>/scripts/user-setup.h
# this creates skill and command links into your ~/.vibe directory.
```

### Option 3: Agent Setup
(As mentioned above, good luck)

```bash
# Clone the repository directly into your agents directory:
git clone https://github.com/MossySlackAI/mossy-slop.git ~/.vibe/agents/mossy-slop
```

### Option 4: Development Setup

If you're developing mossy-slop, just clone the repository and start vibe from inside. 
The skills are already in the right place to activate.

### Verification

Restart Vibe and check that mossy commands are available:

```
/mossy:plan --help
/mossy:work --help
/mossy:review --help
```

---


# ATTENTION

None of the the instructions below are expected to work. The AI wrote them itself. The Mistral setup above works.


## GitHub Copilot CLI

GitHub Copilot CLI uses a marketplace system for plugin discovery.

### Installation

```bash
# Add this repository as a marketplace
/plugin marketplace add MossySlackAI/mossy-slop

# Install the mossy-slop plugin
/plugin install mossy-slop@github-copilot-plugins
```

### Manual Installation

If the marketplace method doesn't work, you can manually install:

```bash
# Clone the repository
git clone https://github.com/MossySlackAI/mossy-slop.git
cd mossy-slop

# Copy skills to Copilot's skills directory
cp -r skills/* ~/.github/copilot/skills/
cp -r commands/* ~/.github/copilot/commands/
```

### Verification

```bash
# List installed skills
/plugin list

# Check mossy-slop are available
/plugin show mossy-slop
```

---

## Claude Code

Claude Code supports plugins through its marketplace system.

### Installation

```bash
# Add this repository as a marketplace
/plugin marketplace add MossySlackAI/mossy-slop

# Install the mossy-slop plugin
/plugin install mossy-slop@claude-code-skills
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
git clone https://github.com/MossySlackAI/mossy-slop.git
cd mossy-slop

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

## Manual Installation (Any Tool)

If your tool isn't listed above or you prefer manual setup:

### Directory Structure

```
mossy-slop/
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
git clone https://github.com/MossySlackAI/mossy-slop.git
cd mossy-slop

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
git clone --branch v1.0.0 https://github.com/MossySlackAI/mossy-slop.git

# Or checkout a tag after cloning
cd mossy-slop
git checkout v1.0.0
```

---

## Updating

To update to the latest version:

```bash
cd <mossy-slop-path>  # or wherever you cloned it
git pull origin main
```

If you installed via marketplace, use:

```bash
/plugin update mossy-slop
```

---

## Uninstalling

### GitHub Copilot

```bash
/plugin uninstall mossy-slop
/plugin marketplace remove MossySlackAI/mossy-slop
```

### Claude Code

```bash
/plugin uninstall mossy-slop
/plugin marketplace remove MossySlackAI/mossy-slop
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

- **Homepage**: https://github.com/MossySlackAI/mossy-slop
- **Issues**: https://github.com/MossySlackAI/mossy-slop/issues
- **License**: MIT

## Support

For questions or issues, please file an issue on GitHub or check the AGENTS.md file in this repository for detailed skill documentation.
