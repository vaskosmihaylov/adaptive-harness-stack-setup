#!/usr/bin/env bash
# Install the adaptive harness into ~/.claude and ~/.codex.
# Idempotent. Backs up anything it replaces. Never touches auth, history, logs,
# session state, or Codex project trust levels.
#
#   ./install.sh              install (or re-install) both harnesses
#   ./install.sh --dry-run    show what would change, write nothing
#   ./install.sh --uninstall  remove what this installer put there
#   ./install.sh --claude     only Claude Code
#   ./install.sh --codex      only Codex CLI
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DIST="$ROOT/dist"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$ROOT/backups/$STAMP"

DRY=0; UNINSTALL=0; DO_CLAUDE=1; DO_CODEX=1
for arg in "$@"; do
  case "$arg" in
    --dry-run)   DRY=1 ;;
    --uninstall) UNINSTALL=1 ;;
    --claude)    DO_CODEX=0 ;;
    --codex)     DO_CLAUDE=0 ;;
    -h|--help)   sed -n '2,12p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "unknown flag: $arg" >&2; exit 2 ;;
  esac
done

say()  { printf '  %s\n' "$*"; }
act()  { if [ "$DRY" = 1 ]; then printf '  [dry-run] %s\n' "$*"; else printf '  %s\n' "$*"; fi; }
need() { command -v "$1" >/dev/null 2>&1 || { echo "missing required tool: $1" >&2; exit 1; }; }

backup() { # backup <path> <label>
  [ -e "$1" ] || [ -L "$1" ] || return 0
  [ "$DRY" = 1 ] && { say "would back up $1"; return 0; }
  mkdir -p "$BACKUP/$2"
  cp -a "$1" "$BACKUP/$2/"
}

install_file() { # install_file <source> <destination> <label>
  if [ -f "$2" ] && cmp -s "$1" "$2"; then
    say "$2 already current"
    return 0
  fi
  backup "$2" "$3"
  act "write $2"
  [ "$DRY" = 0 ] && cp "$1" "$2"
}

install_skill_link() { # install_skill_link <destination>
  if [ -L "$1" ] && [ "$(readlink "$1")" = "$ROOT/skill" ]; then
    say "$1 already current"
    return 0
  fi
  backup "$1" "${2}"
  act "install skill -> $1"
  if [ "$DRY" = 0 ]; then
    rm -rf "$1"
    ln -s "$ROOT/skill" "$1"
  fi
}

retire() { # retire <path> <label>
  [ -e "$1" ] || return 0
  backup "$1" "$2"
  act "remove retired $1"
  if [ "$DRY" = 0 ]; then
    rm -f "$1"
  fi
}

# --------------------------------------------------------------------------- uninstall
if [ "$UNINSTALL" = 1 ]; then
  echo "Uninstalling:"
  if [ "$DO_CLAUDE" = 1 ]; then
    backup "$HOME/.claude/CLAUDE.md" claude
    act "remove ~/.claude/CLAUDE.md"
    [ "$DRY" = 0 ] && rm -f "$HOME/.claude/CLAUDE.md"
    backup "$HOME/.claude/skills/adaptive-harness-stack-setup" claude
    act "remove ~/.claude/skills/adaptive-harness-stack-setup"
    [ "$DRY" = 0 ] && rm -rf "$HOME/.claude/skills/adaptive-harness-stack-setup"
    for a in "$ROOT"/agents/claude/*.md; do
      n="$(basename "$a")"
      backup "$HOME/.claude/agents/$n" claude
      act "remove ~/.claude/agents/$n"
      [ "$DRY" = 0 ] && rm -f "$HOME/.claude/agents/$n"
    done
    retire "$HOME/.claude/agents/scout.md" claude
    say "left ~/.claude/settings.json alone — remove the permissions block by hand if you want it gone"
  fi
  if [ "$DO_CODEX" = 1 ]; then
    backup "$HOME/.codex/AGENTS.md" codex
    act "remove ~/.codex/AGENTS.md"
    [ "$DRY" = 0 ] && rm -f "$HOME/.codex/AGENTS.md"
    backup "$HOME/.codex/skills/adaptive-harness-stack-setup" codex
    act "remove ~/.codex/skills/adaptive-harness-stack-setup"
    [ "$DRY" = 0 ] && rm -rf "$HOME/.codex/skills/adaptive-harness-stack-setup"
    for a in "$ROOT"/agents/codex/*.toml; do
      n="$(basename "$a")"
      backup "$HOME/.codex/agents/$n" codex
      act "remove ~/.codex/agents/$n"
      [ "$DRY" = 0 ] && rm -f "$HOME/.codex/agents/$n"
    done
    retire "$HOME/.codex/agents/scout.toml" codex
  fi
  [ "$DRY" = 0 ] && [ -d "$BACKUP" ] && echo "Backup: $BACKUP"
  exit 0
fi

# --------------------------------------------------------------------------- build
echo "Building from src/:"
bash "$ROOT/build.sh"
echo

# --------------------------------------------------------------------------- claude
if [ "$DO_CLAUDE" = 1 ]; then
  echo "Claude Code:"
  [ "$DRY" = 0 ] && mkdir -p "$HOME/.claude/skills"

  install_file "$DIST/CLAUDE.md" "$HOME/.claude/CLAUDE.md" claude

  # Merge the permission allowlist into settings.json without clobbering existing keys.
  need jq
  SETTINGS="$HOME/.claude/settings.json"
  settings_input="$SETTINGS"
  if [ ! -f "$settings_input" ]; then
    settings_input="$(mktemp)"
    printf '{}\n' > "$settings_input"
  fi
  tmp="$(mktemp)"
  jq -s '
    .[0] as $cur | .[1] as $new
    | $cur
    | .permissions.allow = (((($cur.permissions.allow) // []) + $new.permissions.allow) | unique)
    | .permissions.ask   = (((($cur.permissions.ask)   // []) + $new.permissions.ask)   | unique)
  ' "$settings_input" "$ROOT/settings/claude-settings.json" > "$tmp"
  if [ -f "$SETTINGS" ] && cmp -s "$tmp" "$SETTINGS"; then
    say "$SETTINGS permissions already current"
  else
    backup "$SETTINGS" claude
    act "merge permissions into $SETTINGS"
    [ "$DRY" = 0 ] && mv "$tmp" "$SETTINGS"
  fi
  rm -f "$tmp"
  [ "$settings_input" = "$SETTINGS" ] || rm -f "$settings_input"

  install_skill_link "$HOME/.claude/skills/adaptive-harness-stack-setup" claude

  # Cheap-tier subagents. Copied, not symlinked: Claude Code scans this directory for
  # *.md and a dangling symlink here breaks agent discovery for the whole session.
  [ "$DRY" = 0 ] && mkdir -p "$HOME/.claude/agents"
  retire "$HOME/.claude/agents/scout.md" claude
  for a in "$ROOT"/agents/claude/*.md; do
    n="$(basename "$a")"
    install_file "$a" "$HOME/.claude/agents/$n" claude
  done
  echo
fi

# --------------------------------------------------------------------------- codex
if [ "$DO_CODEX" = 1 ]; then
  echo "Codex CLI:"
  [ "$DRY" = 0 ] && mkdir -p "$HOME/.codex/skills"

  install_file "$DIST/AGENTS.md" "$HOME/.codex/AGENTS.md" codex

  install_skill_link "$HOME/.codex/skills/adaptive-harness-stack-setup" codex

  [ "$DRY" = 0 ] && mkdir -p "$HOME/.codex/agents"
  retire "$HOME/.codex/agents/scout.toml" codex
  for a in "$ROOT"/agents/codex/*.toml; do
    n="$(basename "$a")"
    install_file "$a" "$HOME/.codex/agents/$n" codex
  done

  # config.toml is left alone on purpose: it holds ~50 project trust levels.
  # Report drift from the recommended defaults instead of rewriting it.
  CFG="$HOME/.codex/config.toml"
  if [ -f "$CFG" ]; then
    echo "  config.toml (not modified — check these by hand):"
    for kv in 'model=gpt-5.6-sol' 'model_reasoning_effort=medium' 'sandbox_mode=workspace-write' 'approval_policy=on-request' 'web_search=live'; do
      k="${kv%%=*}"; want="${kv#*=}"
      have="$(grep -E "^[[:space:]]*$k[[:space:]]*=" "$CFG" | head -1 | sed 's/.*=[[:space:]]*//; s/"//g' || true)"
      if [ -z "$have" ]; then
        printf '    %-24s missing   (recommended: %s)\n' "$k" "$want"
      elif [ "$have" != "$want" ]; then
        printf '    %-24s %-12s (recommended: %s)\n' "$k" "$have" "$want"
      else
        printf '    %-24s %s ✓\n' "$k" "$have"
      fi
    done

    echo "    note: explorer and log-digger pin their own models; config.toml is left untouched."
  fi
  echo
fi

if [ "$DRY" = 0 ]; then
  [ -d "$BACKUP" ] && echo "Backup of replaced files: $BACKUP"
  echo "Done. Start a new session to pick up the changes."
  echo "Per-repo setup and recommendations (skills, agents, hooks, MCP, memory, schedules,"
  echo "worktrees): see docs/PER-REPO.md"
else
  echo "Dry run complete. No global files written; dist/ was regenerated from src/."
fi
