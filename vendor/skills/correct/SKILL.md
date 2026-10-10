---
name: correct
description: "Find the mistakes agents keep repeating in this repo and make each one impossible. Try structure first, then schema and validation, then a lint or policy check whose error names the fix, then a hook or test, and write docs last. Prove each check fails on a real past mistake. Repeat this each time the operator corrects you. Use for /correct."
disable-model-invocation: true
---

<!-- Adapted from cursor/plugins pstack/skills/correct (MIT, Lauren Tan), upstream
     d73344b 2026-10-09. Enforcement levels retargeted at Terraform, Helm, Kubernetes,
     Ansible, Puppet, and CI; agent-harness hooks added as a level. See LICENSE. -->

# Correct

The operator keeps correcting agents in this repo for the same mistakes. Change the repo so the next agent can't make them.

Assume every contributor is an agent that sees only the files it opened, copies the nearest example, and takes the shortest path that passes `validate` or `lint`. Design the repo so a change that looks right from one file is right for the whole repo.

## Find the mistake classes

First, read recent commits, reverts, review comments, agent instruction files (`CLAUDE.md`, `AGENTS.md`, `.claude/`), and comments that explain workarounds. Group the mistakes into classes. A class counts once it has happened twice.

## Fix each class at the highest level that works

1. **Eliminate it with structure.** Give each resource, value, and piece of state one owner and each task one supported way. One module or chart owns a resource, and everything else consumes its outputs. Replace hand-synced lists (CIDRs, account IDs, image tags, version pins) with one source of truth: `locals`, a shared values file, a data source, group vars. Delete old modules, copy-pasted environments, and dead examples an agent would copy.
2. **Make the bad state fail validation.** Terraform type constraints, `validation` blocks, and `precondition` / `postcondition`. Helm `values.schema.json` and `required` / `fail` in templates. Kubernetes CRD schemas and admission policy. Ansible `argument_specs`. Puppet data types on class parameters. The error message must name the fix.
3. **Catch it with a lint or policy check.** `tflint` rules, OPA / Conftest, Checkov, `kube-linter`, `ansible-lint`, `puppet-lint`, `actionlint`, `yamllint`, wired into pre-commit and CI. The error names the file, module, or value to use instead. If the pattern is already common, fail only when a change adds more.
4. **Block it at the agent.** For mistakes in what the agent runs rather than what it writes (an apply, a force-push, a command against the wrong context), add a harness hook that denies the command and says what to run instead.
5. **Test the behavior.** `terraform test`, `helm unittest` or `ct`, Molecule, rspec-puppet, a plan or render assertion in CI. Fix or delete any test that would still pass if the module rendered nothing.
6. **Write docs or agent rules last, only for judgment calls.** Nothing fails when an agent skips them.

## Fix and prove

Then fix the most frequent classes now, one reviewable change each. Prove each new check fails on a real past mistake: check out or reconstruct the bad change and show the error. Run the same command locally and in CI. Exceptions go on the offending line with a reason, an expiry date, and a human's approval (`# tflint-ignore: <rule> # <reason>, expires <date>`, `#checkov:skip=<id>:<reason>`).

## Keep the rule table

Last, keep a table in the repo's agent instruction file that pairs each rule with what enforces it. When the operator corrects you, fix the mistake and add the rule. If the rule was already there and nothing enforces it, that's a repeat, so fix it at the highest level in the same change. Drop a rule once its mistake can't happen.

**Reply:** each class with its evidence, the level you picked, and why a higher level didn't work.
