#!/bin/bash
# Mossy Slop - Local Development Setup Script
# This script sets up symlinks for local development and testing

set -e

REPO_ROOT=$1
REPO_ROOT_SOURCE=$2
if test -z "$REPO_ROOT" || test -z "$REPO_ROOT_SOURCE"; then
    echo Usage: setup.sh \<target repo\> \<mossy-slop repo\>
    exit 1
fi

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
mkdir -p "$REPO_ROOT/.vibe/commands"
ln -sfn "$REPO_ROOT_SOURCE/commands" "$REPO_ROOT/.vibe/commands/mossy-slop"
echo "  ✓ .vibe/commands -> commands"

# Symlink skills directory
mkdir -p "$REPO_ROOT/.vibe/skills"
ln -sfn "$REPO_ROOT_SOURCE/skills" "$REPO_ROOT/.vibe/skills/mossy-slop"
echo "  ✓ .vibe/skills -> skills"

# Install default mossy-config if not exists
if [ ! -f "$REPO_ROOT/.flow/mossy-config" ] && [ -f "$REPO_ROOT_SOURCE/config/mossy-config.default" ]; then
    cp "$REPO_ROOT_SOURCE/config/mossy-config.default" "$REPO_ROOT/.flow/mossy-config"
    echo "  ✓ .flow/mossy-config installed from default template"
else
    echo "  - .flow/mossy-config already exists, not overwriting"
fi

# Verify symlinks
echo ""
echo "Verifying setup..."

if [ -L "$REPO_ROOT/.vibe/commands/mossy-slop" ] && [ -d "$REPO_ROOT/.vibe/commands/mossy-slop" ]; then
    echo "  ✓ commands symlink: OK"
else
    echo "  ✗ commands symlink: FAILED"
    exit 1
fi

if [ -L "$REPO_ROOT/.vibe/skills/mossy-slop" ] && [ -d "$REPO_ROOT/.vibe/skills/mossy-slop" ]; then
    echo "  ✓ skills symlink: OK"
else
    echo "  ✗ skills symlink: FAILED"
    exit 1
fi

# Count skills (follow symlinks)
SKILL_COUNT=$(find -L "$REPO_ROOT/.vibe/skills/mossy-slop" -mindepth 1 -maxdepth 1 -type d | wc -l)

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
echo "  .vibe/commands/mossy-slop -> $(readlink "$REPO_ROOT_SOURCE/.vibe/commands/mossy-slop")"
echo "  .vibe/skills/mossy-slop -> $(readlink "$REPO_ROOT_SOURCE/.vibe/skills/mossy-slop")"
echo ""
echo "Skills available: $SKILL_COUNT"
