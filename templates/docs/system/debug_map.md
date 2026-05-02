# Debug Map

> Maps each major flow to its entrypoints, logs, failure points, repro steps, and verification.
> Update whenever a flow's shape, logging, or failure modes change.

---

## Flow template

```
## Flow: <flow name>

- **Purpose**: <what this flow does>
- **Entrypoint(s)**:
  - `path/to/handler.ext:line` — <route / event / cli>
- **Dependent modules**:
  - `path/to/service.ext`
  - `path/to/repo.ext`
- **External dependencies**: <db, queue, third-party APIs>
- **State touched**: <tables, caches, queues>
- **Logs emitted** (event names + where):
  - `op.start` — entrypoint
  - `op.dependency.call` — service layer
  - `op.success` / `op.failure` — entrypoint return
- **Correlation ID source**: <header, generated, propagated from>
- **Likely failure points**:
  - dependency timeout at `<location>`
  - validation failure at `<location>`
  - state conflict at `<location>`
- **Reproduction steps**:
  1. <setup>
  2. <trigger>
  3. <observe>
- **Fix locations**: <where fixes typically land for this flow>
- **Verification commands**:
  - `<test command>`
  - `<log query>`
  - `<metric / dashboard>`
- **Linked**: incident `<id>` | ledger entry `<date>` | inventory section `<name>`
```

---

## Flows

<!-- One section per critical flow. Use the template above. -->
