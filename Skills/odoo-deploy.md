---
name: odoo-deploy
description: >
  Deployment & Infrastruktur für Odoo 18 — odoo.sh (PaaS), Docker, On-Premise,
  Multi-DB-Setup, Worker-Tuning, PostgreSQL-Konfiguration, TLS/Reverse-Proxy
  (nginx/Caddy), Modul-Update-Pipeline, Migrations-Skripte, Backup/Restore,
  Logging, Monitoring (Prometheus/Grafana), Secrets-Management, CI/CD.
  Verwende diesen Skill für jede Frage zu Deployment, Server-Setup, Update-
  Strategien, DB-Migration zwischen Versionen, Staging-Workflows, Hotfixes,
  Rolling-Updates, Backup-Strategien, Disaster-Recovery. Trigger bei "deploy",
  "deployment", "odoo.sh", "Docker Odoo", "Dockerfile Odoo", "odoo.conf",
  "Workers", "PostgreSQL", "nginx odoo", "Caddy odoo", "Reverse-Proxy",
  "Backup", "Restore", "filestore", "pg_dump", "Migration 17 18", "OpenUpgrade",
  "Staging", "Hotfix", "rolling deploy", "Monitoring".
  Pair mit odoo-performance (Worker-Sizing) und odoo-security (TLS, Secrets).
---

# Odoo 18 — Deployment & Infrastruktur

Drei Wege Odoo zu betreiben: **odoo.sh** (Odoo SAS PaaS), **Docker**
(Container, eigener Server) oder **bare-metal** (apt-Pakete, einzelner Server).
Dieser Skill deckt alle drei mit Schwerpunkt Docker + odoo.sh ab.

**Quelle:**
- https://www.odoo.com/documentation/18.0/administration/on_premise.html
- https://www.odoo.com/documentation/18.0/administration/odoo_sh.html

---

## 1. Welche Variante wann?

| Variante | Wann | Wartung |
|---|---|---|
| **odoo.sh** | Standard für Enterprise-Kunden, schnelles Setup, Multi-Stage out-of-box | Odoo SAS macht alles |
| **Docker** | Self-hosted, eigene Compliance-Anforderungen, Multi-Tenant | du selbst |
| **Bare-Metal** | Single-Tenant, maximale Performance, dedicated Server | du selbst |

**Faustregel:**
- < 50 User, einfache Anforderungen → **odoo.sh**.
- Datenschutzgrund: alles on-prem → **Docker** (oder bare-metal, aber Docker
  ist 99 % der Fälle passend).
- 1000+ User, eigene Infra-Plattform → **Bare-Metal mit eigenem Tooling**.

---

## 2. odoo.sh — PaaS

### Setup

1. **Account anlegen** auf https://www.odoo.sh/.
2. **GitHub-Repo connecten**: odoo.sh deploys jeden Commit automatisch.
3. **Branches** = Stages:
   - `production` — Production-DB
   - `staging` — Staging-DB (klont täglich Prod)
   - `dev/*` — Dev-Branches mit Demo-Daten

### Repo-Layout

```
my-odoo-project/
├── .gitignore
├── README.md
├── requirements.txt              # Python-Deps (z.B. requests, stripe, qrcode)
├── modul_a/
│   └── …
├── modul_b/
│   └── …
└── private_extras/               # nicht im Apps-Store: eigene Module
    └── …
```

odoo.sh **klont auch Submodule** — typisches Pattern für OCA:

```ini
# .gitmodules
[submodule "OCA-server-tools"]
    path = OCA-server-tools
    url = https://github.com/OCA/server-tools.git
    branch = 18.0
```

### `requirements.txt` für odoo.sh

```txt
# Pin auf Major-Versionen
qrcode==7.4.2
stripe==10.13.0
pdfkit==1.0.0
python-magic==0.4.27
```

odoo.sh installiert automatisch via `pip install -r requirements.txt`.

### Branch-spezifische Configs

odoo.sh hat im Settings-Panel pro Branch:

- **Workers** (HTTP + Cron)
- **CPU**/**RAM**-Tier
- **Custom Subdomain** (`my-prod.odoo.com`)
- **Outgoing Email** (SMTP-Server)
- **Database / Filestore Backups** (Snapshot)

### Deploy-Flow

```
git push origin dev/feature-xy   →  odoo.sh build (5–10 min, mit Tests)
                                     ↓
                                  Test-DB (klont Prod)
                                     ↓
                                  Live-Preview-URL
                                     ↓
git merge dev/feature-xy → staging  →  Staging-Build (mit Prod-Daten-Klon)
                                     ↓
git merge staging → production       →  Production-Build (Hot-Update via -u)
```

### Migrations-Skripte (siehe Sektion 7)

odoo.sh führt automatisch `migrations/<version>/post-migration.py` aus, wenn die
Modul-Version sich erhöht.

### odoo.sh-Limits

- Max RAM pro Worker: je nach Plan (4–32 GB).
- `wkhtmltopdf` ist **gepinnt** auf eine Version pro Odoo-Major; eigene Versionen
  geht nicht.
- Custom System-Pakete (apt) gehen **nicht**. Reine Python-Deps via `requirements.txt`.
- SSH-Zugang nur in höheren Plänen. Web-Shell immer.

---

## 3. Docker (selbst gehostet)

### Minimal-Setup mit `docker-compose`

```yaml
# docker-compose.yml
services:
  postgres:
    image: postgres:14-alpine
    environment:
      POSTGRES_USER: odoo
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRES_DB: postgres
    volumes:
      - pg_data:/var/lib/postgresql/data
    healthcheck:
      test: ['CMD-SHELL', 'pg_isready -U odoo']
      interval: 10s
      timeout: 5s
      retries: 5
    restart: unless-stopped

  odoo:
    image: odoo:18.0
    depends_on:
      postgres:
        condition: service_healthy
    ports:
      - "127.0.0.1:8069:8069"
      - "127.0.0.1:8072:8072"     # longpolling
    environment:
      HOST: postgres
      USER: odoo
      PASSWORD: ${POSTGRES_PASSWORD}
    volumes:
      - odoo_data:/var/lib/odoo
      - ./addons:/mnt/extra-addons:ro
      - ./enterprise:/mnt/enterprise:ro
      - ./config/odoo.conf:/etc/odoo/odoo.conf:ro
    restart: unless-stopped

volumes:
  pg_data:
  odoo_data:
```

`docker compose up -d`. Reverse-Proxy (nginx/Caddy) terminiert TLS und routet
auf `:8069` und `:8072`.

### Custom-Image für eigene Module + Python-Deps

```dockerfile
# Dockerfile
FROM odoo:18.0

USER root

# OS-Pakete (z.B. wkhtmltopdf-Patch oder zusätzliche Sprach-Pakete)
RUN apt-get update && apt-get install -y --no-install-recommends \
        fonts-noto-cjk \
        fonts-liberation \
    && rm -rf /var/lib/apt/lists/*

# Python-Deps
COPY requirements.txt /tmp/requirements.txt
RUN pip3 install --no-cache-dir -r /tmp/requirements.txt

# Eigene Module
COPY ./addons /mnt/extra-addons
COPY ./enterprise /mnt/enterprise

# Config
COPY ./config/odoo.conf /etc/odoo/odoo.conf

USER odoo
```

```bash
docker build -t eledia/odoo:18.0-1.0.0 .
```

### `odoo.conf` (Production)

```ini
[options]
; --- DB ---
db_host = postgres
db_port = 5432
db_user = odoo
db_password = ${POSTGRES_PASSWORD}
db_maxconn = 64
db_template = template0
list_db = False                          ; production: hide

; --- Addons ---
addons_path = /mnt/enterprise,/mnt/extra-addons,/usr/lib/python3/dist-packages/odoo/addons
data_dir = /var/lib/odoo

; --- Workers ---
workers = 4
max_cron_threads = 2
proxy_mode = True

; --- Limits ---
limit_request = 8192
limit_memory_soft = 1610612736           ; 1.5 GB
limit_memory_hard = 2147483648           ; 2 GB
limit_time_cpu = 600
limit_time_real = 1200
limit_time_real_cron = 1800

; --- Misc ---
admin_passwd = ${ADMIN_PASSWORD}
csv_internal_sep = ,
log_level = info
log_handler = :INFO
logfile = /var/log/odoo/odoo.log
without_demo = all                       ; nie Demo in Prod
```

### Worker-Sizing-Faustregel

`workers = (CPU-Cores * 2) + 1` für Web-Workers.
`max_cron_threads = CPU-Cores / 2`.

Beispiel 4 vCPU: `workers=9, max_cron_threads=2` → Spitzen bis 11 parallele
Python-Prozesse, jeder bis 2 GB RAM. → 24 GB RAM-Empfehlung.

> Performance-Tuning siehe `odoo-performance.md`.

---

## 4. Reverse-Proxy

### nginx

```nginx
upstream odoo {
    server 127.0.0.1:8069;
}
upstream odoo_longpolling {
    server 127.0.0.1:8072;
}

server {
    listen 443 ssl http2;
    server_name odoo.example.com;

    ssl_certificate /etc/letsencrypt/live/odoo.example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/odoo.example.com/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;

    proxy_read_timeout 720s;
    proxy_connect_timeout 720s;
    proxy_send_timeout 720s;

    proxy_set_header X-Forwarded-Host $host;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_set_header X-Real-IP $remote_addr;

    # Longpolling (Live-Updates, Discuss)
    location /longpolling {
        proxy_pass http://odoo_longpolling;
    }
    # /websocket (Odoo 16+)
    location /websocket {
        proxy_pass http://odoo_longpolling;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "Upgrade";
    }

    location / {
        proxy_redirect off;
        proxy_pass http://odoo;
    }

    # Static-Cache
    location ~* /web/static/ {
        proxy_cache_valid 200 60m;
        proxy_buffering on;
        expires 864000;
        proxy_pass http://odoo;
    }

    gzip_types text/css text/scss text/plain text/xml application/xml application/json application/javascript;
    gzip on;
    client_max_body_size 100m;
}

# HTTP→HTTPS Redirect
server {
    listen 80;
    server_name odoo.example.com;
    return 301 https://$host$request_uri;
}
```

### Caddy (einfacher)

```caddy
odoo.example.com {
    reverse_proxy /longpolling/* 127.0.0.1:8072
    reverse_proxy /websocket 127.0.0.1:8072
    reverse_proxy 127.0.0.1:8069 {
        header_up X-Forwarded-Proto https
        header_up X-Forwarded-Host {host}
    }
    encode gzip
}
```

`proxy_mode = True` in `odoo.conf` ist Pflicht, damit Odoo die `X-Forwarded-*`-
Header respektiert.

---

## 5. PostgreSQL-Tuning

### Mindest-Empfehlungen für 50 User

```ini
# postgresql.conf
shared_buffers = 4GB                     ; 25 % des RAM
effective_cache_size = 12GB              ; 75 %
work_mem = 32MB                          ; per Query
maintenance_work_mem = 1GB
max_connections = 200
max_wal_size = 4GB
checkpoint_completion_target = 0.9
random_page_cost = 1.1                   ; SSD
effective_io_concurrency = 200           ; SSD
```

### Critical: Connection-Pooling

Bei `workers=8` und `db_maxconn=64` → max **512** Connections.
PostgreSQL-Default ist 100. → entweder `max_connections` raufdrehen ODER
**PgBouncer** dazwischen.

```bash
apt install pgbouncer
# /etc/pgbouncer/pgbouncer.ini
pool_mode = transaction
max_client_conn = 1000
default_pool_size = 100
```

`pool_mode = transaction` ist für Odoo OK, **session** ist sicherer.

### Backup mit `pg_basebackup`

Für PITR (Point-in-Time-Recovery):

```bash
pg_basebackup -h localhost -U replication \
    -D /backups/base/$(date +%F) \
    -X stream -P
# WAL-Archive in /backups/wal/, Retention via `find … -mtime +7`
```

Für regelmäßige logische Backups:

```bash
pg_dump -h localhost -U odoo \
    -d production \
    -F c -f /backups/$(date +%F)/production.dump

# Filestore separat!
tar -czf /backups/$(date +%F)/filestore.tar.gz /var/lib/odoo/filestore/production
```

> **Niemals nur DB sichern.** Der Filestore (`data_dir/filestore/<db>/`) enthält
> Anhänge und Bilder, die nicht in der DB sind, wenn `Binary(attachment=True)`.

---

## 6. Modul-Update-Pipeline

### Update-Befehl

```bash
docker compose exec odoo odoo \
    -c /etc/odoo/odoo.conf \
    -d production \
    -u eledia_project,eledia_billing \
    --stop-after-init
```

`-u` = update, `-i` = install. Mehrere Module komma-separiert.
Niemals `-u all` in Production ohne Backup — kann Stunden dauern.

### Hot-Update (Production läuft weiter)

odoo.sh: build-and-deploy macht das automatisch (mit kurzer Downtime
während Modul-Update).

Selbstgehostet: typisches Pattern:

1. Git-Pull auf Staging.
2. Test-Run gegen Staging-DB-Klon.
3. Maintenance-Page (nginx-Redirect auf statisches HTML) für 5 min.
4. `odoo … -u <modul> --stop-after-init` auf Prod-DB.
5. Container-Restart.
6. Maintenance-Page weg.

### Rolling-Update mit Multi-Container (avancé)

Bei mehreren Odoo-Containern hinter Load-Balancer: ein Container nach dem
anderen aktualisieren. **ABER** die DB-Migration läuft nur einmal — also
**erst** ein Container mit `-u`, andere Container müssen `--no-update` haben:

```bash
# Container 1 macht die Migration
docker compose run --rm odoo-migrator -u eledia_project --stop-after-init

# Andere Container starten ohne Update
docker compose up -d odoo-1 odoo-2 odoo-3
```

---

## 7. Migrations-Skripte

```
my_module/migrations/18.0.1.1.0/
├── pre-migration.py       # vor data/-Load
├── post-migration.py      # nach data/-Load
└── end-migration.py       # ganz am Ende
```

```python
# migrations/18.0.1.1.0/pre-migration.py
def migrate(cr, version):
    """Vor Update von <1.1.0 auf 1.1.0: alte Spalte umbenennen."""
    if not version:
        return                              # Frisch-Install — nicht migrieren
    cr.execute("""
        ALTER TABLE eledia_project
        RENAME COLUMN old_name TO new_name
    """)
```

```python
# migrations/18.0.1.1.0/post-migration.py
from odoo import api, SUPERUSER_ID


def migrate(cr, version):
    if not version:
        return
    env = api.Environment(cr, SUPERUSER_ID, {})
    env['eledia.project'].search([('migrated', '=', False)]).write({
        'migrated': True,
        'state': 'active',
    })
```

`version` = die **alte** installierte Modul-Version (str). `cr` = DB-Cursor.

### `openupgradelib` für komplexe Migrationen

```bash
pip install openupgradelib
```

```python
from openupgradelib import openupgrade


def migrate(cr, version):
    openupgrade.rename_columns(cr, {
        'eledia_project': [('foo', 'bar')],
    })
    openupgrade.rename_models(cr, [('eledia.old', 'eledia.new')])
    openupgrade.copy_columns(cr, {
        'eledia_project': [('legacy_amount', 'amount', None)],
    })
```

---

## 8. Migration zwischen Odoo-Versionen (z.B. 17 → 18)

### Offizieller Pfad: Odoo Enterprise Migration Service

Zahlungspflichtig. Odoo macht es. Sicher, aber teuer und langsam.

### Selbst-Migration via OpenUpgrade

OCA-Projekt: https://github.com/OCA/OpenUpgrade

Für jede Version eigener Branch (`18.0`). Workflow:

```bash
# 1. DB-Backup
pg_dump production > backup.dump

# 2. Codebase auf OpenUpgrade-Version
git clone -b 18.0 https://github.com/OCA/OpenUpgrade.git
# eigene Module auf 18.0 portieren

# 3. Migration-Lauf
./openupgrade/odoo-bin -d production \
    -u all \
    --addons-path=openupgrade/addons,addons-eledia \
    --stop-after-init \
    --logfile=/var/log/odoo-migration.log \
    --without-demo=all

# 4. Standard-Odoo-18 nehmen, gleiche DB
./odoo/odoo-bin -d production -u all
```

> **Prinzip:** OpenUpgrade migriert die Schema-Differenzen, dann wird mit
> Standard-Odoo nochmal `-u all` gefahren, um den finalen Stand zu validieren.

### Eigene Module porten

Bei jedem Major-Update:

1. `__manifest__.py` Version: `17.0.1.0.0` → `18.0.1.0.0`
2. Deprecation-Warnings im Log fixen.
3. Tests durchlaufen lassen.
4. View-Anpassungen: `<tree>` → `<list>`, `attrs` entfernen, `states` entfernen.
5. JS-Patches: jQuery weg, OWL 2.

---

## 9. Backup-Strategie

### Mindest-Setup

```bash
#!/usr/bin/env bash
# bin/backup.sh — täglich via Cron
set -euo pipefail

DATE=$(date +%F)
DEST=/backups/$DATE
mkdir -p "$DEST"

# 1. DB
docker compose exec -T postgres pg_dump -U odoo -F c production > "$DEST/db.dump"

# 2. Filestore
tar -czf "$DEST/filestore.tar.gz" -C /var/lib/odoo/filestore production

# 3. Configs
cp /etc/odoo/odoo.conf "$DEST/odoo.conf"
cp -r /etc/nginx/sites-enabled "$DEST/nginx/"

# 4. Encryption (für Off-Site)
gpg --encrypt --recipient backup@eledia.de "$DEST/db.dump"
gpg --encrypt --recipient backup@eledia.de "$DEST/filestore.tar.gz"

# 5. Off-Site
rclone sync "$DEST" "remote:eledia-backups/$DATE"

# 6. Retention
find /backups -mindepth 1 -maxdepth 1 -type d -mtime +30 -exec rm -rf {} +
```

### Restore-Drill (mind. quartalsweise testen!)

```bash
# 1. Empty staging-DB
docker compose exec postgres dropdb -U odoo staging
docker compose exec postgres createdb -U odoo staging

# 2. DB-Restore
gpg --decrypt /backups/2026-05-01/db.dump.gpg | \
    docker compose exec -T postgres pg_restore -U odoo -d staging

# 3. Filestore
tar -xzf /backups/2026-05-01/filestore.tar.gz -C /var/lib/odoo/filestore-staging

# 4. odoo.conf für Staging anpassen
# 5. Container starten, smoke-test
```

> **Backup ohne dokumentierten Restore-Drill ist kein Backup.**

---

## 10. Logging & Monitoring

### Log-Levels

```ini
log_level = info                     ; debug | debug_sql | info | warn | error
log_handler = :INFO,werkzeug:WARN,odoo.modules.loading:INFO,odoo.addons.eledia_project:DEBUG
logfile = /var/log/odoo/odoo.log
log_db = False                       ; bei True: Logs in DB-Tabelle
```

Per-Modul-Log-Levels via `log_handler` — sehr nützlich.

### Log-Rotation

```bash
# /etc/logrotate.d/odoo
/var/log/odoo/odoo.log {
    daily
    rotate 30
    compress
    delaycompress
    notifempty
    sharedscripts
    postrotate
        docker compose kill -s SIGUSR1 odoo
    endscript
}
```

`SIGUSR1` reopens log-files in Odoo.

### Prometheus-Metrics

OCA-Modul `monitoring` (https://github.com/OCA/server-tools/tree/18.0/monitoring)
oder eigener `/api/v1/metrics`-Endpoint:

```python
@http.route('/api/v1/metrics', type='http', auth='public', csrf=False)
def metrics(self):
    if request.httprequest.headers.get('Authorization') != f'Bearer {METRICS_TOKEN}':
        return Response(status=401)

    user_count = request.env['res.users'].sudo().search_count([('active', '=', True)])
    project_count = request.env['eledia.project'].sudo().search_count([])

    body = (
        f'# HELP odoo_users_total Active users\n'
        f'# TYPE odoo_users_total gauge\n'
        f'odoo_users_total {user_count}\n'
        f'# HELP eledia_projects_total Active projects\n'
        f'# TYPE eledia_projects_total gauge\n'
        f'eledia_projects_total {project_count}\n'
    )
    return Response(body, content_type='text/plain; version=0.0.4')
```

In Grafana via Prometheus-Datasource.

### Health-Check

```python
@http.route('/health', type='http', auth='none', csrf=False)
def health(self):
    try:
        request.env.cr.execute("SELECT 1")
        return Response('OK', status=200)
    except Exception:
        return Response('FAIL', status=503)
```

In nginx als `/health` weiterleiten, in Docker-Healthcheck nutzen.

---

## 11. Secrets-Management

### NICHT in Repo (auch nicht in `odoo.conf`)

```ini
; SCHLECHT
admin_passwd = supersecret
```

### Docker / Compose-Secrets

```yaml
services:
  odoo:
    environment:
      ODOO_ADMIN_PASSWD_FILE: /run/secrets/admin_passwd
    secrets:
      - admin_passwd

secrets:
  admin_passwd:
    file: ./secrets/admin_passwd.txt
```

Im Entrypoint:

```bash
#!/bin/sh
export ADMIN_PASSWORD=$(cat $ODOO_ADMIN_PASSWD_FILE)
exec odoo "$@"
```

### Vault / SOPS

Für mehrere Secrets: HashiCorp Vault, Mozilla SOPS, AWS Secrets Manager.
SOPS + git-crypt bei kleinen Setups OK.

### `ir.config_parameter` für Runtime-Secrets

API-Keys, Webhook-Secrets im `ir.config_parameter`, nicht im Code:

```python
api_key = self.env['ir.config_parameter'].sudo().get_param('eledia_billing.stripe_key')
```

Im Settings: `Settings → Technical → Parameters → System Parameters`. **Niemals**
diese Tabelle als „normaler User" lesbar machen — Default-ACL hat
`base.group_system` only.

---

## 12. Multi-DB / Multi-Tenant

### Multi-DB auf einem Server

`odoo.conf`:

```ini
list_db = True              ; DB-Auswahl in Login-Page (oder per Subdomain)
db_filter = ^%h$            ; DB-Name = aktueller Hostname
```

Mit nginx pro Subdomain → eine DB. Z.B. `customer-a.example.com` →
DB `customer_a`.

```nginx
server {
    server_name customer-a.example.com;
    location / {
        proxy_pass http://odoo;
        proxy_set_header Host customer_a;
    }
}
```

### Performance-Caveats

- Eine PostgreSQL-Instanz für viele DBs ist OK bis ~ 50 DBs.
- Filestore wächst pro DB → Disk-Monitoring pro DB.
- Backups pro DB skripten.

---

## 13. Checkliste: Production-Go-Live

- [ ] `odoo.conf`: `proxy_mode = True`, `list_db = False`, `without_demo = all`,
      `admin_passwd` aus Secrets.
- [ ] PostgreSQL: `pg_hba.conf` restriktiv, kein `trust`.
- [ ] TLS via Let's Encrypt + auto-renew (`certbot renew --quiet`).
- [ ] Reverse-Proxy mit Longpolling-Route auf `:8072`.
- [ ] Workers = 2 × Cores + 1, RAM-Limits gesetzt.
- [ ] Backup-Cron läuft + Restore-Drill abgenommen.
- [ ] Monitoring: Disk, RAM, CPU, PostgreSQL-Connections, HTTP-Latenz.
- [ ] Log-Rotation aktiv.
- [ ] Outgoing Email konfiguriert (SMTP, DKIM, SPF).
- [ ] Incoming Email konfiguriert (Catch-All-Mailbox + IMAP-Polling oder
      Mailgateway).
- [ ] DNS: A-Record + AAAA + MX (für Mail-In).
- [ ] Datenschutz: GDPR-Banner, Cookie-Notice, AVV mit Hosting-Anbieter.
- [ ] Externe Integrationen: API-Keys gesetzt, Webhooks-Secrets dokumentiert.
- [ ] Module: nur `installable=True` und reviewed Module installiert.
- [ ] User-Management: Admin-User mit eigener E-Mail (nicht `admin@example.com`),
      MFA aktiviert.

---

## 14. Häufige Pitfalls

| Pitfall | Symptom | Fix |
|---|---|---|
| Vergessenes `proxy_mode=True` | falsche URLs in Mails (http statt https) | `odoo.conf` setzen |
| Kein Longpolling-Proxy | Discuss / Live-Updates flackern | `:8072` proxieren |
| `db_maxconn × workers > max_connections` | "FATAL too many clients" | PgBouncer oder Werte anpassen |
| Kein `without_demo=all` in Prod | Demo-User in Customer-DB | sofort entfernen, neu deployen |
| Kein Filestore-Backup | Anhänge weg nach Restore | Backup-Skript erweitern |
| `wkhtmltopdf` falsche Version | Reports leer oder fehlerhaft | offizielle gepatched Version: 0.12.6.1 |
| `default_company_id` fehlt | Multi-Company-Records nicht sichtbar | Default in Modell setzen |
| Cron läuft als falscher User | Zugriffsfehler in Cron | `user_id` auf Admin oder dedizierten Service-User |
| `--limit-time-real` zu niedrig für Reports | "504 Gateway Timeout" | erhöhen, oder Report async |

---

## 15. Quellen

- On-Premise Install: https://www.odoo.com/documentation/18.0/administration/on_premise.html
- odoo.sh Doc: https://www.odoo.com/documentation/18.0/administration/odoo_sh.html
- Docker-Hub: https://hub.docker.com/_/odoo
- OpenUpgrade: https://github.com/OCA/OpenUpgrade
- PgBouncer: https://www.pgbouncer.org/
- OCA `monitoring`: https://github.com/OCA/server-tools/tree/18.0/monitoring
- Odoo Bistro Migration Service: https://www.odoo.com/de_DE/migration
