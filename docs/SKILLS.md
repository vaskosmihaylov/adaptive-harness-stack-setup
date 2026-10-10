# Global skills and plugins

Last reviewed: **2026-08-06**.

The global harness carries behavior (`src/core.md`). This file records the small set of *skills*
and *plugins* installed at user level for both harnesses, and why each one earned that scope.

A skill installed globally costs its description in every session, on both harnesses, forever.
That is the budget line. Keep only skills whose trigger and complete dependency chain are safe in
every repository; the full catalog is the ECC mistake again.

## Two delivery mechanisms, not one

They are managed by different tools and do not share a store:

| | Store | Installed with | Discovery |
|---|---|---|---|
| **Skills** | `~/.agents/skills/` | `npx skills add -g` | Codex reads `~/.agents/skills` natively ("universal"); Claude Code gets a symlink into `~/.claude/skills/` |
| **Plugins** | `~/.claude/plugins/`, `~/.codex/plugins/` | `claude plugin` / `codex plugin` | each harness's own marketplace cache |

`~/.agents/skills` alone is **not** enough for Claude Code. A skill placed there without the
`~/.claude/skills` symlink is inert on Claude and invisible in `/skills`. This is the failure mode
that left `find-skills` dead from 2026-08-04 to 2026-08-05: it was installed to `~/.agents/skills`
with `lastSelectedAgents` that did not include `claude-code`.

Always pass the agents explicitly:

```bash
npx skills add -g <owner>/<repo> --skill <names...> --agent claude-code codex -y
```

Verify after every install — the presence of the store directory proves nothing:

```bash
ls -la ~/.claude/skills/    # expect symlinks into ../../.agents/skills/
ls    ~/.agents/skills/     # Codex reads these directly
```

## Installed: skills

Reproduce the global skill tier on a new machine:

```bash
npx skills add -g vercel-labs/skills --skill find-skills --agent claude-code codex -y
npx skills add -g mattpocock/skills \
  --skill diagnosing-bugs handoff resolving-merge-conflicts wizard \
  --agent claude-code codex -y
```

| Skill | Source | Why global |
|---|---|---|
| `find-skills` | vercel-labs/skills | Discovery entry point; searches skills.sh by keyword or owner |
| `diagnosing-bugs` | mattpocock/skills | Reproduce → minimize → hypothesize → instrument → make an evidence-backed local fix. No repo assumptions; publishing and external mutations remain forbidden |
| `handoff` | mattpocock/skills | Compacts a session into a continuation document |
| `resolving-merge-conflicts` | mattpocock/skills | Hunk-by-hunk by intent |
| `wizard` | mattpocock/skills | Generates interactive bash wizards for steps only a human can do — secrets, CI credentials, third-party dashboards, one-off cutovers. The best fit in the catalog for this toolchain |

## Installed: vendored skills

Adapted copies that live in this repo under `../vendor/skills/<name>/`. `install.sh` symlinks
each one into `~/.claude/skills/` and `~/.codex/skills/` exactly as it links `skill/`.
`npx skills update` cannot change them; upstream changes arrive only by re-reading upstream and
editing here.

Both are explicit-invoke only on both harnesses, so they cost nothing until called:
`disable-model-invocation: true` in `SKILL.md` for Claude Code (the description is not loaded),
and `agents/openai.yaml` with `policy.allow_implicit_invocation: false` for Codex (the shape
Codex's own `.system/review-agent` ships, verified against codex-cli 0.146.0 on 2026-10-10).
`validate.sh` fails a vendored skill missing either, its `LICENSE`, or a row here.

| Skill | Upstream | Why global | What changed from upstream |
|---|---|---|---|
| `blast-radius` | `cursor/plugins` `pstack/skills/blast-radius` @ `d73344b` (2026-10-09) | Finds what a change breaks beyond the diff and proves the one safety fact with a real dry-run. Fits every infra repo: replacement-vs-update, out-of-repo consumers, version-default drift | Proof ladder and "where grep stops" rewritten for `terraform plan`, `helm template`, `kubectl diff`, `--check`/`--noop`; read-only rule added; dependencies on pstack's `why`, `arena`, and `unslop` removed |
| `correct` | `cursor/plugins` `pstack/skills/correct` @ `d73344b` (2026-10-09) | Turns repeated agent corrections into enforced checks, highest level first. The same job this harness does globally, applied per repo | Levels retargeted from app types to Terraform/Helm/Ansible/Puppet validation, policy linters, and tests; a harness-hook level added for mistakes in what the agent runs |

The rest of pstack was reviewed on 2026-10-10 and left out: `poteto-mode` and the 24
`principle-*` skills are one author's operating style, mostly already in `src/core.md`, and
`principle-never-block-on-the-human` contradicts its confirmation rules; `recall` reads Cursor
transcript paths; `swarm`, `arena`, and `interrogate` are multi-agent fan-outs; `unslop` is
already installed separately; `tdd`, `typescript-best-practices`, and `make-bot-ui` assume
application code. `addyosmani/agent-skills` was rejected whole on the same date: 25
model-invoked skills, none mentioning Terraform, Helm, Kubernetes, or Ansible, largely
restating `src/core.md` and the Matt Pocock tier.

### Deliberately not global — per repo only

These depend on repository-specific tracker, specification, review, or domain-document context:

`setup-matt-pocock-skills`, `to-spec`, `to-tickets`, `implement`, `triage`, `wayfinder`,
`code-review`, `grill-with-docs`

`research` is also per repo, and only when a durable cited Markdown artifact is explicitly wanted.
Ordinary documentation lookup uses current primary sources on the web; it should not
automatically spawn an agent and write a file. `grill-me` is not installed because it is only a
seven-line launcher for the separate `grilling` skill. Avoiding that hidden dependency is cheaper
than globalizing both; use `grill-with-docs` in repositories that benefit from durable domain docs.

### Deliberately not installed at all

`tdd`, `codebase-design`, `improve-codebase-architecture`, `prototype`, `domain-modeling` — all
assume application code with test seams. Do not force them onto Terraform, Helm, Kubernetes,
Ansible, or Puppet.

## Installed: plugins (Trail of Bits)

Marketplace added to both harnesses. Codex consumes Claude plugin marketplaces directly, so there
is no Codex-specific sidecar:

```bash
claude plugin marketplace add trailofbits/skills
codex   plugin marketplace add trailofbits/skills
claude plugin install gh-cli@trailofbits
claude plugin install git-cleanup@trailofbits
claude plugin install insecure-defaults@trailofbits
codex plugin add gh-cli@trailofbits
codex plugin add git-cleanup@trailofbits
codex plugin add insecure-defaults@trailofbits
```

| Plugin | Scope | Notes |
|---|---|---|
| `gh-cli` | global | Redirects GitHub URL fetches to the authenticated `gh` CLI. **Install the plugin, not the skill** — the value is in `hooks/`: `intercept-github-fetch.sh`, `intercept-github-curl.sh`, a PATH shim for `gh` anti-patterns, and `cleanup-clones.sh` at session end |
| `git-cleanup` | global, explicit invoke only | Gated worktree and branch cleanup: exact-command confirmation, refuses on a dirty worktree. Pairs with the worktree guidance in PER-REPO.md |
| `insecure-defaults` | global install, on-demand run | `/insecure-defaults:audit [path]` |

### `gh-cli` hooks are Claude-only in practice

`plugins/gh-cli/hooks/hooks.json` is Claude schema throughout — `SessionStart`, `SessionEnd`, and
`PreToolUse` with `"matcher": "WebFetch"`, a Claude tool name with no Codex equivalent — and
`${CLAUDE_PLUGIN_ROOT}` for paths. After installing on Codex, `~/.codex/config.toml` gains only:

```toml
[plugins."gh-cli@trailofbits"]
enabled = true
```

No hook registration. **Treat URL interception as Claude-only.** Codex gets the `gh-cli` skill
body; assume the hooks are inert there until proven otherwise.

### `insecure-defaults` is command-shaped, not a skill

As of upstream `ea7c60e` (2026-08-05) there is no `SKILL.md` — the plugin ships
`commands/audit.md` plus `workflows/audit.js`. `npx skills add trailofbits/skills@insecure-defaults`
finds nothing to install. Use the marketplace on both harnesses.

Run it on demand only, never from a hook: one run is recon (1 agent) + six parallel category
sweeps + N Opus refuting verifiers (≤16 findings each) + a report agent.

Its value over `checkov`/`tfsec`/`trivy` is the reachability question those cannot answer — it
separates **configurable** defaults (`env.get('K','x')`, only a bug if it runs) from
**unconditional** ones (insecure as written, about half of all findings), and each verifier starts
at `refuted: true`.

## Per repo, not global

| Plugin | Gate |
|---|---|
| `static-analysis` (`semgrep`) | Repos where a Semgrep scan is actually wanted. `semgrep` 1.172.0 is installed globally; the plugin and rulesets remain per-repo decisions |
| `agentic-actions-auditor` | Only repos whose workflows invoke Claude Code Action, Gemini CLI, OpenAI Codex, or GitHub AI Inference. It audits AI agents in CI, not general Actions security |

### Semgrep ruleset pinning

The skill treats third-party rulesets (Trail of Bits, 0xdea, Decurity) as mandatory but says
nothing about pinning. Semgrep rules are executable patterns fetched over the network. Unpinned,
an audit is both non-reproducible and importing unreviewed remote content mid-review. **Pin
revisions.** Keep the skill's own `--metrics=off` discipline: `--config auto` phones home.

## Rejected

| Candidate | Reason |
|---|---|
| `codeql` | Supported languages are Python, JS/TS, Go, Java/Kotlin, C/C++, C#, Ruby, Swift. No HCL, YAML, or Ansible — it analyzes nothing in these repos. Also carries database-build cost and a documented macOS `arm64` exit-137 workaround. Reconsider for substantial Go or Python operators/controllers |
| `supply-chain-risk-auditor` | Risk criteria are sound, but its discovery layer walks *package* dependencies. The real supply chain here is Terraform providers and module sources, Helm chart dependencies, pinned Action SHAs, base images, and Ansible collections. A custom infrastructure version reusing its criteria — and its "use `gh` for exact numbers, never guess" rule — is worth building |
| `differential-review` | Well-built, but duplicates the built-in `/code-review` and `/security-review`. Third review path, same job |
| `secure-workflow-guide` | Generic name, smart-contract scope: it lives under `plugins/building-secure-contracts/` and drives Slither, upgradeability, and ERC conformance |
| DevOps skill collections (`jeffallan/claude-skills@devops-engineer` and similar) | Persona/role skills — the pattern already rejected with `agency-agents`. Top hit has 7.9K installs, everything below under 900. The large "150+ skills" repos are knowledge dumps of what the models already know, at permanent context cost |

## License

`trailofbits/skills` is **CC-BY-SA-4.0**. Share-alike. Using the plugins is unencumbered, but
vendoring or adapting their skill text into a repository makes the derivative subject to SA.
Check before that lands in a company repository. `mattpocock/skills` and `hashicorp/agent-skills`
do not carry this constraint. The vendored pstack skills are MIT; each directory keeps the
upstream `LICENSE`, which is the only condition.

## Maintenance

```bash
npx skills update -g -y                       # skills
claude plugin marketplace update trailofbits  # plugins
codex  plugin marketplace upgrade trailofbits
```

Both upstreams move fast. Re-read a skill body after an update before trusting it — they run with
full agent permissions.
