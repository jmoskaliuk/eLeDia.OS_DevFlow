---
name: moodle-cs
description: >
  Moodle Coding Style (PHP_CodeSniffer-Rulesets aus moodlehq/moodle-cs). Verwende
  diesen Skill für alles rund um Moodle-PHP-Linting und Coding-Standards: phpcs /
  phpcbf ausführen, Findings interpretieren und beheben, das `moodle`- vs.
  `moodle-extra`-Ruleset konfigurieren, `.phpcs.xml`/`phpcs.xml` aufsetzen,
  Drittanbieter-Code per `grunt ignorefiles` ausnehmen, einzelne Sniffs
  unterdrücken (`phpcs:ignore`/`phpcs:disable`) und das Linting in moodle-plugin-ci
  bzw. GitHub Actions einbinden. Trigger bei: "moodle-cs", "phpcs", "phpcbf",
  "Coding Style", "Coding Standards", "Sniff", "codechecker", "MoodleInternal",
  "MissingDocblock", "Boilerplate", "PSR-12 Moodle", "Line too long", "ValidVariableName",
  "ValidFunctionName", "@covers", "TestCaseNames", oder jeder PHP_CodeSniffer-Meldung
  mit Präfix `moodle.`. Pair mit `moodle-dev`/`moodle-framework` für strukturelle
  API-Fragen und mit `moodle-plugin-submit` für die QA-Prechecks vor Einreichung.
---

# Moodle Coding Style — `moodlehq/moodle-cs`

Authoritative Referenz für die **Moodle PHP Coding Standards**, ausgeliefert als
PHP_CodeSniffer (phpcs) Rulesets im Paket [`moodlehq/moodle-cs`](https://github.com/moodlehq/moodle-cs).
Dieses Paket ist die *einzige* offiziell unterstützte Quelle der Moodle-Coding-Style-Sniffs;
es ersetzt das alte `local_codechecker`/`moodlehq/moodle-local_codechecker`.

**Quellen**
- Repo: https://github.com/moodlehq/moodle-cs
- Packagist: https://packagist.org/packages/moodlehq/moodle-cs
- Coding-Style-Policy: https://moodledev.io/general/development/policies/codingstyle
- PHPDoc-Policy: https://moodledev.io/general/development/policies/codingstyle/phpdoc

**Stand:** moodle-cs **v3.7.x** (2025). Baut auf `squizlabs/php_codesniffer ^3.13`,
`phpcsstandards/phpcsextra ^1.4` und PHP ≥ 7.4. PHPCompatibility ist in aktuellen
Versionen **deaktiviert** (kommt erst mit PHP_CodeSniffer 4 zurück).

---

## 1. Was steckt drin — zwei Rulesets

| Ruleset | Zweck | Wann nutzen |
|---|---|---|
| `moodle` | Der Standard-Coding-Style, den Moodle Core und die offizielle CI durchsetzen. | **Default** für jedes Plugin. Das, was die QA-Bots im Plugins Directory prüfen. |
| `moodle-extra` | `moodle` + zusätzliche *Best-Practice*-Regeln (z. B. Constant Visibility, statische DataProvider). | Für neue/strenge Codebasen, die über das Pflichtminimum hinausgehen wollen. Erweitert `moodle`. |

Das `moodle`-Ruleset ist im Kern **PSR-12 mit Moodle-spezifischen Ausnahmen** plus eine
Reihe eigener `moodle.*`-Sniffs und ausgewählter Regeln aus Generic/Squiz/PSR2/Universal/NormalizedArrays.

Wichtige bewusste Abweichungen von PSR-12 (im `moodle`-Ruleset ausgeschlossen):
- **Kein** camelCase erzwungen (Moodle erlaubt/erwartet `lower_snake` bei Funktionen).
- Eigene **Zeilenlängen**-Regel statt `Generic.Files.LineLength`.
- Öffnende Klammer von Klassen/Funktionen **in derselben Zeile** (K&R), nicht auf neuer Zeile.
- `else if` ist erlaubt.
- Eigener Sniff für Side-Effects (`MoodleInternal`) statt `PSR1.Files.SideEffects`.

Zusätzlich erzwungen (Auswahl): kurze Array-Syntax `[]` statt `array()`
(`Generic.Arrays.DisallowLongArraySyntax`), **trailing comma** in mehrzeiligen Arrays
(`NormalizedArrays.Arrays.CommaAfterLast`), kurze List-Syntax `[$a, $b] = …`,
lowercase `::class`, duplicate-array-key-Erkennung, alphabetische `extends`/`implements`.

---

## 2. Installation

### Variante A — global via Composer (lokales Entwickeln, empfohlen)

```shell
composer global config minimum-stability dev
composer global require moodlehq/moodle-cs
```

Das installiert phpcs **mit** den Moodle-Rules und allen Abhängigkeiten. Danach steht
`phpcs`/`phpcbf` global zur Verfügung (sicherstellen, dass `~/.composer/vendor/bin`
bzw. `~/.config/composer/vendor/bin` im `PATH` liegt). Der phpcs-Composer-Installer
registriert das `moodle`- und `moodle-extra`-Standard automatisch:

```shell
phpcs -i        # sollte "moodle" und "moodle-extra" in der Liste zeigen
```

### Variante B — pro Projekt via moodle-plugin-ci

In der CI ist moodle-cs bereits enthalten. `moodle-plugin-ci phpcs` ruft den
`moodle`-Standard auf das Plugin an. Siehe Abschnitt 8.

### Variante C — als dev-dependency im Plugin

```shell
composer require --dev moodlehq/moodle-cs
```

Nicht zwingend nötig; nützlich, wenn man phpcs reproduzierbar pinnen will.

---

## 3. Konfiguration

### Moodle ab 3.11

Aktuelle Moodle-Versionen liefern selbst eine phpcs-Konfiguration mit, die den
`moodle`-Standard setzt, sobald phpcs **innerhalb eines Moodle-Verzeichnisses**
läuft. Meist ist also **keine** eigene Konfig nötig.

Drittanbieter-/Library-Code (thirdpartylibs) soll **nicht** geprüft werden. Die
passende Ignore-Konfiguration wird automatisch generiert:

```shell
npx grunt ignorefiles
```

Das erzeugt/aktualisiert die `phpcs.xml` mit den korrekten `<exclude-pattern>`-Einträgen.

### `moodle-extra` aktivieren

Empfohlener Weg ab Moodle 3.11: eine `.phpcs.xml` anlegen, die die generierte
`phpcs.xml` lädt und `moodle-extra` obendrauf legt:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<ruleset name="MoodleCore">
  <rule ref="./phpcs.xml"/>
  <rule ref="moodle-extra"/>
</ruleset>
```

### Moodle 3.10 und älter

Eine `phpcs.xml` von Hand anlegen:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<ruleset name="MoodleCore">
  <rule ref="moodle"/>      <!-- oder: moodle-extra -->
</ruleset>
```

(In diesen Versionen wird Drittanbieter-Code nicht automatisch ignoriert.)

### Eigenes Plugin-Ruleset (selektives Tuning)

In einem Plugin kann man Regeln gezielt anpassen — aber **sparsam**, sonst weicht
man vom Standard ab, den die QA-Bots prüfen:

```xml
<?xml version="1.0"?>
<ruleset name="mod_leitnerquiz">
  <rule ref="moodle"/>

  <!-- Beispiel: einen einzelnen Sniff projektweit unterdrücken -->
  <rule ref="moodle.Commenting.MissingDocblock.Missing">
    <severity>0</severity>
  </rule>

  <!-- Beispiel: Pfade ausnehmen -->
  <exclude-pattern>*/tests/fixtures/*</exclude-pattern>
  <exclude-pattern>*/vendor/*</exclude-pattern>
</ruleset>
```

---

## 4. phpcs / phpcbf ausführen

```shell
# Lint eines ganzen Plugins gegen den Moodle-Standard
phpcs --standard=moodle /pfad/zu/mod/leitnerquiz

# Strenger (Best Practices)
phpcs --standard=moodle-extra /pfad/zu/mod/leitnerquiz

# Auto-Fix der automatisch behebbaren Findings
phpcbf --standard=moodle /pfad/zu/mod/leitnerquiz
```

Nützliche Flags:

| Flag | Wirkung |
|---|---|
| `-s` | Zeigt den **Sniff-Code** zu jeder Meldung (z. B. `moodle.Files.LineLength.MaxExceeded`). Praktisch immer mitgeben. |
| `-p` | Fortschritts-Anzeige. |
| `--report=full|summary|source|diff` | Report-Format. `source` listet, welche Sniffs wie oft feuern; `diff` zeigt die phpcbf-Änderungen. |
| `--report-file=phpcs.txt` | Report in Datei schreiben. |
| `--extensions=php` | Nur PHP prüfen (Standard im `moodle`-Ruleset). |
| `--ignore=*/vendor/*,*/node_modules/*` | Pfade ausnehmen. |
| `--sniffs=...` / `--exclude=...` | Nur bestimmte / bestimmte-außer Sniffs laufen lassen. |
| `-vv` | Debug: zeigt, welche Tokens welche Sniffs auslösen (zum Verstehen kniffliger Findings). |

**Wichtig zu phpcbf:** Nicht alle Sniffs sind auto-fixbar. moodle-cs hat
absichtlich die Auto-Fixes für **Naming-Sniffs deaktiviert** (`ValidFunctionName`,
`ValidVariableName`), weil phpcbf dort Legacy-Code zerstören würde. Diese Findings
**immer von Hand** beheben.

---

## 5. Sniff-Referenz — die `moodle.*`-Sniffs

Jeder Sniff hat einen Code `moodle.<Kategorie>.<SniffName>.<MessageCode>`. Mit `-s`
zeigt phpcs den vollen Code, mit dem man gezielt unterdrücken oder nachschlagen kann.

### Commenting / PHPDoc
| Sniff | Prüft | Fix |
|---|---|---|
| `moodle.Commenting.MissingDocblock` | Dateien, Klassen, Interfaces, Traits, Enums und Funktionen/Methoden müssen einen Docblock haben. | teils |
| `moodle.Commenting.DocblockDescription` | Haupt-Scope-Docblocks brauchen eine (einzeilige) Beschreibung. | nein |
| `moodle.Commenting.FileExpectedTags` | Datei- bzw. Artefakt-Docblock braucht passende Tags (`@copyright`, `@license`, …). | teils |
| `moodle.Commenting.ValidTags` | Nur gültige/erlaubte Docblock-Tags; warnt vor falschen wie `@returns`, `@throw`. | teils |
| `moodle.Commenting.VariableComment` | `@var`-Docblocks bei Properties: Typ (akzeptiert `int` statt `integer`), Reihenfolge, keine Duplikate. Erlaubt `@since`, `@link`, `@deprecated`. | teils |
| `moodle.Commenting.InlineComment` | Inline-Kommentare: Stil (`//`), beginnt großgeschrieben, kein leerer Kommentar, kein PHPDoc-Stil inline. | teils |
| `moodle.Commenting.ConstructorReturn` | Konstruktoren dürfen kein `@return` im Docblock haben. | nein |
| `moodle.Commenting.TodoComment` | `TODO`/`@todo` brauchen einen Tracker-Issue-Verweis (konfigurierbares Muster, z. B. `MDL-xxxxx`). | nein |
| `moodle.Commenting.Category` / `moodle.Commenting.Package` | `@category`/`@package`-Tag-Validität. | nein |

### Files
| Sniff | Prüft | Fix |
|---|---|---|
| `moodle.Files.BoilerplateComment` | Jede Datei beginnt mit dem Standard-**GPLv3-Boilerplate**-Header (exakter Wortlaut). | nein |
| `moodle.Files.MoodleInternal` | Nach den Includes muss `defined('MOODLE_INTERNAL') || die();` stehen — oder die Datei bindet `config.php` ein bzw. hat keine Side-Effects. Klassischer "moodle internal not defined". | teils |
| `moodle.Files.LineLength` | Zeilen max. **180** Zeichen (Error), Soll **132** (Warning). Lang-Strings ausgenommen. | nein |
| `moodle.Files.RequireLogin` | Heuristik: Skripte sollen Login-Checks (`require_login`/`require_course_login`) enthalten. | nein |
| `moodle.Files.LangFilesOrdering` | `lang/*`-Dateien: String-Keys alphabetisch sortiert. | nein |

### Naming Conventions
| Sniff | Prüft | Fix |
|---|---|---|
| `moodle.NamingConventions.ValidFunctionName` | Funktionsnamen lower-case; Methodennamen ohne camelCase; korrekte Magic-Method-Schreibweise. | **nein (bewusst)** |
| `moodle.NamingConventions.ValidVariableName` | Variablen/Properties: lower-case, **keine** Underscores in `$camelCase`-Members; Member-Sichtbarkeit. | **nein (bewusst)** |

### PHP
| Sniff | Prüft | Fix |
|---|---|---|
| `moodle.PHP.ForbiddenFunctions` | Debug-/verbotene Funktionen im Fertigcode (`print_r`, `var_dump`, `error_log`, `eval`, …). | teils |
| `moodle.PHP.DeprecatedFunctions` | Nutzung Moodle-deprecateder Funktionen → Ersatz vorschlagen. | nein |
| `moodle.PHP.ForbiddenGlobalUse` | `global $PAGE`/`$OUTPUT` in Renderern, `global $PAGE` in Blocks. | nein |
| `moodle.PHP.ForbiddenTokens` | Verbotene Tokens/Operatoren (z. B. error-suppression `@`, `goto`, backtick-exec). | nein |
| `moodle.PHP.IncludingFile` | `require_once` regulär, `include_once` nur konditional; Klammern um den Pfad. | teils |
| `moodle.PHP.MemberVarScope` | Klassen-Properties brauchen Sichtbarkeits-Modifier (`public`/`protected`/`private`). | nein |

### Control Structures / Methods / Namespaces / Strings / WhiteSpace
| Sniff | Prüft | Fix |
|---|---|---|
| `moodle.ControlStructures.ControlSignature` | Schreibweise/Whitespace von `if/else/for/foreach/while/try` etc. | ja |
| `moodle.Methods.MethodDeclarationSpacing` | Korrektes Whitespace in Methoden-Deklarationen. | ja |
| `moodle.Namespaces.NamespaceStatement` | Korrektes `namespace`-Statement. | teils |
| `moodle.Strings.ForbiddenStrings` | Strings, die auf falsche API-Nutzung hindeuten. | nein |
| `moodle.WhiteSpace.SpaceAfterComma` | Genau ein Space nach Komma. | ja |
| `moodle.WhiteSpace.WhiteSpaceInStrings` | Kein Trailing-Whitespace am Zeilenende, keine Tabs im String. | ja |

### PHPUnit (Tests)
| Sniff | Prüft | Fix |
|---|---|---|
| `moodle.PHPUnit.TestCaseNames` | Testklasse heißt wie die Datei und endet auf `_test`; Datei `*_test.php`. | teils |
| `moodle.PHPUnit.TestCaseCovers` / `…CaseProvider` / `…ReturnType` / `AbstractTestCase` | `@covers`/`@coversNothing` korrekt gesetzt; DataProvider existieren, sind nicht privat, kein `_test`-Präfix, korrekte Groß-/Kleinschreibung, geben Array/Iterable zurück; Test-Methoden-Returntype `void`. | teils |
| `moodle.PHPUnit.ParentSetUpTearDown` | `setUp()`/`tearDown()` rufen `parent::…` auf. | nein |
| `moodle.PHPUnit.TestCasesAbstract` / `TestClassesFinal` | Basis-Testcases `abstract`, konkrete Testklassen `final`. | teils |

> **Tipp:** Die vollständige, immer aktuelle Liste der Message-Codes steht in den
> Sniff-Klassen unter `moodle/Sniffs/**/`*Sniff.php` und den Fixtures unter
> `moodle/Tests/fixtures/`. Bei unklaren Findings dort den Code nachschlagen.

---

## 6. `moodle-extra` — Zusatzregeln

`moodle-extra` lädt `moodle` und ergänzt u. a.:
- `PSR12.Properties.ConstantVisibility.NotFound` als **Warning** (im `moodle`-Standard auf Severity 0): Klassenkonstanten sollen eine Sichtbarkeit bekommen.
- `moodle.PHPUnit.TestCaseProvider` mit `autofixStaticProviders=true`: DataProvider werden — wo möglich — automatisch in **statische** Methoden umgewandelt (PHPUnit-10-Kompatibilität).

Nutze `moodle-extra` für neuen Code; für Bestandscode kann es viele zusätzliche
Warnings erzeugen, die nicht alle pflichtig sind.

---

## 7. Findings unterdrücken (sparsam!)

phpcs-Inline-Annotationen, wenn ein Finding bewusst akzeptiert wird:

```php
// Eine einzelne Zeile ausnehmen:
$x = some_legacy_thing(); // phpcs:ignore moodle.PHP.ForbiddenFunctions.Found

// Einen Block ausnehmen:
// phpcs:disable moodle.Commenting.MissingDocblock.Missing
class Legacy_Thing { /* ... */ }
// phpcs:enable moodle.Commenting.MissingDocblock.Missing

// Ganze Datei (z. B. generierter Code):
// phpcs:ignoreFile
```

Immer **mit konkretem Sniff-Code** unterdrücken, nie pauschal. Jede Unterdrückung
braucht einen guten Grund (am besten als Kommentar dahinter). Die QA-Bots zählen
unterdrückte Pflicht-Sniffs ggf. trotzdem — also lieber den Code fixen.

---

## 8. CI-Integration

### moodle-plugin-ci

```yaml
# Auszug GitHub-Actions-Job
- name: PHP CodeSniffer (Moodle standard)
  run: moodle-plugin-ci phpcs --max-warnings 0
```

`moodle-plugin-ci phpcs` nutzt intern moodle-cs und meldet Findings als
Annotations im PR. `--max-warnings 0` lässt den Job auch bei Warnings fehlschlagen
(empfohlen für saubere Plugins).

### Direkt mit phpcs in CI

```yaml
- run: composer global require moodlehq/moodle-cs
- run: ~/.composer/vendor/bin/phpcs --standard=moodle --report=full -s mod/leitnerquiz
```

### Lokaler Pre-Commit (Schnellschleife)

```shell
phpcbf --standard=moodle . ; phpcs --standard=moodle -s .
```

Erst `phpcbf` (auto-fix), dann `phpcs -s` für den Rest, der von Hand muss.

---

## 9. Beziehung zu den anderen Skills / Guardrails

- Für **Plugin-Architektur, APIs, XMLDB, Events/Hooks** → `moodle-dev.md` / `moodle-framework.md`. moodle-cs prüft *Stil*, nicht *Korrektheit*.
- Vor **Submission ins Plugins Directory** → `moodle-plugin-submit.md`; die QA-Prechecks dort = im Wesentlichen der `moodle`-Standard. Plugin muss `phpcs --standard=moodle` sauber durchlaufen.
- Für **UI/Frontend** ist moodle-cs irrelevant (nur PHP). JS/CSS-Linting läuft über grunt/eslint/stylelint, nicht über moodle-cs.

**Guardrails**
- Immer gegen `moodle` (Pflicht) prüfen; `moodle-extra` ist Kür.
- Naming-Findings nie mit phpcbf "fixen" — Auto-Fix ist dort bewusst aus.
- Drittanbieter-Code via `grunt ignorefiles` / `exclude-pattern` ausnehmen, nicht einzeln unterdrücken.
- Version mitdenken: moodle-cs entwickelt sich; bei unerwarteten neuen Findings die `CHANGELOG.md` des Repos prüfen.
- Den exakten **GPLv3-Boilerplate-Header** nie umformulieren — `moodle.Files.BoilerplateComment` verlangt den Wortlaut zeichengenau.

---

## Quick-Reference

```shell
# Setup (einmalig)
composer global config minimum-stability dev
composer global require moodlehq/moodle-cs
phpcs -i                                   # "moodle", "moodle-extra" prüfen

# Arbeiten
phpcs  --standard=moodle -s -p PFAD        # prüfen, mit Sniff-Codes
phpcbf --standard=moodle      PFAD         # auto-fixen (außer Naming)
phpcs  --standard=moodle --report=source PFAD   # welche Sniffs feuern wie oft

# Drittanbieter ausnehmen
npx grunt ignorefiles
```
