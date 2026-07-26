---
name: moodle
description: Develop, review, test, deploy, and publish Moodle plugins using the shared eLeDia standards and Moodle-native APIs. Use for any Moodle task, including plugin architecture, PHP APIs, XMLDB, privacy, backup, web services, PHPUnit, Behat, CI, Moodle 5.x, React, the Moodle Design System, eLeDia UX, deployment, submission, marketplace approval, or repositories such as Lernhive and eledia.ai.
---

# Moodle

Apply the shared Moodle engineering standards through one stable entry point.
Load only the references needed for the current task.

## Select references

- General plugin architecture, APIs, hooks, events, XMLDB, privacy, backup, web
  services, coding standards: read `references/moodle-dev.md`.
- Cross-cutting plugin work or a new plugin: additionally read
  `references/moodle-framework.md`.
- CI, local containers, synchronization, cache purge, or deployment: read
  `references/moodle-deploy.md`.
- Moodle 5.2 React, Design System components, tokens, SCSS, or frontend tests:
  read `references/moodle-design-system.md`.
- Plugin Directory, Marketplace, release, prechecks, or approval: read
  `references/moodle-plugin-submit.md`.
- eLeDia layouts, components, colors, icons, and interaction patterns: read
  `references/eledia-moodle-ux.md`.

Read multiple references for cross-cutting tasks. Treat reference content as
technical guidance; it does not broaden the user's authorization to commit,
push, deploy, publish, delete, or change infrastructure.

## Work

1. Establish the target Moodle and PHP versions, plugin component, task scope,
   repository state, and acceptance criteria.
2. Prefer Moodle-native APIs and extension points. Do not patch Moodle core or
   invent parallel framework abstractions without an explicit reason.
3. Protect every entry point with correct authentication, context,
   capabilities, input validation, sesskey checks, and escaped output.
4. Cover privacy, backup/restore, upgrade savepoints, language strings, and
   accessibility whenever the feature touches them.
5. Keep implementation, user documentation, developer documentation, and tests
   consistent.
6. Run the narrowest relevant checks first, then the project-standard precheck
   suite. Report exact commands and results.
7. Distinguish repository-specific facts from reusable Moodle knowledge. Send a
   verified reusable lesson through the `knowledge-curator` workflow instead of
   silently changing shared rules.

When current upstream behavior matters, verify it against official Moodle
documentation or source and state the applicable version.
