# Installing the moodle-test skill

This folder contains a Claude skill that runs PHPUnit + Moodle Codechecker
for any plugin inside your local Docker container.

## One-time install

The skill needs to live inside your Claude skills directory so it can be
picked up automatically. On your Mac, run:

```bash
# Find the folder this file lives in (it was just created in your Cowork workspace):
SKILL_SRC=~/demo/moodle-test-skill           # adjust if you moved it
SKILL_DST=~/.claude/skills/moodle-test       # Claude's personal skills dir

mkdir -p "$(dirname "$SKILL_DST")"
cp -R "$SKILL_SRC" "$SKILL_DST"
chmod +x "$SKILL_DST/scripts/test.sh"
```

Afterwards restart Cowork/Claude Code so the new skill is detected.

## First-time container setup

The first time you ever run this on a fresh Docker container, pass
`--install-tools` so the script installs composer, clones the Moodle
codechecker, and initializes PHPUnit:

```bash
bash ~/.claude/skills/moodle-test/scripts/test.sh \
  --plugin mod/eledialeitnerflow --install-tools
```

This is idempotent — running it again won't reinstall anything that is
already present.

## Prerequisites in config.php

For PHPUnit init to succeed, your Moodle `config.php` must contain:

```php
$CFG->phpunit_prefix = 'phpu_';
$CFG->phpunit_dataroot = '/var/www/phpunit_dataroot';
```

Add these manually if they're missing — the script intentionally does
not modify `config.php` for safety.

## Daily usage

```bash
# Check code quality + run unit tests
bash ~/.claude/skills/moodle-test/scripts/test.sh --plugin mod/eledialeitnerflow

# Auto-fix formatting first, then check + test
bash ~/.claude/skills/moodle-test/scripts/test.sh --plugin mod/eledialeitnerflow --fix

# Only run a single test method
bash ~/.claude/skills/moodle-test/scripts/test.sh \
  --plugin mod/eledialeitnerflow --filter test_calculate_box

# Only run codechecker, skip tests
bash ~/.claude/skills/moodle-test/scripts/test.sh \
  --plugin mod/eledialeitnerflow --skip-phpunit
```

Or just ask Claude: "run the tests for eledialeitnerflow" — it will invoke
the skill for you.
