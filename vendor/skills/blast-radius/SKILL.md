---
name: blast-radius
description: "Find what an infrastructure or code change could break somewhere else before it ships, beyond the diff, and prove the one fact it's safe because of by running a real dry-run instead of writing it up. Use for 'blast radius of X', 'what could this break', or reviewing a small diff you don't trust."
disable-model-invocation: true
---

<!-- Adapted from cursor/plugins pstack/skills/blast-radius (MIT, Lauren Tan), upstream
     d73344b 2026-10-09. Retargeted at Terraform, Helm, Kubernetes, Ansible, Puppet, and CI;
     references to pstack's `why` and `arena` skills removed. See LICENSE. -->

# Blast radius

Find what a change breaks somewhere else, before it ships. Use for "blast radius of X", "what could this break", or reviewing a small diff you don't trust yet.

Listing the callers is not the job. The agent can grep those in a second. The job is the breakage grep won't show you: the resource that gets replaced instead of updated, the consumer in another repo, the default that changed under a version bump.

Everything here is read-only. Plans, renders, diffs, and dry-runs only. Never apply, sync, upgrade, or mutate shared state to prove a point.

## Don't trust your own writeup

A blast-radius writeup that sounds right is worthless. It reads as convincing whether or not it's true. So don't hand back the writeup. Find the one or two facts the whole thing depends on and prove them by running something.

### How sure are you

For each fact the change's safety depends on, get it as far down this list as is cheap, and say where it stopped.

1. You said so. Worthless on its own.
2. You pointed at the line. A real `file:line`, or the provider, chart, or module source at the pinned version.
3. You showed the bad case can't happen. You walked the failure step by step and it doesn't reach.
4. You ran it. A dry-run against the real thing that fails loud if you're wrong: `terraform plan` against the real backend, `helm template` rendered before and after and diffed, `kubectl diff` or `kubectl apply --dry-run=server` against the target cluster, `ansible-playbook --check --diff`, `puppet apply --noop`, `terraform console` to evaluate the exact expression.
5. You reproduced it in a non-production environment that runs the same versions.

Step 4 is usually one command. A plan that shows `0 to destroy` and no `must be replaced` is worth more than a page of reasoning.

## Steps

1. **Read the change.** The diff, plus what it now does differently that the diff doesn't spell out. For declarative code that means the rendered result, not the source: the plan, the rendered manifests, the effective values after every overlay and values file merges. Pull the PR and commit history with `git log -p` and `gh pr view` to see what the author meant.
2. **Find the one fact it's safe because of.** Most changes that look risky are safe because of a single fact, like "the plan only updates tags in place" or "this label is not part of any selector". Find that fact. If it holds, most risky cases are cleared at once. Spend your time here, not on a long list of maybes.
3. **Look where grep stops.** Read the provider, chart, or module source at the pinned version and the lock file, not the latest docs. Then check the places a text search misses:
   - **Replacement instead of update.** ForceNew or immutable fields (names, subnets, AZs, engine versions, Deployment and StatefulSet `selector`, PVC storage class), `for_each` keys or `count` indexes that shift, resource addresses that change without a `moved` block, `create_before_destroy` against names that must be unique.
   - **Consumers outside this repo.** Module callers pinned by `?ref=`, `terraform_remote_state` and SSM or Secrets Manager readers of outputs, services that resolve a DNS name or read a ConfigMap, IAM principals that depend on a policy or trust relationship, dashboards and alerts keyed on metric or label names.
   - **Version and default drift.** Provider, chart, or collection bumps that change defaults, deprecated API versions, CRD schema changes, Helm subchart values that merge differently, Ansible or Puppet module defaults.
   - **Runtime and ordering.** Rollout strategy and PodDisruptionBudgets, readiness gates, Argo CD sync waves and hooks, Helm hooks, Ansible handlers, Puppet resource ordering, Terraform `depends_on`, admission webhooks and policy engines that can reject the new shape.
   - **Environment spread.** The same module or chart under every workspace, tfvars file, values file, overlay, inventory, and Hiera level. The change is safe only where you checked.
4. **Be honest about each risk.** Give it a real chance of happening and a real cost if it does. Keep the risks you confirmed. List the ones you checked and cleared separately. Cite a real `file:line` or command output. A search that finds nothing is still an answer, and never make up a consumer, a field, or a flag.
5. **Prove the one fact.** Run the dry-run that would show it false, and paste what happened. Redirect large output (a full plan, a rendered chart) to a file and quote only the lines that matter.

## What to hand back

- **What it does.** What changed, including the part that isn't obvious.
- **The one fact it's safe because of.** State it, say which step you got it to, and show the proof. If you couldn't prove it, write unproven.
- **Risks.** Each names how it breaks, the `file:line` or resource address, how likely and how bad, and how to check. Paste the proof for the ones that matter.
- **Cleared.** What you checked and why it's fine.
- **Before you merge.** The cheapest dry-run, plan, or test that catches the real breakage, as the exact command.

Write it in plain prose, cite real code and real output, and strip account IDs, hostnames, and secrets before it goes anywhere public.

**Reply:** the writeup above, with the one safety fact either proven or marked unproven.
