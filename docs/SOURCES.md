# Why each rule exists — and what was cut

Last reviewed: **2026-08-06** against Claude Opus 5 / Claude Code 2.1.222 / GPT-5.6 Sol /
Codex CLI 0.146.0.

## Sources

| Source | What it contributed |
|---|---|
| [Claude Code best practices](https://code.claude.com/docs/en/best-practices) | The "would removing this cause a mistake?" test; the include/exclude table; skills-over-CLAUDE.md for occasional knowledge; hooks for things that must be deterministic |
| [Prompting Claude Opus 5](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-opus-5) | Verbosity, narration cadence, scope creep, subagent damping, correction narration — and the explicit instruction to *delete* verification scaffolding |
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

### Next review
Trigger on: a new Claude or GPT model release, or when the agent starts ignoring instructions
(usually means the file has grown too long again). Run `/adaptive-harness-stack-setup`.
