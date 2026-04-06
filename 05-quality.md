# Quality (Bugs & Tests)

## Bugs

### bugXX Titel
**Status:** open / fixed  
**Feature:** featXX  
**Beschreibung:**  
**Reproduktion:**  
**Erwartet:**  
**Tatsächlich:**  

---

## Testläufe

### testXX
**Datum:**  
**Kontext:**  
**Ergebnis:**  
**Fehler:**  
**Bezug:** featXX  

---

### bug01 Veraltete Dateireferenzen und gemischte ID-Schemata
**Status:** fixed  
**Feature:** feat01  
**Beschreibung:** `00-master.md` verwies auf nicht vorhandene Dateien, und die Vorlagen mischten `FEAT-XXX`- und `featXX`-Schreibweisen. Dadurch war die operative Steuerung des Systems uneinheitlich.  
**Reproduktion:** Repository frisch öffnen, `00-master.md` lesen und die referenzierten Dateien mit dem Dateisystem vergleichen. Anschließend die Vorlagen in `01-features.md`, `04-tasks.md` und `05-quality.md` vergleichen.  
**Erwartet:** Alle Referenzen zeigen auf vorhandene Dateien, und alle Dokumente nutzen dieselbe ID-Notation.  
**Tatsächlich:** `00-master.md` nannte `01-product.md` und `04-work.md`, während das Repository `01-features.md` und `04-tasks.md` verwendet. Außerdem unterschieden sich die ID-Vorlagen.  

---

### test01 Dokumentations-Baseline geprüft
**Datum:** 2026-04-06  
**Kontext:** Manuelle Prüfung der Steuerdokumente nach der Vereinheitlichung von Dateinamen und IDs.  
**Ergebnis:** Bestanden. `00-master.md`, `01-features.md`, `02-user-doc.md`, `03-dev-doc.md`, `04-tasks.md`, `05-quality.md` und `README.md` verwenden dieselben Dateinamen und dasselbe ID-Schema.  
**Fehler:** Keine.  
**Bezug:** feat01  

---

## Regeln

- Bugs strukturiert
- Tests klar dokumentieren

---

## KI-Regeln

- Bugs deduplizieren
- keine Diskussionen
- nur Fakten
