# Global skills and plugins

Last reviewed: **2026-08-13**.

The global harness carries behavior (`src/core.md`). This file records the small set of *skills*
and *plugins* installed at user level for both harnesses, and why each one earned that scope.

**`../skills.sh` is the executable form of this file.** It holds the same tier as a manifest and
installs, verifies, or updates it; `validate.sh` fails if the manifest and the tables below name
different things. Until 2026-08-13 this file was the *only* record, `install.sh` provisioned none
of it, and the entire tier was absent on a machine whose docs said it was installed. Prose that
nothing executes is a wish, not a configuration.

```bash
../skills.sh --check     # local, no network: is the tier actually present?
../skills.sh             # install whatever is missing
../skills.sh --update    # update skills and the marketplace cache
```

A skill installed globally costs its description in every session, on both harnesses, forever.
That is the budget line. Keep only skills whose trigger and complete dependency chain are safe in
every repository; the full catalog is the ECC mistake again.

## Two delivery mechanisms, not one

They are managed by different tools and do not share a store:

| | Installed with | Where it lands | Discovery |
|---|---|---|---|
| **Skills** | `npx skills add -g` | `~/.claude/skills/<name>/` and `~/.codex/skills/<name>/`; `~/.agents/skills/` is the shared store the CLI uses when a single copy backs several agents | each harness scans its own skills directory |
| **Plugins** | `claude plugin` / `codex plugin` | `~/.claude/plugins/marketplaces/<market>/`, enabled in `~/.claude/settings.json` | each harness's own marketplace cache |

**Do not treat any particular store layout as the contract.** The `skills` CLI decides it and has
changed it: targeting `--agent claude-code` alone now *copies* the skill straight into
`~/.claude/skills/<name>/` and never creates `~/.agents/`, while a multi-agent install may keep one
copy in `~/.agents/skills` and link to it. Both are fine. A missing `~/.agents/` is not a fault to
repair — verified on 2026-08-13, `skills` CLI via `npx skills@latest`, Claude Code 2.1.231.

What must be true is that the harness can *see* the skill, so check for the file it reads:

```bash
ls ~/.claude/skills/*/SKILL.md      # what Claude Code actually loads
npx skills list -g                  # source repo and target agents per skill
```

`../skills.sh --check` is that check, for every entry in the tier at once, and it is what
`install.sh` now reports on. The historical failure it guards against: `find-skills` was dead from
2026-08-04 to 2026-08-05 because it was installed with `lastSelectedAgents` that did not include
`claude-code`, so always pass the agents explicitly rather than accepting the remembered default:

```bash
npx skills add -g <owner>/<repo> --skill <names...> --agent claude-code codex -y
```

## Installed: skills

Reproduce the global skill tier on a new machine with `../skills.sh`. The equivalent raw commands,
which is what the script runs:

```bash
npx skills add -g vercel-labs/skills --skill find-skills --agent claude-code codex -y
npx skills add -g mattpocock/skills \
  --skill diagnosing-bugs grilling handoff resolving-merge-conflicts wayfinder wizard \
  --agent claude-code codex -y
```

All seven names were confirmed still present upstream on 2026-09-25 (`npx skills add <repo> --list`).
Check that before assuming a missing skill means a broken install — `mattpocock/skills` renames and
retires skills, and it now also ships a separate `claude-handoff`, which is not this `handoff`.

| Skill | Source | Why global |
|---|---|---|
| `find-skills` | vercel-labs/skills | Discovery entry point; searches skills.sh by keyword or owner |
| `diagnosing-bugs` | mattpocock/skills | Reproduce → minimize → hypothesize → instrument → make an evidence-backed local fix. No repo assumptions; publishing and external mutations remain forbidden |
| `grilling` | mattpocock/skills | Stress-tests a plan or decision by relentless questioning. Global by owner decision, 2026-09-25 |
| `handoff` | mattpocock/skills | Compacts a session into a continuation document |
| `resolving-merge-conflicts` | mattpocock/skills | Hunk-by-hunk by intent |
| `wayfinder` | mattpocock/skills | Maps work too large for one session as decision tickets on the issue tracker. Global by owner decision, 2026-09-25; it still needs `setup-matt-pocock-skills` in a repo to know the tracker, and its calls to `domain-modeling` find nothing because that skill stays uninstalled |
| `wizard` | mattpocock/skills | Generates interactive bash wizards for steps only a human can do — secrets, CI credentials, third-party dashboards, one-off cutovers. The best fit in the catalog for this toolchain |

## Installed: vendored skills

Adapted copies that live in this repo under `../vendor/skills/<name>/`. `install.sh` symlinks
each one into `~/.claude/skills/` and `~/.codex/skills/` exactly as it links `skill/`. `skills.sh`
does not touch them, and `npx skills update` cannot change them; upstream changes arrive only by
re-reading upstream and editing here.

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

`setup-matt-pocock-skills`, `to-spec`, `to-tickets`, `implement`, `triage`, `code-review`,
`grill-with-docs`

`research` is also per repo, and only when a durable cited Markdown artifact is explicitly wanted.
Ordinary documentation lookup uses current primary sources on the web; it should not
automatically spawn an agent and write a file. `grill-me` is not installed because it is only a
seven-line launcher for `grilling`, which is global. Use `grill-with-docs` in repositories that
benefit from durable domain docs.

### Deliberately not installed at all

`tdd`, `codebase-design`, `improve-codebase-architecture`, `prototype`, `domain-modeling` — all
assume application code with test seams. Do not force them onto Terraform, Helm, Kubernetes,
Ansible, or Puppet.

## Installed: plugins (Trail of Bits)

Marketplace added to both harnesses. Codex consumes Claude plugin marketplaces directly, so there
is no Codex-specific sidecar. Installed versions as of 2026-08-13: `gh-cli` 1.5.1, `git-cleanup`
1.0.1, `insecure-defaults` 2.0.0. `claude plugin install` writes `enabledPlugins` and
`extraKnownMarketplaces` into `~/.claude/settings.json` — that is the cheap local proof a plugin is
present, and what `../skills.sh --check` reads:

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

### The Codex half is conditional

`codex plugin` and `codex plugin marketplace` exist (codex-cli 0.146.0), but a `codex` binary on
`PATH` does not mean Codex is usable: without `~/.codex/config.toml` it has no configuration and no
auth, and installing into it writes state nothing reads. `../skills.sh` therefore treats Codex as
absent unless that file exists, and says so instead of failing. On this machine the Codex commands
above are documented but deliberately unrun.

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
| `static-analysis` (`semgrep`) | Repos wanting the plugin's orchestration — parallel scans, SARIF, per-finding verifiers — on top of Semgrep. The binary alone covers ad-hoc scanning (see below); the plugin is the per-repo decision — `claude plugin install static-analysis@trailofbits --scope project` |
| `agentic-actions-auditor` | Only repos whose workflows invoke Claude Code Action, Gemini CLI, OpenAI Codex, or GitHub AI Inference. It audits AI agents in CI, not general Actions security |

`static-analysis` 1.3.1 was enabled at user scope until 2026-08-17, contradicting the gate above;
`./skills.sh --check` reported the tier complete and so never surfaced it. It is now uninstalled and
the enabled set matches the manifest exactly. It was never load-bearing, and it cannot be fed local
rule paths anyway — `run-scans.sh` jq-validates every ruleset as a registry identifier.

### Semgrep is not harness infrastructure

`semgrep` (1.172.0 via Homebrew here) is a manual tool, not part of this harness. Nothing installs
or wraps it. For infra work its coverage is thin next to what is already in the toolchain — 63
Terraform rules against `checkov`/`tfsec`/`trivy`, 7 Dockerfile against `hadolint`, 12 Actions
against `actionlint`/`zizmor`, 52 secrets against `gitleaks`, and `insecure-defaults` already
answers reachability. Its real win is `p/python`'s 151 rules, on a minority surface. Use it when you
remember it exists:

```bash
semgrep -e '<pattern>' -l <lang> <path>     # AST-aware grep, no network
```

**Put `export SEMGREP_ENABLE_VERSION_CHECK=0` in your shell profile.** The version check runs on
*every* invocation, including `--version` and ad-hoc `-e` patterns, and behind a TLS interceptor it
cannot succeed and does not fail fast. Measured 2026-08-17: the same `-e` scan took **99 s** without
the variable and **1 s** with it. Harmless on an unintercepted machine, so it belongs in the profile
on every machine.

Registry configs (`--config p/…`, `r/…`, `auto`) cannot work from the host binary behind Netskope,
and no trust store fixes it: the intercepting CA (`ca.lnw.goskope.com`) carries no `keyUsage`
extension, and OpenSSL ≥3.5 rejects that *structurally* — `CA cert does not include key usage
extension`. It is a malformed CA, not an untrusted one, so `REQUESTS_CA_BUNDLE` and `SSL_CERT_FILE`
change nothing. semgrep 1.172.0 links OpenSSL 3.6.3. `git clone` is unaffected; git uses a
different TLS stack. If you genuinely want a registry pack on an intercepted machine, run the
container, whose older OpenSSL accepts the CA structure:

```bash
docker run --rm -v "$PWD:/src" -v ~/.config/certs/corp-ca-bundle.pem:/ca.pem:ro \
  -e REQUESTS_CA_BUNDLE=/ca.pem -e SSL_CERT_FILE=/ca.pem \
  -e SEMGREP_ENABLE_VERSION_CHECK=0 \
  semgrep/semgrep semgrep --config p/python --metrics=off /src
```

A shim that routed this automatically, plus a script that vendored expanded packs into
`~/.config/semgrep/packs`, were built and removed on 2026-08-17 — see the `docs/SOURCES.md`
changelog for why. Short version: they hardcoded `/opt/homebrew`, gated on a certificate file
rather than on the actual failure, and the packs carry a license that keeps them out of Git, so
none of it could travel to another machine. This section can.

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
../skills.sh --update    # npx skills update -g -y, then the marketplace cache
```

Which runs the two underlying commands, plus the Codex one by hand where Codex is configured:

```bash
npx skills update -g -y                       # skills
claude plugin marketplace update trailofbits  # plugins
codex  plugin marketplace upgrade trailofbits
```

Both upstreams move fast. Re-read a skill body after an update before trusting it — they run with
full agent permissions.

## Adding or removing an entry

Edit the manifest at the top of `../skills.sh` **and** the tables here in the same change.
`validate.sh` fails when they disagree, which is the whole point: the tier cannot drift back into
being documentation-only.
