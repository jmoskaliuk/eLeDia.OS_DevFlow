---
name: eledia-moodle-ux
description: "eLeDia / LernHive Moodle plugin UX & visual design system. Use this skill whenever building or modifying ANY Moodle plugin UI for eLeDia GmbH — in the lernhive repo (plugins/) AND the eledia.ai repo (custom-plugins/): view pages, report pages, dashboards, settings forms, CSS styling, chat UIs, progress visualizations, or icon usage. Also trigger on 'eLeDia style', 'LernHive style', 'consistent design', 'Plugin Shell', 'lh-tokens', color palette, or Moodle component usage questions. The single source of truth is mockups/ux-system.md in the lernhive repo — this skill is its condensed application layer. For deep Moodle Design System topics (`@moodlehq/design-system`, `--mds-*` tokens, React UI in Moodle 5.2+), defer to `moodle-design-system.md`."
---

# eLeDia / LernHive Moodle Plugin UX System

**Source of truth:** `mockups/ux-system.md` in the lernhive repo (Ratified v0.1.16+, § 12 cross-repo scope). This skill is the condensed, always-loaded application layer. On any conflict, ux-system.md wins. When working inside the lernhive repo, read the relevant § of ux-system.md before non-trivial UI work.

**Scope:** ALL eLeDia Moodle plugins — lernhive repo (`plugins/`) **and** eledia.ai repo (`custom-plugins/`). One design language, one token vocabulary: `--lh-*`.

## Design Philosophy

1. **Moodle-native first** — reuse Moodle Core + Bootstrap components; custom CSS only where Core provides nothing. A PR that hand-rolls a toast, confirm dialog, dropdown, tab, progress indicator, or course-card lookalike is blocked in review.
2. **Bootstrap-utilities first** — spacing/grid/flex via `.p-3`, `.mt-4`, `.d-flex`, `.row/.col-*`. Never invent custom spacing classes.
3. **Calm, clear, guided** — LernHive polishes Moodle, it does not replace it. One primary CTA per page. No card-in-card nesting. Shape carries meaning (angular = structure, round = action, pill = tag).
4. **Tokens, never hex** — all brand values are CSS custom properties. Hardcoded colors/radii/spacing in plugin code are defects.

## Canonical Tokens (`--lh-*`)

Source: `plugins/local_lernhive/scss/plugin-shell/_tokens.scss`. Bootstrap mapping: primary→`primary`, accent→`warning`, success→`success`, danger→`danger`.

| Token | Value | Role |
|---|---|---|
| `--lh-primary` | `#194866` | Brand primary, Zone-A name, structural navy |
| `--lh-primary-dark` | `#0f2b3d` | Primary hover/active |
| `--lh-primary-light` | `#f3f5f8` | Subtle surfaces, hover tints |
| `--lh-accent` | `#f98012` | **Single accent** — primary CTA, focus ring, active marker. Never a large background. |
| `--lh-accent-dark` | `#c25b00` | Accent hover |
| `--lh-accent-light` | `#ffecdb` | Warning/accent tint |
| `--lh-bg-white` / `--lh-bg` / `--lh-bg-soft` | `#ffffff` / `#f5f5f5` / `#f3f5f8` | Card / page / soft panel background |
| `--lh-text` / `--lh-text-secondary` (=`--lh-muted`) / `--lh-text-light` | `#1f2937` / `#5f6b77` / `#80868b` | Text tiers |
| `--lh-border` / `--lh-border-light` | `#dbe7ee` / `#f0f0f0` | Card+button border / inner divider |
| `--lh-success` / `--lh-success-light` | `#3aadaa` / `#d1eceb` | Completion, positive |
| `--lh-danger` / `--lh-danger-light` | `#ab1d79` / `#f5e4ef` | Destructive (eLeDia lila) |
| `--lh-warning` / `--lh-warning-light` | `#f98012` / `#ffecdb` | Alias of accent |

**Radii:** `--lh-radius-sm 8px` (inputs, chips) · `--lh-radius-btn 8px` (**all buttons — no pill buttons**) · `--lh-radius 12px` (cards, panels) · `--lh-radius-lg 16px` (large surfaces) · `--lh-radius-pill 9999px` (**tags only**, `.lh-plugin-tag`).

**Shadows:** `--lh-shadow 0 1px 3px rgba(60,64,67,.12)` · `--lh-shadow-card 0 2px 8px rgba(15,23,42,.05)` · `--lh-shadow-hover 0 4px 16px rgba(60,64,67,.18)`. Used sparingly — borders do the structural work.

**Spacing:** Bootstrap scale 0–6 via utility classes. Aliases only for structural components: `--lh-spacing-{xs 4, sm 8, md 16, lg 24, xl 32}px`.

**Typography:** Open Sans (system-stack fallback), base 16 px, Bootstrap type scale, weights 400/600/700 (700 only for emphasis in copy). No inline typography styles — `.fw-semibold`, `.fs-5`, `.text-muted`.

**Page width:** wrap every plugin page in `.lh-plugin-shell` (+ `--reading` for forms/wizards; `--wide`/`--full` are approved **only** for `local_lernhive_seminarmanagement`). Tokens: `--lh-page-max-{default,reading} 58rem`, `--wide 88rem`.

### Superseded palettes — do NOT use

- **`--lf-*` (LeitnerFlow) is superseded.** Migration is value-level, not just prefix: `--lf-green #669933` → `--lh-success #3aadaa`; `--lf-red #cc3333` → `--lh-danger #ab1d79`; `--lf-grey #6c757d` → `--lh-muted #5f6b77`; `--lf-border #dee2e6` → `--lh-border #dbe7ee`; `--lf-radius 6px` → `--lh-radius-sm 8px`; `--lf-orange/--lf-dark-blue` keep values, become `--lh-accent`/`--lh-primary`. Plugin-semantic stage colors (Leitner boxes) may stay plugin-scoped but must not redefine shared semantics.
- **`--eat-*` (`block_eledia_aitutor`) is the ONLY sanctioned exception** — standalone sellable product with deliberate brand divergence (navy `#1e3f59`, orange `#ed7b2d`). Keep it inside that block only; no other plugin adopts or clones it. Mapping table: ux-system.md § 12.2.

### eledia.ai adoption rules (ux-system.md § 12)

- eledia.ai plugins may run without `theme_lernhive`/`local_lernhive` → read every token with a fallback **equal to the canonical default**: `var(--lh-primary, #194866)`. A fallback is a copy of the default, never a private shade. Reference: `custom-plugins/local/lernhive_strategy/styles.css`.
- **No `<style>` blocks or static `style=""` in Mustache templates.** All styling in the plugin's `styles.css`, tokenised.
- No new per-plugin token systems. Plugin-scoped custom properties only for plugin-semantic values, derived from `--lh-*`.
- Chat UIs follow the `lh-chat` anatomy (ux-system.md § 12.4): `__toolbar` / `__messages` (aria-live=polite) / `__bubble--user|--ai` / `__status` / `__input` with icon-only send (`fa-paper-plane`). One shared implementation — do not fork chat templates per plugin.

## Plugin Shell (ux-system.md § 3)

Every full plugin page renders through three regions. Blocks and question types never carry the shell.

- **Zone A — Header (mandatory):** shared partial `local_lernhive/plugin_shell_header` + helper `local_lernhive\output\plugin_shell` (`action_slots()`, `content_open()`/`content_close()`). Slots left→right: `[back] [title-block: name | tagline, subtitle, tags] [actions: ctas, actionicons, help, settings]`. Never duplicate Zone-A markup into a plugin.
  - Help slot is mandatory (icon-only `fa-question` → `/local/lernhive/support.php?component=<frankenstyle>`).
  - Settings cog only when customer-changeable settings exist; target is the in-shell `/local/<plugin>/configuration.php` — linking `/admin/settings.php?section=…` is **forbidden**. Operator-only settings stay in the Moodle admin tree.
  - Shell pages call `$PAGE->set_heading('')` — Zone A already states identity.
  - Section nav (2–6 peer areas) is the bottom row of Zone A: underline-active style, `aria-current="page"`, never in Zone B.
- **Zone B — Infobar (optional):** state only — progress bar, stat row, or filter summary. Max one CTA. Never navigation. Omit when there is no at-a-glance state.
- **Content Area:** cards/tables/forms directly on page background. Grid `.lh-plugin-grid--cols-{1..4}` with `align-items: start`; card `.lh-plugin-card`; table card = `--cols-1` card with `padding: 0` around `<table class="generaltable">`; empty state `.lh-plugin-empty-state` (icon → h3 title → message → one CTA).

**Page patterns (§ 6):** Index (A: identity+action / B: optional stats / grid), Drilldown (A: back+parent context / KPI row + table card), Wizard (A: back + "Step N of M" / B: progress / moodleform), Form (A: back / moodleform only), Empty first-run (empty-state with one CTA), Audit log (`.lh-log-filter` toolbar + table card, § 6.7). Admin-tree pages (§ 6.6) do not use the shell.

## Components

**Mandatory Moodle Core reuse (§ 4):** `$OUTPUT->notification()` for inline feedback, `core/toast` for transient success, `core/notification` `Notification.confirm()` for destructive confirms, `core/modal`, `action_menu` (+ kebab), `core/task_indicator` for anything > a few seconds, `core/dynamic_tabs`, `core/collapsable_section`, `core/dropdown`, `core/toggle`, `core/search_input`, `core/sortable_list`, `core/inplaceeditable`, `coursecard` for anything listing courses, `moodleform` for every form. No bespoke equivalents — ever.

**Forms:** never expose Moodle's text-format selector for ordinary business fields (descriptions, notes, messages) — fixed format server-side (§ 4.3).

**LernHive-owned (§ 5, only where Core has no equivalent):** `.lh-plugin-card` (one primary action per card, icon directly next to title), `.lh-plugin-grid`, `.lh-plugin-tag` (metadata only — never clickable, never hover), `.lh-cta-strip` (max one per page), card action strip (spacer-first right alignment, max 2 labeled buttons, Info anchor rightmost), `.lh-eyebrow` (Mixed-Case source + `text-transform`, ≥ 12 px, 1–3 words), `.lh-plugin-filter-inline` (max 3 filters, more → modal), `.lh-table-card`, `local_lernhive/person_list` (Moodle avatar + profile-linked name, no email column by default), `.lh-plugin-empty-state`, Spotlight detail pattern (§ 5.11: progress chips + ONE focused next action, no per-row CTA lists).

**Key anti-patterns (all normative, § 5.10):**
- Card-in-card nesting.
- Pill-shaped actions (pill = read-only tag; actions are rectangular with verb-icon + hover state).
- Filled accent circle for status (that shape means "click here"; status uses inline glyph + text).
- Container-wide hover when the affordance is inside (hover lives on the action, not the card).
- Index-only labels ("Tour 1", "Step 2") as primary label — use the artifact's semantic name.
- Unscoped `.lh-plugin-*` overrides in plugin CSS — prefix with `body.path-<component-with-dashes>`; `local_lernhive` owns the contract.

## Icons (§ 7)

Four types with fixed shape+cursor semantics: `.lh-icon-nav` (36 px, 8 px radius), `.lh-icon-artifact` (38 px, 9 px radius, color-coded, no hover), `.lh-icon-action` (36 px **circle**, grows on hover), `.lh-icon-info` (28 px, `cursor: help`, tint-only hover).

- Dual mapping Lucide ↔ FontAwesome; plugins always render FA (`pix_icon` / `<i class="fa fa-…">`), `theme_lernhive` overlays Lucide via CSS.
- **PHP SSOT:** `local_lernhive\output\icon_kit::ICONS` — new verbs land in ux-system.md § 7.4 AND `icon_kit` in the same PR. No bespoke glyphs, no per-plugin mappings.
- **Action-render convention (§ 7.8, contract):** 1–2 obvious row actions → visible `.lh-icon-action` pair (typically Edit + Delete); ≥ 3 or rare actions → kebab `action_menu`. State/decision transitions (Approve, Reject, Publish, Mark paid …) → **always labeled button**, on the detail page, never icon-only. Page CTAs in Zone A → labeled with leading icon. Toolbar utilities (Search `fa-magnifying-glass`, Filter, Sort) → icon-only with `aria-label`. Search submit is a stable circular icon, never a text "Search" button.

## Accessibility (§ 9 — floor, not goal)

WCAG 2.2 AA. Per page: contrast ≥ 4.5:1; visible focus (accent ring) on everything interactive; full keyboard path; DOM order = reading order; no color-only meaning; semantic HTML (`<button>` vs `<a>`, real `<table>` with `<th scope>`); labeled inputs; `aria-label` on every icon-only control; `role="progressbar"` + values on progress; `aria-live` for dynamic updates; touch targets ≥ 44×44; reflow at 320 px / 200 % zoom; decorative icons `aria-hidden="true"`.

## Strings (§ 8)

English first, Moodle-core strings where they fit, one term per concept. Canonical product terms (never translated): `Audience`, `Follow`, `Bookmark`, `Launcher`, `ContentHub`, `Community`, `Snack`, `Explore`, `Grow`, `Onboarding`, `Level`. Verbs on buttons (no "OK/Yes"), no exclamation marks, no emoji in UI copy. String changes update `product/05-string-inventory.md` in the same PR.

## Moodle 5.2+ / MDS

For plugins targeting Moodle 5.2+ with React surfaces, prefer `@moodlehq/design-system` (`--mds-*` tokens, `<Button label=… variant=…>`) — full reference in `Skills/moodle-design-system.md`, which wins on any MDS conflict. The `--lh-*` layer remains canonical for 4.5–5.1 support and for eLeDia brand semantics; hybrid pattern: derive `--lh-*` surfaces from `--mds-*` where available, keep brand + plugin-semantic colors as `--lh-*`.

## Ship checklist (every UI PR)

1. Tokens only — zero new hardcoded hex/radius/spacing (`grep -nE '#[0-9a-fA-F]{3,6}' styles.css` on touched files).
2. Plugin Shell partial/helper used; `$PAGE->set_heading('')`; Help slot present; Settings rule honoured.
3. Core components reused (toast/confirm/modal/task_indicator/action_menu/moodleform) — nothing hand-rolled.
4. Icons from § 7.4 via `icon_kit`; action-render convention § 7.8 respected.
5. No inline `<style>` in templates; plugin CSS scoped (`body.path-…` for any `.lh-plugin-*` deviation).
6. A11y pass: keyboard walk, focus visible, `aria-label` on icon-only, empty states present.
7. Strings: core-string reuse checked, inventory updated.
