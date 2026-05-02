# Incidents and Root Causes

> Every bug found or fixed gets an entry. **Newest at the top.**
> If a fix turns out to be wrong, do not edit the original — add a new entry referencing it.

---

## Entry template

```
## YYYY-MM-DD — <id> — <title> — <status>

- **Status**: open | investigating | resolved | monitoring | regressed
- **Detection time**: <when was it first observed>
- **Detection source**: alert | user report | log review | test | other
- **Impacted area**: <module / flow / endpoint>
- **Symptoms**:
  - User-visible: <what the user saw>
  - Internal: <what logs / metrics showed>
- **Root cause**: <the actual cause, not the trigger>
- **Trigger**: <what set off the cause this time>
- **Fix**: <what changed and where>
- **Prevention**: <new test, alert, guardrail, doc>
- **Linked**:
  - ledger entry: `<date>`
  - debug_map flow: `<name>`
  - PR / commit: `<ref>`
- **Timeline**:
  - HH:MM — <event>
  - HH:MM — <event>
```

---

## Entries

<!-- Newest first. -->
