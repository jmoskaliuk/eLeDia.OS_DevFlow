#!/usr/bin/env bash
# moodle-test — Run Moodle plugin quality checks inside the local Docker container.
#
# Usage: bash test.sh --plugin mod/eledialeitnerflow [--fix] [--filter NAME]
#        bash test.sh --plugin mod/eledialeitnerflow --install-tools
#
# See SKILL.md for full documentation.

set -euo pipefail

# -----------------------------------------------------------------------------
# Defaults (hard-coded for Johannes' OrbStack/Docker setup)
# -----------------------------------------------------------------------------
CONTAINER="demo-webserver-1"
# Moodle 5.x "public" layout: dirroot (web-facing) lives at /var/www/site/moodle/public,
# but Composer/vendor/phpunit.xml.dist live at the project root one level up.
MOODLE_ROOT="/var/www/site/moodle/public"
PROJECT_ROOT=""  # Auto-derived from MOODLE_ROOT if empty (parent dir)
PLUGIN=""
FIX=0
SKIP_PHPUNIT=0
SKIP_CODECHECK=0
FILTER=""
INSTALL_TOOLS=0
# All agents using the shared PHPUnit dataroot must serialize initialization and
# test execution. Keep the lock in the container so it is shared across hosts.
PHPUNIT_LOCK="/var/www/phpunitdata/.phpunit.lock"

# -----------------------------------------------------------------------------
# Colors
# -----------------------------------------------------------------------------
if [[ -t 1 ]]; then
  C_RED=$'\033[31m'; C_GREEN=$'\033[32m'; C_YELLOW=$'\033[33m'
  C_BLUE=$'\033[34m'; C_BOLD=$'\033[1m'; C_RESET=$'\033[0m'
else
  C_RED=""; C_GREEN=""; C_YELLOW=""; C_BLUE=""; C_BOLD=""; C_RESET=""
fi

info()  { echo "${C_BLUE}[i]${C_RESET} $*"; }
ok()    { echo "${C_GREEN}[✓]${C_RESET} $*"; }
warn()  { echo "${C_YELLOW}[!]${C_RESET} $*"; }
err()   { echo "${C_RED}[✗]${C_RESET} $*" >&2; }
hdr()   { echo; echo "${C_BOLD}==> $*${C_RESET}"; }

# -----------------------------------------------------------------------------
# Arg parsing
# -----------------------------------------------------------------------------
usage() {
  cat <<EOF
Usage: $0 --plugin <path> [options]

Required:
  --plugin <path>       Plugin path relative to Moodle root (e.g. mod/eledialeitnerflow)

Options:
  --fix                 Run PHPCBF first to auto-fix formatting
  --skip-phpunit        Skip unit tests
  --skip-codecheck      Skip codechecker
  --filter <name>       --filter passed through to phpunit
  --container <name>    Container name (default: $CONTAINER)
  --moodle-root <path>  Moodle root inside container (default: $MOODLE_ROOT)
  --install-tools       First-time setup: install codechecker + init phpunit
  -h, --help            Show this help
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --plugin)        PLUGIN="$2"; shift 2 ;;
    --fix)           FIX=1; shift ;;
    --skip-phpunit)  SKIP_PHPUNIT=1; shift ;;
    --skip-codecheck) SKIP_CODECHECK=1; shift ;;
    --filter)        FILTER="$2"; shift 2 ;;
    --container)     CONTAINER="$2"; shift 2 ;;
    --moodle-root)   MOODLE_ROOT="$2"; shift 2 ;;
    --install-tools) INSTALL_TOOLS=1; shift ;;
    -h|--help)       usage; exit 0 ;;
    *) err "Unknown argument: $1"; usage; exit 1 ;;
  esac
done

if [[ -z "$PLUGIN" ]]; then
  err "Missing required --plugin <path>"
  usage
  exit 1
fi

# Auto-derive PROJECT_ROOT (one level up from MOODLE_ROOT in Moodle 5.x public layout)
if [[ -z "$PROJECT_ROOT" ]]; then
  PROJECT_ROOT="$(dirname "$MOODLE_ROOT")"
fi
# Plugin path relative to PROJECT_ROOT (for phpunit invocation)
MOODLE_ROOT_NAME="$(basename "$MOODLE_ROOT")"
PLUGIN_FROM_PROJECT="${MOODLE_ROOT_NAME}/${PLUGIN}"

# -----------------------------------------------------------------------------
# Helper: run a command inside the container with the Moodle root as cwd
# -----------------------------------------------------------------------------
in_container() {
  docker exec -w "$MOODLE_ROOT" "$CONTAINER" "$@"
}

in_container_bash() {
  docker exec -w "$MOODLE_ROOT" "$CONTAINER" bash -c "$1"
}

# Test helper — must go through bash because `test` is a shell builtin
# and is not reliably available as a standalone binary in all containers.
in_container_test() {
  docker exec -w "$MOODLE_ROOT" "$CONTAINER" bash -c "$1"
}

# Same as in_container but uses PROJECT_ROOT as cwd (for phpunit from project root).
in_project() {
  docker exec -w "$PROJECT_ROOT" "$CONTAINER" "$@"
}
in_project_test() {
  docker exec -w "$PROJECT_ROOT" "$CONTAINER" bash -c "$1"
}

# Run a PHPUnit-dataroot-mutating command while holding the shared container lock.
# The lock deliberately covers both init.php and the complete PHPUnit process;
# locking only initialization would still allow concurrent tests to wipe caches.
in_project_locked() {
  docker exec -w "$PROJECT_ROOT" "$CONTAINER" flock -x "$PHPUNIT_LOCK" -- "$@"
}

# -----------------------------------------------------------------------------
# Sanity checks
# -----------------------------------------------------------------------------
hdr "Sanity checks"

if ! docker ps --format '{{.Names}}' | grep -qx "$CONTAINER"; then
  err "Container '$CONTAINER' is not running."
  err "Start it with: cd ~/demo && docker compose up -d"
  exit 2
fi
ok "Container '$CONTAINER' is running"

if ! in_container_test "[ -d '$MOODLE_ROOT' ]"; then
  err "Moodle root '$MOODLE_ROOT' does not exist inside the container."
  exit 2
fi
ok "Moodle root exists: $MOODLE_ROOT"

if ! in_project_test "[ -d '$PROJECT_ROOT' ]"; then
  err "Project root '$PROJECT_ROOT' does not exist inside the container."
  exit 2
fi
ok "Project root exists: $PROJECT_ROOT"

if ! in_container_test "[ -d '$MOODLE_ROOT/$PLUGIN' ]"; then
  err "Plugin path '$PLUGIN' does not exist inside Moodle root."
  err "Tried: $MOODLE_ROOT/$PLUGIN"
  exit 2
fi
ok "Plugin found: $PLUGIN"

if ! in_container_test "command -v flock >/dev/null 2>&1"; then
  err "The container does not provide flock; cannot safely use the shared PHPUnit dataroot."
  exit 3
fi
in_container mkdir -p "$(dirname "$PHPUNIT_LOCK")"

# -----------------------------------------------------------------------------
# First-time setup
# -----------------------------------------------------------------------------
if [[ "$INSTALL_TOOLS" == "1" ]]; then
  hdr "First-time setup"

  info "Checking composer..."
  if ! in_container bash -c 'command -v composer >/dev/null 2>&1'; then
    info "Installing composer in container..."
    in_container_bash '
      cd /tmp && \
      php -r "copy(\"https://getcomposer.org/installer\", \"composer-setup.php\");" && \
      php composer-setup.php --install-dir=/usr/local/bin --filename=composer && \
      rm composer-setup.php
    '
    ok "Composer installed"
  else
    ok "Composer already installed"
  fi

  info "Checking codechecker..."
  if ! in_container_test "[ -d '$MOODLE_ROOT/local/codechecker' ]"; then
    info "Cloning moodle-local_codechecker..."
    in_container_bash 'git clone --depth 1 https://github.com/moodlehq/moodle-local_codechecker.git local/codechecker'
    info "Running composer install for codechecker..."
    in_container_bash 'cd local/codechecker && composer install --no-interaction --no-progress'
    ok "Codechecker installed"
  else
    ok "Codechecker already present"
  fi

  info "Checking phpunit config..."
  # In Moodle 5.x public layout, phpunit.xml(.dist) and vendor/ live at PROJECT_ROOT
  # (one level above dirroot), so init.php must run from there.
  if in_project_test "[ -f '$PROJECT_ROOT/phpunit.xml' ] || [ -f '$PROJECT_ROOT/phpunit.xml.dist' ]"; then
    ok "PHPUnit config already present at $PROJECT_ROOT"
  else
    info "Initializing PHPUnit from $PROJECT_ROOT (this can take a minute)..."
    info "Waiting for shared PHPUnit lock: $PHPUNIT_LOCK"
    if ! in_project_locked php "$MOODLE_ROOT_NAME/admin/tool/phpunit/cli/init.php"; then
      err "PHPUnit init failed."
      err "Make sure these lines are in config.php:"
      err '  $CFG->phpunit_prefix = "phpu_";'
      err '  $CFG->phpunit_dataroot = "/var/www/phpunit_dataroot";'
      exit 3
    fi
    ok "PHPUnit initialized"
  fi
fi

# -----------------------------------------------------------------------------
# PHPCBF (auto-fix)
# -----------------------------------------------------------------------------
if [[ "$FIX" == "1" ]]; then
  hdr "PHPCBF — auto-fixing formatting in $PLUGIN"
  if ! in_container_test "[ -f '$MOODLE_ROOT/local/codechecker/vendor/bin/phpcbf' ]"; then
    err "phpcbf not found. Run with --install-tools first."
    exit 3
  fi
  set +e
  in_container php local/codechecker/vendor/bin/phpcbf --standard=moodle "$PLUGIN"
  CBF_EXIT=$?
  set -e
  # phpcbf exits 1 when it fixed things — that's success for us.
  if [[ $CBF_EXIT -eq 0 ]]; then
    ok "PHPCBF: nothing to fix"
  elif [[ $CBF_EXIT -eq 1 ]]; then
    ok "PHPCBF: violations were auto-fixed"
  else
    err "PHPCBF exited with code $CBF_EXIT"
  fi
fi

# -----------------------------------------------------------------------------
# Codechecker
# -----------------------------------------------------------------------------
CODECHECK_EXIT=0
if [[ "$SKIP_CODECHECK" == "0" ]]; then
  hdr "Codechecker — running phpcs --standard=moodle $PLUGIN"
  if ! in_container_test "[ -f '$MOODLE_ROOT/local/codechecker/vendor/bin/phpcs' ]"; then
    err "phpcs not found. Run with --install-tools first."
    exit 3
  fi
  set +e
  in_container php local/codechecker/vendor/bin/phpcs --standard=moodle --report=full --colors "$PLUGIN"
  CODECHECK_EXIT=$?
  set -e
  if [[ $CODECHECK_EXIT -eq 0 ]]; then
    ok "Codechecker: 0 errors, 0 warnings"
  else
    warn "Codechecker reported issues (exit $CODECHECK_EXIT)"
  fi
fi

# -----------------------------------------------------------------------------
# PHPUnit
# -----------------------------------------------------------------------------
PHPUNIT_EXIT=0
if [[ "$SKIP_PHPUNIT" == "0" ]]; then
  hdr "PHPUnit — running tests in $PLUGIN/tests"
  info "Project root:  $PROJECT_ROOT"
  info "Plugin path:   $PLUGIN_FROM_PROJECT"

  # In Moodle 5.x public layout: phpunit.xml(.dist) and vendor/ live at PROJECT_ROOT
  # (one level up from dirroot). Accept either phpunit.xml or phpunit.xml.dist.
  PHPUNIT_CONFIG=""
  if in_project_test "[ -f '$PROJECT_ROOT/phpunit.xml' ]"; then
    PHPUNIT_CONFIG="phpunit.xml"
  elif in_project_test "[ -f '$PROJECT_ROOT/phpunit.xml.dist' ]"; then
    PHPUNIT_CONFIG="phpunit.xml.dist"
  else
    err "Neither phpunit.xml nor phpunit.xml.dist exists at $PROJECT_ROOT."
    err "Run with --install-tools and verify: docker exec $CONTAINER ls $PROJECT_ROOT/phpunit*"
    exit 3
  fi
  info "Config:        $PHPUNIT_CONFIG"

  if ! in_project_test "[ -f '$PROJECT_ROOT/vendor/bin/phpunit' ]"; then
    err "phpunit binary not found at $PROJECT_ROOT/vendor/bin/phpunit"
    err "Run: docker exec -w $PROJECT_ROOT $CONTAINER composer install --no-interaction"
    exit 3
  fi
  info "Binary:        vendor/bin/phpunit"

  # Derive Moodle component name from plugin path:
  #   mod/eledialeitnerflow       -> mod_eledialeitnerflow
  #   blocks/eledialeitnerflow    -> block_eledialeitnerflow
  #   local/testdata              -> local_testdata
  PLUGIN_TYPE="${PLUGIN%%/*}"
  PLUGIN_NAME="${PLUGIN##*/}"
  case "$PLUGIN_TYPE" in
    blocks) COMPONENT="block_${PLUGIN_NAME}" ;;
    *)      COMPONENT="${PLUGIN_TYPE}_${PLUGIN_NAME}" ;;
  esac
  TESTSUITE="${COMPONENT}_testsuite"
  info "Testsuite:     $TESTSUITE"

  PHPUNIT_ARGS=(-c "$PHPUNIT_CONFIG" --colors=always --testsuite "$TESTSUITE")
  if [[ -n "$FILTER" ]]; then
    PHPUNIT_ARGS+=(--filter "$FILTER")
  fi

  info "Waiting for shared PHPUnit lock: $PHPUNIT_LOCK"
  set +e
  PHPUNIT_OUTPUT=$(in_project_locked php vendor/bin/phpunit "${PHPUNIT_ARGS[@]}" 2>&1)
  PHPUNIT_EXIT=$?
  set -e
  echo "$PHPUNIT_OUTPUT"
  if [[ $PHPUNIT_EXIT -eq 0 ]]; then
    if echo "$PHPUNIT_OUTPUT" | grep -q "No tests executed"; then
      err "PHPUnit ran but discovered 0 tests — testsuite '$TESTSUITE' may not exist in $PHPUNIT_CONFIG."
      err "Check: docker exec -w $PROJECT_ROOT $CONTAINER grep -n '$TESTSUITE' $PHPUNIT_CONFIG"
      PHPUNIT_EXIT=1
    else
      ok "PHPUnit: all tests passed"
    fi
  else
    err "PHPUnit failed (exit $PHPUNIT_EXIT)"
  fi
fi

# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------
hdr "Summary"
echo "  Plugin:       $PLUGIN"
echo "  Container:    $CONTAINER"
echo "  Moodle root:  $MOODLE_ROOT"
echo "  Project root: $PROJECT_ROOT"
[[ "$FIX" == "1" ]]           && echo "  PHPCBF:       ran"
[[ "$SKIP_CODECHECK" == "0" ]] && echo "  Codechecker:  exit $CODECHECK_EXIT"
[[ "$SKIP_PHPUNIT" == "0" ]]   && echo "  PHPUnit:      exit $PHPUNIT_EXIT"

# Final exit code: nonzero if either tool failed
FINAL=0
[[ $CODECHECK_EXIT -ne 0 ]] && FINAL=1
[[ $PHPUNIT_EXIT   -ne 0 ]] && FINAL=1
exit $FINAL
