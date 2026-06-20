# Entwickler-Dokumentation

## Plugin-Struktur

```text
admin/tool/adminassist/
├── version.php
├── settings.php
├── index.php
├── db/access.php
├── classes/local/dashboard_provider.php
├── classes/privacy/provider.php
├── lang/en/tool_adminassist.php
├── lang/de/tool_adminassist.php
├── templates/dashboard.mustache
└── tests/local/dashboard_provider_test.php
```

## Komponente

- Frankenstyle: `tool_adminassist`
- Namespace: `tool_adminassist`
- Capability: `tool/adminassist:view`

## Rendering

`index.php` richtet die Admin-Seite über `admin_externalpage_setup()` ein, fordert die System-Capability an und rendert `tool_adminassist/dashboard`.

Die Daten für das Template liefert `tool_adminassist\local\dashboard_provider`.

## Dashboard Provider

`dashboard_provider::get_sections()` erzeugt drei Gruppen:

- Betrieb
- Qualität und Wartung
- Sicherheit und Resilienz

Im MVP sind Cron und Debugging echte Checks. Weitere Einträge sind Schnellzugriffe auf bestehende Moodle-Adminseiten.

## Datenschutz

`classes/privacy/provider.php` implementiert `null_provider`, weil im MVP keine eigenen Daten gespeichert werden.

## Teststrategie

Der erste PHPUnit-Test prüft, dass der Provider die erwarteten Dashboard-Gruppen zurückgibt. Für spätere Provider sollen gezielte Unit-Tests und Behat-Flows ergänzt werden.

