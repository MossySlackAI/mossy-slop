#!/bin/bash
# Mossy Slop - Local Development Setup Script
# This script sets up symlinks for users into the current repository

set -e

REPO_ROOT_SOURCE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO_ROOT=`git rev-parse --show-toplevel || pwd`

# delegate
`dirname $0`/setup.sh "$REPO_ROOT" "$REPO_ROOT_SOURCE"