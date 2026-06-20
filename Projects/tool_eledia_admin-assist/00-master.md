# Admin Assist — Master

## 1. Projekt-Meta

- **Name:** Admin Assist
- **Moodle-Komponente:** `tool_adminassist`
- **Repository:** <https://github.com/jmoskaliuk/tool_eledia_admin-assist>
- **DevFlow-Quelle:** <https://github.com/jmoskaliuk/eLeDia.OS_DevFlow>
- **Ziel:** Moodle-Admins erhalten eine zentrale Übersichtsseite für wichtige Todos, Wartungsaufgaben und direkte Einstiege in bestehende Admin-Funktionen.
- **Plugin-Typ:** `admin/tool`, installiert unter `admin/tool/adminassist`
- **Primäres Zielsystem:** Moodle 4.5+; vorbereitet für Moodle 5.x

## 2. Leitentscheidung

### adr01 Admin-Tool statt Local-Plugin

- **Datum:** 2026-06-20
- **Status:** beschlossen
- **Kontext:** Die Funktion richtet sich ausschließlich an Site-Admins und bündelt bestehende Admin-Oberflächen.
- **Optionen:** `local_*` mit eigener Navigation | `report_*` | `admin/tool`
- **Entscheidung:** `admin/tool` mit Komponente `tool_adminassist`.
- **Konsequenzen:** Das Plugin erscheint im Site-Administration-Kontext, nutzt System-Capabilities und speichert im MVP keine eigenen Daten.

## 3. Session-Start

1. Dieses Dokument lesen.
2. `04-tasks.md` öffnen.
3. Offene `taskXX`, `qXX`, `bugXX` prüfen.
4. Bei Code-Änderungen `03-dev-doc.md` aktualisieren.
5. Bei UX-Änderungen `02-user-doc.md` aktualisieren.
6. Vor Done: passende Checks in `05-quality.md` grün markieren.

## 4. Definition of Done

Ein Feature ist erst fertig, wenn:

- Akzeptanzkriterien in `01-features.md` erfüllt sind.
- Nutzerführung in `02-user-doc.md` beschrieben ist.
- Implementierung in `03-dev-doc.md` nachvollziehbar ist.
- Relevante Tests oder manuelle Verifikationen in `05-quality.md` dokumentiert sind.
- PO-Sign-off erfolgt ist.

## 5. Branch- und Commit-Konvention

- Branch: `feat/featXX-kurztitel`, `task/taskXX-kurztitel`, `fix/bugXX-kurztitel`
- Commit: `taskXX: Kurzbeschreibung`
- PR: `taskXX Kurzbeschreibung`

