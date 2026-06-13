#!/bin/bash
# flowctl wrapper - invokes flowctl.py from the same directory

# fallback location: here.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# find the correct script to call. Prefer installed version by flow-next.
pushd . 1>/dev/null
    while test '/' != `pwd`; do
        if test -d .flow && test -x .flow/bin/flowctl.py; then           
            SCRIPT_DIR="$(cd .flow/bin/; pwd)"
            REPO_DIR="$SCRIPT_DIR"
            break
        fi
        if test -d .git; then
            REPO_DIR="$(pwd)"
            break
        fi
        cd ..
    done
popd 1>/dev/null

if ! python3 "$SCRIPT_DIR/flowctl.py" "$@" 2>/dev/null; then
    pushd "$REPO_DIR" 1>/dev/null
    "$SCRIPT_DIR/ensure-flow-dir.sh"
    popd 1>/dev/null
    python3 "$SCRIPT_DIR/flowctl.py" "$@" || exit $?
fi

# amend skeleton spec
if test "$1" == "spec" && test "$2" == "skeleton"; then
cat << EOF

## Resolved via Codebase
- <item> — <file:line>
EOF
fi