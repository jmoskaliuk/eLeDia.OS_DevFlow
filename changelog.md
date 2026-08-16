# Changelog

Dieses Dokument hält die technischen Änderungen des Projekts nachvollziehbar und
chronologisch fest. Es wird bei jeder relevanten Änderung aktualisiert und richtet
sich primär an Entwicklung, Betrieb und Wartung.

Einträge stehen in umgekehrt chronologischer Reihenfolge. Änderungen bis zur
Freigabe unter `Unreleased` sammeln und beim Release in einen datierten
Versionsabschnitt verschieben.

## Unreleased

### Added

-

### Changed

-

### Fixed

-

### Security

-

### Deprecated

-

### Removed

-

## Versionsvorlage

Den folgenden Block pro Release kopieren:

```markdown
## [X.Y.Z] - YYYY-MM-DD

### Added
- Neue technische Funktionen.

### Changed
- Verhaltens-, API-, Konfigurations- oder Datenmodelländerungen.

### Fixed
- Behobene Fehler mit Bezug zu bugXX/taskXX, soweit vorhanden.

### Security
- Veröffentlichbare Sicherheitsverbesserungen ohne ausnutzbare Details.

### Deprecated
- Noch vorhandene, künftig entfallende Funktionen inklusive Alternative.

### Removed
- Entfernte Funktionen, APIs oder Konfigurationen.
```

## Regeln

- Nutzerrelevante Änderungen zusätzlich in `releasenotes.md` erklären.
- Datenschutz- und Sicherheitsauswirkungen mit `privacy.md` und `security.md`
  abgleichen.
- Keine reine Liste von Commits oder internen Diskussionen führen.
- Breaking Changes, Migrationen und erforderliche Betriebsmaßnahmen ausdrücklich
  kennzeichnen.
- Keine Secrets, vertraulichen Findings oder personenbezogenen Daten aufnehmen.
