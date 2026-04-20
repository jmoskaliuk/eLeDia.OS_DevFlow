# Tasks

## Meta

This is the operational center of the system.

It contains:
- new observations
- tasks (`taskXX`)
- clarifications
- active work
- verification steps

Start every working session here.

---

## New

### Platform
- define Directus Flow automation for projection upsert and retirement
- implement first Directus migration/script set for catalog collections using checklist v1
- harden portal auth model beyond service-token bootstrap (optional post-R1)

### Catalog — expert review dimensions (extend `plugin_review_dimension` catalog)
Roll out one new dimension per release; each feeds into the Proven rollup only after ≥30 % of catalog entries have been scored, to keep the signal clean.
- `privacy_gdpr` — stored/transferred data, AVV needed, EU-only hosting
- `code_quality` — readability, structure, test coverage
- `security` — input validation, escaping, SQL-injection safety, XSS
- `performance` — DB queries per page, caching, behaviour under load
- `functional_value` — does it solve a real problem, how do alternatives compare
- `ux_quality` — usability, mobile, accessibility (WCAG)
- `maintainability` — complexity, dependencies, upgrade path
- `documentation_quality`
- `support_quality` — issue reaction time
- `update_stability` — breaking-change history, migration cleanliness

### Catalog — social proof and adoption
- `installation_count_bucket` from moodle.org (`<100`, `100-1k`, `1k-10k`, `>10k`)
- `rating_average`, `rating_count` from moodle.org
- `internal_install_count` — how many of our managed Moodles run this plugin (from SSOT + managed-installation data)
- `reference_customers[]` — optional public references

### Catalog — security / compliance detail (beyond GDPR ampel)
- `cve_history[]` — reported CVEs with dates and severity
- `last_security_review_date`
- `schulsicher_rating` — explicit rating for the school market (large DE segment)

### Catalog — integration awareness
- known conflicts with other plugins (free-text + structured cross-references)
- theme compatibility matrix
- Moodle Mobile app support
- LTI / SCORM / xAPI awareness

### Catalog — accessibility and i18n specifics
- WCAG level (A / AA / AAA) from expert review
- screen-reader tested (yes/no, date)
- supported languages (list)
- translation completeness per language (percent)

### Portal — site info deferred in Release 1.1
- dataroot on-disk usage — needs CLI helper or custom `du` job, not safe from the web tier
- backup history panel — parse `backup_controller` outputs or site-level backup logs
- certificate expiry — outbound HTTPS probe for the site's own cert
- adhoc task queue depth + age of oldest unprocessed task as a dedicated card
- concurrent session / peak user metrics beyond simple "online now"

### Portal — UX ideas
- plugin-detail deprecation banner with structured link to replacement entry (consumer side of `is_deprecated` / `replacement_entry_id`)
- "installed across your fleet" mini-chart when multi-installation context lands (post-R1)
- request-form prefill for storage/consulting with installation facts pre-filled

### Catalog — plugin data importer (concept only, scheduled post-R1.2)
Full concept: `docs/03-dev-doc.md → "Plugin Data Importer"`
- phased rollout: (1) moodle.org-only manual refresh, (2) GitHub/GitLab + file-scan enrichment with per-field override locks, (3) nightly drift detection, (4) webhook-driven updates on repo releases
- new collection `plugin_source_snapshot` keeps raw + parsed payloads separate from canonical `plugin_component`
- deployed as a separate Directus extension `plugin-importer`, same pattern as existing `v1` and `catalog-projection-hook`
- depends on task25 scope being locked so mapping targets are stable

---

## Clarification Needed

### clar01 Initial frontend stack for the public catalog
Decision (2026-04-18): Next.js App Router is the primary implementation stack for the public catalog website.
Rationale:
- aligns with the Release 1 website proposal recommendation
- strong SSR and metadata support for detail routes
- straightforward route scaffold for `/`, `/catalog`, `/catalog/[slug]`, `/proven`

### clar02 Portal auth and API strategy
Decision (2026-04-18): Moodle calls Directus directly server-side with a service token (Bearer auth).
No additional external API facade is introduced in Release 1. The `api_client` class encapsulates all HTTP calls.
This is consistent with the handover contract scope boundary: portal-private endpoints are server-side only.

### clar03 Live endpoint mismatch (2026-04-18)
Observation:
- `local_customerportal` expects `/v1/catalog/*` and `/v1/portal/*` endpoints.
- Initial live state exposed raw catalog reads via `/items/catalog_entry_public`, while `/v1/*` returned `404`.

Resolved implementation (2026-04-18):
- Keep "no external facade" for Release 1.
- Contract endpoints are implemented as Directus endpoint extension package `directus/extensions/v1`.
- Live smoke test `directus/scripts/v1_contract_smoke_test.sh` is green on `directus.eledia.ai`.

---

## Tasks

### task01 Define Directus catalog schema
Status: done  
Feature: feat01

### task02 Define public catalog projection
Status: done  
Feature: feat02

### task03 Define shared API contract
Status: done  
Feature: feat02, feat03, feat04

### task04 Draft public catalog website information architecture
Status: done  
Feature: feat02

### task05 Define Moodle portal information architecture
Status: done  
Feature: feat03
Artifact: docs/03-dev-doc.md → "Portal Blueprint — Information Architecture"

### task06 Define portal overlay logic for catalog entries
Status: done  
Feature: feat04
Artifact: docs/03-dev-doc.md → "Portal Blueprint — Overlay Logic"

### task07 Define request model and lifecycle
Status: done  
Feature: feat05
Artifact: docs/03-dev-doc.md → "Portal Blueprint — Request Model"

### task08 Define Proven data model for Release 1
Status: done  
Feature: feat06

### task09 Implement Directus Flow for projection lifecycle
Status: done  
Feature: feat01, feat02
Scope:
- implement projection lifecycle automation for source mutations on `plugin_component`, `plugin_release`, `product`, `product_component`, `plugin_review`
- cover F1/F2/F3 behavior from checklist (`upsert`, `retire`, `published_at` timestamp)
- keep implementation version-controlled and deployable without UI-only flow editing
Result:
- implemented as Directus hook extension `directus/extensions/catalog-projection-hook/`
- deploy helper added: `directus/scripts/deploy_catalog_projection_hook.sh`
- projection upsert uses `source_type + source_id` and derives `proven_*` / `supported_*` fields from canonical records
- optional columns (`projection_version`, `projection_updated_at`, `retired_at`) are used when present but not required
Verification:
- deployed on `directus-vps` with `./directus/scripts/deploy_catalog_projection_hook.sh directus-vps`
- Directus container confirms loaded extensions: `catalog-projection-hook`, `v1`

### task10 Implement API facade or Directus endpoint policy
Status: done  
Feature: feat02, feat03
Result:
- Decision finalized: no external facade in Release 1.
- Contract served directly inside Directus through endpoint extension package `v1`.

### task11 Implement Directus endpoint extension for contract paths
Status: done  
Feature: feat02, feat03, feat04, feat05
Scope:
- provide `/v1/catalog/search` and `/v1/catalog/{slug}`
- provide `/v1/portal/installation/{id}`, `/v1/portal/installation/{id}/plugins`, `/v1/portal/overlay`, `/v1/portal/requests`
- keep deployment inside Directus stack (no separate external facade)
Verification:
- deployed with `directus/scripts/deploy_v1_endpoint_extension.sh`
- verified with `directus/scripts/v1_contract_smoke_test.sh` on 2026-04-18

### task12 Lock frontend stack and bootstrap public catalog app
Status: done  
Feature: feat02
Scope:
- resolve `clar01` by selecting Next.js App Router or Astro SSR as primary stack
- document final decision in `docs/03-dev-doc.md`
- create initial app scaffold with routes `/`, `/catalog`, `/catalog/[slug]`, `/proven`
Artifacts:
- `website/public-catalog/`
- `website/public-catalog/src/app/page.tsx`
- `website/public-catalog/src/app/catalog/page.tsx`
- `website/public-catalog/src/app/catalog/[slug]/page.tsx`
- `website/public-catalog/src/app/proven/page.tsx`
- `website/public-catalog/src/lib/catalog-api.ts`

### task13 Implement catalog search/list page (`/catalog`)
Status: done  
Feature: feat02
Scope:
- consume `GET /v1/catalog/search` only
- implement search (`q`) and filters (`entry_type`, `plugin_type`, `proven_badge`)
- implement pagination with `page`
- render cards with locked search fields only
Artifacts:
- `website/public-catalog/src/app/catalog/page.tsx`
- `website/public-catalog/src/app/globals.css`
Verification:
- `npm run lint` (website/public-catalog) passed
- `npm run build` (website/public-catalog) passed

### task14 Implement catalog detail page (`/catalog/[slug]`)
Status: done  
Feature: feat02
Scope:
- consume `GET /v1/catalog/{slug}` only
- render hero/title, `description_public`, screenshots, docs link
- render Proven summary block and supported versions block
- implement not-found state for unknown slug
Artifacts:
- `website/public-catalog/src/app/catalog/[slug]/page.tsx`
- `website/public-catalog/src/app/globals.css`
Verification:
- `npm run lint` (website/public-catalog) passed
- `npm run build` (website/public-catalog) passed

### task15 Implement landing and Proven pages (`/`, `/proven`)
Status: done  
Feature: feat02
Scope:
- implement landing page with clear entry point to `/catalog`
- implement Proven explainer page with aggregate-only semantics
- ensure no internal review evidence is exposed
Artifacts:
- `website/public-catalog/src/app/page.tsx`
- `website/public-catalog/src/app/proven/page.tsx`
- `website/public-catalog/src/app/globals.css`
Verification:
- `npm run lint` (website/public-catalog) passed
- `npm run build` (website/public-catalog) passed

### task16 Implement SEO and metadata baseline for public website
Status: done (2026-04-18)
Feature: feat02
Scope:
- SSR for detail pages
- metadata generation from title, teaser/description, hero image
- OpenGraph and Twitter card tags
- canonical URLs per slug
Result:
- `website/public-catalog/src/lib/seo.ts` owns the SEO fallback chain documented in `docs/03-dev-doc.md → "Shared API Contract"` → "SEO metadata" (task24): `meta_title`→`title`, `meta_description`→truncated `description_public`, `og_image`→first screenshot, `tags`→keywords.
- `website/public-catalog/src/app/layout.tsx` defines `metadataBase` from `NEXT_PUBLIC_SITE_URL` (default `http://localhost:3000` for dev), default OG site name + locale (`de_DE`), and `summary_large_image` Twitter card.
- `website/public-catalog/src/app/catalog/[slug]/page.tsx` `generateMetadata` consumes `resolveDetailMetadata(detail)` and emits canonical, OG (title/description/url/type/images) and Twitter cards. 404 paths return `robots: { index: false, follow: false }`.
- `website/public-catalog/src/app/catalog/page.tsx` and `src/app/page.tsx` set canonical + OG for the listing and home routes.
- Verified rendered HTML: `<title>`, `<meta name="description">`, `<link rel="canonical">`, OG/Twitter all present and absolute under `NEXT_PUBLIC_SITE_URL=https://catalog.eledia.ai`. `npm run build` and `npm run lint` green.
- `website/public-catalog/README.md` documents the new env var and the SEO baseline.
Note (task24 cross-link):
- The SEO fallback chain works today: live Directus does not yet expose `meta_title`/`meta_description`/`og_image`/`tags` columns, so the website transparently falls back to `description_public` + first screenshot. Once task24's live schema migration runs, populated SEO content will surface automatically without any further website change.

### task17 Implement accessibility baseline (WCAG AA)
Status: done (2026-04-18)
Feature: feat02
Scope:
- keyboard-accessible filters and pagination
- visible focus states and contrast checks
- require/validate alt text for hero and screenshot images
Result:
- global Skip-Link (`Zum Inhalt springen`) and focusable `<main id="main-content">` added in `layout.tsx`.
- `/catalog` filter controls use semantic `fieldset/legend`, explicit labels/ids, and ARIA status announcements for result count.
- pagination now exposes explicit disabled states with `aria-disabled` instead of empty placeholders.
- image alt handling hardened: hero and screenshot alt text is normalized via shared helper (`normalizeMediaAlt`) so empty values never render as empty `alt`.
- detail capability cards switched to proper heading hierarchy (`h3` under section heading).
Artifacts:
- `website/public-catalog/src/app/layout.tsx`
- `website/public-catalog/src/app/catalog/page.tsx`
- `website/public-catalog/src/app/catalog/[slug]/page.tsx`
- `website/public-catalog/src/app/globals.css`
- `website/public-catalog/src/lib/catalog-api.ts`
Verification:
- `npm run lint` (website/public-catalog) passed
- `npm run build` (website/public-catalog) passed
- `npm run smoke` (website/public-catalog) passed

### task18 Implement caching, resiliency, and runtime error handling
Status: done (2026-04-18)
Feature: feat02
Scope:
- apply route/data caching strategy aligned with shared contract guidance
- implement graceful handling for API timeout/5xx/empty states
- ensure website never falls back to canonical Directus collections
Result:
- `catalog-api.ts` refactored to a guarded fetch layer with:
  - request timeout (`CATALOG_API_TIMEOUT_MS`, default 6000ms)
  - structured error class (`CatalogApiError`: timeout/network/http/invalid_response)
  - response-shape normalization/validation before pages render.
- caching remains contract-aligned through explicit route revalidation (`search=60s`, `detail=120s`) and only `/v1/catalog/*` is used.
- `/catalog` and `/catalog/[slug]` now render graceful error panels for timeout/5xx/network errors instead of crashing.
- `generateMetadata` on detail route now fails soft (fallback metadata) when API errors occur, avoiding hard runtime failure in head generation.
Artifacts:
- `website/public-catalog/src/lib/catalog-api.ts`
- `website/public-catalog/src/app/catalog/page.tsx`
- `website/public-catalog/src/app/catalog/[slug]/page.tsx`
- `website/public-catalog/src/app/globals.css`
Verification:
- `npm run lint` (website/public-catalog) passed
- `npm run build` (website/public-catalog) passed
- `npm run smoke` (website/public-catalog) passed

### task19 End-to-end verification and release readiness for public website
Status: done (2026-04-18)
Feature: feat02
Scope:
- verify Release 1 acceptance checks from `docs/03-dev-doc.md → "Public Website Foundation"`
- verify only published entries are shown via shared contract
- verify no customer-specific portal data appears on website
- document test evidence in `docs/05-quality.md`
Verification evidence:
- Local end-to-end route smoke: `website/public-catalog/scripts/smoke.sh`
  - `/` -> 200
  - `/catalog` -> 200
  - `/catalog/attendance-plus-pro` -> 200
  - `/proven` -> 200
  - `/catalog/does-not-exist-smoke` -> 404
- Contract-surface checks against live `directus.eledia.ai`:
  - `/v1/catalog/search` contains only public catalog keys (no installation/overlay fields)
  - `/v1/catalog/{slug}` contains only public detail keys (no installation/overlay fields)
  - `/items/catalog_entry_public?fields=slug` and `/v1/catalog/search` return the same published slug set (`attendance-plus`, `attendance-plus-pro`, `classroom-insights-suite`)
- Build-quality gates:
  - `npm run lint` passed
  - `npm run build` passed
### task20 Implement local_customerportal baseline
Status: done
Feature: feat03, feat04, feat05
Scope:
- scaffold plugin with services (`api_client`, `catalog_service`, `installation_service`, `request_service`, `site_info_service`)
- implement pages: Dashboard, Meine Installation, Meine Plugins, Katalog, Plugin-Detail, Anfragen
- consume shared contract `/v1/catalog/*` and portal-private `/v1/portal/*`
- graceful 404 handling while Directus endpoints are being rolled out
- navigation integration via `\core\hook\navigation\primary_extend`
- local request table + scheduled sync task to Directus
Result: plugin version `2026041801`, maturity ALPHA, release `0.1.0`.

### task21 Apply LernHive design system to portal
Status: done
Feature: feat03
Scope:
- plugin stylesheet `styles.css` with design tokens scoped to `.path-local-customerportal`
- Zone A navigation bar, Zone B info bar
- cp-* component set (card, kpi-card, tag, table, stats-card, btn, empty, status, alert, form-wrap)
- all six Mustache templates rewritten to use design tokens
- FontAwesome icons from Moodle core
- unified page heading "Customer Portal" on all subpages

### task22 German language pack
Status: done
Feature: feat03
Scope:
- `lang/de/local_customerportal.php` for all plugin-specific strings
- strings duplicated in Moodle core replaced with core references (`search`, `never`, `cancel`, `courses`, `profile`, `version`, `date`)
- unused `request_cancel` removed (auto-supplied by `add_action_buttons()`)

### task23 Portal Release 1.1 — system info & health
Status: done
Feature: feat03
Scope:
- extend `site_info_service` with storage stats (dedup-unique `{files}` size + Postgres/MySQL DB size), environment info (PHP version, memory limit, upload max, maintenance flag), and users-online count (5-minute window)
- new `health_service` wrapping `\core\check\manager::get_checks()` for status/security/performance checks; aggregates totals, worst overall status, issues list
- new caches `healthoverview` (TTL 300s) and `storagestats` (TTL 600s)
- dashboard shows health ampel and storage KPI tiles; "My Installation" page gains Storage and Environment sections plus "Online now" stat
- English and German lang strings added
- 9 new PHPUnit tests (4 site_info extensions + 5 health_service)
Result: plugin bumped to `2026041802`, release `0.2.0`; codechecker 0/0, PHPUnit 24/24 green.

### task24 SSOT schema extension — SEO metadata + screenshot alt policy
Status: open (code complete 2026-04-18, awaiting live schema migration + smoke run + task16 website wiring)
Feature: feat02
Owner: Agent A
Scope:
- extend `catalog_entry_public` projection with optional SEO fields: `meta_title`, `meta_description`, `og_image` (on detail) and `meta_description` (on search result)
- extend the projection with optional `tags` (string array) on search result (already listed as extension candidate)
- enforce non-empty `alt` on `screenshots[]` at SSOT write-time (Directus validation rule)
- all new fields are nullable on the wire; consumers apply the fallbacks defined in `docs/03-dev-doc.md → "Shared API Contract"`
- extend `v1` endpoint extension (`directus/extensions/v1`) to return the new fields when populated
- extend seed data with SEO fields for at least one entry so smoke tests can observe the non-null path
Artefakte:
- `docs/03-dev-doc.md → "Shared API Contract"` SEO section (already added)
- Directus schema migration + `catalog-projection-hook` update
- updated `v1_contract_smoke_test.sh` assertion that the keys are **present** (value may be null)
Definition of done:
- smoke test green with and without populated SEO fields
- public website (task16) can render `<title>`, `<meta name="description">`, and OG tags using the fallback chain
Progress 2026-04-18:
- `directus/extensions/v1/index.js` exposes SEO keys on search and detail; runtime column-detection means responses always include the keys (`null` until columns exist or content is filled), so the smoke test stays green pre- and post-migration.
- `directus/extensions/catalog-projection-hook/index.js` preserves SEO fields across projection rebuilds and adds a filter hook that rejects `catalog_entry_public` writes with empty `screenshots[].alt`.
- `directus/scripts/v1_contract_smoke_test.sh` switched from strict-equality to key-presence assertion; new SEO keys are required to be present on both endpoints.
- `docs/seeds/catalog_seed_v1.json` `attendance-plus-pro` entry seeded with SEO fields and a screenshot with non-empty `alt` (smoke test default slug).
- `docs/03-dev-doc.md → "Catalog and SSOT Domain"` and `docs/03-dev-doc.md → "Directus Setup Checklist"` updated with the new fields, validation rule, and Flow F4.
Open follow-ups:
- Apply live schema: `./directus/scripts/apply_seo_fields.sh directus-vps` — adds the four SEO columns + Studio field metadata and restarts Directus.
- Deploy the updated `v1` and `catalog-projection-hook` extensions; run `v1_contract_smoke_test.sh` against `directus.eledia.ai`.
- Website wiring (task16) is done as of 2026-04-18: fallback chain is live and will surface populated SEO content automatically once the columns ship.

### task25 SSOT schema extension — plugin classification (Release 1.2)
Status: open (code complete 2026-04-18, awaiting live schema migration + smoke run)
Feature: feat01, feat02
Owner: Agent A
Depends on: task09 (projection hook), task11 (v1 endpoint extension)
Scope:
Four thematic blocks, all optional on the wire, rolled out behind the same fallback pattern as task24 so reviewers can fill data gradually without blocking public render.

1. **Lifecycle-Trio** (auto-fetchable from moodle.org / GitHub)
   - `last_release_version`, `last_release_date`
   - `release_cadence_days` (derived from release history)
   - `maintenance_badge` enum: `actively_maintained`, `looking_for_maintainer`, `orphaned`, `unknown`
   - `is_deprecated` bool + nullable `replacement_entry_id`

2. **Pricing-Baseline**
   - `pricing_model` enum: `free`, `freemium`, `paid_onetime`, `paid_subscription`, `paid_support_only`
   - `is_open_source` bool
   - `price_range_eur` enum bucket: `<100`, `100-500`, `500-2000`, `>2000`, `poa`
   - `license_unit` enum: `per_site`, `per_user`, `per_installation`, `enterprise`
   - `trial_available` bool
   - `is_eledia_product` bool (internal flag, public projection OK)
   - `vendor_id` FK → `plugin_maintainer` (see block 4)

3. **GDPR-Ampel**
   - `stores_personal_data` enum: `none`, `pseudonymised`, `identifying`
   - `privacy_api_implemented` bool (auto-derivable from code scan)
   - `data_transfer_outside_eu` bool
   - `gdpr_readiness` enum: `green`, `amber`, `red`, `unknown`

4. **Maintainer-Collection** (new collection `plugin_maintainer`)
   - fields: `type` (`individual`/`organisation`/`moodle_partner`/`eledia`), `name`, `org_name`, `homepage`, `is_moodle_certified_partner`, `plugin_portfolio_count`, `active_since_year`
   - new join table or array FK: `catalog_entry.primary_maintainer_id`, `catalog_entry.co_maintainer_ids[]`
   - public projection exposes only `maintainer_name`, `maintainer_type`, `is_moodle_certified_partner` (no contact details)

Contract additions (to be documented in `docs/03-dev-doc.md → "Shared API Contract"` as optional extensions):
- Search: `pricing_model`, `maintenance_badge`, `last_release_date`, `is_open_source`, `gdpr_readiness`, `is_eledia_product`
- Detail: all search fields plus `maintainer` (object: name, type, is_moodle_certified_partner), `price_range_eur`, `license_unit`, `stores_personal_data`, `data_transfer_outside_eu`, `privacy_api_implemented`, `is_deprecated`, `replacement_entry_id`, `release_cadence_days`

Note: qualitative expert-review fields (privacy_gdpr, code_quality, security, performance, functional_value, ux_quality, maintainability, documentation_quality, support_quality, update_stability) are **not** part of this task — they live in the existing `plugin_review_dimension` collection and only the dimensions catalog needs to grow. Each dimension is added to the Proven rollup one release at a time so "unbewertet" does not become the public default.

Artefakte:
- Directus schema migration for all four blocks + the `plugin_maintainer` collection
- `catalog-projection-hook` extension updated to derive the new public fields
- `v1` endpoint extension passes the new fields through when populated
- `docs/03-dev-doc.md → "Shared API Contract"` gets a new optional-extensions section "Plugin classification (Release 1.2)"
- seed data extended with at least one fully populated entry (free OSS plugin) and one commercial example (paid + eLeDia product + moodle certified partner)

Definition of done:
- smoke test `v1_contract_smoke_test.sh` asserts the new keys are present (values may be null) on a reviewed entry
- public projection exposes **no** internal vendor contact data
- fallback rendering works: consumer sees `null` → renders neutral placeholder, no crash

Progress 2026-04-18:
- `directus/extensions/catalog-projection-hook/index.js` — `CURATED_PROJECTION_COLUMNS` extended with all 17 classification columns (lifecycle, pricing, GDPR, maintainer JSON). Preservation across rebuilds matches the task24/27 pattern.
- `directus/extensions/v1/index.js` — new `CLASSIFICATION_SEARCH_FIELDS` and `CLASSIFICATION_DETAIL_ONLY_FIELDS` constants merged into `OPTIONAL_*` lists; runtime column-detection (`getOptionalColumns`) automatically extends the SELECT and ensures keys are always present (value `null` until column ships).
- `directus/scripts/v1_contract_smoke_test.sh` — `search_required` and `detail_required` now include all classification keys per the contract spec; presence-asserted (values may be null).
- `docs/seeds/catalog_seed_v1.json` — `attendance-plus` projection fully populated as the **free OSS** example (`free`, `is_open_source`, `gdpr_readiness=green`, maintainer "Moodle HQ"); `attendance-plus-pro` populated as the **commercial example** (`paid_subscription`, `100-500`, `is_eledia_product=true`, maintainer "eLeDia GmbH" with `is_moodle_certified_partner=true`).
- `docs/03-dev-doc.md` — canonical `plugin_component`/`product` tables list classification fields; new `plugin_maintainer` canonical collection documented (with internal-only `contact_email`/`contact_phone`/`homepage`); projection table extended; new "Plugin Classification" section in Shared API Contract with rendering rules and the public-projection guarantee that vendor contact data must never appear; handover Release 1.2 Additions updated; "Optional Field Extensions" generalised.

Open follow-ups:
- Add classification columns to live `catalog_entry_public`, `plugin_component`, `product`; create `plugin_maintainer` collection (Studio or schema snapshot diff).
- Reconcile placeholder seed values ("Moodle HQ", "eLeDia GmbH") against actual `plugin_maintainer` records once they exist.
- Redeploy `v1` + `catalog-projection-hook`; run `v1_contract_smoke_test.sh` against `directus.eledia.ai`.
- Move lifecycle (`last_release_*`, `release_cadence_days`) and `maintainer` out of `CURATED_PROJECTION_COLUMNS` once derivation from canonical FK + release history is wired (separate follow-up).
- Unblocks task26 (portal rendering, Agent B).

### task26 Portal — render + filter plugin classification fields (Release 1.2)
Status: open (blocked by task25)
Feature: feat03
Owner: Agent B
Depends on: task25
Scope:
- extend `catalog_service` and portal `catalog_list` / `catalog_detail` templates to render the classification fields from task25
- add filter UI in the portal catalog for: `pricing_model`, `maintenance_badge`, `is_open_source`, `gdpr_readiness`, `is_eledia_product`
- add classification badges to card footer (pricing tag, GDPR ampel, deprecated warning, maintainer badge if certified)
- render deprecation banner on plugin detail when `is_deprecated = true` (with link to `replacement_entry_id` if set)
- show maintainer block on plugin detail (name, type, certified-partner badge)
- lang strings EN + DE for all new labels
- PHPUnit tests for filter pass-through in `catalog_service`

Definition of done:
- five new filters functional in portal catalog
- classification badges visible on card + detail without populated fields degrading to empty (graceful fallback)
- codechecker 0/0, PHPUnit green

---

## Runbot Integration Tasks (Release 1.3)

---

### task27 Catalog SSOT — add `runbot_demo_id` field
Status: done (2026-04-18; live schema migration + deploy + smoke complete)
Feature: feat07
Owner: Agent A (Claude)
Scope:
- add nullable string field `runbot_demo_id` to `catalog_entry_public` (and to canonical `plugin_component` and `product` as editorial source)
- extend `catalog-projection-hook` to preserve `runbot_demo_id` across projection rebuilds (same pattern as SEO fields)
- extend `v1` endpoint extension: expose `runbot_demo_id` on search result and detail response when non-null (runtime column-detection, always present as key, value may be null)
- update `v1_contract_smoke_test.sh`: assert key presence on detail response
- seed the `attendance-plus-pro` and `exam2pdf` entries with their Runbot demo IDs (`exam2pdf` is confirmed live on `demo.eledia.ai`)
- update `docs/03-dev-doc.md → "Shared API Contract"`: add `runbot_demo_id` as optional extension field on detail

Definition of done:
- smoke test green
- field present in live Directus Studio
- seed entries carry correct IDs

Progress 2026-04-18:
- `directus/extensions/catalog-projection-hook/index.js` generalises the SEO preservation list into `CURATED_PROJECTION_COLUMNS` and adds `runbot_demo_id`. Projection rebuilds preserve curated values across the board.
- `directus/extensions/v1/index.js` renames `getSeoColumns` → `getOptionalColumns`; `runbot_demo_id` is now exposed on both `/v1/catalog/search` and `/v1/catalog/{slug}` with always-present keys (value `null` when column or content missing).
- `directus/scripts/v1_contract_smoke_test.sh` now requires `runbot_demo_id` presence on both search and detail responses.
- `docs/seeds/catalog_seed_v1.json` adds a complete `exam2pdf` set (canonical + release + projection) with `runbot_demo_id="exam2pdf"`, and seeds `attendance-plus-pro` projection with `runbot_demo_id="attendance-plus-pro"` (placeholder slug-as-id; reconcile with Runbot `configs.json` keys).
- `docs/03-dev-doc.md` updated: canonical `plugin_component` + `product` tables include `runbot_demo_id`; new "Runbot Demo Link" section under Shared API Contract; handover contract Release 1.3 Additions; "Optional Field Extensions" generalised to cover both task24 and task27.

Open follow-ups:
- Reconcile placeholder seed values against the live Runbot `configs.json`.
- task27 live rollout completed (2026-04-18):
  - added `runbot_demo_id` columns to live `plugin_component`, `product`, `catalog_entry_public`
  - seeded live examples: `attendance-plus` and `attendance-plus-pro`
  - redeployed `v1` extension on `directus-vps`
  - re-ran `directus/scripts/v1_contract_smoke_test.sh` against `directus.eledia.ai` (green)
- task28 (website CTA) and task29 (portal CTA) are unblocked.

---

### task28 Public website — "Demo starten" CTA
Status: done (2026-04-18; CTA visibility against live data pending task27 deploy)
Feature: feat07
Owner: Agent A (Claude)
Depends on: task27
Scope:
- extend `catalog-api.ts` to pass `runbot_demo_id` through to the page
- on `/catalog/[slug]` detail page: render a "Demo starten" button when `runbot_demo_id` is non-null
  - href: `https://demo.eledia.ai?demo={runbot_demo_id}`, target `_blank`, rel `noopener`
  - button uses accent color, secondary CTA hierarchy (primary CTA remains "Docs")
  - when null: no button rendered (no placeholder)
- WCAG: button has visible focus state, aria-label includes plugin title
- `npm run build` + `npm run lint` must pass

Definition of done:
- CTA visible on at least one live catalog entry post-task27 migration
- not rendered when field is null

Result:
- `website/public-catalog/src/lib/catalog-api.ts`: `CatalogSearchItem` and `CatalogDetail` types now expose `runbot_demo_id?: string | null`; both normalizers (`normalizeSearchItem`, `normalizeDetailResponse`) trim the value and coerce empty strings to `null` so the CTA conditional is robust against whitespace.
- `website/public-catalog/src/app/catalog/[slug]/page.tsx`: hero actions now render a "Demo starten" link between the Docs CTA and the back-to-list button only when `runbot_demo_id` is truthy. URL: `https://demo.eledia.ai?demo=${encodeURIComponent(detail.runbot_demo_id)}`. `target="_blank"`, `rel="noopener"`, `aria-label="Demo für {title} in neuem Tab starten"`.
- `website/public-catalog/src/app/globals.css`: new `.button-accent` variant (accent-coloured outline on neutral background) so the Demo CTA reads as accent-coloured but visually below the dominant primary CTA. Uses the existing global `:focus-visible` outline (WCAG-compliant).
- Verified: `npm run lint` + `npm run build` (with `NEXT_PUBLIC_SITE_URL=https://catalog.eledia.ai`) green. Live API (pre-task27) does not yet return `runbot_demo_id`, so the CTA correctly does not render — graceful fallback works. Positive path validated by asserting the normalizer + conditional with a sample payload (`runbot_demo_id="exam2pdf"` → CTA rendered; `null` → not rendered).
- The CTA will become visible automatically on `/catalog/attendance-plus-pro` and `/catalog/exam2pdf` once task27's live migration ships and the seed entries carry the values.

---

### task29 Portal — "Demo starten" CTA on plugin detail
Status: done (2026-04-18)
Feature: feat07
Owner: Agent B (Codex)
Depends on: task27
Scope:
- extend `catalog_service::get_detail()` to forward `runbot_demo_id` from the v1 API response
- extend `catalog_detail.mustache`: render a "Demo starten" link-button when `runbot_demo_id` is set
  - uses Moodle button classes (`btn btn-primary`)
  - URL: `https://demo.eledia.ai?demo={{runbot_demo_id}}`, opens in new tab
  - rendered below the overlay block, only when non-null
- add German lang string `demo_start` = "Demo starten"
- PHPUnit: assert `catalog_service::get_detail()` forwards `runbot_demo_id` (mock API)
- codechecker 0/0

Definition of done:
- CTA renders on plugin detail when field is set
- graceful absence when null
- codechecker 0/0, PHPUnit green

Result 2026-04-18:
- task27 prerequisite confirmed live (`runbot_demo_id` available on `/v1/catalog/*` for seeded entries).
- task29 implemented and deployed in active `local_customerportal` checkout:
  - `classes/local/catalog_service.php`:
    - normalizes/forwards `runbot_demo_id` (`null` fallback)
    - fixes cache key for hyphenated slugs (`detail_` + `md5($slug)`) to satisfy simple cache keys
    - supports optional `api_client` injection for unit tests
  - `templates/catalog_detail.mustache`:
    - renders "Demo starten" CTA below overlay when `entry.runbot_demo_id` is present
    - URL `https://demo.eledia.ai?demo={{entry.runbot_demo_id}}`, `target="_blank"`, `rel="noopener noreferrer"`
    - class `btn btn-primary` (Moodle-native styling)
  - `lang/de/local_customerportal.php`: `demo_start = "Demo starten"`
  - `lang/en/local_customerportal.php`: `demo_start = "Start demo"` (fallback/consistency)
  - `tests/catalog_service_test.php`:
    - asserts forwarding + `null` fallback for `runbot_demo_id`
    - adds regression test for hyphenated slug cache-key handling
  - `classes/local/api_client.php`:
    - loads Moodle curl library via `require_once($CFG->libdir . '/filelib.php')` for reliable CLI/runtime HTTP calls
  - `version.php`: bumped to `2026041803` (`release 0.1.1`) to avoid downgrade on local deploy.
- Verification (local Moodle container `demo-webserver-1`):
  - deploy: `scripts/deploy-moodle-plugin.sh --type local --name customerportal --repo /tmp/local_customerportal`
  - codechecker: `php local/codechecker/run.php local/customerportal` → 0 violations
  - PHPUnit: `php public/admin/tool/phpunit/cli/util.php --run /var/www/site/moodle/public/local/customerportal/tests/catalog_service_test.php` → 3 tests, 5 assertions, green (runner still reports one global PHPUnit deprecation)
  - functional smoke: direct `catalog_service::get_detail('attendance-plus-pro')` call returns `runbot_demo_id="attendance-plus-pro"` after deploy.

---

### task30 Runbot → Directus: Plugin Wizard SSOT import
Status: done (cf040a8 — 2025)
Feature: feat08
Owner: Coordinator (Copilot)
Scope:
- this task lives in the **Runbot repo** (`moodle-runbot-mcp`), not in `eledia.os_repo`
- extend the Runbot Plugin Wizard backend (`src/services/plugin-install.ts` or new `directus-import.ts`):
  - after successful `version.php` parse, POST to `https://directus.eledia.ai/items/plugin_component` with fields: `component` (frankenstyle), `display_name`, `slug` (derived from frankenstyle), `status=draft`
  - duplicate check: if `component` already exists (Directus 409 or pre-check GET), skip and return existing `id`
  - auth: dedicated Directus service token with `catalog_editor` role; stored in Runbot `.env` as `DIRECTUS_IMPORT_TOKEN`
  - error: on Directus failure, log warning and continue — wizard must not fail because of import
- Directus side: no code changes needed (existing `catalog_editor` policy is sufficient); only provision the token
- update Runbot `03-dev-doc.md`: document the integration endpoint and token setup

Definition of done:
- a plugin wizard submission creates a `draft` entry in Directus
- duplicate frankenstyle is handled without error
- Directus failure does not break the wizard flow

---

### task31 Runbot Onlineshop → Directus installation registration (Release 2 concept)
Status: Agent A code complete 2026-04-18; Runbot + portal sides remain dependent on Onlineshop production
Feature: feat09
Owner: Coordinator (Copilot) — planning; Agent A (Claude) — Directus endpoint; Agent B (Codex) — portal pre-config
Scope:
- **Directus (Agent A):** add a new portal-private endpoint `POST /v1/portal/installations` to the `v1` extension
  - payload: `id` (UUID), `label`, `moodle_version`, `profile`, `contact_email`
  - auth: service token; responds with created record or 409 if UUID already exists
  - add `installation` collection to Directus if not yet present
- **Runbot (Coordinator):** after successful provisioning in `orders.ts`, call `POST /v1/portal/installations`; store returned `installation_id` in order state; include it in the Welcome-Mail
- **Portal (Agent B):** add a setup-wizard step to `local_customerportal/settings.php` that pre-fills `installation_id` and `directus_url` from URL parameters (Runbot passes them as query params in the Welcome-Mail setup link)
- depends on: Runbot Onlineshop reaching production (task46–49 in Runbot repo)

Definition of done:
- end-to-end: Runbot order → Directus installation record → portal settings pre-filled
- no manual Directus Studio step required for new customer onboarding

Progress 2026-04-18 (Agent A side):
- `directus/extensions/v1/index.js` — new `POST /v1/portal/installations` behind the existing service-token guard. Validates `id` (UUID), `label`/`moodle_version` (length-bounded), `profile` against allowlist `managed`/`self_hosted`/`demo`, optional `contact_email` (format-checked). Returns `201 {id, label, moodle_version, profile, contact_email, snapshot_status, created_at}` or `409` when the UUID is already registered.
- `ensureInstallationTable(database)` — lazy table creator (same pattern as `ensurePortalRequestTable`), so the endpoint works **before** the matching Studio collection is added. Schema: `id`, `label`, `moodle_version`, `profile`, `contact_email`, `snapshot_status` (default `current`), `created_at`, `created_by`. A later Studio collection with overlapping schema picks up the existing table — no manual data migration.
- `GET /v1/portal/installation/{id}` — now prefers the real `installation` row when present; falls back to the deterministic Release-1 mock for unregistered UUIDs so existing portal flows (test02 / test05) stay green during rollout.
- `directus/extensions/v1/README.md` and `docs/03-dev-doc.md` updated: new endpoint shape documented; new "Operational Tables (portal-private)" subsection introduces `installation` and `portal_request` formally; "Portal-Private Installation Endpoints" describes the read-fallback behaviour.

Open follow-ups:
- **Coordinator:** wire the call in Runbot `orders.ts` once Onlineshop reaches production; design the Welcome-Mail setup-link contract (`installation_id` + `directus_url` query params).
- **Agent B:** portal setup-wizard step in `local_customerportal/settings.php` consuming the Welcome-Mail setup-link parameters.
- **Studio (optional):** add a matching `installation` collection in Directus Studio when admin UX over the same data is desired. The lazy table is already storage-compatible.
- **Smoke test:** after the next deploy, add a positive POST→GET round-trip case to `v1_contract_smoke_test.sh` (currently the smoke test only exercises `portal_request` end-to-end).

---

### task32 Public Website — VPS Deploy auf marketplace.eledia.ai
Status: done (2026-04-19)
Feature: feat02
Owner: Coordinator (Copilot)
Depends on: task24 (empfohlen, aber nicht blockierend)

Scope:
Deploy der Next.js-App (`website/public-catalog/`) auf dem bestehenden Directus-VPS unter `marketplace.eledia.ai`.

**Infra-Schritte (einmalig):**
- DNS: A-Record `marketplace.eledia.ai` → Directus-VPS-IP
- SSL: `certbot --nginx -d marketplace.eledia.ai` (Let's Encrypt)
- Nginx-Vhost anlegen: Reverse Proxy `marketplace.eledia.ai` → `localhost:3001`
- Node.js + pm2 auf VPS verfügbar (prüfen)

**App-Schritte:**
- Repo auf VPS clonen/pullen: `website/public-catalog/`
- `.env.production` anlegen:
  ```
  NEXT_PUBLIC_SITE_URL=https://marketplace.eledia.ai
  CATALOG_API_BASE_URL=https://directus.eledia.ai
  ```
- `npm ci && npm run build`
- pm2-Prozess: `pm2 start npm --name "catalog" -- start -- -p 3001`
- `pm2 save && pm2 startup`

**next.config.ts anpassen:**
- `cdn.example.com` in `images.remotePatterns` durch finale Domain ersetzen (falls CDN vorgesehen)

**Deployment-Skript** (Folge-Deploys):
```bash
# website/public-catalog/scripts/deploy.sh
cd /opt/catalog/website/public-catalog
git pull origin main
npm ci
npm run build
pm2 reload catalog
```

Progress 2026-04-19:
- Repo-side deploy path hardened in `website/public-catalog/scripts/deploy.sh`.
- Fixed production env name to `CATALOG_API_BASE_URL` so the deployed app points at the live Directus contract endpoint.
- Removed `npm ci --omit=dev` from the deploy path because the Next.js TypeScript build needs dev dependencies during `npm run build`.
- Added guard rails so deploy fails early if `NEXT_PUBLIC_SITE_URL` or `CATALOG_API_BASE_URL` are missing in `.env.production`.
- Updated `website/public-catalog/README.md` with the VPS deploy flow for `marketplace.eledia.ai`.
- VPS checkout updated to `main` (`0d5e028`), `catalog` and `caddy` containers recreated successfully.
- Public DNS now resolves `marketplace.eledia.ai` to `167.235.71.47`; Let's Encrypt certificate for `marketplace.eledia.ai` is valid (`2026-04-19` to `2026-07-18`).
- Public verification passed:
  - `https://marketplace.eledia.ai/catalog` → `200`
  - `https://marketplace.eledia.ai/catalog/exam2pdf` → `200`
  - canonical / OG metadata render with `NEXT_PUBLIC_SITE_URL=https://marketplace.eledia.ai`
- Live catalog projection extended with published `exam2pdf` entry so the task32 detail-route DoD is met.

Definition of done:
- `https://marketplace.eledia.ai/catalog` zeigt Einträge aus live Directus
- `https://marketplace.eledia.ai/catalog/exam2pdf` zeigt Detail-Seite
- SSL-Zertifikat gültig
- pm2 überlebt Server-Neustart (`pm2 startup`)
- `NEXT_PUBLIC_SITE_URL` korrekt gesetzt (Canonical URLs + OG tags)

---

## Release 1.2 Plus — Installation Digital Twin

Ziel: Release 1.2 bewusst erweitern, damit Kundeninstallationen in Directus nicht nur registriert, sondern als belastbarer Betriebszustand (Snapshot + Änderungen + Pluginzustand) geführt werden.

Priorität/Reihenfolge:
1. task33 (P0) — Schema-Basis für Installation Digital Twin
2. task34 (P0) — v1 Endpoint-Contract für Snapshot und Plugin Sync
3. task35 (P0) — Moodle Plugin: Snapshot/Plugin Sync Writer
4. task36 (P1) — Change Event Log + Idempotenz
5. task37 (P1) — Portal-Read-Path auf echte `installation_plugin` Daten
6. task38 (P1) — End-to-End Qualitätssicherung und Rollout-Checkliste

### 4-Agent Arbeitsteilung (verbindlich)

Claude (Directus/API):
- owns schema + endpoint contract + persistence semantics
- responsible tasks: task33, task34, API-part of task36
- must provide: migrations/snapshot changes, endpoint validation, idempotent upserts, API examples

Gemini (Moodle/Portal):
- owns producer and consumer side in Moodle (`local_customerportal`)
- responsible tasks: task35, task37, plugin-part of task36
- must provide: scheduled sync writer, payload normalization, resilient retries, portal rendering fallback states

Coordinator (QA & Release Gate):
- owns rollout sequence, smoke evidence, and release gate decision
- responsible tasks: task38 and cross-agent handoff acceptance
- must provide: deploy order, live smoke runs, quality evidence in docs, go/no-go status

Codex (Schema/Ops & Deployment):
- owns live Directus Studio schema migration and deployment operations
- responsible tasks: task33 (Studio-side), deployment of v1 extension, snapshot capture/apply
- works in parallel with Claude: Claude writes lazy-create code, Codex applies matching schema in Studio simultaneously
- must provide: confirmed schema live in Directus, extension redeploy confirmation, updated live status in docs/03-dev-doc.md
- key scripts: `directus/scripts/apply_snapshot.sh`, `directus/scripts/capture_snapshot.sh`, `directus/scripts/deploy_v1_endpoint_extension.sh`

Handoff gates (no parallel bypass):
1. Claude -> Gemini gate after task34:
  - stable request/response examples for snapshot + plugin sync + events
  - error model frozen (`validation_error`, `conflict`, `forbidden`, `internal_error`)
2. Claude -> Codex gate (parallel to Claude->Gemini, unblocks Gemini testing):
  - Claude provides `ensureInstallationPluginTable()` schema definition
  - Codex confirms: `installation` fields + `installation_plugin` table live in Directus Studio
3. Gemini -> Coordinator gate after task35/task37:
  - successful local roundtrip evidence (snapshot + plugin sync)
  - portal reads real `installation_plugin` rows
4. Claude+Gemini -> Coordinator gate after task36:
  - duplicate event idempotency proven
  - drift correction via periodic snapshot proven
5. Codex -> Coordinator gate (prerequisite for task38 live smoke):
  - v1 extension redeployed with task34 code
  - schema confirmed live

Decision rights:
- Claude decides DB/API shape.
- Gemini decides Moodle extraction/rendering details.
- Coordinator decides rollout timing and release acceptance.
- Codex decides deployment sequencing and Studio migration order.

Escalation rule:
- if a contract change is required after Claude->Gemini gate, task34 is re-opened and task35/task37 return to in-progress until examples and tests are updated.
- if a schema conflict is found by Codex in Studio, Claude is consulted before applying; schema code and Studio must stay in sync.

### task33 Directus schema extension — installation digital twin core
Status: open
Feature: feat09
Owner: Claude (lazy-create code) + Codex (Studio migration)
Depends on: task31
Scope:
- extend `installation` table/collection with mandatory fields:
  - `flavour` enum: `lms`, `workplace`
  - `release_channel` enum: `lts`, `newest`
  - `sla_level` enum: `level_1`, `level_2`
  - `user_tier` enum: `250`, `500`, `1000`, `2000`
  - `addon_bbb_enabled` bool, `addon_solr_enabled` bool
- add optional runtime telemetry fields:
  - `user_count_active_30d`, `user_count_total`
  - `storage_used_gb`, `storage_quota_gb`, `storage_utilization_percent`
  - `health_overall` enum: `green`, `amber`, `red`
  - `last_sync_at`, `last_event_at`
- add new `installation_plugin` table/collection:
  - `id`, `installation_id`, `frankenstyle`, `plugin_component_id`, `product_id`, `catalog_entry_id`, `installed_version`, `status`, `time_installed`, `time_updated`
  - status enum: `installed`, `outdated`, `deprecated`, `removed`
- add indexes:
  - unique (`installation_id`, `frankenstyle`)
  - lookup indexes on `installation_id`, `status`, `plugin_component_id`, `product_id`, `catalog_entry_id`
Definition of done:
- schema exists in live Directus (Studio or snapshot apply)
- all required enums/constraints are enforced
- `installation_plugin` can store rows with only (`installation_id`, `frankenstyle`) and later-resolved IDs (nullable FK strategy)

### task34 v1 extension — snapshot + plugin sync endpoints
Status: done (2026-04-19)
Feature: feat09
Owner: Agent A
Depends on: task33
Scope:
- implement `POST /v1/portal/installations/snapshot` (upsert by `installation_id`)
  - accepts the mandatory digital-twin fields + runtime telemetry
  - validates enum allowlists and numeric bounds
- implement `POST /v1/portal/installations/{installation_id}/plugins/sync`
  - upsert plugin rows by (`installation_id`, `frankenstyle`)
  - attempts 4-way linkage resolution on each row:
    - base: `installation_id`, `frankenstyle`
    - canonical: `plugin_component_id` or `product_id`
    - projection: `catalog_entry_id`
- keep service-token guard for all new routes (`/v1/portal/*`)
- keep backward compatibility for existing task31 `POST /v1/portal/installations`
Definition of done:
- both endpoints deployed and reachable on `directus.eledia.ai`
- invalid payloads return `400 validation_error` with useful message
- sync endpoint is idempotent for repeated payloads
Verification:
- redeployed to `directus-vps` with `directus/scripts/deploy_v1_endpoint_extension.sh`
- live snapshot upsert, plugin sync roundtrip, and event idempotency verified on `2026-04-19`

### task35 local_customerportal — snapshot and plugin sync writer
Status: open
Feature: feat03, feat09
Owner: Agent B
Depends on: task34
Scope:
- extend `installation_service`/new sync service to produce installation snapshot payload:
  - flavour, release_channel, sla_level, user_tier, add-ons
  - runtime values (users, storage, health, timestamps)
- extend plugin inventory extraction (real installed plugins from Moodle)
- send payloads to:
  - `POST /v1/portal/installations/snapshot`
  - `POST /v1/portal/installations/{id}/plugins/sync`
- scheduled task cadence:
  - full snapshot every 15 min
  - plugin sync every 15 min (same task or sibling task)
- robust failure handling with retry-friendly behavior (no portal hard-fail)
Definition of done:
- local sync task writes snapshot and plugin rows end-to-end
- no fatal errors when Directus is temporarily unavailable
- PHPUnit for payload normalization and API client interactions is green

### task36 change event log — audit trail + idempotency
Status: open
Feature: feat09
Owner: Agent A + Agent B
Depends on: task34, task35
Scope:
- add `installation_change_event` table/collection:
  - `id`, `installation_id`, `event_id`, `event_type`, `payload`, `actor_type`, `actor_id`, `happened_at`, `received_at`
  - unique (`installation_id`, `event_id`) for idempotency
- add endpoint `POST /v1/portal/installations/{installation_id}/events`
- event types (minimum):
  - `plugin_installed`, `plugin_updated`, `plugin_removed`
  - `tier_changed`, `addon_enabled`, `addon_disabled`, `storage_changed`
- plugin side emits events for explicit actions; periodic snapshot remains source of truth for drift correction
Definition of done:
- duplicate event submission does not create duplicate rows
- event stream is queryable per installation for support/audit
- smoke path validates one positive event ingestion and one duplicate rejection/ignore

### task37 portal read path — remove deterministic plugin bootstrap
Status: open
Feature: feat03, feat09
Owner: Agent B
Depends on: task35
Scope:
- switch portal "Meine Plugins" and detail overlay read path to real `installation_plugin` rows
- fallback behavior:
  - if installation has no synced rows yet, show explicit "Noch nicht synchronisiert" state
  - do not present deterministic fake plugin state for synced installations
- render classification and status tags (`installed`, `outdated`, `deprecated`, `removed`)
Definition of done:
- portal plugin list for synced installations reflects real Directus rows
- deterministic bootstrap behavior no longer visible once first sync completed
- UI handles empty-state gracefully

### task38 Release 1.2 Plus verification pack
Status: open
Feature: feat03, feat09
Owner: Agent C (Coordinator)
Depends on: task33, task34, task35, task36, task37
Scope:
- extend `directus/scripts/v1_contract_smoke_test.sh` with:
  - installation snapshot upsert roundtrip
  - plugin sync upsert roundtrip
  - event ingestion + duplicate idempotency check
- add quality evidence section in `docs/05-quality.md`
- rollout checklist:
  - schema apply
  - v1 extension deploy
  - plugin deploy
  - smoke tests against `directus.eledia.ai`
Definition of done:
- new smoke suite is green against live endpoint
- quality doc contains reproducible commands + expected outputs
- release gate can be evaluated in one pass by Ops/QA

---

## Operational Follow-ups (consolidated)

Snapshot of work that is **code complete** in the repo but waiting on operational steps (live Directus schema changes, redeploys, smoke runs, derivation work). Grouped by deployment unit so one Studio session + one extension redeploy unblocks several tasks at once.

### A. Live Directus schema migration (Studio or schema snapshot diff)

Apply once, in a single editorial pass:

1. **task24 — SEO columns on `catalog_entry_public`** (Release 1.2)
   - `meta_title` (string, nullable)
   - `meta_description` (string, nullable)
   - `og_image` (JSON `{url, alt}`, nullable)
   - `tags` (JSON string array, nullable)
   - Studio validation rule: `screenshots[].alt` non-empty (already enforced at runtime by `catalog-projection-hook` Flow F4).

2. **task25 — Plugin classification** (Release 1.2)
   - 17 columns on `catalog_entry_public`: lifecycle (`last_release_version`, `last_release_date`, `release_cadence_days`, `maintenance_badge`, `is_deprecated`, `replacement_entry_id`), pricing (`pricing_model`, `is_open_source`, `price_range_eur`, `license_unit`, `trial_available`, `is_eledia_product`), GDPR (`stores_personal_data`, `privacy_api_implemented`, `data_transfer_outside_eu`, `gdpr_readiness`), `maintainer` (JSON public subset).
   - Mirror the editorial subset on canonical `plugin_component` and `product` (same fields, plus `vendor_id` M2O).
   - Create new collection `plugin_maintainer` per `docs/03-dev-doc.md → "plugin_maintainer"` (incl. internal-only `contact_email`, `contact_phone`, `homepage`).
   - Field allowlist on `public_api` policy: deny new internal `plugin_maintainer` fields; only the `maintainer` JSON projection is public.

Field definitions and enum values are in [docs/03-dev-doc.md](03-dev-doc.md) under "Plugin Classification" and the canonical/projection tables.

### B. Extension redeploy

After A:

```bash
./directus/scripts/deploy_v1_endpoint_extension.sh directus-vps
./directus/scripts/deploy_catalog_projection_hook.sh directus-vps
```

The redeploy is safe before the schema is migrated as well — runtime column-detection emits the new keys as `null`. Doing it after migration just makes populated values surface.

### C. Smoke + content reconciliation

1. Run `directus/scripts/v1_contract_smoke_test.sh` against `directus.eledia.ai` — must stay green; SEO + classification + Runbot keys are already presence-asserted.
2. Re-import (or hand-edit) the `attendance-plus` and `attendance-plus-pro` projections from `docs/seeds/catalog_seed_v1.json` so the seed values surface on a real entry. `attendance-plus` carries the OSS profile; `attendance-plus-pro` carries the eLeDia / certified-partner / paid profile.
3. Reconcile placeholder `runbot_demo_id` values (`attendance-plus-pro`, `exam2pdf` — slug-as-id placeholders) against the actual keys in Runbot's `configs.json`.
4. Reconcile placeholder `maintainer` records (`Moodle HQ`, `eLeDia GmbH`) against actual `plugin_maintainer` rows once the collection exists in live.

### D. Tasks unblocked by A+B+C

| Step done | Unblocked |
|---|---|
| task24 SEO columns live | task24 DoD met (CTAs already wired in task16) |
| task25 classification + `plugin_maintainer` live | task25 DoD met → unblocks **task26** (portal classification rendering, Agent B) |

### E. Code-side derivation work (no live dep)

Once the editorial flow is healthy, move these projection columns out of `CURATED_PROJECTION_COLUMNS` and let the hook derive them again:

- `last_release_version`, `last_release_date`, `release_cadence_days` — derive from published `plugin_release` rows in `rebuildPluginProjection` / `rebuildProductProjection`.
- `maintainer` — derive from `plugin_component.vendor_id` → `plugin_maintainer` join, exposing only `{name, type, is_moodle_certified_partner}`.

Trade-off: leaving them as curated is fine while the editorial side fills the data; deriving them later avoids drift between `plugin_release` and the projection.

### F. Schema snapshot captured

`directus/schema/catalog-v1.yaml` was refreshed from the live export on `2026-04-19`, replacing the previous placeholder. Follow-up schema work should now update this checked-in snapshot instead of reusing the placeholder note from `docs/catalog/directus_live_status_2026-04-18.md`.

### G. Cross-agent / future work

- **task26** (Agent B, portal): blocked on D-step for task25.
- **task29** (Agent B, portal Demo CTA): "in progress" on Agent B side — task27 dep already resolved.
- **task32** (Coordinator, marketplace.eledia.ai deploy): unblocks public production URL for task16/task24/task28 user-visible verification.
- **task31** (Release 2 concept, feat09): Runbot Onlineshop → Directus installation registration. Agent A side **code complete**: `POST /v1/portal/installations` plus lazy `installation` table is in `directus/extensions/v1`. Just needs the next `deploy_v1_endpoint_extension.sh` cycle to ship to `directus.eledia.ai`. Coordinator-side (Runbot `orders.ts` integration) and Agent B-side (portal setup-wizard step) remain dependent on Onlineshop production rollout. Smoke-test extension to add a POST→GET round-trip is open.

---

## Verify After Deploy

- public catalog only exposes published entries
- portal only exposes customer-specific installation context
- request creation works without commercial ordering
- shared contract is implemented consistently in website and portal
- Proven summary is public while internal evidence remains private

---

## Done

- initial project scope aligned
- work split into Agent A and Agent B
- Agent A catalog/SSOT schema documented
- Agent A public projection/read model documented
- Agent A shared API contract documented
- Agent A seed data and website IA proposed
- Agent A Directus implementation checklist v1 created
- Phase 9 rollout assets added (snapshot/apply wrappers and smoke-test script)
- Agent A -> Agent B handover contract frozen (overlay and request fields)
- Agent B portal information architecture defined (task05)
- Agent B overlay logic documented (task06)
- Agent B request model defined (task07)
- Agent B local_customerportal technical blueprint created
- Directus `v1` contract endpoint extension deployed and smoke-tested live
- task09 projection lifecycle automation implemented as Directus hook extension (`catalog-projection-hook`)
- task12 public catalog frontend stack locked (Next.js App Router) and scaffold created
- task13 catalog search/list implemented with focused filter set and pagination
- task20 local_customerportal baseline implemented (plugin v2026041801)
- task21 LernHive design system applied to all portal pages
- task22 German language pack created and redundant strings sourced from Moodle core
- catalog_entry_public Studio UX optimized (field order, defaults, admin preset without JSON list columns)
- task23 Portal Release 1.1 shipped — storage / environment / health panels on dashboard and installation page
- task33 Digital Twin Schema-Erweiterung (installation_plugin, installation_change_event)
- task34 Digital Twin API Endpoints (snapshot, sync, events)
- task35 Moodle Plugin Sync Writer (Snapshot & Plugin Tasks)
- task36 Event Observer im Moodle Plugin (idempotente Change Events)
- task37 Portal Read Path Umstellung auf Live-Daten (Wegfall Bootstrap-Mocks)
- task38 Quality Gate R1.2 Plus (Smoke Tests 1-16 erfolgreich)
- task32 Website VPS Deploy marketplace.eledia.ai
