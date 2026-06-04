#!/bin/bash
# Mossy Slop - Local Development Setup Script
# This script sets up symlinks for users into their home directory

set -e

REPO_ROOT_SOURCE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO_ROOT="$HOME"

# delegate
${REPO_ROOT_SOURCE}/scripts/setup.sh "$REPO_ROOT" "$REPO_ROOT_SOURCE"