---
name: moodle-glossar
description: >-
  Verbindliches EN/DE-Glossar für Moodle-Sprachdateien der eLeDia/LernHive-Plugins.
  Verwende diesen Skill, sobald du Strings in lang/en oder lang/de anlegst, änderst
  oder übersetzt — also bei jeder Arbeit an Moodle-Sprachdateien, bei Reviews von
  Übersetzungen und bei der Frage, wie ein Begriff auf Deutsch heißen muss.
  Trigger: "lang/de", "lang/en", "Sprachdatei", "Übersetzung", "get_string",
  "$string[", "Glossar", "Terminologie", "AMOS".
---

# Moodle-Glossar (eLeDia/LernHive)

Verbindliche Terminologie für alle Moodle-Plugins der Suite. Das Glossar selbst
steht in [references/GLOSSAR.md](references/GLOSSAR.md).

## Grundregeln

1. **Moodle-Core ist bindend.** Steht ein Begriff im Glossar mit Quelle
   `core_*`, gilt die dortige deutsche Entsprechung — ohne Ausnahme und ohne
   plugin-eigene Variante. Maßgeblich ist das offizielle Langpack, nicht das
   eigene Sprachgefühl.
2. **Eine Entsprechung je Begriff.** Ein englischer Begriff hat genau eine
   deutsche Übersetzung in der gesamten Suite. Abweichungen sind Konflikte und
   werden im Glossar entschieden, nicht im Plugin.
3. **`lang/en` ist die Quelle der Wahrheit**, `lang/de` ist die Übersetzung.
   Neue Strings immer zuerst in EN.
4. **Sie-Form.** Alle deutschen UI-Strings (Labels, Buttons, Hinweise,
   Fehlermeldungen, Hilfetexte) verwenden die Sie-Form.
   Ausgenommen sind LLM-System-Prompts (Text, der an das Sprachmodell geht) und
   Strings, die an H5P-Content-Types durchgereicht werden — dort gilt die
   Konvention der Zielumgebung.
5. **Echte Umlaute und ß.** Niemals `ue`/`oe`/`ae`/`ss` als Ersatzschreibung.
6. **Englisch nach Moodle-Konvention:** Sentence case; kein Satzpunkt bei
   Labels, Buttons und Überschriften; ganze Sätze (Fehlermeldungen,
   Beschreibungen, Hilfetexte) bekommen einen Punkt; keine Anrede-Floskeln.

## Vorgehen beim Übersetzen

1. Begriff in [references/GLOSSAR.md](references/GLOSSAR.md) nachschlagen.
2. Kein Treffer? Prüfen, ob Moodle-Core den Begriff kennt
   (`~/.cache/moodle-langpack/<version>/{en,de}/<component>.php`). Wenn ja: die
   Core-Entsprechung verwenden **und** den Begriff mit Quelle `core_<component>`
   ins Glossar aufnehmen.
3. Auch dort kein Treffer? Eigene Entsprechung festlegen, konsistent zum
   restlichen Wortfeld, und mit Quelle `Plugin` ins Glossar aufnehmen.
4. Platzhalter (`{$a}`, `{$a->x}`) müssen in EN und DE identisch sein — gleiche
   Anzahl, gleiche Namen.

## Wann ein Plugin-String gar nicht angelegt wird

Existiert in `core` (also `moodle.php`) ein semantisch deckungsgleicher String,
wird kein eigener Plugin-String angelegt, sondern `get_string('key')` verwendet.
Strings **anderer Plugins** werden nicht wiederverwendet — das erzeugt eine
Abhängigkeit, die Moodle nicht garantiert.

## AMOS

**Jedes Plugin führt ein `lang/de` im Repository — auch wenn es im
Moodle-Plugins-Verzeichnis veröffentlicht ist.** Die Repo-Fassung ist die
verbindliche deutsche Übersetzung und unabhängig von AMOS. (Entscheidung
Johannes, 2026-07-26; die frühere Regel „veröffentlicht → nur AMOS" gilt nicht
mehr.)

Praktische Folgen:

- Eine fehlende `lang/de` ist ein Befund, kein Sonderfall.
- Bei Plugins mit fremdem Upstream (z. B. `qtype_aitext` von marcusgreen,
  `tool_dynamic_cohorts` von Catalyst) erzeugt die Repo-Übersetzung Fork-Drift:
  Beim nächsten Upstream-Merge muss `lang/de` gegen die dann aktuelle `lang/en`
  geprüft werden — neue EN-Keys nachziehen, umbenannte Keys mitziehen,
  entfernte Keys löschen.
- Weicht die AMOS-Übersetzung ab, gewinnt die Repo-Fassung plus dieses Glossar.

## Pflege

- Glossar immer **mergen**, nie überschreiben. Alphabetisch sortiert halten.
- Jede Konfliktentscheidung im Abschnitt „Entschiedene Konflikte" mit Datum und
  Begründung dokumentieren.
