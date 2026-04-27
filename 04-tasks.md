# Tasks

## Meta

Dies ist das **operative Zentrum** des Systems.

Es enthält:
- neue Beobachtungen
- Tasks (`taskXX`)
- offene Klärungen (`qXX`)
- aktive Arbeit
- Verifikations-Schritte

**Jede Session beginnt hier.**

---

## 🆕 Neu

(Unstrukturierter Input erlaubt — wandert nach Triage in `taskXX` oder `qXX`.)

---

## ❓ Klärung benötigt

Offene Fragen, die Fortschritt blockieren. ID-Format: `qXX`.

### Vorlage

```
### qXX Frage in einem Satz
Linked: featXX / taskXX
Asked-by: KI | Mensch
Status: open | answered
Answer: (wird beim Schließen ergänzt; Antwort wandert dann in das passende Doc)
```

---

## 📋 Tasks

### Vorlage

```
### taskXX Titel des Tasks
Status:    open | in_progress | done
Feature:   featXX
Priorität: P0 | P1 | P2 | P3
Linked:    bugXX (optional), qXX (optional)

**Ziel**
Was soll am Ende stehen?

**Schritte**
1. ...
2. ...

**Erwartetes Ergebnis**
Wie erkennt man Fertigstellung?

**Done-Checkliste** (vor Verschieben nach ✅ Done)
- [ ] 01-features.md aktualisiert (falls Verhalten geändert)
- [ ] 02-user-doc.md aktualisiert (falls UX geändert)
- [ ] 03-dev-doc.md aktualisiert (immer bei Code-Änderung)
- [ ] testXX in 05-quality.md grün
- [ ] PO Sign-off
```

### Prioritäten

| Stufe | Bedeutung |
|---|---|
| **P0** | Blocker — nichts anderes kann sinnvoll vorangehen |
| **P1** | Kern-Feature, geplante Iteration |
| **P2** | wichtig, aber nicht blockierend |
| **P3** | nice-to-have, Backlog |

---

## 🔧 In Progress

Tasks, an denen aktuell gearbeitet wird. Hier landen Tasks, sobald die KI mit `#implement` startet.

---

## 🔎 Verifikation nach Deploy

Verifikations-Items für die letzte Auslieferung. Nach erfolgreicher Verifikation → in den jeweiligen Task „PO Sign-off" abhaken und nach „✅ Done" verschieben.

---

## ✅ Done

Erledigte Tasks. Nicht löschen — sie sind die Historie der Entscheidungen.

---

## ✅ Geklärt

Beantwortete `qXX`. Antworten sind ins jeweilige Doc übernommen.

---

## Regeln

- Eingaben in „🆕 Neu" werden zeitnah in `taskXX` oder `qXX` umgewandelt.
- Tasks klein und ausführbar halten.
- Erledigte Items **nicht löschen**, sondern verschieben.
- Klärungen nicht im Chat versanden lassen → immer als `qXX` festhalten.
- Status-Änderungen passieren genau hier — nicht in `01-features.md`.

---

## Grundprinzip

> Was nicht hier steht, passiert nicht.
