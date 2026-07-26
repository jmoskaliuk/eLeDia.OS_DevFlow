# Skills

Dieser Ordner bündelt die **agentenübergreifenden Skills** für eLeDia.OS. Jeder kanonische Skill ist ein eigenständiges Paket unter `Skills/<name>/` mit einer primären `SKILL.md`, UI-Metadaten unter `agents/` und optionalen Detailreferenzen unter `references/`.

## Sinn und Zweck

Die Skills sind die **wiederverwendbare Arbeitsanweisung** für Claude / ChatGPT beim Arbeiten an eLeDia-Plugins. Während eLeDia.OS (die `0x-*.md`-Files) beantwortet **„was wird gebaut und wo steht es?"**, beantworten die Skills **„wie wird es gebaut?"**.

Zusammenspiel:

- `00-master.md` … `05-quality.md` → projekt-spezifischer Zustand (Features, Tasks, Bugs, Docs)
- `Playbooks/*.md` → projekt-spezifische Deploy- und Release-Abläufe
- `Skills/<name>/SKILL.md` → **generische**, projektübergreifende Expertise; Details werden bei Bedarf aus `references/` geladen

## Inhalte

| Skill | Zweck | Einstieg |
|---|---|---|
| **Moodle** | Moodle-Plugin-Entwicklung, Tests, CI, Deployment, Submission, Design System und eLeDia UX. | [`moodle/SKILL.md`](./moodle/SKILL.md) |
| **Odoo** | Odoo-18-Entwicklung, Views, Security, Tests, Performance, Deployment und Enterprise-Themen. | [`odoo/SKILL.md`](./odoo/SKILL.md) |
| **Accessibility** | Audits und Remediation nach WCAG 2.2 AA mit EN 301 549-, BITV- und BFSG-Mapping. | [`accessibility/SKILL.md`](./accessibility/SKILL.md) |
| **Knowledge Curator** | Prüft neue, wiederverwendbare Erkenntnisse und pflegt GitHub als Quelle der Wahrheit. | [`knowledge-curator/SKILL.md`](./knowledge-curator/SKILL.md) |

Die kanonischen Skill-Namen sind bewusst kurz und einheitlich: `moodle`,
`odoo`, `accessibility` und `knowledge-curator`. Die bisherigen flachen
Dateien bleiben während der Migration vorübergehend als Quelle erhalten und
werden erst nach erfolgreichem Multica-Import entfernt.

## Nutzung

### Für Agents

1. Projektkontext aus den DevFlow- und Multica-Projektressourcen laden.
2. Bei Moodle-Themen `Skills/moodle/SKILL.md` verwenden; der Skill wählt die
   nötigen Referenzen.
3. Bei Odoo-Themen `Skills/odoo/SKILL.md` verwenden.
4. Für Barrierefreiheitsprüfungen `Skills/accessibility/SKILL.md` verwenden.
5. Verifiziertes, wiederverwendbares Wissen über
   `Skills/knowledge-curator/SKILL.md` als GitHub-Änderung vorschlagen.

### Für Menschen

Die Referenzen bleiben direkt lesbar und enthalten Code-Patterns,
Anti-Patterns, Entscheidungsbäume und Checklisten.

## Pflege

- Neue Skills immer als Paket `Skills/<name>/SKILL.md` anlegen; Details in `references/` auslagern. Kanonische Namen bestehen aus Kleinbuchstaben, Ziffern und Bindestrichen.

- Skills werden **nicht** mit dem Projektstand vermischt. Projektbezogene Besonderheiten (z. B. der konkrete Container-Name, die konkrete Quiz-Endpoint-URL) gehören in einen Playbook unter `Playbooks/`, nicht in den Skill.
- Ändert sich Moodle-Core (neue Hook-API, neue Context-Klasse, neue Precheck-Regel), **aktualisiere den Skill**, nicht das Playbook.
- Jeder Skill hat oben ein YAML-Frontmatter (`name`, `description`). Dieses ist für KI-Systeme, die Skills automatisch laden; bitte beim Editieren nicht entfernen.

## Stand

**2026-07-26** — Kanonische Multica-Pakete `moodle`, `odoo` und `accessibility` eingeführt. Bestehendes Fachwissen als Referenzen übernommen; flache Altdateien bleiben bis zur Import-Verifikation erhalten.

**2026-07-05** — **UX-Konsolidierung:** `eledia-moodle-ux.md` komplett neu geschrieben als Kondensat von `mockups/ux-system.md` (lernhive-Repo, Ratified v0.1.16 + neues § 12 Cross-Repo-Scope). Die LeitnerFlow-Palette (`--lf-*`, Grün `#669933`, Rot `#cc3333`) ist raus — kanonisch sind die `--lh-*`-Tokens (Success `#3aadaa`, Danger `#ab1d79`). Geltung explizit auf beide Repos ausgedehnt (lernhive `plugins/` + eledia.ai `custom-plugins/`), inkl. Fallback-Pattern `var(--lh-*, default)`, Verbot von Inline-CSS in Templates, `lh-chat`-Anatomie und der sanktionierten `--eat-*`-Ausnahme für `block_eledia_aitutor`. Kopien synchronisiert: lernhive `meta/eLeDia.OS_DevFlow/Skills/` + claude.ai-Upload-Staging (`_claude-skills-update/eledia-moodle-ux/SKILL.md` — Re-Upload nötig).

**2026-05-09** — Neue **Odoo-18-Enterprise**-Skill-Sammlung (8 Files):

- `odoo-dev.md` — Dachskill: Modul-Anatomie, `__manifest__.py`, ORM, Inheritance, Hooks
- `odoo-coding-guidelines.md` — Style-Guide nach offizieller Odoo-Doku + OCA-Strenger
- `odoo-views-frontend.md` — Views (inkl. Odoo-18-`<list>` statt `<tree>`), OWL 2, QWeb, Reports
- `odoo-security.md` — ACL, Record Rules, Multi-Company, GDPR/DSGVO
- `odoo-testing.md` — `TransactionCase`, `HttpCase`, Tours, Hoot (Odoo-18-neu), CI
- `odoo-performance.md` — Computed/Stored, `read_group`, Prefetch, `ormcache`, Batch
- `odoo-deploy.md` — odoo.sh, Docker, Reverse-Proxy, OpenUpgrade, Backup, Monitoring
- `odoo-enterprise-specifics.md` — Studio, Approvals, Documents, Sign, Subscriptions, IoT, VoIP, Knowledge

Basis: offizielle Odoo-18.0-Developer-Doku (https://www.odoo.com/documentation/18.0/), inkl. der vom User gewählten Coding-Guidelines-Seite. OCA-Abweichungen markiert (z.B. AGPL vs. OPL-1, strenge Pylint-Konfiguration, README.rst-Pflicht). Code-Beispiele decken die häufigsten realen Patterns ab (Modell mit Chatter, Multi-Company-Rule, Tour-Test, OWL-Widget, QWeb-Report, GitHub-Actions-CI, nginx-Reverse-Proxy, Migrations-Skript).

**2026-04-22** — Neuer Skill `moodle-design-system.md` für das offizielle MDS-npm-Paket:

- Basis: Snapshot von [github.com/moodlehq/design-system](https://github.com/moodlehq/design-system) v2.1.1 (2026-03-12) inkl. `.github/copilot-instructions.md` und den drei scoped Instructions-Files (components / stories-tests / tokens).
- Deckt die echte Package-API ab: Exports, Subpath-Imports, SCSS-Entrypoints (inkl. `scssphp`-Legacy-Bridge), vollständiger `--mds-*` Token-Katalog, Button-API (`label`-Prop statt children, Varianten `primary|secondary|danger|outline-*`, Sizes `sm|lg`), Double-Class-Specificity (`.mds-btn.btn.btn-<var>`), i18n/RTL-Contract, Testing mit Vitest + Storybook/Playwright, Release-Please-Workflow.
- **Korrekturen** in `eledia-moodle-ux.md` und `moodle-framework.md`: Token-Prefix `--ds-*` → `--mds-*`, Button-API (`variant="destructive"` → `"danger"` / `"outline-danger"`; `children` → `label`; `size="md"` entfernt — gibt es nicht), React-Version 18 → 19.2, DS-Pfad `theme/boost/scss/moodle/design-system/` → npm-Paket `@moodlehq/design-system`, Migrations-Tabelle auf echte Tokens aktualisiert.

**2026-04-21 (abends)** — Moodle-Marketplace-Update eingebaut:

- `moodle-plugin-submit.md` → neue Sektionen **„Marketplace vs Plugins Directory — two tracks (2026+)"**, **„Marketplace-spezifische Pflicht-Ergänzungen"**, **„Marketplace-Approval-Blockers (2026+ Liste)"**, **„Phase 2.5 — Marketplace-Provider-Setup"** und **„Phase 2.6 — Marketplace-Plugin-Page einrichten"**. Skill-Titel umbenannt in „Moodle Plugin Submission Playbook — Directory & Marketplace". Frontmatter-Description erweitert für Marketplace-Trigger (Provider, Paid-Plugin, Marketplace-Launch).

Basis: Moodle Marketplace Plugin Submission Guidelines vom 30.03.2026.

**2026-04-21** — Moodle-5.2-Update eingebaut:

- `moodle-framework.md` → neuer Abschnitt **„Moodle 5.2 — React & Design-System"** mit Import-Map-Specifiern, Mustache-`{{#react}}`-Helper, Grunt-Targets, Build-Pipeline und einer Checkliste für neue 5.2-Plugins.
- `eledia-moodle-ux.md` → neuer Abschnitt **„Moodle 5.2+ Design System"** mit SCSS-Token-Liste, `@moodlehq/design-system`-Komponenten, Migrations-Tabelle `--lf-*` → `--ds-*` und aktualisierter Button-Hierarchie.
- `moodle-dev.md` → Kurz-Notiz zu React/DS in 5.2 sowie erweitertes Anti-Pattern für Inline-Scripts.
- `moodle-plugin-submit.md` → neuer Unterabschnitt in Phase 1 zu Version-Requirements und `js/react/build/` im Release-ZIP.

Basis: Tickets MDL-87759, MDL-87765, MDL-87908, MDL-87922, MDL-87987, MDL-87730, MDL-87909 (alle gegen `MOODLE_502_STABLE` gemergt).

