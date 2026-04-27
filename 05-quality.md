# Qualität

## Meta

Dieses Dokument erfasst die **Qualitätssicht** auf das System.

Es enthält:
- Bugs (`bugXX`) — reproduzierbare Probleme, mit Severity
- Tests (`testXX`) — Verifikationen, die auf Akzeptanzkriterien aus `01-features.md` verweisen

Es enthält **nicht**:
- Ideen → `01-features.md`
- Tasks → `04-tasks.md`

---

## 🐞 Bugs

### Severity-Skala

| Severity | Bedeutung | Reaktion |
|---|---|---|
| **S1** | Kritisch — Kernfunktion komplett kaputt, Datenverlust, Sicherheitslücke | Sofortiger Hotfix-Task, blockiert Release |
| **S2** | Schwer — Feature unbrauchbar oder schwerer UX-Defekt, kein Workaround | Im laufenden Release fixen |
| **S3** | Mittel — Feature eingeschränkt, Workaround vorhanden | Nächstes Release |
| **S4** | Gering — kosmetisch, edge-case, minor | Backlog, opportunistisch |

### Vorlage

```
### bugXX Kurztitel

Feature:  featXX
Severity: S1 | S2 | S3 | S4
Status:   open | in_progress | fixed | wontfix
Linked:   taskXX (Fix), testXX (Reproduktion)

**Beschreibung**
Was ist falsch?

**Reproduktion**
1. ...
2. ...

**Erwartet**
Was sollte passieren?

**Tatsächlich**
Was passiert stattdessen?

**Umgebung** (falls relevant)
Browser / Version / Konfiguration / Datenstand
```

---

## 🧪 Tests

Jeder Test verweist auf ein Akzeptanzkriterium aus `01-features.md` und macht es prüfbar.

### Vorlage

```
### testXX Kurztitel

Feature:                featXX
Akzeptanzkriterium:     featXX.ACyy
Typ:                    manuell | automatisiert
Status:                 pending | pass | fail
Letzter Lauf:           YYYY-MM-DD

**Schritte**
1. ...
2. ...

**Erwartetes Ergebnis**
Aus dem Akzeptanzkriterium übernommen oder konkretisiert.

**Beobachtetes Ergebnis** (bei pass/fail)
Was wurde tatsächlich gesehen?

**Verlinkter Bug** (bei fail)
bugXX
```

---

## Regeln

- Jeder Bug bekommt eine Severity — auch S4 ist eine Severity.
- Jeder Test referenziert ein Akzeptanzkriterium. Ein Test ohne `featXX.ACyy`-Verweis ist verdächtig.
- Reproduzierbarkeit hat Vorrang vor Vermutung.
- Fixed-Status nur, wenn der zugehörige `testXX` grün ist.

---

## Grundprinzip

> Bugs sind Teil des normalen Loops, keine Ausnahme.
> Ein Test ohne Akzeptanzkriterium prüft nichts Verbindliches.
