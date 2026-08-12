---
name: moodle-test
description: |
  Run Moodle plugin quality checks inside the user's local Docker container on OrbStack — PHPUnit tests, Moodle Codechecker (phpcs), and optional PHPCBF auto-fixing. Use this skill whenever the user asks to "test the plugin", "run phpunit", "run codechecker", "check code quality", "lint the plugin", "run the moodle tests", "tests grün bekommen", or similar. Also triggers on German phrases like "Tests laufen lassen", "Codecheck machen", "PHPUnit ausführen", "Plugin testen". Handles first-time setup automatically (installing codechecker, initializing PHPUnit) and runs everything non-interactively so the user only has to invoke the skill.
---

# Moodle Test — Quality Checks for Moodle Plugins

Runs the full Moodle quality-check stack for a plugin inside Johannes' local Docker container:

1. **PHPCBF** (optional, via `--fix`) — auto-fixes formatting violations
2. **Codechecker** (`phpcs --standard=moodle`) — reports coding-standard issues
3. **PHPUnit** — runs the plugin's unit test suite via its named Moodle testsuite

All three steps share the same container/path discovery logic, so the same command works for `mod_*`, `block_*`, `local_*`, `qtype_*`, etc.

## Environment (hard-coded defaults for Johannes' OrbStack setup)

| Key | Value |
|---|---|
| Container | `demo-webserver-1` |
| Moodle dirroot (in container) | `/var/www/site/moodle/public` |
| Project root (in container) | `/var/www/site/moodle` (parent of dirroot) |
| PHPUnit binary | `/var/www/site/moodle/vendor/bin/phpunit` |
| PHPUnit config | `/var/www/site/moodle/phpunit.xml` |
| Codechecker path | `/var/www/site/moodle/public/local/codechecker` |
| Host → container mount | `~/demo/site` → `/var/www/site` |
| Shared PHPUnit lock | `/var/www/phpunitdata/.phpunit.lock` (inside the container) |

**Critical path facts (Moodle 5.x "public" layout):**

- Moodle's dirroot is `public/` — all plugins live under `public/mod/…`, `public/blocks/…`, `public/local/…`
- `composer.json`, `vendor/`, and the generated `phpunit.xml` live at the **project root**, one level **above** dirroot
- PHPUnit must be invoked from the project root, with the plugin path expressed as `public/mod/<plugin>` relative to it
- Codechecker runs from dirroot, with the plugin path expressed as `mod/<plugin>` relative to dirroot
- **Never** use `/var/www/site/moodle` as a path for plugin files (it resolves to the project root, not the webroot)

## Usage

```bash
bash <skill-path>/scripts/test.sh --plugin mod/eledialeitnerflow
```

### Options

```
--plugin <path>       Plugin path relative to Moodle dirroot, e.g. mod/eledialeitnerflow. Required.
--fix                 Run PHPCBF first to auto-fix formatting.
--skip-phpunit        Skip unit tests (run only codechecker).
--skip-codecheck      Skip codechecker (run only phpunit).
--filter <name>       Pass --filter to phpunit (test class or method name).
--container <name>    Override container (default: demo-webserver-1).
--moodle-root <path>  Override container dirroot (default: /var/www/site/moodle/public).
                      Project root is auto-derived as its parent.
--install-tools       First-time setup: install composer + codechecker + init phpunit.
-h, --help            Show help.
```

### Typical invocations

First time on a fresh container:
```bash
bash scripts/test.sh --plugin mod/eledialeitnerflow --install-tools
```

Full quality check:
```bash
bash scripts/test.sh --plugin mod/eledialeitnerflow
```

Auto-fix formatting then check:
```bash
bash scripts/test.sh --plugin mod/eledialeitnerflow --fix
```

Run a single test method:
```bash
bash scripts/test.sh --plugin mod/eledialeitnerflow --filter test_calculate_box
```

Isolate PHPUnit while chasing a bug:
```bash
bash scripts/test.sh --plugin mod/eledialeitnerflow --skip-codecheck
```

## How the script builds its commands

All commands run via `docker exec` in the container. The script uses **two** working directories depending on the tool:

### Codechecker & PHPCBF (cwd = dirroot)
```bash
docker exec -w /var/www/site/moodle/public demo-webserver-1 \
  php local/codechecker/vendor/bin/phpcs --standard=moodle mod/eledialeitnerflow
```

### PHPUnit (cwd = project root)
```bash
docker exec -w /var/www/site/moodle demo-webserver-1 \
  php vendor/bin/phpunit -c phpunit.xml --testsuite mod_eledialeitnerflow_testsuite
```

### Testsuite name derivation

The script derives the PHPUnit testsuite name from `--plugin`:

| `--plugin` value | Component | Testsuite |
|---|---|---|
| `mod/eledialeitnerflow` | `mod_eledialeitnerflow` | `mod_eledialeitnerflow_testsuite` |
| `blocks/eledialeitnerflow` | `block_eledialeitnerflow` | `block_eledialeitnerflow_testsuite` |
| `local/testdata` | `local_testdata` | `local_testdata_testsuite` |

Note: `blocks/` → `block_` (Moodle's frankentype quirk; blocks live in `blocks/` but components are `block_*`).

**Why the testsuite approach (not a directory path)?** Moodle test files use the suffix `_test.php`, but PHPUnit's default discovery looks for `*Test.php`. Passing a directory therefore discovers zero tests. Moodle's `init.php` writes a named testsuite into `phpunit.xml` for every component — invoking that testsuite by name is the reliable way to run a plugin's tests.

### "No tests executed" is treated as failure

PHPUnit exits 0 when a testsuite is empty. The script greps the output for "No tests executed" and flips the exit code to 1 if found, so a silent zero-test run can't masquerade as green.

## First-time setup (`--install-tools`)

Steps in order:

1. **Composer** — installed into `/usr/local/bin/composer` in the container if missing.
2. **Codechecker** — `git clone --depth 1 https://github.com/moodlehq/moodle-local_codechecker.git` into `public/local/codechecker`, then `composer install`.
3. **PHPUnit config** — if neither `phpunit.xml` nor `phpunit.xml.dist` exists at the project root, the script runs (under the shared lock):
   ```bash
   docker exec -w /var/www/site/moodle demo-webserver-1 \
     php public/admin/tool/phpunit/cli/init.php
   ```
   Note: `init.php` must be run **from the project root** in Moodle 5.x public layout, not from dirroot. The script acquires `/var/www/phpunitdata/.phpunit.lock` before initialization.

**Prerequisites in `config.php`** (the script does NOT modify config.php — ever):
```php
$CFG->phpunit_prefix = 'phpu_';
$CFG->phpunit_dataroot = '/var/www/phpunit_dataroot';
```

If init.php fails, the script prints these lines and exits. The user must add them manually.

## Sanity checks (always run)

Before doing any work the script verifies:

1. Container is running
2. Moodle dirroot exists in the container
3. Project root exists in the container
4. Plugin directory exists at `<dirroot>/<plugin>`

Any failure exits immediately with a clear message — no silent fallbacks.

## Running the skill from Claude

When the user asks Claude to run tests:

1. Determine the plugin path from current context (usually `mod/eledialeitnerflow` for Johannes). If ambiguous, ask.
2. If this is the first run on a new container, use `--install-tools` first.
3. Invoke the script and show its output (don't re-wrap it).
4. On codechecker failures, group remaining issues by file and suggest the next fix.
5. On PHPUnit failures, show the failing test names and a short excerpt of each error/assertion message. Look for:
   - `dml_missing_record_exception` with `WHERE id IS NULL` → a generator helper is using the wrong property (e.g. `$cm->instance` instead of `$cm->id` — the Moodle plugin generator's `create_instance()` returns the activity record directly, PK is `id`).
   - `Undefined property` warnings → same root cause pattern.
   - `Failed asserting that X matches expected Y` with arithmetic patterns → likely an off-by-one in domain logic; check the dataProvider values against the tested function.

Never modify `config.php` automatically. Never skip the `/public` in container paths.

## Troubleshooting

**"Could not read XML from file phpunit.xml"** — PHPUnit config not initialized. Run with `--install-tools`.

**"No tests executed!"** — Testsuite name doesn't match the one in `phpunit.xml`. Verify:
```bash
docker exec -w /var/www/site/moodle demo-webserver-1 grep testsuite phpunit.xml | head
```
Re-run `--install-tools` after adding `tests/` files to the plugin so `init.php` picks them up.

**"phpunit binary not found"** — Composer deps missing. Run:
```bash
docker exec -w /var/www/site/moodle demo-webserver-1 composer install --no-interaction
```

**"local/codechecker: No such file"** — Run with `--install-tools`.

**"Plugin path does not exist"** — The `--plugin` value is relative to dirroot. Use `mod/<name>`, not `public/mod/<name>` and not an absolute path. For blocks use `blocks/<name>` (plural).

**Plugin lives under `public/` but script can't find it** — Check `--moodle-root`. It must be `/var/www/site/moodle/public`, NOT `/var/www/site/moodle`.

**PHPCBF fixes things but exits 1** — That's normal. phpcbf uses exit 1 to mean "I fixed violations". The script treats 0 and 1 as success for phpcbf.

**`test -d` type commands fail silently** — The script always wraps path tests in `bash -c "[ -d path ]"` because `test` is a shell builtin and isn't always available as a standalone binary via `docker exec`.

**Concurrent PHPUnit runs** — The shared container has one PHPUnit dataroot and
one database prefix. The script acquires `/var/www/phpunitdata/.phpunit.lock`
with `flock` around both `init.php` and the complete PHPUnit process, including
its cache and temporary-file cleanup. A second agent waits for the first one;
do not bypass the script with an unlocked `init.php`, PHPUnit command, or
`rm -rf` against the PHPUnit dataroot. Codechecker does not use this lock.

**Recovery after an interrupted run** — If a killed run left orphaned `pt_`
tables and Moodle reports `Can not use database for testing, try different
prefix`, first stop other PHPUnit activity and run the following SQL against
the configured test database. It generates `DROP TABLE ... CASCADE` statements
for only the orphaned `pt_` tables:

```sql
select 'drop table if exists "'||table_name||'" cascade;'
  from information_schema.tables
 where table_schema='public' and table_name like 'pt\_%';
```

Execute the generated statements, then reinitialize PHPUnit through the same
lock (adjust the container/project paths only when using the script overrides):

```bash
docker exec -w /var/www/site/moodle demo-webserver-1 \
  flock -x /var/www/phpunitdata/.phpunit.lock -- \
  php public/admin/tool/phpunit/cli/init.php
```

Never use an unlocked `rm -rf` on the PHPUnit dataroot. If the generated SQL
does not list the expected prefix, stop and verify the configured
`$CFG->phpunit_prefix` before dropping anything.
