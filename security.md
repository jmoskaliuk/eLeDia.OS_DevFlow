# Datensicherheit

## Zweck

Dieses Dokument beschreibt den projektspezifischen Sicherheitsstand: schützenswerte
Werte, Vertrauensgrenzen, Bedrohungen, Schutzmaßnahmen, Findings und Reaktionen auf
Vorfälle. Es ergänzt `privacy.md`, ersetzt aber keine Datenschutzbewertung.

Keine produktiven Secrets, privaten Schlüssel, Tokens, Passwörter oder unmittelbar
ausnutzbaren Zugangsdaten dokumentieren. Stattdessen nur Namen sicherer Ablagen und
zuständige Rollen nennen.

## Geltungsbereich

- **Produkt/Projekt:**
- **Security-Verantwortung:**
- **Betroffene Systeme und Umgebungen:**
- **Schutzbedarf:** normal | hoch | kritisch
- **Stand:** YYYY-MM-DD
- **Letzte menschliche Prüfung:** YYYY-MM-DD / Person

## Schutzwerte und Vertrauensgrenzen

| Schutzwert/System | Vertraulichkeit | Integrität | Verfügbarkeit | Verantwortlich | Bemerkung |
|---|---|---|---|---|---|
| | normal/hoch/kritisch | normal/hoch/kritisch | normal/hoch/kritisch | | |

Wichtige Vertrauensgrenzen und externe Schnittstellen als Datenfluss oder kurze
Architekturbeschreibung festhalten.

## Bedrohungsmodell

| Bedrohung/Missbrauchsfall | Betroffene Komponenten | Eintritt/Auswirkung | Schutzmaßnahmen | Restrisiko | Status |
|---|---|---|---|---|---|
| | | | | | offen |

Mindestens berücksichtigen:

- Authentifizierung, Sitzungen und Kontenübernahme
- Autorisierung, Rollen, Mandanten- und Objektgrenzen
- Eingabevalidierung, Uploads, Injection und unsichere Deserialisierung
- Ausgabe-Escaping, XSS, CSRF und Weiterleitungen
- Secrets, Verschlüsselung und Schlüsselrotation
- Abhängigkeiten, Lieferkette, Builds und Deployments
- Protokollierung, Monitoring, Backups und Wiederherstellung
- Verfügbarkeit, Rate Limits und Missbrauch externer APIs

## Sicherheitskontrollen

| Bereich | Vorgabe/Umsetzung | Nachweis/Test | Verantwortlich | Status |
|---|---|---|---|---|
| Authentifizierung | | | | offen |
| Autorisierung | | | | offen |
| Secrets | | | | offen |
| Verschlüsselung | | | | offen |
| Eingabe/Ausgabe | | | | offen |
| Dependencies/SBOM | | | | offen |
| Logging/Monitoring | | | | offen |
| Backup/Restore | | | | offen |
| CI/CD und Deploy | | | | offen |

## Findings und Schwachstellen

Sicherheitsrelevante Details nur so weit dokumentieren, dass das Repository sie
sicher enthalten darf. Für vertrauliche Findings auf ein geschütztes System
verweisen.

| Finding | Schweregrad | Bezug zu Feature/Task/Bug | Maßnahme | Verantwortlich | Status |
|---|---|---|---|---|---|
| | kritisch/hoch/mittel/niedrig | | | | offen |

## Incident Response

- **Meldeweg:**
- **Ersteinschätzung und Eskalation:**
- **Eindämmung:**
- **Beweissicherung und Protokolle:**
- **Wiederherstellung:**
- **Kommunikation/Datenschutzbezug:**
- **Nachbereitung und Lessons Learned:**

## Prüfung bei Änderungen und Releases

- [ ] Neue oder geänderte Angriffsflächen sind im Bedrohungsmodell erfasst.
- [ ] Authentifizierung, Autorisierung und Mandantentrennung sind geprüft.
- [ ] Keine Secrets oder produktiven Daten wurden committed oder geloggt.
- [ ] Abhängigkeiten und bekannte Schwachstellen sind geprüft.
- [ ] Relevante automatisierte und manuelle Security-Tests sind dokumentiert.
- [ ] Backup, Restore, Monitoring und Incident-Prozess bleiben funktionsfähig.
- [ ] Offene kritische oder hohe Findings blockieren das Release oder sind menschlich akzeptiert.
- [ ] Relevante Änderungen stehen in `changelog.md` und `releasenotes.md`.
