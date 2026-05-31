#!/usr/bin/env bash
#
# alternate-skills installer — auto-detects which AI assistants are
# installed and wires `skills/*` into each agent's discovery path.
#
# Idempotent: safe to re-run after `git pull` to pick up new skills.
# Uses symlinks so future updates land instantly.
#
# Usage:
#   bash install.sh               # auto-detect and install everywhere
#   bash install.sh claude        # only Claude Code
#   bash install.sh cursor        # only Cursor
#   bash install.sh codex         # only Codex
#
# Per-agent install paths (these are conventions, not hardcoded in this
# repo — change here if any platform moves them):
#   Claude Code  → ~/.claude/skills/<skill>/
#   Cursor       → ~/.cursor/skills/<skill>/
#   Codex        → ~/.agents/skills/<skill>/

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_DIR="$REPO_DIR/skills"

if [ ! -d "$SKILLS_DIR" ]; then
  echo "✗ No skills/ directory at $SKILLS_DIR — wrong repo?" >&2
  exit 1
fi

# ── Argument handling ────────────────────────────────────────────────
TARGETS=()
if [ $# -eq 0 ]; then
  # auto-detect mode
  [ -d "$HOME/.claude" ] && TARGETS+=("claude")
  [ -d "$HOME/.cursor" ] && TARGETS+=("cursor")
  [ -d "$HOME/.codex" ] || [ -d "$HOME/.agents" ] && TARGETS+=("codex")
  if [ ${#TARGETS[@]} -eq 0 ]; then
    echo "✗ Couldn't auto-detect any agent install (~/.claude, ~/.cursor, ~/.codex)." >&2
    echo "  Run explicitly: bash install.sh claude | cursor | codex" >&2
    exit 1
  fi
else
  for arg in "$@"; do
    case "$arg" in
      claude|cursor|codex) TARGETS+=("$arg") ;;
      *)
        echo "✗ Unknown target: $arg (use claude | cursor | codex)" >&2
        exit 1
        ;;
    esac
  done
fi

# ── Helpers ──────────────────────────────────────────────────────────
link_skills_into() {
  local dest_dir="$1"
  local agent_name="$2"
  mkdir -p "$dest_dir"

  local linked=0
  for skill_dir in "$SKILLS_DIR"/*/; do
    local skill_name
    skill_name="$(basename "$skill_dir")"
    local target="$dest_dir/$skill_name"

    # Symlink (overwriting any existing symlink, refusing to overwrite a
    # regular dir to avoid clobbering hand-edited skills).
    if [ -L "$target" ]; then
      rm "$target"
    elif [ -e "$target" ]; then
      echo "  ⚠ $target already exists as a real file/dir — skipping (delete it first to re-link)."
      continue
    fi
    ln -s "$skill_dir" "$target"
    linked=$((linked + 1))
  done

  echo "✓ $agent_name: linked $linked skill(s) into $dest_dir"
}

# ── Per-agent wiring ─────────────────────────────────────────────────
for target in "${TARGETS[@]}"; do
  case "$target" in
    claude)
      link_skills_into "$HOME/.claude/skills" "Claude Code"
      ;;
    cursor)
      # Cursor reads ~/.cursor/skills/ for global skills (project-level
      # is .cursor/skills/ inside a project — we're installing globally).
      link_skills_into "$HOME/.cursor/skills" "Cursor"
      ;;
    codex)
      # Codex reads ~/.agents/skills/<skill>/SKILL.md (or ~/.codex/agents/).
      # We use ~/.agents/skills/ — the documented path. Symlinks here
      # mean a `git pull` in this repo updates every Codex skill instantly.
      link_skills_into "$HOME/.agents/skills" "Codex"
      ;;
  esac
done

echo
echo "Done. Open a fresh chat in any agent and ask it about the af CLI to verify."
echo "Update later with:  cd $REPO_DIR && git pull"
