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

# Create symlinks for local development
echo "Creating symlinks..."

# Symlink commands directory
mkdir -p "$REPO_ROOT/.vibe/commands"
for f in "$REPO_ROOT_SOURCE/.vibe/commands/*"; do ln -sfn $f "$REPO_ROOT/.vibe/commands/"; done
echo "  ✓ .vibe/commands -> commands"

# Symlink skills directory
mkdir -p "$REPO_ROOT/.vibe/skills"
for f in "$REPO_ROOT_SOURCE/.vibe/skills/*"; do ln -sfn $f "$REPO_ROOT/.vibe/skills/"; done
echo "  ✓ .vibe/skills -> skills"

# Install default mossy-config if not exists
if [ ! -f "$REPO_ROOT/.flow/mossy-config" ] && [ -f "$REPO_ROOT_SOURCE/.vibe/skills/mossy-scripts/mossy-config.default" ]; then
    mkdir -p "$REPO_ROOT/.flow"
    cp "$REPO_ROOT_SOURCE/config/mossy-config.default" "$REPO_ROOT/.flow/mossy-config"
    echo "  ✓ .flow/mossy-config installed from default template"
else
    echo "  - .flow/mossy-config already exists, not overwriting"
fi

# Verify symlinks
echo ""
echo "Verifying setup..."

if [ -L "$REPO_ROOT/.vibe/commands/mossy-plan.md" ] && [ -f "$REPO_ROOT/.vibe/commands/mossy-plan.md" ]; then
    echo "  ✓ commands symlink: OK"
else
    echo "  ✗ commands symlink: FAILED"
    exit 1
fi

if [ -L "$REPO_ROOT/.vibe/skills/mossy-plan" ] && [ -d "$REPO_ROOT/.vibe/skills/mossy-plan" ]; then
    echo "  ✓ skills symlink: OK"
else
    echo "  ✗ skills symlink: FAILED"
    exit 1
fi

# Count skills (follow symlinks)
SKILL_COUNT=$(find -L "$REPO_ROOT/.vibe/skills/" -name "mossy-*" -mindepth 1 -maxdepth 1 -type d | wc -l)

echo ""
echo "Setup complete!"
echo "================"
echo "Local development environment ready."
echo ""
echo "To use with Mistral Vibe from this directory:"
echo "  1. Ensure Vibe is installed"
echo "  2. Run Vibe from $REPO_ROOT"
echo ""
echo "Symlinks:"
for f in "$REPO_ROOT"/.vibe/commands/mossy-* "$REPO_ROOT"/.vibe/skills/mossy-*; do
    echo "  $f -> $(readlink "$f")" | sed -e "s,$REPO_ROOT,,"
done
echo ""
echo "Skills available: $SKILL_COUNT"
