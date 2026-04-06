# User Documentation

## Zweck
Erklärt das System aus Nutzersicht

---

## Struktur

### Feature: [Name]

**Was macht es?**  
**Wie benutze ich es?**  
**Beispiel:**  
**Hinweise:**  

---

## Regeln

- Keine technischen Details
- Klar und verständlich schreiben

---

## 🔥 KI-Pflicht

Bei JEDEM Feature:
- prüfen
- ggf. aktualisieren

---

## KI-Regeln

- Nutzerfokus
- einfache Sprache
- keine internen Begriffe ohne Erklärung

---

## Features

### Feature: Workflow-Dokumentation konsistent halten

**Was macht es?**  
Das System hält Projektwissen in fünf festen Dateien getrennt: Features, User-Doku, Dev-Doku, Tasks und Qualität. So bleibt nachvollziehbar, was geplant ist, was umgesetzt wurde und was noch geprüft werden muss.

**Wie benutze ich es?**  
Arbeite immer vom Master-Dokument aus. Prüfe zuerst offene `taskXX`-Einträge in `04-tasks.md`. Wenn du etwas änderst, aktualisiere danach die passende Beschreibung in `01-features.md`, die Anwendersicht in `02-user-doc.md` und die technische Sicht in `03-dev-doc.md`. Bugs kommen nach `05-quality.md`.

**Beispiel:**  
Du führst `task01` aus. Danach verschiebst du den Task in den passenden Abschnitt in `04-tasks.md`, dokumentierst das Ergebnis in den drei Perspektiven und ergänzt einen `testXX`-Eintrag in `05-quality.md`, wenn du die Konsistenz geprüft hast.

**Hinweise:**  
Verwende IDs immer als `featXX`, `taskXX`, `bugXX` und `testXX`. Nutze vorhandene Dateinamen und lösche keine Einträge, sondern verschiebe sie in den passenden Abschnitt.
