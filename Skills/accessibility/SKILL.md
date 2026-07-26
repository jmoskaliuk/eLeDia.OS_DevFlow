---
name: accessibility
description: Audit web interfaces for accessibility and provide evidence-based remediation guidance mapped to WCAG 2.2 AA, EN 301 549, BITV, and BFSG. Use for accessibility reviews, keyboard and focus testing, screen-reader semantics, forms, contrast, zoom and reflow, motion, touch targets, ARIA, accessible names, issue triage, remediation verification, or compliance-oriented web UI reports.
---

# Accessibility

Read `references/audit-guide.md` before performing an audit or advising on a
finding. Use it as the detailed testing and reporting standard.

## Audit

1. Establish the target pages, user journeys, supported browsers and assistive
   technologies, authentication constraints, and required legal mapping.
2. Combine automated checks with manual keyboard, focus, semantics, zoom,
   reflow, contrast, form, error, motion, and screen-reader inspection.
3. Reproduce every reported finding and capture the affected element, user
   impact, relevant success criterion, severity, and concrete remediation.
4. Separate confirmed violations from risks, observations, and items that
   require testing with a real assistive technology or user.
5. Prefer semantic HTML. Recommend ARIA only when native semantics cannot
   express the required behavior.
6. Re-test after remediation and distinguish code verification from legal
   certification. Do not claim compliance from automated scans alone.
7. Send verified, reusable audit lessons through the `knowledge-curator`
   workflow instead of silently changing the shared standard.

An audit request does not authorize code changes unless the user also asks for
remediation. A remediation request does not authorize deployment or publication.
