#!/bin/bash
# flowctl wrapper - invokes flowctl.py from the same directory

# fallback location: here.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# find the correct script to call. Prefer installed version by flow-next.
pushd . 1>/dev/null
    while test '/' != `pwd`; do
        if test -d .flow && test -x .flow/bin/flowctl.py; then           
            SCRIPT_DIR="$(cd .flow/bin/; pwd)"
            break
        fi
        cd ..
    done
popd 1>/dev/null

if ! python3 "$SCRIPT_DIR/flowctl.py" "$@"; then
    "$SCRIPT_DIR/ensure-flow-dir.sh"
    python3 "$SCRIPT_DIR/flowctl.py" "$@" || exit $?
fi

# amend skeleton spec
if test "$1" == "spec" && test "$2" == "skeleton"; then
cat << EOF

## Mossy-Config
- commit-policy: <manual|auto-per-change|auto-per-spec|batch>: fill from idea text or `load-mossy-config.sh COMMIT_POLICY 2>/dev/null) || true`
- new-branch-per-spec: <true|false>: fill from idea text or `load-mossy-config.sh NEW_BRANCH_PER_SPEC 2>/dev/null) || true`
- auto-push: <true|false>: fill from idea text or `load-mossy-config.sh AUTO_PUSH 2>/dev/null) || true`
- co-authored-by: <string>: fill from idea text or `load-mossy-config.sh CO_AUTHORED_BY 2>/dev/null) || true`

## Resolved via Codebase
- <item> — <file:line>
EOF
fi