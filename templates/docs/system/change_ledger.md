# Change Ledger

> Append-only. Every meaningful change gets an entry. **Newest at the top.**
> Do not edit past entries. If a change is reverted, add a new entry referencing the original.

---

## Entry template

```
## YYYY-MM-DD HH:MM — <task-id> — <one-line summary>

- **Files affected**:
  - `path/to/file.ext`
- **Behavior changed**: <what user-visible or system-visible behavior moves>
- **Risk**: low | medium | high — <why>
- **Validation performed**: <tests, manual repro, lint, build, type check>
- **Rollback note**: <how to back out — git revert, feature flag, config>
- **Follow-ups**: <linked tasks, todos, debt>
- **Linked**: incident `<id>` | debug_map flow `<name>` | inventory section `<name>`
```

---

## Entries

<!-- Newest first. Use the template above. -->
