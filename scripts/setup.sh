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

echo "Mossy Slop - Setup"
echo "========================================"
echo "Repository root: $REPO_ROOT"
echo "Source: $REPO_ROOT_SOURCE"
echo ""

# Create .vibe directory if it doesn't exist
mkdir -p "$REPO_ROOT/.vibe"

# Create links (hard links, because they work universally and don't create leads for Vibe to follow)
echo "Creating hardlinks..."

# Symlink directories
for subdir in commands skills; do
    mkdir -p "$REPO_ROOT/.vibe/$subdir"
    for f in "$REPO_ROOT_SOURCE/.vibe/$subdir/"*; do 
        rm -rf "$REPO_ROOT/.vibe/$subdir/`basename $f`"
        cp -al $f "$REPO_ROOT/.vibe/$subdir/"
    done
    echo "  ✓ .vibe/$subdir -> $subdir"
done

# Install default mossy-config if not exists
if [ ! -f "$REPO_ROOT/.flow/mossy-config" ] && [ -f "$REPO_ROOT_SOURCE/.vibe/skills/mossy-scripts/mossy-config.default" ]; then
    mkdir -p "$REPO_ROOT/.flow"
    cp "$REPO_ROOT_SOURCE/.vibe/skills/mossy-scripts/mossy-config.default" "$REPO_ROOT/.flow/mossy-config"
    echo "  ✓ .flow/mossy-config installed from default template"
else
    echo "  - .flow/mossy-config already exists, not overwriting"
fi

# Verify symlinks
echo ""
echo "Verifying setup..."

if [ -f "$REPO_ROOT/.vibe/commands/idea.md" ]; then
    echo "  ✓ commands link: OK"
else
    echo "  ✗ commands link: FAILED"
    exit 1
fi

if [ -d "$REPO_ROOT/.vibe/skills/mossy-plan" ] && [ -f "$REPO_ROOT/.vibe/skills/mossy-plan/SKILL.md" ]; then
    echo "  ✓ skills link: OK"
else
    echo "  ✗ skills link: FAILED"
    exit 1
fi

# Count skills (follow symlinks)
SKILL_COUNT=$(find -L "$REPO_ROOT/.vibe/skills/" -mindepth 1 -maxdepth 1 -name "mossy-*" -type d | wc -l)

echo ""
echo "Setup complete!"
echo "================"
echo "Local development environment ready."
echo ""
echo "To use with Mistral Vibe from this directory:"
echo "  1. Ensure Vibe is installed"
echo "  2. Run Vibe from $REPO_ROOT"
echo ""
echo "Skills available: $SKILL_COUNT"
