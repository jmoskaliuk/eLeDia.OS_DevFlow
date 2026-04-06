# Features (Was + Wie)

## Zweck
Beschreibt Features und deren Verhalten (Soll-Zustand)

---

## Struktur pro Feature

### featXX Titel
**Status:** open / planned / in-progress / done  
**Beschreibung:**  
**Verhalten:**  
**Akzeptanzkriterien:**  
-  

**Offene Fragen:**  

---

## Regeln

- Keine Code-Details
- Keine Tasks
- Keine Testlogs

---

## KI-Regeln

- Keine Entscheidungen erfinden
- Keine Features löschen
- Nur bestätigte Inhalte ergänzen

---

## Features

### feat01 Workflow-Dokumentation konsistent halten
**Status:** done  
**Beschreibung:** Die fünf Steuerdateien und das Master-Dokument verwenden dieselben Dateinamen, dieselben IDs und dieselbe Arbeitslogik.  
**Verhalten:** Alle Referenzen zeigen auf die vorhandenen Dateien `01-features.md` bis `05-quality.md`. IDs werden durchgehend als `featXX`, `taskXX`, `bugXX` und `testXX` geschrieben. Operative Änderungen werden erst dann als abgeschlossen betrachtet, wenn Feature-, User- und Dev-Dokumentation zueinander passen.  
**Akzeptanzkriterien:**  
- `00-master.md` verweist auf die realen Steuerdateien im Repository.
- Vorlagen in `01-features.md`, `04-tasks.md` und `05-quality.md` nutzen dasselbe ID-Schema.
- `02-user-doc.md` und `03-dev-doc.md` beschreiben die Nutzung und die technische Struktur dieses Dokumentations-Workflows konsistent.

**Offene Fragen:** Keine.
