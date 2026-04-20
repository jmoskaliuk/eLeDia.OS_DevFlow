# Quality

## Meta

This document tracks quality, tests, and defects.

It contains:
- bugs (`bugXX`)
- tests (`testXX`)
- quality risks
- verification results

Do not include:
- new ideas
- planning
- implementation details

---

## Quality Risks

### risk01 Catalog and portal drift apart
If website and portal consume different contracts, the same catalog entry may behave differently across surfaces.

### risk02 Public/private data leakage
If public catalog projections are not separated cleanly from internal data, customer-specific or internal review data could leak.

### risk03 Portal becomes a second catalog
If installation-specific context is stored directly in portal-specific catalog records, maintenance complexity will increase.

### risk04 Request flow is overdesigned too early
If Release 1 tries to support commercial ordering too early, scope may become unstable.

---

## Bugs

### bug01 Contract endpoints unavailable on live Directus
Severity: major
Status: closed (fixed 2026-04-18)

`local_customerportal` expects `/v1/catalog/*` and `/v1/portal/*` endpoints.
Root cause was extension packaging/path mismatch (`/extensions/endpoints/v1` not loaded by Directus v11 loader).
Fix: deploy top-level extension package `directus/extensions/v1` with manifest.
Verification: live smoke test `directus/scripts/v1_contract_smoke_test.sh` passed on `directus.eledia.ai`.

### bug02 Navigation hook leaked navigation_node object into Boost template
Severity: major
Status: closed (fixed 2026-04-18)

Creating the portal primary nav entry via `navigation_node::create()` with a `pix_icon` argument and passing the resulting object into `->add()` caused "Object of class core\\navigation\\navigation_node could not be converted to string" under the Boost theme.
Fix: call `$hook->get_primaryview()->add()` directly with scalar parameters (title, url, type, icon-name string).

### bug03 Cache keys rejected for containing dashes (UUID)
Severity: major
Status: closed (fixed 2026-04-18)

Cache definitions with `simplekeys: true` accept only `[A-Za-z0-9_]`. Installation UUIDs contain dashes, causing "Cache definition requires simple keys" on every portal render.
Fix: wrap UUID-based cache keys with `md5()` in `installation_service` (applies to `install_*`, `plugins_*`, `overlay_*`).

### bug04 Class 'curl' not found
Severity: major
Status: closed (fixed 2026-04-18)

`api_client` called `new \curl()`, but `\curl` lives in `lib/filelib.php` and is not autoloaded in Moodle 5.x, so the portal threw on first API call.
Fix: rewrite `api_client` to use `\core\http_client` (Guzzle-based, fully autoloaded). Converted header format from string-list to associative array. Introduced `\Psr\Http\Message\ResponseInterface`-based response parsing.

### bug05 Missing table local_customerportal_request
Severity: major
Status: closed (fixed 2026-04-18)

Plugin installations that predated the introduction of `local_customerportal_request` in `install.xml` hit "Table doesn't exist" on the Requests page.
Fix: added `db/upgrade.php` with savepoint `2026041801` that creates the table if missing; bumped `version.php`.

### bug06 Missing lang string request_status_open
Severity: minor
Status: closed (fixed 2026-04-18)

Directus returns request status `open` but the plugin only knew `pending`, `synced`, `error`.
Fix: added `$string['request_status_open']`, added `status_open` boolean to the PHP normalization, added `{{#status_open}}` branch in the template.

### bug07 Form class moodleform not found
Severity: major
Status: closed (fixed 2026-04-18)

`request_form` extends `\moodleform` but that class is not part of Moodle's class autoloader.
Fix: `require_once($CFG->libdir . '/formslib.php')` in the form file, after the `namespace` declaration.

### bug08 api_client produced URLs with HTML-encoded separators
Severity: major
Status: closed (fixed 2026-04-18)

`api_client::get()` and `catalog_get()` built query strings via `http_build_query($params)` without specifying the separator. Moodle overrides `arg_separator.output` to `&amp;` (for safe HTML rendering), so the resulting URL became `...?installation_id=X&amp;catalog_entry_id=Y`. Directus then saw one merged parameter with value `X&amp;catalog_entry_id=Y`, the real `catalog_entry_id` never arrived, and the endpoint rejected the request with `HTTP 400 "catalog_entry_id must be numeric or UUID"`.

Fix: pass `'&'` explicitly as the third argument — `http_build_query($params, '', '&')` — in both `catalog_get()` and `get()`. Symptom had been hidden because UUIDs passed as the first parameter still looked valid on their own.

### bug09 catalog_service cache key contained dashes from slug
Severity: minor
Status: closed (fixed 2026-04-18)

`catalog_service::get_detail()` used `'detail_' . $slug` as the cache key. Slugs like `attendance-plus-pro` contain dashes, which are forbidden by `simplekeys: true` caches. Hitting the plugin detail page threw "Cache definition requires simple keys".
Fix: wrap the slug with `md5()`, same pattern as `install_*`, `plugins_*`, `overlay_*` keys (bug03).

### bug10 Release 1.2 Plus — Moodle-Plugin-Code fehlerhaft abgelegt und teilweise nicht lauffähig
Severity: major (rollout-blocker für task35 + Plugin-Teil task36)
Status: open (diagnosed 2026-04-19) — implementation fixes move to Claude on 2026-04-20; Gemini reviewt nur

Agent B's draft files for task35 + Plugin-Teil task36 landed unter `eledia.os_repo/tasks/*.php` statt im `local_customerportal`-Moodle-Plugin. Mehrere Dateien referenzieren APIs, Klassen oder Core-Events, die nicht existieren — ein Deploy im aktuellen Zustand würde den Moodle-Cron crashen oder die Observer stumm lassen.

Betroffene Dateien (alle in `eledia.os_repo/tasks/`):
- `events.php`, `observer.php` (task36 Plugin-Seite)
- `sync_installation_snapshot.php`, `sync_installation_plugins.php`, `tasks.php` (task35)
- `installation_service.php` (dupliziert existierende Klasse im Plugin)

#### Kritische Issues (würden fatal-failen oder still no-op sein)

1. **`events.php` + `observer.php`** abonnieren `\core\event\plugin_installed`, `\core\event\plugin_updated`, `\core\event\plugin_uninstalled`. Diese Moodle-Core-Events **existieren nicht** (verifiziert in Moodle 5.1.3 Container: `ls lib/classes/event/plugin*.php` → leer). Observer feuern nie. Alternativen:
   - Plugin-Lifecycle über `core_plugin_manager` + `upgrade.php`
   - Diff-Strategie innerhalb `sync_installation_plugins::execute()` (letzter Sync-Stand vs. aktueller `get_plugins()`-Snapshot), Event-Emission aus dem Diff
   - Moodle 5 `\core\hook\`-Attribute prüfen, ob es passende Plugin-Lifecycle-Hooks gibt

2. **`sync_installation_snapshot.php`** referenziert drei Dinge, die nicht existieren:
   - `new \local_customerportal\local\health_service()` — Klassendatei fehlt
   - `$site_info->get_users_online_count()` — Methode fehlt
   - `$site_info->get_storage_stats()['total_gb']` — Methode fehlt
   
   Aktueller `site_info_service` bietet nur: `get_user_stats`, `get_course_count`, `get_moodle_release`, `get_cron_info`, `count_failed_tasks`.

3. **`installation_service.php`** redeklariert `local_customerportal\local\installation_service`. Unverändert ins Plugin gemerged = PHP-Fatal "Cannot redeclare class".

4. **`tasks.php`** registriert nur die beiden neuen Scheduled Tasks. Das bestehende `db/tasks.php` im Plugin registriert bereits `sync_pending_requests_task`. Ersetzen statt Mergen = `sync_pending_requests_task` verschwindet aus der Scheduler-Registry.

#### Strukturelle / konventionelle Issues

5. Allen sechs Dateien fehlen GPL-Header, `@package`, `@copyright` — Moodle-Codechecker wird das flaggen.
6. Cache-Namespace `pluginsdata` in `installation_service.php` ist nicht in `db/caches.php` deklariert. Existierende Caches: `installationdata`, `overlaydata`, `catalogsearch`, `catalogdetail`.
7. Variablennamen mischen snake_case (`$installation_id`, `$cache_key`) mit der No-Underscore-Konvention des Plugins (`$installationid`, `$cachekey`).
8. Lang-Strings fehlen — rendern als `[[status_installed]]` etc.:
   - `status_installed`, `status_outdated`, `status_deprecated`, `status_removed`
   - `task_sync_plugins`, `task_sync_snapshot`
9. `sync_installation_plugins.php` nutzt `$plugin->versiondisk` (on-disk). Semantisch richtig für "installed_version" ist `$plugin->versiondb`; während eines anstehenden Upgrades driften die Werte.
10. `sync_installation_snapshot.php` hardcoded `'profile' => 'managed'` statt `get_config('local_customerportal', 'profile')`.
11. `sync_installation_snapshot.php` nutzt `get_site_identifier()` (Moodle-UUID) als `label`. API erwartet klartextlichen Namen — `$SITE->fullname` oder eine eigene `settings_site_label`-Config wären korrekt.
12. Keine Tombstone-Logik: Ein zuvor gesynchtes und danach deinstalliertes Plugin landet nie auf `status: removed` in Directus.
13. Nach erfolgreichem `/v1/portal/installations/snapshot` invalidiert der Task den `installationdata`-Cache nicht — Portal zeigt bis zum TTL-Ablauf einen veralteten Stand.
14. `sync_installation_snapshot.php` kennt keinen Backoff bei Directus-Ausfall — effektives Retry-Intervall = Cron-Tick (15 min). "last failed sync"-Marker für Observability fehlt.

#### Erforderliche Aktion (Claude implementation, Gemini review)

- Claude verschiebt/überführt die Logik in `local_customerportal/` und hängt sie korrekt ein:
  - `classes/local/health_service.php` (NEU; implementieren)
  - `classes/task/sync_installation_snapshot.php`, `classes/task/sync_installation_plugins.php`
  - `classes/local/observer.php` (erst umbauen, nachdem eine funktionierende Event-Quelle gewählt ist)
  - `db/events.php` — mergen, nicht ersetzen
  - `db/tasks.php` — in bestehendes Array aufnehmen
  - **NICHT** `installation_service.php` ins Plugin kopieren — neue Logik in bestehende Klasse einfalten.
- Die sechs Dateien unter `eledia.os_repo/tasks/*.php` bleiben bis zur Migration als Draft-Artefakte erhalten; danach löschen.
- Fehlende Lang-Strings ergänzen (de + en).
- Cache-Definition `pluginsdata` in `db/caches.php` aufnehmen ODER `installationdata` wiederverwenden.
- Plugin-Observer-Strategie neu entscheiden (Diff-basiert oder Moodle-5-Hooks).
- Gemini prüft danach: Payloads, erwartete Portal-States, Roundtrip-Nachweis und Abnahmekriterien für Coordinator.

#### Verifikation nach Fix (Definition of Done für bug10)

- `moodle-test`-Skill (phpunit + codechecker) grün 0/0.
- `sync_installation_snapshot` einmalig manuell → `HTTP 200` von `/v1/portal/installations/snapshot`.
- `sync_installation_plugins` einmalig manuell → `HTTP 200` von `/v1/portal/installations/:id/plugins/sync`, `synced: N` konsistent mit `core_plugin_manager::instance()->get_plugins()`-Count.
- Observer-Integration: Event-Quelle triggern → `POST /v1/portal/installations/:id/events` liefert `201 duplicate: false`; Wiederholung → `200 duplicate: true`.
- Portal "Meine Plugins" zeigt echte Rows; entfernte Plugins erscheinen mit Tag "Entfernt".

### risk05 Plugin-intake MVP geht verloren oder wird unreviewed ausgerollt
Wenn der zusätzliche task41-Code in `directus/extensions/v1/index.js` nicht bewusst gesichert und reviewed wird, droht entweder stiller Verlust der Arbeit oder ein unkontrollierter Deploy eines nur teilweise validierten MVPs.

Entscheidung (2026-04-20, Claude Review — siehe task41 in `docs/04-tasks.md`):
- Der MVP-Code (`parsePluginIntakeLink`, `componentFromGithubRepo`, `POST /v1/portal/plugins/intake-links`) **existiert auf disk nicht mehr** — er wurde nur uncommitted im Working Tree gehalten und ging beim `git checkout -- directus/extensions/v1/index.js` (2026-04-19 End-of-day) verloren. Weder `git log` noch `git reflog` enthalten ihn.
- Konsequenz: kein Review-Objekt mehr vorhanden. Der in `docs/03-dev-doc.md` dokumentierte Endpoint ist damit **Spec, nicht Implementierung**.
- Empfehlung für den nächsten Anlauf (wenn task41 wirklich ausgeliefert werden soll): eigenständige Directus-Extension `plugin-intake` — analog zum bestehenden `catalog-projection-hook`-Pattern — statt die Endpoint-Datei `v1/index.js` weiter wachsen zu lassen (aktuell 1249 Zeilen).
- Bis zur Re-Implementierung: `POST /v1/portal/plugins/intake-links` liefert `404`, Docs-Abschnitt mit Status "proposed" kennzeichnen statt "implemented".

#### Agent A (Directus-API) ist nicht betroffen

- `v1/index.js` + alle drei neuen Endpoints live und smoke-verifiziert (2026-04-19).
- Contract stabil, keine Nachbesserung nötig.
- `installation.last_event_at` nachgereicht (Commit `9564552`), Spec `claude_r12plus.md` vollständig erfüllt.

### bug10 update (2026-04-20) — task35/36-plugin/37 umgesetzt

Die unter bug10 aufgelisteten Issues sind mit Commit `3041df5` in `local_customerportal` (v0.2.0) behoben. Zusammenfassung der Überführung:

- **Nicht verwendete Core-Events vermieden:** Kein `\core\event\plugin_*`. Events werden Diff-basiert in `sync_service::emit_plugin_change_events()` aus dem Vergleich `current_plugins` ↔ `plugin_state_last` erzeugt.
- **`health_service` (NEU):** aggregiert `lastcronruntime` + `task_*.faildelay`-Zähler zu `green|amber|red`. Ersetzt das vorherige Hardcoded-`green`.
- **`sync_service` (weiterentwickelt):** Gemini-Basis um Config-driven `profile`, `health_service`-Delegation und `storage_quota_gb`-Opt-in ergänzt.
- **Cron-Registrierung:** `db/tasks.php` um `sync_installation_snapshot` + `sync_installation_plugins` ergänzt (gemerged, nicht ersetzt).
- **Read-Path (task37):** `myplugins.php` + `plugin_list.mustache` rendern alle vier Status-Badges (`installed`, `outdated`, `deprecated`, `removed`); neuer `never_synced`-Zustand wenn `installation.last_sync_at` leer.
- **Cache-Invalidierung:** `installation_service::invalidate_caches()` wird nach erfolgreichem Snapshot-POST aufgerufen; Cache-Keys auf `md5()` normiert (bug03-Pattern).
- **Keine Klassendopplung:** Draft-`installation_service.php` wurde **nicht** ins Plugin kopiert; stattdessen `has_synced()` + `invalidate_caches()` in die bestehende Klasse eingearbeitet.
- **Draft-Dateien** unter `eledia.os_repo/tasks/*.php` sind mit Commit `3041df5` in `local_customerportal` aufgegangen und wurden aus dem SSOT-Repo entfernt.

Verifikation:
- `moodle-test` grün: 29/29 Tests, 87 Assertions, codechecker 0/0.
- Live-Smoke gegen `directus.eledia.ai` mit Service-Token: Snapshot + 421-Plugin Bulk-Sync + 422 `plugin_installed`-Events alle `HTTP 200`, Installation `0994d330-d04f-42b4-ad4b-a5d1cfcc1c28` trägt populierte Telemetrie + frisches `last_sync_at`.

---

## Tests

### test01 Public catalog visibility rules
Feature: feat02  
Result: passed

**Goal**
Verify that only `published` catalog entries are visible through the public contract.

**Verification** (live check, 2026-04-18)
- `GET /items/catalog_entry_public` (public) returned only `published` entries.
- canonical read (`/items/plugin_review`) returned `403` for public access.
- contract endpoint `GET /v1/catalog/search` returned expected locked field set.
- contract endpoint `GET /v1/catalog/{slug}` returned expected locked field set.

---

### test02 Portal installation context overlay
Feature: feat04  
Result: passed

**Goal**
Verify that portal catalog views correctly enrich public entries with installation-specific context — both at the contract level (curl) and end-to-end through the Moodle plugin runtime.

**Verification** (live check, 2026-04-18)

Contract level:
- `GET /v1/portal/overlay` with valid token + installation + catalog entry returned locked keys:
  `installation_id`, `catalog_entry_id`, `is_installed`, `compatibility_status`,
  `requestable`, `recommended`, `requires_upgrade_first`, `note`.
- Missing token on `/v1/portal/*` returns `403`.
- `directus/scripts/v1_contract_smoke_test.sh` ran green against `directus.eledia.ai` (all 8 checks).

End-to-end through the Moodle plugin (container `demo-webserver-1`, installation `0994d330-…`):
- `catalog_service::get_detail()` returned correct entries for slugs `attendance-plus`, `attendance-plus-pro`, `classroom-insights-suite`.
- `installation_service::get_overlay()` returned all 8 locked fields plus the optional `installed_version_summary` where applicable.
- Verified distinct overlay variants: already-installed (`is_installed=true, requestable=false`), request-eligible (`is_installed=false, requestable=true, recommended=true`).
- Surfaced and fixed bug08 (HTML-encoded `&amp;` in query strings) and bug09 (dash in cache key) during verification.

---

### test03 Request creation flow
Feature: feat05  
Result: passed

**Goal**
Verify that a portal user can create a request with the correct installation and catalog context.

**Verification**
PHPUnit suite `local_customerportal_testsuite` — 15/15 tests green (Moodle 5.1.3+, PHP 8.3, pgsql), 33 assertions.
Covers: REQUEST_TYPES constant, exception on unconfigured installation, exception on invalid type,
DB record with status=pending, catalog_entry_id stored/null, plus `site_info_service` user/course/cron counters.
See `tests/request_service_test.php` and `tests/site_info_service_test.php`.

Additional live verification (2026-04-18):
- `POST /v1/portal/requests` creates row and returns `201`.
- `GET /v1/portal/requests` includes created request in installation-scoped list.

---

### test04 Locked handover contract for overlay and request payload
Feature: feat03, feat04, feat05  
Result: passed

**Goal**
Verify that locked Agent A -> Agent B fields in `docs/03-dev-doc.md → "Agent A → Agent B Handover Contract"` are present, stable, and not silently renamed.

**Verification** (code audit, 2026-04-18)

Overlay query params sent by `installation_service::get_overlay()`:
- `installation_id` ✅ exact name, line 126
- `catalog_entry_id` ✅ exact name, line 127

Overlay response: passed through verbatim as `$result['data']` — no field renaming.
Locked response keys (`is_installed`, `compatibility_status`, `requestable`, `recommended`,
`requires_upgrade_first`, `note`) are consumed by rendering layer without transformation. ✅

Request payload sent by `request_service::sync_to_directus()`:
- `installation_id` ✅ line 100
- `catalog_entry_id` ✅ line 101 (nullable via `: null`)
- `request_type` ✅ line 102
- `message` ✅ line 103

Enum values in `REQUEST_TYPES` constant:
- `plugin_request`, `feature_request`, `storage_request`, `consulting_request` ✅ all 4 present

No field has been renamed or removed. Contract is stable.

---

### test06 Portal quality baseline (codechecker + phpunit)
Feature: feat03, feat04, feat05
Result: passed

**Goal**
Verify that `local_customerportal` passes Moodle coding standards and has a green test suite after each sprint.

**Verification** (2026-04-18, via moodle-test skill)

Release 1.0 run (plugin v`2026041801`):
- Codechecker: `phpcs --standard=moodle local/customerportal` → 0 errors, 0 warnings
- PHPUnit: suite `local_customerportal_testsuite` → 15/15 green, 33 assertions (Moodle 5.1.3+, PHP 8.3, pgsql 18.3)
- Non-blocking: 2 PHPUnit deprecations at framework level

Release 1.1 run (plugin v`2026041802`, added `health_service` + site_info extensions):
- Codechecker: 0 errors, 0 warnings (after lang-string auto-sorting)
- PHPUnit: 24/24 green, 129 assertions
- 5 new tests for site_info storage/env/online, 5 new tests for health_service

Fixes needed to reach green:
- `db/upgrade.php` — removed unnecessary `MOODLE_INTERNAL` guard, collapsed column-aligned whitespace to single spaces
- `tests/site_info_service_test.php` — bumped "old user" lastaccess offset from 60 days to 400 days (matches `ACTIVE_DAYS=365`)
- Release 1.1: lang strings auto-reordered by PHPCBF; PHPUnit re-init after version bump

---

### test05 End-to-end v1 contract smoke test
Feature: feat02, feat03, feat04, feat05  
Result: passed (re-run required after task24 deploy)

**Goal**
Run one deterministic smoke test that validates public catalog, portal overlay, request create/list, and auth guard together.

**Verification** (2026-04-18)
- Script: `directus/scripts/v1_contract_smoke_test.sh`
- Target: `https://directus.eledia.ai`
- Result: all 8 checks passed.

**task24 follow-up (2026-04-18)**
- Smoke test now also asserts SEO key presence (`meta_description`, `tags` on search; `meta_title`, `meta_description`, `og_image`, `tags` on detail). Values may be `null`.
- v1 extension performs runtime column-detection and always returns the keys, so the test stays green pre- and post-migration.
- After the four SEO columns are applied to live `catalog_entry_public` and the seed `attendance-plus-pro` is re-imported (it now carries non-null SEO values), the test must be re-run to confirm both null and non-null paths.

---

### test07 SEO contract & screenshot alt validation
Feature: feat02
Result: pending (Directus side code complete 2026-04-18, website side passed 2026-04-18; awaiting live deploy of SEO columns)

**Website side (task16) — passed 2026-04-18**
- `npm run build` and `npm run lint` green in `website/public-catalog/`.
- Rendered HTML inspected against pre-migration live `directus.eledia.ai`:
  - `/`: `<title>eLeDia Public Catalog — Plugin- und Produktkatalog für Moodle</title>`, canonical `https://catalog.eledia.ai`.
  - `/catalog`: canonical `https://catalog.eledia.ai/catalog`, OG title/description/url/type present.
  - `/catalog/attendance-plus-pro`: title `Attendance Plus Pro | eLeDia Public Catalog`, canonical absolute, OG + Twitter cards present, `meta description` correctly fell back to `description_public` (live SEO columns not yet present).
- Confirms the SEO fallback chain `lib/seo.ts` works correctly when the SSOT side returns SEO keys as `null`. The same HTML will pick up populated `meta_title`/`meta_description`/`og_image`/`tags` automatically after task24's live deploy.

**Goal**
Verify that the task24 SSOT extensions hold end-to-end:
- v1 contract returns the four SEO keys on detail and the two SEO keys on search.
- The projection hook rejects `catalog_entry_public` writes with empty `screenshots[].alt`.
- The projection hook preserves curated SEO values across rebuilds (an `items.update` on a canonical source must not wipe `meta_title` etc.).

**Verification plan**
1. Apply the four SEO columns to live `catalog_entry_public`; redeploy `v1` and `catalog-projection-hook`.
2. Run `directus/scripts/v1_contract_smoke_test.sh` against `directus.eledia.ai` — all SEO keys must be present.
3. Re-import `docs/seeds/catalog_seed_v1.json` (or update the `attendance-plus-pro` row manually) so the SEO values are non-null on at least one entry. Re-run smoke to observe non-null path.
4. Trigger a write to `plugin_component`/`product` linked to a curated entry; confirm via `GET /v1/catalog/{slug}` that `meta_title`/`meta_description`/`og_image`/`tags` survive the rebuild.
5. Attempt to PATCH a `catalog_entry_public` row with `screenshots: [{url:"…", alt:""}]` via Directus admin/API — expect HTTP 400 from the filter hook.

---

### test08 Runbot Demo CTA contract & rendering
Feature: feat07
Result: pending (Directus side code complete 2026-04-18, website side passed 2026-04-18; awaiting live deploy of `runbot_demo_id` column)

**Goal**
Verify the task27/task28 wiring end-to-end:
- v1 contract returns `runbot_demo_id` on search and detail (presence-asserted).
- Projection hook preserves curated `runbot_demo_id` across rebuilds.
- Public website renders the "Demo starten" CTA only when `runbot_demo_id` is non-null.

**Website side (task28) — passed 2026-04-18**
- `npm run lint` + `npm run build` (with `NEXT_PUBLIC_SITE_URL=https://catalog.eledia.ai`) green.
- Negative path verified against pre-migration live `directus.eledia.ai`: `/catalog/attendance-plus-pro` renders no Demo CTA (live response carries no `runbot_demo_id`), confirming graceful fallback.
- Positive path verified by sample-payload assertion: `runbot_demo_id="exam2pdf"` → CTA href `https://demo.eledia.ai?demo=exam2pdf`, `target=_blank`, `rel=noopener`, `aria-label` includes plugin title.

**Verification plan (full pass after deploy)**
1. Apply `runbot_demo_id` column to live `catalog_entry_public`, `plugin_component`, and `product`; redeploy `v1` + `catalog-projection-hook`.
2. Run `directus/scripts/v1_contract_smoke_test.sh` against `directus.eledia.ai` — `runbot_demo_id` key must be present on both search and detail.
3. Set the column on the `attendance-plus-pro` and `exam2pdf` projections in Studio, reconciling the placeholder values against the live Runbot `configs.json` keys.
4. Visit `/catalog/attendance-plus-pro` and `/catalog/exam2pdf` — CTA visible, target opens demo in new tab.
5. Visit any unrelated entry — CTA must remain absent.
6. Trigger a write to a linked `plugin_component`/`product`; confirm via `GET /v1/catalog/{slug}` that `runbot_demo_id` survives the projection rebuild (preservation in `CURATED_PROJECTION_COLUMNS`).

---

### test09 Plugin classification contract & projection preservation
Feature: feat01, feat02
Result: pending (code complete 2026-04-18; awaiting live deploy of classification columns + `plugin_maintainer` collection)

**Goal**
Verify that the task25 SSOT extensions hold end-to-end:
- v1 contract returns the six classification keys on search and the eleven additional classification keys on detail (presence-asserted, values may be null).
- Projection hook preserves all 17 classification fields across rebuilds (`CURATED_PROJECTION_COLUMNS`).
- Public projection never leaks vendor contact data (`contact_email`, `contact_phone`, `homepage` from `plugin_maintainer`).
- Consumers handle null values without crashing (graceful fallback).

**Verification plan (full pass after deploy)**
1. Create `plugin_maintainer` collection in live Directus with the documented field set; add `vendor_id` FK to `plugin_component` and `product`; add the 17 classification columns to `catalog_entry_public` (and matching editorial columns to `plugin_component`/`product`).
2. Redeploy `v1` + `catalog-projection-hook`; run `directus/scripts/v1_contract_smoke_test.sh` against `directus.eledia.ai` — all classification keys must be present on both search and detail.
3. Re-import (or hand-edit) the `attendance-plus` and `attendance-plus-pro` projections so they carry the seed values; re-run smoke to observe non-null path.
4. Inspect a populated detail response — `maintainer` must contain only `{name, type, is_moodle_certified_partner}`. Vendor contact fields must not appear.
5. Trigger a write to a linked `plugin_component`/`product`; confirm via `GET /v1/catalog/{slug}` that all 17 classification fields survive the projection rebuild.
6. Set `is_deprecated = true` on a test entry; confirm portal renders deprecation banner and (when `replacement_entry_id` is set) the link to the replacement (task26 verification).

---

### test10 Installation registration endpoint (task31, feat09)
Feature: feat09
Result: pending (Agent A code complete 2026-04-18; full pass needs Runbot Onlineshop + portal wizard)

**Goal**
Verify the new portal-private installation registration end-to-end:
- `POST /v1/portal/installations` rejects bad payloads (missing/invalid UUID, label, moodle_version, profile, malformed email).
- Successful POST creates an `installation` row, returns `201` with the documented field set, and is idempotent on the UUID (`409` on second call with the same `id`).
- `GET /v1/portal/installation/{id}` returns the stored row when it exists; returns the deterministic mock for unregistered UUIDs (so existing portal smoke tests stay green during rollout).
- The endpoint requires the existing `/v1/portal/*` Bearer guard; unauthenticated POST returns `403`.

**Verification plan**
1. Redeploy `directus/extensions/v1` against `directus.eledia.ai` (`./directus/scripts/deploy_v1_endpoint_extension.sh directus-vps`).
2. `curl -X POST .../v1/portal/installations` without `Authorization` → expect `403`.
3. POST with malformed UUID, missing label, missing moodle_version, profile not in `{managed, self_hosted, demo}`, malformed email → expect `400` with `validation_error` and a useful message in each case.
4. POST a valid payload → expect `201` and the documented `data` shape.
5. POST the same payload again → expect `409 conflict`.
6. `GET /v1/portal/installation/{id}` for the registered UUID → expect the stored row (real `label`/`moodle_version`/etc.).
7. `GET /v1/portal/installation/{id}` for a different (unregistered) UUID → expect the deterministic mock (existing test02 / test05 behaviour).
8. After the next iteration of `v1_contract_smoke_test.sh`, add a POST→GET round-trip step that proves the real-row path.

---

### test11 Installation snapshot upsert
Feature: feat09
Result: passed (2026-04-19, Agent C)

**Goal**
Verify that the digital twin snapshot can be created or updated.

**Verification**
`curl -X POST "$BASE_URL/v1/portal/installations/snapshot" -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -d '{ "id": "'$INSTALLATION_ID'", "label": "Smoke Test Installation", "flavour": "lms", "moodle_version": "5.1", "release_channel": "lts", "profile": "managed", "sla_level": "level_1", "user_tier": "250", "addon_bbb_enabled": false, "addon_solr_enabled": false, "user_count_active_30d": 3, "user_count_total": 41, "storage_used_gb": 0, "health_overall": "green" }'`
Expected: `201` (Created) or `200` (OK).  
Evidence: Status `201`, Body contains full installation object.

---

### test12 Installation snapshot idempotency
Feature: feat09
Result: passed (2026-04-19, Agent C)

**Goal**
Verify that sending the same snapshot twice does not create side effects or errors.

**Verification**
Repeat the command from `test11`.
Expected: `200` (OK), response contains the same installation data.
Evidence: Status `200`, no duplicate rows in Studio visible.

---

### test13 Plugin sync roundtrip
Feature: feat09
Result: passed (2026-04-19, Agent C)

**Goal**
Verify that bulk-syncing plugins correctly persists the state.

**Verification**
1. `curl -X POST "$BASE_URL/v1/portal/installations/$INSTALLATION_ID/plugins/sync" -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -d '{ "plugins": [ { "frankenstyle": "mod_smoke_test", "installed_version": "2026041900", "status": "installed", "time_installed": "2026-04-19T21:08:00Z", "time_updated": "2026-04-19T21:08:00Z" } ] }'`
2. `curl -X GET "$BASE_URL/v1/portal/installation/$INSTALLATION_ID/plugins" -H "Authorization: Bearer $TOKEN"`
Expected: `200`, list contains `mod_smoke_test`.
Evidence: GET response contains `mod_smoke_test` with correct version.

---

### test14 Event ingestion
Feature: feat09
Result: passed (2026-04-19, Agent C)

**Goal**
Verify that change events are recorded correctly.

**Verification**
`curl -X POST "$BASE_URL/v1/portal/installations/$INSTALLATION_ID/events" -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -d '{ "event_id": "smoke_test_evt_001", "event_type": "plugin_installed", "payload": "{\"frankenstyle\":\"mod_smoke_test\",\"version\":\"2026041900\"}", "actor_type": "smoke_test", "actor_id": "smoke", "happened_at": "2026-04-19T10:00:00Z" }'`
Expected: `201` (Created).
Evidence: Status `201`, record visible in `installation_change_event`.

---

### test15 Duplicate event idempotency
Feature: feat09
Result: passed (2026-04-19, Agent C)

**Goal**
Verify that events are idempotent by their `event_id`.

**Verification**
Repeat command from `test14`.
Expected: `200` (OK), no new row created, no error.
Evidence: Status `200`, response body contains `"duplicate": true`.

---

### test16 Invalid snapshot payload (validation_error)
Feature: feat09
Result: passed (2026-04-19, Agent C)

**Goal**
Verify that the API rejects invalid data according to allowlists.

**Verification**
`curl -X POST "$BASE_URL/v1/portal/installations/snapshot" -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -d '{ "id": "'$INSTALLATION_ID'", "label": "Smoke Test Installation", "flavour": "invalid_flavour", "moodle_version": "5.1", "release_channel": "lts", "profile": "managed", "sla_level": "level_1", "user_tier": "250", "addon_bbb_enabled": false, "addon_solr_enabled": false }'`
Expected: `400` (Bad Request), body contains `"code": "validation_error"`.
Evidence: Status `400`, correctly rejected with error code.

---

### test17 Link-based plugin intake endpoint (task41 MVP)
Feature: feat01, feat09
Result: deferred (2026-04-20) — implementation was never committed and is not recoverable; revive plan moves work into a standalone `plugin-intake` extension (see `docs/04-tasks.md → task41`). Steps below stay on file as the smoke template for the next iteration.

**Goal**
Verify that `POST /v1/portal/plugins/intake-links` supports safe dry-run parsing and idempotent canonical upsert behavior.

**Verification plan**
1. Unauthorized request to `/v1/portal/plugins/intake-links` -> expect `403`.
2. Dry-run parse:
  - `POST` with
    - `https://moodle.org/plugins/mod_forum`
    - `https://github.com/moodlehq/moodle-mod_forum`
  - `dry_run=true` (or omitted) -> expect `200`, no DB writes, non-empty `items`.
3. Invalid links batch:
  - include one malformed URL and one unsupported host
  - expect `200`, `skipped > 0`, with reasons in `skipped_rows`, while valid rows are still processed.
4. Write mode:
  - repeat payload with `dry_run=false`
  - expect `200`, `created` or `updated` counters > 0.
5. Idempotency:
  - send same write payload again
  - expect stable result (rows updated in place, no duplicates by `plugin_component.component`).
6. Manual DB/Studio check:
  - `plugin_component` contains normalized `component` values and additive field updates only.

### test18 Moodle 5.2 Demo card end-to-end workflow
Feature: feat01, feat02, feat09
Result: passed (2026-04-20, manual)

**Goal**
Walk a newly authored catalog entry through the full SSOT → projection → public API → portal stack to prove the Release 1.2+ workflow actually works for a fresh card.

**Setup**
Insert a `moodle-5-2-demo` entry via SQL on `directus.eledia.ai`:
- `product` row with `vendor_id` → eLeDia GmbH, `runbot_demo_id='moodle-5-2'`, `pricing_model='free'`, `is_eledia_product=true`, `gdpr_readiness='green'`.
- `catalog_entry_public` projection row mirroring the canonical fields plus SEO (`meta_title`, `meta_description`, `tags`), maintainer JSON subset, and `supported_versions=[{channel: moodle, min: 5.2, max: 5.2}]`.

**Verification (2026-04-20)**
- `GET /v1/catalog/search?page_size=10` returned 5 entries including `moodle-5-2-demo` with classification fields populated (`pricing_model=free`, `is_eledia_product=true`, `gdpr_readiness=green`, `runbot_demo_id=moodle-5-2`).
- `GET /v1/catalog/search?entry_type=product&is_eledia_product=true` returned exactly `attendance-plus-pro` + `moodle-5-2-demo` — classification filter pass-through works.
- `GET /v1/catalog/moodle-5-2-demo` detail payload carried `meta_title`, `supported_versions`, `maintainer.is_moodle_certified_partner=true`, `runbot_demo_id=moodle-5-2`.
- Portal flow (manual): catalog list shows the card with pricing+eLeDia+GDPR badges; detail renders the maintainer block; "Demo starten" CTA target is `https://demo.eledia.ai?demo=moodle-5-2`.

**Notes**
- `supported_moodle` string column stays `null` on the projection row for non-plugin entries; consumers that need a human-readable version use `supported_versions[0]` instead.
- Insert path bypasses the `catalog-projection-hook` because SQL writes don't trigger Directus item hooks; for repeated seeding, prefer the Directus Studio UI or admin REST API so the hook re-derives the projection.

---

## Release 1.2 Plus — Rollout-Checkliste

Diese Checkliste muss vor dem Sign-off durch Agent C vollständig abgehakt sein.

[x] 1. **Agent D:** Schema live in Directus bestätigt
    - `installation`: flavour, release_channel, sla_level, user_tier, addon_bbb_enabled, addon_solr_enabled + Telemetrie-Felder vorhanden.
    - Neue Collections: `installation_plugin`, `installation_change_event` vorhanden.
[x] 2. **Agent A:** v1 Extension redeployt (`deploy_v1_endpoint_extension.sh`).
[x] 3. **Agent D:** `capture_snapshot.sh` ausgeführt, Snapshot-YAML committed.
[x] 4. **Smoke-Tests 1-8** grün (Baseline — keine Regression).
[x] 5. **Smoke-Tests 11-16** grün (R1.2 Plus — neue Endpoints).
[x] 6. **Agent B:** Plugin auf Staging deployed.
[x] 7. **Agent B:** Sync-Task einmalig manuell ausgeführt (`mtrace`-Log vorweisen).
[x] 8. **Portal "Meine Plugins"** zeigt echte Rows (kein deterministic bootstrap mehr).
[x] 9. **Release Gate:** Agent C sign-off erfolgt.

---

## Release 1 Quality Gate

Release 1 should only be considered ready when:
- public catalog contract is stable
- portal uses the same public catalog basis as the website
- installation-specific overlay behaves consistently
- requests are stored and visible with correct status handling
- locked handover fields remain stable across releases
