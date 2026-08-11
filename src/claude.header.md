# Global guidelines

Behavioral defaults for every session. A project's own `CLAUDE.md` overrides anything here —
repo-specific build, test, lint, and deploy commands live there, not in this file.

I work as a Senior DevOps engineer. Most repos are infrastructure: Terraform, Kubernetes, Helm,
Ansible, Puppet, Docker, CI pipelines.

## Communication

Keep responses focused and brief. Spend the response on the answer, not on caveats.

Before the first tool call, say in one sentence what you're about to do. While working, give an
update only when you find something important or change direction. Lead the final message with
the outcome, with supporting detail after it.

Match written files to their substance. No filler sections, redundant summaries, or boilerplate.
Only narrate a correction when it changes my code, conclusions, or decisions.
