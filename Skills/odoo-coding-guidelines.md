---
name: odoo-coding-guidelines
description: >
  Style-Guide und Coding-Standards für Odoo-18-Entwicklung. Verwende diesen Skill,
  wenn es um Code-Style, Naming, XML-IDs, Idiome, Formatierung, pylint-odoo,
  pre-commit, OCA-Abweichungen, PEP 8 in Odoo-Kontext, oder Review-Findings geht.
  Trigger bei "Coding Guidelines", "Style Guide", "Naming Convention", "XML-ID",
  "pylint-odoo", "pre-commit", "OCA Guidelines", "PEP 8", "PEP 257",
  "Code-Review-Feedback", "Linting", "ESLint Odoo", "isort", "black".
  Pair mit odoo-dev für strukturelle Themen (ORM, Inheritance) und mit
  odoo-views-frontend für View-spezifische Style-Regeln.
---

# Odoo 18 — Coding Guidelines & Style

Konsolidierte Regeln aus den offiziellen Odoo-18-Coding-Guidelines plus den
strikteren OCA-Standards. **Wenn beide kollidieren**, ist OCA strenger — bei
Modulen für die OCA-Repos folge OCA, bei Modulen ausschließlich für Apps-Store
oder eigene Kunden reicht der Odoo-Standard, OCA ist aber empfohlen.

**Quelle Odoo:** https://www.odoo.com/documentation/18.0/contributing/development/coding_guidelines.html
**Quelle OCA:** https://github.com/OCA/odoo-community.org/blob/master/website/Contribution/CONTRIBUTING.rst

---

## 1. Modul-Struktur (verbindlich)

Standard-Verzeichnisse — kein „models2/", kein „helpers/", kein „utils/" auf
Modul-Wurzel:

```
my_module/
├── __init__.py            (nur from . import …)
├── __manifest__.py
├── README.rst             (OCA-Pflicht; sonst .md)
├── controllers/           (HTTP-Routen)
├── data/                  (Master-Daten, immer geladen)
├── demo/                  (nur bei demo=True)
├── i18n/                  (.pot, .po)
├── models/                (Geschäftsmodelle)
├── populate/              (Mass-Demo-Daten, Odoo 16+)
├── reports/               (QWeb-Reports)
├── security/              (CSV + ir.rule + groups)
├── static/description/    (icon.png, index.html)
├── static/src/            (JS, SCSS, OWL-XML)
├── tests/
├── views/                 (alle XML-Views)
└── wizards/               (TransientModel)
```

**Verboten:**

- Python-Files auf Modul-Wurzel außer `__init__.py` und `__manifest__.py`.
- Helper-Module mit `_` als Präfix (`_utils.py`) — gehört nach `models/utils.py`
  oder als `AbstractModel`.
- Mehrere Modelle in einer Datei, wenn sie inhaltlich getrennt sind. Faustregel:
  ein Top-Level-Modell = eine Datei.

**Datei-Naming:**

- Snake-Case, kein CamelCase. `sale_order.py`, nicht `SaleOrder.py`.
- Erweiterungen bestehender Modelle bekommen exakt den Modellnamen mit Punkten
  als Unterstriche: `res_partner.py` für `_inherit = 'res.partner'`.

---

## 2. Python-Stil

### Allgemein (PEP 8 mit Odoo-Erweiterungen)

- **Zeilenlänge:** 120 Zeichen (Odoo) / 88 Zeichen (OCA, weil `black`).
- **Indents:** 4 Spaces. Niemals Tabs.
- **Quotes:** Single-Quotes (`'`) für Strings, Double für Docstrings (`"""…"""`).
- **Trailing comma** bei mehrzeiligen Listen/Dicts/Args — verbindlich.
- **Imports** in drei Blöcken:

  ```python
  # 1. stdlib
  import logging
  from datetime import timedelta
  
  # 2. third-party
  import requests
  
  # 3. odoo + odoo.addons
  from odoo import api, fields, models, _
  from odoo.exceptions import UserError, ValidationError
  from odoo.tools import float_compare, float_round
  from odoo.addons.account.models.account_move import AccountMove
  ```

- Nie `from odoo.addons.foo import *`.
- Nie absolute `import addons.foo` — immer `from odoo.addons.foo import …`.

### File-Header (Odoo, OCA-strenger)

Odoo-Standard (optional):

```python
# -*- coding: utf-8 -*-
# Part of Odoo. See LICENSE file for full copyright and licensing details.
```

OCA-Standard (Pflicht):

```python
# Copyright 2026 eLeDia GmbH
# License OPL-1 - See LICENSE file for full copyright and licensing details.
```

Keine `#!/usr/bin/env python3`-Shebangs in Modul-Code (außer Stand-alone-Scripts
unter `tools/`).

### Klassennamen

- CamelCase, **Modellname als Klasse**: `ResPartner`, `SaleOrderLine`,
  `EledialProjectKpi`.
- Bei `_inherit`-Extensions: dieselbe Klasse, im eigenen Modul. Keine `Mixin`-
  Suffixe wenn nicht wirklich Mixin (`AbstractModel`).

```python
# GUT
class ResPartner(models.Model):
    _inherit = 'res.partner'

# SCHLECHT
class PartnerExtended(models.Model):
    _inherit = 'res.partner'
```

### Methoden-Naming

| Pattern | Verwendung |
|---|---|
| `_compute_<field>` | Compute-Methode für `<field>` |
| `_inverse_<field>` | Inverse für computed Field |
| `_search_<field>` | Custom-Search für non-stored computed |
| `_default_<field>` | Default-Callable |
| `_check_<rule>` | `@api.constrains` |
| `_onchange_<field>` | `@api.onchange` |
| `_<verb>_<noun>` | private Helper |
| `action_<verb>` | Public, von Buttons in Views aufrufbar |
| `cron_<verb>` | Public, von `ir.cron` aufgerufen |
| `_cron_<verb>` | Private Cron-Helper |

```python
# GUT
def action_confirm(self):
    ...

def _check_amount_positive(self):
    ...

# SCHLECHT
def confirm(self):                # public ohne action_
    ...
def amount_positive_check(self):  # ohne _, ohne _check_-Präfix
    ...
```

### Variable-Naming

- Snake-Case.
- Recordsets im Plural (`partners`, `invoices`), Single-Records im Singular
  (`partner`, `invoice`).
- IDs als `_id` / `_ids`-Suffix nur, wenn es **wirklich** eine ID ist (Integer):
  ```python
  partner_id = self.partner_id.id      # int
  partner = self.partner_id            # Recordset
  ```

### Docstrings (PEP 257, ReST)

```python
def _compute_amount_total(self):
    """Compute the total amount including taxes.

    The total is the sum of all line amounts plus the configured tax rate.
    Recomputes when ``line_ids.amount`` or ``tax_rate`` change.

    :raises UserError: if any line has a negative amount and ``allow_negative``
        is False.
    """
```

OCA verlangt Docstrings für alle public-Methoden außer Computed-Internals.
Odoo-Standard ist lascher — Docstrings nur wenn nicht-trivial.

### Logging

```python
import logging
_logger = logging.getLogger(__name__)

_logger.info("Project %s activated by %s", project.name, self.env.user.login)
_logger.warning("Deprecated field accessed: %s", field_name)
_logger.error("Stripe charge failed: %s", exc, exc_info=True)
```

- **Niemals** f-Strings im Logger: `_logger.info(f"…")`. Verhindert Lazy-Evaluation
  und hängt PII potenziell in Logs, die der Logger sonst per Filter unterdrücken
  könnte. Immer `%s`-Format.
- **Niemals** `print()` in Modul-Code.

---

## 3. ORM-Idiome

### Domain-Tupel

```python
# GUT — Listen mit Tupeln
domain = [
    ('state', '=', 'posted'),
    ('amount_total', '>', 0),
    '|',                             # OR
    ('partner_id.country_id.code', '=', 'DE'),
    ('partner_id.country_id.code', '=', 'AT'),
]

# SCHLECHT — Strings
domain = "[('state','=','posted')]"
```

### Verfügbare Operatoren

`=`, `!=`, `>`, `>=`, `<`, `<=`, `=?` (gleich oder leer), `=like`, `=ilike`,
`like`, `not like`, `ilike`, `not ilike`, `in`, `not in`, `child_of`,
`parent_of`, `any`, `not any` (Odoo 17+ für relationale Subqueries).

```python
# any / not any (Odoo 17+) — relationale Subquery
domain = [
    ('order_line_ids', 'any', [('product_id.type', '=', 'service')]),
]
# alt: ('order_line_ids.product_id.type', '=', 'service') — semantisch leicht anders
```

### Search-Patterns

```python
# Mit Limit und Order
recent = env['sale.order'].search([], limit=10, order='create_date desc')

# Count
count = env['sale.order'].search_count([('state', '=', 'sale')])

# Existenz-Check (schneller als search_count > 0)
exists = bool(env['sale.order'].search([('state', '=', 'sale')], limit=1))

# Mit User-RLS umgangen — NUR mit Begründung (Audit-Log!)
all_orders = env['sale.order'].sudo().search([])
```

### Niemals ohne Pagination iterieren

```python
# SCHLECHT — kann RAM sprengen
for order in env['sale.order'].search([]):
    process(order)

# BESSER
for orders in env['sale.order']._read_group_iter(...):  # Odoo 17+
    ...

# Oder bei großen Sets:
offset = 0
batch_size = 1000
while True:
    orders = env['sale.order'].search([], offset=offset, limit=batch_size)
    if not orders:
        break
    process(orders)
    env.cr.commit()                      # bei Cron-Jobs!
    offset += batch_size
```

> Performance-Patterns siehe `odoo-performance.md`.

### Mehrwertige Updates (Recordset-Write)

```python
# GUT — ein Write für viele
self.env['sale.order'].search(domain).write({'state': 'cancel'})

# SCHLECHT — N Writes
for order in orders:
    order.write({'state': 'cancel'})
```

Ausnahme: wenn jeder Record einen anderen Wert bekommt.

---

## 4. XML-Style

### XML-IDs

Format: `<modul>.<modell>_<aktion>_<unterscheidung>`:

- `eledia_project.action_eledia_project` — `ir.actions.act_window`
- `eledia_project.view_eledia_project_form` — Form-View
- `eledia_project.view_eledia_project_tree` — List-View
- `eledia_project.view_eledia_project_kanban` — Kanban
- `eledia_project.view_eledia_project_search` — Search
- `eledia_project.menu_eledia_project_root` — Root-Menü
- `eledia_project.menu_eledia_project_kpi` — Untermenü
- `eledia_project.group_eledia_manager` — Group
- `eledia_project.rule_eledia_project_user` — Record Rule
- `eledia_project.access_eledia_project_user` — Access (in CSV)

OCA-Strenger:

- Keine `_id`/`_ids`-Suffixe in XML-IDs (es sei denn der Record IST eine ID).
- Kategorie immer am Anfang (`view_`, `action_`, `menu_`, `seq_`, `cron_`).
- Bei Inherited Views: `<original_xmlid>_<your_module>` als XML-ID:
  `view_partner_form_eledia` für eine erbende View, **nicht** `view_partner_form`.

### Indent in XML

- 4 Spaces, **nicht** Tabs.
- Attribute in einer Zeile **wenn** kurz; sonst untereinander, ein Attribut pro
  Zeile, geschlossenes Tag auf eigener Zeile:

```xml
<!-- KURZ → einzeilig -->
<field name="name"/>

<!-- LANG → multi-line -->
<field
    name="partner_id"
    domain="[('customer_rank', '>', 0)]"
    options="{'no_create_edit': True, 'always_reload': True}"
    context="{'default_company_id': company_id}"
/>
```

### Field-Tag-Patterns

```xml
<!-- Einfache Felder -->
<field name="name"/>
<field name="amount" widget="monetary"/>

<!-- Many2one mit Domain (kein String!) -->
<field name="partner_id" domain="[('customer_rank', '&gt;', 0)]"/>

<!-- Readonly mit Bedingung -->
<field name="state" readonly="state == 'done'"/>

<!-- Invisible -->
<field name="amount_residual" invisible="state != 'posted'"/>

<!-- Required -->
<field name="vat" required="country_id.code == 'DE'"/>
```

> **Odoo 17+ Breaking-Change:** `attrs="{'invisible': […]}"` ist deprecated.
> Stattdessen direkt `invisible="<python-expr>"`. Gilt für `readonly`, `required`,
> `column_invisible` ebenso.

### Records anlegen (`<record>`)

```xml
<record id="ir_cron_eledia_daily" model="ir.cron">
    <field name="name">eLeDia: Daily Project KPI Recompute</field>
    <field name="model_id" ref="model_eledia_project"/>
    <field name="state">code</field>
    <field name="code">model.cron_recompute_kpi()</field>
    <field name="interval_number">1</field>
    <field name="interval_type">days</field>
    <field name="numbercall">-1</field>
    <field name="active" eval="True"/>
</record>
```

`eval="…"` für nicht-String-Werte (Booleans, Listen, Dicts), `ref="…"` für andere
XML-IDs.

### Niemals `noupdate="0"` setzen, wenn `noupdate="1"` reicht

```xml
<!-- Daten, die der User editieren darf, dürfen beim -u nicht überschrieben werden -->
<data noupdate="1">
    <record id="email_template_eledia_welcome" model="mail.template">
        ...
    </record>
</data>
```

Mail-Templates, ir.cron-Active-Flags, Sequenzen, IAP-Configs: **immer**
`noupdate="1"`.

---

## 5. Translations

### Wrapping

```python
# Python: _ aus odoo importieren, NIE aus gettext
from odoo import _, api, fields, models

raise UserError(_("Order %s cannot be cancelled in state %s.", order.name, order.state))
self.env['mail.message'].create({'body': _("Status updated.")})
```

- **Statische Strings** `_("Hello")` — wird von `i18n_extract` gefunden.
- **Dynamische Strings** mit Platzhaltern: `_("Hello %s", name)`. Niemals
  `_("Hello %s") % name` — bricht das Auffinden in einigen Fällen.
- **Ab Odoo 16** ist `_("Hello %s", name)` mit positionalen Args Standard.
  Ab Odoo 17 mit Keyword-Args:
  ```python
  _("Order %(name)s in state %(state)s.", name=order.name, state=order.state)
  ```

### XML

```xml
<!-- Strings in Attributen werden automatisch extrahiert -->
<button name="action_confirm" string="Bestätigen" class="btn-primary"/>

<!-- Texte in <separator>, <p>, <span> ebenso -->
<separator string="Adresse"/>
<p>Bitte alle Pflichtfelder ausfüllen.</p>
```

### Was NICHT übersetzbar ist

- Selection-Werte (intern): `('draft', 'Entwurf')` — der `draft`-Key bleibt.
- Modell-Namen, Feld-Namen.
- E-Mail-Adressen, URLs, technische Codes.
- Datumsformate, Zahlenformate (kommt vom Locale).

---

## 6. Sicherheits-Idiome (Kurz)

> Vollständig in `odoo-security.md`.

**Pflicht:**

- Jedes Modell mit Daten hat einen Eintrag in `ir.model.access.csv`.
- Multi-Company-Modelle haben eine `ir.rule` für `company_id`.
- `sudo()`-Aufrufe sind dokumentiert (Kommentar warum).

```python
# GUT — explizit
# Verwende sudo: User darf eigene Statistik sehen, aber nicht alle Records.
self.sudo().search([('user_id', '=', self.env.uid)])

# SCHLECHT — implizit, nicht reviewbar
self.sudo().search([])
```

---

## 7. Linting & Formatter

### Pflicht-Toolchain (OCA-Standard, eLeDia-Default)

```yaml
# .pre-commit-config.yaml — Auszug
repos:
  - repo: https://github.com/psf/black
    rev: 24.10.0
    hooks:
      - id: black
        args: [--line-length=88]
        language_version: python3.10

  - repo: https://github.com/pycqa/isort
    rev: 5.13.2
    hooks:
      - id: isort
        args: [--profile=black]

  - repo: https://github.com/pycqa/flake8
    rev: 7.0.0
    hooks:
      - id: flake8

  - repo: https://github.com/OCA/pylint-odoo
    rev: v9.1.5
    hooks:
      - id: pylint_odoo
        args:
          - --rcfile=.pylintrc
          - --disable=all
          - --enable=odoolint
```

Aktivieren:

```bash
pip install pre-commit
pre-commit install
pre-commit run --all-files
```

### `pylint-odoo` — wichtige Checks

| Check | Was er prüft |
|---|---|
| `manifest-required-key` | `name`, `version`, `license`, `category` müssen da sein |
| `manifest-version-format` | Version muss `X.Y.A.B.C` sein |
| `missing-readme` | README-Datei vorhanden |
| `translation-required` | `_()` um sichtbare Strings |
| `print-used` | `print()` in Modul-Code → Fehler |
| `sql-injection` | f-String in `cr.execute` |
| `external-request-timeout` | `requests.get` ohne `timeout=` |
| `attribute-deprecated` | `attrs=` in Views (17+) |
| `no-write-in-compute` | `compute` schreibt fremde Felder |
| `consider-merging-classes-inherited` | mehrere `_inherit`-Klassen für dasselbe Modell |
| `xml-deprecated-tree-attribute` | `<tree>` statt `<list>` (Odoo 18!) |

> **Odoo 18 Breaking:** `<tree>` heißt jetzt `<list>`. Beides funktioniert noch,
> aber `<list>` ist die neue Form. Pylint-odoo warnt.

### `isort`-Profile für Odoo

```ini
# .isort.cfg
[settings]
profile = black
known_first_party = odoo,odoo.addons
known_third_party = requests,stripe
sections = FUTURE,STDLIB,THIRDPARTY,FIRSTPARTY,LOCALFOLDER
```

---

## 8. JavaScript / OWL — Kurzfassung

> Vollständig in `odoo-views-frontend.md`.

- **OWL 2** ist Standard. Kein jQuery in neuem Code (Odoo 17+ entfernt jQuery
  schrittweise).
- ES Modules + Static Class Components.
- Imports via Odoo-Module-System: `import { Component } from "@odoo/owl";`
- Style-Files: SCSS, BEM-Naming für eigene Klassen, **immer** mit Modul-Präfix:
  `.o_eledia_project_kpi`.
- Keine `console.log` im Production-Code.

```javascript
/** @odoo-module **/

import { Component, useState } from "@odoo/owl";
import { registry } from "@web/core/registry";
import { _t } from "@web/core/l10n/translation";

export class EledialKpiWidget extends Component {
    static template = "eledia_project.KpiWidget";
    static props = { record: Object };

    setup() {
        this.state = useState({ loaded: false });
    }

    get label() {
        return _t("KPIs für %s", this.props.record.name);
    }
}

registry.category("view_widgets").add("eledia_kpi", { component: EledialKpiWidget });
```

---

## 9. Commit-Messages (OCA-Konvention, eLeDia-Default)

Format:

```
[TAG] modul: Kurzbeschreibung

Optional: längerer Body mit "warum", nicht "was".
Refs: T1234
```

Tags:

- `[ADD]` — neues Modul oder Feature
- `[IMP]` — Improvement (Refactor, kleinere Verbesserung)
- `[FIX]` — Bugfix
- `[REF]` — Refactor ohne Funktionsänderung
- `[REM]` — Entfernung
- `[REV]` — Revert
- `[MIG]` — Migration (z.B. 17.0 → 18.0)
- `[I18N]` — nur Translations
- `[BREAK]` — Breaking Change (Major-Version-Bump)

Beispiele:

```
[ADD] eledia_project_tracker: KPI-Dashboard pro Projekt

[FIX] eledia_project_tracker: Division-by-zero bei leerem Sprint

Wenn ein Sprint keine Stories hat, scheiterte _compute_velocity am 0/0.
Jetzt liefert es 0.0.
Refs: BUG-227
```

---

## 10. Code-Review-Checkliste

**Vor jedem PR:**

- [ ] `pre-commit run --all-files` grün
- [ ] Manifest-Version inkrementiert
- [ ] `i18n/<modul>.pot` regeneriert (`odoo-bin --i18n-export`)
- [ ] Tests grün (`odoo-bin -d test --test-tags=/<modul>`)
- [ ] Neue Modelle haben `ir.model.access.csv`-Eintrag
- [ ] Neue Felder haben `string=` (oder absichtlich nicht)
- [ ] Computed-Felder haben `@api.depends`
- [ ] Public-Methoden haben Docstring (mindestens 1 Zeile)
- [ ] Keine TODO/FIXME ohne Ticket-Reference
- [ ] Migration-Skript geschrieben, falls Datenmigration nötig
- [ ] README aktualisiert (Features, Configuration, Bug-Tracker)
- [ ] CHANGELOG-Eintrag (bei eigenen Repos)

---

## 11. Quick-Reference — Häufige Fehler & Fixes

| Fehler | Fix |
|---|---|
| `AttributeError: 'function' object has no attribute 'create'` | `@api.model_create_multi` fehlt |
| `Recursion detected` in compute | Compute schreibt eigenes Trigger-Feld |
| `ValueError: Invalid field 'foo' on model 'bar'` | Modul nicht in `depends` |
| Translation wird nicht gefunden | `_` aus `gettext` statt `odoo` importiert |
| `403 Forbidden` im Frontend | Controller-Route ohne `auth='public'` |
| Wert wird beim `-u` zurückgesetzt | Record nicht in `<data noupdate="1">` |
| `psycopg2.IntegrityError: null value in column "company_id"` | `default=lambda` schaut nach falscher Company |
| pylint-odoo `external-request-without-timeout` | `requests.get(url, timeout=10)` |
| QWeb `t-esc` rendert HTML doppelt-escaped | Es ist `t-out` für rohen HTML, `t-esc` für sicheren Text |

---

## 12. Quellen

- Coding Guidelines (DE): https://www.odoo.com/documentation/18.0/de/contributing/development/coding_guidelines.html
- Coding Guidelines (EN): https://www.odoo.com/documentation/18.0/contributing/development/coding_guidelines.html
- OCA Contributing: https://github.com/OCA/odoo-community.org/blob/master/website/Contribution/CONTRIBUTING.rst
- pylint-odoo: https://github.com/OCA/pylint-odoo
- OCA Maintainer-Tools: https://github.com/OCA/maintainer-tools
- Black-Config OCA: https://github.com/OCA/maintainer-tools/blob/master/template/module/.pre-commit-config.yaml
