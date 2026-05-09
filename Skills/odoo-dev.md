---
name: odoo-dev
description: >
  Dachskill für Odoo-18-Enterprise-Entwicklung. Verwende diesen Skill für JEDE
  Odoo-bezogene Aufgabe — Modul-Entwicklung, ORM, Models, Fields, Inheritance,
  Manifest, Verzeichnisstruktur, Bootstrapping eines neuen Add-ons. Trigger bei
  "Odoo", "Odoo 18", "Odoo-Modul", "__manifest__.py", "models.Model", "_inherit",
  "_inherits", "Recordset", "api.depends", "api.model", "api.constrains",
  "api.onchange", "fields.Many2one", "fields.One2many", "fields.Many2many",
  "ir.model", "OCA", "odoo.sh", "addons-path", oder bei Erwähnung von Odoo-Dateien
  wie __init__.py in einem Odoo-Modul, models/*.py, controllers/*.py.
  Bei Spezialthemen zusätzlich passenden Sub-Skill laden:
  odoo-coding-guidelines (Style), odoo-views-frontend (UI/OWL),
  odoo-security (Access/Rules), odoo-testing (Tests), odoo-performance (Tuning),
  odoo-deploy (odoo.sh/Docker), odoo-enterprise-specifics (Studio/Subscriptions/IoT).
---

# Odoo 18 Development Framework — Dachskill

Dieses Framework ist die **erste Anlaufstelle** für jede Odoo-18-Entwicklung. Es
deckt Modul-Anatomie, ORM-Grundlagen, Inheritance-Mechanismen und das saubere
Aufsetzen eines Add-ons ab. Tiefer gehende Themen sind in spezialisierte
Sub-Skills ausgelagert (siehe „Sub-Skills" unten).

**Ziel-Version:** Odoo 18.0 Enterprise (released Oktober 2024).
**Python-Minimum:** 3.10 (3.11 empfohlen).
**PostgreSQL-Minimum:** 12 (14+ empfohlen).
**Browser-Targets (Frontend):** moderne Evergreen-Browser, OWL 2.

> **OCA-Hinweis:** Für jedes Pattern markiert dieser Skill, wo OCA
> (`OCA-Guidelines`) strenger oder anders ist als die offizielle Odoo-Doku.
> Beispiel: OCA verbietet `# noqa`-Pauschalen und verlangt `pylint-odoo`-Pflicht;
> Odoo selbst empfiehlt es nur.

---

## Sub-Skills (Wann was laden)

| Aufgabe | Skill |
|---|---|
| Style, Naming, XML-IDs, Idiome, OCA-Abweichungen | `odoo-coding-guidelines.md` |
| Views (Form/List/Kanban/Search), QWeb, OWL 2, Widgets, Reports | `odoo-views-frontend.md` |
| `ir.model.access.csv`, Record Rules, Multi-Company, `sudo()` | `odoo-security.md` |
| `tagged`, `TransactionCase`, `HttpCase`, Tours, Mocking, CI | `odoo-testing.md` |
| Computed/Stored, Indizes, `read_group`, Caching, Cron-Jobs | `odoo-performance.md` |
| odoo.sh, Docker, Migrations-Skripte, Multi-DB | `odoo-deploy.md` |
| Studio, Approvals, Documents, IoT, Subscriptions, Field Service | `odoo-enterprise-specifics.md` |

**Regel:** Bei jeder neuen Aufgabe zuerst diesen Dachskill konsultieren, dann
**genau die** Sub-Skills laden, die zum Scope gehören. Nicht alle gleichzeitig.

---

## Kern-Prinzipien (Odoo Way)

1. **ORM zuerst, SQL zuletzt.** Roh-SQL nur, wenn die ORM-Methode nachweislich
   nicht reicht. Geht durch keinen Code-Review, ohne dass der Trade-off
   begründet ist.
2. **Inheritance statt Forks.** Bestehende Modelle mit `_inherit` erweitern,
   nicht kopieren. Bestehende Views mit `xpath` patchen, nicht neu schreiben.
3. **Datentrennung sauber halten.** Logik in `models/`, Views in `views/`,
   Security in `security/`, statische Daten in `data/` und Demo in `demo/`.
4. **Manifest ist Wahrheit.** Nichts wird geladen, was nicht im `__manifest__.py`
   unter `data` oder `demo` steht.
5. **Translations ab Tag 1.** Jeder dem User sichtbare String wird `_("…")`-gewrappt.
6. **Multi-Company by default.** Jedes neue Geschäftsmodell bekommt ein
   `company_id`-Feld (oder bewusst nicht — dann begründen).
7. **Privacy/GDPR.** Personenbezogene Daten werden via Archiv (`active`-Feld) und
   `unlink`-Konsistenz, nicht durch Hard-Delete-Hacks gemanagt.

---

## 1. Modul-Anatomie

### Vollständige Verzeichnisstruktur

Ein produktionsreifes Odoo-18-Modul:

```
my_module/
├── __init__.py                 # imports controllers, models, wizards, …
├── __manifest__.py             # Modul-Metadaten (s.u.)
├── README.rst                  # OCA-Pflicht; bei eigenem Repo dringend empfohlen
├── README.md                   # alternativ; Odoo-Standard ist .rst
├── i18n/                       # Übersetzungen (.pot, .po)
│   ├── my_module.pot
│   └── de.po
├── controllers/
│   ├── __init__.py
│   └── main.py                 # http.Controller, Routen (/portal/…, /api/…)
├── data/                       # Master-Daten (geladen einmalig + on update)
│   ├── ir_sequence_data.xml
│   ├── mail_template_data.xml
│   └── ir_cron_data.xml
├── demo/                       # nur bei demo=True
│   └── demo_data.xml
├── models/
│   ├── __init__.py
│   ├── res_partner.py          # Erweiterung von res.partner via _inherit
│   ├── my_main.py
│   └── my_line.py
├── wizards/                    # TransientModel (Pop-Up-Dialoge)
│   ├── __init__.py
│   └── my_wizard.py
├── reports/                    # QWeb-Reports
│   ├── my_report.py            # AbstractModel mit _name = 'report.…'
│   ├── my_report_template.xml  # QWeb-Template
│   └── my_report.xml           # ir.actions.report
├── security/
│   ├── ir.model.access.csv
│   ├── my_module_security.xml  # ir.rule, res.groups
│   └── my_module_groups.xml    # nur Groups, falls separat gewünscht
├── views/
│   ├── my_main_views.xml
│   ├── my_line_views.xml
│   ├── res_partner_views.xml   # Inheritance-Views
│   └── menus.xml               # Menüs (oft am Ende!)
├── static/
│   ├── description/
│   │   ├── icon.png            # 140x140, OCA: 128x128
│   │   └── index.html          # Optional: Modul-Landingpage im Apps-Store
│   └── src/
│       ├── components/         # OWL-Komponenten (.js, .xml, .scss)
│       ├── js/                 # Patches & Service-Erweiterungen
│       ├── scss/
│       └── xml/                # OWL-Templates
├── tests/
│   ├── __init__.py
│   ├── common.py               # gemeinsame Fixtures
│   ├── test_my_main.py
│   └── test_my_main_tours.py   # Frontend-Tours
└── pyproject.toml              # bei OCA üblich, sonst optional
```

**Reihenfolge in `__init__.py`** (Modulwurzel):

```python
from . import controllers
from . import models
from . import wizards
from . import reports
```

`controllers` zuerst, weil Routen früh registriert sein müssen. `wizards` nach
`models`, weil sie diese typischerweise referenzieren.

### `__manifest__.py` — Vollständiges Beispiel mit allen Feldern

```python
# -*- coding: utf-8 -*-
{
    'name': 'eLeDia Project Tracker',
    'version': '18.0.1.0.0',                # X.Y.A.B.C — Odoo-Major.Minor + Modul-Version
    'category': 'Project',                  # Kategorie aus Odoo-Apps
    'summary': 'Erweiterte Projektverfolgung mit KPI-Dashboard',
    'description': """
Long description in RST (wird im Apps-Store gerendert).

Features
========
* KPI-Dashboard pro Projekt
* Burn-Down-Chart auf Sprint-Ebene
* Slack-Integration via webhook
""",
    'author': 'eLeDia GmbH',
    'website': 'https://eledia.de',
    'license': 'OPL-1',                     # Enterprise-Modul; sonst LGPL-3 oder AGPL-3
    'maintainer': 'eLeDia GmbH',

    # Abhängigkeiten — IMMER explizit, auch wenn 'base' implizit wäre
    'depends': [
        'base',
        'mail',
        'project',
        'hr_timesheet',                     # Enterprise-only-Beispiel
    ],
    'external_dependencies': {
        'python': ['stripe', 'qrcode'],     # via requirements.txt installieren
        'bin': ['wkhtmltopdf'],
    },

    # Daten (Reihenfolge wichtig — Security VOR Views)
    'data': [
        'security/my_module_groups.xml',
        'security/my_module_security.xml',
        'security/ir.model.access.csv',
        'data/ir_sequence_data.xml',
        'data/mail_template_data.xml',
        'data/ir_cron_data.xml',
        'wizards/my_wizard_views.xml',
        'views/my_main_views.xml',
        'views/my_line_views.xml',
        'views/res_partner_views.xml',
        'reports/my_report.xml',
        'reports/my_report_template.xml',
        'views/menus.xml',                  # MENÜS ZULETZT
    ],
    'demo': [
        'demo/demo_data.xml',
    ],

    # Frontend-Assets (Odoo 18 Asset-Bundles)
    'assets': {
        'web.assets_backend': [
            'my_module/static/src/components/**/*',
            'my_module/static/src/js/**/*',
            'my_module/static/src/scss/**/*.scss',
            'my_module/static/src/xml/**/*.xml',
        ],
        'web.assets_frontend': [
            'my_module/static/src/portal/**/*',
        ],
        'web.qunit_suite_tests': [
            'my_module/static/tests/**/*',
        ],
    },

    # Lifecycle-Hooks
    'pre_init_hook': 'pre_init_hook',
    'post_init_hook': 'post_init_hook',
    'uninstall_hook': 'uninstall_hook',

    # Marketplace / Apps-Store
    'installable': True,
    'application': True,                    # Eigene App-Kachel im Apps-Menü
    'auto_install': False,                  # True = automatisch bei Bedingungserfüllung
    'images': ['static/description/banner.png'],
    'price': 199.00,                        # Apps-Store
    'currency': 'EUR',
    'support': 'support@eledia.de',
    'live_test_url': 'https://demo.eledia.de',
}
```

**Wichtige Regeln für `depends`:**

- Jedes Modell, das du in `_inherit` referenzierst, **muss** in `depends` stehen.
- Jeder XML-ID-Reference (`ref="account.action_…"`), **muss** das definierende Modul
  in `depends` haben.
- Niemals `depends: ['base']` allein lassen, wenn du `mail.thread`, `mail.activity.mixin`
  o. ä. nutzt.
- OCA-Repos: zusätzlich `'maintainers': ['<github-handle>']`.

### Versionsschema

Format: `<odoo-version>.<modul-major>.<modul-minor>.<modul-patch>`

- `18.0.1.0.0` — initiale Release auf Odoo 18
- `18.0.1.1.0` — neues Feature
- `18.0.1.0.1` — Bugfix
- `18.0.2.0.0` — Breaking Change

OCA verlangt das Schema strikt. Eigene Repos sollten es ebenfalls nutzen, weil
`odoo-bin --update` die Modulversion vergleicht und Migrations-Skripte
`migrations/<version>/post-migration.py` automatisch lädt.

---

## 2. Models — Das Herz von Odoo

### Modell-Typen

| Klasse | Tabelle? | Persistent? | Einsatz |
|---|---|---|---|
| `models.Model` | ja | ja | Normales Geschäftsmodell |
| `models.TransientModel` | ja, mit auto-cleanup | nein (autovacuum nach Stunden) | Wizards, Pop-Ups |
| `models.AbstractModel` | nein | nein | Mixins, gemeinsame Logik, Reports |

### Minimal-Modell

```python
# models/eledia_project.py
from odoo import api, fields, models, _
from odoo.exceptions import ValidationError, UserError


class EledialProject(models.Model):
    _name = 'eledia.project'
    _description = 'eLeDia Project'         # IMMER setzen — sonst Warning
    _inherit = ['mail.thread', 'mail.activity.mixin']  # Chatter & Aktivitäten
    _order = 'sequence, name'
    _rec_name = 'name'                       # Default ist 'name'; explizit ist klarer

    # ---- Felder ----
    name = fields.Char(
        string='Projektname',
        required=True,
        tracking=True,                       # mit mail.thread → Chatter-Eintrag
        translate=False,                     # bei mehrsprachigen Strings: True
    )
    sequence = fields.Integer(default=10)
    active = fields.Boolean(default=True)    # Pflicht für Archiv-Pattern
    company_id = fields.Many2one(
        'res.company',
        string='Company',
        default=lambda self: self.env.company,
        required=True,
    )
    user_id = fields.Many2one(
        'res.users',
        string='Verantwortlich',
        default=lambda self: self.env.user,
        tracking=True,
    )
    state = fields.Selection(
        selection=[
            ('draft', 'Entwurf'),
            ('active', 'Aktiv'),
            ('done', 'Abgeschlossen'),
            ('cancel', 'Abgebrochen'),
        ],
        default='draft',
        tracking=True,
        copy=False,                          # bei .copy() nicht übernehmen
    )
    line_ids = fields.One2many('eledia.project.line', 'project_id', string='Lines')
    line_count = fields.Integer(
        compute='_compute_line_count', store=True
    )
    total_amount = fields.Monetary(
        string='Gesamtbetrag',
        compute='_compute_total_amount', store=True,
        currency_field='currency_id',
    )
    currency_id = fields.Many2one(
        'res.currency',
        default=lambda self: self.env.company.currency_id,
    )

    # ---- SQL-Constraints ----
    _sql_constraints = [
        ('name_company_uniq',
         'unique(name, company_id)',
         'Der Projektname muss pro Firma eindeutig sein.'),
    ]

    # ---- Computed-Felder ----
    @api.depends('line_ids')
    def _compute_line_count(self):
        for record in self:
            record.line_count = len(record.line_ids)

    @api.depends('line_ids.amount')
    def _compute_total_amount(self):
        for record in self:
            record.total_amount = sum(record.line_ids.mapped('amount'))

    # ---- Constraints ----
    @api.constrains('state', 'line_ids')
    def _check_lines_for_active(self):
        for record in self:
            if record.state == 'active' and not record.line_ids:
                raise ValidationError(
                    _("Aktive Projekte brauchen mindestens eine Zeile.")
                )

    # ---- Onchange (NUR für UI-Hints, NICHT für Geschäftsregeln) ----
    @api.onchange('user_id')
    def _onchange_user_id(self):
        if self.user_id and not self.user_id.email:
            return {
                'warning': {
                    'title': _("Hinweis"),
                    'message': _("Der gewählte User hat keine E-Mail-Adresse."),
                }
            }

    # ---- CRUD-Overrides ----
    @api.model_create_multi
    def create(self, vals_list):
        for vals in vals_list:
            if not vals.get('name'):
                vals['name'] = self.env['ir.sequence'].next_by_code('eledia.project') or '/'
        return super().create(vals_list)

    def write(self, vals):
        if 'state' in vals and vals['state'] == 'cancel':
            for record in self:
                if record.line_ids.filtered(lambda l: l.state == 'invoiced'):
                    raise UserError(_("Projekte mit verrechneten Zeilen können nicht storniert werden."))
        return super().write(vals)

    def unlink(self):
        for record in self:
            if record.state not in ('draft', 'cancel'):
                raise UserError(_("Nur Entwürfe oder stornierte Projekte können gelöscht werden."))
        return super().unlink()

    # ---- Action-Methoden (Buttons in Views) ----
    def action_activate(self):
        self.ensure_one()
        if not self.line_ids:
            raise UserError(_("Bitte zuerst Zeilen anlegen."))
        self.state = 'active'

    def action_done(self):
        self.write({'state': 'done'})        # write() für Multi-Record sicher
        return True
```

### Wichtige API-Decorators (Odoo 18)

| Decorator | Wann | Selbst-Typ |
|---|---|---|
| `@api.model` | Methoden ohne Recordset-Bezug, klassen-statisch | leeres `self` (ein Recordset) |
| `@api.model_create_multi` | `create()` — **ab 16 Default; ab 18 Pflicht für Performance** | leeres `self` |
| `@api.depends('field1', 'rel.field2')` | Computed Field | Recordset (kann mehrere) |
| `@api.depends_context('uid', 'company')` | Computed-Recompute bei Context-Änderung | Recordset |
| `@api.constrains('field', …)` | Server-seitige Validierung beim `write`/`create` | Recordset |
| `@api.onchange('field', …)` | Nur UI-Hints (Warnings, Domain-Updates) | NewRecord (im Form) |
| `@api.returns('self')` | Methode gibt Recordset zurück | Recordset |
| `@api.autovacuum` | Cron-getriebene Cleanup-Jobs (TransientModel-Erbe) | leeres `self` |

> ⚠️ **`@api.one` und `@api.multi` gibt es seit Odoo 13 nicht mehr.** Wer das in
> Code findet: das Modul wurde nicht migriert.

### Felder-Cheatsheet (Odoo 18)

| Typ | Wichtige Optionen |
|---|---|
| `Char(size=64, translate=False, trim=True)` | `size` ist eine Empfehlung, kein Hard-Limit |
| `Text(translate=False)` | unbegrenzt, kein HTML |
| `Html(sanitize=True, sanitize_tags=True, sanitize_attributes=True)` | Default-sicher; nur abschalten, wenn nötig |
| `Integer`, `Float(digits=(10,2))`, `Monetary(currency_field='…')` | `Monetary` ist der einzig korrekte Typ für Geld |
| `Boolean(default=False)` | |
| `Date`, `Datetime` | UTC-only intern; UI rechnet auf User-TZ um |
| `Selection(selection=[…], selection_add=[…], ondelete={…})` | `ondelete` Pflicht beim Erweitern |
| `Many2one('model', ondelete='restrict', domain="[('field','=',True)]")` | `ondelete`: `restrict`, `cascade`, `set null` |
| `One2many('model', 'inverse_field')` | inverse Field MUSS Many2one zurück sein |
| `Many2many('model', 'rel_table', 'col1', 'col2', domain=…)` | bei mehreren M2M zum selben Ziel: `relation` explizit |
| `Reference(selection=[('model','Label')])` | dynamische Verknüpfung, langsamer |
| `Json` | für strukturierte Daten ohne neue Tabelle |
| `Properties(definition_record='…', definition_record_field='…')` | **neu in 17/18:** flexible Custom-Fields |
| `Binary(attachment=True)` | `attachment=True` = im Filestore, nicht in DB |
| `Image(max_width=1024, max_height=1024)` | Spezialisierung von Binary |

**Häufige Fallen:**

- `compute=` ohne `store=True` → kein DB-Lookup möglich, langsam in Listen.
- `compute=` ohne `@api.depends` → wird **bei jedem Read** neu berechnet. Pflicht.
- `Many2one` ohne `ondelete` → Default ist `set null`, oft nicht gewollt.
- `Selection` erweitern via `selection_add`, nie via Override des `selection`-Args.
- `Html` mit `sanitize=False` ist eine XSS-Lücke. Reviewer-Killer.

---

## 3. Inheritance — Die drei Mechanismen

Odoo kennt drei Inheritance-Modelle. Alle drei werden in produktiven Modulen
gebraucht.

### a) Klassische Erweiterung — `_inherit` (Extension)

Erweitert ein bestehendes Modell **in-place**: dieselbe Tabelle, dieselbe
Klasse-Hierarchie. **99 % der Use-Cases.**

```python
class ResPartner(models.Model):
    _inherit = 'res.partner'

    eledia_loyalty_points = fields.Integer(default=0)
    eledia_tier = fields.Selection(
        selection=[('bronze', 'Bronze'), ('silver', 'Silver'), ('gold', 'Gold')],
        compute='_compute_tier', store=True,
    )

    @api.depends('eledia_loyalty_points')
    def _compute_tier(self):
        for partner in self:
            if partner.eledia_loyalty_points >= 1000:
                partner.eledia_tier = 'gold'
            elif partner.eledia_loyalty_points >= 200:
                partner.eledia_tier = 'silver'
            else:
                partner.eledia_tier = 'bronze'
```

### b) Prototype-Inheritance — `_inherit` mit neuem `_name` (Copy)

Erstellt ein **neues** Modell mit den Feldern und Methoden des Eltern-Modells.
Selten — meistens für Wizards, die wie ein anderes Modell aussehen sollen.

```python
class EledialPartnerSnapshot(models.Model):
    _name = 'eledia.partner.snapshot'
    _inherit = 'res.partner'                # NEUE Tabelle, kopierte Felder
    _description = 'Partner-Snapshot zum Stichtag'

    snapshot_date = fields.Date(required=True)
```

### c) Delegation — `_inherits` (Composition)

Legt einen **Many2one** zum Elternmodell an, dessen Felder transparent
durchgereicht werden. Klassiker: `res.users` → `res.partner`.

```python
class EledialEmployeeContract(models.Model):
    _name = 'eledia.employee.contract'
    _inherits = {'hr.employee': 'employee_id'}   # legt Many2one + Felder an
    _description = 'Arbeitsvertrag'

    employee_id = fields.Many2one('hr.employee', required=True, ondelete='cascade')
    start_date = fields.Date(required=True)
    end_date = fields.Date()
    monthly_rate = fields.Monetary(currency_field='currency_id')
    currency_id = fields.Many2one('res.currency', related='employee_id.company_id.currency_id')
```

Beim Zugriff auf `contract.name` greift Odoo automatisch auf `employee_id.name`.

### View-Inheritance

Views werden **nie** überschrieben, immer **erweitert**:

```xml
<record id="view_partner_form_eledia" model="ir.ui.view">
    <field name="name">res.partner.form.eledia</field>
    <field name="model">res.partner</field>
    <field name="inherit_id" ref="base.view_partner_form"/>
    <field name="arch" type="xml">
        <xpath expr="//notebook" position="inside">
            <page string="Loyalty" name="loyalty">
                <group>
                    <field name="eledia_loyalty_points"/>
                    <field name="eledia_tier"/>
                </group>
            </page>
        </xpath>
    </field>
</record>
```

**`position`-Werte:** `inside` (Default), `before`, `after`, `replace`, `attributes`.

> Details zu Views/XPath/Widgets in `odoo-views-frontend.md`.

---

## 4. ORM-Methoden — Das Recordset

Ein **Recordset** ist eine geordnete Sammlung von Records desselben Modells.
Auch ein leerer Recordset und ein Single-Record sind Recordsets.

### Basics

```python
# Suchen
partners = env['res.partner'].search([('customer_rank', '>', 0)])
partners = env['res.partner'].search([], limit=10, order='create_date desc')

# Single-Record per ID
partner = env['res.partner'].browse(7)

# Mit XML-ID
admin = env.ref('base.user_admin')

# Erstellen (Multi seit 16!)
new_partners = env['res.partner'].create([
    {'name': 'Alpha GmbH'},
    {'name': 'Beta GmbH'},
])

# Schreiben (auf Recordset, beliebig groß)
partners.write({'category_id': [(6, 0, [tag_id])]})

# Löschen
partners.unlink()
```

### Recordset-Operationen

```python
# Filtern (in-memory, kein SQL)
active_partners = partners.filtered(lambda p: p.active)
active_partners = partners.filtered('active')                # Shortcut bei Boolean

# Mappen
names = partners.mapped('name')                              # Liste von Strings
all_invoices = partners.mapped('invoice_ids')                # Recordset (uniq)
amounts = partners.mapped(lambda p: p.balance * 1.19)

# Sortieren
sorted_partners = partners.sorted('name')
sorted_partners = partners.sorted(key=lambda p: p.balance, reverse=True)

# Mengen-Operationen
combined = partners1 | partners2                             # Union
common = partners1 & partners2                               # Intersection
diff = partners1 - partners2                                 # Differenz

# Iteration
for partner in partners:                                     # IMMER pro-record
    ...

# Single-Assertion
partner.ensure_one()                                         # raises wenn ≠ 1
```

### Many2many / One2many — Spezial-Tupel-Syntax

```python
# Klassische Tupel (nach wie vor unterstützt)
partner.write({
    'category_id': [
        (0, 0, {'name': 'New Tag'}),     # create
        (1, tag_id, {'name': 'Updated'}), # update
        (2, tag_id, 0),                   # delete (full unlink)
        (3, tag_id, 0),                   # unlink (relation only)
        (4, tag_id, 0),                   # link
        (5, 0, 0),                        # clear
        (6, 0, [t1, t2, t3]),             # replace all
    ],
})

# Modern (Odoo 16+, lesbarer)
from odoo import Command
partner.write({
    'category_id': [
        Command.create({'name': 'New Tag'}),
        Command.update(tag_id, {'name': 'Updated'}),
        Command.delete(tag_id),
        Command.unlink(tag_id),
        Command.link(tag_id),
        Command.clear(),
        Command.set([t1, t2, t3]),
    ],
})
```

`Command.*` ist ab Odoo 16 die empfohlene Form. OCA verlangt sie für neuen Code.

### `read_group` — Aggregate ohne SQL

```python
result = env['account.move.line'].read_group(
    domain=[('move_id.state', '=', 'posted')],
    fields=['debit:sum', 'credit:sum', 'partner_id'],
    groupby=['partner_id'],
    orderby='debit desc',
    limit=20,
)
# → Liste von Dicts: [{'partner_id': (7, 'Alpha'), 'debit': 1234.0, ...}, ...]
```

> Details zu Aggregations-Performance in `odoo-performance.md`.

---

## 5. Environment, Context, Companies

Jeder Recordset trägt ein `env` (Environment). `env` hält:

- `cr` — DB-Cursor
- `uid` — User-ID
- `context` — frozendict (TZ, lang, force_company, …)
- `su` — Superuser-Flag (`sudo()`)
- `registry` — Modell-Registry

### Context-Manipulation

```python
# Mit anderem Context
partners = self.with_context(active_test=False).search([])      # auch archivierte
partner_de = self.with_context(lang='de_DE')                    # in Deutsch lesen
partner_eur = self.with_context(default_currency_id=eur.id)     # Default-Wert

# Mit anderem User
partner_as_admin = self.with_user(admin_user)
partner_su = self.sudo()                                        # = with_user(SUPERUSER_ID)

# Mit anderer Company
self_de = self.with_company(de_company)
```

> Details zu `sudo()` und Multi-Company-Sicherheit in `odoo-security.md`.

---

## 6. Hooks: pre_init, post_init, uninstall, migrations

```python
# my_module/__init__.py
from . import models, controllers


def pre_init_hook(env):                  # Odoo 17+ erhält env, vorher cr
    """Läuft VOR dem Anlegen der Tabellen. Selten gebraucht."""
    env.cr.execute("SELECT 1")


def post_init_hook(env):
    """Läuft NACH dem ersten Install und nach data/."""
    # z.B. bestehende Records mit einem neuen Default-Wert befüllen
    env['res.partner'].search([('eledia_loyalty_points', '=', 0)]).write(
        {'eledia_loyalty_points': 0}
    )


def uninstall_hook(env):
    """Läuft beim Deinstallieren. Cleanup, der ondelete='cascade' nicht abdeckt."""
    env['ir.config_parameter'].sudo().search([('key', 'like', 'my_module.%')]).unlink()
```

### Migrations-Skripte

Datei-Layout:

```
my_module/migrations/18.0.1.1.0/
├── pre-migration.py          # vor data/ load
├── post-migration.py         # nach data/ load
└── end-migration.py          # ganz am Ende
```

Beispiel:

```python
# migrations/18.0.1.1.0/post-migration.py
def migrate(cr, version):
    """Beim Update von <1.1.0 auf 1.1.0: alte 'tier' kleinschreiben."""
    cr.execute("UPDATE res_partner SET eledia_tier = LOWER(eledia_tier) WHERE eledia_tier IS NOT NULL")
```

`version` ist die **alte** Modul-Version. Wenn `None`, ist es ein Frischinstall —
dann nicht migrieren.

---

## 7. Externe Abhängigkeiten korrekt deklarieren

```python
# __manifest__.py
'external_dependencies': {
    'python': ['stripe', 'qrcode'],
    'bin': ['wkhtmltopdf'],
},
```

Im Code:

```python
import logging
_logger = logging.getLogger(__name__)

try:
    import stripe
except ImportError:
    stripe = None
    _logger.warning("python-stripe nicht installiert; eledia_payment_stripe inaktiv.")


def charge(self, amount):
    if stripe is None:
        raise UserError(_("Bitte installieren Sie 'stripe' (pip install stripe)."))
    ...
```

Für odoo.sh: `requirements.txt` im Repo-Root. Siehe `odoo-deploy.md`.

---

## 8. Bootstrapping eines neuen Moduls — Kompakt-Rezept

```bash
# 1. Skeleton via odoo-bin
odoo-bin scaffold eledia_project_tracker addons-eledia/

# 2. Manifest editieren (siehe Abschnitt 1)

# 3. Erstes Model anlegen
mkdir -p addons-eledia/eledia_project_tracker/{models,security,views}
touch addons-eledia/eledia_project_tracker/models/__init__.py

# 4. Modul installieren
odoo-bin -c odoo.conf -d eledia_dev --addons-path=addons-eledia,addons \
  -i eledia_project_tracker --stop-after-init

# 5. Im Dev-Modus ausführen
odoo-bin -c odoo.conf -d eledia_dev --dev=xml,reload --log-level=debug
```

`--dev=xml,reload` lädt geänderte Views/Python automatisch nach (kein Server-Restart
für View-Änderungen nötig — Python-Änderungen reichen oft `Ctrl+C; up`).

---

## 9. Anti-Patterns — Was im Review durchfällt

1. **`for x in self.search([])` statt `read_group`** — Performance-Killer.
2. **`self.env.cr.execute("UPDATE …")`** ohne Begründung — ORM umgangen,
   Cache nicht invalidiert.
3. **`compute` ohne `@api.depends`** — Recompute bei jedem Read.
4. **`@api.onchange` für Geschäftsregeln** — Onchange läuft nur in der UI,
   nicht beim API-Create. Nutze `@api.constrains` oder `_check_*` plus
   `default_*`.
5. **`unlink()`-Override, der `super()` vergisst.**
6. **Hartkodierte XML-IDs in Python** — `env.ref('base.user_admin')` ist OK,
   aber `env.ref('my_module.specific_record_xyz123')` deutet auf falsches
   Datenmodell.
7. **`Many2one` ohne `string`-Default und ohne `ondelete`** — beides muss bewusst
   sein.
8. **`Float` für Geld** — immer `Monetary` mit `currency_field`.
9. **Strings ohne `_("…")`** — bricht jede Lokalisierung.
10. **Demo-Daten in `data/` statt `demo/`** — landet auch in Production-DBs.

---

## 10. Quellen & weiterführend

- Offizielle Odoo-18-Doku — Developer:
  https://www.odoo.com/documentation/18.0/developer.html
- ORM API:
  https://www.odoo.com/documentation/18.0/developer/reference/backend/orm.html
- Module Manifests:
  https://www.odoo.com/documentation/18.0/developer/reference/backend/module.html
- Coding Guidelines (DE):
  https://www.odoo.com/documentation/18.0/de/contributing/development/coding_guidelines.html
- OCA Contribution-Guidelines:
  https://github.com/OCA/odoo-community.org/blob/master/website/Contribution/CONTRIBUTING.rst
- OCA Maintainer-Tools:
  https://github.com/OCA/maintainer-tools

**Sub-Skills siehe Tabelle ganz oben.**
