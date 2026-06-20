# eLeDia.OS_DevFlow

eLeDia.OS_DevFlow ist ein strukturierter „Operating System"-Rahmen für KI-gestützte Softwareentwicklung.

Er definiert, wie Idee, Implementierung, Dokumentation und Qualität in einem konsistenten Workflow zusammenwirken — sodass Mensch und KI (z. B. Claude, ChatGPT) effektiv zusammenarbeiten können, ohne dass Kontext verloren geht.

---

## Warum es das gibt

Beim Arbeiten mit KI an Softwareprojekten taucht ein neues Problem auf:

> Der limitierende Faktor ist nicht mehr das Schreiben von Code — es ist das Managen von Kontext.

Typische Probleme:
- Anforderungen, Entscheidungen und Implementierung driften auseinander
- Kontext geht im Chatverlauf verloren
- Benutzer-Doku wird vergessen
- Entwickler-Doku veraltet
- Bugs und Tests werden inkonsistent erfasst
- KI produziert technisch korrekte, aber kontextuell falsche Lösungen

eLeDia.OS_DevFlow adressiert das mit einer **minimalen, aber strikten Struktur** für Information.

---

## Kernidee

Softwareentwicklung wird in **fünf Perspektiven** getrennt:

| Perspektive | Datei | Frage |
|---|---|---|
| Features | `01-features.md` | Was bauen wir und warum? |
| Benutzer | `02-user-doc.md` | Wie bedient ein Nutzer es? |
| Entwicklung | `03-dev-doc.md` | Wie ist es implementiert? |
| Arbeit | `04-tasks.md` | Was tun wir gerade? |
| Qualität | `05-quality.md` | Funktioniert es, und was ist kaputt? |

Jede Datei hat **eine** Verantwortung.

Plus drei Querschnitts-Bausteine:
- **Master** (`00-master.md`) — Eintrittspunkt, Rollen, ADRs, Prompt-Shortcuts
- **Skills** (`Skills/`) — generisches, projektübergreifendes Framework-Wissen (Moodle, Design Systems, BFSG)
- **Playbooks** (`Playbooks/`) — projekt-spezifische Deploy-/Release-Abläufe

---

## Wichtigste Regel

> Ein Feature ist erst **done**, wenn alle drei Doku-Perspektiven konsistent sind.

Heißt:
- Feature definiert (`01-features.md`, inkl. Akzeptanzkriterien)
- Nutzer kann es bedienen (`02-user-doc.md`)
- Implementierung ist beschrieben (`03-dev-doc.md`)

Fehlt eine → Feature ist nicht done.

---

## Workflow

```
Idee → Feature → Task → Implementierung → Test → (Bug → Fix) → Done → Doku-Sync
```

Iterativer Loop — Implementierung kann neue Tasks erzeugen, Tests können Bugs aufdecken, Bugs erzeugen neue Tasks, Tasks können Features verfeinern.

---

## 🤝 Mensch und KI — Wer macht was?

Verantwortung ist explizit verteilt (Details in `00-master.md` §9):

| Rolle | Wer | Schwerpunkt |
|---|---|---|
| **Product Owner** | Mensch | Ziel, Scope, Sign-off, Releases |
| **Architekt** | Mensch (KI berät) | ADRs, Strukturentscheidungen |
| **Implementer** | KI primär | Code, Tests |
| **Doc-Sync** | KI primär | `01`/`02`/`03` konsistent halten |
| **QA-Reviewer** | Mensch (KI generiert Drafts) | manuelle Verifikation, BFSG |
| **Triage** | Mensch | „🆕 Neu" → Tasks, Klärungen, Priorität |

KI rät nicht — bei Unklarheit landet die Frage als `qXX` in `04-tasks.md`.

---

## 🔁 Kollaborations-Prinzipien

- **KI darf alleine:** Code für freigegebene Tasks, Doku-Sync, Status-Reports
- **KI muss vorschlagen + warten:** neue Features, Architektur-Entscheidungen, neue Dependencies, Lösch-Operationen
- **Nur Mensch:** Done-Sign-off, Releases, Submission, Privacy/Secrets

---

## ID-System

| Präfix | Bedeutung |
|---|---|
| `featXX` | Feature |
| `taskXX` | Task |
| `qXX` | Offene Frage |
| `bugXX` | Bug (mit Severity S1–S4) |
| `testXX` | Test (verweist auf Akzeptanzkriterium) |
| `adrXX` | Architektur-Entscheidung |
| `relXX` | Release |

---

## Repo-Aufbau

```
eLeDia.OS_DevFlow/
├── 00-master.md         Eintrittspunkt: Rollen, ADRs, Prompts
├── 01-features.md       Was wird gebaut, Akzeptanzkriterien, Releases
├── 02-user-doc.md       Bedienung
├── 03-dev-doc.md        Implementierung
├── 04-tasks.md          Tasks, Klärungen
├── 05-quality.md        Bugs, Tests
├── Skills/              generisches Framework-Wissen
├── Playbooks/           projekt-spezifische Deploy-Mechanik
├── examples/            Anschauungsmaterial (kein Live-Stand)
└── README.md            (dieses Dokument)
```

## Projekt-DevFlows

Konkrete Projekte können die fünf Perspektiven als eigenen Projektordner spiegeln:

- `Projects/tool_eledia_admin-assist/` — Moodle Admin-Tool für zentrale Admin-Todos und Schnellzugriffe

---

## Einstieg für eine neue Session

1. `00-master.md` lesen.
2. `04-tasks.md` öffnen — Tasks und offene `qXX` sichten.
3. Bei Moodle-Themen: passenden Skill in `Skills/` lesen.
4. `#status` an die KI, um den aktuellen Stand zusammenfassen zu lassen.
5. `#next` für die nächsten 1–3 sinnvollsten Schritte.

---

## Loop, nicht Linie

> Implementierung allein ist keine Fertigstellung.
> Ein Feature ist erst fertig, wenn es **verstanden, nutzbar und wartbar** ist.

---
