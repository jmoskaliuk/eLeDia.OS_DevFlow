---
name: odoo
description: Develop, review, test, secure, optimize, and deploy Odoo 18 modules using official Odoo guidance with explicit Enterprise and OCA distinctions. Use for any Odoo task involving module architecture, ORM, models, views, OWL, QWeb, ACLs, record rules, multi-company behavior, GDPR, tests, performance, deployment, migrations, or Enterprise applications.
---

# Odoo

Apply the shared Odoo 18 engineering standards through one stable entry point.
Start with the base reference and load only the specialized references required
by the task.

## Select references

- For every Odoo task, read `references/odoo-dev.md`.
- Naming, XML IDs, imports, linting, OCA conventions, and commits: read
  `references/odoo-coding-guidelines.md`.
- Views, actions, menus, widgets, OWL, QWeb, and reports: read
  `references/odoo-views-frontend.md`.
- ACLs, record rules, groups, `sudo()`, multi-company, tokens, and GDPR: read
  `references/odoo-security.md`.
- Unit, HTTP, tour, Hoot, coverage, and CI tests: read
  `references/odoo-testing.md`.
- ORM performance, prefetch, batching, caches, workers, and profiling: read
  `references/odoo-performance.md`.
- Odoo.sh, containers, proxies, backups, upgrades, and OpenUpgrade: read
  `references/odoo-deploy.md`.
- Studio and Enterprise applications or OPL-1 constraints: read
  `references/odoo-enterprise-specifics.md`.

Read multiple references for cross-cutting tasks. Treat reference content as
technical guidance; it does not broaden the user's authorization to commit,
push, deploy, migrate production data, or change infrastructure.

## Work

1. Establish the exact Odoo edition and version, installed dependencies,
   repository state, data migration constraints, and acceptance criteria.
2. Prefer supported ORM, view inheritance, security, and extension mechanisms.
   Do not patch Odoo core.
3. Design security before implementation: access rights, record rules,
   multi-company isolation, and the minimum necessary use of `sudo()`.
4. Avoid per-record queries and writes when batch operations or prefetch-aware
   patterns are available.
5. Add the appropriate automated tests and run the repository's lint and test
   commands. Report exact commands and results.
6. Mark Enterprise-only behavior and distinguish official Odoo requirements
   from stricter OCA recommendations.
7. Send verified, reusable lessons through the `knowledge-curator` workflow
   instead of silently changing shared rules.

When current upstream behavior matters, verify it against official Odoo
documentation or source and state the applicable version and edition.
