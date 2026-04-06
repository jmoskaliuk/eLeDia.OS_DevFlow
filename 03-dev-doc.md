# Developer Documentation

## Zweck
Beschreibt die tatsächliche technische Umsetzung

---

## Struktur

### Feature: [Name]

**Architektur:**  
**Komponenten:**  
**Datenfluss:**  
**Besonderheiten:**  

---

## Regeln

- Nur IST-Zustand
- Keine Tasks
- Keine Ideen

---

## KI-Regeln

- Nur implementierte Dinge beschreiben
- präzise und knapp
- keine Spekulation

---

## Features

### Feature: Workflow-Dokumentation konsistent halten

**Architektur:**  
Der Workflow ist dateibasiert. `00-master.md` steuert die Session und verweist auf die fünf operativen Dokumente. Jedes Dokument hat genau eine Verantwortung.

**Komponenten:**  
`01-features.md` beschreibt den Soll-Zustand, `02-user-doc.md` die Nutzersicht, `03-dev-doc.md` die tatsächliche Umsetzung, `04-tasks.md` den Arbeitsfluss und `05-quality.md` Bugs sowie Testläufe.

**Datenfluss:**  
Ein neues Vorhaben startet als `featXX`. Daraus entstehen `taskXX`-Einträge in `04-tasks.md`. Nach der Umsetzung werden die betroffenen Beschreibungen in `01-features.md`, `02-user-doc.md` und `03-dev-doc.md` synchronisiert. Prüfungen und Fehler landen als `testXX` und `bugXX` in `05-quality.md`.

**Besonderheiten:**  
Das Repository nutzt bewusst ein einheitliches kleingeschriebenes ID-Schema. Statuswechsel werden durch Verschieben zwischen Abschnitten dokumentiert, nicht durch Löschen von Verlauf.
