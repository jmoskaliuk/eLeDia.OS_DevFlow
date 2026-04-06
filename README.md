# eLedia.OS

eLedia.OS is a structured operating system for AI-assisted software development.

It defines how ideas, implementation, documentation, and testing interact in a consistent workflow — enabling humans and AI (e.g. Claude, ChatGPT) to collaborate effectively without chaos.

---

## 🧠 Why eLedia.OS exists

Working with AI on software projects introduces a new problem:

> The limiting factor is no longer writing code — it is managing context.

Typical issues:
- requirements, decisions, and implementation drift apart
- important context is lost in chat history
- user documentation is forgotten
- technical documentation becomes outdated
- bugs and tests are tracked inconsistently
- AI produces correct but contextually wrong solutions

eLedia.OS addresses this by introducing a **minimal but strict structure** for how information is organized and maintained.

---

## 🧩 Core idea

eLedia.OS separates software development into **five distinct perspectives**:

| Perspective | File | Question |
|------------|------|----------|
| Features | `01-features.md` | What are we building and why? |
| User | `02-user-doc.md` | How does a user interact with it? |
| Developer | `03-dev-doc.md` | How is it actually implemented? |
| Work | `04-tasks.md` | What are we doing right now? |
| Quality | `05-quality.md` | Does it work and what is broken? |

Each file has a **single responsibility**.

---

## ⚙️ System logic

The system is built around a simple but powerful principle:

> Different types of information must not be mixed.

Why?

Because mixing:
- planning + implementation
- user view + developer view
- ideas + tasks + bugs

leads to:
- confusion
- duplication
- inconsistent decisions
- poor AI reasoning

---

### Separation of concerns

- **Features (`01-features.md`)**  
  Defines intent and expected behavior.  
  → This is the *source of truth* for what the system should do.

- **User Documentation (`02-user-doc.md`)**  
  Explains how real users interact with the system.  
  → Forces clarity and usability.

- **Developer Documentation (`03-dev-doc.md`)**  
  Describes the actual implementation.  
  → Reflects reality, not intention.

- **Tasks (`04-tasks.md`)**  
  Contains active work, questions, and verification steps.  
  → The operational center.

- **Quality (`05-quality.md`)**  
  Tracks bugs and test results.  
  → The reality check.

---

## 🔥 The most important rule

> A feature is only done when all perspectives are consistent.

This means:

- Feature is defined (`01-features.md`)
- User can understand it (`02-user-doc.md`)
- Implementation is documented (`03-dev-doc.md`)

If one is missing → the feature is not done.

---

## 🔁 Workflow
