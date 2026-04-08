# Developer Documentation

## Meta

This document describes the actual implementation.

It answers:
→ How is the system built?

Use this document when:
- implementation changes
- architecture needs explanation

Do NOT include:
- feature ideas
- tasks
- vague plans

---

## Popup Control (feat01)

**Architecture**
- communication via postMessage

**Components**
- view.js
- popup.js

**Data Flow**
View → Popup → View

**Constraints**
- no backend sync

---

## Question Navigation (feat02)

**Architecture**
- session-based navigation

**Components**
- navigation handler
- session storage

**Data Flow**
User → Session → UI

**Known limitations**
- state resets on full reload
