# eLedia.OS — Master

## 1. Projekt-Meta
- **Name:** 
- **Ziel:** 
- **Kurzbeschreibung:** 
- **Tech Stack:** 

---

## 2. Session-Start (für KI)

1. Lies dieses Dokument vollständig
2. Lies `04-tasks.md`
3. Prüfe offene taskXX-Einträge
4. Lies relevante featXX-Einträge in `01-features.md`
5. Beginne mit höchstpriorisiertem Task

---

## 3. Dateisystem

| Datei | Zweck |
|------|------|
| 01-features.md | Was bauen wir und wie (Soll) |
| 02-user-doc.md | Nutzung aus Anwendersicht |
| 03-dev-doc.md | Technische Umsetzung (Ist) |
| 04-tasks.md | Tasks + Testing-Inbox |
| 05-quality.md | Bugs + Testläufe |

---

## ID System

- feat01 → feature
- task01 → task
- bug01 → bug
- test01 → test

Example:
feat01 → task02 → bug01 → test03

---

## Prompt Shortcuts

# eLedia.OS — Prompt Shortcuts

This file contains reusable prompt shortcuts for working with AI (e.g. Claude, ChatGPT) inside eLedia.OS.

Each prompt is designed to:
- use the correct context (files)
- produce structured output
- support consistent workflows

---

## 🔹 Status & Overview

### #status

Analyze the current project state using:

- 01-features.md
- 04-tasks.md
- 05-quality.md

Provide a structured summary:

1. Implemented features (featXX)
2. Features in progress
3. Open tasks (taskXX), grouped by feature
4. Open bugs (bugXX), prioritized by severity
5. Items waiting for verification
6. Biggest risks or inconsistencies

End with:
→ 3 concrete next steps

---

## 🔹 Next Steps & Prioritization

### #next

Based on the current state in:

- 04-tasks.md
- 05-quality.md
- 01-features.md

Identify the 1–3 highest-value next tasks.

For each:
- explain WHY it is important
- identify dependencies
- estimate complexity (low / medium / high)

Prioritize:
1. blockers
2. bugs affecting functionality
3. incomplete core features

---

## 🔹 Planning

### #plan

Take the current feature (featXX) and break it into tasks.

Each task must:
- have a clear goal
- be independently executable
- reference the feature (featXX)

Output format:

taskXX Title  
- Goal:
- Steps:
- Dependencies:
- Expected result:

Also:
- identify potential risks
- identify unclear areas → move to clarification

---

## 🔹 Refinement / Clarification

### #refine

Analyze the selected feature (featXX).

Identify:
- unclear behavior
- missing edge cases
- conflicting assumptions

Ask focused questions that:
- unblock implementation
- reduce ambiguity

Group questions by:
1. behavior
2. UX
3. technical constraints

Do NOT answer the questions yourself.

---

## Implementation

### #implement

Start implementing the next task (taskXX).

Steps:
1. restate the goal of the task
2. identify required components
3. implement step-by-step
4. highlight decisions made during implementation

If something is unclear:
→ create an entry in "clarification" instead of guessing

---

## Testing Strategy

### #test

Design a test strategy for the selected feature (featXX).

Include:

1. Manual tests
   - user flows
   - edge cases
   - UI behavior

2. Automated tests (if applicable)
   - unit tests
   - integration tests

3. Failure scenarios
   - what can break?
   - how to detect it?

Output:
- structured checklist
- ready to copy into quality.md

---

## Bug Analysis

### #bugs

Analyze all open bugs from 05-quality.md.

For each bug:
- summarize the issue
- identify affected feature (featXX)
- estimate severity (low / medium / high / critical)
- suggest fix approach

Then:
- prioritize bugs
- identify patterns or recurring problems

---

## Verification (Post-Deploy)

### #verify

Based on recent changes and tasks:

Create a verification checklist for manual testing.

For each item:
- what to test
- expected outcome
- where (UI / endpoint / flow)

Group by feature.

Output should be ready to paste into:
→ "Nach Deploy verifizieren" section

---

## Documentation Sync (Critical)

### #doc

Check consistency across:

- 01-features.md
- 02-user-doc.md
- 03-dev-doc.md

For each feature:

1. Does implementation match feature definition?
2. Is user documentation accurate and complete?
3. Does developer documentation reflect reality?

Then:
- list inconsistencies
- update documentation where needed

Do NOT rewrite everything — only adjust relevant parts.

---

## User Documentation

### #userdoc

Write or update user documentation for feature (featXX).

Focus on:
- what the user wants to achieve
- step-by-step usage
- examples
- common mistakes

Avoid:
- technical jargon
- implementation details

---

## Developer Documentation

### #devdoc

Document the implementation of feature (featXX).

Include:
- architecture overview
- key components
- data flow
- dependencies
- constraints

Focus on:
→ enabling another developer to understand and extend the system

---

## System Consistency Check

### #consistency

Check the entire system for inconsistencies:

- features vs implementation
- tasks vs actual state
- bugs vs unresolved issues
- missing documentation

Output:
- list of issues
- suggested fixes

---

## Critical Review

### #review

Critically evaluate the current solution.

Answer:

1. What is working well?
2. What is fragile or risky?
3. Where is complexity too high?
4. What can be simplified?

Focus on actionable improvements.

---

## Usage Notes

- Use these prompts directly in AI chats
- Combine them with IDs (featXX, taskXX, bugXX)
- Prefer small, focused prompts over large, vague ones
- Always reference relevant files when needed

---

## Recommended Daily Workflow

1. #status
2. #next
3. #implement
4. #test
5. #doc

This loop keeps the system consistent and productive.
---

## Core Rule

## Core Rule (Definition of Done)

A feature is only considered **done** when all three perspectives are consistent, complete, and aligned:

### 1. Feature Definition (`01-features.md`)

The feature must clearly define:

- **Goal** → why the feature exists
- **Behavior** → what exactly happens (including edge cases)
- **Non-goals** → what is explicitly not included
- **Decisions** → key design choices

There must be no ambiguity that would block implementation.

---

### 2. User Documentation (`02-user-doc.md`)

The feature must be understandable from a user perspective:

- clear explanation of what the feature does
- step-by-step usage
- expected outcomes
- relevant constraints or limitations

A user should be able to use the feature **without reading the code**.

---

### 3. Developer Documentation (`03-dev-doc.md`)

The actual implementation must be documented:

- architecture and components involved
- data flow and interactions
- key technical decisions
- constraints and known limitations

Another developer should be able to understand and extend the feature **without guessing**.

---

### 4. Consistency Check (Critical)

All three must match:

- behavior described in `01-features.md`
- usage described in `02-user-doc.md`
- implementation described in `03-dev-doc.md`

If any mismatch exists:
→ the feature is NOT done

---

### 5. Verification

Additionally:

- all related tasks (taskXX) are completed
- no blocking bugs (bugXX) remain
- relevant tests (testXX) pass or are verified

---

### Not Done If

A feature is NOT done if:

- documentation is missing or outdated
- behavior is unclear or inconsistent
- implementation differs from defined behavior
- user documentation does not match reality
- known bugs affect core functionality

---

## Principle

> Implementation alone is not completion.  
> A feature is only complete when it is **understood, usable, and maintainable**.
