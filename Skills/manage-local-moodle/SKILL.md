---
name: manage-local-moodle
description: Operate the user's local Moodle 5.2 and Moodle 4.5 LTS test installations on OrbStack, manage additional isolated Moodle instances, install plugins into one or all instances, and run Moodle Plugin CI checks including PHPDoc, PHPCS, PHP lint, PHPUnit, Behat, Mustache, and Grunt. Use for requests about starting or stopping local Moodle, opening the Moodle Control Center, installing/testing/updating Moodle plugins, compatibility matrices, container status or logs, cache purging, and Moodle CLI upgrades in /Users/moskaliuk/Documents/Docker.
---

# Lokales Moodle verwalten

Alle Operationen über `/Users/moskaliuk/Documents/Docker/moodlectl` ausführen. Das Skript setzt Docker-Variablen, Ports und Projektbezeichner selbst und startet OrbStack bei Bedarf.

## Instanzen auswählen

- Moodle 5.2: `moodlectl <befehl>` oder `moodlectl --instance default <befehl>`; URL `http://localhost:8000`
- Moodle 4.5 LTS: `moodlectl --instance moodle45 <befehl>`; URL `http://localhost:8045`
- Instanzen auflisten: `moodlectl instance-list`
- Neue Instanz erstellen: `moodlectl instance-create <name> --branch <branch> --port <port> --php <version>`

Für Start, Stop, Status, Öffnen, Logs, Upgrade und Cache-Löschung jeweils `up`, `down`, `status`, `open`, `logs-tail`, `upgrade` oder `purge-caches` als Befehl verwenden.

## Webinterface

Das lokale Control Center über `/Users/moskaliuk/Documents/Docker/moodle-control-center.command` starten. Es ist unter `http://localhost:3000` erreichbar und darf nicht öffentlich bereitgestellt werden. Darüber Instanzen starten, stoppen und öffnen, Plugins installieren, Logs lesen und CI-Prüfungen ausführen.

## Plugins installieren

- In eine Instanz: `moodlectl [--instance NAME] plugin-install <verzeichnis|git-url|zip>`
- In alle Instanzen: `moodlectl plugin-install-all <quelle>`
- Vorhandene Git-Installation aktualisieren: `moodlectl [--instance NAME] plugin-update <komponente>`

Das Skript liest `$plugin->component` aus `version.php`, bestimmt den korrekten Plugin-Pfad und führt Upgrade sowie Cache-Löschung aus. Vorhandene Plugin-Verzeichnisse nicht überschreiben. Keine zufälligen Forks installieren; bei nur genanntem Plugin-Namen die offizielle Quelle und Versionskompatibilität bestimmen.

## CI ausführen

- Einzelprüfung: `moodlectl [--instance NAME] test <check> <komponente>`
- Versionsmatrix: `moodlectl test-matrix <check> <komponente>`
- Checks: `static`, `phplint`, `phpcs`, `phpdoc`, `validate`, `savepoints`, `mustache`, `grunt`, `phpunit`, `behat`, `all`

Statische Checks und Testläufe im PHP-Container der ausgewählten Moodle-Version ausführen. PHPUnit und Behat initialisieren ihre getrennten Testdaten beim ersten Aufruf automatisch. Testergebnisse vollständig berichten; Fehler im Plugin nicht als Fehler der lokalen Infrastruktur darstellen.

## Sicherheitsregeln

- Kein `reset`, `down -v`, Löschen einer Instanz oder Entfernen von Daten ohne ausdrücklichen Auftrag.
- Keine lokalen Plugin- oder Moodle-Core-Änderungen überschreiben, bereinigen oder zurücksetzen.
- Bei Problemen zuerst `doctor`, `status` und `logs-tail` für die betroffene Instanz ausführen.
