#!/usr/bin/env bash
# Provision the global skill and plugin tier documented in docs/SKILLS.md.
# install.sh writes files; this script talks to the two package managers that own
# the tier (`npx skills` and `claude plugin`). Split out because it needs the
# network, while install.sh does not.
#
#   ./skills.sh              install anything missing (idempotent, needs network)
#   ./skills.sh --check      verify only, no network, non-zero exit on drift
#   ./skills.sh --dry-run    show what would be installed, change nothing
#   ./skills.sh --manifest   print the manifest as machine-readable lines
#   ./skills.sh --update     update installed skills and the marketplace cache
#   ./skills.sh --claude     Claude Code only
#   ./skills.sh --codex      Codex CLI only
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --------------------------------------------------------------------------- manifest
# The single source of truth for the tier. docs/SKILLS.md explains why each entry
# earned global scope; validate.sh fails if the two disagree.
SKILL_SOURCES=(
  "vercel-labs/skills:find-skills"
  "mattpocock/skills:diagnosing-bugs grilling handoff resolving-merge-conflicts wayfinder wizard"
)
MARKETPLACE_NAME="trailofbits"
MARKETPLACE_SOURCE="trailofbits/skills"
PLUGINS=(gh-cli git-cleanup insecure-defaults)

CHECK=0; DRY=0; MANIFEST=0; UPDATE=0; DO_CLAUDE=1; DO_CODEX=1
for arg in "$@"; do
  case "$arg" in
    --check)     CHECK=1 ;;
    --dry-run)   DRY=1 ;;
    --manifest)  MANIFEST=1 ;;
    --update)    UPDATE=1 ;;
    --claude)    DO_CODEX=0 ;;
    --codex)     DO_CLAUDE=0 ;;
    -h|--help)   sed -n '2,/^set -euo/{/^set -euo/!p;}' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "unknown flag: $arg" >&2; exit 2 ;;
  esac
done

say() { printf '  %s\n' "$*"; }
act() { if [ "$DRY" = 1 ]; then printf '  [dry-run] %s\n' "$*"; else printf '  %s\n' "$*"; fi; }

skill_names() { # every skill name in the manifest, one per line
  local spec
  for spec in "${SKILL_SOURCES[@]}"; do
    tr ' ' '\n' <<< "${spec#*:}"
  done
}

# --------------------------------------------------------------------------- manifest mode
if [ "$MANIFEST" = 1 ]; then
  for spec in "${SKILL_SOURCES[@]}"; do
    repo="${spec%%:*}"
    for name in ${spec#*:}; do
      printf 'skill %s %s\n' "$name" "$repo"
    done
  done
  printf 'marketplace %s %s\n' "$MARKETPLACE_NAME" "$MARKETPLACE_SOURCE"
  for p in "${PLUGINS[@]}"; do
    printf 'plugin %s %s\n' "$p" "$MARKETPLACE_NAME"
  done
  exit 0
fi

# Codex is only real once it has a config.toml. `command -v codex` succeeds on a
# machine where Codex was never configured, and installing there writes dead state.
if [ "$DO_CODEX" = 1 ]; then
  if ! command -v codex >/dev/null 2>&1; then
    DO_CODEX=0
    say "codex: binary not found — skipping"
  elif [ ! -f "$HOME/.codex/config.toml" ]; then
    DO_CODEX=0
    say "codex: no ~/.codex/config.toml (binary present but unconfigured) — skipping"
  fi
fi

AGENTS=()
[ "$DO_CLAUDE" = 1 ] && AGENTS+=(claude-code)
[ "$DO_CODEX" = 1 ] && AGENTS+=(codex)
if [ "${#AGENTS[@]}" = 0 ]; then
  echo "no target harness selected" >&2
  exit 2
fi

# --------------------------------------------------------------------------- checks
# A skill is present when Claude Code can actually see it: a directory (or symlink
# into ~/.agents/skills) under ~/.claude/skills holding a SKILL.md. The store layout
# is the CLI's business and has changed before; the SKILL.md is what must exist.
skill_installed() { [ -f "$HOME/.claude/skills/$1/SKILL.md" ]; }
codex_skill_installed() { [ -f "$HOME/.codex/skills/$1/SKILL.md" ]; }

settings_has() { # settings_has <jq-path>
  [ -f "$HOME/.claude/settings.json" ] || return 1
  [ "$(jq -r "$1 // false" "$HOME/.claude/settings.json")" = "true" ]
}
marketplace_registered() {
  [ -f "$HOME/.claude/settings.json" ] || return 1
  [ "$(jq -r --arg n "$MARKETPLACE_NAME" \
      '(.extraKnownMarketplaces[$n] != null)' "$HOME/.claude/settings.json")" = "true" ]
}
plugin_enabled() { settings_has ".enabledPlugins[\"$1@$MARKETPLACE_NAME\"]"; }

report() { # report; returns 1 if anything is missing
  local missing=0 name
  echo "Skills (global):"
  while read -r name; do
    if [ "$DO_CLAUDE" = 1 ] && ! skill_installed "$name"; then
      printf '    %-28s MISSING (claude)\n' "$name"; missing=1
    elif [ "$DO_CODEX" = 1 ] && ! codex_skill_installed "$name"; then
      printf '    %-28s MISSING (codex)\n' "$name"; missing=1
    else
      printf '    %-28s ok\n' "$name"
    fi
  done < <(skill_names)

  echo "Plugins (global):"
  if marketplace_registered; then
    printf '    %-28s ok\n' "marketplace:$MARKETPLACE_NAME"
  else
    printf '    %-28s MISSING\n' "marketplace:$MARKETPLACE_NAME"; missing=1
  fi
  for name in "${PLUGINS[@]}"; do
    if plugin_enabled "$name"; then
      printf '    %-28s ok\n' "$name"
    else
      printf '    %-28s MISSING\n' "$name"; missing=1
    fi
  done

  # Plugins enabled at user scope that the manifest does not claim. docs/SKILLS.md gates
  # `static-analysis` to per-repo installs (`claude plugin install -s project`), and a
  # user-scope install of it is precisely the drift that gate exists to prevent — which
  # this check reported as a complete tier until 2026-08-15. Reported, not a failure:
  # the fix is a scope decision, not a missing install.
  if [ -f "$HOME/.claude/settings.json" ]; then
    while read -r extra; do
      [ -n "$extra" ] || continue
      printf '    %-28s EXTRA — user scope, not in the manifest\n' "$extra"
    done < <(jq -r --arg m "@$MARKETPLACE_NAME" \
        '(.enabledPlugins // {}) | keys[] | select(endswith($m)) | rtrimstr($m)' \
        "$HOME/.claude/settings.json" \
      | grep -vxF "$(printf '%s\n' "${PLUGINS[@]}")" || true)
  fi
  return "$missing"
}

if [ "$CHECK" = 1 ]; then
  command -v jq >/dev/null 2>&1 || { echo "missing required tool: jq" >&2; exit 1; }
  if report; then
    echo "Global skill and plugin tier complete."
    exit 0
  fi
  echo
  echo "Run ./skills.sh to install what is missing (needs network)."
  exit 1
fi

# --------------------------------------------------------------------------- update
if [ "$UPDATE" = 1 ]; then
  echo "Updating:"
  act "npx skills update -g -y"
  [ "$DRY" = 0 ] && npx --yes skills@latest update -g -y
  act "claude plugin marketplace update $MARKETPLACE_NAME"
  [ "$DRY" = 0 ] && claude plugin marketplace update "$MARKETPLACE_NAME"
  echo
  echo "Re-read any skill body that changed before trusting it — they run with full agent permissions."
  exit 0
fi

# --------------------------------------------------------------------------- install
command -v jq  >/dev/null 2>&1 || { echo "missing required tool: jq" >&2; exit 1; }
command -v npx >/dev/null 2>&1 || { echo "missing required tool: npx" >&2; exit 1; }

echo "Skills (global, agents: ${AGENTS[*]}):"
for spec in "${SKILL_SOURCES[@]}"; do
  repo="${spec%%:*}"
  wanted=()
  for name in ${spec#*:}; do
    if skill_installed "$name" && { [ "$DO_CODEX" = 0 ] || codex_skill_installed "$name"; }; then
      say "$name already installed"
    else
      wanted+=("$name")
    fi
  done
  [ "${#wanted[@]}" = 0 ] && continue
  act "npx skills add -g $repo --skill ${wanted[*]} --agent ${AGENTS[*]} -y"
  if [ "$DRY" = 0 ]; then
    npx --yes skills@latest add -g "$repo" \
      --skill "${wanted[@]}" --agent "${AGENTS[@]}" -y
  fi
done
echo

# Plugins are Claude Code's own mechanism. Codex consumes the same marketplace, but
# `gh-cli`'s hooks are Claude schema throughout, so nothing here targets Codex.
if [ "$DO_CLAUDE" = 1 ]; then
  echo "Plugins (global):"
  command -v claude >/dev/null 2>&1 || { echo "missing required tool: claude" >&2; exit 1; }
  if marketplace_registered; then
    say "marketplace $MARKETPLACE_NAME already registered"
  else
    act "claude plugin marketplace add $MARKETPLACE_SOURCE"
    [ "$DRY" = 0 ] && claude plugin marketplace add "$MARKETPLACE_SOURCE"
  fi
  for name in "${PLUGINS[@]}"; do
    if plugin_enabled "$name"; then
      say "$name already installed"
    else
      act "claude plugin install $name@$MARKETPLACE_NAME"
      [ "$DRY" = 0 ] && claude plugin install "$name@$MARKETPLACE_NAME"
    fi
  done
  echo
fi

if [ "$DRY" = 0 ]; then
  echo "Verifying:"
  report || { echo; echo "Tier still incomplete — see the MISSING rows above." >&2; exit 1; }
  echo "Done. Start a new session to pick up new skills, plugins, and hooks."
else
  echo "Dry run complete. Nothing installed."
fi
