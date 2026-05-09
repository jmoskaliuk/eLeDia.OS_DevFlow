---
name: odoo-testing
description: >
  Test-Strategie und -Implementierung für Odoo-18-Module — Python-Tests
  (TransactionCase, SingleTransactionCase, HttpCase, common.SavepointCase),
  JS-Tests (QUnit, Hoot — neu in Odoo 18), Tours (Tour-Tests im Browser),
  Test-Tags, Test-Daten via populate, Mocking, CI mit odoo-bin --test-enable.
  Verwende diesen Skill für jede Frage zu Tests, Coverage, Test-Fixtures,
  Test-Performance, Flaky-Tests, CI-Konfiguration. Trigger bei "Test", "tagged",
  "TransactionCase", "HttpCase", "QUnit", "Hoot", "Tour", "Tour-Test",
  "test-tags", "test-enable", "Mock", "patch", "fixture", "populate", "TestCase",
  "Coverage", oder Test-Datei-Namen wie test_*.py, tests/*.py.
  Pair mit odoo-coding-guidelines (Test-Style) und odoo-deploy (CI-Integration).
---

# Odoo 18 — Testing

Odoo hat ein eingebautes Test-Framework auf Basis von Python `unittest`. Tests
laufen in Transaktionen, die nach jedem Test zurückgerollt werden — d.h.
Test-Daten kommen und gehen ohne DB-Cleanup.

**Quelle:** https://www.odoo.com/documentation/18.0/developer/reference/backend/testing.html

> **Odoo 18 Highlight:** Das neue **Hoot**-Test-Framework ersetzt QUnit für
> Frontend-Tests. QUnit funktioniert noch, neue Tests sollten in Hoot geschrieben
> werden.

---

## 1. Test-Klassen — Welche wann

| Klasse | Transaktion | Setup pro | Wann |
|---|---|---|---|
| `TransactionCase` | rollback nach jedem Test | Test | Default für Modell-Tests |
| `SingleTransactionCase` | rollback nach Test-Klasse | Klasse | Teure Setups, Read-Only-Tests |
| `HttpCase` | rollback nach Klasse | Klasse | HTTP-Endpunkte, Tours |
| `BaseCase` | keine | — | Pure-Python ohne DB |
| `MailCommon` (`mail.tests.common.MailCommon`) | wie `TransactionCase` | Klasse | Mail-Templates, Notifications |
| `AccountTestInvoicingCommon` | wie `TransactionCase` | Klasse | Buchhaltungs-Tests |

`SavepointCase` aus älteren Versionen ist seit 16 weg — verwende
`TransactionCase`, das Verhalten ist identisch.

---

## 2. Minimal-Test

```python
# tests/test_eledia_project.py
from odoo.tests.common import TransactionCase, tagged
from odoo.exceptions import UserError, ValidationError
from odoo import Command


@tagged('post_install', '-at_install', 'eledia_project')
class TestEledialProject(TransactionCase):

    @classmethod
    def setUpClass(cls):
        super().setUpClass()
        cls.user_demo = cls.env.ref('base.user_demo')
        cls.partner = cls.env['res.partner'].create({
            'name': 'Test Partner',
            'email': 'test@example.com',
        })
        cls.project = cls.env['eledia.project'].create({
            'name': 'Test Project',
            'user_id': cls.user_demo.id,
            'line_ids': [
                Command.create({'name': 'Line 1', 'amount': 100.0}),
                Command.create({'name': 'Line 2', 'amount': 200.0}),
            ],
        })

    def test_compute_total_amount(self):
        """Total amount = Summe der Zeilen."""
        self.assertEqual(self.project.total_amount, 300.0)

    def test_state_workflow(self):
        """Draft → Active → Done."""
        self.assertEqual(self.project.state, 'draft')
        self.project.action_activate()
        self.assertEqual(self.project.state, 'active')
        self.project.action_done()
        self.assertEqual(self.project.state, 'done')

    def test_cannot_activate_without_lines(self):
        """Aktivierung ohne Zeilen wirft UserError."""
        empty = self.env['eledia.project'].create({'name': 'Empty'})
        with self.assertRaises(UserError):
            empty.action_activate()

    def test_cannot_unlink_active(self):
        """Aktive Projekte sind nicht löschbar."""
        self.project.action_activate()
        with self.assertRaises(UserError):
            self.project.unlink()

    def test_user_isolation(self):
        """User sieht nur eigene Projekte."""
        other_user = self.env['res.users'].create({
            'name': 'Other',
            'login': 'other@example.com',
        })
        self.env['eledia.project'].create({
            'name': 'Foreign',
            'user_id': other_user.id,
        })
        own_projects = self.env['eledia.project'].with_user(self.user_demo).search([])
        self.assertNotIn('Foreign', own_projects.mapped('name'))
```

---

## 3. Test-Tags

`@tagged(...)` steuert, welche Tests in welcher Phase laufen.

### Eingebaute Tags

| Tag | Wirkung |
|---|---|
| `at_install` | Vor anderen Modulen — beim Installieren |
| `post_install` | Nach allen Modulen — Default für Integrationstests |
| `-at_install` | Negation — explizit ausschließen |
| `standard` | Default-Tag für alle Tests |
| `nightly` | Nur in Nightly-Builds |
| `slow` | Langsame Tests (Tour, Selenium) |

**Empfohlen:**

```python
@tagged('post_install', '-at_install', 'eledia_project')
class TestX(TransactionCase):
    ...
```

`post_install` weil bei Modul-Install andere Module noch nicht da sind. `-at_install`
verhindert, dass derselbe Test zweimal läuft.

### Eigene Tags

`'eledia_project'` ist ein Custom-Tag → man kann gezielt nur diese Tests
ausführen:

```bash
odoo-bin -d testdb -i eledia_project --test-enable --stop-after-init \
  --test-tags='/eledia_project'
```

### Tag-Filter beim Run

```bash
# Nur post_install
--test-tags='/eledia_project:TestEledialProject.test_state_workflow'

# Mehrere Tags (OR)
--test-tags='post_install,nightly'

# Negation
--test-tags='-slow'

# Modul:Klasse:Methode
--test-tags='/eledia_project:TestEledialProject.test_state_workflow'
```

---

## 4. Häufige Test-Patterns

### Mit anderem User testen

```python
def test_as_user(self):
    project_as_demo = self.project.with_user(self.user_demo)
    project_as_demo.action_activate()
```

`with_user` re-evaluiert `env.uid`, `env.context.uid`, und respektiert ACL +
Rules. **Korrekte Form** für Permission-Tests.

### Mit anderer Company

```python
def test_multi_company(self):
    company_b = self.env['res.company'].create({'name': 'Company B'})
    self.user_demo.company_ids = [Command.link(company_b.id)]
    project_b = self.env['eledia.project'].with_user(self.user_demo).with_company(company_b).create({
        'name': 'In B',
    })
    self.assertEqual(project_b.company_id, company_b)
```

### Sub-Tests (mehrere Asserts in Schleife)

```python
def test_multiple_states(self):
    cases = [
        ('draft', 'active'),
        ('active', 'done'),
        ('draft', 'cancel'),
    ]
    for src, dst in cases:
        with self.subTest(src=src, dst=dst):
            project = self.env['eledia.project'].create({'name': f'{src}→{dst}'})
            project.state = src
            getattr(project, f'action_{dst}')()
            self.assertEqual(project.state, dst)
```

### Mocking

```python
from unittest.mock import patch, MagicMock

def test_external_api_call(self):
    with patch('odoo.addons.eledia_project.models.eledia_project.requests.post') as mock_post:
        mock_post.return_value = MagicMock(status_code=200, json=lambda: {'ok': True})
        result = self.project.action_send_to_external()
        mock_post.assert_called_once()
        self.assertTrue(result)
```

Für Models ohne externen Call ist Mocking selten nötig — Odoo-Tests laufen
ohnehin in einer geschützten Transaktion.

### Errors testen

```python
# UserError
with self.assertRaises(UserError) as cm:
    self.project.action_invalid()
self.assertIn("nicht erlaubt", str(cm.exception))

# ValidationError
with self.assertRaises(ValidationError):
    self.env['eledia.project'].create({'name': '', 'user_id': self.user_demo.id})

# Beliebiges Exception
with self.assertRaisesRegex(ValueError, "Invalid"):
    self.project._compute_invalid_field()
```

### Mail-Tests

```python
from odoo.addons.mail.tests.common import MailCommon


@tagged('post_install', '-at_install')
class TestEledialProjectMail(MailCommon):

    def test_state_change_sends_mail(self):
        with self.mock_mail_gateway():
            self.project.action_activate()
        self.assertEqual(len(self._new_mails), 1)
        self.assertIn('aktiviert', self._new_mails.body_html)

    def test_post_message(self):
        msg = self.project.message_post(body='Hello')
        self.assertEqual(msg.body, '<p>Hello</p>')
```

`mock_mail_gateway()` fängt alle gesendeten Mails ab; sie landen in `self._new_mails`.

### Snapshot-Test mit `recompute_records`

```python
def test_compute_after_change(self):
    self.project.line_ids[0].amount = 999
    self.project.invalidate_recordset(['total_amount'])    # Cache invalidieren
    self.assertEqual(self.project.total_amount, 1199.0)
```

`invalidate_recordset` in Odoo 17+ (vorher: `invalidate_cache` auf env).

---

## 5. HTTP-Tests (HttpCase)

```python
from odoo.tests.common import HttpCase, tagged


@tagged('post_install', '-at_install', 'eledia_project_http')
class TestEledialProjectHttp(HttpCase):

    def test_portal_my_projects_anonymous(self):
        """Anonyme Anfrage → Redirect auf Login."""
        response = self.url_open('/my/projects')
        self.assertEqual(response.status_code, 200)
        self.assertIn('/web/login', response.url)

    def test_portal_my_projects_logged_in(self):
        self.authenticate('demo', 'demo')
        response = self.url_open('/my/projects')
        self.assertEqual(response.status_code, 200)
        self.assertIn('Meine Projekte', response.text)

    def test_json_endpoint(self):
        self.authenticate('demo', 'demo')
        response = self.url_open(
            '/api/v1/projects',
            data='{}',
            headers={'Content-Type': 'application/json'},
        )
        result = response.json()
        self.assertIn('result', result)

    def test_csrf_protection(self):
        response = self.url_open(
            '/portal/projects/create',
            data='name=Foo',
            headers={'Content-Type': 'application/x-www-form-urlencoded'},
        )
        self.assertEqual(response.status_code, 400)              # CSRF-Token fehlt
```

`HttpCase` startet einen Worker auf einem Test-Port und macht echte HTTP-Requests.

---

## 6. Tour-Tests (Browser-Automation)

Tours sind Frontend-Test-Scripts, die wie ein User durch die UI klicken.

### Tour definieren

```javascript
// static/tests/tours/eledia_project_tour.js
/** @odoo-module **/

import { registry } from "@web/core/registry";
import { stepUtils } from "@web_tour/tour_service/tour_utils";

registry.category("web_tour.tours").add("eledia_project_tour", {
    test: true,
    url: "/odoo/eledia",
    steps: () => [
        stepUtils.showAppsMenuItem(),
        {
            content: "App-Menü: eLeDia auswählen",
            trigger: '.o_app[data-menu-xmlid="eledia_project.menu_eledia_root"]',
            run: "click",
        },
        {
            content: "Neuer Projekt-Button",
            trigger: 'button.o_list_button_add',
            run: "click",
        },
        {
            content: "Name eingeben",
            trigger: 'div[name="name"] input',
            run: "edit Test Project von Tour",
        },
        {
            content: "Speichern",
            trigger: '.o_form_button_save',
            run: "click",
        },
        {
            content: "Aktivieren-Button",
            trigger: 'button[name="action_activate"]',
            run: "click",
        },
        {
            content: "State ist 'active'",
            trigger: '.o_statusbar_status button[data-value="active"].btn-primary',
            isCheck: true,
        },
    ],
});
```

### Tour aus Python triggern

```python
from odoo.tests.common import HttpCase, tagged


@tagged('post_install', '-at_install', 'eledia_project_tour')
class TestEledialProjectTour(HttpCase):

    def test_create_and_activate_tour(self):
        self.start_tour(
            url='/odoo',
            tour_name='eledia_project_tour',
            login='demo',
        )
```

### Tour-Step-Optionen

| Option | Wirkung |
|---|---|
| `trigger` | CSS-Selektor (Pflicht) |
| `content` | Beschreibung im Log |
| `run` | `"click"`, `"edit Foo"` (für Inputs), `"hover"`, eigene Funktion |
| `isCheck: true` | Nur Sichtbarkeit prüfen, keine Aktion |
| `extra_trigger` | Zusätzlicher Selektor, der auch matchen muss |
| `tooltipPosition` | `"top"`, `"bottom"`, `"left"`, `"right"` (für UI-Tour, nicht Test) |
| `timeout` | Custom-Timeout in ms |

### Asset-Bundle für Tests

```python
# __manifest__.py
'assets': {
    'web.assets_tests': [
        'eledia_project/static/tests/tours/**/*',
    ],
},
```

---

## 7. Hoot — Frontend-Tests (Odoo 18 neu)

Hoot ersetzt QUnit. Hoot-Test-Format:

```javascript
// static/tests/eledia_kpi_widget.test.js
/** @odoo-module **/

import { describe, expect, test } from "@odoo/hoot";
import { mountWithCleanup } from "@web/../tests/web_test_helpers";
import { EledialKpiWidget } from "@eledia_project/components/kpi_widget";

describe("EledialKpiWidget", () => {

    test("rendert KPIs nach dem Laden", async () => {
        const widget = await mountWithCleanup(EledialKpiWidget, {
            props: { record: { resId: 7 } },
        });
        expect(widget.el).toHaveClass("o_eledia_kpi_widget");
    });

    test("zeigt Loading bei initialem Render", async () => {
        const widget = await mountWithCleanup(EledialKpiWidget, {
            props: { record: { resId: 7 } },
        });
        expect("[class*='o_eledia_kpi_loading']").toHaveCount(1);
    });
});
```

Hoot-Tests werden im Browser via `/web/tests` ausgeführt:

```
http://localhost:8069/web/tests
```

Asset-Bundle:

```python
'assets': {
    'web.assets_unit_tests': [
        'eledia_project/static/tests/**/*.test.js',
    ],
},
```

---

## 8. Test-Daten via `populate`

Massentests (Performance, Reports) brauchen viele Records. `populate` ist der
offizielle Weg.

```python
# populate/eledia_project.py
from odoo import models


class EledialProject(models.Model):
    _inherit = 'eledia.project'
    _populate_sizes = {'small': 10, 'medium': 100, 'large': 10000}
    _populate_dependencies = ['res.partner']

    def _populate_factories(self):
        return [
            ('name', lambda values, counter, random: f'Project {counter}'),
            ('user_id', lambda values, counter, random: random.choice(self.env['res.users'].ids)),
            ('state', lambda values, counter, random: random.choice(['draft', 'active', 'done'])),
        ]
```

Im Manifest: keine spezielle Eintragung — Datei muss nur in `populate/`
liegen und in `__init__.py` importiert sein.

```bash
odoo-bin populate -c odoo.conf -d test_db --models=eledia.project --size=large
```

---

## 9. Coverage

```bash
pip install coverage
coverage run --source=addons-eledia odoo-bin -d test_db -i eledia_project \
  --test-enable --stop-after-init --test-tags=/eledia_project
coverage report -m
coverage html -d coverage_html/
```

OCA-Standard: ≥ 80% pro Modul. Kritische Module (Buchhaltung, Payment,
Security) ≥ 90%.

`pylint-odoo`-Check: keine direkter Coverage-Check, aber `missing-docstring` und
`unused-variable` schubsen in Richtung sauberer Tests.

---

## 10. CI mit `moodle-plugin-ci`-Pendant: `odoo-bin --test-enable`

### Lokale Test-Pipeline

```bash
#!/usr/bin/env bash
# bin/test.sh
set -euo pipefail

DB="test_$(date +%s)"
ODOO_BIN="odoo-bin"
ADDONS_PATH="addons,enterprise,addons-eledia"
MODULES="eledia_project,eledia_billing"

createdb "$DB"

"$ODOO_BIN" -c odoo.conf \
    -d "$DB" \
    --addons-path="$ADDONS_PATH" \
    -i "$MODULES" \
    --test-enable \
    --stop-after-init \
    --log-level=test \
    --test-tags='/eledia_project,/eledia_billing'

EXIT=$?

dropdb "$DB"
exit $EXIT
```

### GitHub Actions

```yaml
# .github/workflows/ci.yml
name: CI
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-22.04
    services:
      postgres:
        image: postgres:14
        env:
          POSTGRES_USER: odoo
          POSTGRES_PASSWORD: odoo
          POSTGRES_DB: postgres
        ports: ['5432:5432']
        options: --health-cmd pg_isready

    steps:
      - uses: actions/checkout@v4

      - name: Setup Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.10'

      - name: Clone Odoo
        run: git clone --depth=1 -b 18.0 https://github.com/odoo/odoo.git /opt/odoo

      - name: Clone Enterprise (privates Repo)
        run: |
          git clone --depth=1 -b 18.0 \
            https://${{secrets.ODOO_BOT}}@github.com/odoo/enterprise.git \
            /opt/enterprise

      - name: Install
        run: |
          pip install -r /opt/odoo/requirements.txt
          pip install -r requirements.txt
          pip install pre-commit pylint-odoo

      - name: Pre-commit
        run: pre-commit run --all-files

      - name: Run tests
        env:
          PGPASSWORD: odoo
        run: |
          createdb -h localhost -U odoo test_eledia
          /opt/odoo/odoo-bin \
            -d test_eledia \
            --addons-path=/opt/odoo/addons,/opt/enterprise,addons-eledia \
            -i eledia_project \
            --test-enable --stop-after-init \
            --log-level=test \
            --db_host=localhost --db_user=odoo --db_password=odoo
```

### `OCA/oca-ci` (für OCA-Repos)

```yaml
# .github/workflows/test.yml
on: [pull_request, push]
jobs:
  test:
    runs-on: ubuntu-22.04
    strategy:
      matrix:
        container:
          - image: ghcr.io/oca/oca-ci/py3.10-odoo18.0
    container: ${{ matrix.container.image }}
    services:
      postgres:
        image: ghcr.io/oca/oca-ci/postgres:14-alpine
    steps:
      - uses: actions/checkout@v4
      - run: oca_init_test_database
      - run: oca_run_tests
      - uses: codecov/codecov-action@v4
```

---

## 11. Flaky-Tests — Häufige Ursachen

| Ursache | Fix |
|---|---|
| Zeit-abhängige Asserts | `freeze_time` (`pip install freezegun`) |
| Random-Daten ohne Seed | Random-Seed in `setUpClass` setzen |
| Reihenfolge-Abhängigkeit zwischen Tests | jeder Test muss self-contained sein |
| `mail.activity` läuft async | `with self.mock_mail_gateway()` |
| Cron startet im Test | `--test-enable` setzt `_cron_workers=0`, sonst manuell unterdrücken |
| Tour bricht weil Element nicht da | `extra_trigger`, höherer Timeout |
| Frontend-Test schaut nach Element vor Render | `await mountWithCleanup`, dann assert |

```python
from freezegun import freeze_time

@freeze_time('2026-05-09')
def test_with_fixed_date(self):
    self.assertEqual(fields.Date.today(), date(2026, 5, 9))
```

---

## 12. Test-Performance

- `setUpClass` nutzen statt `setUp` — Klassen-Setup, einmal pro Klasse.
- `SingleTransactionCase` für reine Read-Only-Tests.
- Demo-Daten **nicht** im Test mitladen, wenn nicht nötig — `--without-demo=all`
  beim Test-Run.
- Bei `populate`-Daten: `_populate_sizes` differenzieren, Test mit `small`
  laufen lassen.
- Mit `--test-tags='-slow'` Tour-Tests vom Default ausnehmen.

---

## 13. Anti-Patterns

1. **Tests, die Demo-Daten verändern** ohne Setup-Reset → Test-Reihenfolge-Bug.
2. **`time.sleep()` in Tests** — synchronisiere via Odoo-Mechaniken.
3. **`commit()` in Tests** — Transaktion-Rollback bricht.
4. **Tests gegen Production-DB** — niemals.
5. **`raise` ohne Cause-Test** — `assertRaises` mit erwartetem Typ.
6. **Tests, die `print()` statt `_logger`** — übersieht man im Run-Output.
7. **CSS-Selektoren in Tours mit `#id`** wenn ID dynamisch — nutze `name="…"`.
8. **`@tagged('-at_install')` vergessen** — Test läuft zweimal.

---

## 14. Quellen

- Testing Reference: https://www.odoo.com/documentation/18.0/developer/reference/backend/testing.html
- Tour Test Helpers: https://www.odoo.com/documentation/18.0/developer/reference/frontend/tour_tests.html
- Hoot: https://github.com/odoo/odoo/tree/18.0/addons/web/static/lib/hoot
- OCA-CI: https://github.com/OCA/oca-ci
- Coverage: https://coverage.readthedocs.io/
- freezegun: https://github.com/spulec/freezegun
