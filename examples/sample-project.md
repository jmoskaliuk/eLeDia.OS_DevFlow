# Beispielprojekt — „Popup & Navigation"

> **Zweck dieses Dokuments**
> Demo-Daten für eLeDia.OS_DevFlow. Zeigt, wie sich ein konkretes Projekt
> in Tasks (`04-tasks.md`), Bugs und Tests (`05-quality.md`) niederschlägt.
>
> **Hinweis:** Der eigentliche Projekt-Repo verwendet `04-tasks.md` und
> `05-quality.md` selbst — die hier gezeigten Einträge sind frei erfunden
> und dienen nur der Anschauung.

---

## Beispiel-Tasks (würden in `04-tasks.md` stehen)

### task01 Popup-Steuerung implementieren
Status: done
Feature: feat01
Priorität: P1

---

### task02 Navigation implementieren
Status: done
Feature: feat02
Priorität: P1

---

### task03 Popup-Sync-Bug fixen
Status: open
Feature: feat01
Priorität: P0
Linked-Bug: bug01

---

## Beispiel-Bug (würde in `05-quality.md` stehen)

### bug01 Popup desync

Feature: feat01
Severity: S2
Status: open

**Beschreibung**
Popup synchronisiert sich nicht mit der View.

**Reproduktion**
1. Popup öffnen
2. navigieren
3. Mismatch tritt auf

**Erwartet**
Popup spiegelt den View-Zustand.

---

## Beispiel-Test (würde in `05-quality.md` stehen)

### test01 Popup-Sync-Test

Feature: feat01
Akzeptanzkriterium: feat01.AC02
Ergebnis: failed

**Schritte**
- Popup öffnen
- vorwärts navigieren

**Beobachtung**
Desync erkannt.
