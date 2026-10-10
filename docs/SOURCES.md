# Why each rule exists — and what was cut

Last reviewed: **2026-09-25** against Claude Opus 5.5 / Claude Code 2.1.282. Codex side last
verified 2026-08-17 against GPT-5.6 / Codex CLI 0.146.0 (see the 2026-09-25 entry).

## Sources

| Source | What it contributed |
|---|---|
| [Claude Code best practices](https://code.claude.com/docs/en/best-practices) | The "would removing this cause a mistake?" test; the include/exclude table; skills-over-CLAUDE.md for occasional knowledge; hooks for things that must be deterministic |
| [Prompting Claude Opus 5](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-opus-5) | Verbosity, narration cadence, scope creep, subagent damping, correction narration — and the explicit instruction to *delete* verification scaffolding |
| [Prompting Claude Opus 5.5](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-opus-5-5) and its [migration guide](https://platform.claude.com/docs/en/models/opus-5-5/migration-guide) | `medium` default effort; built-in progress updates between tool calls; remove "think carefully" and reasoning-in-response instructions (none present here) |
| [Claude prompting best practices](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices) | Positive examples over prohibitions; be explicit about desired behavior |
| [Claude Code docs](https://code.claude.com/docs) | Permission modes, settings.json schema, skills/subagents/hooks boundaries |
| [Claude Code scheduling](https://code.claude.com/docs/en/scheduled-tasks) and [worktrees](https://code.claude.com/docs/en/worktrees) | Repo-mode recommendations for session loops, durable schedules, goals, and isolated parallel edits |
| [Codex prompting guide](https://developers.openai.com/cookbook/examples/gpt-5/codex_prompting_guide) | AGENTS.md hierarchy (root→leaf, later overrides earlier); reasoning effort defaults; *don't* instruct upfront plans/preambles — it causes early stops |
| [GPT-5.6 model guidance](https://developers.openai.com/api/docs/guides/latest-model?model=gpt-5.6#prompting-best-practices) | Lean prompts; compact autonomy and approval boundaries; Sol/Terra/Luna tier roles; medium effort as the balanced starting point |
| [ChatGPT/Codex best practices](https://learn.chatgpt.com/guides/best-practices) | Goal / Context / Constraints / Done-when prompt frame; AGENTS.md as an "open-format README for agents"; effort matched to task |
| [mattpocock/skills](https://github.com/mattpocock/skills) | Four complete repo-agnostic skills global; tracker/domain workflows and durable research artifacts per repo. See SKILLS.md and PER-REPO.md |
| [vercel-labs/skills](https://github.com/vercel-labs/skills) | The `skills` CLI and `find-skills`; the `~/.agents/skills` store and its symlink model |
| [trailofbits/skills](https://github.com/trailofbits/skills) | Security plugin marketplace (CC-BY-SA-4.0) — `gh-cli`, `git-cleanup`, `insecure-defaults` global; `semgrep`, `agentic-actions-auditor` per repo. See SKILLS.md |
| [hashicorp/agent-skills](https://github.com/hashicorp/agent-skills) | Official Terraform + Packer skills: HashiCorp style conventions, `terraform test`, Stacks, module refactoring, provider development. Per repo |
| [Codex manual](https://developers.openai.com/codex/codex-manual.md) | Current custom-agent precedence and model tiers, project hooks/config, local memories, scheduled tasks, and managed worktrees |

## Rule-by-rule

| Authored rule | Justification |
|---|---|
| **Documentation freshness** | Not a model-behavior fix — a domain fix. K8s APIs, TF providers, and cloud SDKs move faster than any training cutoff, and a plausible-but-deprecated resource block costs a real apply. Uses current primary web sources with installed-tool documentation as the fallback. |
| **Claude communication overlay** (brevity, cadence, deliverable length, correction narration) | Four separately documented Opus 5 behaviors. These stay in `src/claude.header.md`, not the shared core, because GPT-5.6 is concise by default and its Codex harness already supplies progress behavior. |
| **Scope** | "Claude Opus 5 can also expand the scope of a task, adding steps that weren't requested." Recommended constraint text, adapted. |
| **Right-sizing and delegation** | Opus 5 over-delegates; current Codex runs subagents when directly requested or when an applicable instruction/skill requests it. Both vendors describe subagents as a context-isolation tool with additional token cost. The rule keeps the main model on small work and routes only noisy recurring jobs to cheaper utilities. |
| **Searching and reading** | The only rule here added because the failure was *observed*, not predicted: the context window was filling early. `grep -r`, `ls -R`, and `find \| xargs cat` return a tree when one line was wanted, and both harnesses will happily run them. Passes the removal test — without it the model reaches for whole-file reads and uncapped output, which is exactly what exhausts the window. |
| **Blast radius** | The one section that is mine, not the vendors'. DevOps-specific and the highest-value content in the file: it enumerates the actual irreversible commands in this toolchain and requires naming the target environment before confirmation. Not a model deficiency — a blast-radius control. |
| **Verification** (report honestly) | Kept only as *honest reporting*, not as an instruction to verify. See the cut list below for why that distinction matters. |

## What was cut, and why

| Cut | Reason |
|---|---|
| **VALIDATION / "always include a final verification step"** | Opus 5 guide, verbatim: *"If your prompt contains explicit verification instructions... remove them: instructions like these cause over-verification on Claude Opus 5, and removing them reduces wasted tokens with no loss in quality. The same applies to legacy harness scaffolding that adds separate verification steps."* |
| **"Double-check your answer" / re-verify loops** | Same guide: *"Claude Opus 5 catches and fixes its own mistakes well without prompting. Avoid instructing re-checks it already performs."* |
| **CORE PRINCIPLES (TDD, security-first, immutability, 80% coverage)** | Claude Code best practices lists "self-evident practices like 'write clean code'" under ❌ Exclude. These are project decisions, not global behavior — and when they *are* real project policy, they belong in that repo's CLAUDE.md or a Stop hook, where they're enforceable. |
| **[ECC](https://github.com/affaan-m/ECC)** — 60 agents / 232 skills / 75 commands, 281 lines in `~/.codex/AGENTS.md` | Exactly the "legacy harness scaffolding" the Opus 5 guide names. An agent roster the model must read every session to maybe use one entry, plus a verification-heavy workflow that now fires on top of behavior the model already has. Removed. |
| **[serena](https://github.com/oraios/serena)** (semantic code MCP) | Its value was symbol-level navigation. Claude Code now ships native LSP and code-intelligence plugins; Codex reads with ripgrep efficiently. An extra MCP server costs tool-definition tokens every session for capability that's now built in. Revisit only if a specific language stops navigating well. |
| **[agency-agents](https://github.com/msitarzewski/agency-agents)** | A large role catalog duplicates engineering capability already present in the main models and increases routing/context overhead. Repository-specific agents remain available for measured recurring jobs. |
| **[claude-code-best-practice](https://github.com/shanraisshan/claude-code-best-practice)** | Community restatement of the official docs; the official pages are now more current and are cited directly above. |
| **[awesome-devops-mcp-servers](https://github.com/rohitg00/awesome-devops-mcp-servers)** | Kept as a browsable list, not as an install target. Claude Code's own guidance: *"CLI tools are the most context-efficient way to interact with external services."* `kubectl`, `terraform`, `aws`, `gh` are already installed and already known. Add an MCP server only where no CLI exists. |
| **"Long-horizon persistence / don't stop for token budget" + mandatory progress files** | Both harnesses compact and persist sessions. Existing issues/specs are better durable state; add task files only for work that truly spans contexts and lacks a tracker. |
| **"Extract direct quotes for >20k-token documents"** | Marginal on a 1M-token context window with consistent long-context instruction following. |
| **"Use parallel tool calls"** | Already in both harnesses' built-in system prompts. Duplicating it buys nothing and costs context. |
| **Upfront plan/preamble instructions in AGENTS.md** | Codex guide: this *"can cause the model to stop abruptly before the rollout is complete."* The brief-cadence rule in core.md is deliberately about updates *during* work, not a required opening plan. |
| **[mattpocock/skills](https://github.com/mattpocock/skills) as a *whole-catalog* global install** | Revised 2026-08-05. Four complete repo-agnostic skills are global. Tracker/domain workflows stay per repo. `research` is per repo only when a durable artifact is explicitly wanted, and `grill-me` is rejected because it is only a launcher for the separately installed `grilling` skill. `tdd`, `codebase-design`, `improve-codebase-architecture`, `prototype`, and `domain-modeling` remain out: they assume app code with test seams. |
| **[trailofbits/skills](https://github.com/trailofbits/skills)@`codeql`** | Its own supported-language list is Python, JS/TS, Go, Java/Kotlin, C/C++, C#, Ruby, Swift. No HCL, YAML, or Ansible — it analyzes nothing in these repos, while charging database-build time and a documented macOS `arm64` exit-137 workaround. Reconsider only for substantial Go or Python operators/controllers. |
| **`supply-chain-risk-auditor`** | The risk criteria are good (single/anonymous maintainer, unmaintained, low popularity, FFI/deserialization, CVE history, no `SECURITY.md`) and it forbids guessing numbers. But its discovery layer walks *package* dependencies. The real supply chain here is Terraform providers and module sources, Helm chart dependencies, pinned Action SHAs, base images, Ansible collections. Build a custom infrastructure version reusing the criteria. |
| **`differential-review`** | Genuinely well-built — risk-first triage, blast radius, git-history regression detection, an anti-skip "Rationalizations" table. But `/code-review` and `/security-review` already ship in the harness. A third review path is duplicate machinery, the same objection as `agency-agents`. |
| **`secure-workflow-guide`** | Generic name, smart-contract scope. It lives under `plugins/building-secure-contracts/` and drives Slither, upgradeability, and ERC conformance. Rejected on inspection, not on the name. |
| **DevOps skill collections** (`jeffallan/claude-skills@devops-engineer`, `BagelHole/DevOps-Security-Agent-Skills`, `j4flmao/agent-skills`) | `npx skills find "terraform kubernetes devops"` returns persona skills — "devops-engineer", "devops-automator" — the role-catalog pattern already rejected with `agency-agents`. Top hit 7.9K installs, everything below under 900. The "150+ skills" repos are knowledge dumps of what the models already know, at permanent context cost. |
| **[codex_workflow](https://github.com/viettran-edgeAI/codex_workflow) as a global harness** | Its light default, compact work packages, and cheap-worker tier are sound. Its route taxonomy, executor/tester roster, repair loops, and mandatory progress documents duplicate current native orchestration and add always-on context. Keep only the useful patterns for exceptional large repo work. |

## Changelog

### 2026-08-03 — initial build
Replaced a 281-line ECC `AGENTS.md` and ~20 symlinked global skills with a ~75-line shared core
generating both `~/.claude/CLAUDE.md` and `~/.codex/AGENTS.md`. Net: roughly a 70% reduction in
always-loaded instruction tokens, with the DevOps blast-radius section as the only net addition.

### 2026-08-03 — token usage and model tiering
Added a **Right-sizing** section to `src/core.md` (absorbing the old Delegation section): the
default is minimal machinery, and escalation requires evidence and targets one dimension. Added
two read-only cheap-tier subagents, `scout` and `log-digger`, in `agents/`. Rationale, the
rejected candidates, and the Codex routing bug are in `docs/TOKENS.md`. Net +14 lines in core.md
— justified because both harnesses' defaults over-serve small tasks, which is the dominant cost.

### 2026-08-04 — current native orchestration and repository assessment
Re-checked the live Opus 5, GPT-5.6, Claude Code, and Codex manuals. Kept the lean global behavior
rules, replaced the generic scout names with the native exploration overrides (`Explore` on Haiku,
`explorer` on Terra), and kept Luna/Haiku log extraction as the only second utility. Expanded repo
mode to assess skills, project agents, both harnesses' hooks, MCP, memory, schedules/goals, and
worktrees. Rejected a global engineering division and the fixed `codex_workflow` route/roster;
retained its useful bounded-work-package pattern for exceptional large repository workflows.

### 2026-08-05 — global skill and plugin layer
Fixed a live bug: `find-skills` had sat in `~/.agents/skills` since 2026-08-04 with no
`~/.claude/skills` symlink, inert on Claude Code. `~/.agents/skills` is Codex's native discovery
path but only a *store* for Claude — the `skills` CLI must be told `--agent claude-code`.

Split `mattpocock/skills` into a six-skill global tier and a tracker-bound per-repo tier, replacing
the earlier blanket rejection. Added `trailofbits/skills` as a plugin marketplace on both harnesses
(Codex consumes Claude marketplaces directly, so no sidecar metadata) with `gh-cli`, `git-cleanup`,
and `insecure-defaults` global; `semgrep` and `agentic-actions-auditor` deferred to repo mode.
Rejected `codeql`, `supply-chain-risk-auditor`, `differential-review`, `secure-workflow-guide`, and
the community DevOps skill collections — see the cut table. New file: `docs/SKILLS.md`.

Two findings worth keeping: `gh-cli`'s hooks are Claude-schema (`PreToolUse` matching `WebFetch`,
`${CLAUDE_PLUGIN_ROOT}`) and register nothing in `~/.codex/config.toml`, so URL interception is
Claude-only; and `insecure-defaults` ships no `SKILL.md` at upstream `ea7c60e`, only
`commands/audit.md` plus `workflows/audit.js`, so `npx skills add` cannot install it.

### 2026-08-05 — portability and global-skill trigger correction
Removed absolute checkout and `Work`/`Personal` path assumptions from the setup skill. Repository
mode now resolves the current repository safely on any machine. Narrowed the Pocock global tier
from six to four: `grill-me` was incomplete without the separate `grilling` dependency, while
`research` auto-delegated and wrote a repository artifact for ordinary documentation questions.
Kept `wayfinder`, `grill-with-docs`, and durable research as per-repository choices. Diagnosis now
explicitly permits evidence-backed local fixes and in-session checks while preserving the ban on
publishing, deployment, and external-state mutation. Recorded Semgrep 1.172.0.

The portability review also corrected the new-machine path: `install.sh` reproduces authored
guidance and agents, while `docs/SKILLS.md` carries the explicit third-party skill/plugin commands.
Retune now audits both harnesses' live skill, plugin, and MCP discovery state.

### 2026-08-17 — Semgrep machinery built, then removed for portability
`static-analysis@trailofbits` was found enabled at *user* scope, contradicting its documented
per-repo gate, and its registry rulesets could not be fetched at all on the work machine. The
diagnosis is worth keeping: the Netskope intercepting CA carries no `keyUsage` extension, OpenSSL
≥3.5 rejects that structurally, and semgrep 1.172.0 links OpenSSL 3.6.3 — so it is a malformed CA,
not an untrusted one, and no trust-store variable can fix it.

The plugin was uninstalled. Two `bin/` scripts were then written to work around the transport: a
shim installed as `~/.local/bin/semgrep` that routed registry configs through the `semgrep/semgrep`
image, and a vendoring script that fetched expanded packs into `~/.config/semgrep/packs`. Both
worked, and both were removed the same day. Three reasons, all portability:

- The install gate keyed on `~/.config/certs/corp-ca-bundle.pem` *existing* — a symptom, not the
  condition. A fresh work machine reads as "no interceptor"; a fixed Netskope reads as "interceptor".
- `/opt/homebrew/bin/semgrep` was hardcoded. On an Intel Mac the shim would install *as* `semgrep`
  on PATH and then die with "real semgrep not found" — semgrep totally broken, strictly worse
  than absent.
- Vendored registry rules carry the **Semgrep Rules License v1.0**, so the packs can never be
  committed and can never travel with the repo.

This repo is cloned onto several Macs, personal and work, and every machine-specific workaround it
carries is a machine it breaks on. The judgement that settled it was not that semgrep is useless —
it is that ~400 lines of machinery is the unportable part and the diagnosis is the portable part.
What replaces all of it: one profile line, `export SEMGREP_ENABLE_VERSION_CHECK=0`, harmless
everywhere and worth **99 s → 1 s** on an ad-hoc `-e` scan (measured), because the version check
runs on every invocation and cannot fail fast behind the interceptor. `docs/SKILLS.md` keeps the
CA explanation and a copy-pasteable container command for the rare registry-pack case.

Semgrep's own value was also weaker than assumed for this toolchain: 63 Terraform rules against
`checkov`/`tfsec`/`trivy`, 7 Dockerfile against `hadolint`, 12 Actions against
`actionlint`/`zizmor`, 52 secrets against `gitleaks`, with `insecure-defaults` already answering
reachability. Only `p/python` (151 rules) is a clear win, on a minority surface.

### 2026-08-17 — search discipline and a deterministic delegation cap
Prompted by a reported symptom: the context window filling early. Most of the model tiering was
already in place — main model on `opus` at `medium` effort, both utilities pinned to `haiku` with
`effort: low`, both prompts already reaching for `rg` — so the work was the three real gaps.

New **Searching and reading** section in `src/core.md`: `Grep`/`rg` over `grep -r`, `ls -R`, and
`find | xargs cat`; locate with `-l`/`-c` before pulling matching lines; pipe streaming output
through `head`/`tail`; read a line range rather than a whole large file. Plus one line in
Right-sizing giving an oversized but judgment-free delegated job `model: sonnet` instead of pulling
it back into the main context. Net **+14 lines** in `core.md` (73 → 87), justified because this is
the observed failure, not a predicted one, and no other section could be cut to pay for it.

`settings/claude-settings.json` gained `CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH=1` and
`CLAUDE_CODE_MAX_CONCURRENT_SUBAGENTS=4` (both Claude Code ≥ 2.1.219). Over-delegation had been
discouraged in prose only, and the subagent docs are explicit that the instruction "only steers
Claude, so set the limits as well". The `install.sh` merge now carries `env` per key with harness
keys winning, so the caps reproduce on a new machine while a machine's own `ANTHROPIC_AUTH_TOKEN`,
base URL, and CA path survive a re-run. No credential enters this repo.

Rejected: `BASH_MAX_OUTPUT_LENGTH`, which caps the same hazard but truncates silently — recorded in
`docs/TOKENS.md` as a per-session tool, not a global default. Also rejected: a third installed agent
for the Sonnet tier. It is a `model` override on `general-purpose`, so the roster stays at two and
no session pays context for a definition it rarely uses.

### 2026-09-25 — backport of hand edits; Opus 5.5 recheck; Codex tier stale
The installed `~/.claude` files had been edited by hand on 2026-08-22 and had drifted from `src/`.
A plain `./install.sh` would have silently reverted them, so they were backported first: the
"prefer a path over a paste" rule into `core.md` (both harnesses have the log extractor), the
`docs-lookup` agent into `agents/claude/`, its routing line and the em-dash rule into
`claude.footer.md` (Claude-only, so Codex's AGENTS.md carries no reference to an agent it lacks),
and the `rg`-first lines plus `log-digger` `maxTurns: 15` into the two existing agents. Net
**+13 lines** in `core.md` (87 → 100): no cut, because every section still passes the removal
test and the paste rule addresses the same observed context-exhaustion failure as Searching and
reading.

Opus 5.5 guidance changes nothing in the authored text. Checked rule by rule:
- Effort: the default is now `medium` (Opus 5 was `high`), which already matches `effortLevel`.
- Removals the guide asks for ("think carefully" directives, reasoning written into the response,
  rules against thinking): none of them appear here. The verification cut stays correct.
- Progress updates: Opus 5.5 now writes short updates between tool calls by itself, so the
  cadence line in `claude.header.md` still passes the removal test. It is what keeps those
  updates to important findings. Updates arriving as thinking blocks is an API concern.
- Delegation: the guide doesn't mention it, so the Opus 5 damping and the env caps stay.
- Rejected: the guide's "explore broadly before acting, including sources the task does not
  mention". It is written for multi-app email/document workflows, and in this toolchain it would
  work against the Scope rule.

`haiku` still resolves to Haiku 4.5, so the agent aliases stand.

Not changed, deliberately: `agents/codex/`. OpenAI now lists `gpt-6-astra`/`gpt-6-sol`/`gpt-6-luna`
(Codex CLI 0.157.0), and `gpt-5.6-terra` has no successor. The installed Codex CLI is 0.146.0 and
unconfigured on this machine, so the new ids cannot be verified against it as the rules require.

Skill drift: `domain-modeling` (rejected) and `grill-with-docs` (per repo only) had been installed
globally. They were moved out of `~/.claude/skills` into the gitignored
`backups/20260925-skills-removed/`. `wayfinder` and `grilling` were promoted into the global
manifest by owner decision: both earn their place in daily use. Still outside the manifest:
`playwright-cli` and `unslop`. The `agent-routing.sh` / `unslop-always.sh` SessionStart
hooks live only in `~/.claude/hooks`.

### Next review
Trigger on: a new Claude or GPT model release, or when the agent starts ignoring instructions
(usually means the file has grown too long again). Run `/adaptive-harness-stack-setup`.
