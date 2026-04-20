# Developer Documentation

## Meta

This document describes how the Moodle Plugin Platform is technically structured.

It is the source of truth for:
- architecture and responsibility split
- Directus SSOT and published projection model
- shared API contract between catalog and portal
- implementation model for the Moodle portal plugin
- deployment procedures

---

## Live Status (2026-04-19)

Directus: 11.17.3 — PostgreSQL — `directus.eledia.ai`

### Collections live

- `plugin_component`, `plugin_release`, `product`, `product_component`, `plugin_review`, `plugin_review_dimension`, `catalog_entry_public`
- `installation`, `portal_request` — lazy-created by v1 extension (task31)
- `installation_plugin`, `installation_change_event` — live and managed (task33)

### Seed counts

- `plugin_component`: 3 · `plugin_release`: 3 · `product`: 2 · `product_component`: 3
- `plugin_review`: 2 · `plugin_review_dimension`: 3 · `catalog_entry_public`: 3

### Extensions loaded

- `catalog-projection-hook` — projection lifecycle automation
- `v1` — contract endpoint package (`/v1/catalog/*`, `/v1/portal/*`)

### Contract endpoint status

| Endpoint | Status |
|---|---|
| `GET /v1/catalog/search` | 200 |
| `GET /v1/catalog/{slug}` | 200 |
| `GET /v1/portal/installation/{id}` | 200 (service token) |
| `GET /v1/portal/installation/{id}/plugins` | 200 (service token) |
| `GET /v1/portal/overlay` | 200 (service token) |
| `GET /v1/portal/requests` | 200/201 (service token) |
| `GET /v1/portal/*` without token | 403 |
| `POST /v1/portal/installations` | 201 (service token, task31) |
| `POST /v1/portal/installations/snapshot` | 200/201 (service token, task34) |
| `POST /v1/portal/installations/{id}/plugins/sync` | 200 (service token, task34) |
| `POST /v1/portal/installations/{id}/events` | 200/201 (service token, task36 API part) |

Verification:
- `directus/scripts/v1_contract_smoke_test.sh` — 8/8 passed on 2026-04-18 (baseline)
- live spot checks on 2026-04-19 after redeploy: snapshot upsert, plugin sync roundtrip, event ingestion + duplicate idempotency, unauthenticated `403`

### R1.2 Plus Migration (completed 2026-04-19)

Schema migration script: `directus/scripts/apply_installation_r12_schema.sh`

Applied on `directus-vps`:
```bash
bash directus/scripts/apply_installation_r12_schema.sh directus-vps
bash directus/scripts/capture_snapshot.sh
```

Migration adds:
- 14 new fields on `installation` table (flavour, release_channel, sla_level, user_tier, addon_bbb_enabled, addon_solr_enabled + telemetry)
- New table `installation_plugin` with 4-way linkage model and all Studio metadata
- New table `installation_change_event` with idempotency unique index and all Studio metadata
- Tabular presets: "Installation Plugins", "Installation Events"

### Studio UX patch applied

Script `directus/scripts/optimize_catalog_entry_public_ui.sh`:
- improved field ordering and interfaces
- required flags on `title`, `slug`, `entry_type`, `status`
- hidden internal fields (`source_type`, `source_id`) in form
- tabular preset `Catalog Public - Redaktion`
- column defaults: `entry_type=plugin`, `proven_badge=none`, `status=draft`

### Snapshot note

Live schema snapshot exported to `/opt/directus/extensions/catalog-v1-live.yaml` and copied into `directus/schema/catalog-v1.yaml` on 2026-04-19. This export is now the current checked-in baseline for follow-up schema work.


## System Overview

### Architecture overview

The platform is built around three main surfaces:
1. **Directus + PostgreSQL** as internal SSOT and editorial backoffice
2. **Public catalog website** as read-only discovery layer
3. **Moodle customer portal (`local_customerportal`)** as customer-specific interface

Later phases may add Odoo integration and commerce flows.

### Responsibility split

Directus is responsible for:
- canonical catalog data (`plugin_component`, `plugin_release`, `product`, `product_component`)
- Proven review data (`plugin_review`, `plugin_review_dimension`)
- public projection (`catalog_entry_public`)
- operational domain entities (installations and requests)

Public website is responsible for:
- consuming the shared public API contract
- search/filter and detail rendering
- exposing only public projection fields

Moodle portal is responsible for:
- installation and installed-plugin context
- consuming the same public catalog contract
- overlaying installation-specific context
- request creation

## Catalog and SSOT Domain

Assumptions:
- Directus 11 with PostgreSQL is the operational baseline.
- Collection IDs use UUIDs.
- Media references use `directus_files` relations.
- Public consumption happens only through `catalog_entry_public`.
- Workflow statuses are `draft -> reviewed -> published -> retired`.

Seed data: `docs/seeds/catalog_seed_v1.json`

### Canonical Collections

| Collection | Purpose | Publicly readable |
|---|---|---|
| `plugin_component` | Technical identity and metadata of Moodle plugins | No |
| `plugin_release` | Versioned release data for a plugin component | No |
| `product` | Commercial/catalog-facing product or bundle | No |
| `product_component` | Mapping between `product` and `plugin_component` | No |
| `plugin_review` | Proven review header, aggregate score, public summary | No |
| `plugin_review_dimension` | Per-dimension review result and internal evidence | No |
| `catalog_entry_public` | Published read model for website and portal | Yes, but only `published` |

#### `plugin_component`

| Field | Type | Required | Notes |
|---|---|---|---|
| `id` | UUID | Yes | Primary key |
| `component` | String (unique) | Yes | Moodle component name, e.g. `mod_attendanceplus` |
| `plugin_type` | Enum | Yes | `mod`, `local`, `auth`, `block`, `theme`, `tool`, `enrol`, ... |
| `display_name` | String | Yes | Human-readable title |
| `slug` | String (unique) | Yes | Stable slug for plugin-level public entries |
| `teaser` | String | No | Short public teaser |
| `description_public` | Text | No | Public long description |
| `docs_url` | URL | No | Public docs target |
| `hero_asset` | M2O `directus_files` | No | Public hero image |
| `status` | Enum | Yes | `draft`, `reviewed`, `published`, `retired` |
| `published_at` | Timestamp | No | Set when status becomes `published` |
| `retired_at` | Timestamp | No | Set when status becomes `retired` |
| `owner_team` | String | No | Internal stewardship |
| `updated_at` | Timestamp | Yes | System-managed |
| `runbot_demo_id` | String | No | task27 (feat07): Runbot `configs.json` key for the live demo, deep-linked from "Demo starten" CTA |
| `vendor_id` | M2O `plugin_maintainer` | No | task25: editorial maintainer link; projection exposes only public subset |
| `pricing_model` | Enum | No | task25: `free`, `freemium`, `paid_onetime`, `paid_subscription`, `paid_support_only` |
| `is_open_source` | Boolean | No | task25 |
| `price_range_eur` | Enum | No | task25: `<100`, `100-500`, `500-2000`, `>2000`, `poa` |
| `license_unit` | Enum | No | task25: `per_site`, `per_user`, `per_installation`, `enterprise` |
| `trial_available` | Boolean | No | task25 |
| `is_eledia_product` | Boolean | No | task25 (internal flag, public projection OK) |
| `is_deprecated` | Boolean | No | task25 lifecycle |
| `replacement_entry_id` | String/UUID | No | task25 lifecycle; M2O fallback to `catalog_entry_public` slug or id |
| `maintenance_badge` | Enum | No | task25: `actively_maintained`, `looking_for_maintainer`, `orphaned`, `unknown` |
| `stores_personal_data` | Enum | No | task25 GDPR: `none`, `pseudonymised`, `identifying` |
| `privacy_api_implemented` | Boolean | No | task25 GDPR (auto-derivable from code scan) |
| `data_transfer_outside_eu` | Boolean | No | task25 GDPR |
| `gdpr_readiness` | Enum | No | task25 GDPR: `green`, `amber`, `red`, `unknown` |

Relations: 1:N to `plugin_release`; 1:N to `plugin_review`; M:N to `product` via `product_component`; M:O to `plugin_maintainer` via `vendor_id`

Lifecycle fields (`last_release_*`, `release_cadence_days`) are derived from `plugin_release` history by the projection hook (open follow-up: derivation goes live once canonical FKs land — until then projection rows carry curated values).

#### `plugin_release`

| Field | Type | Required | Notes |
|---|---|---|---|
| `id` | UUID | Yes | Primary key |
| `plugin_component_id` | M2O `plugin_component` | Yes | Parent plugin |
| `version_name` | String | Yes | Human version, e.g. `2.4.1` |
| `version_code` | BigInt | Yes | Moodle release integer |
| `supported_moodle_min` | String | Yes | e.g. `4.1` |
| `supported_moodle_max` | String | Yes | e.g. `4.4` |
| `release_date` | Date | No | Official release date |
| `changelog_url` | URL | No | Changelog URL |
| `is_lts` | Boolean | Yes | LTS marker |
| `status` | Enum | Yes | `draft`, `reviewed`, `published`, `retired` |

Constraint: Unique (`plugin_component_id`, `version_code`)

#### `product`

| Field | Type | Required | Notes |
|---|---|---|---|
| `id` | UUID | Yes | Primary key |
| `slug` | String (unique) | Yes | Public slug |
| `title` | String | Yes | Public title |
| `entry_type` | Enum | Yes | `product` or `bundle` |
| `teaser` | String | No | Public teaser |
| `description_public` | Text | No | Public long description |
| `docs_url` | URL | No | Public docs URL |
| `hero_asset` | M2O `directus_files` | No | Public hero image |
| `shop_url` | URL | No | Optional future link, no checkout in R1 |
| `status` | Enum | Yes | `draft`, `reviewed`, `published`, `retired` |
| `published_at` | Timestamp | No | Set when published |
| `retired_at` | Timestamp | No | Set when retired |
| `runbot_demo_id` | String | No | task27 (feat07): Runbot `configs.json` key for the live demo, deep-linked from "Demo starten" CTA |
| `vendor_id` | M2O `plugin_maintainer` | No | task25: editorial maintainer link |
| `pricing_model` | Enum | No | task25: see `plugin_component` |
| `is_open_source` | Boolean | No | task25 |
| `price_range_eur` | Enum | No | task25 |
| `license_unit` | Enum | No | task25 |
| `trial_available` | Boolean | No | task25 |
| `is_eledia_product` | Boolean | No | task25 |
| `is_deprecated` | Boolean | No | task25 lifecycle |
| `replacement_entry_id` | String/UUID | No | task25 lifecycle |
| `maintenance_badge` | Enum | No | task25 lifecycle |
| `stores_personal_data` | Enum | No | task25 GDPR |
| `privacy_api_implemented` | Boolean | No | task25 GDPR |
| `data_transfer_outside_eu` | Boolean | No | task25 GDPR |
| `gdpr_readiness` | Enum | No | task25 GDPR |

Relations: M:N to `plugin_component` via `product_component`; M:O to `plugin_maintainer` via `vendor_id`

#### `product_component`

| Field | Type | Required | Notes |
|---|---|---|---|
| `id` | UUID | Yes | |
| `product_id` | M2O `product` | Yes | Parent product |
| `plugin_component_id` | M2O `plugin_component` | Yes | Linked plugin |
| `relation_role` | Enum | Yes | `core`, `optional`, `dependency` |
| `min_version_code` | BigInt | No | Optional compatibility floor |
| `max_version_code` | BigInt | No | Optional compatibility ceiling |
| `sort` | Integer | No | Ordering in UI |

Constraint: Unique (`product_id`, `plugin_component_id`)

#### `plugin_review`

| Field | Type | Required | Notes |
|---|---|---|---|
| `id` | UUID | Yes | |
| `plugin_component_id` | M2O `plugin_component` | Yes | Reviewed plugin |
| `plugin_release_id` | M2O `plugin_release` | No | Optional release-scoped review |
| `review_scope` | Enum | Yes | `component` or `release` |
| `reviewed_at` | Timestamp | Yes | Review date |
| `reviewer_name` | String | No | Internal reviewer identifier |
| `overall_score` | Decimal(4,2) | Yes | Aggregate 0-100 |
| `proven_badge` | Enum | Yes | `none`, `bronze`, `silver`, `gold` |
| `proven_summary_public` | Text | Yes | Public aggregate summary only |
| `internal_notes` | Text | No | Never exposed publicly |
| `status` | Enum | Yes | Workflow state |

Recommendation: exactly one active `published` review per plugin component in Release 1.

#### `plugin_review_dimension`

| Field | Type | Required | Notes |
|---|---|---|---|
| `id` | UUID | Yes | |
| `plugin_review_id` | M2O `plugin_review` | Yes | Parent review |
| `dimension_key` | Enum | Yes | `security`, `maintainability`, `performance`, `ux`, `interoperability`, `supportability` |
| `score` | Integer | Yes | 1-5 |
| `verdict` | Enum | Yes | `fail`, `watch`, `pass`, `strong` |
| `summary_public` | String | No | Optional one-line public hint |
| `evidence_internal` | Text | No | Internal evidence only |

#### `plugin_maintainer` (task25, Release 1.2)

| Field | Type | Required | Notes |
|---|---|---|---|
| `id` | UUID | Yes | |
| `type` | Enum | Yes | `individual`, `organisation`, `moodle_partner`, `eledia` |
| `name` | String | Yes | Display name |
| `org_name` | String | No | Legal org name when `type=organisation`/`moodle_partner` |
| `homepage` | URL | No | Public homepage |
| `is_moodle_certified_partner` | Boolean | Yes | Surfaced in public projection |
| `plugin_portfolio_count` | Integer | No | Editorial count of maintained plugins |
| `active_since_year` | Integer | No | Public footprint since |
| `contact_email` | String | No | **Internal only** — never exposed in `catalog_entry_public` |
| `contact_phone` | String | No | **Internal only** |

Relations:
- M2O on `plugin_component.vendor_id` and `product.vendor_id` → `plugin_maintainer`
- Optional M2M for co-maintainers via array FK `co_maintainer_ids[]` (Release 1.2 keeps this single-maintainer; co-maintainer rendering is a R1.3+ option)

Public projection rule: `catalog_entry_public.maintainer` only carries `{name, type, is_moodle_certified_partner}`. Contact details, homepage, and portfolio count stay internal in Release 1.2.
| `sort` | Integer | No | UI order |

Constraint: Unique (`plugin_review_id`, `dimension_key`)

### Published Projection — `catalog_entry_public`

This is the only public source for catalog search/detail.

| Field | Type | Notes |
|---|---|---|
| `id` | UUID | Projection record ID |
| `slug` | String (unique) | Public routing key |
| `title` | String | Public title |
| `entry_type` | Enum | `plugin`, `product`, `bundle` |
| `teaser` | String | Search teaser |
| `plugin_type` | String | Filled for plugin entries, nullable for others |
| `proven_badge` | Enum | `none`, `bronze`, `silver`, `gold` |
| `supported_moodle` | String | e.g. `4.1-4.4` |
| `hero_asset` | M2O `directus_files` | |
| `description_public` | Text | Detail description |
| `screenshots` | O2M sub-collection | Ordered screenshots with `alt_text` |
| `docs_url` | URL | |
| `proven_summary` | JSON | Aggregate-only proven output |
| `supported_versions` | JSON | Detail version objects |
| `source_type` | Enum | `plugin_component` or `product` |
| `source_id` | UUID | Origin item ID |
| `status` | Enum | Workflow status mirrored to projection |
| `published_at` | Timestamp | |
| `projection_version` | Integer | Starts at 1 |
| `projection_updated_at` | Timestamp | Last projection run |
| `meta_title` | String | task24 SEO; consumer fallback: `title` |
| `meta_description` | String | task24 SEO; consumer fallback: `teaser` then truncated `description_public` |
| `og_image` | JSON `{url, alt}` | task24 SEO; consumer fallback: `hero_asset` |
| `tags` | JSON string array | task24 SEO; consumer fallback: `[]` |
| `runbot_demo_id` | String | task27 (feat07); consumer renders "Demo starten" CTA when non-null |
| `last_release_version` | String | task25 lifecycle |
| `last_release_date` | Date | task25 lifecycle (search-filterable) |
| `release_cadence_days` | Integer | task25 lifecycle, derived from release history |
| `maintenance_badge` | Enum | task25 lifecycle: `actively_maintained`, `looking_for_maintainer`, `orphaned`, `unknown` |
| `is_deprecated` | Boolean | task25 lifecycle |
| `replacement_entry_id` | String/UUID | task25 lifecycle; only meaningful when `is_deprecated = true` |
| `pricing_model` | Enum | task25 pricing: `free`, `freemium`, `paid_onetime`, `paid_subscription`, `paid_support_only` |
| `is_open_source` | Boolean | task25 pricing |
| `price_range_eur` | Enum | task25 pricing: `<100`, `100-500`, `500-2000`, `>2000`, `poa` |
| `license_unit` | Enum | task25 pricing: `per_site`, `per_user`, `per_installation`, `enterprise` |
| `trial_available` | Boolean | task25 pricing |
| `is_eledia_product` | Boolean | task25 pricing (internal flag, public projection OK) |
| `stores_personal_data` | Enum | task25 GDPR: `none`, `pseudonymised`, `identifying` |
| `privacy_api_implemented` | Boolean | task25 GDPR (auto-derivable from code scan) |
| `data_transfer_outside_eu` | Boolean | task25 GDPR |
| `gdpr_readiness` | Enum | task25 GDPR: `green`, `amber`, `red`, `unknown` |
| `maintainer` | JSON `{name, type, is_moodle_certified_partner}` | task25 maintainer (public subset only — no contact details) |

Curated field policy (task24, task25, task27): editorially curated columns are listed in `CURATED_PROJECTION_COLUMNS` in `catalog-projection-hook` and preserved across projection rebuilds. `screenshots[].alt` is required at write-time (WCAG AA). Lifecycle (`last_release_*`, `release_cadence_days`) and `maintainer` are treated as curated until canonical FKs (`plugin_component.vendor_id`, `plugin_release` derivation) ship to live; the hook's `CURATED_PROJECTION_COLUMNS` lists the open derivation candidates.

### Workflow and Publishing Rules

| From | To | Allowed | Guardrail |
|---|---|---|---|
| `draft` | `reviewed` | Yes | Validation checks pass |
| `reviewed` | `published` | Yes | Requires `catalog_publisher` role |
| `published` | `reviewed` | Yes | Content rework |
| `published` | `retired` | Yes | Requires retirement reason |
| `retired` | `reviewed` | Yes | Explicit reactivation path |

Public visibility rule: only `catalog_entry_public.status = published` may be exposed externally.

Proven display policy — public output may include: badge level, aggregate summary text, optional dimension labels and verdict counts. Public output must NOT include: reviewer identity, internal notes, raw evidence entries.

### Directus Roles

| Role | Permissions |
|---|---|
| `catalog_editor` | CRUD on canonical collections in `draft` and `reviewed`; no `published` transitions |
| `catalog_reviewer` | Read + update review fields; allowed transition `draft -> reviewed` |
| `catalog_publisher` | Transitions to `published` and `retired`; write access to projection |
| `public_api` | Read-only on `catalog_entry_public` where `status = published`; deny all canonical collections |

### Projection Lifecycle Automation (task09)

Implemented as Directus hook extension `directus/extensions/catalog-projection-hook/`.
Deploy: `directus/scripts/deploy_catalog_projection_hook.sh`

**Flow F1 — Upsert**
- Trigger: `items.create`, `items.update` on `plugin_component`, `plugin_release`, `product`, `product_component`, `plugin_review`
- Resolves impacted sources; derives `proven_badge`/`proven_summary` from latest published reviews; derives `supported_moodle`/`supported_versions` from published releases; upserts by `source_type + source_id`; increments `projection_version`.

**Flow F2 — Retire**
- Trigger: source status update to `retired` or source deletes (defensive fallback)
- Sets projection row `status = retired`

**Flow F3 — Publish Timestamp**
- Trigger: updates on `catalog_entry_public`
- If `status = published` and `published_at` is null, sets `published_at = now()`

**Flow F4 — Screenshot Alt Guard (task24)**
- Trigger: filter on `catalog_entry_public` `items.create`/`items.update`
- Rejects writes when any `screenshots[].alt` is missing or empty (WCAG AA)
- SEO fields (`meta_title`, `meta_description`, `og_image`, `tags`) are preserved across projection rebuilds

The hook uses optional columns (`projection_version`, `projection_updated_at`, `retired_at`) only when present, keeping automation functional with the current live schema.

### Optional Field Extensions (task24/task27)

`directus/extensions/v1/index.js` runtime-detects which optional columns exist (`getOptionalColumns`) and dynamically extends the SELECT. The response always contains the optional keys (`null` when the column is missing or the row has no value) — contract surface is stable before, during, and after schema migration.

Currently tracked as optional/curated:
- task24 (Release 1.2): `meta_title`, `meta_description`, `og_image`, `tags`
- task25 (Release 1.2): plugin classification — lifecycle (`last_release_version`, `last_release_date`, `release_cadence_days`, `maintenance_badge`, `is_deprecated`, `replacement_entry_id`), pricing (`pricing_model`, `is_open_source`, `price_range_eur`, `license_unit`, `trial_available`, `is_eledia_product`), GDPR (`stores_personal_data`, `privacy_api_implemented`, `data_transfer_outside_eu`, `gdpr_readiness`), maintainer (`maintainer` JSON public subset)
- task27 (Release 1.3): `runbot_demo_id`

`catalog-projection-hook` preserves all of these across rebuilds via the shared `CURATED_PROJECTION_COLUMNS` list — projection rebuilds from canonical sources never wipe curated content.

`website/public-catalog/src/lib/seo.ts` (task16) owns the SEO fallback chain on the consumer side; `app/layout.tsx` sets `metadataBase` from `NEXT_PUBLIC_SITE_URL`; detail page `generateMetadata` emits canonical, OG, and Twitter cards.

The Runbot CTA (task28) reads `runbot_demo_id` from the normalised detail response (`catalog-api.ts` trims whitespace and coerces empty strings to `null`) and renders a "Demo starten" link in the detail hero actions only when truthy. Link uses the new `.button-accent` style (accent-coloured outline) so it reads as a secondary CTA below the dominant Docs primary; `target="_blank"`, `rel="noopener"`, accessible name includes the plugin title.

Open follow-ups:
- task24: run `./directus/scripts/apply_seo_fields.sh directus-vps` → redeploy extensions → re-run smoke test.
- task27: apply `runbot_demo_id` column to live `catalog_entry_public` (and to canonical `plugin_component`/`product`) → redeploy extensions → re-run smoke test.
- task25: apply classification columns + new `plugin_maintainer` collection (Studio or schema snapshot diff) → redeploy `v1` + `catalog-projection-hook` → re-run smoke test → unblocks task26 (portal rendering, Agent B). Lifecycle / `maintainer` derivation from canonical FK/release history is a follow-up that lets those entries leave `CURATED_PROJECTION_COLUMNS` once derivation is reliable.

### Operational Tables (portal-private)

These tables back the `/v1/portal/*` endpoints and are not part of the public catalog projection. Both are created lazily by the `v1` extension on first use; creating the matching collections in Studio later just registers the existing table.

#### `installation` (task31, feat09)

| Field | Type | Required | Notes |
|---|---|---|---|
| `id` | UUID | Yes | Primary key, supplied by the caller (Runbot Onlineshop) |
| `label` | String (255) | Yes | Display name |
| `flavour` | Enum | Yes | `lms`, `workplace` |
| `moodle_version` | String (32) | Yes | e.g. `4.5` |
| `release_channel` | Enum | Yes | `lts`, `newest` |
| `profile` | Enum | Yes | `managed`, `self_hosted`, `demo` |
| `sla_level` | Enum | Yes | Current managed service level (`level_1`, `level_2`) |
| `user_tier` | Enum | Yes | Contract tier: `250`, `500`, `1000`, `2000` |
| `contact_email` | String | No | Format-checked when provided |
| `addon_bbb_enabled` | Boolean | Yes | BigBlueButton add-on active |
| `addon_solr_enabled` | Boolean | Yes | SOLR add-on active |
| `snapshot_status` | String (32) | Yes | Defaults to `current` |
| `created_at` | Timestamp | Yes | Server-set |
| `created_by` | String (64) | No | Resolved from `req.portalUser.id` (service-token user) |

Endpoint: `POST /v1/portal/installations` — see "Portal-Private Installation Endpoints" above.
Read fallback: `GET /v1/portal/installation/{id}` prefers a registered row; falls back to a deterministic mock when the row does not exist.

#### `installation_plugin` (task31 follow-up, mandatory linkage)

Persists the real plugin state per customer installation. This replaces the deterministic bootstrap behavior in `GET /v1/portal/installation/{id}/plugins` once rollout is complete.

| Field | Type | Required | Notes |
|---|---|---|---|
| `id` | UUID | Yes | Primary key |
| `installation_id` | UUID | Yes | FK -> `installation.id` |
| `frankenstyle` | String (128) | Yes | Runtime identifier from Moodle (`mod_forum`, `local_plugin`) |
| `plugin_component_id` | UUID | No | FK -> canonical `plugin_component.id` when a match exists |
| `product_id` | UUID | No | FK -> canonical `product.id` for product-style entries |
| `catalog_entry_id` | UUID/int | No | FK -> `catalog_entry_public.id` (public projection) |
| `installed_version` | String (64) | Yes | Installed plugin version |
| `status` | Enum | Yes | `installed`, `outdated`, `deprecated`, `removed` |
| `time_installed` | Timestamp | No | First detection/installation |
| `time_updated` | Timestamp | Yes | Last sync timestamp |

Mandatory 4-way linkage rule:
- Each row must always keep `installation_id` + `frankenstyle`.
- During sync, the resolver attempts to add canonical + projection links in this order: `plugin_component_id`/`product_id` and `catalog_entry_id`.
- The row remains valid even if canonical/projection IDs are temporarily null, but resolution is retried on every sync.

#### `portal_request`

Backs `GET /v1/portal/requests` and `POST /v1/portal/requests`. Schema: `id` (UUID), `installation_id`, `catalog_entry_id` (nullable), `request_type`, `message`, `status` (defaults to `open`), `created_at`, `created_by`.

### Database Indexes

- Unique: `plugin_component(component)`, `plugin_component(slug)`, `product(slug)`, `catalog_entry_public(slug)`
- Composite: `plugin_release(plugin_component_id, status, version_code DESC)`, `catalog_entry_public(status, entry_type, plugin_type)`
- Optional GIN index on `proven_summary`, `supported_versions` for heavy filter/search usage
- Operational: `portal_request(installation_id, created_at)` (already declared by lazy create), `installation(id)` PK only, `installation_plugin(installation_id, frankenstyle)` unique, `installation_plugin(installation_id, status)`, `installation_plugin(plugin_component_id)`, `installation_plugin(product_id)`, `installation_plugin(catalog_entry_id)`

### Directus Setup Checklist (condensed)

Phase 1: Shared enums (`draft`, `reviewed`, `published`, `retired`); UUID PKs; slug convention.
Phase 2: Create canonical collections in order: `plugin_component` → `plugin_release` → `product` → `product_component` → `plugin_review` → `plugin_review_dimension`.
Phase 3: Create `catalog_entry_public` with all fields including task24 SEO additions; create `catalog_entry_public_screenshot` sub-collection.
Phase 4: Configure roles and public policy (field allowlist matches contract).
Phase 5: Deploy `catalog-projection-hook` extension (F1–F4).
Phase 6: Apply indexes.
Phase 7: Import seed from `docs/seeds/catalog_seed_v1.json`.
Phase 8: Contract verification (search/detail/security checks).
Phase 9: Export snapshot → commit → `schema apply --dry-run` → apply.

Smoke test commands:
```bash
# Projection smoke test
./directus/scripts/catalog_smoke_test.sh https://directus.example.com <token> attendance-plus-pro

# Contract smoke test
BASE_URL=https://directus.example.com TOKEN=<token> INSTALLATION_ID=<uuid> \
  ./directus/scripts/v1_contract_smoke_test.sh
```

## Shared API Contract

Contract version: `v1` — locked for Release 1. Locked fields must not be changed silently. Additions allowed only as explicit optional extensions.

- Public base path: `/v1/catalog` — content type: `application/json`
- Portal-private base path: `/v1/portal` — service-token authenticated, server-side only

All public catalog endpoints return only `catalog_entry_public` rows with `status = published`.

### Endpoint 1: Public Catalog Search

`GET /v1/catalog/search`

Query parameters:

| Param | Type | Notes |
|---|---|---|
| `q` | string | Free-text search over title, teaser, tags |
| `entry_type` | enum | `plugin`, `product`, `bundle` |
| `plugin_type` | string | e.g. `mod`, `local`, `auth` |
| `proven_badge` | enum | `none`, `bronze`, `silver`, `gold` |
| `supported_moodle` | string | e.g. `4.3` |
| `page` | integer | Default `1` |
| `page_size` | integer | Default `20`, max `100` |
| `sort` | string | `title`, `-title`, `published_at`, `-published_at` |

Response shape:
```json
{
  "data": [{
    "id": "4c777f2c-...",
    "slug": "attendance-plus-pro",
    "title": "Attendance Plus Pro",
    "entry_type": "product",
    "teaser": "Enterprise attendance workflows for managed Moodle setups.",
    "plugin_type": null,
    "proven_badge": "silver",
    "supported_moodle": "4.1-4.4",
    "hero_asset": {"url": "https://cdn.example.com/.../hero.jpg", "alt": "Attendance Plus dashboard"}
  }],
  "meta": {"page": 1, "page_size": 20, "total": 1}
}
```

Locked search result fields: `id`, `slug`, `title`, `entry_type`, `teaser`, `plugin_type`, `proven_badge`, `supported_moodle`, `hero_asset`

### Endpoint 2: Public Catalog Detail

`GET /v1/catalog/{slug}`

Response shape:
```json
{
  "data": {
    "id": "4c777f2c-...",
    "slug": "attendance-plus-pro",
    "title": "Attendance Plus Pro",
    "description_public": "...",
    "screenshots": [{"url": "...", "alt": "Attendance report overview"}],
    "docs_url": "https://docs.example.com/attendance-plus-pro",
    "proven_summary": {"badge": "silver", "summary": "...", "reviewed_at": "2026-03-01"},
    "supported_versions": [{"channel": "moodle", "min": "4.1", "max": "4.4"}]
  }
}
```

Locked detail fields: `id`, `slug`, `title`, `description_public`, `screenshots`, `docs_url`, `proven_summary`, `supported_versions`

### Endpoint 3: Installation Context Overlay (portal-private)

`GET /v1/portal/overlay?installation_id=<uuid>&catalog_entry_id=<id>`

Locked overlay fields: `installation_id`, `catalog_entry_id`, `is_installed`, `compatibility_status`, `requestable`, `recommended`, `requires_upgrade_first`, `note`

Optional extension fields: `installed_version_summary`, `compatibility_note`

### Endpoint 4: Create Request (portal-private)

`POST /v1/portal/requests`

```json
{
  "installation_id": "f6b5b65c-...",
  "catalog_entry_id": 1,
  "request_type": "plugin_request",
  "message": "Please evaluate rollout in our staging environment."
}
```

Allowed `request_type` values: `plugin_request`, `feature_request`, `storage_request`, `consulting_request`

Minimum response fields: `id`, `installation_id`, `catalog_entry_id`, `request_type`, `message`, `status`, `created_at`

Note: `catalog_entry_id` currently uses integer IDs on live Directus; contract allows integer and UUID for forward compatibility.

### Portal-Private Installation Endpoints

`GET /v1/portal/installation/{installation_id}` — returns: `id`, `label`, `flavour`, `moodle_version`, `release_channel`, `profile`, `sla_level`, `user_tier`, `addon_bbb_enabled`, `addon_solr_enabled`, `snapshot_status`, `contact_email`. task31 (feat09): now reads from the real `installation` table when the installation has been registered via `POST /v1/portal/installations`; falls back to a deterministic Release-1 mock for unregistered IDs so existing portal flows stay green.

`GET /v1/portal/installation/{installation_id}/plugins` — returns array from `installation_plugin` with: `frankenstyle`, `display_name`, `installed_version`, `plugin_component_id`, `product_id`, `catalog_entry_id`, `proven_badge`, `status` (`installed|outdated|deprecated|removed`).

The endpoint is allowed to fall back to deterministic bootstrap data only while `installation_plugin` has no rows for the requested installation.

`POST /v1/portal/installations` (task31, feat09) — Runbot Onlineshop registration entry point.

```json
{
  "id": "f6b5b65c-8b9d-4a85-a2ec-863ff04af58c",
  "label": "Acme School Moodle",
  "flavour": "lms",
  "moodle_version": "4.5",
  "release_channel": "lts",
  "profile": "managed",
  "sla_level": "level_1",
  "user_tier": "500",
  "addon_bbb_enabled": true,
  "addon_solr_enabled": false,
  "contact_email": "admin@acme-school.example"
}
```

- Auth: service token (same `/v1/portal/*` Bearer guard as the existing endpoints).
- `flavour` allowlist: `lms`, `workplace`.
- `release_channel` allowlist: `lts`, `newest`.
- `profile` allowlist: `managed`, `self_hosted`, `demo`.
- `sla_level` allowlist: `level_1`, `level_2`.
- `user_tier` allowlist: `250`, `500`, `1000`, `2000`.
- `contact_email` is optional but format-checked when provided.
- Idempotent on `id`: `409 conflict` if the UUID is already registered.
- Response `201` returns: `id`, `label`, `flavour`, `moodle_version`, `release_channel`, `profile`, `sla_level`, `user_tier`, `addon_bbb_enabled`, `addon_solr_enabled`, `contact_email`, `snapshot_status` (defaults to `current`), `created_at`.
- Backing table `installation` is created lazily on first call (same pattern as `portal_request`); creating the matching collection in Studio later just registers the existing table.

#### Agent A → Agent B handoff (task34 + task36 API)

These endpoints are the portal-writable surface for Release 1.3. All three live under `/v1/portal/*` and require the standard Bearer service-token. Lazy-table pattern: `installation`, `installation_plugin`, and `installation_change_event` are created on first hit.

##### `POST /v1/portal/installations/snapshot` (task34 — full upsert)

Upserts the `installation` row by `id`. Accepts the full installation payload plus optional telemetry in one call. `last_sync_at` defaults to server-now on every write; pass a value explicitly to preserve a client timestamp.

Request:

```json
{
  "id": "f6b5b65c-8b9d-4a85-a2ec-863ff04af58c",
  "label": "Acme School Moodle",
  "flavour": "lms",
  "moodle_version": "4.5",
  "release_channel": "lts",
  "profile": "managed",
  "sla_level": "level_1",
  "user_tier": "500",
  "addon_bbb_enabled": true,
  "addon_solr_enabled": false,
  "contact_email": "admin@acme-school.example",
  "user_count_active_30d": 834,
  "user_count_total": 1247,
  "storage_used_gb": 12.4,
  "storage_quota_gb": 50.0,
  "storage_utilization_percent": 24.8,
  "health_overall": "green",
  "last_sync_at": "2026-04-19T18:30:00Z"
}
```

- Enum allowlists are the same as register (`flavour`, `release_channel`, `profile`, `sla_level`, `user_tier`, `health_overall` ∈ `{green, amber, red}`).
- Numeric telemetry fields (`user_count_*`, `storage_*`) must be non-negative when provided.
- `201 Created` on insert, `200 OK` on update.
- Response body: the complete saved `installation` row (same shape as `GET /v1/portal/installation/{id}`).

##### `POST /v1/portal/installations/{installation_id}/plugins/sync` (task34 — bulk plugin upsert)

Bulk upsert of the installation's plugin state. Each row is keyed by `(installation_id, frankenstyle)`; `time_updated` is stamped server-side. Safe to retry — resend the same payload and rows will be updated in place.

Request:

```json
{
  "plugins": [
    {
      "frankenstyle": "mod_attendanceplus",
      "installed_version": "2026030100",
      "status": "installed",
      "time_installed": "2025-11-04T09:00:00Z"
    },
    {
      "frankenstyle": "local_eledia_exam2pdf",
      "installed_version": "2026041800",
      "status": "installed",
      "plugin_component_id": "4",
      "catalog_entry_id": "7"
    }
  ]
}
```

- Required per row: `frankenstyle` (≤128 chars), `installed_version` (≤64 chars), `status` ∈ `{installed, outdated, deprecated, removed}`.
- 4-way linkage resolution when caller omits IDs: the endpoint looks up `plugin_component.component = frankenstyle`, and then resolves `catalog_entry_id` from `catalog_entry_public` where `source_type='plugin_component' AND source_id = <resolved component id>`. Unresolved links stay `null` and will be retried on the next sync.
- Invalid rows are skipped (not aborting the batch) and reported in `skipped_rows`.
- Response `200 OK`:

```json
{
  "data": {
    "synced": 2,
    "skipped": 0,
    "skipped_rows": []
  }
}
```

`GET /v1/portal/installation/{id}/plugins` picks up the real rows immediately after the first sync for that installation.

##### `POST /v1/portal/installations/{installation_id}/events` (task36 — idempotent event append)

Append-only log of installation-level change events. The caller supplies `event_id`; duplicates are swallowed so retries are safe.

Request:

```json
{
  "event_id": "runbot-2026-04-19T18:30Z-tier_changed",
  "event_type": "tier_changed",
  "payload": {"from": "250", "to": "500"},
  "actor_type": "runbot",
  "actor_id": "runbot-main",
  "happened_at": "2026-04-19T18:30:00Z"
}
```

- `event_type` allowlist: `plugin_installed`, `plugin_updated`, `plugin_removed`, `tier_changed`, `addon_enabled`, `addon_disabled`, `storage_changed`.
- `happened_at` is ISO-8601; `received_at` is server-set.
- `payload` is free-form JSON (stored as text) — callers own the schema per `event_type`.
- `201 Created` on first accept; `200 OK` with `duplicate: true` when `(installation_id, event_id)` already exists.
- Side effect: every fresh-accepted event bumps `installation.last_event_at = happened_at`, so readers can page by freshness without scanning the change log.

Response (fresh insert):

```json
{
  "data": {
    "id": "7a4c4f9e-74a7-4e7f-8f31-4d98fef3a1b8",
    "installation_id": "f6b5b65c-8b9d-4a85-a2ec-863ff04af58c",
    "event_id": "runbot-2026-04-19T18:30Z-tier_changed",
    "event_type": "tier_changed",
    "happened_at": "2026-04-19T18:30:00.000Z",
    "received_at": "2026-04-19T18:30:05.123Z",
    "duplicate": false
  }
}
```

### Link-Based Plugin Intake (proposed R1.3)

Goal: ingest real canonical plugin metadata by submitting one or more source links (GitHub repo URLs and Moodle plugin-db URLs) and upserting into `plugin_component` plus optional `plugin_release` enrichment.

#### Endpoint proposal

`POST /v1/portal/plugins/intake-links`

Request:

```json
{
  "dry_run": false,
  "links": [
    "https://github.com/moodlehq/moodle-mod_forum",
    "https://moodle.org/plugins/mod_forum"
  ]
}
```

- Auth: service token (same Bearer guard as other `/v1/portal/*` write endpoints).
- `dry_run=true` validates and resolves payloads without writing.
- Source detection by URL host/path:
  - `github.com/<owner>/<repo>` -> source `github`
  - `moodle.org/plugins/<frankenstyle>` -> source `moodle_plugins_db`

Response (`200 OK`):

```json
{
  "data": {
    "processed": 2,
    "created": 1,
    "updated": 1,
    "skipped": 0,
    "items": [
      {
        "link": "https://moodle.org/plugins/mod_forum",
        "source": "moodle_plugins_db",
        "frankenstyle": "mod_forum",
        "plugin_component_id": "8d9c...",
        "action": "updated"
      }
    ]
  }
}
```

#### Extracted core fields (MVP)

- From Moodle plugin DB link:
  - `component` (`frankenstyle`, canonical key)
  - `plugin_type` (derived from prefix, e.g. `mod`, `local`)
  - `display_name`
  - `teaser` / short summary
  - `docs_url` (plugin page URL)
  - optional latest version hints for `plugin_release`
- From GitHub link:
  - `docs_url` fallback (repo URL when no better docs URL exists)
  - `owner_team` candidate (repo owner)
  - optional enrichment candidates for later phase: stars, forks, last commit, license

#### Write model and idempotency

- Upsert key: `plugin_component.component` (unique).
- If only GitHub link is provided and no reliable `frankenstyle` can be derived, return `validation_error` and skip item.
- If both links are present and disagree on `frankenstyle`, item is skipped with reason `source_mismatch`.
- Never delete rows in intake flow; only insert/update additive fields.

#### Quality and safety rules

- Per-item isolation: one bad link must not abort the full batch.
- Store import audit in logs with source URL and normalized `frankenstyle`.
- Rate-limit external calls and use short timeouts; return partial success payload on upstream failures.
- Preserve editorial ownership: lifecycle/commercial/GDPR fields stay manual unless explicitly mapped later.

#### Rollout sequence

1. Add endpoint with `dry_run` and parser only.
2. Enable write path to `plugin_component` upserts.
3. Add optional `plugin_release` latest-version enrichment from Moodle plugin DB.
4. Add async GitHub enrichment job (stars/forks/license/activity) as a separate non-blocking task.

### Error Model

```json
{"error": {"code": "not_found", "message": "Catalog entry not found"}}
```

Recommended error codes: `not_found`, `validation_error`, `rate_limited`, `forbidden`, `internal_error`

### Caching and Consistency

- Search: `Cache-Control: public, max-age=60, stale-while-revalidate=300`
- Detail: `Cache-Control: public, max-age=120, stale-while-revalidate=600`
- Overlay: short TTL (`<= 120s`)
- Include `ETag` headers for public cache revalidation.

### Security and Data-Minimization Rules

- No internal review notes or evidence in any response.
- Customer-specific installation context allowed only on `/v1/portal/*`.
- `/v1/portal/*` must not be exposed publicly.
- Internal IDs outside locked contract fields must never leak.

### SEO Metadata (optional, task24/Release 1.2)

Search result optional fields:

| Field | Type | Fallback when null |
|---|---|---|
| `meta_description` | string (150–160 chars) | `teaser` |

Detail optional fields:

| Field | Type | Fallback when null |
|---|---|---|
| `meta_title` | string | `title` |
| `meta_description` | string | `teaser` else first 155 chars of `description_public` |
| `og_image` | `{url, alt}` | `hero_asset` |
| `tags` | string array | `[]` |

`screenshots[].alt` is always populated; empty strings are not allowed (write-time enforcement).

### Runbot Demo Link (optional, task27/Release 1.3)

Search result and detail optional field:

| Field | Type | Notes |
|---|---|---|
| `runbot_demo_id` | string | Key into Runbot's `configs.json`. Consumer deep-links to `https://demo.eledia.ai?demo=<runbot_demo_id>` when non-null. No CTA when null (graceful fallback per feat07). |

Always present in the response (key emitted with `null` when the column is missing or unfilled). Runbot remains the authoritative system for available demos; SSOT only stores the link key.

### Plugin Classification (optional, task25/Release 1.2)

Lifecycle, pricing, GDPR readiness, and maintainer attribution. All fields nullable; consumers render neutral placeholders when null. Always present in the response (key emitted with `null` until the column or content ships).

Search result optional fields (filterable):

| Field | Type | Values |
|---|---|---|
| `pricing_model` | enum | `free`, `freemium`, `paid_onetime`, `paid_subscription`, `paid_support_only` |
| `maintenance_badge` | enum | `actively_maintained`, `looking_for_maintainer`, `orphaned`, `unknown` |
| `last_release_date` | date | ISO date of latest published release |
| `is_open_source` | boolean | |
| `gdpr_readiness` | enum | `green`, `amber`, `red`, `unknown` |
| `is_eledia_product` | boolean | Internal flag, public-projection-safe |

Detail optional fields (in addition to all search fields):

| Field | Type | Notes |
|---|---|---|
| `maintainer` | object `{name, type, is_moodle_certified_partner}` | Public subset; **never** carries contact details |
| `price_range_eur` | enum | `<100`, `100-500`, `500-2000`, `>2000`, `poa` |
| `license_unit` | enum | `per_site`, `per_user`, `per_installation`, `enterprise` |
| `stores_personal_data` | enum | `none`, `pseudonymised`, `identifying` |
| `data_transfer_outside_eu` | boolean | |
| `privacy_api_implemented` | boolean | |
| `is_deprecated` | boolean | |
| `replacement_entry_id` | string | Slug or UUID of replacement entry; only meaningful when `is_deprecated = true` |
| `release_cadence_days` | integer | Median days between published releases |
| `trial_available` | boolean | |
| `last_release_version` | string | Human version string of latest published release |

Consumer rendering rules:
- `gdpr_readiness` → render Ampel/badge with the four states; `unknown` styled as neutral.
- `is_deprecated = true` → render deprecation banner; if `replacement_entry_id` is set, link to that catalog entry.
- `maintainer.is_moodle_certified_partner = true` → certified-partner badge near maintainer name.
- `pricing_model = free` and `is_open_source = true` → render "Free / OSS" tag.
- Missing values → silent fallback (no placeholder text); rendering layer must never fabricate values.

Public-projection guarantee: vendor contact data (`contact_email`, `contact_phone`, `homepage` from `plugin_maintainer`) **must never** appear on `/v1/catalog/*`. The contract is enforced by the v1 endpoint allowlist (only the `maintainer` JSON subset is selected).

---

## Agent A → Agent B Handover Contract

Locked and binding for Release 1. Primary reference for portal implementation.

### Scope Boundary

- Public website and shared catalog use `/v1/catalog/*`
- Portal-specific context and requests use `/v1/portal/*` (server-side only)

### Stability Rules

- Locked fields must not be renamed or removed in Release 1
- Portal rendering logic may assume key presence for all locked fields
- Any contract change requires updating: `03-dev-doc.md`, `04-tasks.md`, relevant tests in `05-quality.md`

### Release 1.2 Additions (non-breaking)

Public detail may also include: `meta_title`, `meta_description`, `og_image`, `tags` (task24 SEO).
Public search may also include: `meta_description`, `tags`.
Fallback chain defined in SEO metadata section above.

task25 plugin classification (Release 1.2):
- Public search may also include: `pricing_model`, `maintenance_badge`, `last_release_date`, `is_open_source`, `gdpr_readiness`, `is_eledia_product`.
- Public detail may also include all search fields plus `maintainer`, `price_range_eur`, `license_unit`, `stores_personal_data`, `data_transfer_outside_eu`, `privacy_api_implemented`, `is_deprecated`, `replacement_entry_id`, `release_cadence_days`, `trial_available`, `last_release_version`.
- Rendering rules in "Plugin Classification" section above.
- `maintainer` carries the public subset only — vendor contact data stays internal.

### Release 1.3 Additions (non-breaking, task27/feat07)

Public detail and search may also include: `runbot_demo_id` (string, nullable).
Consumer behaviour defined in "Runbot Demo Link" section above.

## Public Website Foundation

Stack: **Next.js App Router** (clar01 resolved 2026-04-18).
Scaffold: `website/public-catalog/`

Routes:
- `/` — landing page with catalog entry point
- `/catalog` — search and filter list
- `/catalog/[slug]` — public entry detail page
- `/proven` — Proven badge explainer

Data source: shared API contract only — no direct reads from canonical Directus collections.

### Catalog List (`/catalog`)

Card content: `hero_asset`, `title`, `teaser`, `entry_type`, `plugin_type`, `proven_badge`, `supported_moodle`

Active filters: `entry_type`, `plugin_type`, `proven_badge` (filter `supported_moodle` and `page_size` removed in layout v1). Search field is a dedicated first-row control. Filter bar is always visible.

### Detail Page (`/catalog/[slug]`)

Zones: hero/title block, `description_public`, screenshots, `docs_url`, Proven summary block, `supported_versions` block, not-found state for unknown slug.

### Layout v1 Contract (implemented 2026-04-18)

- Tokens: `#194866` primary, `#f98012` accent, `#f3f5f8` background
- Shape: `8px` buttons/inputs, `12px` structural containers, `pill` only for tags
- Zone A = page identity and context (`h1`, intro, support actions)
- Zone B = warm info strip for result status and reset action
- Cards: structure-first — media, metadata block, action strip
- Primary CTA: one dominant action per card/section

### Deployment and Operations

CDN in front of API and website. Cache invalidation by TTL + optional purge on publish events.
Availability target: `>= 99.5%` for read path.

### Release 1 Acceptance Checks

- Only published entries are visible
- Search and detail use locked shared fields
- No customer-specific data appears on the website
- Proven output is aggregate-only

## SEO and projection extension (task24, Release 1.2)

The `catalog_entry_public` projection accepts four optional SEO columns: `meta_title`, `meta_description`, `og_image` (`{url, alt}`), `tags` (string array). All are nullable on the wire; the website applies the fallback chain documented in `docs/03-dev-doc.md → "Shared API Contract"` → "SEO metadata".

Implementation pattern (resilient to deploy ordering):
- `directus/extensions/v1/index.js` runtime-detects which SEO columns exist (`getSeoColumns`) and dynamically extends the SELECT. The response always contains the SEO keys (`null` when columns or content are missing) so that the contract surface is stable before, during, and after the schema migration.
- `directus/extensions/catalog-projection-hook/index.js` preserves curated SEO values across rebuilds: when the projection is recomputed from canonical sources, it reads the existing row and re-injects the SEO fields rather than wiping them.
- Same hook adds a `filter` on `catalog_entry_public` `items.create`/`items.update` that rejects writes with empty `screenshots[].alt` (Flow F4, supports task17 / WCAG AA).
- `directus/scripts/v1_contract_smoke_test.sh` asserts SEO key **presence** (value may be `null`) instead of exact-key equality, so a deploy without the columns still passes.
- `website/public-catalog/src/lib/seo.ts` (task16) owns the fallback chain on the consumer side; `app/layout.tsx` sets `metadataBase` from `NEXT_PUBLIC_SITE_URL`; `app/catalog/[slug]/page.tsx` `generateMetadata` emits canonical, OG, and Twitter cards based on the resolved metadata. The chain works today against the pre-migration v1 surface (which returns SEO keys as `null`) and will surface populated content automatically post-migration.

Open follow-ups (task24):
- Apply live schema: `./directus/scripts/apply_seo_fields.sh directus-vps` — adds `meta_title`, `meta_description`, `og_image`, `tags` columns + Studio field metadata and restarts Directus.
- Redeploy `v1` + `catalog-projection-hook` against `directus.eledia.ai` and re-run `v1_contract_smoke_test.sh`.

## Portal Blueprint — local_customerportal

Current: plugin version `2026041802`, maturity `MATURITY_ALPHA`, release `0.2.0` (Release 1.1).

### Information Architecture

Navigation entry **"Kundenportal"** via `\core\hook\navigation\primary_extend`. Only users with `local/customerportal:view` see this entry.

Tab bar on every portal page: `Dashboard | Meine Installation | Meine Plugins | Katalog | Anfragen`

| Route | File | Capability | Description |
|---|---|---|---|
| `/local/customerportal/` | `index.php` | `view` | Dashboard |
| `/local/customerportal/installation.php` | `installation.php` | `view` | Technische Stammdaten |
| `/local/customerportal/myplugins.php` | `myplugins.php` | `view` | Installierte Plugins |
| `/local/customerportal/catalog.php` | `catalog.php` | `view` | Öffentlicher Katalog |
| `/local/customerportal/plugin.php?slug=` | `plugin.php` | `view` | Plugin-Detail mit Overlay |
| `/local/customerportal/requests.php` | `requests.php` | `createrequest` | Anfragen |

Dashboard shows: installation short-info, installed plugin count (ampel), open requests count, up to 3 recommended catalog entries (overlay `recommended=true`), health ampel + top-5 issues, storage KPIs.

### Plugin File Structure

```
local/customerportal/
├── version.php, lib.php, settings.php, styles.css
├── index.php, installation.php, myplugins.php, catalog.php, plugin.php, requests.php
├── classes/
│   ├── hook_callbacks.php
│   ├── form/request_form.php
│   ├── local/
│   │   ├── api_client.php
│   │   ├── catalog_service.php
│   │   ├── installation_service.php
│   │   ├── request_service.php
│   │   ├── site_info_service.php
│   │   └── health_service.php        (Release 1.1)
│   ├── task/sync_pending_requests_task.php
│   └── privacy/provider.php
├── db/
│   ├── access.php, install.xml, upgrade.php, tasks.php, hooks.php, caches.php
├── templates/
│   ├── dashboard.mustache, installation_view.mustache, plugin_list.mustache
│   ├── catalog_list.mustache, catalog_detail.mustache, catalog_overlay_block.mustache
│   ├── request_list.mustache, nav_tabs.mustache
└── lang/
    ├── en/local_customerportal.php
    └── de/local_customerportal.php
```

### Class Responsibilities

**`api_client`** — all outgoing HTTP via `\core\http_client` (Guzzle, PSR-7); Bearer-token auth from plugin settings; HTTP 404 → `['data' => []]` (graceful degradation); `http_build_query($params, '', '&')` with explicit `'&'` separator (Moodle overrides `arg_separator.output` to `&amp;`).

**`catalog_service`** — `search(array $filters)` → `GET /v1/catalog/search`; `get_detail($slug)` → `GET /v1/catalog/{slug}`; cache `catalogsearch` TTL 60s, `catalogdetail` TTL 120s.

**`installation_service`** — `get_installation()`, `get_installed_plugins()`, `get_overlay($catalog_entry_id)`; caches `installationdata` TTL 300s, `overlaydata` TTL 120s; UUID-based keys wrapped with `md5()`.

**`request_service`** — `create(array $payload)` → `POST /v1/portal/requests`; `list_for_installation()` → `GET /v1/portal/requests?installation_id=`.

**`site_info_service`** (Release 1.1) — `get_user_stats()`, `get_users_online_count()` (5-min window), `get_course_count()`, `get_moodle_release()`, `get_cron_info()`, `get_storage_stats()` (dedup-unique filesize + DB-driver-specific size, cached TTL 600s), `get_environment_info()` (PHP version, memory, upload, DB platform+version, maintenance flag).

**`health_service`** (Release 1.1) — wraps `\core\check\manager::get_checks()` for `status`, `security`, `performance`; aggregates `{totals, overall, groups, issues}`; cached TTL 300s; exceptions per check caught → counted as `unknown`.

### Database Schema

Table `local_customerportal_request`:
- `id` (int, PK), `installation_id` (char 36), `catalog_entry_id` (char 64, nullable), `request_type` (char 64), `message` (text), `userid` (int, FK user), `status` (char 32, default `pending`), `directus_id` (char 36, nullable), `timecreated` (int), `timemodified` (int)
- Index: `installation_status (installation_id, status)`

Request status lifecycle: `pending` → `synced` (after sync task) → Directus manages: `in_review`, `approved`, `rejected`, `done`.

### Overlay Logic

```
plugin.php:
  1. catalog_service → GET /v1/catalog/{slug}       (public, cached)
  2. installation_service → GET /v1/portal/overlay  (private, auth, cached)
  3. merge → catalog_detail.mustache + catalog_overlay_block.mustache
```

Overlay block render rules:

| State | Display |
|---|---|
| `is_installed = true` | Badge "Installiert" + version |
| `compatibility_status = incompatible` | Warning + `compatibility_note` |
| `requires_upgrade_first = true` | Upgrade-required notice |
| `recommended = true` | Badge "Empfohlen" |
| `requestable = true` | Button → requests.php with prefilled `catalog_entry_id` |

### Capabilities

| Capability | Type | Default |
|---|---|---|
| `local/customerportal:view` | read | all authenticated users, managers |
| `local/customerportal:createrequest` | write | all authenticated users, managers |
| `local/customerportal:viewall` | read | managers only |

`require_login()` on all portal pages.

### Caching

```php
'catalogsearch'    => TTL 60s,   simplekeys: false
'catalogdetail'    => TTL 120s
'installationdata' => TTL 300s
'overlaydata'      => TTL 120s
'healthoverview'   => TTL 300s   (health_service)
'storagestats'     => TTL 600s   (site_info_service)
```

All UUID-based cache keys are `md5()`-normalized (`simplekeys: true` forbids `-`).

### Scheduled Task

`sync_pending_requests_task` — runs every 5 minutes; sends locally stored requests (`status=pending`) to Directus; marks as `synced` or `error`.

### Navigation Hook

```php
$hook->get_primaryview()->add(
    get_string('pluginname', 'local_customerportal'),
    new \moodle_url('/local/customerportal/index.php'),
    \navigation_node::TYPE_CUSTOM,
    null,
    'local_customerportal'
);
```

Must use scalar parameters only — no `navigation_node` objects, no `pix_icon` objects. Boost renders primary nav into Mustache context and calls `__toString()`, causing "could not be converted to string" if objects are passed.

### Design System (LernHive)

Scoped to `.path-local-customerportal` via `styles.css` (auto-loaded by Moodle).

- **Zone 0** — Moodle page heading: uniform "Customer Portal" on all subpages
- **Zone A** — plugin nav bar, `cp-zone-a`: 3px primary border-top, sticky, edge-to-edge bleed
- **Zone B** — context info bar, `cp-zone-b`: light-accent, KPI stats (dashboard + installation)
- **Components** — `cp-card`, `cp-kpi-card`, `cp-tag`, `cp-table`, `cp-stats-card`, `cp-btn`, `cp-empty`, `cp-status`, `cp-alert`, `cp-form-wrap`

Design tokens: `--cp-primary` (#194866), `--cp-accent` (#f98012), `--cp-bg` (#f3f5f8), `--cp-radius` (12px cards), `--cp-radius-sm` (8px buttons).

### Language Strings

Own strings: `lang/en/local_customerportal.php`, `lang/de/local_customerportal.php`.

Sourced from Moodle core (not redefined in plugin): `search`, `never`, `cancel`, `courses`, `profile`, `version`, `date`. Form cancel button: auto-supplied by `add_action_buttons()`.

Mustache: `{{#str}} search {{/str}}` (no component argument for core strings).

### Security Checklist

- `require_login()` on every portal page
- `require_capability('local/customerportal:view', ...)` before any output
- `require_sesskey()` before form processing
- No direct passthrough of URL parameters into API calls
- API token never exposed in HTML or client-side code
- `required_param()` / `optional_param()` for all input
- SQL: `{tablename}` notation, parameterized queries only

### Implementation Deviations vs. Blueprint

| Topic | Baseline | Actual | Reason |
|---|---|---|---|
| HTTP client | generic | `\core\http_client` (Guzzle) | `\curl` not autoloaded Moodle 5.x |
| 404 handling | unspecified | `['data' => []]` | graceful degradation |
| Cache keys | UUID-based | `md5()`-normalized | `simplekeys: true` forbids `-` |
| Active users | unspecified | 12 months (365 days) | meaningful customer metric |
| `classes/output/` | planned | not created | page controllers build template data directly |
| Page heading | per-page | uniform "Customer Portal" | consistent portal frame |
| `db/upgrade.php` | not in baseline | savepoint `2026041801` | covers pre-install installations |
| Lang strings | all plugin-own | 7 from core | no redundant translations |

### Open Decisions

| Topic | Release 1 assumption | Clarification needed |
|---|---|---|
| Auth strategy | Direct Directus API call with service token | If API facade desired, swap `api_client.php` only |
| Overlay data maintenance | Directus team maintains `catalog_entry_installation_context` manually | Automation is Phase 2 |
| Multi-installation | One Moodle = one `installation_id` | Extension needed if one Moodle manages multiple installations |
| Request sync strategy | Scheduled task every 5 min | Can switch to synchronous if Directus is reliable enough |

## Plugin Data Importer (Concept — Post-R1.2)

Status: draft concept, not yet scheduled. Deployed as Directus extension `plugin-importer`.

### Goal

Pull plugin metadata from external sources (moodle.org, GitHub/GitLab, repo file scan) into Directus SSOT so reviewers edit on top of pre-filled data. Nothing goes public without an editorial pass. No code eval from fetched repos.

### Data Sources

- **moodle.org** — `https://download.moodle.org/api/1.3/pluginfo.php?frankenstyle=<fs>` (structured JSON, no auth, 1 req/plugin/sync)
- **GitHub REST** — `/repos/{owner}/{repo}` (stars, license, pushed_at), `/releases` (cadence), `/contributors`
- **GitLab REST** — equivalent endpoints at `/api/v4/projects/{id}`
- **File scan** — raw-file fetch of `version.php`, `db/install.xml`, `db/access.php`, `classes/privacy/provider.php`, `lang/*/`, `LICENSE`. Parse `version.php` via regex/AST — never `include`/`require`.

Security: HTTPS only; URL allowlist (`moodle.org`, `github.com`, `api.github.com`, `raw.githubusercontent.com`, `gitlab.com`, `api.gitlab.com`, configurable on-prem hosts). File scan uses raw-content endpoint only — no shell-out to `git clone`.

### Storage Model

New collection **`plugin_source_snapshot`**: `id`, `plugin_component` (FK), `source_type` (enum: `moodle_org`, `github`, `gitlab`, `file_scan`), `source_url`, `fetched_at`, `fetch_status`, `raw_payload` (JSON), `parsed_fields` (JSON), `content_hash` (sha256). Accumulates; latest per `(plugin_component, source_type)` is current. Retention: keep latest 5 per source type.

New columns on **`plugin_component`**: `source_moodle_org_slug`, `source_repo_url`, `import_last_run_at`, `import_last_status`, `import_override_fields` (string[]).

**Override lock**: when a reviewer manually edits an auto-fetched field, importer must not overwrite it until the reviewer releases the lock. Lock stored per-field in `import_override_fields`.

### Importer Architecture

```
directus/extensions/plugin-importer/
├── src/
│   ├── fetchers/ (moodle_org, github, gitlab, file_scan)
│   ├── mappers/ (per source, pure functions)
│   ├── merge.ts  (field precedence, honors override locks)
│   ├── scheduler.ts
│   └── endpoints/refresh.ts  (POST /items/plugin_component/:id/refresh)
```

Triggers: manual (Studio button), scheduled (nightly cron), optional webhook (post-R1.2).
Rate limits: moodle.org ≤ 1 req/s, GitHub ≤ 30 req/min unauthenticated / ≤ 100 req/min with PAT. Exponential backoff on 429/5xx. Skip no-op via `content_hash`.

---

## Deployment

Universal deploy flow for local OrbStack environment. Reference: `scripts/deploy-moodle-plugin.sh`.

### Standard Workflow

```bash
cd <repo-path>
bash scripts/deploy-moodle-plugin.sh --type <type> --name <name> --repo <repo-path>
# Optional flags: --verify --marker "DEPLOY_MARKER" --precheck
```

### Parameters

| Flag | Description |
|---|---|
| `--type <plugin-type>` | Moodle plugin type: `local`, `mod`, `block`, `tool`, ... |
| `--name <plugin-name>` | Plugin shortname |
| `--repo <repo-path>` | Repository root path |
| `--container <name>` | Docker container name (default: `demo-webserver-1`) |
| `--mount-root <path>` | Host-side mount root for Moodle plugins |
| `--skip-upgrade` | Skip upgrade step |
| `--verify` | Run marker verification after deploy |
| `--marker <text>` | Marker text for verification |
| `--precheck` | Run `bin/precheck.sh` after deploy |

### Environment Paths

- Plugin target: `~/demo/site/moodle/public/<type>/<name>/`
- Moodle CLI: `/var/www/site/moodle/admin/cli/`
- `docker exec` commands must run as `www-data`
- `rsync` always runs on the host, not inside the container

### Workflow Rationale

1. `bin/sync-mirror.sh` — creates clean `.deploy/` copy with correct release files
2. `rsync -a --delete` — removes deleted files in target
3. `upgrade.php` — required after structure/version changes
4. `purge_caches.php` — clears Moodle caches (classes, Mustache, lang strings)
5. OPcache reset — removes stale bytecode

---

## Constraints

- Release 1 has no Odoo dependency
- Release 1 has no checkout
- public and customer-specific data must stay separated
- portal must not maintain a duplicate catalog model
