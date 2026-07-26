---
name: knowledge-curator
description: Curate verified, reusable knowledge into the shared eLeDia.OS_DevFlow repository and keep GitHub as the source of truth for agent skills. Use when an agent discovers a repeatable lesson, resolved failure pattern, updated framework rule, or cross-project practice that should benefit other agents; when reviewing knowledge candidates; when updating or deduplicating files under Skills/ or Playbooks/; or when synchronizing a merged GitHub skill into Multica.
---

# Knowledge Curator

Maintain shared knowledge as reviewed repository content, never as private agent
memory. Treat `https://github.com/jmoskaliuk/eLeDia.OS_DevFlow` on `main` as the
authoritative source. Treat Multica workspace skills as derived copies.

## Classify the knowledge

Put information in exactly one durable home:

- `Skills/`: stable, reusable "how" knowledge that applies across projects.
- `Playbooks/`: concrete deployment, release, or operational procedures for a
  particular project or environment.
- `00-master.md` through `05-quality.md`: product state, decisions, features,
  tasks, documentation, bugs, and tests for the DevFlow itself.
- Agent instructions: role and behavioral constraints specific to one agent.
- Project resources or descriptions: context that applies only to one Multica
  project.

Do not turn project paths, hostnames, credentials, temporary workarounds, or
one-off implementation details into a shared skill.

## Admit a knowledge candidate

Accept a candidate only when all of these are true:

1. It is supported by primary evidence: upstream documentation or source,
   a reproducible test, a reviewed code change, or a resolved incident with a
   known cause.
2. It is likely to recur and changes a future agent's decision or action.
3. Its scope and version boundaries are explicit.
4. It does not duplicate or contradict existing DevFlow guidance.
5. It contains no secret, personal data, private customer data, or sensitive
   operational value.

Reject speculation and preferences presented as facts. Defer contradictory,
security-critical, compliance, destructive, or release-policy changes for human
review.

Use this compact candidate shape when the evidence arrives through an issue:

```markdown
Target: <skill, playbook, or DevFlow document>
Claim: <the reusable knowledge>
Evidence: <URL, commit, file:line, test, or incident>
Scope: <versions, projects, or environments>
Action: <what an agent should do differently>
Supersedes: <existing rule, or none>
Risk: <low, medium, high>
```

## Curate into GitHub

1. Read the current target from `main` and search `Skills/`, `Playbooks/`, and
   the root DevFlow documents for overlapping guidance.
2. Classify the candidate and record why it is accepted, merged, deferred, or
   rejected.
3. Integrate accepted knowledge into the authoritative section. Do not append a
   second rule at the end if an existing rule should be corrected.
4. Keep instructions concise and imperative. Move detailed tables, examples,
   and source notes into `references/` when they would bloat `SKILL.md`.
5. Preserve `name` and `description` frontmatter. For a new Multica-compatible
   skill, use:

   ```text
   Skills/<skill-name>/
   ├── SKILL.md
   ├── agents/openai.yaml
   └── references/       # only when needed
   ```

6. Do not mass-migrate unrelated legacy flat files under `Skills/` without an
   explicit request.
7. Validate every changed skill. Use `quick_validate.py` when the skill-creator
   tooling is available; otherwise verify YAML parsing, required frontmatter,
   relative links, and referenced files manually.
8. Create a focused branch and pull request. Include the evidence, scope,
   conflict decision, and validation result in the PR body. Do not push directly
   to `main` unless the user explicitly requests it.

If repository write access is missing, provide a ready-to-apply patch or create a
tracking issue. Never claim the knowledge is shared until it exists in the
authoritative repository.

## Synchronize into Multica

After the GitHub change is merged, update the workspace copy only when the user
authorized synchronization:

```bash
multica skill import \
  --url https://github.com/jmoskaliuk/eLeDia.OS_DevFlow/tree/main/Skills/<skill-name> \
  --on-conflict overwrite \
  --output json
```

Treat the structured response as the result. `overwrite` preserves the existing
skill ID and agent bindings when the caller is allowed to overwrite it.

Agent assignment is separate. Add without replacing existing assignments:

```bash
multica agent skills add <agent-id> --skill-ids <skill-id> --output json
multica agent skills list <agent-id> --output json
```

Do not use `agent skills set` for an additive assignment. Do not call a GitHub
edit or a Multica import an automatic two-way sync: GitHub remains authoritative,
and every workspace update must follow a reviewed repository change.

## Report

Report the candidate decision, changed files, evidence used, validation performed,
commit or PR link, and whether the merged version has been synchronized into
Multica. Clearly separate proposed, merged, and imported states.
