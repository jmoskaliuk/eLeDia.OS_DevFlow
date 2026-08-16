# Glossar EN/DE — eLeDia/LernHive Moodle-Plugins

Verbindliche Terminologie. Regeln und Vorgehen: [SKILL.md](../SKILL.md).

Spalte **Quelle**: `core_<component>` = aus dem Moodle-Langpack übernommen und
damit bindend; `Plugin` = suite-eigener Begriff, im Glossar entschieden.

Referenz: Moodle-Langpack 5.2 (`~/.cache/moodle-langpack/5.2/`).
Stand: 2026-07-26.

## A–Z

| Begriff EN | Begriff DE | Definition | Quelle | Verwendet in |
| --- | --- | --- | --- | --- |
| Actions | Aktionen | Spaltenkopf für Zeilenaktionen in Tabellen | core_moodle | tool_taskrunner |
| Activity | Aktivität | Moodle-Aktivität in einem Kurs | core_moodle | suiteweit |
| Ad hoc task | Ad-hoc-Task | Einmalig eingeplanter Hintergrund-Task | core_tool_task | tool_taskrunner |
| AI | KI | Künstliche Intelligenz; im Deutschen durchgängig „KI", nicht „AI" | Plugin | suiteweit |
| AI audit | KI-Audit | Auditbericht über KI-Nutzung in der Suite | Plugin | local_lernhive_ai |
| AI chat | KI-Chat | Chat-Oberfläche gegen ein Sprachmodell | Plugin | mod_aichat, local_lernhive_ai, local_lernhive_strategy |
| AI provider | KI-Anbieter | Über `core_ai` konfigurierter Anbieter für Textgenerierung | core_ai | suiteweit |
| AI tutor | KI-Tutor | Tutor-Block der Suite | Plugin | block_eledia_aitutor, local_lernhive_ai, local_ragingest |
| API key | API-Schlüssel | Zugangsschlüssel für einen externen Dienst | Plugin | filter_eledia_translate, local_literag, local_ragingest |
| Back | Zurück | Navigation einen Schritt zurück | core_moodle | suiteweit |
| Back (of a card) | Rückseite | Rückseite einer Lernkarte — nicht mit „Zurück" verwechseln | Plugin | local_h5pauthor |
| Cancel | Abbrechen | Abbruch ohne Speichern | core_moodle | suiteweit |
| Capability | Fähigkeit | Moodle-Berechtigung (`component:capability`) | core_role | suiteweit |
| Category | Kursbereich | Moodle-Kursbereich | core_moodle | suiteweit |
| Cohort | Globale Gruppe | Site- oder bereichsweite Nutzergruppe. Nicht „Kohorte" | core_cohort | tool_dynamic_cohorts |
| Coming soon | In Vorbereitung | Funktion angekündigt, aber noch nicht verfügbar | Plugin | local_lernhive_ai, local_lernhive_strategy, local_lernhive_teacher_tools |
| Condition | Bedingung | Einzelkriterium einer Regel | core_moodle | tool_dynamic_cohorts |
| Content bank | Inhaltsspeicher | Moodle-Inhaltsspeicher | core_contentbank | local_h5pauthor |
| Context | Kontext | Moodle-Kontext (System, Kurs, Modul) | core_moodle | suiteweit |
| Course | Kurs | Moodle-Kurs | core_moodle | suiteweit |
| Course ID | Kurs-ID | Numerische Kurs-ID | core_feedback | filter_eledia_translate, local_ragingest |
| Default | Standard | Voreinstellung | core_moodle | suiteweit |
| Delete | Löschen | Endgültiges Entfernen | core_moodle | suiteweit |
| Deleted user | Gelöschtes Nutzerkonto | Platzhalter für ein entferntes Nutzerkonto | core_bulkusers | mod_elli |
| Description | Beschreibung | Freitextbeschreibung | core_moodle | suiteweit |
| Details | Details | Detailansicht/-spalte | core_moodle | local_ragingest |
| Disable / Disabled | Deaktivieren / Deaktiviert | Funktion ausschalten bzw. ausgeschaltet — nicht „ausgeschaltet" | core_moodle, core_admin | suiteweit |
| Edit | Bearbeiten | Bearbeitungsmodus öffnen | core_moodle | suiteweit |
| Enable / Enabled | Aktivieren / Aktiviert | Funktion einschalten bzw. eingeschaltet — nicht „eingeschaltet" | core_moodle, core_admin | suiteweit |
| Entries | Einträge | Listeneinträge | core_moodle | filter_eledia_translate |
| Error | Fehler | Fehlerzustand | core_moodle | suiteweit |
| Fail delay | Fehlerverzögerung | Wartezeit vor dem nächsten Versuch eines fehlgeschlagenen Tasks | core_tool_task | tool_taskrunner |
| Failed | Fehlgeschlagen | Endzustand eines nicht erfolgreichen Laufs | Plugin | tool_taskrunner, local_lernhive_ai, mod_aifeedback |
| Feedback | Rückmeldung | Rückmeldung an Lernende. Ausnahme: als Produktname („eLeDia.ai \| Feedback") und als Moodle-Modulname bleibt „Feedback" stehen | core_moodle | mod_aifeedback |
| File | Datei | Datei | core_moodle | suiteweit |
| Free text | Freitext | Offene Texteingabe. Auch im Produktnamen: „eLeDia.ai \| Freitext" (Ausnahme von der Regel, Produktnamen unübersetzt zu lassen — suiteweit etabliert) | Plugin | qtype_aitext, local_lernhive_ai, local_h5pauthor |
| Guardrail | Leitplanke | Inhaltliche Begrenzung für Modellantworten. Im Fachbegriff `guardrail prompt` bleibt „Guardrail-Prompt" | Plugin | mod_elli |
| History tool | Verlaufs-Tool | Werkzeug, mit dem das Modell den Gesprächsverlauf abruft | Plugin | block_eledia_aitutor, local_literag |
| Language | Sprache | Sprache/Sprachpaket | core_moodle | suiteweit |
| Last run | Letzte Ausführung | Zeitpunkt des letzten Task-Laufs — nicht „Letzter Lauf" | core_tool_task | tool_taskrunner |
| Logging | Protokollierung | Vorgang des Protokollierens. Für die Log-Daten selbst nutzt Core „Logdaten" | Plugin | filter_eledia_translate, local_literag |
| Logging verbosity | Protokollierungsdetailgrad | Detailtiefe der Protokollierung | Plugin | block_eledia_aitutor, local_literag |
| MCP external service | Externer MCP-Service | In Moodle angelegter externer Dienst für das MCP-Plugin | Plugin | block_eledia_aitutor, webservice_elediamcp |
| Memory opt-in tool | Gedächtnis-Zustimmungs-Tool | Werkzeug, über das Lernende der Speicherung zustimmen | Plugin | block_eledia_aitutor, local_literag |
| Missing | Fehlt | Zustand „nicht vorhanden" in Statusanzeigen | Plugin | block_eledia_aitutor, filter_eledia_translate |
| Next | Weiter | Navigation einen Schritt vorwärts | core_moodle | suiteweit |
| Next run | Nächste Ausführung | Geplanter nächster Task-Lauf — nicht „Nächster Lauf" | core_tool_task | tool_taskrunner |
| Number of questions | Anzahl Fragen | Anzahl zu erzeugender Fragen | Plugin | local_lernhive_questiongen, local_lernhive_strategy |
| Overview | Übersicht | Einstiegs-/Sammelansicht | Plugin | local_lernhive_ai, local_ragingest, filter_eledia_translate |
| Preview | Vorschau | Vorschau vor dem Speichern | core_moodle | suiteweit |
| Prompt | Prompt | Eingabe an das Sprachmodell. Nicht „Eingabeaufforderung" | Plugin | suiteweit |
| Prompt starters | Vorgeschlagene Fragen | Vorgefertigte Einstiegsfragen im Chat | Plugin | block_eledia_aitutor |
| Question | Frage | Einzelne Frage | core_moodle | suiteweit |
| Question bank | Fragensammlung | Moodle-Fragensammlung | core_question | qbank_lernhive_questiongen, local_lernhive_questiongen |
| Question type | Fragetyp | Moodle-Fragetyp | core_question | local_lernhive_questiongen |
| Reason | Grund | Grund für einen Zustand (z. B. Fehler) | core_moodle | filter_eledia_translate |
| Reason (justification) | Begründung | Begründung einer KI-Empfehlung | Plugin | local_activityfilter |
| Request timeout | Anfrage-Timeout | Zeitlimit für eine Anfrage an einen externen Dienst | Plugin | block_eledia_aitutor, local_literag, local_ragingest |
| Retry | Neu versuchen | Erneuter Versuch nach einem Fehler | core_moodle | block_eledia_aitutor |
| Revoke (a token) | Widerrufen | Ein Token dauerhaft ungültig machen | Plugin | webservice_elediamcp |
| Rule | Regel | Regelwerk aus Bedingungen, das die Mitglieder einer globalen Gruppe bestimmt | Plugin | tool_dynamic_cohorts |
| Save | Speichern | Speichern | core_moodle | suiteweit |
| Save and continue | Speichern und weiter | Speichern und im Ablauf weitergehen | core_assign | filter_eledia_translate |
| Scheduled task | Geplanter Task | Periodisch laufender Hintergrund-Task | core_tool_task | tool_taskrunner |
| Search | Suchen | Suchaktion/-feld | core_moodle | suiteweit |
| Section | Abschnitt | Kursabschnitt | core_moodle | suiteweit |
| Service (web service) | Service | Externer Moodle-Webservice | core_webservice | webservice_elediamcp |
| Settings | Einstellungen | Einstellungsseite/-bereich | core_moodle | suiteweit |
| Source activity | Quellaktivität | Aktivität, aus der Inhalte übernommen werden | Plugin | local_h5pauthor, local_lernhive_questiongen, mod_aifeedback |
| Status | Status | Zustandsanzeige | core_moodle | suiteweit |
| Student | Teilnehmer/in | Lernende Person in einem Kurs. In Fließtext ist „Lernende" zulässig; als Rollenbezeichnung gilt der Core-Begriff | core_moodle | suiteweit |
| Submission | Abgabe | Abgabe einer Aufgabe | core_assign | mod_elli |
| Tags | Tags | Moodle-Tags | core_moodle | suiteweit |
| Task (background) | Task | Moodle-Hintergrund-Task | core_tool_task | tool_taskrunner |
| Task (learning) | Aufgabe | Arbeitsauftrag an Lernende — nicht mit dem Hintergrund-Task verwechseln | Plugin | mod_elli |
| Token | Token | Zugangs-Token für einen Webservice. Neutrum: „das Token", Plural „Tokens" | core_webservice | webservice_elediamcp |
| Token, create a | Token erstellen | Aktion auf der Token-Seite. Core sagt bei `webservice:createtoken` „Token erzeugen"; hier gewinnt die dateiinterne Konsistenz, weil zehn weitere Strings „erstellt" verwenden | Plugin | webservice_elediamcp |
| Tool (MCP) | Tool | Über MCP aufrufbare Moodle-Funktion. Nicht „Werkzeug" | Plugin | webservice_elediamcp, block_eledia_aitutor, local_literag |
| Topic | Thema | Inhaltliches Thema | core_moodle | local_lernhive_questiongen |
| Translate | Übersetzen | Übersetzungsvorgang | Plugin | filter_eledia_translate, local_lernhive_ai |
| User | Nutzer/in | Moodle-Nutzerkonto. Nicht „Benutzer" | core_moodle | suiteweit |
| User ID | Nutzer-ID | Numerische Nutzer-ID. Nicht „Benutzer-ID" | core_grades | filter_eledia_translate |
| Valid until | Gültig bis | Ablaufzeitpunkt eines Tokens | core_webservice | webservice_elediamcp |
| You (chat role) | Sie | Sprecherlabel für die eigene Person im Chat | Plugin | block_eledia_aitutor, block_lernhive_ai_chat, mod_aichat, mod_elli |

## Entschiedene Konflikte

Jeder Eintrag: festgelegte Variante, verworfene Variante(n), Begründung.

| Datum | Begriff EN | Festgelegt | Verworfen | Begründung |
| --- | --- | --- | --- | --- |
| 2026-07-26 | Cohort | Globale Gruppe | Kohorte | Core-Terminologie (`core_cohort`) ist bindend; „Kohorte" ist im Moodle-DE-UI nirgends belegt. |
| 2026-07-26 | Student | Teilnehmer/in | Schüler/in, Studierende | Core-Terminologie (`core_moodle`, Rolle `defaultcoursestudent`). Ausgenommen sind LLM-Prompts, deren Wortwahl die Modellantwort steuert. |
| 2026-07-26 | Free Text (Produktname) | eLeDia.ai \| Freitext | eLeDia.ai \| Free Text | Bewusste Ausnahme von der Produktnamen-Regel: die deutsche Fassung ist in `qtype_aitext` und `local_lernhive_ai` bereits durchgängig „Freitext". |
| 2026-07-26 | Tool (MCP) | Tool | Werkzeug | Etablierter Fachbegriff im MCP-Kontext, so auch in der deutschen Nutzerdoku von `webservice_elediamcp`. |
| 2026-07-26 | AI chat / AI audit / AI strategy helper / AI tutor | Durchgekoppelt mit Bindestrich („KI-Chat", „KI-Audit", „KI-Strategie-Helper", „KI-Tutor") | „KI Chat", „KI Audit", „KI Strategie-Helper", „AI Tutor" | Deutsche Rechtschreibung verlangt Durchkopplung; zusätzlich „KI" statt „AI" im gesamten deutschen UI. |
| 2026-07-26 | API key | API-Schlüssel | API-Key | Mehrheitsvariante in der Suite; deutsches Wort vorhanden. |
| 2026-07-26 | Coming soon | In Vorbereitung | Demnächst | Mehrheitsvariante (3 Plugins gegen 1) und aussagekräftiger. |
| 2026-07-26 | Disabled / Enabled | Deaktiviert / Aktiviert | Ausgeschaltet / Eingeschaltet | Core-Terminologie (`core_admin`) ist bindend. |
| 2026-07-26 | Fail delay | Fehlerverzögerung | Faildelay | Core-Terminologie (`core_tool_task`) ist bindend. |
| 2026-07-26 | Last run / Next run | Letzte Ausführung / Nächste Ausführung | Letzter Lauf / Nächster Lauf | Core-Terminologie (`core_tool_task`) ist bindend. |
| 2026-07-26 | Ad hoc tasks | Ad-hoc-Tasks | Adhoc Tasks | Core-Terminologie (`core_tool_task`) ist bindend, inkl. Durchkopplung. |
| 2026-07-26 | Number of questions | Anzahl Fragen | Fragenanzahl | Mehrheitsvariante und näher am englischen Original. |
| 2026-07-26 | Overview | Übersicht | Überblick | Gängige Moodle-Übersetzung für Navigationsziele. |
| 2026-07-26 | Prompt | Prompt | Eingabeaufforderung, Aufforderung | Etablierter Fachbegriff; „Eingabeaufforderung" ist im Deutschen mit der Kommandozeile belegt. |
| 2026-07-26 | Request timeout | Anfrage-Timeout | Request-Timeout | Mehrheitsvariante; nur der etablierte Anglizismus „Timeout" bleibt. |
| 2026-07-26 | Retry | Neu versuchen | Erneut versuchen, Wiederholen | Core-Terminologie (`core_moodle`) ist bindend. Ausgenommen: Strings, die an H5P-Content-Types durchgereicht werden. |
| 2026-07-26 | Source activity | Quellaktivität | Quell-Aktivität | Ein Kompositum, kein Bindestrich nötig. |
| 2026-07-26 | User / User ID | Nutzer/in, Nutzer-ID | Benutzer, Benutzer-ID | Core-Terminologie (`core_moodle`, `core_grades`) ist bindend. |
| 2026-07-26 | You (chat role) | Sie | Du | Sie-Form gilt für die gesamte deutsche UI der Suite. |
| 2026-07-26 | History tool name | Name des Verlaufs-Tools | Name des Verlauf-Tools | Korrekte Fugen-s-Bildung. |
| 2026-07-26 | The message text | Der Nachrichtentext | Der Text der Nachricht | Mehrheitsvariante (3 Plugins gegen 1), kompakter. |

## Bewusste Abweichungen von Core

| Begriff EN | Suite-DE | Core-DE | Begründung |
| --- | --- | --- | --- |
| Sync | Synchronisieren | Syncronisieren (`core_repository`) | Der Core-String enthält einen Tippfehler; die Suite verwendet die korrekte Schreibweise. |
| Actions | Aktionen | Aktivitäten (`core_badges`) | `core_badges` übersetzt den Begriff kontextspezifisch falsch; `core_moodle` hat „Aktionen". |
| File to import | Zu importierende Datei | Datei importieren (`core_glossary`) | Der Core-String ist eine Aktion, hier wird ein Feldlabel gebraucht. |

## Nicht übersetzt (Produkt- und Eigennamen)

`eLeDia.ai`, `LernHive`, `Elli`, `LiteRAG`, `RagIngest`, `Contenthub`,
`Model Context Protocol` / `MCP`, `DeepL`, `H5P`, sowie alle Varianten
`eLeDia.ai | <Produkt>`.
