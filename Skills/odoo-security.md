---
name: odoo-security
description: >
  Sicherheits-Modell von Odoo 18 — Access Control Lists (ir.model.access.csv),
  Record Rules (ir.rule), Groups (res.groups), Multi-Company-Strategien,
  sudo()-Pattern, check_access_rights/_rule, Security im Frontend (Controllers,
  CSRF), API-Tokens, Passwort-Policies. Verwende diesen Skill bei jeder Frage zu
  Berechtigungen, Datentrennung, Tenant-Isolation, GDPR/Datenschutz, externen
  APIs mit Auth, Token-Handling. Trigger bei "Security", "Access Rights",
  "ir.model.access", "Record Rule", "ir.rule", "Group", "res.groups", "sudo",
  "Multi-Company", "check_access", "CSRF", "auth='public'", "auth='user'",
  "API-Key", "Token", "GDPR", "DSGVO".
  Pair mit odoo-dev (Modelle), odoo-views-frontend (Visibility via groups=),
  odoo-deploy (TLS, Reverse-Proxy, Secrets).
---

# Odoo 18 — Security & Access Control

Vollständiges Sicherheits-Modell. **Wichtigste Regel:** Odoo prüft Berechtigungen
auf zwei Ebenen — **Modell-Ebene** (ACL via `ir.model.access`) und
**Record-Ebene** (Domain-Filter via `ir.rule`). Beide werden bei **jeder**
ORM-Operation evaluiert (außer `sudo()`).

**Quelle:** https://www.odoo.com/documentation/18.0/developer/reference/backend/security.html

---

## 1. Die vier Säulen

```
                    ┌──────────────────────────┐
   User-Login   →  │  res.users               │
                    │  └─ groups_id (M2M)      │
                    └──────────┬───────────────┘
                               │
                    ┌──────────▼───────────────┐
        Säule 1:    │  res.groups              │  ← Wer ist User?
                    └──────────┬───────────────┘
                               │
        ┌──────────────────────┼──────────────────────────┐
        ▼                      ▼                          ▼
   ┌──────────────┐   ┌──────────────────┐   ┌──────────────────┐
   │ Säule 2:     │   │ Säule 3:         │   │ Säule 4:         │
   │ ir.model     │   │ ir.rule          │   │ Field-Level      │
   │ .access      │   │ (Record Rules)   │   │ groups="…"       │
   │ (ACL)        │   │                  │   │                  │
   │              │   │                  │   │                  │
   │ MODELL-      │   │ RECORD-          │   │ FELD-            │
   │ Ebene        │   │ Ebene            │   │ Ebene            │
   │              │   │                  │   │                  │
   │ "Darf Group  │   │ "Welche Records  │   │ "Sieht Group X   │
   │ X überhaupt  │   │ darf Group X     │   │ Feld foo?"       │
   │ Modell M     │   │ in Modell M      │   │                  │
   │ lesen?"      │   │ sehen?"          │   │                  │
   └──────────────┘   └──────────────────┘   └──────────────────┘
```

**Reihenfolge:** ACL → Record Rule → Field-Level. Versagt ACL, wird gar nichts
gelesen. ACL erlaubt → Record-Rule filtert → Field-Level blendet Felder aus.

---

## 2. Säule 1 — Groups (`res.groups`)

### Group definieren

```xml
<!-- security/eledia_groups.xml -->
<odoo>
    <data noupdate="1">
        <!-- Kategorie (Modul-Bucket im Settings → Users) -->
        <record id="module_category_eledia" model="ir.module.category">
            <field name="name">eLeDia</field>
            <field name="description">eLeDia-Module</field>
            <field name="sequence">80</field>
        </record>

        <!-- User-Group: darf eigene Daten sehen -->
        <record id="group_eledia_user" model="res.groups">
            <field name="name">User</field>
            <field name="category_id" ref="module_category_eledia"/>
            <field name="implied_ids" eval="[(4, ref('base.group_user'))]"/>
        </record>

        <!-- Manager-Group: darf alles inkl. Konfiguration -->
        <record id="group_eledia_manager" model="res.groups">
            <field name="name">Manager</field>
            <field name="category_id" ref="module_category_eledia"/>
            <field name="implied_ids" eval="[(4, ref('group_eledia_user'))]"/>
            <field name="users" eval="[(4, ref('base.user_admin'))]"/>
        </record>
    </data>
</odoo>
```

**`implied_ids`** = "wer Manager ist, ist automatisch auch User". Das ist die
saubere Form. **Niemals** Berechtigungen verdoppeln; immer impliziert vererben.

### Spezial-Groups (immer da)

| XML-ID | Bedeutung |
|---|---|
| `base.group_user` | Internal User (eingeloggter Mitarbeiter) |
| `base.group_portal` | Portal-User (Kunde) |
| `base.group_public` | Anonymer Besucher |
| `base.group_system` | Settings-Zugriff (Admin) |
| `base.group_no_one` | "Niemand" (nur Dev-Mode sichtbar) |
| `base.group_multi_company` | Multi-Company-Switch sichtbar |
| `base.group_multi_currency` | Multi-Currency-Switch sichtbar |
| `base.group_partner_manager` | Kontakt-Bearbeitung |

`base.group_user` impliziert `base.group_partner_manager` impliziert nichts.
Eigene Manager-Groups **immer** mit `implied_ids` nach `base.group_user` ketten.

---

## 3. Säule 2 — ACL (`ir.model.access.csv`)

### Datei-Format

```csv
id,name,model_id:id,group_id:id,perm_read,perm_write,perm_create,perm_unlink
access_eledia_project_user,eledia.project.user,model_eledia_project,group_eledia_user,1,1,1,0
access_eledia_project_manager,eledia.project.manager,model_eledia_project,group_eledia_manager,1,1,1,1
access_eledia_project_line_user,eledia.project.line.user,model_eledia_project_line,group_eledia_user,1,1,1,1
access_eledia_project_line_manager,eledia.project.line.manager,model_eledia_project_line,group_eledia_manager,1,1,1,1
```

**Spalten:**

- `id` — XML-ID (Convention: `access_<model>_<group>`)
- `name` — beliebiger Klartext (oft `<model>.<group>`)
- `model_id:id` — `model_<model_name_with_underscores>`
- `group_id:id` — XML-ID einer Group; **leer = alle internal Users**
- `perm_read|write|create|unlink` — `0` oder `1`

### Modell-Namen-Konvention

`eledia.project` → `model_eledia_project` (Punkte → Unterstriche).

### Pflicht-Regeln

1. **Jedes Modell muss min. einen ACL-Eintrag haben** — sonst Fehler beim Install.
2. **Manager-Group hat alle 4 Permissions** (auch `unlink`), User-Group oft nur
   `read,write,create` ohne `unlink`.
3. Kein `group_id:id`-Eintrag = "alle internal Users". **Vorsichtig nutzen**:
   das ist eine implizite Erlaubnis für `base.group_user`.
4. Portal-Zugriff: separater Eintrag mit `base.group_portal` als Group, meistens
   nur `perm_read=1`.

### TransientModel

TransientModels (Wizards) brauchen **keine** ACL-Einträge — Odoo gibt allen
internal Users automatisch Vollzugriff. Wenn man **explizite** Restriktion will,
trotzdem Eintrag machen.

---

## 4. Säule 3 — Record Rules (`ir.rule`)

Record Rules = Domain-Filter, die **automatisch** an jede `search`/`read`/`write`/
`unlink`-Operation gehängt werden.

### Anatomie einer Rule

```xml
<record id="rule_eledia_project_user" model="ir.rule">
    <field name="name">eledia.project: User sieht nur eigene</field>
    <field name="model_id" ref="model_eledia_project"/>
    <field name="domain_force">
        ['|',
            ('user_id', '=', user.id),
            ('user_id.id', 'in', user.subordinate_ids.ids)]
    </field>
    <field name="groups" eval="[(4, ref('group_eledia_user'))]"/>
    <field name="perm_read" eval="True"/>
    <field name="perm_write" eval="True"/>
    <field name="perm_create" eval="True"/>
    <field name="perm_unlink" eval="True"/>
</record>

<!-- Manager: keine Beschränkung -->
<record id="rule_eledia_project_manager" model="ir.rule">
    <field name="name">eledia.project: Manager sieht alles</field>
    <field name="model_id" ref="model_eledia_project"/>
    <field name="domain_force">[(1, '=', 1)]</field>
    <field name="groups" eval="[(4, ref('group_eledia_manager'))]"/>
</record>
```

**Verfügbare Variablen im `domain_force`:**

- `user` — `res.users`-Recordset des aktuellen Users
- `company_id` — aktuelle Company-ID (selten nötig — siehe Multi-Company)
- `time` (Python-Modul, eingeschränkt)

### Globale vs. Group-spezifische Rules

```xml
<!-- Globale Rule: für ALLE (auch sudo respektiert sie nicht!) -->
<record id="rule_eledia_archived" model="ir.rule">
    <field name="name">eledia.project: kein Schreiben auf archivierte</field>
    <field name="model_id" ref="model_eledia_project"/>
    <field name="domain_force">[('active', '=', True)]</field>
    <field name="global" eval="True"/>             <!-- KEIN groups-Eintrag -->
    <field name="perm_read" eval="False"/>          <!-- Lesen erlaubt -->
    <field name="perm_write" eval="True"/>          <!-- Schreiben blockiert -->
</record>
```

**Globale Rules** (`global=True` oder schlicht `groups=[]`) gelten für alle —
auch via `sudo()`! Daher restriktiv einsetzen.

### Rule-Logik

Bei mehreren Rules pro Modell:

- **Innerhalb einer Group:** Domains werden mit **OR** verknüpft (User in Group A
  und Group B sieht Records, die für A ODER B sichtbar sind).
- **Globale Rules:** mit **AND** verknüpft mit den Group-Rules.
- **`sudo()`** umgeht Group-Rules, **nicht** globale Rules.

### Standard-Pattern: Multi-Company-Filter

Jedes Multi-Company-Modell braucht eine globale Rule:

```xml
<record id="rule_eledia_project_company" model="ir.rule">
    <field name="name">eledia.project: Multi-Company</field>
    <field name="model_id" ref="model_eledia_project"/>
    <field name="domain_force">
        ['|', ('company_id', '=', False), ('company_id', 'in', company_ids)]
    </field>
    <field name="global" eval="True"/>
</record>
```

`company_ids` = aktiv ausgewählte Companies des Users (Multi-Company-Switch).
`company_id` = aktuell selektierte Hauptcompany.

---

## 5. Säule 4 — Field-Level Security

### Im Modell

```python
class EledialProject(models.Model):
    _name = 'eledia.project'

    salary = fields.Monetary(
        groups='hr.group_hr_user,hr.group_hr_manager',
    )
    internal_notes = fields.Text(
        groups='eledia_project.group_eledia_manager',
    )
```

User ohne mind. eine der genannten Groups kann das Feld **weder lesen noch
schreiben**. Es taucht in `read()` nicht auf, nicht in `search`-Domains, nicht in
Views.

### In Views

```xml
<field name="user_id" groups="eledia_project.group_eledia_manager"/>

<button name="action_force_done"
        string="Erzwingen"
        type="object"
        groups="base.group_system"/>

<page name="audit"
      string="Audit"
      groups="eledia_project.group_eledia_manager,base.group_system"/>
```

`groups="…"` versteht auch Negation: `groups="!base.group_portal"` für „nicht-
Portal".

---

## 6. `sudo()` — Wann erlaubt, wann nicht

`sudo()` führt die Operation als Superuser aus. Konsequenzen:

- Group-basierte ACLs werden **ignoriert**.
- Group-basierte Record Rules werden **ignoriert**.
- Globale Record Rules werden **respektiert**.
- Field-Level-Groups werden **ignoriert**.

### Legitime Use-Cases

```python
# 1. Hintergrund-Job (Cron) ohne User-Context
@api.model
def cron_recompute_kpis(self):
    self.search([])._compute_kpi()                  # ohne sudo läuft als der User, der den Cron-Owner ist

# 2. Public-Controller, der einen Wert lesen muss
@http.route('/api/v1/projects/<int:pid>', type='json', auth='public')
def public_project(self, pid):
    project = request.env['eledia.project'].sudo().browse(pid)
    if not project.exists() or not project.is_public:
        return {'error': 'not_found'}
    return project.read(['name', 'description'])[0]

# 3. Aktion eines Users, die aber temporär elevated Rechte braucht
def action_create_invoice(self):
    # User darf das Project sehen, aber nicht direkt Invoices anlegen.
    # Das macht nur unsere Server-Logik.
    invoice = self.env['account.move'].sudo().create({…})
    return invoice
```

### Verbotene `sudo()`

```python
# SCHLECHT — leakt Daten quer durch Tenants
return self.sudo().search([])

# SCHLECHT — umgeht alle Security ohne Audit
self.sudo().write({'active': False})

# SCHLECHT — gibt User Berechtigungen, die er nicht hat
def action_pay(self):
    self.payment_id.sudo().confirm()                # User darf zahlen, ohne Berechtigung!
```

### Best Practices

- Jeder `sudo()`-Aufruf **mit Kommentar** warum.
- `sudo()` so spät wie möglich, so eng wie möglich.
- Nach `sudo()`-Read: User-Context wieder herstellen mit `with_user(self.env.user)`.

---

## 7. Frontend-Security (Controllers)

### Auth-Modi

```python
from odoo import http
from odoo.http import request


class EledialController(http.Controller):

    # 1. Komplett offen — auch ohne Login
    @http.route('/public/health', type='http', auth='none')
    def health(self):
        return 'OK'

    # 2. Erlaubt jeden — anonyme Sessions bekommen Public-User
    @http.route('/portal/projects', type='http', auth='public', website=True)
    def portal_projects(self):
        # request.env läuft als 'public'-User
        if request.env.user._is_public():
            return request.redirect('/web/login')
        ...

    # 3. Eingeloggte User
    @http.route('/my/projects', type='http', auth='user', website=True)
    def my_projects(self):
        ...

    # 4. Nur via Token (für API)
    @http.route('/api/v1/projects', type='json', auth='api_key')
    def api_projects(self):
        ...
```

| Mode | Wer kommt durch | Session |
|---|---|---|
| `none` | Jeder; `request.env.user` ist None | nein |
| `public` | Jeder; `request.env.user` = Public-User | ja |
| `user` | Eingeloggte | ja |
| `bearer` | Mit OAuth2-Token (Odoo 18) | nein |
| `api_key` | Mit `X-Odoo-Api-Key`-Header | nein |

### CSRF-Schutz

Odoo schützt POST-Routen automatisch über CSRF-Token. Bei API-Endpunkten
explizit deaktivieren:

```python
@http.route('/api/v1/webhook', type='http', auth='public', methods=['POST'], csrf=False)
def webhook(self, **kwargs):
    # Eigene Auth via HMAC-Signatur
    self._verify_signature(request.httprequest)
    ...
```

`csrf=False` ist nur OK, wenn man **eigene** Auth/Verifikation macht (HMAC,
Bearer-Token, IP-Whitelist).

### Input-Validation

```python
# SCHLECHT — direktes Reichen an ORM
@http.route('/api/search', type='json', auth='user')
def search(self, domain):
    return request.env['res.partner'].search(domain).read()

# BESSER — Whitelist
@http.route('/api/search', type='json', auth='user')
def search(self, query):
    if not isinstance(query, str) or len(query) > 100:
        raise ValueError("Invalid query")
    return request.env['res.partner'].search([
        ('name', 'ilike', query)
    ], limit=20).read(['name', 'email'])
```

### XSS

`request.render()` rendert QWeb — `t-esc` escaped automatisch. **Niemals**
`t-out` mit User-Input ohne Sanitization (`html_sanitize`).

### Subverted ORM-Calls (z.B. SQL-Injection in `cr.execute`)

```python
# KATASTROPHE — SQL-Injection
self.env.cr.execute(f"SELECT * FROM res_partner WHERE name = '{name}'")

# RICHTIG — Parametrisiert
self.env.cr.execute(
    "SELECT * FROM res_partner WHERE name = %s",
    [name],
)

# RICHTIG — psycopg2.sql für Identifier
from psycopg2 import sql
self.env.cr.execute(
    sql.SQL("SELECT {} FROM res_partner").format(sql.Identifier(field_name))
)
```

`pylint-odoo`-Check: `sql-injection`.

---

## 8. API-Tokens

### `res.users.apikeys` (Odoo 14+)

User generiert in `Profil → API-Keys` einen Schlüssel. Auth via Header:

```
X-Odoo-Api-Key: <key>
```

```python
@http.route('/api/v1/me', type='json', auth='api_key')
def me(self):
    return {'login': request.env.user.login}
```

Programmatisch erzeugen:

```python
key_record = request.env['res.users.apikeys']._generate(
    'eledia_integration',                # scope
    'Backup-Sync-Service',               # name
    expiration_date=fields.Datetime.now() + relativedelta(years=1),
)
api_key = key_record.key                  # nur einmal lesbar!
```

**Niemals** API-Keys in Logs, in Repos, in Mails.

---

## 9. Multi-Company

### Strategien

| Strategie | Was |
|---|---|
| **Shared** | `company_id = False` möglich; Daten über alle Companies sichtbar |
| **Owned** | `company_id` Pflicht; Trennung über Record Rule |
| **Replicated** | Pro Company eigene Instanz (kein echtes Multi-Company) |

### Pflicht-Setup für „Owned" Modelle

```python
class EledialProject(models.Model):
    _name = 'eledia.project'

    company_id = fields.Many2one(
        'res.company',
        default=lambda self: self.env.company,
        required=True,
        index=True,                       # für Performance der Rules
    )
```

```xml
<!-- Globale Rule -->
<record id="rule_eledia_project_company" model="ir.rule">
    <field name="name">eledia.project: Multi-Company</field>
    <field name="model_id" ref="model_eledia_project"/>
    <field name="domain_force">
        ['|', ('company_id', '=', False), ('company_id', 'in', company_ids)]
    </field>
    <field name="global" eval="True"/>
</record>
```

### Inter-Company-Konsistenz

Für M2O-Felder über Companies hinweg:

```python
@api.constrains('company_id', 'partner_id')
def _check_company(self):
    for record in self:
        if (record.partner_id.company_id
                and record.partner_id.company_id != record.company_id):
            raise ValidationError(
                _("Der Partner gehört nicht zur Company des Projektes.")
            )
```

`_check_company_auto = True` (Modell-Attribut, Odoo 14+) generiert das automatisch
für alle M2O-Felder mit `check_company=True`.

```python
class EledialProject(models.Model):
    _name = 'eledia.project'
    _check_company_auto = True

    partner_id = fields.Many2one('res.partner', check_company=True)
```

---

## 10. Programmatische Permission-Checks

### `check_access_rights(operation)`

```python
self.env['eledia.project'].check_access_rights('write', raise_exception=True)
```

Prüft **nur** ACL, nicht Record Rules.

### `check_access_rule(operation)`

```python
project.check_access_rule('write')        # raises AccessError wenn nicht erlaubt
```

Prüft Record Rules **auf den konkreten Records**.

### Beides zusammen

```python
def write_safely(self, vals):
    self.check_access_rights('write')
    self.check_access_rule('write')
    return self.write(vals)
```

`check_access_rights` + `check_access_rule` werden in jeder `read/write/…`
Operation **automatisch** ausgeführt — explizit nur, wenn man früher abbrechen
will.

---

## 11. GDPR / DSGVO — Privacy-Patterns

### Zustimmung dokumentieren

```python
class ResPartner(models.Model):
    _inherit = 'res.partner'

    eledia_marketing_consent = fields.Boolean(string="Marketing-Einwilligung")
    eledia_marketing_consent_date = fields.Datetime(readonly=True)
    eledia_marketing_consent_source = fields.Char(readonly=True)
    eledia_marketing_consent_log_ids = fields.One2many(
        'eledia.partner.consent.log', 'partner_id'
    )

    def write(self, vals):
        if 'eledia_marketing_consent' in vals:
            self._log_consent_change(vals['eledia_marketing_consent'])
        return super().write(vals)
```

### Recht auf Vergessen

```python
def action_anonymize(self):
    """GDPR Art. 17 — Recht auf Löschung."""
    self.ensure_one()
    self.sudo().write({
        'name': _('Anonymized %s', self.id),
        'email': False,
        'phone': False,
        'mobile': False,
        'street': False,
        'street2': False,
        'zip': False,
        'city': False,
        'country_id': False,
        'vat': False,
        'comment': False,
        'active': False,
    })
    # Verknüpfte Daten via mail.message + ir.attachment cleanen
    self.message_ids.unlink()
    self.env['ir.attachment'].search([
        ('res_model', '=', 'res.partner'),
        ('res_id', '=', self.id),
    ]).unlink()
```

> Hartes `unlink()` ist oft nicht möglich (Foreign Keys auf Invoices etc.).
> Anonymisierung + `active=False` ist DSGVO-konform.

### Datenexport (Auskunftsrecht)

Odoo bietet via `Settings → Technical → Database → Export Data` Standard-CSV-
Export. Programmatisch:

```python
def action_export_personal_data(self):
    self.ensure_one()
    data = {
        'partner': self.read()[0],
        'invoices': self.invoice_ids.read(['name', 'amount_total', 'invoice_date']),
        'tickets': self.ticket_ids.read(['name', 'description']),
    }
    return self.env['ir.attachment'].create({
        'name': f'gdpr_export_{self.id}.json',
        'datas': base64.b64encode(json.dumps(data, default=str).encode()),
        'res_model': 'res.partner',
        'res_id': self.id,
    })
```

---

## 12. Audit-Logging

### Built-in: `mail.thread` mit `tracking=True`

```python
class EledialProject(models.Model):
    _inherit = ['mail.thread']

    state = fields.Selection(..., tracking=True)
    user_id = fields.Many2one('res.users', tracking=True)
```

Jede Änderung von `state` oder `user_id` legt eine `mail.message` an. Im Chatter
sichtbar, im `mail.message`-Modell durchsuchbar.

### Echtes Audit-Log (Sensible Operationen)

```python
def action_force_unlink(self):
    self.env['ir.logging'].sudo().create({
        'name': 'eledia_project',
        'type': 'server',
        'level': 'warning',
        'message': f'Force-unlink of {self.name} by {self.env.user.login}',
        'path': __file__,
        'func': 'action_force_unlink',
        'line': '1',
    })
    return self.unlink()
```

Für umfassendes Audit: OCA-Modul `auditlog`
(https://github.com/OCA/server-tools/tree/18.0/auditlog).

---

## 13. Häufige Sicherheits-Fehler

| Fehler | Konsequenz |
|---|---|
| `sudo()` ohne Domain-Restriktion | Daten-Leak quer durch Tenants |
| `auth='public'` ohne explizite Auth-Logik | Anonymer Zugriff auf interne Daten |
| `csrf=False` ohne eigene Verifikation | CSRF-Angriff |
| f-String in `cr.execute` | SQL-Injection |
| `t-out` mit User-Input ohne Sanitize | XSS |
| Multi-Company-Modell ohne globale Rule | Cross-Tenant-Leakage |
| Vergessenes `groups="…"` an Admin-Buttons | User triggert Admin-Action |
| `unlink()` ohne `check_access_rule` | Datenverlust |
| API-Key in `_logger.info` | Credentials in Logs |
| `Image`/`Binary`-Felder ohne `attachment=True` bei großen Files | DB-Bloat + Backup-Aufblähung |

---

## 14. Quellen

- Security Reference: https://www.odoo.com/documentation/18.0/developer/reference/backend/security.html
- Module Manifests: https://www.odoo.com/documentation/18.0/developer/reference/backend/module.html
- HTTP Routes: https://www.odoo.com/documentation/18.0/developer/reference/backend/http.html
- OCA `auditlog`: https://github.com/OCA/server-tools/tree/18.0/auditlog
- OWASP Odoo-Guide: keine offizielle, aber pylint-odoo-Checks (`sql-injection`, `external-request-without-timeout`) decken die Top-Ten-Klassiker ab.
