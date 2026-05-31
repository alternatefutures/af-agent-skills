#!/usr/bin/env bash
#
# Alternate Cloud plugin — PreToolUse hook.
#
# Runs before every Bash tool invocation. Detects `af …` commands and
# verifies that the CLI is installed + the user is logged in. If not,
# the hook EXITS NON-ZERO with a clear message — Claude Code / Cursor
# treat that as a "tool call cancelled, here's why" and surface the
# message to the user instead of running a doomed command.
#
# Non-`af` commands are passed through (exit 0 immediately).
#
# The hook reads the tool input as JSON on stdin (Claude Code convention).
# We don't strictly need it — we only check shell PATH + auth state — but
# the JSON parse is robust enough to handle anything the harness sends.

set -uo pipefail

# Read the tool input (we don't actually need it; just drain stdin so the
# harness doesn't block).
INPUT="$(cat || true)"

# Cheap detection: is the command line invoking `af` (as a word)?
# A more precise jq-based parse would catch heredocs/quoted forms, but
# this matches 99% of real invocations and adds no jq dependency.
case "$INPUT" in
  *'"command":'*'"af '*|*'"command":'*' af '*|*'"command":'*'"af"'*)
    : # falls through to the af-readiness check below
    ;;
  *)
    # Not an `af` command — let it run.
    exit 0
    ;;
esac

# Is `af` on PATH?
if ! command -v af >/dev/null 2>&1; then
  cat >&2 <<'EOF'
✗ The Alternate Clouds CLI (`af`) is not installed.

Install it with one of:

    npm install -g @alternatefutures/cli
    pnpm add -g @alternatefutures/cli

Then run `af login` to sign in. After that, re-run the request.
EOF
  exit 1
fi

# Is the user logged in? `af whoami --json` exits non-zero when not authed.
# We swallow stderr so the user doesn't see the inner "not logged in" twice.
if ! af whoami --json >/dev/null 2>&1; then
  cat >&2 <<'EOF'
✗ You're not signed in to Alternate Clouds.

Run:

    af login

Then re-run the request. (Use `af login --email` for terminal-only flow.)
EOF
  exit 1
fi

exit 0
