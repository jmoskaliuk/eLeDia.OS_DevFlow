# Qualität

## Tests

### test01 MVP-Installation und Provider
Linked: feat01 / task01  
Status: pending

**Automatische Checks**

- `php -l` für PHP-Dateien
- `moodle-plugin-ci phpcs --max-warnings 0`
- `moodle-plugin-ci phpdoc --max-warnings 0`
- `moodle-plugin-ci validate`
- `moodle-plugin-ci phpunit --fail-on-warning`

**Manuelle Verifikation**

1. Plugin nach `admin/tool/adminassist` installieren.
2. Moodle-Upgrade ausführen.
3. Als Admin `/admin/tool/adminassist/index.php` öffnen.
4. Cron- und Debugging-Status prüfen.
5. Alle Schnellzugriffe anklicken.
6. Als Nutzer ohne Capability Zugriff prüfen.

## Bugs

Keine bekannten Bugs.

## Risiken

- Moodle 4.5-Kompatibilität begrenzt den Einsatz von Moodle 5.2 React/MDS.
- Einige Core-Adminseiten können je nach installierten Plugins oder Berechtigungen anders erreichbar sein.
- Der MVP bewertet viele Punkte noch als Schnellzugriff statt als echten Zustand.

