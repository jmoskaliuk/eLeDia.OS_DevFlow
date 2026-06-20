# Features

## feat01 Admin-Übersichtsseite

**Status:** in_progress  
**Priorität:** P0  
**Zielgruppe:** Moodle Site-Admins und Manager mit Admin-Berechtigung

### Ziel

Admins sehen an einer zentralen Stelle die wichtigsten Aufgaben und Schnellzugriffe, ohne sich durch die komplette Moodle-Administration zu klicken.

### MVP-Verhalten

- Das Plugin stellt eine Admin-Seite bereit.
- Die Seite gruppiert Aufgaben in Betrieb, Qualität/Wartung und Sicherheit/Resilienz.
- Einfache Statussignale zeigen mindestens Cron- und Debugging-Zustand.
- Bestehende Moodle-Adminfunktionen werden nicht ersetzt, sondern leichter erreichbar gemacht.
- Das Plugin speichert im MVP keine personenbezogenen Daten.

### Akzeptanzkriterien

- **AC01:** Ein Admin kann die Seite über die Site-Administration öffnen.
- **AC02:** Cron wird als `OK` oder `Todo` bewertet.
- **AC03:** Debugging wird als `OK` oder `Todo` bewertet.
- **AC04:** Die Übersicht verlinkt zu bestehenden Moodle-Seiten für Notifications, scheduled tasks, environment, plugins, security, policies und backups.
- **AC05:** Nicht berechtigte Nutzer können die Seite nicht öffnen.
- **AC06:** Privacy API meldet, dass keine personenbezogenen Daten gespeichert werden.

## feat02 Intelligente Todo-Priorisierung

**Status:** proposed  
**Priorität:** P1

### Ziel

Admin Assist soll aus Moodle-Zustand echte To-dos ableiten und nach Dringlichkeit sortieren.

### Mögliche Signale

- Fehlgeschlagene scheduled tasks
- Plugin-Updates und Upgrade-Bedarf
- Sicherheitsreport mit Warnungen
- Cron-Latenz
- Debugging auf Produktivsystemen
- Backups deaktiviert oder fehlgeschlagen

## feat03 Erweiterbare Check-Provider

**Status:** proposed  
**Priorität:** P2

### Ziel

Checks sollen später als eigene Provider-Klassen modular ergänzt werden können, ohne die Dashboard-Seite umzubauen.

