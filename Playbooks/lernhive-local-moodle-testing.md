# Lernhive: isolated local Moodle testing

Use this playbook for concurrent agent or issue runs against the Lernhive
Moodle 5.2 workspace.

## Safety rule

The `moodle52` target is a shared integration stack. It is not run-safe:
concurrent sync or test-init processes share its mounted source tree, database
volumes, PHPUnit/Behat dataroots, and generated version hashes. Do not use it
for an agent-owned PHPUnit or Behat run while other work may be active.

Create a private stack for every issue. Keep the shared stack read-only from
that run.

## Create the issue stack

1. Clone the Moodle source tree into the issue workdir. On APFS, use a
   copy-on-write clone:

   ```bash
   cp -Rc <shared-wwwroot> <workdir>/moodle-<issue>
   ```

   Use a full copy when the filesystem does not support clones.

2. Start moodle-docker with values unique to the issue:

   ```bash
   export COMPOSE_PROJECT_NAME=<agent><issue>
   export MOODLE_DOCKER_WWWROOT=<workdir>/moodle-<issue>
   export MOODLE_DOCKER_DB=pgsql
   export MOODLE_DOCKER_WEB_PORT=<unused-port>
   <runtime>/moodle-docker/bin/moodle-docker-compose up -d
   ```

3. Sync only the issue branch's plugin directories into the private wwwroot.
   Never sync them into `moodle52` as an intermediate step.

4. Add an uncommitted `playbooks/test.<stack>.env` for the existing test
   runner:

   ```dotenv
   CONTAINER="<agent><issue>-webserver-1"
   MOODLE_REPO_ROOT="/var/www/html"
   MOODLE_CLI_ROOT="/var/www/html/public"
   ```

   Use `/var/www/html` for both roots on Moodle branches without the
   `public/` split.

## Provision dependencies before init

Inspect every deployed plugin's `$plugin->dependencies` before Moodle install,
upgrade, PHPUnit init, or Behat init. The Lernhive
`local_lernhive_orgchart` plugin has a hard dependency on
`tool_dynamic_cohorts`, so the issue wwwroot must contain:

```text
public/admin/tool/dynamic_cohorts/version.php
```

Pin the dependency to a revision tested against the target Moodle branch and
record that revision with the test result. At the time this playbook was
written, upstream `tool_dynamic_cohorts` release `2026031300` declared support
through Moodle 5.1, not 5.2. Do not treat an unpinned clone or a successful
file copy as Moodle 5.2 compatibility evidence.

Run Moodle's non-interactive upgrade after all dependencies and Lernhive
plugins are present, then initialize the selected test environment.

## Run and clean up

Run the normal wrapper against the private target:

```bash
playbooks/test.sh --target=<stack> --suite=phpunit --component=<component>
playbooks/test.sh --target=<stack> --suite=behat --tags=<tags>
```

Use the same exported moodle-docker variables for cleanup:

```bash
<runtime>/moodle-docker/bin/moodle-docker-compose stop
```

Use `down` when the issue stack and its volumes are no longer needed. The
private source clone may remain for follow-up runs.

If a freshly initialized environment immediately reports a `versionshash` or
“initialised for different version” mismatch, compare the mounted plugin
commits and dataroot ownership before re-running init. The expected fix is to
remove the shared-state mutation, not to retry on `moodle52`.
