# Benutzer-Dokumentation

## Zweck

Admin Assist bündelt wichtige Moodle-Administrationsaufgaben auf einer kompakten Übersichtsseite. Die Seite ersetzt keine Moodle-Core-Funktion, sondern führt schneller zu den vorhandenen Admin-Bereichen.

## Aufruf

Nach Installation und Moodle-Upgrade erscheint die Seite in der Website-Administration als **Admin Assist**.

Direkter Pfad:

```text
/admin/tool/adminassist/index.php
```

## Bereiche

### Betrieb

Zeigt operative Aufgaben wie Cron, Moodle-Mitteilungen und geplante Vorgänge.

### Qualität und Wartung

Verlinkt zu Debugging, Systemumgebung und Plugin-Übersicht.

### Sicherheit und Resilienz

Verlinkt zu Sicherheitsbericht, Website-Richtlinien und automatischen Sicherungen.

## Statusanzeigen

- **OK:** Der einfache Check sieht aktuell keinen Handlungsbedarf.
- **Todo:** Der Check erkennt einen Zustand, der geprüft werden sollte.
- **Prüfen:** Das Plugin verlinkt bewusst auf eine Moodle-Seite, ohne den Zustand bereits automatisch zu bewerten.

## Berechtigungen

Nur Rollen mit der Capability `tool/adminassist:view` können die Übersicht sehen. Standardmäßig erhält die Rolle `manager` diese Berechtigung.

