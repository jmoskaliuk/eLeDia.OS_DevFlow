---
name: odoo-performance
description: >
  Performance-Tuning für Odoo 18 — Computed/Stored Fields, @api.depends,
  Datenbank-Indizes, read_group, Search-Optimierung, Prefetching, Caching,
  Batch-Operationen, Cron-Jobs, Memory-Management, Profiling. Verwende diesen
  Skill bei langsamen Views, hohem RAM-Verbrauch, langen Search-Queries,
  N+1-Problemen, Cache-Invalidierungen, Cron-Jobs die Worker blockieren,
  Reports die nicht rendern, oder bei der Auswahl zwischen Stored vs.
  Non-Stored. Trigger bei "Performance", "langsam", "slow", "N+1", "Index",
  "read_group", "prefetch", "Cache", "ormcache", "Batch", "Cron", "blocking",
  "OOM", "Memory", "Profiling", "EXPLAIN ANALYZE", "DB-Query".
  Pair mit odoo-dev (ORM-Fundament), odoo-deploy (Worker-Tuning, PostgreSQL-Config).
---

# Odoo 18 — Performance & Tuning

Pragmatische Performance-Optimierung für Odoo-18-Module: Wo wird's langsam und
warum, wie misst man, wie behebt man.

**Quelle:** https://www.odoo.com/documentation/18.0/developer/howtos/performance.html

---

## 1. Diagnose-First — Bevor du was änderst

### Profiler aktivieren (Dev-Mode)

In den URL-Params `?debug=assets,tests` oder in den Settings → Developer Tools.
Dann: rechte obere Ecke → 🐞 → "Become Superuser" → "Enable Profiling".

Speichert ein **Speedscope-JSON** zu jedem Request, das man im Browser
visualisieren kann.

### `odoo-bin --log-level=debug_sql`

Schreibt jeden SQL-Statement ins Log. Hart aber effektiv.

```bash
odoo-bin -c odoo.conf -d eledia --log-level=debug_sql 2>&1 | grep -E '^\s*[0-9]+ms'
```

### `EXPLAIN ANALYZE` auf eigene Queries

```python
self.env.cr.execute("EXPLAIN ANALYZE SELECT * FROM eledia_project WHERE name ILIKE %s", ['%foo%'])
print(self.env.cr.fetchall())
```

### `pgbadger` für Production

```bash
pgbadger -j 4 /var/log/postgresql/postgresql-14-main.log -o report.html
```

### Built-in Decorator: `@profile`

```python
from odoo.tools.profiler import profile


class EledialProject(models.Model):
    _inherit = 'eledia.project'

    @profile(stream='sql')
    def heavy_method(self):
        for record in self:
            ...
```

---

## 2. Compute-Felder

### Stored vs. Non-Stored

| Stored | Non-Stored |
|---|---|
| `store=True` | Default `store=False` |
| Wert in DB-Spalte | Wert nur im RAM |
| Sortierbar, durchsuchbar | nur via `_search_<field>` durchsuchbar |
| Recompute getriggert via `@api.depends` | Recompute bei jedem Read |
| Trigger müssen sauber sein, sonst stale | immer „live" |
| DB-Schreiblast | CPU bei jedem Read |

**Faustregel:**

- Wert ändert sich selten oder ist teuer zu berechnen → `store=True`.
- Wert hängt von User-Context (z.B. TZ, Sprache) → `store=False`, oder
  `store=True` plus `@api.depends_context('uid')`.
- Wert wird in Listen/Kanban angezeigt → `store=True` (sonst N×Compute).
- Wert wird gefiltert oder sortiert → **muss** `store=True`.

### `@api.depends` korrekt setzen

```python
total_amount = fields.Monetary(
    string='Gesamt',
    compute='_compute_total_amount',
    store=True,
    currency_field='currency_id',
)

@api.depends('line_ids.amount', 'line_ids.tax_rate')
def _compute_total_amount(self):
    for record in self:
        record.total_amount = sum(
            line.amount * (1 + line.tax_rate / 100)
            for line in record.line_ids
        )
```

**Falsch:**

```python
@api.depends('line_ids')                  # nur Trigger bei Zeilen-Add/Remove
@api.depends('amount')                    # 'amount' ist nicht IM Modell
@api.depends()                            # nie ausgelöst → wird stale
```

**Spezial: `@api.depends_context`**

Wert hängt vom Context ab (User, Currency, Lang):

```python
@api.depends_context('company')
@api.depends('amount')
def _compute_amount_company_currency(self):
    for record in self:
        record.amount_company = record.amount * record.env.company.exchange_rate
```

### Compute-Reihenfolge bei Inheritance

Beim Override eines Compute via `_inherit` mit zusätzlichen Dependencies:

```python
class EledialProject(models.Model):
    _inherit = 'eledia.project'

    bonus_amount = fields.Monetary()

    @api.depends('bonus_amount')         # zusätzlich zu Parent-Depends
    def _compute_total_amount(self):
        super()._compute_total_amount()
        for record in self:
            record.total_amount += record.bonus_amount
```

`@api.depends` werden **gemerged**. Aber: `super()` muss aufgerufen werden,
sonst wird die Parent-Logik übersprungen.

### `precompute=True` (Odoo 17+)

```python
total_amount = fields.Monetary(compute='…', store=True, precompute=True)
```

Berechnung erfolgt **vor** dem `INSERT`, nicht in einem zweiten Pass — spart
einen `UPDATE` pro `create()`. Sinnvoll für **immutable** Computes (Wert hängt nur
von Werten ab, die schon im `vals` sind).

---

## 3. Indizes

### Auto-Indizes

Odoo legt automatisch Indizes an für:

- Primary Keys (`id`)
- Foreign Keys (`*_id`-Felder)
- Felder mit `index=True`
- Volltext-Indizes für `Char`/`Text` mit `index='trigram'` (Odoo 16+)

### Wann manuell `index=True` setzen

```python
class EledialProjectLine(models.Model):
    _name = 'eledia.project.line'

    project_id = fields.Many2one('eledia.project', index=True, required=True)
    state = fields.Selection([…], index=True)            # häufig gefiltert
    product_code = fields.Char(index='trigram')          # Volltext-Suche
    create_date = fields.Datetime(index=True)             # bei Reports nach Datum
```

**Faustregel:** Felder, die in `domain=`-Filtern stehen und > 10k Records pro
Wert aufweisen, brauchen einen Index.

### Composite-Indizes (manuell)

```python
class EledialProjectLine(models.Model):
    _name = 'eledia.project.line'

    def init(self):
        self.env.cr.execute("""
            CREATE INDEX IF NOT EXISTS eledia_project_line_project_state_idx
            ON eledia_project_line (project_id, state)
            WHERE state IN ('active', 'done')
        """)
```

`init()` läuft nach jedem `-u`. Partielle Indizes (`WHERE …`) sind oft 10× kleiner
und schneller.

---

## 4. Search-Patterns

### `search_count` ist NICHT immer schneller als `search`

`search_count` macht ein `COUNT(*)` mit allen Joins der Domain — kann teurer sein
als ein `search` mit `limit=1` für Existenz-Checks.

```python
# SCHLECHT bei großen Tabellen
if self.env['sale.order'].search_count([('state', '=', 'sale')]):
    ...

# BESSER für Existenz
if self.env['sale.order'].search([('state', '=', 'sale')], limit=1):
    ...
```

### `read_group` statt `search` + Aggregation

```python
# SCHLECHT — N+1
totals_per_user = {}
for user in self.env['res.users'].search([]):
    totals_per_user[user.id] = sum(
        self.env['eledia.project'].search([('user_id', '=', user.id)]).mapped('total_amount')
    )

# RICHTIG — eine Query
result = self.env['eledia.project'].read_group(
    domain=[],
    fields=['user_id', 'total_amount:sum'],
    groupby=['user_id'],
)
totals_per_user = {r['user_id'][0]: r['total_amount'] for r in result}
```

### `read_group` Aggregations-Funktionen

| Spec | Wirkung |
|---|---|
| `'total_amount:sum'` | SUM |
| `'total_amount:avg'` | AVG |
| `'total_amount:min'` | MIN |
| `'total_amount:max'` | MAX |
| `'state:count_distinct'` | COUNT DISTINCT |
| `'create_date:day'` | gruppiere pro Tag |
| `'create_date:week'`, `:month`, `:quarter`, `:year` | Zeit-Bucket |

### `domain` schlägt `filtered`

```python
# SCHLECHT — alle Records laden, dann in Python filtern
all_orders = env['sale.order'].search([])
ge_de = all_orders.filtered(lambda o: o.partner_id.country_id.code == 'DE')

# RICHTIG — Filter in DB
ge_de = env['sale.order'].search([('partner_id.country_id.code', '=', 'DE')])
```

### Domain-Optimierung

```python
# Domain so schnell wie möglich verkleinern
[
    ('state', '=', 'posted'),       # selektiv → früh
    ('amount_total', '>', 100),
    ('partner_id.country_id.code', '=', 'DE'),  # Join → spät
]
```

PostgreSQL macht das oft selbst, aber bei großen Tabellen hilft die Reihenfolge.

### `any` / `not any` (Odoo 17+)

```python
# Alt: implicit Subquery via dotted path
[('order_line_ids.product_id.type', '=', 'service')]

# Neu: explizit, klarere Semantik
[('order_line_ids', 'any', [('product_id.type', '=', 'service')])]
```

`any` ist semantisch sauberer (entspricht `EXISTS`), bei tiefen Pfaden meist
schneller.

---

## 5. Prefetching

Odoo lädt automatisch verwandte Records in Batches — aber nur, wenn man **dieselbe
Recordset-Variable** wiederverwendet:

```python
# GUT — Odoo prefetcht alle partner_ids in einem Query
orders = env['sale.order'].search([])
for order in orders:
    print(order.partner_id.name)        # ein Query für alle Partner

# SCHLECHT — Prefetch zerstört
order_ids = env['sale.order'].search([]).ids
for oid in order_ids:
    order = env['sale.order'].browse(oid)
    print(order.partner_id.name)        # ein Query PRO Order
```

### `prefetch_fields=False` ausschalten (selten)

```python
records = self.with_context(prefetch_fields=False).search([])
```

Sinnvoll, wenn man wirklich nur ein Feld braucht und gegen Cache-Pollution
schützen will. Default-Verhalten ist meistens OK.

### `read()` statt `mapped()` bei vielen Feldern

```python
# Lädt ALLE Felder
all_data = orders.mapped(lambda o: (o.name, o.partner_id.name, o.amount_total))

# Lädt nur die genannten Felder
all_data = orders.read(['name', 'partner_id', 'amount_total'])
```

`read` ist explizit über benötigte Felder; `mapped` lädt im Zweifel mehr.

---

## 6. Caching

### LRU-Cache via `ormcache`

```python
from odoo.tools.cache import ormcache, ormcache_context


class EledialConfig(models.Model):
    _inherit = 'res.config.settings'

    @ormcache('company_id')
    def _get_default_currency(self, company_id):
        return self.env['res.company'].browse(company_id).currency_id.id

    @ormcache_context('uid', keys=('lang',))
    def _get_user_label(self):
        # Cached pro User pro Sprache
        return f"{self.env.user.name} ({self.env.context.get('lang', 'en_US')})"
```

`ormcache` ist Process-lokal (pro Worker). Bei Cluster: Ergebnisse ggf.
unterschiedlich.

### Invalidation

`ormcache` wird automatisch invalidiert, wenn:

- Modell `_register_hook()` triggert.
- Datenbank-Trigger via `_unregister_hook` läuft.
- `clear_caches()` aufgerufen wird.

```python
class ResPartner(models.Model):
    _inherit = 'res.partner'

    def write(self, vals):
        result = super().write(vals)
        if 'category_id' in vals:
            self.env['eledia.config'].clear_caches()       # cross-model invalidation
        return result
```

### Field-Cache

Ein Recordset hat einen internen Cache pro Feld. Geleert via:

```python
records.invalidate_recordset(['total_amount'])           # nur ein Feld
records.invalidate_recordset()                           # alle Felder
self.env.invalidate_all()                                # globaler Reset
```

Wann nötig: nach Roh-SQL-Updates, die ORM-Cache nicht mitbekommt.

---

## 7. Batch-Operationen

### Schreiben

```python
# GUT — eine Transaktion, ein Statement
records.write({'state': 'done'})

# SCHLECHT — N Statements
for r in records:
    r.state = 'done'
```

### Erzeugen

```python
# GUT — eine Query
self.env['eledia.project.line'].create([
    {'project_id': pid, 'name': f'Line {i}', 'amount': i * 10}
    for i in range(100)
])

# SCHLECHT — 100 Queries
for i in range(100):
    self.env['eledia.project.line'].create({
        'project_id': pid, 'name': f'Line {i}', 'amount': i * 10,
    })
```

### Mass-Update via `cr.execute` (selten, aber legal)

```python
def cron_archive_old_projects(self):
    """Archive >2J alte Projekte. Klassisches Mass-Update."""
    self.env.cr.execute("""
        UPDATE eledia_project
           SET active = False
         WHERE state = 'done'
           AND write_date < (NOW() - INTERVAL '2 years')
    """)
    # ORM-Cache invalidieren!
    self.env['eledia.project'].invalidate_model(['active'])
```

**Begründung im Kommentar pflicht.** Cache-Invalidierung **nicht vergessen**.

### Cursor-Commit in langen Cron-Jobs

```python
@api.model
def cron_recompute_kpis_in_batches(self):
    batch_size = 500
    offset = 0
    while True:
        projects = self.search([('kpi_dirty', '=', True)], offset=offset, limit=batch_size)
        if not projects:
            break
        projects._compute_kpi()
        projects.write({'kpi_dirty': False})
        self.env.cr.commit()                # Wichtig bei großen Jobs
        offset += batch_size
        # Reset des Caches, sonst RAM-Wachstum
        self.env.invalidate_all()
        gc.collect()
```

`cr.commit()` ist OK in Cron-Jobs, **niemals** in normalen User-Requests.

---

## 8. Cron-Jobs richtig konfigurieren

```xml
<record id="cron_eledia_kpi_recompute" model="ir.cron">
    <field name="name">eLeDia: Daily KPI Recompute</field>
    <field name="model_id" ref="model_eledia_project"/>
    <field name="state">code</field>
    <field name="code">model.cron_recompute_kpis()</field>
    <field name="interval_number">1</field>
    <field name="interval_type">days</field>
    <field name="numbercall">-1</field>
    <field name="active" eval="True"/>
    <field name="priority">5</field>
</record>
```

**Tipps:**

- `priority` (1-10): niedriger = wichtiger. Default 10.
- Mehrere Workers via `--max-cron-threads=2` (default 1).
- Cron-User ist der **Eigentümer** des Cron-Records (`user_id`); standardmäßig
  Admin. Für Multi-Company → bewusst setzen.
- Cron läuft **nicht** im Test-Modus (außer man triggert manuell).

### Lange Crons in Worker-Pools verlagern

```python
def cron_heavy_recompute(self):
    """Triggert Verarbeitung in separaten Worker via queue_job."""
    self.with_delay()._do_heavy_recompute()
```

Bei Last: OCA-Modul `queue_job`
(https://github.com/OCA/queue/tree/18.0/queue_job) — Redis-basierte
Background-Queue.

---

## 9. Memory-Management

### Symptom: Worker wächst auf > 2 GB

Ursachen:

1. Ein Recordset wird durch eine lange Operation gehalten und wächst kontinuierlich
   (Cache-Effekt).
2. Nicht-paginierter Search lädt 100k Records in den RAM.
3. `mapped` über tiefe Hierarchien lädt N×M Felder.

### `--limit-memory-soft` / `--limit-memory-hard`

```ini
# odoo.conf
limit_memory_soft = 1610612736           # 1.5 GB → Worker neugestartet
limit_memory_hard = 2147483648           # 2 GB → Hard kill
limit_request = 8192                     # max requests bevor Worker recycled
```

### `gc.collect()` nach Mega-Jobs

```python
import gc

def cron_huge_export(self):
    for batch in self._iter_batches():
        self._export_batch(batch)
        self.env.cr.commit()
        self.env.invalidate_all()
        gc.collect()
```

---

## 10. Tabellen mit > 1 Mio Records

Strategien:

1. **Partitionierung** (PostgreSQL native, Odoo-blind):

   ```sql
   CREATE TABLE eledia_event (
       id bigserial PRIMARY KEY,
       create_date timestamp NOT NULL,
       …
   ) PARTITION BY RANGE (create_date);

   CREATE TABLE eledia_event_2026 PARTITION OF eledia_event
   FOR VALUES FROM ('2026-01-01') TO ('2027-01-01');
   ```

2. **Archiv-Modell** für historische Daten:

   ```python
   class EledialEventArchive(models.Model):
       _name = 'eledia.event.archive'
       _description = 'Archived Events'
       # gleiche Felder wie eledia.event

   def cron_archive_events(self):
       cutoff = fields.Date.today() - timedelta(days=365)
       old = self.env['eledia.event'].search([('create_date', '<', cutoff)])
       self.env['eledia.event.archive'].create([{
           'name': e.name, 'create_date': e.create_date,
       } for e in old])
       old.unlink()
   ```

3. **`_log_access = False`** für Mass-Tabellen ohne Audit-Bedarf:

   ```python
   class EledialEventLog(models.Model):
       _name = 'eledia.event.log'
       _log_access = False               # spart create_uid, write_uid, *_date
   ```

   → 4 Spalten weniger pro Row, weniger Index-Overhead.

---

## 11. Frontend-Performance

### Kanban: nicht zu viele Felder

```xml
<!-- SCHLECHT — lädt für jede Karte 20 Felder -->
<kanban>
    <field name="..."/>
    ...
</kanban>

<!-- BESSER — nur das, was die Karte zeigt -->
```

Jeder `<field>` im Kanban-Header wird **vorab geladen**. Mehr Felder = größere
JSON-Payload.

### Listen mit > 80 Zeilen

Page-Size in `<list>`: `limit="80"` (Default). Bei größeren Sichten Paginieren
einplanen — Odoo macht das automatisch, aber: Server muss `search_count` machen
und kann teuer werden.

### Asset-Bundle Size

```bash
ls -lh /path/to/odoo/web/.assets/web.assets_backend.<hash>.js
```

Backend-Bundles können > 5 MB unkomprimiert werden. Eigene Module nicht
übermäßig fett machen — kein `import lodash` o.ä.

---

## 12. Anti-Patterns — Performance-Killer

1. **`for r in env['model'].search([])`** ohne Pagination → OOM bei großen Tabellen.
2. **Compute ohne `@api.depends`** → Recompute bei jedem Read.
3. **`store=False` auf Feld in List-View** → Recompute pro Zeile.
4. **`mapped('rel.field')` in einer Schleife** → keine Prefetch-Optimierung.
5. **`unlink()` mit Cascade auf riesigen Sub-Tables** → langsam, blockierend.
6. **Cron mit `numbercall=1`** der vergessen wird zu reset → Job läuft nie wieder.
7. **`Image`-Feld mit Megapixel-Originalen** ohne `attachment=True` → DB-Bloat.
8. **`Many2many` mit `domain="[…]"`** über geo-tief Tables → langsame Such-Queries.
9. **Roh-SQL ohne `invalidate_*`** → Stale-Daten in der UI.
10. **Background-Job im HTTP-Request** → Worker blockiert, andere Requests timeouten.

---

## 13. Server-Konfiguration (Quick-Ref)

```ini
; odoo.conf
workers = 4                              ; HTTP-Workers
max_cron_threads = 2                     ; parallele Cron-Workers
db_maxconn = 64                          ; PostgreSQL-Connections pro Process
limit_request = 8192                     ; Requests bevor Worker recycled
limit_memory_soft = 2147483648           ; 2 GB Soft
limit_memory_hard = 2684354560           ; 2.5 GB Hard
limit_time_cpu = 600                     ; 10 min CPU-Limit
limit_time_real = 1200                   ; 20 min Real-Limit
limit_time_real_cron = 1800              ; 30 min für Crons

; PostgreSQL
db_template = template0
list_db = False                          ; Production: hide DB-list
proxy_mode = True                        ; hinter Reverse-Proxy
```

> Vollständig in `odoo-deploy.md`.

---

## 14. Quellen

- Performance Howto: https://www.odoo.com/documentation/18.0/developer/howtos/performance.html
- ORM Reference: https://www.odoo.com/documentation/18.0/developer/reference/backend/orm.html
- PostgreSQL Tuning: https://wiki.postgresql.org/wiki/Tuning_Your_PostgreSQL_Server
- OCA `queue_job`: https://github.com/OCA/queue/tree/18.0/queue_job
- pgbadger: https://pgbadger.darold.net/
- Speedscope: https://www.speedscope.app/
