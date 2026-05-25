#!/bin/bash
# Mossy Slop - Local Development Setup Script
# This script sets up symlinks for local development and testing

set -e

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# delegate
`dirname $0`/setup.sh "$REPO_ROOT" "$REPO_ROOT"