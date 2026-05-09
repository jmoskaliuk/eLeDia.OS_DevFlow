---
name: odoo-enterprise-specifics
description: >
  Odoo-18-Enterprise-spezifische Module, ihre APIs und die Regeln für ihre
  Erweiterung — Studio, Approvals, Documents, Sign, IoT, Voice/VoIP, Marketing
  Automation, Subscriptions, Field Service, Helpdesk, Quality, MRP-PLM,
  Accounting (in Enterprise-Erweiterungen), Spreadsheet, Knowledge, Appointments.
  Verwende diesen Skill, wenn ein Modul aus Enterprise erweitert werden soll, bei
  Lizenz-/OPL-Fragen, bei Studio-vs.-Code-Entscheidungen, bei Subscription-Logik,
  bei der Wahl zwischen Community-OCA-Modul und Enterprise-Pendant.
  Trigger bei "Enterprise", "Studio", "Approvals", "Documents", "Sign",
  "Subscription", "subscription_management", "Field Service", "industry",
  "Helpdesk", "Quality", "PLM", "IoT", "Voice", "VoIP", "Marketing Automation",
  "Spreadsheet", "Knowledge", "Appointments", "OPL-1", "Apps-Store-Lizenz".
  Pair mit odoo-dev (Inheritance) und odoo-coding-guidelines (Lizenz-Header).
---

# Odoo 18 Enterprise — Spezifika

Übersicht der wichtigsten Enterprise-Module, ihrer APIs und der Best-Practices
zur Erweiterung. **Lizenz-Hinweis:** Enterprise-Module stehen unter **OPL-1**
(Odoo Proprietary License v1.0). Eigene Module, die `_inherit` auf Enterprise-
Modelle machen, dürfen ebenfalls nicht GPL/LGPL sein, sondern müssen OPL-1 oder
proprietär bleiben.

**Quelle:**
- https://www.odoo.com/documentation/18.0/applications.html
- Repo: https://github.com/odoo/enterprise (privater Zugang, Enterprise-Customer)

---

## 1. Lizenz-Modell

| Lizenz | Wann |
|---|---|
| **LGPL-3** | Community-Modul, frei nutzbar, modifizierbar |
| **OPL-1** | Apps-Store-Modul (kostenpflichtig oder kostenlos), Modifikation nur intern |
| **AGPL-3** | OCA-Module (strenger als LGPL — kein Hosting ohne Source-Disclosure) |

**Folgen für eigenes Modul:**

```python
# __manifest__.py — Apps-Store-Modul
'license': 'OPL-1',
```

- Wenn das Modul **Enterprise-Module erweitert** (`_inherit` oder `depends`):
  Lizenz **muss** OPL-1 oder proprietär sein. **Niemals LGPL/AGPL**.
- Wenn das Modul **nur Community-Module erweitert**: LGPL-3 (Apps-Store) oder
  AGPL-3 (OCA) erlaubt.
- Bei Mischfall: das **strengste** Vorbild gibt die Lizenz vor — also OPL-1.

---

## 2. Studio (`web_studio`)

**Was es ist:** No-Code-Editor für Custom Felder, Views, Reports, Workflows.
Ergebnis: Records in `ir.model`, `ir.model.fields`, `ir.ui.view` mit
`type='form'` und `xml_id`-Präfix `studio_customization.`.

### Wann Studio, wann Code?

| Kriterium | Studio | Code |
|---|---|---|
| Custom-Feld in bestehender View | ✓ | (auch möglich, aber overkill) |
| Custom-Modell für Kunden-Workflow | ✓ | wenn Logik komplex ist |
| Custom-Report mit Logik | ✗ (nur einfache QWeb) | ✓ |
| Compute-Felder mit Domain | ✗ | ✓ |
| Server-Action mit `code` | ✓ (limited Python) | ✓ |
| Multi-Modul-Erweiterung | ✗ | ✓ |
| Versionsmigration | umständlich (Customizations exportieren/importieren) | git |

**Faustregel eLeDia:** Studio nur als **Prototyp** oder für **kleinste**
Änderungen, bei denen ein eigenes Modul Overhead wäre. Sobald CI, Tests, oder
Multi-Stage-Deployment ins Spiel kommt: **Code**.

### Studio-Customization als Modul exportieren

`Settings → Studio → Customizations → Export` lädt eine ZIP herunter, die ein
echtes Odoo-Modul ist (`studio_customization` heißt es per Default — vor Import
umbenennen). Anschließend kann es git-versioniert werden.

```bash
unzip studio_customization.zip
mv studio_customization eledia_field_studio
sed -i 's/studio_customization/eledia_field_studio/g' eledia_field_studio/__manifest__.py
```

> **Achtung:** Studio-XML-IDs haben oft `studio_customization.` als Präfix —
> beim Import in eigene Module **alle ändern**, sonst Konflikte mit nächster
> Studio-Session.

---

## 3. Approvals (`approvals`)

Genehmigungs-Workflow für jedes Modell.

### Standard-Felder

```python
class HrExpense(models.Model):
    _inherit = 'hr.expense'
    _inherit = ['mail.thread', 'mail.activity.mixin']    # Pflicht für Approvals

    approver_id = fields.Many2one('res.users', string='Approver')
    approval_state = fields.Selection([
        ('draft', 'Draft'),
        ('submit', 'Submitted'),
        ('approve', 'Approved'),
        ('refuse', 'Refused'),
    ], default='draft', tracking=True)
```

### Approval-Type konfigurieren

`Approvals → Konfiguration → Approval Types`:

- **Approver:** User oder Group
- **Has Amount:** ob Approval einen Betrag hat
- **Has Approver:** ob der Approver pro Request bestimmt wird
- **Stages:** mehrstufige Approvals (Manager → Director → CFO)

### Eigene Approval-Type via XML

```xml
<record id="approval_type_eledia_travel" model="approval.category">
    <field name="name">Reisekosten</field>
    <field name="approval_minimum">1</field>
    <field name="has_amount">required</field>
    <field name="amount_min">100.00</field>
    <field name="approver_ids" eval="[(4, ref('hr.group_hr_manager'))]"/>
</record>
```

---

## 4. Documents (`documents`)

DMS mit OCR (Optical Character Recognition), Tags, Workspaces, Workflows.

### Workspace-Strukturen

```python
class DocumentsWorkspace(models.Model):
    _inherit = 'documents.folder'

    # eigene Felder
    eledia_retention_days = fields.Integer()
```

### Dokument programmatisch hinzufügen

```python
attachment = self.env['ir.attachment'].create({
    'name': 'Vertrag.pdf',
    'datas': base64.b64encode(pdf_bytes),
    'res_model': 'documents.document',
    'res_id': 0,
})
self.env['documents.document'].create({
    'name': 'Vertrag.pdf',
    'attachment_id': attachment.id,
    'folder_id': self.env.ref('documents.documents_finance_folder').id,
    'tag_ids': [(4, self.env.ref('documents.documents_finance_paid').id)],
})
```

### OCR / IAP

Documents-OCR nutzt Odoo IAP (`In-App Purchase`, kostenpflichtig pro OCR).
Für Self-Hosted-Alternative: Tesseract via Custom-Modul + `python-tesseract`.

---

## 5. Sign (`sign`)

E-Signatur. Templates, Reminder, Audit-Trail.

### Template programmatisch

```python
template = self.env['sign.template'].create({
    'name': 'Vertrag-Template',
    'attachment_id': pdf_attachment.id,
})

# Felder zum Template (Position auf der PDF)
self.env['sign.item'].create({
    'template_id': template.id,
    'type_id': self.env.ref('sign.sign_item_type_signature').id,
    'required': True,
    'page': 1,
    'posX': 0.5,
    'posY': 0.8,
    'width': 0.2,
    'height': 0.04,
    'responsible_id': self.env.ref('sign.sign_default_role_customer').id,
})
```

### Sign-Request senden

```python
sign_request = self.env['sign.request'].create({
    'template_id': template.id,
    'request_item_ids': [(0, 0, {
        'partner_id': customer.partner_id.id,
        'role_id': customer_role.id,
    })],
    'subject': 'Bitte unterschreiben',
    'message': 'Ihr Vertrag steht zur Unterschrift bereit.',
})
sign_request.send_signature_accesses()
```

---

## 6. Subscriptions (`sale_subscription`)

### Modell-Hierarchie

```
sale.subscription.plan          ← Plan-Definition (z.B. „Monthly Pro")
   └ recurring_invoice_template   ← Mail-Template
   └ recurring_rule_count          ← „6 Wochen vor Ende reminden"

sale.order                      ← bei is_subscription=True
   └ sale.order.line              ← mit subscription_pricing
```

### Eigenes Subscription-Modell anlegen

```python
class SaleOrder(models.Model):
    _inherit = 'sale.order'

    eledia_renewal_discount = fields.Float()

    def _create_invoices(self, grouped=False, final=False, date=None):
        invoices = super()._create_invoices(grouped, final, date)
        if self.is_subscription and self.eledia_renewal_discount:
            invoices.write({'global_discount': self.eledia_renewal_discount})
        return invoices
```

### Renewal-Logik

```python
class SaleOrder(models.Model):
    _inherit = 'sale.order'

    def action_renew_subscription(self):
        self.ensure_one()
        # Standard-Methode aus subscriptions
        new_order = super().action_renew_subscription()
        # eigene Hooks
        new_order.eledia_loyalty_bonus = self._compute_loyalty_bonus()
        return new_order
```

### MRR / ARR berechnen

```python
mrr = self.env['sale.subscription.alert'].search([]).filtered(
    lambda a: a.action == 'rule_action_alert'
).mapped('mrr_change')
```

Für Reports: `sale.report` (View) hat `is_subscription`-Filter und `mrr_change`-
Feld.

---

## 7. Field Service (`industry_fsm`)

Service-Aufträge vor Ort, Zeit-/Material-Erfassung, Geo-Tracking.

### Task-Modell-Erweiterung

```python
class ProjectTask(models.Model):
    _inherit = 'project.task'

    eledia_signature_required = fields.Boolean(default=False)
    eledia_kit_id = fields.Many2one('product.template')

    def action_fsm_create_quotation(self):
        result = super().action_fsm_create_quotation()
        if self.eledia_kit_id:
            result.update({'context': dict(result.get('context', {}),
                                           default_eledia_kit=self.eledia_kit_id.id)})
        return result
```

### Mobil-View

Field Service hat eigene Mobile-Optimierungen — `<form>` mit `class="o_fsm_form"`
und spezielle Action-Bars. Eigene Erweiterungen sollten via `xpath`
inheritance dort einklinken, nicht ersetzen.

---

## 8. Helpdesk (`helpdesk`)

Ticketing. Ähnlich Project, aber mit SLA, Eskalationen, Customer-Portal-View.

### SLA-Konfiguration

```xml
<record id="sla_eledia_response" model="helpdesk.sla">
    <field name="name">First Response &lt; 4h</field>
    <field name="team_id" ref="helpdesk.helpdesk_team1"/>
    <field name="stage_id" ref="helpdesk.stage_in_progress"/>
    <field name="time">4</field>
    <field name="exclude_stage_ids" eval="[(4, ref('helpdesk.stage_solved'))]"/>
</record>
```

### Eskalation triggern

```python
class HelpdeskTicket(models.Model):
    _inherit = 'helpdesk.ticket'

    def cron_check_sla(self):
        breached = self.search([
            ('sla_status', '=', 'failed'),
            ('escalated', '=', False),
        ])
        for ticket in breached:
            ticket.assigned_user_id = ticket.team_id.escalation_user_id
            ticket.escalated = True
            ticket.message_post(body=_("SLA verletzt — eskaliert an %s",
                                       ticket.assigned_user_id.name))
```

---

## 9. Quality (`quality`)

QC-Checks in MRP, Stock, Purchase. Quality-Points definieren wann ein Check
fällig wird.

### Quality-Point

```xml
<record id="quality_point_eledia_serial_check" model="quality.point">
    <field name="title">Seriennummern-Validierung</field>
    <field name="picking_type_ids" eval="[(4, ref('stock.picking_type_in'))]"/>
    <field name="product_ids" eval="[(4, ref('product.product_product_8'))]"/>
    <field name="test_type_id" ref="quality.test_type_text"/>
    <field name="note">Seriennummer auf dem Karton checken.</field>
</record>
```

---

## 10. IoT (`iot`)

Hardware-Integration: Drucker, Waagen, Scanner, Cash-Drawer. Setzt eine
**IoT-Box** voraus (Raspberry Pi mit gepatched OS).

### IoT-Device aus Custom-Code triggern

```python
def action_print_label(self):
    self.ensure_one()
    return {
        'type': 'ir.actions.client',
        'tag': 'iot_send_value_to_device',
        'params': {
            'iot_ip': self.iot_box_ip,
            'identifier': self.printer_identifier,
            'value': self._get_label_zpl(),
        },
    }
```

ZPL = Zebra Printer Language. Für Standard-PDF-Drucker reicht ein normaler
`ir.actions.report`.

### IoT vs. Direct-Print

| Use-Case | IoT-Box | Direkt vom Browser |
|---|---|---|
| Etiketten-Drucker | ✓ | ✗ |
| Kassen-Drucker | ✓ | ✗ |
| Waage | ✓ | ✗ |
| Standard-Bürodrucker | ✗ (overkill) | ✓ (PDF→Browser-Print) |
| Barcode-Scanner | ✓ (USB-HID) oder Browser-API | beide |

---

## 11. Marketing Automation (`marketing_automation`)

Mehrstufige Mail-Kampagnen mit Triggern (Filter-Match, Mail-Open, Link-Click).

### Custom-Action-Type

Marketing-Automation kennt `child_ids` mit `trigger_type`:
`begin`, `mail_open`, `mail_reply`, `mail_click`, `mail_bounce`, `act_filter`.

```python
class MarketingActivity(models.Model):
    _inherit = 'marketing.activity'

    eledia_score_increment = fields.Integer()

    def execute(self, *args, **kwargs):
        result = super().execute(*args, **kwargs)
        if self.eledia_score_increment:
            for trace in self._get_traces_to_process():
                trace.res_id and \
                self.env[self.model_name].browse(trace.res_id).write({
                    'lead_score': F('lead_score') + self.eledia_score_increment,
                })
        return result
```

---

## 12. Spreadsheet (`spreadsheet`, Enterprise)

Voll-Excel-kompatible Spreadsheets in Odoo (auf Basis von **o-spreadsheet**, das
auch Open-Source ist). Pivot, Charts, Formeln, Filter.

### Spreadsheet aus eigenen Daten erstellen

```python
data = self.env['eledia.project'].read_group(
    [], ['user_id', 'total_amount:sum'], ['user_id']
)

# Spreadsheet-Document
sheet = self.env['documents.document'].create({
    'name': 'KPI-Übersicht.osheet',
    'handler': 'spreadsheet',
    'raw': self._build_spreadsheet_json(data),
})
```

`_build_spreadsheet_json` erzeugt das o-spreadsheet-JSON-Format.

### Templates

`Spreadsheet → Templates`. Kann via Code als XML-Record vorbefüllt werden:

```xml
<record id="spreadsheet_template_eledia_kpi" model="spreadsheet.template">
    <field name="name">eLeDia KPI-Dashboard</field>
    <field name="data">…JSON…</field>
</record>
```

---

## 13. Knowledge (`knowledge`)

Confluence-Konkurrent in Odoo. Hierarchie aus Articles, Inline-Embeds (Pivot,
Kanban, Spreadsheet, Sign, etc.).

### Article-Struktur

```python
article = self.env['knowledge.article'].create({
    'name': 'Onboarding eLeDia',
    'icon': '🚀',
    'parent_id': self.env.ref('knowledge.article_help').id,
    'body': '<p>Willkommen…</p>',
})

# Sub-Articles
self.env['knowledge.article'].create({
    'parent_id': article.id,
    'name': 'Erster Tag',
    'sequence': 1,
})
```

### Embed in Article

Knowledge unterstützt `/`-Commands für Embeds. Programmatisch:

```html
<div class="o_knowledge_behavior_type_view"
     data-behavior-props='{"act_window":{"id":42},"viewType":"kanban","name":"Projekte"}'>
</div>
```

`{"id": 42}` = `ir.actions.act_window`-ID.

---

## 14. Appointments (`appointment`)

Calendly-ähnliches Buchungs-Tool. Resource-basiert.

### Appointment-Type

```xml
<record id="appointment_type_eledia_consultation" model="appointment.type">
    <field name="name">eLeDia-Beratungs-Slot</field>
    <field name="appointment_duration">0.5</field>
    <field name="min_schedule_hours">2</field>
    <field name="max_schedule_days">15</field>
    <field name="staff_user_ids" eval="[(4, ref('base.user_admin'))]"/>
    <field name="slot_ids" eval="[
        (0, 0, {'weekday': '1', 'start_hour': 9.0, 'end_hour': 12.0}),
        (0, 0, {'weekday': '1', 'start_hour': 14.0, 'end_hour': 17.0}),
    ]"/>
</record>
```

Public-URL: `https://<host>/appointment/<id>`. Custom-Routing via Controller-Override.

---

## 15. Voice / VoIP (`voip`)

Click-to-call, Inbound-Routing via Asterisk/sipgate/Twilio. Nur Enterprise.

### VoIP-Trigger aus Custom-Code

```python
def action_call_partner(self):
    self.ensure_one()
    return {
        'type': 'ir.actions.client',
        'tag': 'voip_call',
        'params': {
            'phone': self.partner_id.phone,
            'res_model': 'eledia.project',
            'res_id': self.id,
        },
    }
```

VoIP setzt **PBX-Konfiguration** voraus (`Settings → VoIP`). Eigene PBX-
Anbindung über `voip.queue` und `voip.event`-Modelle.

---

## 16. Studio-Field-Properties — Flexibles Datenmodell ohne Code

Eines der Killer-Features von Odoo 17/18: **Properties** = Custom-Felder, die
**pro Parent-Record** unterschiedlich sein können.

```python
class ProjectTask(models.Model):
    _inherit = 'project.task'

    properties = fields.Properties(
        definition_record='project_id',
        definition_record_field='task_properties_definition',
    )


class ProjectProject(models.Model):
    _inherit = 'project.project'

    task_properties_definition = fields.PropertiesDefinition()
```

→ Pro Project sind die Felder anders. User definiert die Properties in der UI.
**Kein eigener Code für Custom-Felder nötig.**

> Wenn der Kunde sagt „wir wollen flexible Custom-Felder pro X" → erst
> Properties prüfen, **dann** Studio, **dann** eigenes Modul.

---

## 17. Wann Enterprise-Modul, wann OCA?

Faustregel: **Enterprise-Modul** lohnt, wenn …

- Es ein **direktes Pendant** in OCA gibt, das aber 1–2 Major-Versionen hinterher hängt.
- Du **schnell** liefern musst und keine Zeit für Code-Audit hast.
- Die **Enterprise-Lizenz** sowieso schon vorhanden ist.
- **Customer-Support** Teil des Pakets ist (z.B. SLA-Eskalation an Odoo SAS).

**OCA-Modul** lohnt, wenn …

- Du das **Modul anpassen** musst (OCA-Module sind LGPL/AGPL, voll modifizierbar).
- Du **Self-Hosted** bist und Odoo SAS keinen Mehrwert bringt.
- Das **Enterprise-Modul** ein Feature **fehlt**, das in OCA besteht.
- Es **Community-Pflicht** in deinem Repo gibt (z.B. AGPL-Stack).

### Häufige Doppel-Implementierungen

| Funktion | Enterprise | OCA-Pendant |
|---|---|---|
| Helpdesk | `helpdesk` | `helpdesk_mgmt` (`OCA/helpdesk`) |
| Studio | `web_studio` | — (keine Alternative) |
| Documents | `documents` | `dms` (`OCA/dms`) |
| Sign | `sign` | — (Drittanbieter) |
| Field Service | `industry_fsm` | `fieldservice` (`OCA/field-service`) |
| MRP-PLM | `mrp_plm` | — |
| Quality | `quality` | `quality_control_oca` (`OCA/manufacture`) |
| Subscriptions | `sale_subscription` | `contract` (`OCA/contract`) |
| Marketing Automation | `marketing_automation` | — |
| Knowledge | `knowledge` | `dms` + Wiki-Module aus `OCA/knowledge` |
| Spreadsheet | `spreadsheet` (intern: `o-spreadsheet`) | direkt `o-spreadsheet` (NPM, OSS) |

---

## 18. Anti-Patterns

1. **Enterprise-Modul forken statt erweitern** — bricht beim nächsten Update.
   `_inherit` und Hooks nutzen.
2. **OPL-1-Code in `OCA`-Repo** — Lizenz-Konflikt; OCA verlangt AGPL.
3. **Studio-Customization in Production**, ohne Export → git → Versionierung —
   nicht reproduzierbar, nicht testbar.
4. **Sign-Request an Public-URL** ohne IP-Whitelist → Phishing-Risiko.
5. **VoIP-Modul ohne PBX-Config** installieren → Crashes beim Click-to-Call.
6. **`industry_fsm` parallel zu eigenem Field-Service-Code** → doppelte Logik.
7. **`sale.subscription.line` direkt manipulieren** statt via `subscription_id._update_lines()`
   → MRR-Berechnung springt.
8. **Knowledge-Article direkt in DB einfügen** ohne `body`-Sanitization → XSS.

---

## 19. Quellen

- Enterprise-Übersicht: https://www.odoo.com/de_DE/page/editions
- Enterprise-Module-Repo (privat, mit Lizenz): https://github.com/odoo/enterprise
- OCA-Repos: https://github.com/OCA
- OPL-1-Volltext: https://www.odoo.com/documentation/18.0/legal/licenses/licenses.html
- Apps-Store-Submission-Guidelines: https://www.odoo.com/page/apps-rules
- Studio-Doku: https://www.odoo.com/documentation/18.0/applications/studio.html
- Subscription-Doku: https://www.odoo.com/documentation/18.0/applications/sales/subscriptions.html
- Approvals: https://www.odoo.com/documentation/18.0/applications/services/helpdesk.html
- IoT: https://www.odoo.com/documentation/18.0/applications/general/iot.html
- VoIP: https://www.odoo.com/documentation/18.0/applications/productivity/voip.html
