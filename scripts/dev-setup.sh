#!/bin/bash
# Mossy Slop - Local Development Setup Script
# This script sets up symlinks for local development and testing

set -e

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "Mossy Slop - Local Development Setup"
echo "========================================"
echo "Repository root: $REPO_ROOT"
echo ""

# Create .vibe directory if it doesn't exist
mkdir -p "$REPO_ROOT/.vibe"

# Check if symlinks already exist
if [ -L "$REPO_ROOT/.vibe/commands" ]; then
    echo "Warning: .vibe/commands symlink already exists"
fi

if [ -L "$REPO_ROOT/.vibe/skills" ]; then
    echo "Warning: .vibe/skills symlink already exists"
fi

# Create symlinks for local development
echo "Creating symlinks..."

# Symlink commands directory
ln -sfn "$REPO_ROOT/commands" "$REPO_ROOT/.vibe/commands"
echo "  ✓ .vibe/commands -> commands"

# Symlink skills directory
ln -sfn "$REPO_ROOT/skills" "$REPO_ROOT/.vibe/skills"
echo "  ✓ .vibe/skills -> skills"

# Install default mossy-config if not exists
if [ ! -f "$REPO_ROOT/.flow/mossy-config" ] && [ -f "$REPO_ROOT/config/mossy-config.default" ]; then
    cp "$REPO_ROOT/config/mossy-config.default" "$REPO_ROOT/.flow/mossy-config"
    echo "  ✓ .flow/mossy-config installed from default template"
else
    echo "  - .flow/mossy-config already exists, not overwriting"
fi

# Create local agents.toml for development
mkdir -p "$REPO_ROOT/.vibe/agents"
cat > "$REPO_ROOT/.vibe/agents/mossy-slop.toml" << 'EOF'
# Local development agent configuration for Mossy Slop
# This file is for development purposes only

name = "mossy-local"
path = "."
description = "Local development instance of mossy-slop - all skills loaded from current directory"
EOF

echo "  ✓ .vibe/agents-local.toml created"

# Verify symlinks
echo ""
echo "Verifying setup..."

if [ -L "$REPO_ROOT/.vibe/commands" ] && [ -d "$REPO_ROOT/.vibe/commands" ]; then
    echo "  ✓ commands symlink: OK"
else
    echo "  ✗ commands symlink: FAILED"
    exit 1
fi

if [ -L "$REPO_ROOT/.vibe/skills" ] && [ -d "$REPO_ROOT/.vibe/skills" ]; then
    echo "  ✓ skills symlink: OK"
else
    echo "  ✗ skills symlink: FAILED"
    exit 1
fi

# Count skills (follow symlinks)
SKILL_COUNT=$(find -L "$REPO_ROOT/.vibe/skills" -mindepth 1 -maxdepth 1 -type d | wc -l)

echo ""
echo "Setup complete!"
echo "================"
echo "Local development environment ready."
echo ""
echo "To use with Mistral Vibe from this directory:"
echo "  1. Ensure Vibe is installed"
echo "  2. Run Vibe from $REPO_ROOT"
echo "  3. Or add this to ~/.config/vibe/agents.toml:"
echo ""
echo "[[agents]]"
echo "name = \"mossy-slop\""
echo "path = \"$REPO_ROOT\""
echo ""
echo "Symlinked directories:"
echo "  .vibe/commands -> $(readlink "$REPO_ROOT/.vibe/commands")"
echo "  .vibe/skills -> $(readlink "$REPO_ROOT/.vibe/skills")"
echo ""
echo "Skills available: $SKILL_COUNT"
