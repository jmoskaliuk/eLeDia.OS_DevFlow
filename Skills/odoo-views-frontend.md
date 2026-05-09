---
name: odoo-views-frontend
description: >
  Views, QWeb, OWL 2, Field-Widgets, Actions, Menus und QWeb-Reports für
  Odoo 18 Enterprise. Verwende diesen Skill für jegliche UI-Arbeit — Form-,
  List-, Kanban-, Calendar-, Search-, Graph-, Pivot-, Activity-Views,
  XPath-Inheritance, OWL-Components, Widgets, Mustache→QWeb, Action-Konfiguration,
  Server-Actions, Reports, PDF-Generierung. Trigger bei "View", "Form-View",
  "Kanban", "List-View", "Tree-View", "Search-View", "QWeb", "OWL", "Owl Component",
  "Widget", "ir.actions", "ir.ui.menu", "xpath", "field_widget", "report",
  "Mustache" (Odoo nutzt QWeb statt Mustache), "wkhtmltopdf",
  oder XML-Dateien wie *_views.xml, *_templates.xml.
  Pair mit odoo-coding-guidelines (XML-Style) und odoo-dev (Modell-Inheritance).
---

# Odoo 18 — Views, OWL & Reports

Komplette UI-Schicht: vom XML-View über OWL-Components zum gerenderten PDF.

**Quelle:** https://www.odoo.com/documentation/18.0/developer/reference/user_interface.html
**OWL-Doku:** https://github.com/odoo/owl/blob/master/doc/readme.md

> **Odoo 18 Breaking-Changes:**
> - `<tree>` heißt jetzt `<list>` (alter Tag funktioniert noch).
> - `attrs="{'invisible': […]}"` deprecated → direkt `invisible="<expr>"`.
> - `states="…"` deprecated → `invisible="state not in ['…']"`.
> - jQuery wird schrittweise entfernt; OWL 2 ist Pflicht für Frontend-Code.

---

## 1. View-Typen — Übersicht

| Typ | Tag | Zweck |
|---|---|---|
| Form | `<form>` | Detail-/Edit-Ansicht eines Records |
| List (ehem. Tree) | `<list>` | Tabellarische Übersicht |
| Kanban | `<kanban>` | Karten-Ansicht, optional mit Spalten |
| Search | `<search>` | Filter, Such-Felder, Group-By |
| Graph | `<graph>` | Bar/Line/Pie-Chart |
| Pivot | `<pivot>` | Pivot-Tabelle |
| Calendar | `<calendar>` | Kalender (Termine, Aufgaben) |
| Gantt | `<gantt>` | Enterprise-only |
| Activity | `<activity>` | Aktivitäten-Ansicht (mit `mail.activity.mixin`) |
| Cohort | `<cohort>` | Enterprise-only |
| Map | `<map>` | Enterprise-only |
| QWeb | — | Reports / Portal-Templates |

---

## 2. Form-View — Vollständiges Beispiel

```xml
<record id="view_eledia_project_form" model="ir.ui.view">
    <field name="name">eledia.project.form</field>
    <field name="model">eledia.project</field>
    <field name="arch" type="xml">
        <form string="Projekt">
            <header>
                <!-- State-Bar -->
                <field name="state" widget="statusbar"
                       statusbar_visible="draft,active,done"/>
                <!-- Action-Buttons -->
                <button name="action_activate"
                        string="Aktivieren"
                        type="object"
                        class="btn-primary"
                        invisible="state != 'draft'"
                        confirm="Projekt wirklich aktivieren?"/>
                <button name="action_done"
                        string="Abschließen"
                        type="object"
                        invisible="state != 'active'"/>
                <button name="action_cancel"
                        string="Stornieren"
                        type="object"
                        invisible="state in ['done', 'cancel']"/>
            </header>

            <sheet>
                <!-- Smart-Buttons (Box oben rechts) -->
                <div class="oe_button_box" name="button_box">
                    <button name="action_view_lines"
                            type="object"
                            class="oe_stat_button"
                            icon="fa-list">
                        <field name="line_count" widget="statinfo" string="Zeilen"/>
                    </button>
                </div>

                <!-- Archivierungs-Banner -->
                <widget name="web_ribbon" title="Archiviert" bg_color="bg-danger"
                        invisible="active"/>

                <!-- Titel -->
                <div class="oe_title">
                    <h1>
                        <field name="name" placeholder="Projektname"/>
                    </h1>
                </div>

                <!-- Hauptgruppen -->
                <group>
                    <group>
                        <field name="user_id" widget="many2one_avatar_user"/>
                        <field name="company_id" groups="base.group_multi_company"/>
                    </group>
                    <group>
                        <field name="currency_id" invisible="1"/>
                        <field name="total_amount" widget="monetary"/>
                    </group>
                </group>

                <!-- Notebook mit Tabs -->
                <notebook>
                    <page string="Zeilen" name="lines">
                        <field name="line_ids">
                            <list editable="bottom">
                                <field name="sequence" widget="handle"/>
                                <field name="name"/>
                                <field name="amount" widget="monetary"/>
                                <field name="state"/>
                            </list>
                        </field>
                    </page>
                    <page string="Beschreibung" name="description">
                        <field name="description" widget="html"
                               options="{'collaborative': true}"/>
                    </page>
                </notebook>
            </sheet>

            <!-- Chatter -->
            <chatter/>
        </form>
    </field>
</record>
```

> **Odoo 18:** `<chatter/>` ist die neue Kurzform statt `<div class="oe_chatter">…</div>`.

### Konditionelle Sichtbarkeit & Pflicht

```xml
<!-- Verboten: attrs (deprecated) -->
<!-- field name="vat" attrs="{'required': [('country_id.code', '=', 'DE')]}"/ -->

<!-- Korrekt: direkt -->
<field name="vat" required="country_id.code == 'DE'"/>
<field name="vat" readonly="state == 'done'"/>
<field name="vat" invisible="not partner_id"/>
<field name="vat" column_invisible="parent.state == 'draft'"/>
```

Ausdrücke sind Python-Subset, ausgewertet im Recordset-Context. Verfügbar:
`record fields`, `parent.<field>` (in Subviews), `context`, `uid`, `id`.

---

## 3. List-View (ehem. Tree)

```xml
<record id="view_eledia_project_list" model="ir.ui.view">
    <field name="name">eledia.project.list</field>
    <field name="model">eledia.project</field>
    <field name="arch" type="xml">
        <list string="Projekte"
              decoration-success="state == 'done'"
              decoration-info="state == 'active'"
              decoration-muted="state == 'cancel'"
              multi_edit="1"
              sample="1">
            <field name="name"/>
            <field name="user_id" widget="many2one_avatar_user" optional="show"/>
            <field name="company_id" optional="hide" groups="base.group_multi_company"/>
            <field name="line_count"/>
            <field name="total_amount" widget="monetary" sum="Summe"/>
            <field name="state" widget="badge"
                   decoration-success="state == 'done'"
                   decoration-info="state == 'active'"/>
            <button name="action_done"
                    string="Abschließen"
                    type="object"
                    icon="fa-check"
                    invisible="state != 'active'"/>
        </list>
    </field>
</record>
```

**Wichtige List-Attribute:**

- `editable="top|bottom"` — Inline-Editing
- `multi_edit="1"` — Selection-basierte Mehrfach-Bearbeitung
- `sample="1"` — Sample-Records bei leerer DB anzeigen
- `decoration-<class>="<expr>"` — Zeilen-Färbung (`success`, `info`, `warning`,
  `danger`, `muted`, `primary`, `bf` für Bold)
- `default_order="name desc"` — Default-Sortierung
- `expand="1"` (für Tree-Models mit `parent_id`) — automatisch expanden

---

## 4. Kanban-View

```xml
<record id="view_eledia_project_kanban" model="ir.ui.view">
    <field name="name">eledia.project.kanban</field>
    <field name="model">eledia.project</field>
    <field name="arch" type="xml">
        <kanban default_group_by="state"
                class="o_kanban_small_column"
                quick_create="1"
                sample="1">
            <field name="state"/>
            <field name="user_id"/>
            <field name="total_amount"/>
            <field name="currency_id"/>
            <field name="activity_state"/>

            <progressbar field="state"
                         colors='{"draft":"muted","active":"info","done":"success","cancel":"danger"}'/>

            <templates>
                <t t-name="kanban-box">
                    <div t-attf-class="oe_kanban_card oe_kanban_global_click">
                        <div class="o_kanban_record_top">
                            <div class="o_kanban_record_headings">
                                <strong class="o_kanban_record_title">
                                    <field name="name"/>
                                </strong>
                            </div>
                            <field name="activity_ids" widget="kanban_activity"/>
                        </div>
                        <div class="o_kanban_record_body">
                            <field name="line_count"/> Zeilen
                        </div>
                        <div class="o_kanban_record_bottom">
                            <div class="oe_kanban_bottom_left">
                                <field name="total_amount" widget="monetary"/>
                            </div>
                            <div class="oe_kanban_bottom_right">
                                <field name="user_id" widget="many2one_avatar_user"/>
                            </div>
                        </div>
                    </div>
                </t>
            </templates>
        </kanban>
    </field>
</record>
```

Verfügbare Kanban-Direktiven:

- `t-name="kanban-box"` — Haupt-Template (Pflicht)
- `t-name="kanban-tooltip"` — Tooltip
- `t-name="kanban-menu"` — Dropdown-Menü pro Karte (drei Punkte)
- `<a type="object" name="…">` — Action-Link
- `<a type="set_cover" data-field="image"/>` — Cover-Image setzen

---

## 5. Search-View

```xml
<record id="view_eledia_project_search" model="ir.ui.view">
    <field name="name">eledia.project.search</field>
    <field name="model">eledia.project</field>
    <field name="arch" type="xml">
        <search>
            <field name="name" string="Projekt"/>
            <field name="user_id"/>
            <field name="company_id" groups="base.group_multi_company"/>

            <separator/>

            <filter name="my_projects"
                    string="Meine Projekte"
                    domain="[('user_id', '=', uid)]"/>
            <filter name="active"
                    string="Aktiv"
                    domain="[('state', '=', 'active')]"/>
            <filter name="archived"
                    string="Archiviert"
                    domain="[('active', '=', False)]"/>

            <separator/>

            <filter name="created_today"
                    string="Heute angelegt"
                    domain="[('create_date', '>=', context_today().strftime('%Y-%m-%d'))]"/>

            <group expand="0" string="Group By">
                <filter name="group_state" string="Status" context="{'group_by': 'state'}"/>
                <filter name="group_user" string="Verantwortlich" context="{'group_by': 'user_id'}"/>
                <filter name="group_company" string="Company"
                        context="{'group_by': 'company_id'}"
                        groups="base.group_multi_company"/>
            </group>

            <searchpanel>
                <field name="company_id" enable_counters="1"/>
                <field name="state" select="multi" enable_counters="1"/>
            </searchpanel>
        </search>
    </field>
</record>
```

Search-Panel (links neben Liste/Kanban) ist Odoo 14+, in 18 produktionsstabil.

---

## 6. Graph- und Pivot-Views

```xml
<record id="view_eledia_project_graph" model="ir.ui.view">
    <field name="name">eledia.project.graph</field>
    <field name="model">eledia.project</field>
    <field name="arch" type="xml">
        <graph type="bar" stacked="1" sample="1">
            <field name="user_id"/>
            <field name="state"/>
            <field name="total_amount" type="measure"/>
        </graph>
    </field>
</record>

<record id="view_eledia_project_pivot" model="ir.ui.view">
    <field name="name">eledia.project.pivot</field>
    <field name="model">eledia.project</field>
    <field name="arch" type="xml">
        <pivot sample="1" disable_linking="0">
            <field name="user_id" type="row"/>
            <field name="state" type="col"/>
            <field name="total_amount" type="measure"/>
        </pivot>
    </field>
</record>
```

`type="bar|line|pie"`. `type="measure"` = Y-Achse (aggregiert). Multiple
`type="row"`/`"col"` für mehrere Dimensionen.

---

## 7. Calendar- und Activity-Views

```xml
<record id="view_eledia_project_calendar" model="ir.ui.view">
    <field name="name">eledia.project.calendar</field>
    <field name="model">eledia.project</field>
    <field name="arch" type="xml">
        <calendar string="Projekte"
                  date_start="date_start"
                  date_stop="date_end"
                  color="user_id"
                  mode="month"
                  quick_create="1">
            <field name="name"/>
            <field name="user_id" filters="1"/>
        </calendar>
    </field>
</record>

<record id="view_eledia_project_activity" model="ir.ui.view">
    <field name="name">eledia.project.activity</field>
    <field name="model">eledia.project</field>
    <field name="arch" type="xml">
        <activity string="Projekte">
            <field name="user_id"/>
            <templates>
                <div t-name="activity-box">
                    <field name="user_id" widget="many2one_avatar_user"/>
                    <div>
                        <field name="name" class="o_text_overflow"/>
                    </div>
                </div>
            </templates>
        </activity>
    </field>
</record>
```

---

## 8. View-Inheritance via XPath

```xml
<record id="view_partner_form_eledia" model="ir.ui.view">
    <field name="name">res.partner.form.eledia</field>
    <field name="model">res.partner</field>
    <field name="inherit_id" ref="base.view_partner_form"/>
    <field name="arch" type="xml">
        <!-- Page hinzufügen -->
        <xpath expr="//notebook" position="inside">
            <page string="Loyalty" name="loyalty">
                <group>
                    <field name="eledia_loyalty_points"/>
                    <field name="eledia_tier" widget="badge"/>
                </group>
            </page>
        </xpath>

        <!-- Feld nach existierendem einfügen -->
        <xpath expr="//field[@name='vat']" position="after">
            <field name="eledia_tax_office_id"/>
        </xpath>

        <!-- Feld-Attribute ändern -->
        <xpath expr="//field[@name='website']" position="attributes">
            <attribute name="placeholder">https://</attribute>
            <attribute name="invisible">type == 'private'</attribute>
        </xpath>

        <!-- Element ersetzen (vermeiden!) -->
        <xpath expr="//field[@name='comment']" position="replace">
            <field name="comment" placeholder="Notizen…"/>
        </xpath>

        <!-- Element komplett entfernen (vermeiden!) -->
        <xpath expr="//field[@name='website']" position="replace"/>
    </field>
</record>
```

**Position-Werte:**

- `inside` (Default) — Kinder am Ende einfügen
- `before` — vor dem Element
- `after` — nach dem Element
- `replace` — Element ersetzen (oder bei leerem Body: entfernen)
- `attributes` — Attribute des Elements ändern
- `move` — Element an neue Stelle verschieben

**Verkürzte Form** (für eindeutige Selektoren):

```xml
<!-- Statt <xpath expr="//field[@name='vat']" …> -->
<field name="vat" position="after">
    <field name="eledia_tax_office_id"/>
</field>
```

**XPath-Tipps:**

- `//field[@name='x']` — alle Felder mit Name `x`
- `//page[@name='x']` — Page mit `name="x"`
- `//notebook//page[1]` — erste Page
- `//header/button[@name='action_confirm']` — präzise Selektion
- Bei mehrdeutigem Match: nutze `name`-Attribute, nicht Reihenfolge.

---

## 9. Widgets — Cheatsheet

### Standard-Widgets (Form, List)

| Widget | Field-Typ | Wirkung |
|---|---|---|
| `email` | Char | Mailto-Link, validate |
| `url` | Char | Klickbar, validiert |
| `phone` | Char | Click-to-call (mit VoIP-Modul) |
| `monetary` | Float/Monetary | Mit Currency-Suffix |
| `percentage` | Float | "%" + Schieber |
| `progressbar` | Integer/Float | Balken |
| `priority` | Selection | Sterne |
| `boolean_toggle` | Boolean | Switch |
| `boolean_button` | Boolean | großer Toggle-Button |
| `radio` | Selection | Radio-Buttons |
| `selection_badge` | Selection | bunte Badges |
| `badge` | Char/Selection | Bunter Badge in Listen |
| `image` | Binary | Bildvorschau |
| `image_url` | Char | URL → Bild |
| `binary` | Binary | Up-/Download |
| `pdf_viewer` | Binary | inline PDF-Vorschau |
| `signature` | Binary | Touch-Signature |
| `html` | Html | TinyMCE-Editor |
| `text` | Text | mehrzeilig |
| `daterange` | Date | Range-Picker (in Verbindung mit zweitem Feld) |
| `remaining_days` | Date | "in 3 Tagen" / "vor 2 Tagen" |
| `handle` | Integer (sequence) | Drag-Handle |
| `statinfo` | Numeric | Smart-Button-Inhalt |
| `statusbar` | Selection | State-Bar im Header |
| `many2one_avatar_user` | Many2one(res.users) | Avatar + Name |
| `many2many_tags` | Many2many | Bunte Tags |
| `many2many_checkboxes` | Many2many | Checkbox-Liste |
| `web_ribbon` | — | "Archiviert"-Banner |

### Optionen via `options="{…}"`

```xml
<field name="partner_id"
       options="{'no_create': True, 'no_open': True, 'always_reload': True}"/>

<field name="amount" widget="monetary"
       options="{'currency_field': 'currency_id'}"/>

<field name="image" widget="image"
       options="{'size': [128, 128], 'preview_image': 'image_128'}"/>

<field name="tag_ids" widget="many2many_tags"
       options="{'color_field': 'color', 'no_create_edit': True}"/>
```

---

## 10. Actions (`ir.actions.*`)

### Window-Action

```xml
<record id="action_eledia_project" model="ir.actions.act_window">
    <field name="name">Projekte</field>
    <field name="res_model">eledia.project</field>
    <field name="view_mode">list,kanban,form,calendar,activity,graph,pivot</field>
    <field name="search_view_id" ref="view_eledia_project_search"/>
    <field name="domain">[]</field>
    <field name="context">{'search_default_my_projects': 1}</field>
    <field name="help" type="html">
        <p class="o_view_nocontent_smiling_face">Erstes Projekt anlegen</p>
        <p>Hier verwaltet eLeDia alle Kundenprojekte.</p>
    </field>
</record>
```

### Server-Action (Action-Type "code")

```xml
<record id="action_eledia_project_archive_old" model="ir.actions.server">
    <field name="name">Alte Projekte archivieren</field>
    <field name="model_id" ref="model_eledia_project"/>
    <field name="binding_model_id" ref="model_eledia_project"/>
    <field name="binding_view_types">list</field>
    <field name="state">code</field>
    <field name="code">
records.filtered(lambda p: p.state == 'done').toggle_active()
action = {'type': 'ir.actions.client', 'tag': 'reload'}
    </field>
</record>
```

`binding_model_id` macht die Action im "Action"-Dropdown der Liste sichtbar.

### Action aus Python zurückgeben

```python
def action_open_lines(self):
    self.ensure_one()
    return {
        'type': 'ir.actions.act_window',
        'name': _("Zeilen von %s", self.name),
        'res_model': 'eledia.project.line',
        'view_mode': 'list,form',
        'domain': [('project_id', '=', self.id)],
        'context': {'default_project_id': self.id},
    }
```

Andere Action-Typen: `ir.actions.client` (Client-Side, z.B. `reload`,
`display_notification`), `ir.actions.report` (PDF), `ir.actions.url` (Browser
öffnen).

```python
return {
    'type': 'ir.actions.client',
    'tag': 'display_notification',
    'params': {
        'title': _("Erfolg"),
        'message': _("Projekt aktiviert."),
        'type': 'success',                   # info, warning, danger
        'sticky': False,
        'next': {'type': 'ir.actions.act_window_close'},
    },
}
```

---

## 11. Menüs

```xml
<!-- Root-Menü (App im Apps-Menü) -->
<menuitem id="menu_eledia_root"
          name="eLeDia"
          web_icon="eledia_project,static/description/icon.png"
          sequence="80"/>

<!-- Hauptbereich -->
<menuitem id="menu_eledia_project"
          parent="menu_eledia_root"
          name="Projekte"
          action="action_eledia_project"
          sequence="10"/>

<!-- Konfiguration -->
<menuitem id="menu_eledia_config"
          parent="menu_eledia_root"
          name="Konfiguration"
          sequence="100"
          groups="base.group_system"/>

<menuitem id="menu_eledia_config_settings"
          parent="menu_eledia_config"
          name="Einstellungen"
          action="action_eledia_settings"/>
```

**Menü-Reihenfolge:** Niedrigere `sequence` = weiter oben.
**Sichtbarkeit** über `groups="…"` (Komma-separiert; auch `groups="!base.group_user"`
für „nicht-Mitglieder").

---

## 12. OWL 2 — Frontend-Komponenten

### Minimal-Component

```javascript
/** @odoo-module **/

import { Component, useState, onMounted } from "@odoo/owl";
import { registry } from "@web/core/registry";
import { useService } from "@web/core/utils/hooks";
import { _t } from "@web/core/l10n/translation";

export class EledialKpiWidget extends Component {
    static template = "eledia_project.KpiWidget";
    static props = {
        record: Object,
        readonly: { type: Boolean, optional: true },
    };
    static defaultProps = {
        readonly: false,
    };

    setup() {
        this.orm = useService("orm");
        this.notification = useService("notification");
        this.state = useState({
            loading: true,
            kpis: {},
        });

        onMounted(() => this.loadKpis());
    }

    async loadKpis() {
        try {
            const result = await this.orm.call(
                "eledia.project",
                "compute_kpis",
                [[this.props.record.resId]]
            );
            this.state.kpis = result;
            this.state.loading = false;
        } catch (error) {
            this.notification.add(_t("KPIs konnten nicht geladen werden."), {
                type: "danger",
            });
        }
    }

    onRefresh() {
        this.state.loading = true;
        this.loadKpis();
    }
}

registry.category("view_widgets").add("eledia_kpi", {
    component: EledialKpiWidget,
});
```

### Template-XML

```xml
<?xml version="1.0" encoding="UTF-8"?>
<templates xml:space="preserve">

    <t t-name="eledia_project.KpiWidget">
        <div class="o_eledia_kpi_widget">
            <div t-if="state.loading" class="o_eledia_kpi_loading">
                <i class="fa fa-spinner fa-spin"/>
                <span>Lade KPIs…</span>
            </div>
            <div t-else="" class="o_eledia_kpi_grid">
                <div t-foreach="Object.entries(state.kpis)" t-as="kpi" t-key="kpi[0]"
                     class="o_eledia_kpi_card">
                    <div class="o_eledia_kpi_label" t-esc="kpi[0]"/>
                    <div class="o_eledia_kpi_value" t-esc="kpi[1]"/>
                </div>
                <button class="btn btn-link" t-on-click="onRefresh">
                    <i class="fa fa-refresh"/>
                </button>
            </div>
        </div>
    </t>

</templates>
```

### OWL-Direktiven (häufige)

| Direktive | Wirkung |
|---|---|
| `t-if`, `t-elif`, `t-else` | Conditional |
| `t-foreach="list"` `t-as="item"` `t-key="…"` | Loop |
| `t-esc="expr"` | Text-Output (escaped) |
| `t-out="expr"` | HTML-Output (vorsichtig!) |
| `t-att-<attr>="expr"` | Dynamic Attribute |
| `t-attf-<attr>="prefix-{{expr}}"` | Format-String-Attribute |
| `t-on-<event>="handler"` | Event-Listener |
| `t-on-<event>.stop="handler"` | mit `event.stopPropagation()` |
| `t-on-<event>.prevent="handler"` | mit `event.preventDefault()` |
| `t-ref="name"` | Element-Reference (`this.elem.el`) |
| `t-call="template"` | Sub-Template einbinden |
| `t-set="x" t-value="expr"` | Variable im Template setzen |

### Service-Pattern

```javascript
this.orm = useService("orm");                    // ORM-Calls
this.action = useService("action");              // Actions ausführen
this.notification = useService("notification");  // Toasts
this.dialog = useService("dialog");              // Modal-Dialogs
this.user = useService("user");                  // Aktuelle User-Info
this.router = useService("router");              // URL-Routing

// Beispiele
await this.orm.search("res.partner", [["customer_rank", ">", 0]]);
await this.orm.searchRead("res.partner", [], ["name", "email"], { limit: 10 });
await this.orm.create("res.partner", [{ name: "Foo" }]);
await this.orm.write("res.partner", [partnerId], { name: "Bar" });
await this.orm.unlink("res.partner", [partnerId]);
await this.orm.call("res.partner", "custom_method", [[partnerId]], { kwarg: 1 });

this.action.doAction({ type: "ir.actions.act_window", res_model: "res.partner" });
this.notification.add("Hello", { type: "success" });
this.dialog.add(ConfirmationDialog, { body: "Sicher?", confirm: () => doIt() });
```

### Asset-Bundle

```python
# __manifest__.py
'assets': {
    'web.assets_backend': [
        'eledia_project/static/src/components/**/*.js',
        'eledia_project/static/src/components/**/*.xml',
        'eledia_project/static/src/components/**/*.scss',
    ],
    'web.qunit_suite_tests': [
        'eledia_project/static/tests/**/*',
    ],
},
```

Bundle-Namen:

| Bundle | Wofür |
|---|---|
| `web.assets_backend` | Backend (eingeloggte UI) |
| `web.assets_frontend` | Website-Frontend (öffentlich) |
| `web.assets_common` | Beides (selten direkt) |
| `web.assets_tests` | QUnit-Tests |
| `web.qunit_suite_tests` | Test-Suite |
| `mail.assets_messaging` | Messaging-System (Discuss) |
| `point_of_sale.assets` | POS-spezifisch |

### List/Form/Kanban-View patchen (nur wenn nötig)

Statt eine View komplett zu ersetzen, lieber eigene Widgets registrieren und in
XML referenzieren. Wenn unausweichlich:

```javascript
import { patch } from "@web/core/utils/patch";
import { ListController } from "@web/views/list/list_controller";

patch(ListController.prototype, {
    setup() {
        super.setup();
        // eigene Logik
    },
});
```

`patch()` ist die offizielle Mechanik in 17/18; davor `patch(target, "name", {…})`.

---

## 13. QWeb — Server-Side-Templating

QWeb ist das Server-Side-Pendant zu OWL — aus Python heraus, für Reports und
Portal-Templates.

### Reports

```xml
<!-- Report-Action -->
<record id="action_report_eledia_project" model="ir.actions.report">
    <field name="name">Projekt-Übersicht</field>
    <field name="model">eledia.project</field>
    <field name="report_type">qweb-pdf</field>          <!-- oder qweb-html -->
    <field name="report_name">eledia_project.report_project</field>
    <field name="report_file">eledia_project.report_project</field>
    <field name="binding_model_id" ref="model_eledia_project"/>
    <field name="binding_type">report</field>
    <field name="paperformat_id" ref="base.paperformat_euro"/>
</record>

<!-- Template -->
<template id="report_project">
    <t t-call="web.html_container">
        <t t-foreach="docs" t-as="doc">
            <t t-call="web.external_layout">
                <div class="page">
                    <h2>Projekt: <span t-field="doc.name"/></h2>
                    <table class="table table-sm">
                        <thead>
                            <tr>
                                <th>Zeile</th>
                                <th class="text-end">Betrag</th>
                            </tr>
                        </thead>
                        <tbody>
                            <tr t-foreach="doc.line_ids" t-as="line">
                                <td t-field="line.name"/>
                                <td class="text-end">
                                    <span t-field="line.amount"
                                          t-options='{"widget": "monetary", "display_currency": doc.currency_id}'/>
                                </td>
                            </tr>
                        </tbody>
                        <tfoot>
                            <tr>
                                <th>Gesamt</th>
                                <th class="text-end">
                                    <span t-field="doc.total_amount"
                                          t-options='{"widget": "monetary", "display_currency": doc.currency_id}'/>
                                </th>
                            </tr>
                        </tfoot>
                    </table>
                </div>
            </t>
        </t>
    </t>
</template>
```

QWeb verwendet **wkhtmltopdf** (für PDF) oder rendert direkt HTML.

### t-Direktiven (Server-QWeb)

| Direktive | Wirkung |
|---|---|
| `t-esc="expr"` | escaped Output (deprecated in OWL — dort `t-out`) |
| `t-out="expr"` | rohe HTML-Ausgabe |
| `t-field="record.field"` | mit Field-Widget rendern (Currency, Date, …) |
| `t-options='{"widget":"monetary","display_currency":doc.currency_id}'` | Field-Optionen |
| `t-if`, `t-elif`, `t-else` | Conditional |
| `t-foreach="seq"` `t-as="item"` | Loop (`item_index`, `item_first`, `item_last` verfügbar) |
| `t-set="var" t-value="expr"` | Variable |
| `t-call="template"` | Sub-Template |
| `t-att-<attr>="expr"` | Dynamic Attribute |
| `t-attf-<attr>="…{{expr}}…"` | Format-String |

### Custom-Report-Daten

Wenn die Default-`docs`-Variable nicht reicht:

```python
from odoo import api, models


class ReportEledialProject(models.AbstractModel):
    _name = 'report.eledia_project.report_project'
    _description = 'Project Report'

    @api.model
    def _get_report_values(self, docids, data=None):
        docs = self.env['eledia.project'].browse(docids)
        return {
            'doc_ids': docids,
            'doc_model': 'eledia.project',
            'docs': docs,
            'company': self.env.company,
            'extra_kpis': self._compute_extra_kpis(docs),
        }

    def _compute_extra_kpis(self, projects):
        return {p.id: {'velocity': p.line_count / 7} for p in projects}
```

### Paper-Formate

```xml
<record id="paperformat_eledia_compact" model="report.paperformat">
    <field name="name">eLeDia Compact</field>
    <field name="format">A4</field>
    <field name="orientation">Portrait</field>
    <field name="margin_top">12</field>
    <field name="margin_bottom">15</field>
    <field name="margin_left">8</field>
    <field name="margin_right">8</field>
    <field name="header_line">False</field>
    <field name="header_spacing">10</field>
    <field name="dpi">90</field>
</record>
```

---

## 14. Portal-Templates (Frontend)

```xml
<template id="portal_my_projects" name="Meine Projekte">
    <t t-call="portal.portal_layout">
        <t t-set="breadcrumbs_searchbar" t-value="True"/>

        <t t-call="portal.portal_searchbar">
            <t t-set="title">Meine Projekte</t>
        </t>

        <t t-if="not projects">
            <p>Keine Projekte vorhanden.</p>
        </t>
        <t t-else="">
            <t t-call="portal.portal_table">
                <thead>
                    <tr><th>Projekt</th><th>Status</th></tr>
                </thead>
                <tbody>
                    <tr t-foreach="projects" t-as="project">
                        <td>
                            <a t-attf-href="/my/projects/#{project.id}">
                                <t t-esc="project.name"/>
                            </a>
                        </td>
                        <td><t t-esc="dict(project._fields['state'].selection).get(project.state)"/></td>
                    </tr>
                </tbody>
            </t>
        </t>
    </t>
</template>
```

### Portal-Controller

```python
from odoo import http
from odoo.http import request
from odoo.addons.portal.controllers.portal import CustomerPortal


class EledialPortal(CustomerPortal):

    @http.route(['/my/projects'], type='http', auth='user', website=True)
    def portal_my_projects(self, **kw):
        projects = request.env['eledia.project'].search([
            ('user_id', '=', request.env.uid),
        ])
        return request.render("eledia_project.portal_my_projects", {
            'projects': projects,
            'page_name': 'projects',
        })
```

---

## 15. Anti-Patterns

1. **`<tree>` in neuem Code** — Odoo 18: nutze `<list>`.
2. **`attrs="{…}"`** — deprecated. Direkt `invisible="…"` etc.
3. **JS-Logik in Mustache (`web.assets_qweb`)** — gibt's nicht mehr; OWL-Templates
   in `static/src/`.
4. **`document.querySelector`** in OWL-Components — nutze `t-ref`.
5. **`alert()` / `confirm()`** — nutze `notification` / `dialog` Service.
6. **Inline-`<script>`** in QWeb-Reports — wkhtmltopdf rendert kein JS zuverlässig.
7. **`<group>` ohne `<group>`-Wrapper** — Layout bricht in mobile View.
8. **Form-Buttons ohne `class="btn-primary"`** — schwer erkennbar.
9. **`t-esc` für vorgerechnete HTML** — XSS-Risiko, nutze `t-out` bewusst.
10. **`<chatter/>` doppelt** in vererbter Form — Original abklemmen oder weglassen.

---

## 16. Quellen

- User Interface Reference: https://www.odoo.com/documentation/18.0/developer/reference/user_interface.html
- Views: https://www.odoo.com/documentation/18.0/developer/reference/user_interface/view_records.html
- QWeb: https://www.odoo.com/documentation/18.0/developer/reference/frontend/qweb.html
- OWL: https://github.com/odoo/owl/blob/master/doc/readme.md
- Reports: https://www.odoo.com/documentation/18.0/developer/howtos/reports.html
- Asset-Bundles: https://www.odoo.com/documentation/18.0/developer/reference/frontend/assets.html
