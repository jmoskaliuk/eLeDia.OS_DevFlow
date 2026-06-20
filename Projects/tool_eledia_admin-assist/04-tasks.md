# Tasks

## Neu

Keine untriagierten Einträge.

## Klärung benötigt

### q01 Ziel-Moodle-Version und Design-System
Linked: feat01 / feat02  
Asked-by: KI  
Status: open  
Answer: offen

Soll Admin Assist kurzfristig Moodle 4.5 kompatibel bleiben oder primär Moodle 5.2 mit React/Moodle Design System nutzen?

### q02 Produktiv-Checks
Linked: feat02  
Asked-by: KI  
Status: open  
Answer: offen

Welche Checks sind für eLeDia-Moodle-Admins am wichtigsten: Security, Backups, Plugin-Updates, scheduled task failures, Datenschutz, Performance oder Hosting-spezifische Checks?

## Tasks

### task01 MVP-Plugin scaffolden
Status: in_progress  
Feature: feat01  
Priorität: P0

**Ziel**  
Installierbares Admin-Tool mit Übersichtsseite, Capability, Privacy API und ersten Checks.

**Schritte**
1. Moodle-Basisdateien anlegen.
2. Admin-Menüeintrag und Capability anlegen.
3. Dashboard-Provider und Mustache-Template bauen.
4. Sprachstrings EN/DE ergänzen.
5. Basistest und CI-Workflow hinzufügen.

**Erwartetes Ergebnis**  
Das Plugin kann unter `admin/tool/adminassist` installiert werden und zeigt eine zentrale Admin-Übersicht.

**Done-Checkliste**
- [x] `01-features.md` aktualisiert
- [x] `02-user-doc.md` aktualisiert
- [x] `03-dev-doc.md` aktualisiert
- [x] `test01` in `05-quality.md` grün
- [ ] PO Sign-off

### task02 Provider-Architektur für echte Checks entwerfen
Status: open  
Feature: feat03  
Priorität: P1

**Ziel**  
Checks werden modular, testbar und priorisierbar.

**Erwartetes Ergebnis**  
Jeder Check liefert Titel, Beschreibung, Status, Priorität, Ziel-URL und optionale Remediation-Hinweise.

### task03 Behat-Flow für Admin-Übersicht ergänzen
Status: open  
Feature: feat01  
Priorität: P2

**Ziel**  
Ein Admin kann die Übersicht öffnen; ein nicht berechtigter Nutzer wird blockiert.

## Done

Noch keine Tasks mit PO-Sign-off abgeschlossen.
